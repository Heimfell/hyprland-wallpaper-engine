#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

info "Stopping services..."
systemctl --user stop wallpaperengine-scene 2>/dev/null
pkill mpvpaper 2>/dev/null
sleep 1

info "Removing scripts from $INSTALL_DIR..."
rm -f "$INSTALL_DIR/wallpaper-select"
rm -f "$INSTALL_DIR/wallpaper-restore"
rm -f "$INSTALL_DIR/wallpaper"
rm -f "$INSTALL_DIR/wallpaper-list"
rm -f "$INSTALL_DIR/wallpaper-status"

info "Removing systemd service..."
rm -f "$HOME/.config/systemd/user/wallpaperengine-scene.service"
systemctl --user daemon-reload 2>/dev/null

info "Removing state file..."
rm -f "$HOME/.config/hypr/wallpaper-engine-state"

info "Removing keybindings from hyprland config..."
for f in \
  "$HOME/.config/hypr/hyprland.conf" \
  "$HOME/.config/hypr/userprefs.conf" \
  "$HOME/.config/hypr/keybindings.conf"; do
  if [ -f "$f" ]; then
    sed -i '/# --- hyprland-wallpaper-engine ---/,/^$/d' "$f"
    sed -i '/wallpaper-select/d' "$f"
    sed -i '/wallpaper stop/d' "$f"
    sed -i '/wallpaper-restore/d' "$f"
    info "  Cleaned $f"
    break
  fi
done

info "Restoring hyprlock background..."
for f in \
  "$HOME/.config/hypr/hyprlock/HyDE.conf" \
  "$HOME/.config/hypr/hyprlock/theme.conf"; do
  if [ -f "$f" ] && grep -q 'HYPRLOCK_BACKGROUND' "$f"; then
    sed -i 's|path = \$HYPRLOCK_BACKGROUND|path = |' "$f"
    warn "  You may need to set a hyprlock background manually in $f"
    break
  fi
done

echo ""
echo -e "${GREEN}Uninstalled.${NC}"
echo "  Run 'paru -Rns mpvpaper linux-wallpaperengine-git' to remove dependencies."
