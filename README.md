<div align="center">

# hyprland-wallpaper-engine

Wallpaper Engine wallpapers on Hyprland

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

</div>

---

People keep asking if Wallpaper Engine works on Hyprland. The answer was always "kinda" or "just use swww". So I made it work properly.

Reads your Steam Workshop wallpapers, detects if they're video or scene type, and plays them on your desktop. Video wallpapers go through mpvpaper, scene wallpapers use linux-wallpaperengine as a systemd service so they don't die when you close the terminal.

## Features

- Video wallpapers (mp4/webm) with hardware decoding
- Scene wallpapers via linux-wallpaperengine + systemd
- Rofi menu with all your subscribed wallpapers
- Auto-restore on startup
- Auto-detects monitor, Steam path, wallpaper type
- Hyprlock integration (lock screen matches your wallpaper)
- Falls back to preview image if a scene crashes
- Works with any Hyprland setup

## Requirements

- Hyprland
- [Wallpaper Engine](https://store.steampowered.com/app/431960/Wallpaper_Engine/) on Steam with wallpapers subscribed
- rofi
- paru or yay
- python3
- ffmpeg (optional, for hyprlock)

## Install

```bash
git clone https://github.com/Heimfell/hyprland-wallpaper-engine.git
cd hyprland-wallpaper-engine
./scripts/install.sh
```

The installer handles everything: AUR dependencies, keybindings, hyprlock setup. Just reload Hyprland and press Super+Alt+W.

## Usage

| Command | Description |
|---|---|
| `wallpaper-select` | Open the rofi menu |
| `wallpaper stop` | Stop current wallpaper |
| `wallpaper start` | Resume last wallpaper |
| `wallpaper-list` | List all wallpapers |
| `wallpaper-status` | Check running status |

## Config

Edit `~/.config/hypr/wallpaper-engine.conf`:

```
STEAM_DIR=        # leave empty for auto-detect
MONITOR=          # leave empty for auto-detect
FPS=30            # scene wallpaper framerate
INSTALL_DIR=      # default: ~/.local/bin
```

## How it works

The install script does a few non-obvious things:

1. Installs `mpvpaper` and `linux-wallpaperengine-git` from AUR
2. Creates symlinks for `assets/models`, `assets/materials`, etc. - this fixes the `solidlayer.json not found` error on Wayland
3. Scene wallpapers run as a systemd user service (survives terminal closure)

When you pick a wallpaper:
- **Video** → mpvpaper plays it as a Wayland background layer (hwdec + 15fps cap to save CPU)
- **Scene** → systemd service starts linux-wallpaperengine with the correct wallpaper ID. If it crashes, falls back to the preview image
- Your hyprlock background gets updated automatically

## Known issues

**Some scene wallpapers don't work.** linux-wallpaperengine is a reverse-engineering effort and doesn't support:
- Text elements
- Complex scripts (clocks, audio visualizers, UI)
- Web wallpapers
- Some mouse parallax

Simple scenes with particles, weather, landscapes work fine. Video wallpapers always work. When a scene crashes, you get the preview image instead of a black screen.

**High CPU?** Video wallpapers are capped at 15fps with hardware decoding. If it's still too much, stop it with Super+Alt+S.

## Uninstall

```bash
./scripts/uninstall.sh
```

Then `paru -Rns mpvpaper linux-wallpaperengine-git` to remove dependencies.

## Credits

- [Almamu/linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine) - the C++ engine that makes scene wallpapers possible. Star that repo, not this one.
- [GhostNaN/mpvpaper](https://github.com/GhostNaN/mpvpaper) - video wallpapers on Wayland
- Kristjan Skutta - [Wallpaper Engine](https://store.steampowered.com/app/431960/Wallpaper_Engine/) on Steam

This is just a bash wrapper around their work.

---

<div align="center">

[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-☕-FFDD00?style=for-the-badge)](https://www.buymeacoffee.com/heimfell)

</div>
