#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo sh install.sh" >&2
    exit 1
fi
for bin in python3 systemd-creds systemctl useradd; do
    command -v "$bin" >/dev/null || { echo "Missing dependency: $bin" >&2; exit 1; }
done
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else "Python 3.11 or later is required")'
if ! id psclips >/dev/null 2>&1; then
    useradd --system --user-group --home-dir /var/lib/psclips --no-create-home \
        --shell /usr/sbin/nologin psclips
fi
install -d -m 0755 /opt/psclips
install -d -m 0700 -o psclips -g psclips /var/lib/psclips
install -d -m 0700 /etc/psclips
install -m 0644 psclips-admin.py psclips-core.py /opt/psclips/
if [ ! -e /etc/psclips/psclips.env ]; then
    umask 077
    cat > /etc/psclips/psclips.env <<'EOF'
# Supply values for an OAuth client you are authorized to use.
PSCLIPS_OAUTH_CLIENT_ID=
PSCLIPS_OAUTH_CLIENT_SECRET=
PSCLIPS_OAUTH_REDIRECT_URI=
# PSCLIPS_OAUTH_SCOPES="psn:mobile.v2.core psn:clientapp"
# PSCLIPS_PROXY=http://proxy.example:7890
EOF
fi
install -m 0644 psclips.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now psclips.service
echo "Installed. See README.md for OAuth setup and secure access."
