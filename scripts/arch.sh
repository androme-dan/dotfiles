#!/bin/bash
# Script to install Arch Linux, inspired by
# https://github.com/frankebel/archinstall and
# https://wiki.archlinux.org/title/Installation_guide.

# Uncomment lines below and set values manually.
# drive=              # Drive to install Arch Linux. (default: first drive)
# swap_size=          # Swap size in GiB. Set 0 for none. (default: 0)
# pass_root=          # Passphrase for root user. (default: pass)
# username=           # Username for regular user. (default: user)
# pass_user=          # Passphrase for regular user. (default: pass)
# hostname=           # hostname of the device. (default: arch)
# keymap=             # Keyboard mapping for console. (default: us-acentos)

# Set default values.
drive_default=$(lsblk -dno NAME | grep -E '^nvme|^sd|^vd' | head -n 1)

: ${drive:=$drive_default}
: ${swap_size:=0}
: ${pass_root:=pass}
: ${username:=user}
: ${pass_user:=pass}
: ${hostname:=arch}
: ${keymap:=us-acentos}

# Assert file existence.
[ -f chroot.sh ] || exit 1

# 1 Pre-installation

# 1.6 Verify UEFI 64-bit boot mode.
[ $(< /sys/firmware/efi/fw_platform_size) == 64 ] || exit 1

# 1.9 Partition the disks
# Create 1024MB partition for EFI system.
# Create root partition with remaining capacity.
fdisk /dev/$drive << FDISK_CMDS
g
n


+1024M
t
1
n



w
FDISK_CMDS

efi_system_partition=$(lsblk -rno NAME /dev/$drive | grep $drive.*1)
root_partition=$(lsblk -rno NAME /dev/$drive | grep $drive.*2)

# 1.10 Format the partitions
mkfs.fat -F 32 /dev/$efi_system_partition
mkfs.btrfs /dev/$root_partition

# 1.11 Mount the filesystems
mount /dev/$root_partition /mnt
mount --mkdir /dev/$efi_system_partition /mnt/boot

# Create swapfile
# https://wiki.archlinux.org/title/Btrfs#Swap_file
if (( swap_size > 0 )); then
	btrfs subvolume create /mnt/swap
	btrfs filesystem mkswapfile --size "${swap_size}g" --uuid clear /mnt/swap/swapfile
	swapon /mnt/swap/swapfile
fi

# 2 Installation

# 2.2 Install essential packages
pacstrap -K /mnt base linux linux-firmware efibootmgr networkmanager neovim

# 3 Configure the system

# 3.1 Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# 3.2 Change root into the new system
# Insert values into chroot.sh 
uuid_root=$(lsblk -dno UUID /dev/$root_partition)

sed -i -E "s/(^drive=$)/\1'$drive'/" chroot.sh
sed -i -E "s/(^uuid_root=$)/\1'$uuid_root'/" chroot.sh
sed -i -E "s/(^pass_root=$)/\1'$pass_root'/" chroot.sh
sed -i -E "s/(^username=$)/\1'$username'/" chroot.sh
sed -i -E "s/(^pass_user=$)/\1'$pass_user'/" chroot.sh
sed -i -E "s/(^hostname=$)/\1'$hostname'/" chroot.sh
sed -i -E "s/(^keymap=$)/\1'$keymap'/" chroot.sh

cp chroot.sh /mnt/root/chroot.sh
arch-chroot /mnt bash /root/chroot.sh
shred -u /mnt/root/chroot.sh

# 4 Reboot

# Turn off swap and unmount all partitions.
(( swap_size > 0 )) && swapoff /mnt/swap/swapfile
umount -R /mnt

printf '\033[1mInstallation is done.\n'
