#!/usr/bin/env bash
set -euo pipefail

# Config
URL="https://github.com/rathole-org/rathole/releases/download/v0.5.0/rathole-x86_64-unknown-linux-gnu.zip"
SHARE_DIR="$HOME/ip-share"
ZIP_PATH="$(mktemp -t rathole.XXXXXX.zip)"
SESSION_PATH="${PATH}"

# Ensure needed tools
need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is required but not found in PATH." >&2
    exit 1
  }
}
need_cmd curl
need_cmd unzip
need_cmd systemctl
need_cmd readlink

# Create directory
mkdir -p "$SHARE_DIR"

# Download
echo "Downloading rathole..."
curl -L --fail -o "$ZIP_PATH" "$URL"

# Extract
echo "Extracting to $SHARE_DIR ..."
unzip -o "$ZIP_PATH" -d "$SHARE_DIR" >/dev/null
rm -f "$ZIP_PATH"

# Ensure binary exists and is executable
if [[ ! -f "$SHARE_DIR/rathole" ]]; then
  echo "Error: rathole binary not found at $SHARE_DIR/rathole after extraction." >&2
  exit 1
fi
chmod +x "$SHARE_DIR/rathole"

# Generate random token (32-char alphanumeric)
RANDOM_TOKEN="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 || true)"
if [[ -z "${RANDOM_TOKEN}" ]]; then
  echo "Error: Failed to generate random token." >&2
  exit 1
fi

# Create server.toml
cat >"$SHARE_DIR/server.toml" <<EOF
[server]
bind_addr = "0.0.0.0:2333"
default_token = "${RANDOM_TOKEN}"

[server.services.mc]
bind_addr = "0.0.0.0:25565"
EOF

# Resolve absolute path
ABS_DIR="$(readlink -f "$SHARE_DIR")"
BIN_PATH="$ABS_DIR/rathole"
CONF_PATH="$ABS_DIR/server.toml"

# Create/Update systemd user service
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SERVICE_PATH="$SYSTEMD_USER_DIR/rathole.service"
cat >"$SERVICE_PATH" <<EOF
[Unit]
Description=Rathole server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment="PATH=${SESSION_PATH}"
WorkingDirectory=${ABS_DIR}
ExecStart=${BIN_PATH} ${CONF_PATH}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

# Reload user units
systemctl --user daemon-reload

# If service is already running, restart it; otherwise enable/start it
if systemctl --user is-active --quiet rathole.service; then
  echo "Service is active, restarting..."
  systemctl --user restart rathole.service
else
  if systemctl --user is-enabled --quiet rathole.service; then
    echo "Service enabled but not active, starting..."
    systemctl --user start rathole.service
  else
    echo "Enabling and starting service..."
    systemctl --user enable --now rathole.service
  fi
fi

echo "Done."
echo "Directory: ${ABS_DIR}"
echo "Binary:    ${BIN_PATH}"
echo "Config:    ${CONF_PATH}"
echo "Service:   rathole.service (user)"
echo "default_token: ${RANDOM_TOKEN}"
