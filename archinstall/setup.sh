#!/bin/bash

# Global config
sudo cp -r etc /

# Install official packages
sudo pacman -Syu
[ -f packages/pacman.txt ] && sudo pacman -S --needed - < packages/pacman.txt
[ -f "packages/$HOSTNAME/pacman.txt" ] && sudo pacman -S --needed - < "packages/$HOSTNAME/pacman.txt"

# Install paru for AUR
# https://github.com/Morganamilo/paru
git clone https://aur.archlinux.org/paru.git
cd paru || exit
makepkg -si
cd .. || exit
rm -rf paru

# Install AUR packages
[ -f packages/aur.txt ] && paru -S --needed - < packages/aur.txt
[ -f "packages/$HOSTNAME/aur.txt" ] && paru -S --needed - < "packages/$HOSTNAME/aur.txt"

# Enable systemwide systemd services
sudo timedatectl set-ntp true
sudo systemctl enable greetd.service # Display manager
sudo systemctl enable grub-btrfsd.service # grub-btrfs, cf. https://github.com/Antynea/grub-btrfs
sudo systemctl enable backup.timer # Hourly backups
sudo systemctl enable paccache.timer # Clean pacman cache every week
sudo systemctl enable bluetooth.service

# Create directories
mkdir -p ~/.config
mkdir -p ~/.local/share
mkdir -p ~/.local/state
mkdir -p ~/.cache
mkdir -p ~/.ssh

# Set permissions
chmod 700 ~/.ssh

# Why does "~" instead of "$HOME" cause errors in stow command?
stow home --dir="$HOME/.dotfiles" --target="$HOME" home

# Enable user-specific systemd services
systemctl enable --user ssh-agent.service
systemctl enable --user hypridle.service
systemctl enable --user hyprpaper.service
systemctl enable --user waybar.service

# Finalize
printf '\033[1mCustom installation is done. Please reboot.\n'
