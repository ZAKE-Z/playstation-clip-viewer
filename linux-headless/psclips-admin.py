#!/usr/bin/env python3
"""Local administration and capture archiving for a headless Debian host."""
import base64
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import html
from http.client import HTTPException
from http.server import BaseHTTPRequestHandler
import ipaddress
import json
import os
from pathlib import Path
import re
import runpy
import secrets
import shutil
import socketserver
import sqlite3
import ssl
import subprocess
import tempfile
import threading
import time
from urllib.parse import parse_qs, quote, urlencode, urlsplit, urlunsplit
from urllib.request import Request
from urllib.error import HTTPError


CORE = runpy.run_path(str(Path(__file__).with_name("psclips-core.py")))
Error = CORE["TestError"]
STATE = Path("/var/lib/psclips")
LIBRARY = STATE / "captures"
SOCKET = Path("/run/psclips/admin.sock")
PORT = 18765
HOSTS = {f"127.0.0.1:{PORT}", f"localhost:{PORT}"}
LAN_RANGES = tuple(ipaddress.ip_network(x) for x in
                   ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"))
CSRF = secrets.token_urlsafe(32)
INTERVAL = 300
MIN_FREE = 128 * 1024**2
LOCK = threading.Lock()
SESSION_LOCK = threading.Lock()
ADMIN_LOCK = threading.Lock()
WAKE = threading.Event()
PENDING = None
CLOUD_CACHE = {}
DAV_CACHE = {}
DAV_EPOCH = 0
DAV_WAKE = threading.Event()
PREVIEW_SLOTS = threading.BoundedSemaphore(8)
STATUS = {"auth": "Checking", "counts": None, "job": "Waiting for check", "last": "—",
          "progress": None, "gallery_rev": 0, "busy": False, "cloud_known": False,
          "dav_status": "Not checked yet", "task_rev": 0}


def atomic(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as f:
        tmp = Path(f.name)
        try:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
            tmp.replace(path)
            directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
            try:
                os.fsync(directory)
            finally:
                os.close(directory)
        finally:
            tmp.unlink(missing_ok=True)


def vault(name, payload=None):
    path = STATE / f"{name}.cred"
    if payload is None and not path.exists():
        return None
    mode = "encrypt" if payload is not None else "decrypt"
    args = ["systemd-creds", mode, "--user", f"--name={name}"]
    args += ["--with-key=host", "-", "-"] if payload is not None else [str(path), "-"]
    result = subprocess.run(args, input=json.dumps(payload).encode() if payload is not None
                            else None, capture_output=True, timeout=10)
    if result.returncode != 0:
        raise Error("Cannot read or write encrypted system credentials")
    if payload is not None:
        atomic(path, result.stdout)
        return None
    return json.loads(result.stdout)


def settings():
    path = STATE / "settings.json"
    return json.loads(path.read_bytes()) if path.exists() else {}


def admin_verifier():
    raw = json.loads((STATE / "admin-verifier.json").read_bytes())
    username = raw.get("user", "admin")
    salt, key = bytes.fromhex(raw["salt"]), bytes.fromhex(raw["key"])
    if not valid_username(username) or len(salt) != 32 or len(key) != 32:
        raise ValueError("Invalid LAN administrator verifier")
    return username, salt, key


def valid_username(value):
    return isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9_.-]{1,32}", value)


def password_key(password, salt):
    return hashlib.scrypt(password, salt=salt, n=16384, r=8, p=1, dklen=32)


def admin_matches(username, password, verifier):
    current, salt, key = verifier
    return (secrets.compare_digest(username, current.encode()) and
            1 <= len(password) <= 256 and
            secrets.compare_digest(password_key(password, salt), key))


def change_admin(fields):
    username = fields.get("username", "").strip()
    password = fields.get("new_password", "")
    if not valid_username(username):
        raise Error("Use 1–32 letters, digits, periods, underscores, or hyphens for the username")
    if not (len(password) >= 12 and len(password.encode()) <= 256) or any(
            ord(c) < 32 or ord(c) == 127 for c in password):
        raise Error("Use at least 12 characters and at most 256 bytes, without control characters")
    if not secrets.compare_digest(password.encode(), fields.get("confirm_password", "").encode()):
        raise Error("The new passwords do not match")
    with ADMIN_LOCK:
        current = admin_verifier()
        if not admin_matches(current[0].encode(), fields.get("current_password", "").encode(), current):
            raise Error("The current admin password is incorrect")
        salt = secrets.token_bytes(32)
        atomic(STATE / "admin-verifier.json", json.dumps({
            "user": username, "salt": salt.hex(), "key": password_key(password.encode(), salt).hex(),
        }).encode())


def stamp(tokens):
    now = time.time()
    try:
        for key, interval in (("access", "expires_in"),
                              ("refresh", "refresh_token_expires_in")):
            ttl = int(tokens[interval])
            if not 1 <= ttl <= 10 * 365 * 86400 or not tokens[f"{key}_token"]:
                raise ValueError
            tokens[f"{key}_until"] = now + ttl
        tokens["checked_at"] = now
    except (KeyError, ValueError, TypeError):
        raise Error("Sony did not return usable tokens and expiration times") from None
    return tokens


class NeedLogin(Error):
    pass


def refresh(tokens):
    data = urlencode(dict(token_format="jwt", refresh_token=tokens["refresh_token"],
                          grant_type="refresh_token", scope=CORE["SCOPE"])).encode()
    try:
        value, _ = CORE["api_json"]("Token refresh", Request(
            CORE["OAUTH"] + "/token", data=data, headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Authorization": CORE["client_authorization"](),
            }))
    except Error as exc:
        if str(exc).endswith(("HTTP 400", "HTTP 401", "HTTP 403")):
            raise NeedLogin("Sony rejected token refresh; sign in again") from None
        raise
    value = stamp(value)
    vault("psn-session", value)
    return value


def session():
    tokens = vault("psn-session")
    if not tokens:
        raise NeedLogin("Signed out")
    now = time.time()
    if tokens.get("refresh_until") and tokens["refresh_until"] <= now:
        raise NeedLogin("The refresh token expired; sign in again")
    if tokens.get("access_until", 0) <= now + 120:
        return refresh(tokens)
    return tokens


def gallery(tokens):
    cursor, seen = None, set()
    for _ in range(500):
        params = {"limit": 20}
        if cursor:
            # Live API accepts nextCursorMark; cursorMark repeats the first page.
            params["nextCursorMark"] = cursor
        req = Request(f"{CORE['GALLERY']}?{urlencode(params)}",
                      headers={"Authorization": f"Bearer {tokens['access_token']}"})
        page, headers = CORE["api_json"]("Cloud gallery", req)
        items = page.get("ugcDocument")
        if not isinstance(items, list) or not all(isinstance(x, dict) for x in items):
            raise Error("The Sony gallery response format changed")
        for row in items:
            yield row, headers
        cursor = page.get("nextCursorMark")
        if not cursor or cursor == "-1":
            return
        if not isinstance(cursor, str) or cursor in seen:
            raise Error("Sony returned a duplicate or invalid gallery cursor")
        seen.add(cursor)
    raise Error("The gallery paging limit was reached")


def safe_component(value):
    if (not isinstance(value, str) or not value.strip() or value in (".", "..")
            or len(value.encode()) > 240 or any(c in value for c in '/\\\0')
            or any(ord(c) < 32 or ord(c) == 127 for c in value)):
        raise Error("Unsafe characters in the title or game folder; the file was not renamed or downloaded")
    return value


def names(row, ext):
    title = safe_component(row.get("title"))
    match = re.fullmatch(r"(.+)_\d{14}(?:\.[a-zA-Z0-9]+)?", title)
    game = safe_component(match[1] if match else row.get("sceTitleName") or "Uncategorized")
    # Keep Sony's title verbatim; the CDN format determines the suffix.
    filename = title if title.lower().endswith("." + ext) else title + "." + ext
    return game, safe_component(filename)


def capture_label(title, game_hint=None):
    raw = title if isinstance(title, str) and title.strip() else "Untitled capture"
    match = re.fullmatch(r"(.+)_([0-9]{14})(?:\.(?:mp4|webm|jpe?g|png|webp))?",
                         raw, flags=re.IGNORECASE)
    if match:
        try:
            when = datetime.strptime(match[2], "%Y%m%d%H%M%S")
            return game_hint or match[1], when.strftime("%Y-%m-%d %H:%M:%S")
        except ValueError:
            pass
    return game_hint or raw, None


def archive(row, headers, report=None):
    kind = row["ugcType"]
    if row.get("cloudStatus") == "error" or row.get("transcodeStatus") == "error":
        raise Error("Sony marked this capture as a processing failure; no file is available")
    sources = [row.get("downloadUrl"),
               row.get("videoUrl" if kind == 2 else "screenshotUrl")]
    last = Error("No downloadable image or video is available")
    for raw in dict.fromkeys(url for url in sources if isinstance(url, str)):
        url = CORE["signed_url"](raw, headers)
        if not url or urlsplit(url).path.lower().endswith(".m3u8"):
            continue
        temp = None
        try:
            with CORE["opener"](media=True).open(Request(url), timeout=45) as reply:
                expected = reply.headers.get("Content-Length")
                if expected is not None:
                    expected = int(expected)
                    if expected <= 0 or expected + MIN_FREE > shutil.disk_usage(STATE).free:
                        raise Error("Insufficient disk space or invalid file length")
                head = reply.read(512)
                game, filename = names(row, CORE["media_extension"](head, kind))
                tick = report.phase("Downloading from Sony", expected, filename) if report else None
                folder = LIBRARY / game
                folder.mkdir(mode=0o700, exist_ok=True)
                path = folder / filename
                digest = hashlib.sha256()
                size = 0
                with tempfile.NamedTemporaryFile(dir=folder, delete=False) as out:
                    temp = Path(out.name)
                    chunk = head
                    while chunk:
                        size += len(chunk)
                        if shutil.disk_usage(STATE).free < MIN_FREE:
                            raise Error("Not enough free disk space; existing files were kept")
                        digest.update(chunk)
                        out.write(chunk)
                        if tick:
                            tick(size)
                        chunk = reply.read(1024 * 1024)
                    if expected is not None and size != expected:
                        raise Error("Incomplete download")
                    out.flush()
                    os.fsync(out.fileno())
                try:
                    os.link(temp, path)
                except FileExistsError:
                    if hash_file(path) != digest.hexdigest():
                        raise Error("A file with this name has different contents; it was not overwritten or renamed") from None
                return str(path.relative_to(LIBRARY)), digest.hexdigest()
        except HTTPError as exc:
            with exc:
                last = Error(f"Sony CDN: HTTP {exc.code}")
        except Error as exc:
            last = exc
        except (OSError, HTTPException, ValueError) as exc:
            last = Error("Sony download timed out through the proxy" if is_timeout(exc) else "Sony download connection or local storage failed")
        finally:
            if temp is not None:
                temp.unlink(missing_ok=True)
    raise last


def hash_file(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def is_timeout(exc):
    return isinstance(getattr(exc, "reason", exc), TimeoutError)


def dav_settings(fields):
    url, user, password = (fields.get(x, "").strip() if x != "password" else
                           fields.get(x, "") for x in ("url", "user", "password"))
    p = urlsplit(url)
    if (p.scheme not in ("http", "https") or not p.hostname or p.username or p.password
            or p.query or p.fragment or not user or ":" in user or not password):
        raise Error("Enter the full WebDAV folder URL, username, and password")
    if p.scheme == "http":
        try:
            addr = ipaddress.ip_address(p.hostname)
            private = addr.version == 4 and any(addr in net for net in LAN_RANGES)
        except ValueError:
            private = False
        if not private or fields.get("allow_http") != "on":
            raise Error("HTTP requires a private IPv4 address and explicit permission for cleartext transport")
    safe_path = quote(p.path.rstrip("/"), safe="/%:@!$&()+,;=-._~") + "/"
    return dict(url=urlunsplit(p._replace(path=safe_path)), user=user, password=password)


def dav_request(dav, method, url, *, data=None, headers=None, timeout=55):
    auth = base64.b64encode((dav["user"] + ":" + dav["password"]).encode()).decode()
    req = Request(url, data=data, method=method,
                  headers={"Authorization": "Basic " + auth, **(headers or {})})
    return CORE["opener"]().open(req, timeout=timeout)


def dav_check(dav):
    try:
        with dav_request(dav, "PROPFIND", dav["url"], headers={"Depth": "0"}) as r:
            if r.status != 207:
                raise Error("The WebDAV address did not return a directory listing")
    except HTTPError as exc:
        with exc:
            raise Error(f"WebDAV directory check failed: HTTP {exc.code}") from None
    except (OSError, HTTPException) as exc:
        raise Error("WebDAV connection timed out through the proxy" if is_timeout(exc) else "WebDAV network or certificate verification failed") from None


class UploadReader:
    def __init__(self, source, tick):
        self.source, self.tick, self.sent = source, tick, 0

    def read(self, size=-1):
        data = self.source.read(size)
        if data:
            self.sent += len(data)
            self.tick(self.sent)
        return data


def dav_file_url(dav, local):
    game, name = local.parts
    folder = dav["url"] + quote(game, safe="") + "/"
    return folder, folder + quote(name, safe="")


def dav_verify(dav, dest, size, digest, tick=None):
    with dav_request(dav, "GET", dest) as response:
        if response.status != 200:
            raise Error("WebDAV did not return a complete file")
        h = hashlib.sha256()
        total = 0
        while chunk := response.read(1024**2):
            total += len(chunk)
            if total > size:
                break
            h.update(chunk)
            if tick:
                tick(total)
    return total == size and h.hexdigest() == digest


def dav_upload(dav, local, digest, report=None):
    name = local.name
    folder, dest = dav_file_url(dav, local)
    try:
        try:
            with dav_request(dav, "MKCOL", folder):
                pass
        except HTTPError as exc:
            with exc:
                if exc.code not in (403, 405):
                    raise
            with dav_request(dav, "PROPFIND", folder, headers={"Depth": "0"}) as r:
                if r.status != 207:
                    raise Error("The WebDAV game folder is unavailable")
        path = LIBRARY / local
        size = path.stat().st_size
        if report:
            report.phase("Checking the WebDAV destination file", None, name)
        try:
            with dav_request(dav, "HEAD", dest):
                pass
        except HTTPError as exc:
            with exc:
                if exc.code != 404:
                    raise
            try:
                tick = report.phase("Uploading to WebDAV", size, name) if report else None
                with path.open("rb") as data:
                    with dav_request(dav, "PUT", dest, data=UploadReader(data, tick) if tick else data,
                                     headers={"Content-Length": str(size), "If-None-Match": "*"}):
                        pass
            except HTTPError as conflict:
                with conflict:
                    if conflict.code != 412:
                        raise
        tick = report.phase("Reading back from WebDAV to verify", size, name) if report else None
        if not dav_verify(dav, dest, size, digest, tick):
            raise Error("The WebDAV copy does not match the local file; the original was not overwritten")
    except HTTPError as exc:
        with exc:
            raise Error(f"WebDAV upload failed: HTTP {exc.code}") from None
    except (OSError, HTTPException) as exc:
        raise Error("WebDAV transfer timed out through the proxy" if is_timeout(exc) else "WebDAV network, local file, or certificate verification failed") from None


def setstatus(**data):
    with LOCK:
        STATUS.update(data)


class TransferProgress:
    def __init__(self, total, skipped):
        self.total, self.skipped = total, skipped
        self.done = self.failed = 0
        self.phase("Preparing transfer")

    def phase(self, stage, total=None, filename=None):
        start = time.monotonic()
        current = {"stage": stage, "filename": filename, "bytes": 0, "size": total,
                   "started": start, "sampled": start, "speed": 0}
        self.current = current
        self.publish()

        def tick(count):
            now = time.monotonic()
            if now - current["sampled"] >= .25 or count == total:
                delta = now - current["started"]
                current.update(bytes=count, sampled=now, speed=round(count / max(.1, delta)))
                self.publish()
        return tick

    def publish(self):
        now = dict(self.current)
        now.update(done=self.done, failed=self.failed, total=self.total, skipped=self.skipped)
        setstatus(progress=now)

    def finish(self, failed=False):
        self.done += 1
        self.failed += int(failed)
        self.publish()


def database():
    db = sqlite3.connect(STATE / "archive.sqlite3")
    db.execute("""CREATE TABLE IF NOT EXISTS captures (
        id TEXT PRIMARY KEY, kind INTEGER NOT NULL, path TEXT NOT NULL,
        sha TEXT NOT NULL, uploaded_to TEXT
    )""")
    return db


def is_new_video(row, cutoff):
    if row["ugcType"] != 2:
        return False
    try:
        upload = datetime.fromisoformat(row["uploadDate"])
        return upload.tzinfo is not None and upload.timestamp() >= cutoff
    except (KeyError, TypeError, ValueError, OverflowError):
        return False


def preview_key(identifier):
    return hashlib.sha256(identifier.encode()).hexdigest()


def unavailable(row):
    return row.get("cloudStatus") == "error" or row.get("transcodeStatus") == "error"


def cache_gallery(rows):
    global CLOUD_CACHE
    with LOCK:
        CLOUD_CACHE = {preview_key(k): (k, r, h) for k, (r, h) in rows.items()}
        STATUS["gallery_rev"] += 1
    DAV_WAKE.set()


def sync(mode, selected=None):
    if mode == "cleanup":
        return cleanup_local_videos(selected or set())
    if mode == "batch":
        return run_batch(selected)
    try:
        with SESSION_LOCK:
            tokens = session()
        try:
            entries = list(gallery(tokens))
        except Error as exc:
            if not str(exc).endswith("HTTP 401"):
                raise
            with SESSION_LOCK:
                current = vault("psn-session")
                tokens = (refresh(tokens) if current == tokens else session())
            entries = list(gallery(tokens))
    except NeedLogin as exc:
        cache_gallery({})
        setstatus(auth=str(exc), counts=None, cloud_known=False)
        return str(exc)
    except Error:
        with LOCK:
            STATUS.update(auth="Cannot verify the session right now; check the task status", cloud_known=False,
                          gallery_rev=STATUS["gallery_rev"] + 1)
        raise
    by_id = {row["id"]: (row, headers) for row, headers in entries
             if isinstance(row.get("id"), str) and row.get("ugcType") in (1, 2)}
    pics = sum(row["ugcType"] == 1 for row, _ in by_id.values())
    setstatus(auth="Signed in", counts=(len(by_id) - pics, pics), cloud_known=True)
    cache_gallery(by_id)
    if mode == "check":
        return "Cloud counts updated"
    if selected is not None:
        by_id = {k: value for k, value in by_id.items() if k in selected}
        if not by_id:
            return "The selected captures are no longer in the Sony cloud"
    try:
        with LOCK:
            active_dav_epoch = DAV_EPOCH
        dav = vault("webdav")
        if not dav:
            return "Downloads are blocked until WebDAV is configured"
        dav_check(dav)
    except (Error, KeyError, OSError, ValueError, subprocess.SubprocessError) as exc:
        reason = str(exc) if isinstance(exc, Error) else "Cannot read WebDAV settings"
        return f"Downloads blocked: {reason}"
    dest_id = hashlib.sha256((dav["url"] + "\0" + dav["user"]).encode()).hexdigest()
    auto_since = settings().get("auto_since", 0) if mode == "auto" else 0
    saved = uploaded = failures = 0
    last_error = ""
    with database() as db:
        history = {item[0]: item[1:] for item in db.execute(
            "SELECT id,path,sha,uploaded_to FROM captures")}
        jobs = [(key, path, sha) for key, (path, sha, remote) in history.items()
                if mode != "force" and remote is None and (LIBRARY / path).is_file()
                and (selected is None or key in selected)]
        downloads = []
        skipped = 0
        for identifier, (row, headers) in by_id.items():
            if mode == "auto" and not is_new_video(row, auto_since):
                continue
            prior = history.get(identifier)
            if mode != "force" and prior and (prior[2] is not None or (LIBRARY / prior[0]).is_file()):
                skipped += int(prior[2] is not None)
                continue
            downloads.append((identifier, row, headers))
        report = TransferProgress(len(jobs) + len(downloads), skipped)

        def upload_one(identifier, path, sha):
            nonlocal uploaded
            report.phase("Connecting to WebDAV", filename=Path(path).name)
            dav_upload(dav, Path(path), sha, report)
            db.execute("UPDATE captures SET uploaded_to=? WHERE id=?", (dest_id, identifier))
            db.commit()
            uploaded += 1
            with LOCK:
                if active_dav_epoch == DAV_EPOCH:
                    DAV_CACHE[preview_key(identifier)] = ("present", time.monotonic())
                STATUS["gallery_rev"] += 1

        for identifier, path, sha in jobs:
            try:
                upload_one(identifier, path, sha)
                report.finish()
            except Error as exc:
                report.finish(failed=True)
                return f"Downloads paused: {exc}; Check WebDAV and try again"
        for identifier, row, headers in downloads:
            try:
                report.phase("Connecting to Sony", filename=row.get("title") if isinstance(row.get("title"), str) else None)
                path, sha = archive(row, headers, report)
                db.execute("""INSERT INTO captures VALUES (?,?,?,?,NULL)
                    ON CONFLICT(id) DO UPDATE SET kind=excluded.kind,
                    path=excluded.path, sha=excluded.sha""",
                    (identifier, row["ugcType"], path, sha))
                db.commit()
                saved += 1
                with LOCK:
                    STATUS["gallery_rev"] += 1
            except Error as exc:
                report.finish(failed=True)
                failures += 1
                last_error = str(exc)
                continue
            try:
                upload_one(identifier, path, sha)
                report.finish()
            except Error as exc:
                report.finish(failed=True)
                return (f"Downloads paused: {exc}; Local files added: {saved}, uploaded to WebDAV: {uploaded}."
                        "Pending files were kept; check WebDAV and try again")
    return (f"{'Force redownload' if mode == 'force' else 'New downloads:'} {saved}, "
            f"verified on WebDAV: {uploaded}, Failed {failures}" +
            (f"; Latest error: {last_error}" if last_error else ""))


def cleanup_local_videos(selected):
    dav = vault("webdav")
    if not dav:
        raise Error("WebDAV is not configured; no local videos were deleted")
    dav_check(dav)
    with database() as db:
        records = [(Path(path), digest) for identifier, path, digest in db.execute(
            "SELECT id,path,sha FROM captures WHERE kind=2 AND uploaded_to IS NOT NULL")
            if identifier in selected]
    removed = released = 0
    report = TransferProgress(len(records), len(selected) - len(records))
    issues = []
    for relative, digest in records:
        path = LIBRARY / relative
        report.phase("Checking local video", filename=relative.name)
        try:
            if (len(relative.parts) != 2 or path.is_symlink() or
                    not path.resolve().is_relative_to(LIBRARY.resolve()) or not path.is_file()):
                raise Error("The local file is missing or its path is unsafe")
            before = path.stat()
            if hash_file(path) != digest:
                raise Error("The local video has changed")
            _, dest = dav_file_url(dav, relative)
            check = report.phase("Verifying the WebDAV copy", before.st_size, relative.name)
            if not dav_verify(dav, dest, before.st_size, digest, check):
                raise Error("The WebDAV copy does not match the local file")
            after = path.stat()
            if (before.st_ino, before.st_dev, before.st_size, before.st_mtime_ns, before.st_ctime_ns) != (
                    after.st_ino, after.st_dev, after.st_size, after.st_mtime_ns, after.st_ctime_ns):
                raise Error("The local file changed during verification")
            path.unlink()
            removed += 1
            released += before.st_size
            report.finish()
            with LOCK:
                STATUS["gallery_rev"] += 1
        except HTTPError as exc:
            with exc:
                issues.append(f"WebDAV HTTP {exc.code}, the local video was kept")
            report.finish(failed=True)
        except (Error, OSError, HTTPException, ValueError) as exc:
            issues.append(str(exc) if isinstance(exc, Error) else "Local or WebDAV I/O error")
            report.finish(failed=True)
    return (f"Deleted: {removed} local videos; freed {released / 1024**2:.1f} MiB; "
            f"Kept: {len(selected) - removed} files"
            + ("; Latest reason: " + issues[-1] if issues else ""))


def task_db():
    db = database()
    db.executescript("""
        CREATE TABLE IF NOT EXISTS batches (
            id INTEGER PRIMARY KEY, mode TEXT NOT NULL, created INTEGER NOT NULL,
            state TEXT NOT NULL DEFAULT 'ready', note TEXT, retry_at INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS batch_files (
            batch INTEGER NOT NULL, capture TEXT NOT NULL, title TEXT NOT NULL,
            state TEXT NOT NULL DEFAULT 'pending', category TEXT, detail TEXT,
            retryable INTEGER NOT NULL DEFAULT 0, path TEXT, sha TEXT,
            PRIMARY KEY (batch, capture)
        );
        CREATE TABLE IF NOT EXISTS batch_attempts (
            id INTEGER PRIMARY KEY, batch INTEGER NOT NULL, capture TEXT NOT NULL,
            failed_at INTEGER NOT NULL, category TEXT NOT NULL, detail TEXT NOT NULL
        );
        CREATE INDEX IF NOT EXISTS batch_attempts_batch ON batch_attempts(batch,id);
    """)
    return db


def task_changed():
    with LOCK:
        STATUS["task_rev"] += 1


def create_batch(mode, selected):
    with LOCK:
        titles = {identifier: row.get("title") for identifier, row, _ in CLOUD_CACHE.values()
                  if identifier in selected}
    with task_db() as db:
        batch = db.execute("INSERT INTO batches (mode,created) VALUES (?,?)",
                           (mode, int(time.time()))).lastrowid
        db.executemany("INSERT INTO batch_files (batch,capture,title) VALUES (?,?,?)",
                       ((batch, key, str(titles.get(key) or "Untitled capture")[:300]) for key in sorted(selected)))
    task_changed()
    WAKE.set()
    return batch


def ready_batch():
    with task_db() as db:
        row = db.execute("""SELECT id FROM batches WHERE state IN ('ready','running','waiting')
                     AND retry_at<=? ORDER BY id LIMIT 1""", (int(time.time()),)).fetchone()
    return row[0] if row else None


def retry_batch(batch):
    with task_db() as db:
        row = db.execute("SELECT state FROM batches WHERE id=?", (batch,)).fetchone()
        if not row or row[0] in ("running", "ready"):
            raise Error("The task does not exist, is running, or is already queued")
        count = db.execute("""UPDATE batch_files SET state='pending',retryable=0,category=NULL,detail=NULL
                        WHERE batch=? AND state='failed' AND retryable=1""", (batch,)).rowcount
        if not count and row[0] != "waiting":
            raise Error("No failed captures can be retried")
        db.execute("UPDATE batches SET state='ready',retry_at=0,note=NULL WHERE id=?", (batch,))
    task_changed()
    WAKE.set()
    return count


def batch_status(batch, state, note=None, delay=0):
    with task_db() as db:
        db.execute("UPDATE batches SET state=?,note=?,retry_at=? WHERE id=?",
                   (state, note, int(time.time()) + delay if delay else 0, batch))
    task_changed()
    return note


def item_result(db, batch, key, state, *, category=None, detail=None, retryable=False):
    db.execute("""UPDATE batch_files SET state=?,category=?,detail=?,retryable=?
                  WHERE batch=? AND capture=?""", (state, category, detail, retryable, batch, key))
    if state == "failed":
        db.execute("""INSERT INTO batch_attempts (batch,capture,failed_at,category,detail)
                    VALUES (?,?,?,?,?)""", (batch, key, int(time.time()), category, detail))
    db.commit()
    task_changed()


def failure_type(detail, dav=False):
    if "timed out" in detail:
        return "Proxy timeout", True
    if dav:
        permanent = "does not match" in detail or "HTTP 412" in detail
        return "WebDAV failure", not permanent
    if "processing failure" in detail:
        return "Not uploaded by PlayStation", False
    if "Unsafe characters" in detail or "a file with this name has different contents" in detail or "No downloadable" in detail:
        return "Capture unavailable", False
    if "disk space" in detail or "free disk space" in detail:
        return "Insufficient disk space", True
    return "Sony download failed", True


def run_batch(batch):
    batch_status(batch, "running")
    # A fresh gallery also refreshes signed URLs; the queue itself never stores them.
    try:
        sync("check")
    except Error as exc:
        return batch_status(batch, "waiting", f"Waiting for Sony: {exc}", delay=INTERVAL)
    with LOCK:
        if not STATUS["cloud_known"]:
            auth = STATUS["auth"]
        else:
            auth = None
        cloud = {key: (r, h) for key, r, h in CLOUD_CACHE.values()}
        epoch = DAV_EPOCH
    if auth:
        return batch_status(batch, "waiting", f"Waiting for Sony: {auth}", delay=INTERVAL)
    try:
        dav = vault("webdav")
        if not dav:
            raise Error("Configure WebDAV first")
        dav_check(dav)
    except (Error, OSError, ValueError, KeyError, subprocess.SubprocessError) as exc:
        description = str(exc) if isinstance(exc, Error) else "Cannot read WebDAV settings"
        return batch_status(batch, "waiting", f"Waiting for WebDAV: {description}", delay=INTERVAL)
    dest_id = hashlib.sha256((dav["url"] + "\0" + dav["user"]).encode()).hexdigest()
    with task_db() as db:
        mode = db.execute("SELECT mode FROM batches WHERE id=?", (batch,)).fetchone()[0]
        rows = db.execute("SELECT capture,title,state,path,sha FROM batch_files WHERE batch=? ORDER BY rowid",
                          (batch,)).fetchall()
        report = TransferProgress(len(rows), sum(row[2] == "skipped" for row in rows))
        report.done = sum(row[2] != "pending" for row in rows)
        report.failed = sum(row[2] == "failed" for row in rows)
        report.publish()
        for key, title, state, path, sha in rows:
            if state != "pending":
                continue
            prior = db.execute("SELECT kind,path,sha,uploaded_to FROM captures WHERE id=?", (key,)).fetchone()
            if not path and mode == "selected" and prior and prior[3] is not None:
                item_result(db, batch, key, "skipped")
                report.skipped += 1
                report.finish()
                continue
            if not path and mode == "selected" and prior and (LIBRARY / prior[1]).is_file():
                path, sha = prior[1:3]
            if path and not (LIBRARY / path).is_file():
                path = sha = None
            if not path:
                entry = cloud.get(key)
                if not entry:
                    item_result(db, batch, key, "failed", category="Removed from the cloud", detail="This capture is no longer in the Sony gallery")
                    report.finish(failed=True)
                    continue
                row, headers = entry
                try:
                    report.phase("Connecting to Sony", filename=title)
                    path, sha = archive(row, headers, report)
                except Error as exc:
                    category, retry = failure_type(str(exc))
                    item_result(db, batch, key, "failed", category=category, detail=str(exc), retryable=retry)
                    report.finish(failed=True)
                    continue
                db.execute("""INSERT INTO captures VALUES (?,?,?,?,NULL)
                    ON CONFLICT(id) DO UPDATE SET kind=excluded.kind,path=excluded.path,sha=excluded.sha""",
                           (key, row["ugcType"], path, sha))
            # Commit this checkpoint before uploading, including for a forced re-download.
            db.execute("UPDATE batch_files SET path=?,sha=? WHERE batch=? AND capture=?",
                       (path, sha, batch, key))
            db.commit()
            with LOCK:
                STATUS["gallery_rev"] += 1
            try:
                report.phase("Connecting to WebDAV", filename=Path(path).name)
                dav_upload(dav, Path(path), sha, report)
            except Error as exc:
                category, retry = failure_type(str(exc), dav=True)
                if retry:
                    # Atomically store both failure and pause so a restart cannot accidentally advance.
                    db.execute("UPDATE batches SET state='paused',note=? WHERE id=?",
                               (f"WebDAV failure: {exc}", batch))
                item_result(db, batch, key, "failed", category=category, detail=str(exc), retryable=retry)
                report.finish(failed=True)
                if retry:
                    return f"Batch task #{batch} paused: {exc}; Retry from the task history."
                continue
            db.execute("UPDATE captures SET uploaded_to=? WHERE id=?", (dest_id, key))
            item_result(db, batch, key, "done")
            with LOCK:
                if epoch == DAV_EPOCH:
                    DAV_CACHE[preview_key(key)] = ("present", time.monotonic())
                STATUS["gallery_rev"] += 1
            report.finish()
    return batch_status(batch, "finished", f"Batch task #{batch} completed; processed {report.done} items, Failed {report.failed} items")


def task_payload():
    with task_db() as db:
        jobs = db.execute("""SELECT id,mode,created,state,note FROM batches
                    ORDER BY (state IN ('ready','running','waiting','paused')) DESC,id DESC LIMIT 15""").fetchall()
        result = []
        for key, mode, created, state, note in jobs:
            items = db.execute("""SELECT state,count(*) FROM batch_files WHERE batch=? GROUP BY state""",
                               (key,)).fetchall()
            failures = db.execute("""SELECT title,category,detail,retryable FROM batch_files
                                      WHERE batch=? AND state='failed' AND detail IS NOT NULL
                                      ORDER BY rowid LIMIT 300""", (key,)).fetchall()
            attempts = db.execute("""SELECT f.title,a.category,a.detail,a.failed_at
                FROM batch_attempts a JOIN batch_files f ON a.batch=f.batch AND a.capture=f.capture
                WHERE a.batch=? ORDER BY a.id DESC LIMIT 50""", (key,)).fetchall()
            result.append(dict(id=key, mode=mode, created=created, state=state, note=note,
                               counts=dict(items), failures=failures, attempts=attempts))
    return result


def clear_failure_history():
    with task_db() as db:
        cleared = db.execute("""DELETE FROM batch_attempts WHERE batch IN
            (SELECT id FROM batches WHERE state='finished') AND NOT EXISTS (
                SELECT 1 FROM batch_files f WHERE f.batch=batch_attempts.batch
                AND f.capture=batch_attempts.capture AND f.state='failed' AND f.retryable=1
            )""").rowcount
        db.execute("""UPDATE batch_files SET category=NULL, detail=NULL
            WHERE batch IN (SELECT id FROM batches WHERE state='finished')
            AND state='failed' AND retryable=0""")
        db.execute("""UPDATE batches SET note=NULL WHERE state='finished'
            AND NOT EXISTS (SELECT 1 FROM batch_files f WHERE f.batch=batches.id
                AND f.state='failed' AND f.retryable=1)""")
    task_changed()
    return cleared


def worker():
    global PENDING
    deadline = 0
    while True:
        WAKE.wait(max(0, deadline - time.monotonic()))
        with LOCK:
            mode, selected = PENDING or (None, None)
            PENDING = None
            WAKE.clear()
            STATUS["busy"] = True
        try:
            batch = ready_batch()
            if mode != "cleanup" and batch is not None:
                mode, selected = "batch", batch
            elif mode is None:
                mode = "auto" if settings().get("auto") else "check"
            setstatus(job={"selected": "Downloading selected captures", "force": "Redownloading selected captures",
                           "cleanup": "Verifying and cleaning up local videos", "batch": f"Running batch task #{selected}",
                           "auto": "Automatically syncing videos", "check": "Checking the cloud library"}[mode],
                      progress=None)
            result = sync(mode, selected)
        except Error as exc:
            result = str(exc)
        except (OSError, ValueError, sqlite3.Error, subprocess.SubprocessError):
            result = "Task failed due to local state, the network, or credentials; try again later"
            if mode == "batch":
                try:
                    batch_status(selected, "waiting", result, delay=INTERVAL)
                except sqlite3.Error:
                    pass
        with LOCK:
            current = STATUS["progress"]
            if current:
                STATUS["progress"] = {**current, "ended": True}
            STATUS.update(job=result, busy=False,
                          last=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"))
        deadline = time.monotonic() + INTERVAL
        try:
            if ready_batch() is not None:
                deadline = time.monotonic()
        except sqlite3.Error:
            pass


def queue(mode, selected=None):
    global PENDING
    manual = ("selected", "force", "cleanup")
    priority = {None: 0, "check": 1, "auto": 2, **dict.fromkeys(manual, 3)}
    with LOCK:
        prev_mode, _ = PENDING or (None, None)
        if prev_mode in manual and mode in manual:
            raise Error("Another selection is already queued; wait until it starts")
        if priority[mode] >= priority[prev_mode]:
            PENDING = (mode, selected)
        WAKE.set()


def selected_ids(raw):
    parts = raw.split(",") if raw else []
    if not 1 <= len(parts) <= 10000 or any(not re.fullmatch(r"[a-f0-9]{64}", p) for p in parts):
        raise Error("Select at least one available cloud capture")
    with LOCK:
        if not STATUS["cloud_known"]:
            raise Error("The cloud library has not been verified; refresh it first")
        selected = {CLOUD_CACHE[p][0] for p in parts if p in CLOUD_CACHE
                    and not unavailable(CLOUD_CACHE[p][1])}
    if not selected:
        raise Error("Selected captures are no longer in the library; refresh and select them again")
    return selected


def cleanup_ids(raw):
    parts = raw.split(",") if raw else []
    if not 1 <= len(parts) <= 10000 or any(not re.fullmatch(r"[a-f0-9]{64}", p) for p in parts):
        raise Error("Select at least one uploaded local video")
    keys = set(parts)
    ids = {identifier for identifier, (kind, path, saved) in archive_history().items()
           if kind == 2 and saved and (LIBRARY / path).is_file() and preview_key(identifier) in keys}
    if not ids:
        raise Error("No uploaded local videos are eligible for cleanup")
    return ids


def archive_history():
    with database() as db:
        return {identifier: (kind, path, uploaded is not None)
                for identifier, kind, path, uploaded in db.execute(
                    "SELECT id,kind,path,uploaded_to FROM captures")}


def expected_remote_paths(row, prior):
    if prior:
        return [Path(prior[1])]
    ext_by_type = {"JPEG": ("jpg",), "JPG": ("jpg",), "PNG": ("png",),
                   "WEBP": ("webp",)}
    if row["ugcType"] == 2:
        ext = ("mp4", "webm")
    else:
        ext = ext_by_type.get(row.get("fileType"), ("jpg", "png", "webp"))
    try:
        return [Path(*names(row, suffix)) for suffix in ext]
    except Error:
        return []


def dav_probe_item(dav, paths):
    unknown = False
    for path in paths:
        if len(path.parts) != 2:
            unknown = True
            continue
        url = dav["url"] + "/".join(quote(x, safe="") for x in path.parts)
        try:
            with dav_request(dav, "HEAD", url, timeout=8) as r:
                if r.status == 200:
                    return "present"
                unknown = True
        except HTTPError as exc:
            with exc:
                if exc.code != 404:
                    unknown = True
        except (OSError, HTTPException, ValueError):
            unknown = True
    return "missing" if paths and not unknown else "unknown"


def request_dav_refresh(*, reset=False):
    global DAV_EPOCH
    with LOCK:
        if reset:
            DAV_EPOCH += 1
            DAV_CACHE.clear()
            STATUS["gallery_rev"] += 1
        DAV_WAKE.set()


def dav_state_worker():
    while True:
        DAV_WAKE.wait(INTERVAL)
        DAV_WAKE.clear()
        with LOCK:
            epoch, cloud = DAV_EPOCH, list(CLOUD_CACHE.items())
            STATUS["dav_status"] = "Checking files on WebDAV"
        results = {}
        try:
            dav = vault("webdav")
            if not dav:
                summary = "WebDAV not configured"
            else:
                dav_check(dav)
                history = archive_history()
                paths = {key: expected_remote_paths(row, history.get(identifier))
                         for key, (identifier, row, _) in cloud}
                paths.update({preview_key(k): [Path(p)] for k, (_, p, _) in history.items()
                              if preview_key(k) not in paths})
                began = time.monotonic()
                with ThreadPoolExecutor(max_workers=6) as pool:
                    keys = list(paths)
                    checks = pool.map(lambda key: dav_probe_item(dav, paths[key]), keys)
                    results = dict(zip(keys, checks))
                summary = ("Last checked " + datetime.now().astimezone().strftime("%H:%M:%S")
                           + ("; some files could not be verified" if "unknown" in results.values() else ""))
        except (Error, OSError, ValueError, KeyError, sqlite3.Error, subprocess.SubprocessError) as exc:
            summary = f"WebDAV status unknown: {exc}" if isinstance(exc, Error) else "Cannot check WebDAV status"
        with LOCK:
            if epoch != DAV_EPOCH:
                continue
            if not results:
                DAV_CACHE.clear()
            else:
                for key, value in results.items():
                    prior = DAV_CACHE.get(key)
                    if not prior or prior[1] <= began:
                        DAV_CACHE[key] = (value, began)
            STATUS["dav_status"] = summary
            STATUS["gallery_rev"] += 1


def gallery_payload():
    with LOCK:
        revision, rows = STATUS["gallery_rev"], list(CLOUD_CACHE.items())
        cloud_known, remote = STATUS["cloud_known"], dict(DAV_CACHE)
    history = archive_history()
    seen, items = set(), []
    for key, (identifier, row, _) in rows:
        seen.add(identifier)
        prior = history.get(identifier)
        title = row.get("title") or "Untitled capture"
        game, captured = capture_label(title, row.get("sceTitleName"))
        items.append(dict(key=key, kind=row["ugcType"], title=title, game=game, captured=captured,
                          date=row.get("uploadDate"), cloud=True if cloud_known else None,
                          local=bool(prior and (LIBRARY / prior[1]).is_file()),
                          saved=bool(prior and prior[2]),
                          remote=remote.get(key, ("unknown",))[0],
                          unavailable=unavailable(row), selectable=cloud_known and not unavailable(row)))
    for identifier, (kind, path, uploaded) in history.items():
        if identifier in seen:
            continue
        key = preview_key(identifier)
        cloud = False if cloud_known else None
        local = (LIBRARY / path).is_file()
        dav = remote.get(key, ("unknown",))[0]
        if cloud is False and not local and dav == "missing":
            continue
        title = Path(path).name
        game, captured = capture_label(title, Path(path).parent.name)
        items.append(dict(key=key, kind=kind, title=title, game=game, captured=captured, date=None,
                          cloud=cloud, local=local, saved=uploaded, remote=dav,
                          unavailable=False, selectable=False))
    return {"revision": revision, "items": items}


PROGRESS_SCRIPT = r"""
(() => {
  const el = (id) => document.getElementById(id);
  const text = (id, value) => { const n = el(id); if (n) n.textContent = value; };
  const csrfToken = () => el("gallery-form").elements.csrf.value;
  let toastTimer = 0;
  function showToast(msg, isError = false) {
    const t = el("toast");
    if (!t || !msg) return;
    t.textContent = msg;
    t.dataset.tone = isError ? "error" : "info";
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { t.hidden = true; }, 4500);
  }
  function format(n) {
    const units = ["B", "KiB", "MiB", "GiB"];
    let i = 0;
    for (; n >= 1024 && i < units.length - 1; i++) n /= 1024;
    return `${n.toFixed(i ? 1 : 0)} ${units[i]}`;
  }
  function bar(id, total, done) {
    const p = el(id);
    if (total > 0) { p.max = total; p.value = Math.min(done, total); }
    else p.removeAttribute("value");
  }
  async function postForm(url, params) {
    const body = new URLSearchParams({csrf: csrfToken(), ...params});
    const r = await fetch(url, {
      method: "POST",
      headers: {Accept: "application/json"},
      body,
      signal: AbortSignal.timeout(15000),
    });
    if (!r.headers.get("content-type")?.startsWith("application/json")) {
      if (r.status === 401 || r.status === 403) {
        return {ok: false, message: "The session or page expired. Refresh and try again."};
      }
      throw new Error();
    }
    const data = await r.json();
    return {ok: r.ok, ...data};
  }

  const settingsDialog = el("settings-dialog");
  function openSettings(tabName = "sony") {
    for (const btn of settingsDialog.querySelectorAll("[data-tab]")) {
      btn.setAttribute("aria-selected", btn.dataset.tab === tabName ? "true" : "false");
    }
    for (const panel of settingsDialog.querySelectorAll("[data-panel]")) {
      panel.hidden = panel.dataset.panel !== tabName;
    }
    text("settings-message", "");
    if (!settingsDialog.open) settingsDialog.showModal();
  }
  for (const trigger of document.querySelectorAll("[data-open-settings]")) {
    trigger.addEventListener("click", () => openSettings(trigger.dataset.openSettings || "sony"));
  }
  for (const btn of settingsDialog.querySelectorAll("[data-tab]")) {
    btn.addEventListener("click", () => openSettings(btn.dataset.tab));
  }
  el("settings-close").addEventListener("click", () => settingsDialog.close());
  settingsDialog.addEventListener("click", (e) => {
    if (e.target === settingsDialog) settingsDialog.close();
  });

  for (const form of settingsDialog.querySelectorAll("form")) {
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const btn = form.querySelector("button[type=submit], button:not([type])");
      if (btn) btn.disabled = true;
      text("settings-message", "Saving…");
      el("settings-message").dataset.tone = "info";
      try {
        const params = {};
        for (const [k, v] of new FormData(form).entries()) params[k] = v;
        const res = await postForm(form.getAttribute("action"), params);
        text("settings-message", res.message || (res.ok ? "Saved." : "Could not save."));
        el("settings-message").dataset.tone = res.ok ? "ok" : "error";
        if (res.ok) {
          for (const pw of form.querySelectorAll("input[type=password]")) pw.value = "";
          if (res.has_dav !== undefined) applyDavState(res.has_dav);
          showToast(res.message);
          update(true);
        }
      } catch {
        text("settings-message", "Request timed out or the connection failed. Try again later.");
        el("settings-message").dataset.tone = "error";
      } finally {
        if (btn) btn.disabled = false;
      }
    });
  }

  el("btn-check-cloud").addEventListener("click", async () => {
    const btn = el("btn-check-cloud");
    btn.disabled = true;
    try {
      const res = await postForm("/check", {});
      showToast(res.message, !res.ok);
    } catch { showToast("Cannot connect to the server.", true); }
    finally { btn.disabled = false; }
  });
  el("btn-check-dav").addEventListener("click", async () => {
    const btn = el("btn-check-dav");
    btn.disabled = true;
    try {
      const res = await postForm("/dav-refresh", {});
      showToast(res.message, !res.ok);
    } catch { showToast("Cannot connect to the server.", true); }
    finally { btn.disabled = false; }
  });
  el("auto-toggle").addEventListener("change", async () => {
    const toggle = el("auto-toggle");
    const want = toggle.checked;
    toggle.disabled = true;
    try {
      const res = await postForm("/auto", want ? {auto: "on"} : {});
      showToast(res.message, !res.ok);
      if (!res.ok) toggle.checked = !want;
    } catch {
      toggle.checked = !want;
      showToast("Could not save auto-download settings.", true);
    } finally {
      toggle.disabled = false;
    }
  });

  function applyDavState(hasDav) {
    el("gallery-form").dataset.dav = hasDav ? "1" : "0";
    const pill = el("dav-pill");
    if (pill) pill.dataset.state = hasDav ? "ok" : "warn";
    text("dav-pill-label", hasDav ? "WebDAV configured" : "WebDAV not configured");
    text("dav-config-state", hasDav ? "Configured; saved credentials are hidden" : "Not configured");
    updateSettingsAlert();
    updateSelection();
  }
  function updateSettingsAlert() {
    const psnOk = el("psn-pill")?.dataset.state === "ok";
    const davOk = el("gallery-form")?.dataset.dav === "1";
    const dot = el("settings-alert-dot");
    if (dot) dot.hidden = psnOk && davOk;
  }

  let pollTimer = 0;
  async function update(once = false) {
    if (!once) clearTimeout(pollTimer);
    try {
      if (document.hidden && !once) return;
      const r = await fetch("/status.json", {cache: "no-store", signal: AbortSignal.timeout(5000)});
      if (!r.ok) throw new Error();
      const s = await r.json(), p = s.progress;
      if (s.gallery_rev !== galleryRev) loadGallery();
      if (s.task_rev !== taskRev) loadTasks(s.task_rev);
      text("progress-connection", "");
      text("job-result", s.job);
      text("job-time", s.last);
      text("psn-auth", s.auth);
      text("psn-auth-modal", s.auth);
      const psnOk = s.auth === "Signed in";
      const psnPill = el("psn-pill");
      if (psnPill) psnPill.dataset.state = psnOk ? "ok" : (s.auth === "Checking" ? "busy" : "warn");
      if (s.has_dav !== undefined) applyDavState(s.has_dav);
      if (s.auto !== undefined && !el("auto-toggle").disabled) el("auto-toggle").checked = !!s.auto;
      const dot = el("job-dot");
      if (dot) dot.dataset.busy = s.busy ? "1" : "0";
      text("cloud-videos", s.counts ? s.counts[0] : "—");
      text("cloud-pictures", s.counts ? s.counts[1] : "—");
      text("dav-check-state", s.dav_status || "Not checked yet");
      updateSettingsAlert();
      const activeTransfer = p && (!p.ended || p.total > 0);
      el("transfer-details").hidden = !activeTransfer;
      if (!activeTransfer) return;
      text("job-items", `Processed ${p.done} / ${p.total} · Succeeded ${p.done - p.failed} · Failed ${p.failed} · Skipped ${p.skipped}`);
      el("job-bar").hidden = !p.total;
      bar("job-bar", p.total, p.done);
      el("file-details").hidden = p.ended || !p.filename;
      if (!p.ended && p.filename) {
        const percent = p.size ? ` · ${Math.min(100, Math.floor(p.bytes / p.size * 100))}%` : "";
        const speed = p.speed ? ` · ${format(p.speed)}/s` : "";
        const eta = p.size && p.speed && p.bytes < p.size
          ? ` · about ${Math.ceil((p.size - p.bytes) / p.speed)} s` : "";
        text("file-name", p.filename);
        text("file-stage", p.stage);
        text("file-size", p.size ? `${format(p.bytes)} / ${format(p.size)}${percent}${speed}${eta}`
          : p.bytes ? `${format(p.bytes)} · unknown total size${speed}` : "");
        el("file-bar").hidden = !p.size && !p.bytes;
        bar("file-bar", p.size, p.bytes);
      }
    } catch {
      text("progress-connection", "Cannot refresh status right now. The page will retry automatically.");
    } finally {
      if (!once) pollTimer = setTimeout(() => update(false), 2000);
    }
  }
  let galleryRev = -1, galleryLoading = false, submitting = false;
  let taskRev = -1, tasksLoading = false;
  let activeFilter = "all";

  el("toggle-tasks").addEventListener("click", () => {
    const panel = el("task-panel");
    const open = panel.hidden;
    panel.hidden = !open;
    el("toggle-tasks").setAttribute("aria-expanded", open ? "true" : "false");
  });
  el("clear-task-failures").addEventListener("click", async (event) => {
    if (!window.confirm("Clear failure details from completed tasks? Retryable failures will be kept.")) return;
    const button = event.currentTarget;
    button.disabled = true;
    try {
      const res = await postForm("/clear-failures", {});
      text("task-message", res.message);
      showToast(res.message, !res.ok);
    } catch { showToast("Could not clear failure history. Try again later.", true); }
    finally { button.disabled = false; }
  });

  async function loadTasks(revision) {
    if (tasksLoading) return;
    tasksLoading = true;
    try {
      const response = await fetch("/tasks.json", {cache: "no-store", signal: AbortSignal.timeout(5000)});
      if (!response.ok) return;
      const tasks = await response.json(), list = el("task-history");
      const opened = new Set([...list.querySelectorAll("details[open]")].map(d => d.dataset.task));
      let attention = 0;
      const nodes = tasks.map(task => {
        if (["ready", "running", "waiting", "paused"].includes(task.state) || task.failures.some(f => f[3])) {
          attention++;
        }
        const detail = document.createElement("details");
        detail.dataset.task = `${task.id}`;
        detail.open = opened.has(detail.dataset.task);
        const head = document.createElement("summary");
        const state = {ready:"Queued", running:"Running", waiting:"Waiting for connection", paused:"paused", finished:"Finished"};
        const counts = task.counts;
        head.textContent = `#${task.id} ${task.mode === "force" ? "Redownload" : "Download"} · ${state[task.state]} · Succeeded ${counts.done || 0} · Pending ${counts.pending || 0} · Skipped ${counts.skipped || 0} · Failed ${counts.failed || 0}`;
        detail.append(head);
        if (task.note) {
          const note = document.createElement("p");
          note.className = "task-note";
          note.textContent = task.note;
          detail.append(note);
        }
        if (!["ready", "running"].includes(task.state) &&
            (task.state === "waiting" || task.failures.some(f => f[3]))) {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "ps-btn ps-btn-primary ps-btn-sm";
          btn.textContent = task.state === "waiting" ? "Retry connection now" : "Retry recoverable failures";
          btn.addEventListener("click", async () => {
            btn.disabled = true;
            try {
              const res = await postForm("/retry-batch", {batch: task.id});
              text("task-message", res.message);
              showToast(res.message, !res.ok);
            } catch {
              text("task-message", "Could not confirm submission. Refresh the task list before trying again.");
            } finally { btn.disabled = false; }
          });
          detail.append(btn);
        }
        const failures = document.createElement("ul");
        failures.className = "task-failures";
        for (const [title, category, reason, retryable] of task.failures) {
          const li = document.createElement("li");
          li.textContent = `${title} — ${category}: ${reason}${retryable ? "（retryable）" : ""}`;
          failures.append(li);
        }
        if (task.failures.length) detail.append(failures);
        if (task.attempts.length > task.failures.length) {
          const history = document.createElement("details");
          const summary = document.createElement("summary");
          summary.textContent = "Recent failed attempts";
          history.append(summary);
          const older = document.createElement("ul");
          older.className = "task-failures";
          for (const [title, category, reason, at] of task.attempts) {
            const li = document.createElement("li");
            li.textContent = `${new Date(at * 1000).toLocaleString()} · ${title} — ${category}: ${reason}`;
            older.append(li);
          }
          history.append(older);
          detail.append(history);
        }
        return detail;
      });
      list.replaceChildren(...nodes);
      text("task-empty", tasks.length ? "" : "No batch tasks yet.");
      const badge = el("task-badge");
      if (badge) {
        badge.textContent = attention ? `${attention}` : `${tasks.length}`;
        badge.dataset.alert = attention ? "1" : "0";
        badge.hidden = !tasks.length;
      }
      taskRev = revision;
    } catch { /* Try again on the next update. */ }
    finally { tasksLoading = false; }
  }
  const cards = new Map();
  const selected = new Set();
  const canClean = (item) => item.kind === 2 && item.local && item.saved;
  function matchesFilter(item) {
    if (activeFilter === "video") return item.kind === 2;
    if (activeFilter === "photo") return item.kind === 1;
    if (activeFilter === "unsaved") return !item.saved;
    if (activeFilter === "local") return item.local;
    return true;
  }
  function applyFilter() {
    let visible = 0;
    for (const view of cards.values()) {
      const show = matchesFilter(view.item);
      view.card.hidden = !show;
      if (show) visible++;
    }
    text("gallery-empty", cards.size ? (visible ? "" : "No captures match this filter.") : "No captures yet. Try Refresh cloud.");
  }
  for (const btn of document.querySelectorAll("[data-filter]")) {
    btn.addEventListener("click", () => {
      activeFilter = btn.dataset.filter;
      for (const b of document.querySelectorAll("[data-filter]")) {
        b.setAttribute("aria-pressed", b === btn ? "true" : "false");
      }
      applyFilter();
    });
  }
  function updateSelection() {
    const keys = [...selected].filter(key => cards.has(key));
    const downloadable = keys.filter(key => cards.get(key).item.selectable).length;
    const cleanable = keys.filter(key => canClean(cards.get(key).item)).length;
    text("selection-count", `Selected ${keys.length} items · Videos eligible for cleanup: ${cleanable} files`);
    el("selection-input").value = keys.join(",");
    for (const [key, view] of cards) {
      view.card.classList.toggle("is-selected", selected.has(key));
    }
    for (const button of document.querySelectorAll("#gallery-form button[type=submit]")) {
      button.disabled = submitting || !(button.value === "cleanup" ? cleanable : downloadable) ||
        el("gallery-form").dataset.dav !== "1";
    }
  }
  function showMedia(item) {
    const element = document.createElement(item.kind === 2 ? "video" : "img");
    element.src = `/preview/${item.key}/${item.kind === 2 ? "video" : "large"}`;
    if (item.kind === 2) { element.controls = true; element.preload = "metadata"; }
    else element.alt = item.title;
    text("viewer-title", item.captured ? `${item.game} · ${item.captured}` : item.game);
    el("viewer-title").title = item.title;
    el("viewer-media").replaceChildren(element);
    el("viewer").showModal();
  }
  function makeCard(item) {
    const card = document.createElement("article");
    card.className = "capture";
    const open = document.createElement("button");
    open.type = "button"; open.className = "preview"; open.title = "Open preview";
    const img = document.createElement("img");
    img.loading = "lazy"; img.alt = item.title; img.hidden = true;
    open.append(img);
    const kind = document.createElement("span");
    kind.className = "capture-kind"; kind.textContent = item.kind === 2 ? "▶ Videos" : "Screenshots";
    open.append(kind);
    const badge = document.createElement("span");
    badge.className = "capture-badge"; open.append(badge);
    const body = document.createElement("div");
    body.className = "capture-body";
    const label = document.createElement("label");
    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.addEventListener("change", () => {
      if (checkbox.checked) selected.add(item.key); else selected.delete(item.key);
      updateSelection();
    });
    const name = document.createElement("span"); name.className = "capture-name";
    const game = document.createElement("span"); game.className = "capture-game";
    const captured = document.createElement("small");
    name.append(game, captured);
    label.append(checkbox, name);
    const states = document.createElement("div");
    states.className = "capture-states";
    const chips = Array.from({length: 4}, () => document.createElement("span"));
    for (const row of [[chips[0], chips[2]], [chips[1], chips[3]]]) {
      const line = document.createElement("div");
      line.append(...row);
      states.append(line);
    }
    body.append(label, states);
    card.append(open, body);
    el("capture-grid").append(card);
    const view = {card, checkbox, badge, open, img, chips, item, name, game, captured, thumbMode: ""};
    open.addEventListener("click", () => showMedia(view.item));
    return view;
  }
  async function loadGallery() {
    if (galleryLoading) return;
    galleryLoading = true;
    try {
      const r = await fetch("/gallery.json", {cache: "no-store", signal: AbortSignal.timeout(5000)});
      if (!r.ok) return;
      const result = await r.json();
      const incoming = new Set(result.items.map(item => item.key));
      for (const [key, view] of cards) {
        if (!incoming.has(key)) { view.card.remove(); cards.delete(key); selected.delete(key); }
      }
      for (const item of result.items) {
        const view = cards.get(item.key) || makeCard(item);
        if (!cards.has(item.key)) cards.set(item.key, view);
        view.item = item;
        view.name.title = item.title;
        view.game.textContent = item.game;
        view.captured.textContent = item.captured || "";
        view.captured.hidden = !item.captured;
        view.badge.textContent = item.saved ? "✓ Uploaded" : "";
        view.badge.hidden = !view.badge.textContent;
        view.checkbox.disabled = !item.selectable && !canClean(item);
        view.open.disabled = (!item.cloud || item.unavailable) && !item.local;
        const thumb = item.cloud ? "cloud" : item.local && item.kind === 1 ? "local" : "";
        if (view.thumbMode !== thumb) {
          view.thumbMode = thumb;
          view.img.hidden = !thumb;
          if (thumb) view.img.src = `/preview/${item.key}/thumb`;
          else view.img.removeAttribute("src");
        }
        const states = [
          ["Cloud", item.cloud === null ? null : item.cloud && !item.unavailable, item.unavailable ? "Not uploaded by PlayStation" : ""],
          ["Local", item.local, ""],
          ["Upload history", item.saved, ""],
          ["Backup file", item.remote === "present" ? true : item.remote === "missing" ? false : null, ""]
        ];
        states.forEach(([label, state, reason], i) => {
          const meaning = reason || (state === true ? "Yes" : state === false ? "No" : "Unknown");
          view.chips[i].textContent = `${state === true ? "✅" : state === false ? "❎" : "❔"}${label}`;
          view.chips[i].title = `${label}: ${meaning}`;
          view.chips[i].setAttribute("aria-label", `${label}: ${meaning}`);
        });
        if (view.checkbox.disabled) selected.delete(item.key);
        view.checkbox.checked = selected.has(item.key);
      }
      galleryRev = result.revision;
      applyFilter();
      updateSelection();
    } catch { /* Retry on the next update. */ }
    finally { galleryLoading = false; }
  }
  el("select-all").addEventListener("click", () => {
    for (const [key, view] of cards) if (!view.card.hidden && !view.checkbox.disabled) {
      selected.add(key); view.checkbox.checked = true;
    }
    updateSelection();
  });
  el("clear-selection").addEventListener("click", () => {
    selected.clear();
    for (const view of cards.values()) view.checkbox.checked = false;
    updateSelection();
  });
  el("select-cleanup").addEventListener("click", () => {
    selected.clear();
    for (const [key, view] of cards) {
      view.checkbox.checked = !view.card.hidden && canClean(view.item);
      if (view.checkbox.checked) selected.add(key);
    }
    updateSelection();
  });
  el("gallery-form").addEventListener("submit", async (event) => {
    event.preventDefault();
    const mode = event.submitter?.value;
    const eligible = [...selected].filter(key => cards.has(key) &&
      (mode === "cleanup" ? canClean(cards.get(key).item) : cards.get(key).item.selectable));
    if (!mode || !eligible.length || submitting) return;
    if (mode === "force" &&
        !window.confirm(`Redownload the selected ${eligible.length} captures?`)) return;
    if (mode === "cleanup" &&
        !window.confirm(`Permanently delete the selected ${eligible.length} local videos after verifying their WebDAV copies? Sony and WebDAV files will not be deleted.`)) return;
    submitting = true;
    updateSelection();
    text("selection-message", "Submitting task…");
    try {
      const res = await postForm("/selected", {mode, selection: eligible.join(",")});
      text("selection-message", res.message);
      showToast(res.message, !res.ok);
    } catch {
      text("selection-message", "Could not confirm submission. Check transfer activity before retrying.");
    } finally {
      submitting = false;
      updateSelection();
    }
  });
  el("viewer-close").addEventListener("click", () => el("viewer").close());
  el("viewer").addEventListener("click", (e) => { if (e.target === el("viewer")) el("viewer").close(); });
  el("viewer").addEventListener("close", () => el("viewer-media").replaceChildren());
  update();
})();
""".encode()


def page(message=""):
    with LOCK:
        st = dict(STATUS)
    video, pic = st["counts"] or ("—", "—")
    checked = "checked" if settings().get("auto") else ""
    has_dav = (STATE / "webdav.cred").is_file()
    configured = "Configured; saved credentials are hidden" if has_dav else "Not configured"
    psn_state = "ok" if st["auth"] == "Signed in" else ("busy" if st["auth"] == "Checking" else "warn")
    dav_state = "ok" if has_dav else "warn"
    alert_hidden = " hidden" if (psn_state == "ok" and has_dav) else ""
    esc = html.escape
    csrf = f'<input type="hidden" name="csrf" value="{CSRF}">'
    notice = f'<p class="banner" role="status">{esc(message)}</p>' if message else ""
    has_admin = (STATE / "admin-verifier.json").is_file()
    admin_tab = '<button type="button" role="tab" data-tab="admin" aria-selected="false">Admin account</button>' if has_admin else ""
    admin_panel = ""
    if has_admin:
        username = esc(admin_verifier()[0])
        admin_panel = f"""<div class="settings-panel" data-panel="admin" hidden>
<h3>Admin account and password</h3>
<p class="panel-desc">This changes only the web admin login, not SSH, Sony, or WebDAV.</p>
<form method="post" action="/admin">{csrf}
<label class="field"><span>New username</span><input name="username" autocomplete="username" value="{username}" required maxlength="32" pattern="[A-Za-z0-9_.\\-]+"></label>
<label class="field"><span>Current admin password</span><input name="current_password" type="password" autocomplete="current-password" required></label>
<label class="field"><span>New password (at least 12 characters)</span><input name="new_password" type="password" autocomplete="new-password" minlength="12" required></label>
<label class="field"><span>Confirm new password</span><input name="confirm_password" type="password" autocomplete="new-password" minlength="12" required></label>
<button class="ps-btn ps-btn-primary">Update admin account</button></form></div>"""
    return f"""<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>PS5 Media Gallery</title><style>
:root{{
  --bg:#060b16; --surface:rgba(16,24,42,.82); --card:rgba(22,33,56,.88);
  --card-hover:rgba(30,44,74,.96); --line:rgba(255,255,255,.1);
  --text:#f3f6fc; --muted:#97a6c2; --ps-blue:#0070d1; --ps-glow:#3b9eff;
  --ok:#22c55e; --warn:#f59e0b; --danger:#ef4444;
}}
*{{box-sizing:border-box}}
body{{
  margin:0; min-height:100vh; color:var(--text);
  font:15px/1.5 system-ui,sans-serif;
  background:
    radial-gradient(ellipse 85% 48% at 50% -12%, rgba(0,112,209,.32), transparent 65%),
    radial-gradient(circle at 92% 85%, rgba(0,67,156,.18), transparent 45%),
    linear-gradient(180deg, #081224 0%, #050912 100%);
  background-attachment:fixed;
}}
a{{color:var(--ps-glow)}}
[hidden]{{display:none !important}}
.topbar{{
  position:sticky; top:0; z-index:30;
  background:rgba(7,13,26,.82); backdrop-filter:blur(18px); -webkit-backdrop-filter:blur(18px);
  border-bottom:1px solid var(--line);
}}
.topbar-inner{{
  max-width:1440px; margin:0 auto; padding:.75rem 1.25rem;
  display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:.75rem 1.25rem;
}}
.brand-group{{display:flex; flex-wrap:wrap; align-items:center; gap:.75rem}}
.brand{{display:flex; align-items:center; gap:.6rem; font-size:1.1rem; font-weight:500; letter-spacing:.02em; margin:0}}
.brand-mark{{
  width:2rem; height:2rem; border-radius:.55rem; display:grid; place-items:center;
  background:linear-gradient(135deg, #0070d1, #003b8e);
  box-shadow:0 4px 14px rgba(0,112,209,.45);
}}
.brand-mark svg{{width:1.15rem; height:1.15rem; fill:white}}
.status-pills{{display:flex; flex-wrap:wrap; align-items:center; gap:.45rem}}
.pill{{
  display:inline-flex; align-items:center; gap:.4rem; padding:.3rem .72rem;
  border-radius:999px; font-size:.82rem; color:var(--text);
  background:rgba(255,255,255,.06); border:1px solid var(--line);
}}
button.pill{{cursor:pointer; font:inherit; font-size:.82rem; transition:.18s ease}}
button.pill:hover{{background:rgba(255,255,255,.12); border-color:rgba(255,255,255,.28)}}
.dot{{width:.5rem; height:.5rem; border-radius:50%; background:var(--muted); flex-shrink:0}}
.pill[data-state=ok] .dot{{background:var(--ok); box-shadow:0 0 8px rgba(34,197,94,.6)}}
.pill[data-state=warn] .dot{{background:var(--warn); box-shadow:0 0 8px rgba(245,158,11,.6)}}
.pill[data-state=busy] .dot{{background:var(--ps-glow)}}
.header-actions{{display:flex; flex-wrap:wrap; align-items:center; gap:.5rem}}
.switch-pill{{
  display:inline-flex; align-items:center; gap:.5rem; padding:.32rem .75rem;
  border-radius:999px; background:rgba(255,255,255,.06); border:1px solid var(--line);
  font-size:.84rem; cursor:pointer; user-select:none;
}}
.switch-pill input{{
  appearance:none; width:2.1rem; height:1.15rem; border-radius:999px; margin:0;
  background:rgba(255,255,255,.2); position:relative; cursor:pointer; transition:.2s ease;
}}
.switch-pill input::after{{
  content:""; position:absolute; top:.14rem; left:.16rem; width:.86rem; height:.86rem;
  border-radius:50%; background:white; transition:.2s ease;
}}
.switch-pill input:checked{{background:var(--ps-blue)}}
.switch-pill input:checked::after{{transform:translateX(.92rem)}}
.ps-btn{{
  display:inline-flex; align-items:center; justify-content:center; gap:.35rem;
  padding:.46rem .95rem; border-radius:999px; border:1px solid rgba(255,255,255,.16);
  background:rgba(255,255,255,.08); color:var(--text); font:inherit; font-size:.86rem;
  text-decoration:none; cursor:pointer; transition:all .18s ease; position:relative;
}}
.ps-btn:hover:not(:disabled){{
  background:rgba(255,255,255,.16); border-color:rgba(255,255,255,.5);
  box-shadow:0 0 14px rgba(59,158,255,.22);
}}
.ps-btn:focus-visible{{outline:2px solid white; outline-offset:2px}}
.ps-btn:disabled{{opacity:.38; cursor:not-allowed}}
.ps-btn-primary{{
  background:linear-gradient(135deg, #0078e2, #0057b8); border-color:rgba(120,192,255,.55);
  color:white; font-weight:500;
}}
.ps-btn-primary:hover:not(:disabled){{
  background:linear-gradient(135deg, #1289f5, #0064d1); border-color:white;
  box-shadow:0 0 18px rgba(0,112,209,.55);
}}
.ps-btn-danger{{
  border-color:rgba(239,68,68,.42); color:#fecaca; background:rgba(239,68,68,.12);
}}
.ps-btn-danger:hover:not(:disabled){{
  background:rgba(239,68,68,.26); border-color:#f87171; box-shadow:0 0 14px rgba(239,68,68,.32);
}}
.ps-btn-sm{{padding:.34rem .75rem; font-size:.8rem}}
.alert-dot{{
  width:.48rem; height:.48rem; border-radius:50%; background:var(--warn);
  box-shadow:0 0 8px var(--warn);
}}
.badge-count{{
  display:inline-flex; align-items:center; justify-content:center; min-width:1.25rem;
  height:1.25rem; padding:0 .35rem; border-radius:999px; font-size:.74rem;
  background:rgba(255,255,255,.16); color:white;
}}
.badge-count[data-alert="1"]{{background:var(--warn); color:#09111f; font-weight:600}}
.shell{{max-width:1440px; margin:0 auto; padding:1rem 1.25rem 2.5rem}}
.banner{{
  margin:0 0 1rem; padding:.75rem 1rem; border-radius:.85rem;
  background:rgba(0,112,209,.2); border:1px solid rgba(59,158,255,.45);
}}
.status-strip{{
  background:var(--surface); border:1px solid var(--line); border-radius:1rem;
  padding:.8rem 1.05rem; margin-bottom:1.1rem; backdrop-filter:blur(12px);
}}
.strip-row{{
  display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:.75rem;
}}
.job-summary{{display:flex; align-items:center; gap:.65rem; min-width:0; flex:1}}
.job-dot{{width:.58rem; height:.58rem; border-radius:50%; background:var(--ok); flex-shrink:0}}
.job-dot[data-busy="1"]{{background:var(--ps-glow); box-shadow:0 0 10px var(--ps-glow)}}
.job-text{{min-width:0}}
.job-text strong{{display:block; font-weight:500; font-size:.92rem; overflow-wrap:anywhere}}
.job-meta{{display:flex; flex-wrap:wrap; gap:.4rem .85rem; color:var(--muted); font-size:.78rem}}
.progress-box{{
  margin-top:.8rem; padding-top:.8rem; border-top:1px solid var(--line);
  display:grid; gap:.55rem;
}}
.progress-line{{display:flex; flex-wrap:wrap; justify-content:space-between; gap:.4rem; font-size:.82rem; color:var(--muted)}}
.progress-line strong{{color:var(--text); font-weight:500}}
#file-name{{overflow-wrap:anywhere; color:var(--text)}}
progress{{
  width:100%; height:.55rem; appearance:none; border:0; border-radius:999px;
  overflow:hidden; background:rgba(255,255,255,.1);
}}
progress::-webkit-progress-bar{{background:rgba(255,255,255,.1); border-radius:999px}}
progress::-webkit-progress-value{{background:linear-gradient(90deg,#0070d1,#4db2ff); border-radius:999px}}
progress::-moz-progress-bar{{background:linear-gradient(90deg,#0070d1,#4db2ff); border-radius:999px}}
.task-panel{{margin-top:.85rem; padding-top:.85rem; border-top:1px solid var(--line)}}
.task-panel details{{
  background:rgba(255,255,255,.04); border:1px solid var(--line); border-radius:.75rem;
  padding:.6rem .85rem; margin:.45rem 0;
}}
.task-panel summary{{cursor:pointer; font-size:.86rem}}
.task-note{{margin:.45rem 0; color:var(--muted); font-size:.83rem}}
.task-failures{{margin:.5rem 0 0; padding-left:1.2rem; color:#fca5a5; font-size:.82rem}}
.gallery-section{{
  background:var(--surface); border:1px solid var(--line); border-radius:1.15rem;
  padding:1rem 1.15rem 1.25rem;
}}
.gallery-toolbar{{
  display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:.75rem;
  padding-bottom:.9rem; border-bottom:1px solid var(--line);
}}
.filter-tabs{{display:flex; flex-wrap:wrap; gap:.35rem}}
.filter-tab{{
  padding:.36rem .82rem; border-radius:999px; border:1px solid transparent;
  background:transparent; color:var(--muted); font:inherit; font-size:.85rem; cursor:pointer;
  transition:.16s ease;
}}
.filter-tab:hover{{color:var(--text); background:rgba(255,255,255,.07)}}
.filter-tab[aria-pressed=true]{{
  background:white; color:#071122; font-weight:500; box-shadow:0 2px 12px rgba(255,255,255,.22);
}}
.action-bar{{
  display:flex; flex-wrap:wrap; align-items:center; justify-content:space-between; gap:.65rem;
  margin-top:.85rem;
}}
.action-group{{display:flex; flex-wrap:wrap; align-items:center; gap:.45rem}}
.selection-meta{{color:var(--muted); font-size:.83rem; margin-left:.2rem}}
#selection-message{{margin:.45rem 0 0; font-size:.84rem; color:var(--ps-glow); min-height:1.2em}}
.captures{{
  display:grid; grid-template-columns:repeat(auto-fill,minmax(220px,1fr));
  gap:1rem; margin-top:.9rem;
}}
.capture{{
  min-width:0; background:var(--card); border:1px solid var(--line); border-radius:.9rem;
  overflow:hidden; transition:transform .18s ease, border-color .18s ease, box-shadow .18s ease;
}}
.capture:hover{{
  transform:translateY(-2px); background:var(--card-hover);
  border-color:rgba(255,255,255,.32); box-shadow:0 10px 26px rgba(0,0,0,.42);
}}
.capture.is-selected{{
  border-color:white;
  box-shadow:0 0 0 1px rgba(255,255,255,.9), 0 0 22px rgba(0,112,209,.55);
}}
.preview{{
  position:relative; display:block; width:100%; aspect-ratio:16/9; margin:0; padding:0;
  background:#0a1326; overflow:hidden; border:0; border-radius:0; cursor:pointer;
}}
.preview:disabled{{cursor:default; opacity:.65}}
.preview img{{width:100%; height:100%; object-fit:cover; display:block; transition:transform .28s ease}}
.capture:hover .preview:not(:disabled) img{{transform:scale(1.03)}}
.preview::after{{
  content:""; position:absolute; inset:auto 0 0 0; height:42%;
  background:linear-gradient(transparent, rgba(5,10,22,.72)); pointer-events:none;
}}
.capture-kind,.capture-badge{{
  position:absolute; z-index:2; padding:.18rem .46rem; border-radius:999px;
  font-size:.7rem; color:white; backdrop-filter:blur(8px);
}}
.capture-kind{{left:.45rem; bottom:.45rem; background:rgba(8,15,30,.72); border:1px solid rgba(255,255,255,.15)}}
.capture-badge{{right:.45rem; top:.45rem; background:rgba(16,120,76,.86); border:1px solid rgba(110,231,183,.35)}}
.capture-body{{padding:.6rem .68rem .68rem}}
.capture label{{display:flex; gap:.5rem; align-items:flex-start; cursor:pointer}}
.capture input[type=checkbox]{{
  width:1.05rem; height:1.05rem; margin:.16rem 0 0; accent-color:var(--ps-blue); flex-shrink:0; cursor:pointer;
}}
.capture-name{{min-width:0; flex:1}}
.capture-game,.capture-name small:not([hidden]){{
  display:block; overflow:hidden; white-space:nowrap; text-overflow:ellipsis;
}}
.capture-game{{font-size:.86rem; font-weight:400; color:var(--text)}}
.capture-name small{{font-size:.77rem; color:var(--muted); font-variant-numeric:tabular-nums; margin-top:.08rem}}
.capture-states{{
  display:grid; gap:.2rem; margin-top:.5rem; padding-top:.45rem;
  border-top:1px solid rgba(255,255,255,.07); color:#c9d6eb; font-size:.74rem;
}}
.capture-states div{{display:grid; grid-template-columns:4.8em 1fr; gap:.45rem; white-space:nowrap}}
.gallery-footer{{margin-top:1rem; color:var(--muted); font-size:.8rem}}
.empty-note{{color:var(--muted); font-size:.9rem; margin:.9rem 0}}
dialog{{
  padding:0; color:var(--text); background:#0c1528; border:1px solid rgba(255,255,255,.16);
  border-radius:1.15rem; box-shadow:0 24px 64px rgba(0,0,0,.72); max-width:min(95vw,66rem);
}}
dialog::backdrop{{background:rgba(3,7,16,.78); backdrop-filter:blur(6px)}}
.viewer-box{{padding:1rem 1.15rem 1.15rem}}
.viewer-head{{display:flex; align-items:center; justify-content:space-between; gap:1rem; margin-bottom:.75rem}}
#viewer-media img,#viewer-media video{{display:block; max-width:100%; max-height:76vh; margin:auto; border-radius:.65rem; background:black}}
#settings-dialog{{width:min(94vw,48rem)}}
.settings-shell{{display:grid; grid-template-columns:12.5rem 1fr; min-height:24rem}}
.settings-nav{{
  background:rgba(6,11,22,.72); border-right:1px solid var(--line); padding:1rem .75rem;
  display:flex; flex-direction:column; gap:.35rem;
}}
.settings-nav h2{{font-size:.95rem; font-weight:500; margin:.2rem .55rem .7rem; color:var(--muted)}}
.settings-nav button{{
  text-align:left; padding:.58rem .78rem; border-radius:.65rem; border:1px solid transparent;
  background:transparent; color:var(--muted); font:inherit; font-size:.88rem; cursor:pointer;
}}
.settings-nav button:hover{{background:rgba(255,255,255,.06); color:var(--text)}}
.settings-nav button[aria-selected=true]{{
  background:rgba(0,112,209,.25); border-color:rgba(59,158,255,.55); color:white; font-weight:500;
}}
.settings-main{{padding:1.1rem 1.3rem 1.3rem; display:flex; flex-direction:column}}
.settings-top{{display:flex; justify-content:space-between; align-items:center; margin-bottom:.6rem}}
.settings-panel h3{{margin:.1rem 0 .35rem; font-size:1.05rem; font-weight:500}}
.panel-desc{{margin:0 0 .9rem; color:var(--muted); font-size:.84rem}}
.step-links{{display:flex; flex-wrap:wrap; gap:.55rem; margin-bottom:1rem}}
.field{{display:block; margin-bottom:.8rem}}
.field span{{display:block; font-size:.82rem; color:var(--muted); margin-bottom:.28rem}}
.field input{{
  width:100%; padding:.58rem .75rem; border-radius:.6rem; color:var(--text);
  background:rgba(5,10,22,.75); border:1px solid rgba(255,255,255,.16); font:inherit;
}}
.field input:focus{{outline:2px solid var(--ps-glow); border-color:transparent}}
.check-field{{display:flex; gap:.5rem; align-items:center; margin:.4rem 0 1rem; font-size:.83rem; color:var(--muted); cursor:pointer}}
.check-field input{{accent-color:var(--ps-blue); width:1rem; height:1rem}}
#settings-message{{min-height:1.25em; margin:.7rem 0 0; font-size:.84rem; color:var(--ps-glow)}}
#settings-message[data-tone=ok]{{color:#86efac}}
#settings-message[data-tone=error]{{color:#fca5a5}}
#toast{{
  position:fixed; right:1.2rem; bottom:1.2rem; z-index:60; max-width:min(90vw,24rem);
  padding:.72rem 1rem; border-radius:.85rem; background:rgba(12,22,42,.95);
  border:1px solid rgba(59,158,255,.55); color:white; font-size:.86rem;
  box-shadow:0 12px 32px rgba(0,0,0,.55);
}}
#toast[data-tone=error]{{border-color:rgba(239,68,68,.7); color:#fecaca}}
@media (max-width:740px){{
  .topbar-inner,.shell{{padding-left:.85rem; padding-right:.85rem}}
  .captures{{grid-template-columns:repeat(auto-fill,minmax(160px,1fr)); gap:.7rem}}
  .settings-shell{{grid-template-columns:1fr}}
  .settings-nav{{border-right:0; border-bottom:1px solid var(--line); flex-direction:row; flex-wrap:wrap; align-items:center}}
  .settings-nav h2{{width:100%; margin-bottom:.3rem}}
}}
</style>
<header class="topbar"><div class="topbar-inner">
  <div class="brand-group">
    <h1 class="brand"><span class="brand-mark" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M4 6a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6zm6 3.5v5l4.5-2.5L10 9.5z"/></svg></span>PS5 Media Gallery</h1>
    <div class="status-pills">
      <button type="button" class="pill" id="psn-pill" data-state="{psn_state}" data-open-settings="sony" title="Open Sony sign-in settings"><span class="dot"></span>PSN <strong id="psn-auth">{esc(st['auth'])}</strong></button>
      <button type="button" class="pill" id="dav-pill" data-state="{dav_state}" data-open-settings="dav" title="Open WebDAV settings"><span class="dot"></span><span id="dav-pill-label">{"WebDAV configured" if has_dav else "WebDAV not configured"}</span></button>
      <span class="pill">Videos <strong id="cloud-videos">{video}</strong> · Screenshots <strong id="cloud-pictures">{pic}</strong></span>
    </div>
  </div>
  <div class="header-actions">
    <label class="switch-pill" title="Check for newly uploaded videos every five minutes"><input type="checkbox" id="auto-toggle" {checked}><span>Auto-download videos</span></label>
    <button type="button" class="ps-btn ps-btn-sm" id="btn-check-cloud">Refresh cloud</button>
    <button type="button" class="ps-btn ps-btn-sm" id="btn-check-dav">Check WebDAV</button>
    <button type="button" class="ps-btn ps-btn-primary ps-btn-sm" data-open-settings="sony">System Settings<span class="alert-dot" id="settings-alert-dot"{alert_hidden}></span></button>
  </div>
</div></header>

<main class="shell">{notice}
<section class="status-strip" aria-label="Transfer activity and task history">
  <div class="strip-row">
    <div class="job-summary">
      <span class="job-dot" id="job-dot" data-busy="{int(st['busy'])}"></span>
      <div class="job-text">
        <strong id="job-result">{esc(st['job'])}</strong>
        <div class="job-meta">
          <span>Last updated: <span id="job-time">{esc(st['last'])}</span></span>
          <span>WebDAV: <span id="dav-check-state">{esc(st['dav_status'])}</span></span>
          <span id="progress-connection"></span>
        </div>
      </div>
    </div>
    <button type="button" class="ps-btn ps-btn-sm" id="toggle-tasks" aria-expanded="false">Task history <span class="badge-count" id="task-badge" hidden>0</span></button>
  </div>
  <div id="transfer-details" class="progress-box" hidden>
    <div class="progress-line"><strong id="job-items"></strong></div>
    <progress id="job-bar" aria-label="Overall task progress"></progress>
    <div id="file-details" hidden>
      <div class="progress-line"><strong id="file-stage"></strong><span id="file-size"></span></div>
      <div class="progress-line"><span id="file-name"></span></div>
      <progress id="file-bar" aria-label="Current file progress"></progress>
    </div>
  </div>
  <div id="task-panel" class="task-panel" hidden>
    <button type="button" class="ps-btn ps-btn-sm" id="clear-task-failures">Clear failure history</button>
    <p id="task-message" role="status"></p>
    <p id="task-empty" class="empty-note">Loading tasks…</p>
    <div id="task-history"></div>
  </div>
</section>

<section class="gallery-section">
  <div class="gallery-toolbar">
    <div class="filter-tabs" role="group" aria-label="Filter captures">
      <button type="button" class="filter-tab" data-filter="all" aria-pressed="true">All</button>
      <button type="button" class="filter-tab" data-filter="video" aria-pressed="false">Videos</button>
      <button type="button" class="filter-tab" data-filter="photo" aria-pressed="false">Screenshots</button>
      <button type="button" class="filter-tab" data-filter="unsaved" aria-pressed="false">Not uploaded</button>
      <button type="button" class="filter-tab" data-filter="local" aria-pressed="false">On this device</button>
    </div>
    <div class="action-group">
      <button type="button" class="ps-btn ps-btn-sm" id="select-all">Select all</button>
      <button type="button" class="ps-btn ps-btn-sm" id="select-cleanup">Select cleanable videos</button>
      <button type="button" class="ps-btn ps-btn-sm" id="clear-selection">Clear selection</button>
      <span class="selection-meta" id="selection-count">Selected 0 items</span>
    </div>
  </div>
  <form method="post" id="gallery-form" action="/selected" data-dav="{int(has_dav)}">{csrf}
    <input type="hidden" name="selection" id="selection-input">
    <div class="action-bar">
      <div class="action-group">
        <button type="submit" class="ps-btn ps-btn-primary" name="mode" value="selected" disabled>Download selected</button>
        <button type="submit" class="ps-btn" name="mode" value="force" disabled>Force redownload</button>
        <button type="submit" class="ps-btn ps-btn-danger" name="mode" value="cleanup" disabled>Delete local videos</button>
      </div>
      <span id="selection-message" role="status"></span>
    </div>
  </form>
  <p id="gallery-empty" class="empty-note">Loading captures…</p>
  <div class="captures" id="capture-grid"></div>
  <footer class="gallery-footer">Only captures still in the Sony cloud can be downloaded. Cleanup removes local videos only after verifying their WebDAV copies; screenshots, WebDAV files, and history are kept.</footer>
</section>
</main>

<dialog id="viewer"><div class="viewer-box">
  <div class="viewer-head"><strong id="viewer-title"></strong><button id="viewer-close" class="ps-btn ps-btn-sm" type="button">Close</button></div>
  <div id="viewer-media"></div>
</div></dialog>

<dialog id="settings-dialog" aria-label="System settings"><div class="settings-shell">
  <nav class="settings-nav" role="tablist">
    <h2>System Settings</h2>
    <button type="button" role="tab" data-tab="sony" aria-selected="true">Sony sign-in</button>
    <button type="button" role="tab" data-tab="dav" aria-selected="false">WebDAV storage</button>
    {admin_tab}
  </nav>
  <div class="settings-main">
    <div class="settings-top"><span class="panel-desc" style="margin:0">Accounts and storage</span><button type="button" class="ps-btn ps-btn-sm" id="settings-close">Close</button></div>
    <div class="settings-panel" data-panel="sony">
      <h3>Sony sign-in</h3>
      <p class="panel-desc">Current status: <strong id="psn-auth-modal">{esc(st['auth'])}</strong>.After signing in, copy the npsso value from the JSON and import it.</p>
      <div class="step-links">
        <a class="ps-btn ps-btn-sm" target="_blank" rel="noopener noreferrer" href="https://id.sonyentertainmentnetwork.com/id/management_ca/">1. Sign in to Sony</a>
        <a class="ps-btn ps-btn-sm" target="_blank" rel="noopener noreferrer" href="https://ca.account.sony.com/api/v1/ssocookie">2. Open Sony session endpoint</a>
      </div>
      <form method="post" action="/login">{csrf}
        <label class="field"><span>3. Paste the npsso value</span><input name="npsso" type="password" autocomplete="off" required maxlength="4096"></label>
        <button class="ps-btn ps-btn-primary">Import session</button>
      </form>
    </div>
    <div class="settings-panel" data-panel="dav" hidden>
      <h3>WebDAV storage settings</h3>
      <p class="panel-desc"><span id="dav-config-state">{configured}</span>.Manual and automatic downloads require WebDAV. Upload failures pause further downloads.</p>
      <form method="post" action="/dav">{csrf}
        <label class="field"><span>Destination folder URL</span><input name="url" type="url" placeholder="https://nas.example/dav/PS5/" required></label>
        <label class="field"><span>Username</span><input name="user" autocomplete="off" required></label>
        <label class="field"><span>Password</span><input name="password" type="password" autocomplete="new-password" required></label>
        <label class="check-field"><input type="checkbox" name="allow_http"><span>Allow LAN HTTP (credentials are not encrypted)</span></label>
        <button class="ps-btn ps-btn-primary">Test and save</button>
      </form>
    </div>
    {admin_panel}
    <p id="settings-message" role="status"></p>
  </div>
</div></dialog>

<div id="toast" role="status" hidden></div>
<script src="/progress.js" defer></script></html>""".encode()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def reply(self, status=200, notice=""):
        self.send_data(page(notice), "text/html; charset=utf-8", status=status)

    def redirect_home(self):
        self.send_response(303)
        self.send_header("Location", "/")
        self.send_header("Content-Length", "0")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()

    def form_reply(self, status=200, notice=""):
        if self.headers.get("Accept") == "application/json":
            payload = {"message": notice, "has_dav": (STATE / "webdav.cred").is_file(),
                       "auto": bool(settings().get("auto"))}
            self.send_data(json.dumps(payload).encode(), "application/json", status=status)
        elif self.path == "/selected" and status == 200:
            self.redirect_home()
        else:
            self.reply(status, notice)

    def send_data(self, data, content_type, *, status=200):
        self.send_response(status)
        for name, value in {
            "Content-Type": content_type, "Content-Length": str(len(data)),
            "Cache-Control": "no-store", "Referrer-Policy": "same-origin",
            "X-Content-Type-Options": "nosniff", "Cross-Origin-Resource-Policy": "same-origin",
            "Content-Security-Policy": "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; media-src 'self'; style-src 'unsafe-inline'; form-action 'self'; base-uri 'none'; frame-ancestors 'none'",
        }.items():
            self.send_header(name, value)
        try:
            self.end_headers()
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError, ssl.SSLEOFError):
            pass

    def permitted(self):
        host = self.headers.get("Host")
        if not getattr(self.server, "lan", False):
            return host in HOSTS
        return host in {f"{self.connection.getsockname()[0]}:{PORT}",
                        f"{self.server.dns_name}:{PORT}"}

    def authenticated(self):
        if not getattr(self.server, "lan", False):
            return True
        try:
            auth = self.headers.get("Authorization", "")
            if auth.startswith("Basic ") and len(auth) <= 400:
                user, sep, password = base64.b64decode(auth[6:], validate=True).partition(b":")
                if sep and admin_matches(user, password, admin_verifier()):
                    return True
        except (OSError, ValueError, KeyError):
            pass
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="PS5 Administration", charset="UTF-8"')
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", "0")
        self.end_headers()
        return False

    def do_GET(self):
        preview = re.fullmatch(r"/preview/([a-f0-9]{64})/(thumb|large|video)", self.path)
        if not self.permitted() or (not preview and
                self.path not in ("/", "/selected", "/status.json", "/progress.js", "/gallery.json", "/tasks.json")):
            self.send_error(404)
            return
        if not self.authenticated():
            return
        if preview:
            if not PREVIEW_SLOTS.acquire(blocking=False):
                self.send_error(503)
                return
            try:
                self.serve_preview(*preview.groups())
            finally:
                PREVIEW_SLOTS.release()
        elif self.path == "/selected":
            self.redirect_home()
        elif self.path == "/gallery.json":
            try:
                self.send_data(json.dumps(gallery_payload()).encode(), "application/json")
            except sqlite3.Error:
                self.send_error(503)
        elif self.path == "/tasks.json":
            try:
                self.send_data(json.dumps(task_payload()).encode(), "application/json")
            except sqlite3.Error:
                self.send_error(503)
        elif self.path == "/status.json":
            with LOCK:
                snapshot = dict(STATUS)
            if snapshot["progress"]:
                snapshot["progress"] = {k: v for k, v in snapshot["progress"].items()
                                        if k not in ("sampled", "started")}
            snapshot["has_dav"] = (STATE / "webdav.cred").is_file()
            snapshot["auto"] = bool(settings().get("auto"))
            self.send_data(json.dumps(snapshot).encode(), "application/json")
        elif self.path == "/progress.js":
            self.send_data(PROGRESS_SCRIPT, "text/javascript; charset=utf-8")
        else:
            self.reply()

    def serve_preview(self, key, variant):
        with LOCK:
            entry = CLOUD_CACHE.get(key)
        if not entry:
            if not self.serve_local_preview(key, variant):
                self.send_error(404)
            return
        _, row, headers = entry
        if variant == "video" and row["ugcType"] != 2:
            self.send_error(404)
            return
        order = {"thumb": ("smallPreviewImage", "largePreviewImage", "screenshotUrl"),
                 "large": ("largePreviewImage", "screenshotUrl", "smallPreviewImage"),
                 "video": ("downloadUrl",)}[variant]
        image_types = {"image/jpeg", "image/png", "image/webp", "image/avif"}
        video_types = {"video/mp4", "video/webm"}
        range_value = self.headers.get("Range", "")
        send_headers = {}
        if variant == "video" and re.fullmatch(r"bytes=\d{1,15}-\d{0,15}", range_value):
            send_headers["Range"] = range_value
        for field in order:
            url = CORE["signed_url"](row.get(field), headers)
            if not url:
                continue
            try:
                response = CORE["opener"](media=True).open(Request(url, headers=send_headers), timeout=20)
            except HTTPError as exc:
                with exc:
                    if exc.code == 416:
                        self.send_error(416)
                        return
                continue
            except (OSError, HTTPException, Error, ValueError):
                continue
            with response:
                kind = response.headers.get_content_type()
                if variant == "video" and kind == "application/octet-stream":
                    path = urlsplit(url).path.lower()
                    kind = "video/mp4" if path.endswith(".mp4") else "video/webm" if path.endswith(".webm") else kind
                if kind not in (video_types if variant == "video" else image_types):
                    continue
                length = response.headers.get("Content-Length", "")
                if variant != "video" and length.isdecimal() and int(length) > 16 * 1024**2:
                    continue
                self.send_response(response.status)
                for name, value in {"Content-Type": kind, "Cache-Control": "no-store",
                                    "X-Content-Type-Options": "nosniff",
                                    "Cross-Origin-Resource-Policy": "same-origin"}.items():
                    self.send_header(name, value)
                for name in ("Content-Length", "Content-Range", "Accept-Ranges"):
                    value = response.headers.get(name)
                    if value and "\n" not in value and "\r" not in value:
                        self.send_header(name, value)
                self.end_headers()
                try:
                    if variant == "video":
                        shutil.copyfileobj(response, self.wfile, length=256 * 1024)
                    else:
                        remaining = 16 * 1024**2
                        while remaining and (chunk := response.read(min(remaining, 256 * 1024))):
                            self.wfile.write(chunk)
                            remaining -= len(chunk)
                except (OSError, HTTPException):
                    pass
                return
        if not self.serve_local_preview(key, variant):
            self.send_error(404)

    def serve_local_preview(self, key, variant):
        try:
            history = archive_history()
            record = next((v for k, v in history.items() if preview_key(k) == key), None)
            if not record:
                return False
            kind, relative, _ = record
            if (variant == "video") != (kind == 2):
                return False
            path = LIBRARY / relative
            media = {".mp4": "video/mp4", ".webm": "video/webm", ".jpg": "image/jpeg",
                     ".png": "image/png", ".webp": "image/webp"}.get(path.suffix.lower())
            if not media or not path.resolve().is_relative_to(LIBRARY.resolve()):
                return False
            reader = path.open("rb")
            length = os.fstat(reader.fileno()).st_size
        except (OSError, sqlite3.Error):
            return False
        with reader:
            start, end = 0, length - 1
            range_value = self.headers.get("Range")
            if range_value and kind == 2:
                match = re.fullmatch(r"bytes=(\d{1,15})-(\d{0,15})", range_value)
                if not match:
                    self.send_error(416)
                    return True
                start = int(match[1])
                if match[2]:
                    end = min(end, int(match[2]))
                if start > end:
                    self.send_error(416)
                    return True
            partial = bool(range_value and kind == 2)
            self.send_response(206 if partial else 200)
            self.send_header("Content-Type", media)
            self.send_header("Content-Length", str(end - start + 1))
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Cross-Origin-Resource-Policy", "same-origin")
            self.send_header("Cache-Control", "no-store")
            if kind == 2:
                self.send_header("Accept-Ranges", "bytes")
            if partial:
                self.send_header("Content-Range", f"bytes {start}-{end}/{length}")
            self.end_headers()
            reader.seek(start)
            remaining = end - start + 1
            try:
                while remaining and (chunk := reader.read(min(remaining, 256 * 1024))):
                    self.wfile.write(chunk)
                    remaining -= len(chunk)
            except OSError:
                pass
        return True

    def do_POST(self):
        host = self.headers.get("Host")
        scheme = "https" if getattr(self.server, "lan", False) else "http"
        # Pages already open with the previous no-referrer policy can send
        # Origin: null. They still need a valid page CSRF token below.
        if (not self.permitted()
                or self.headers.get("Sec-Fetch-Site") in ("cross-site", "same-site")
                or self.headers.get("Origin") not in (None, "null", f"{scheme}://{host}")
                or self.headers.get_content_type() != "application/x-www-form-urlencoded"):
            self.send_error(403)
            return
        if not self.authenticated():
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 1 <= length <= (700000 if self.path == "/selected" else 20000):
                self.send_error(413)
                return
            fields = {k: v[0] for k, v in parse_qs(self.rfile.read(length).decode(),
                                                 max_num_fields=10).items()}
            if not secrets.compare_digest(fields.get("csrf", "").encode(), CSRF.encode()):
                self.send_error(403)
                return
            if self.path == "/login":
                with SESSION_LOCK:
                    vault("psn-session", stamp(CORE["exchange"](fields.get("npsso", "").strip())))
                queue("check")
                notice = "Sony authorization succeeded. Checking the gallery."
            elif self.path == "/check":
                queue("check")
                notice = "Cloud refresh queued."
            elif self.path == "/dav-refresh":
                request_dav_refresh()
                notice = "WebDAV check queued. Results will update automatically."
            elif self.path == "/selected":
                if not (STATE / "webdav.cred").is_file():
                    raise Error("Downloads are blocked until WebDAV is configured")
                mode = fields.get("mode")
                if mode not in ("selected", "force", "cleanup"):
                    raise Error("Unknown download mode")
                parse_selection = cleanup_ids if mode == "cleanup" else selected_ids
                ids = parse_selection(fields.get("selection", ""))
                if mode == "cleanup":
                    queue(mode, ids)
                    notice = f"Cleanup and verification queued for {len(ids)} filesLocalVideos."
                else:
                    batch = create_batch(mode, ids)
                    notice = f"Batch task #{batch}  saved:{len(ids)} items; the task resumes after a restart."
            elif self.path == "/retry-batch":
                batch = int(fields.get("batch", ""))
                count = retry_batch(batch)
                notice = f"Task #{batch} queued again" + (f", Retry {count} failed items." if count else ".")
            elif self.path == "/clear-failures":
                count = clear_failure_history()
                notice = f"Cleared {count} past failure records; retryable failures were kept."
            elif self.path == "/auto":
                enabled = fields.get("auto") == "on"
                with LOCK:
                    old = settings()
                    since = old.get("auto_since", time.time()) if old.get("auto") else time.time()
                    atomic(STATE / "settings.json", json.dumps(
                        {"auto": enabled, "auto_since": since} if enabled else {"auto": False}
                    ).encode())
                queue("auto" if enabled else "check")
                notice = "Automatic downloads enabled." if enabled else "Automatic downloads disabled. The current task will finish."
            elif self.path == "/dav":
                dav = dav_settings(fields)
                dav_check(dav)
                vault("webdav", dav)
                request_dav_refresh(reset=True)
                notice = "WebDAV directory check passed. Credentials were saved encrypted. Upload permission is checked on the first sync."
            elif self.path == "/admin":
                change_admin(fields)
                notice = "Admin account updated. Refresh and sign in with the new credentials."
            else:
                self.send_error(404)
                return
            self.form_reply(notice=notice)
        except Error as exc:
            self.form_reply(400, str(exc))
        except (ValueError, OSError, subprocess.SubprocessError, sqlite3.Error):
            self.form_reply(400, "Invalid request or unable to save local state.")


class Server(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True

    def get_request(self):
        conn, addr = super().get_request()
        conn.settimeout(15)
        return conn, addr


def directly_connected_lan(peer, local):
    remote, address = map(ipaddress.IPv4Address, (peer, local))
    if not any(remote in net and address in net for net in LAN_RANGES):
        return False
    # Kernel-provided on-link routes follow the current static or DHCP subnet.
    for line in Path("/proc/net/route").read_text().splitlines()[1:]:
        _, dest, gateway, flags, _, _, _, mask, *_ = line.split()
        if gateway != "00000000" or dest == "00000000" or not int(flags, 16) & 1:
            continue
        decode = lambda field: int.from_bytes(bytes.fromhex(field), "little")
        net, bits = decode(dest), decode(mask)
        if int(remote) & bits == net and int(address) & bits == net:
            return True
    return False


class LanServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    daemon_threads = True
    allow_reuse_address = True
    request_queue_size = 64
    lan = True

    def __init__(self):
        self.dns_name = os.uname().nodename.lower()
        admin_verifier()
        self.context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        self.context.minimum_version = ssl.TLSVersion.TLSv1_2
        self.context.load_cert_chain(STATE / "lan-tls.crt", STATE / "lan-tls.key")
        self.slots = threading.BoundedSemaphore(24)
        super().__init__(("0.0.0.0", PORT), Handler)

    def verify_request(self, sock, address):
        try:
            return directly_connected_lan(address[0], sock.getsockname()[0])
        except (OSError, ValueError):
            return False

    def process_request(self, sock, address):
        if not self.slots.acquire(blocking=False):
            self.shutdown_request(sock)
            return
        try:
            super().process_request(sock, address)
        except Exception:
            self.slots.release()
            raise

    def process_request_thread(self, sock, address):
        try:
            sock.settimeout(10)
            with self.context.wrap_socket(sock, server_side=True) as conn:
                super().process_request_thread(conn, address)
        except (OSError, ValueError):
            self.shutdown_request(sock)
        finally:
            self.slots.release()


def main():
    os.umask(0o077)
    for key in tuple(os.environ):
        if key.lower() == "no_proxy":
            del os.environ[key]
    LIBRARY.mkdir(exist_ok=True)
    SOCKET.unlink(missing_ok=True)
    with Server(str(SOCKET), Handler) as server:
        SOCKET.chmod(0o660)
        if (STATE / "admin-verifier.json").is_file() and (STATE / "lan-tls.crt").is_file():
            lan = LanServer()
            threading.Thread(target=lan.serve_forever, daemon=True).start()
        threading.Thread(target=worker, daemon=True).start()
        threading.Thread(target=dav_state_worker, daemon=True).start()
        DAV_WAKE.set()
        server.serve_forever()


if __name__ == "__main__":
    main()
