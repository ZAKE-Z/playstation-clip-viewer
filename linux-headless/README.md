# PS5 Media Gallery for Linux

A headless Debian companion that archives your own PlayStation clips and screenshots to WebDAV. Its English, PlayStation-inspired web interface supports previews, batch downloads with restart recovery, per-file retries, and verified local-video cleanup. It does not need Flutter, a desktop session, or a browser installed on the server.

This is an unofficial companion to [PlayStation Clip Viewer](https://github.com/CallMeTak/playstation-clip-viewer). The upstream Flutter app is unchanged; this companion lives in `linux-headless/`. It uses Sony endpoints that may change or reject nonstandard clients. No Sony credentials are distributed with the companion.

## Quick start

1. On a Debian 13 host with Python 3.11+ and systemd, enter `linux-headless/` and run `sudo sh install.sh`.
2. Edit `/etc/psclips/psclips.env` as root. Supply `PSCLIPS_OAUTH_CLIENT_ID`, `PSCLIPS_OAUTH_CLIENT_SECRET`, and `PSCLIPS_OAUTH_REDIRECT_URI` for an OAuth client you are authorized to use with the PSN gallery flow. The redirect URI must match the registered one. Optionally set `PSCLIPS_OAUTH_SCOPES` and `PSCLIPS_PROXY` (an HTTP proxy URL). Without valid client configuration, the dashboard works but cannot import a Sony session. Restart with `sudo systemctl restart psclips`.
3. Grant a trusted SSH user access to the dashboard socket on the server: `sudo usermod -aG psclips YOUR_LINUX_USERNAME`. Reconnect so the group change takes effect. The group grants full web administration through the socket; add only trusted users.
4. On your computer, open this tunnel and leave it running:

   ```sh
   ssh -N -o ExitOnForwardFailure=yes \
     -L 127.0.0.1:18765:/run/psclips/admin.sock YOUR_LINUX_USERNAME@YOUR_SERVER
   ```

   Open <http://127.0.0.1:18765/>. No LAN HTTP port is opened by default.
5. In **System Settings → Sony sign-in**, open Sony's sign-in and session pages in the same browser session. Finish sign-in and paste only the `npsso` value into the dashboard. Do not put it in an issue, log, or command line. Then set a writable WebDAV destination under **System Settings → WebDAV storage**; HTTPS is recommended.

## Daily use

- Click a thumbnail to preview; filter by type or status, then select and download. Normal downloads skip previously verified uploads. **Force redownload** can restore a missing backup without overwriting a conflicting file of the same name.
- Work is filed by game and retains the Sony capture title. The extension matches the downloaded media format. Local files live in `/var/lib/psclips/captures/`.
- Open **Task history** for per-file problems and retry controls. A restart resumes from the next pending file; a complete local copy can go straight to upload. Partial downloads restart from the beginning. Clearing failure history keeps retryable entries and does not delete media.
- Enable **Auto-download videos** to check every five minutes for videos uploaded after the switch was enabled. Only captures available in Sony's cloud can be downloaded.
- **Delete local videos** verifies the current WebDAV copy against the original SHA-256 before removing the local copy. It never deletes screenshots, the cloud copy, or the WebDAV copy.

## Optional direct LAN access

The SSH tunnel is the default. To enable direct LAN HTTPS, provision your own server certificate and private key as `/var/lib/psclips/lan-tls.crt` and `lan-tls.key`, and set up a separate dashboard password. The certificate must cover the private IP or resolve under the server's host name. Run the following on the server; it prompts without echoing the password:

```sh
sudo python3 - <<'PY'
import getpass, hashlib, json, os, pathlib, pwd, tempfile
state = pathlib.Path("/var/lib/psclips")
account = pwd.getpwnam("psclips")
password = getpass.getpass("New dashboard password: ")
if len(password) < 12 or len(password.encode()) > 256 or password != getpass.getpass("Confirm: "):
    raise SystemExit("Passwords did not match or did not meet the length limits.")
salt = os.urandom(32)
key = hashlib.scrypt(password.encode(), salt=salt, n=16384, r=8, p=1, dklen=32)
with tempfile.NamedTemporaryFile(dir=state, delete=False) as f:
    f.write(json.dumps(dict(user="admin", salt=salt.hex(), key=key.hex())).encode())
    os.fchown(f.fileno(), account.pw_uid, account.pw_gid)
    os.replace(f.name, state / "admin-verifier.json")
PY
sudo chown psclips:psclips /var/lib/psclips/lan-tls.crt /var/lib/psclips/lan-tls.key
sudo chmod 600 /var/lib/psclips/lan-tls.key
sudo systemctl restart psclips
```

Open `https://YOUR_SERVER:18765/` and sign in as `admin`. Direct access is restricted to the current private, directly connected IPv4 subnet. It does not make the site suitable for public exposure; do not publish or port-forward this port. Use a certificate your devices trust.

Useful commands: `systemctl status psclips` and `journalctl -u psclips -n 50`. Keep the state directory private; it contains the gallery database and host-bound encrypted credentials. Do not commit server configuration, certificates, logs, or downloaded media.
