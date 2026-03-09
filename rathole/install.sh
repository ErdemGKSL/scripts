create_desktop_entry() {

APP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APP_DIR/rathole-start.desktop"

mkdir -p "$APP_DIR"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Start Rathole
Comment=Start Rathole Reverse Proxy
Exec=$INSTALL_DIR/start.sh
Icon=network-server
Terminal=true
Type=Application
Categories=Network;
EOF

chmod +x "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR"
fi

echo "Desktop entry created."
}