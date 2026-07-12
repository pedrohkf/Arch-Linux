# 🐧 Arch Linux Dotfiles

My personal Arch Linux configuration and backup repository.

This repository contains the configuration files I use on my daily Arch Linux setup, allowing me to quickly recreate my development environment on a new machine.

## 📦 Included

* Hyprland
* Waybar
* Kitty
* Wofi
* GTK 3 & GTK 4 configuration
* Bash/Zsh configuration
* Git configuration
* Installed package lists (`pacman` & `AUR`)

## 📁 Repository Structure

```text
.
├── .config/
│   ├── hypr/
│   ├── waybar/
│   ├── kitty/
│   ├── wofi/
│   ├── gtk-3.0/
│   ├── gtk-4.0/
│   └── mimeapps.list
├── packages.txt
├── aur.txt
└── README.md
```

## 🚀 Restoring the Environment

Clone the repository:

```bash
git clone https://github.com/pedrohkf/Arch-Linux.git
cd Arch-Linux
```

Install official packages:

```bash
sudo pacman -S --needed - < packages.txt
```

Install AUR packages (requires `yay`):

```bash
yay -S --needed - < aur.txt
```

Copy the configuration files:

```bash
cp -r .config/* ~/.config/
cp .bashrc ~/ 2>/dev/null
cp .zshrc ~/ 2>/dev/null
cp .gitconfig ~/ 2>/dev/null
```

## 🎯 Goal

The purpose of this repository is to keep my Arch Linux setup versioned and portable, making it easy to migrate to a new computer or restore my environment after a fresh installation.

## ⚠️ Notes

This repository intentionally excludes:

* Browser profiles
* Discord data
* VS Code cache
* Firefox cache
* Postman data
* Downloads
* Personal files
* Cache and temporary files

Only configuration files and package lists are stored.

---

Made with ❤️ on Arch Linux.
