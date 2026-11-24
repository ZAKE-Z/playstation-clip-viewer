#!/usr/bin/env python3
"""PSN HTTP helpers for an operator-authorized cloud gallery."""

import base64
import json
import os
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlencode, urlsplit, urlunsplit
from urllib.request import (
    HTTPRedirectHandler, ProxyHandler, Request, build_opener,
)

PROXY = os.environ.get("PSCLIPS_PROXY", "").strip()
OAUTH = "https://ca.account.sony.com/api/authz/v3/oauth"
GALLERY = (
    "https://m.np.playstation.com/api/gameMediaService/v2/c2s/"
    "category/cloudMediaGallery/ugcType/all"
)
# OAuth configuration is supplied by the operator, never checked into Git.
CLIENT_ID = os.environ.get("PSCLIPS_OAUTH_CLIENT_ID", "").strip()


def client_authorization():
    client_secret = os.environ.get("PSCLIPS_OAUTH_CLIENT_SECRET", "")
    if not CLIENT_ID or not client_secret or not REDIRECT:
        raise TestError("Configure the authorized PSN OAuth client credentials on the server")
    return "Basic " + base64.b64encode(f"{CLIENT_ID}:{client_secret}".encode()).decode()


REDIRECT = os.environ.get("PSCLIPS_OAUTH_REDIRECT_URI", "")
SCOPE = os.environ.get("PSCLIPS_OAUTH_SCOPES", "psn:mobile.v2.core psn:clientapp")


class TestError(Exception):
    pass


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class HttpsRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if urlsplit(newurl).scheme != "https":
            raise TestError("CDN returned a non-HTTPS redirect")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def opener(*, media=False):
    return build_opener(
        ProxyHandler({"http": PROXY, "https": PROXY} if PROXY else {}),
        HttpsRedirect() if media else NoRedirect(),
    )


def api_json(stage, req):
    try:
        with opener().open(req, timeout=25) as reply:
            headers = reply.headers
            data = reply.read(8 * 1024**2 + 1)
        if len(data) > 8 * 1024**2:
            raise TestError(f"{stage}: response exceeds limit")
        value = json.loads(data)
        if not isinstance(value, dict):
            raise ValueError
        return value, headers
    except HTTPError as error:
        with error:
            raise TestError(f"{stage}: HTTP {error.code}") from None
    except (URLError, OSError):
        raise TestError(f"{stage}: proxy/network failure") from None
    except (ValueError, UnicodeError):
        raise TestError(f"{stage}: invalid JSON response") from None


def exchange(npsso):
    authorization = client_authorization()
    if not npsso or len(npsso) > 4096 or any(
        ord(c) < 33 or ord(c) > 126 or c in '",;\\' for c in npsso
    ):
        raise TestError("Invalid NPSSO input; submit only the npsso value")
    query = urlencode(
        dict(access_type="offline", client_id=CLIENT_ID, redirect_uri=REDIRECT,
             response_type="code", scope=SCOPE),
    )
    req = Request(f"{OAUTH}/authorize?{query}", headers={"Cookie": f"npsso={npsso}"})
    try:
        with opener().open(req, timeout=25):
            raise TestError("Authorization: expected a redirect")
    except HTTPError as error:
        with error:
            if error.code != 302:
                raise TestError(f"Authorization: HTTP {error.code}") from None
            location = error.headers.get("Location", "")
    except (URLError, OSError):
        raise TestError("Authorization: proxy/network failure") from None
    uri = urlsplit(location)
    callback = urlsplit(REDIRECT)
    fields = parse_qs(uri.query)
    code = fields.get("code", [""])[0]
    expected_callback = (uri.scheme, uri.netloc, uri.path.rstrip("/")) == (
        callback.scheme, callback.netloc, callback.path
    )
    if not expected_callback or not code:
        known = {"login_required", "interaction_required", "access_denied",
                 "invalid_request", "invalid_client", "invalid_grant",
                 "unauthorized_client", "invalid_scope", "server_error"}
        reason = fields.get("error", [""])[0]
        if reason not in known:
            reason = "no authorization code" if not code else "unexpected callback"
        destination = ("app callback" if expected_callback else
                       "Sony account page" if uri.hostname in {
                           "ca.account.sony.com", "id.sonyentertainmentnetwork.com",
                           "my.account.sony.com", "account.sony.com"
                       } else "other callback")
        raise TestError(f"Authorization: {destination}, {reason}")
    body = urlencode(
        dict(code=code, grant_type="authorization_code", redirect_uri=REDIRECT)
    ).encode()
    tokens, _ = api_json("Token exchange", Request(
        f"{OAUTH}/token", data=body, headers={
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": authorization,
        },
    ))
    if not all(isinstance(tokens.get(k), str) and tokens[k] for k in
               ("access_token", "refresh_token")):
        raise TestError("Token exchange: missing access or refresh token")
    return tokens


def signed_url(url, headers):
    if not isinstance(url, str):
        return None
    parts = urlsplit(url)
    if parts.scheme != "https" or not parts.hostname or parts.username or parts.password:
        return None
    cookies = {}
    for header in headers.get_all("Set-Cookie", []):
        key, sep, value = header.partition(";")[0].partition("=")
        if sep:
            cookies[key.strip()] = value
    names = ("Key-Pair-Id", "Signature", "Policy")
    if set(names) <= parse_qs(parts.query).keys():
        return url
    if not all(cookies.get(f"CloudFront-{name}") for name in names):
        return url
    suffix = urlencode({name: cookies[f"CloudFront-{name}"] for name in names},
                       quote_via=quote)
    return urlunsplit(parts._replace(query="&".join(filter(None, (parts.query, suffix)))))


def media_extension(head, kind):
    if kind == 2:
        if head[4:8] == b"ftyp" and len(head) >= 16:
            return "mp4"
        if head.startswith(b"\x1a\x45\xdf\xa3") and b"webm" in head:
            return "webm"
    if kind == 1:
        if head.startswith(b"\xff\xd8\xff"):
            return "jpg"
        if head.startswith(b"\x89PNG\r\n\x1a\n"):
            return "png"
        if head.startswith(b"RIFF") and head[8:12] == b"WEBP":
            return "webp"
    raise TestError("CDN response was not an expected original media file")

