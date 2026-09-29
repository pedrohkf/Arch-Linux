#!/usr/bin/env bash
# Instala os pacotes do Crafix adaptados pro ThinkPad T14s (Intel).
# Rode num terminal de verdade (kitty): bash ~/crafix-thinkpad-setup.sh
set -euo pipefail

echo "==> Ativando multilib (Steam)"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
fi

echo "==> Pacotes oficiais"
sudo pacman -Syu --needed ark base base-devel bluez bluez-utils brightnessctl calibre cups cups-pk-helper dbeaver discord docker dolphin dunst efibootmgr firefox flameshot foliate fpc gammastep git grim grub gst-plugin-pipewire htop hyprland hyprpaper hyprpm hyprsunset imv intel-media-driver intel-ucode iwd kitty less libnotify libpulse libreoffice-fresh linux linux-firmware nano ncdu neovim networkmanager network-manager-applet npm ntfs-3g obsidian os-prober pacman-contrib pavucontrol pipewire pipewire-alsa pipewire-jack pipewire-pulse playerctl polkit-kde-agent pulsemixer qt5-wayland qt6-wayland sbctl sddm slurp smartmontools starship steam sudo system-config-printer translate-shell ttf-jetbrains-mono-nerd unzip uwsm vim vulkan-intel waybar wget wireless_tools wireplumber wl-clipboard wofi xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-utils xorg-server xorg-xhost xorg-xinit zram-generator 

echo "==> yay"
if ! command -v yay >/dev/null; then
    tmp=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
fi

echo "==> Pacotes AUR"
yay -S --needed whitesur-gtk-theme whitesur-icon-theme figma-linux google-chrome libresprite-git postman-bin spicetify-cli spotify sublime-text-4 visual-studio-code-bin weylus-bin 

echo "==> Tema WhiteSur (Nautilus / GTK4)"
mkdir -p ~/.config/gtk-4.0 ~/.config/gtk-3.0
for f in assets gtk.css gtk-dark.css; do ln -sfn /usr/share/themes/WhiteSur-Dark/gtk-4.0/\$f ~/.config/gtk-4.0/\$f; done
cp "\$(dirname "\$0")/.config/gtk-3.0/settings.ini" ~/.config/gtk-3.0/
gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
xdg-mime default org.gnome.Nautilus.desktop inode/directory

echo "==> Limite de carga da bateria (75-80%, ThinkPad)"
if [ -e /sys/class/power_supply/BAT0/charge_control_end_threshold ]; then
    sudo cp "\$(dirname "\$0")/system/battery.conf" /etc/tmpfiles.d/battery.conf
    sudo systemd-tmpfiles --create
fi

echo "==> Plugin hyprbars (botões estilo macOS)"
hyprpm update
hyprpm add https://github.com/hyprwm/hyprland-plugins || true
hyprpm enable hyprbars

echo "==> Modus"
curl -fsSL https://raw.githubusercontent.com/S4NKALP/Modus/master/install.sh -o /tmp/modus-install.sh
bash /tmp/modus-install.sh

echo
echo "==> Pronto. Avisa o Claude que terminou pra aplicar os patches do Modus e trocar pro tema 1-macos."
