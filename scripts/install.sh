#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${GREEN}"
cat << 'FROG'
⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡾⣿⠿⢶⣦⡀⠀⠀⠀⠀
⠀⠀⣠⡾⣟⡟⠻⢿⣦⣤⣤⣤⣤⣤⣤⣾⠏⠃⠹⣶⢀⠙⣿⡄⠀⠀⠀
⠀⢠⣿⢁⠸⣷⡀⠀⠉⢉⡉⠉⠁⢰⣶⠀⠀⠀⢀⠛⠙⢳⢿⣇⠀⠀⠀
⠀⠀⣿⢠⢄⠴⠃⠀⠀⠘⠿⠶⠾⠟⠋⠀⠀⠀⠈⠙⠉⠁⠈⣿⡀⠀⠀
⠀⢀⣿⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡆⠂⢸⣷⡀⠀
⠀⣿⠏⠈⠰⣷⣄⠲⠶⣤⣄⢀⡴⢲⠿⠋⢹⣷⣶⠾⠛⠁⠀⠀⢿⣇⠀
⢸⣿⠀⢀⠀⠉⢻⣇⠀⠉⠁⠿⠋⠀⠀⠀⣾⡏⠀⠀⠀⠀⢀⣤⠈⣿⡄
⠐⢻⣷⣄⣉⣋⣼⡟⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⢶⣤⣶⡾⠟⠛⠀⢿⡇
⠀⠀⣿⢿⣟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣶⠇⠀⠀⠀⣸⡇
⠀⠀⣿⠈⢿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⠇⠀⠀⠀⠀⣿⠇
⢀⣴⡿⠀⠀⠻⣕⣦⡀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠃⠀⠀⠀⠀⠘⣿⡖
⢿⣏⡀⠀⠀⠀⠀⠙⠿⣦⣤⣄⠀⠀⢀⣴⡿⠋⠀⠀⠀⠀⠀⢀⣂⣼⡇
⠈⠉⠛⠛⠻⠿⠿⠿⠿⠿⠿⠶⠿⠿⠿⠿⠿⠿⠟⠛⠛⠛⠛⠛⠉⠉
FROG
echo -e "${NC}"

command -v hyprctl > /dev/null || error "Hyprland is not running"
command -v rofi > /dev/null || error "rofi is not installed"
command -v python3 > /dev/null || error "python3 is not installed"

if ! command -v ffmpeg > /dev/null; then
  warn "ffmpeg not found. Hyprlock integration will not work without it."
fi

find_steam() {
  local paths=(
    "${STEAM_DIR:-}"
    "$HOME/.local/share/Steam"
    "$HOME/.steam/steam"
    "$HOME/.steam/root"
  )
  for steam_dir in "${paths[@]}"; do
    [ -z "$steam_dir" ] && continue
    if [ -d "$steam_dir/steamapps/common/wallpaper_engine" ]; then
      echo "$steam_dir"
      return
    fi
  done
  for steam_dir in "${paths[@]}"; do
    [ -z "$steam_dir" ] && continue
    for lib in "$steam_dir"/steamapps/libraryfolders.vdf "$steam_dir"/config/libraryfolders.vdf; do
      if [ -f "$lib" ]; then
        while IFS= read -r path; do
          if [ -d "$path/steamapps/common/wallpaper_engine" ]; then
            echo "$path"
            return
          fi
        done < <(grep '"path"' "$lib" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/')
      fi
    done
  done
}

STEAM_DIR=$(find_steam)
if [ -z "$STEAM_DIR" ]; then
  error "Wallpaper Engine not found. Install it on Steam and run it once."
fi

STEAM_WP="$STEAM_DIR/steamapps/workshop/content/431960"
WE_ASSETS="$STEAM_DIR/steamapps/common/wallpaper_engine"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
MONITOR="${MONITOR:-$(hyprctl monitors -j 2>/dev/null | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["name"])' 2>/dev/null)}"

if [ -z "$MONITOR" ]; then
  warn "Could not detect monitor, defaulting to DP-1"
  MONITOR="DP-1"
fi

info "Steam found at: $STEAM_DIR"
info "Monitor: $MONITOR"

info "Installing dependencies from AUR..."
echo ""
echo -e "${YELLOW}  This might take a while. Please be patient!${NC}"
echo ""
if command -v paru > /dev/null; then
  paru -S --needed --noconfirm mpvpaper linux-wallpaperengine-git
elif command -v yay > /dev/null; then
  yay -S --needed mpvpaper linux-wallpaperengine-git --noconfirm
else
  error "You need paru or yay to install AUR packages"
fi
echo ""
echo -e "${GREEN}  <3 Dependencies installed${NC}"
echo ""

if [ ! -d "/opt/linux-wallpaperengine" ] || [ ! -f "/opt/linux-wallpaperengine/linux-wallpaperengine" ]; then
  warn "/opt/linux-wallpaperengine is missing. Reinstalling..."
  if command -v paru > /dev/null; then
    paru -S linux-wallpaperengine-git --noconfirm
  elif command -v yay > /dev/null; then
    yay -S linux-wallpaperengine-git --noconfirm
  fi
fi

info "Installing scripts to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp scripts/wallpaper-select "$INSTALL_DIR/wallpaper-select"
cp scripts/wallpaper-restore "$INSTALL_DIR/wallpaper-restore"
cp scripts/wallpaper "$INSTALL_DIR/wallpaper"
cp scripts/wallpaper-list "$INSTALL_DIR/wallpaper-list"
cp scripts/wallpaper-status "$INSTALL_DIR/wallpaper-status"
chmod +x "$INSTALL_DIR/wallpaper-select" "$INSTALL_DIR/wallpaper-restore" \
  "$INSTALL_DIR/wallpaper" "$INSTALL_DIR/wallpaper-list" "$INSTALL_DIR/wallpaper-status"

info "Installing config file..."
if [ ! -f "$HOME/.config/hypr/wallpaper-engine.conf" ]; then
  mkdir -p "$HOME/.config/hypr"
  cp config/wallpaper-engine.conf "$HOME/.config/hypr/wallpaper-engine.conf"
  info "  Config installed to ~/.config/hypr/wallpaper-engine.conf"
else
  info "  Config already exists, skipping"
fi

info "Fixing Wallpaper Engine asset paths..."
if [ -d "$WE_ASSETS/assets" ]; then
  for d in models materials effects shaders presets scenes particles fonts scripts; do
    if [ -d "$WE_ASSETS/assets/$d" ] && [ ! -e "$WE_ASSETS/$d" ]; then
      ln -sf "$WE_ASSETS/assets/$d" "$WE_ASSETS/$d"
      info "  Linked: $d"
    fi
  done
else
  warn "Wallpaper Engine assets not found at $WE_ASSETS"
  warn "Make sure it's installed and has been run at least once"
fi

mkdir -p "$HOME/.config/systemd/user"

info "Detecting wallpapers..."
video_count=$(find "$STEAM_WP" -maxdepth 2 \( -name "*.mp4" -o -name "*.webm" \) 2>/dev/null | wc -l)
total_count=$(find "$STEAM_WP" -maxdepth 2 -name "project.json" 2>/dev/null | wc -l)
info "  $video_count video + $((total_count - video_count)) scene = $total_count total"

HYPRLAND_CONF=""
for f in \
  "$HOME/.config/hypr/hyprland.conf" \
  "$HOME/.config/hypr/userprefs.conf" \
  "$HOME/.config/hypr/keybindings.conf"; do
  if [ -f "$f" ]; then
    HYPRLAND_CONF="$f"
    break
  fi
done

echo ""
echo -e "${YELLOW}  Do you want to add keybindings to your hyprland config?${NC}"
echo ""
echo "    These will be added:"
echo "      Super+Alt+W   = open wallpaper selector"
echo "      Super+Alt+S   = stop wallpaper"
echo ""
read -rp "  Add keybindings? [Y/n] " add_binds
echo ""

echo -e "${YELLOW}  Do you want to update hyprlock to use your wallpaper as lock screen?${NC}"
echo ""
read -rp "  Enable hyprlock integration? [Y/n] " add_lockscreen
echo ""

if [[ "$add_binds" =~ ^[Nn] ]]; then
  echo ""
  echo -e "${GREEN}  <3 All done! Thanks for installing.${NC}"
  echo ""
  echo "  Steam:          $STEAM_DIR"
  echo "  Monitor:        $MONITOR"
  echo "  Scripts:        $INSTALL_DIR/wallpaper-select"
  echo "                  $INSTALL_DIR/wallpaper"
  echo ""
  echo "  Add these to your hyprland.conf manually:"
  echo ""
  echo "    bind = \$mainMod ALT, W, exec, wallpaper-select"
  echo "    bind = \$mainMod ALT, S, exec, wallpaper stop"
  echo "    exec-once = wallpaper-restore"
  echo ""
  echo "  Optional env vars:"
  echo "    STEAM_DIR   - Steam path (default: auto-detect)"
  echo "    MONITOR     - Monitor name (default: auto-detect)"
  echo "    FPS         - FPS cap for scenes (default: 30)"
  echo ""
  exit 0
fi

if [ -n "$HYPRLAND_CONF" ]; then
  echo "" >> "$HYPRLAND_CONF"
  echo "# --- hyprland-wallpaper-engine ---" >> "$HYPRLAND_CONF"
  echo "bind = \$mainMod ALT, W, exec, wallpaper-select" >> "$HYPRLAND_CONF"
  echo "bind = \$mainMod ALT, S, exec, wallpaper stop" >> "$HYPRLAND_CONF"
  echo "exec-once = sleep 3 && wallpaper-restore" >> "$HYPRLAND_CONF"
  info "Keybindings and auto-restore added to $HYPRLAND_CONF"
else
  warn "Could not find hyprland.conf. Add these manually:"
  echo ""
  echo "    bind = \$mainMod ALT, W, exec, wallpaper-select"
  echo "    bind = \$mainMod ALT, S, exec, wallpaper stop"
  echo "    exec-once = sleep 3 && wallpaper-restore"
fi

if [[ ! "$add_lockscreen" =~ ^[Nn] ]]; then
  LOCK_CONF=""
  for f in \
    "$HOME/.config/hypr/hyprlock/HyDE.conf" \
    "$HOME/.config/hypr/hyprlock/theme.conf" \
    "$HOME/.config/hypr/hyprlock.conf"; do
    if [ -f "$f" ]; then
      LOCK_CONF="$f"
      break
    fi
  done
  if [ -n "$LOCK_CONF" ]; then
    if grep -q 'path\s*=' "$LOCK_CONF" 2>/dev/null; then
      sed -i 's|path\s*=\s*.*/.*\.\(jpg\|png\|gif\)|path = $HYPRLOCK_BACKGROUND|' "$LOCK_CONF" 2>/dev/null
      info "Hyprlock integration enabled in $LOCK_CONF"
    else
      warn "Could not find background path in $LOCK_CONF"
      warn "Set path = \$HYPRLOCK_BACKGROUND manually in your hyprlock config"
    fi
  else
    warn "Could not find hyprlock config"
    warn "Add 'path = \$HYPRLOCK_BACKGROUND' to your hyprlock background block"
  fi
fi

echo ""
echo -e "${GREEN}  <3 All done! Thanks for installing.${NC}"
echo ""
echo "  Super+Alt+W = select wallpaper"
echo "  Super+Alt+S = stop wallpaper"
echo ""
echo "  Reload hyprland to apply keybindings."
echo ""
