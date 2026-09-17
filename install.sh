#!/usr/bin/env bash
# Crafix installer — installs packages and copies dotfiles into place.
# Safe to re-run. See docs/hyprland-modus-setup.md for the macOS-style setup
# (needs an extra manual step for the Modus shell itself).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing official packages"
sudo pacman -S --needed - < "$REPO_DIR/packages.txt"

if command -v yay >/dev/null 2>&1; then
    echo "==> Installing AUR packages"
    yay -S --needed - < "$REPO_DIR/aur.txt"
else
    echo "!! yay not found — skipping AUR packages, see aur.txt"
fi

echo "==> Copying dotfiles to ~/.config"
cp -r "$REPO_DIR/.config/." ~/.config/
cp "$REPO_DIR/.bashrc" ~/ 2>/dev/null || true
cp "$REPO_DIR/.gitconfig" ~/ 2>/dev/null || true
chmod +x ~/.config/hypr/*.sh ~/.config/hypr/theme-manager/*.sh 2>/dev/null || true

cat <<'EOF'

==> Done.

Next steps:
  1. Edit ~/.config/hypr/hardware.lua — monitors, keyboard layout and mouse
     name are specific to this machine (`hyprctl devices` to find yours).
  2. hyprctl reload
  3. Super+T to pick a theme (plain Waybar, or the Modus macOS-style shell —
     see docs/hyprland-modus-setup.md to install Modus itself first).
EOF
