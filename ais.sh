#!/bin/sh
###############################################################
### Arch Installer Srcipt
###
### Copyright (C) 2017 Md. Tariqul Islam Neil
###
### By: Neil (Neil-seu)
### Email: tariqulislamseu@gmail.com
###
### Any questions, comments, or bug reports may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v3.0
###############################################################
clear
printf '\e[1;33m%-6s\e[m' "################## Welcome to the Arch Installer Script ######################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### To increase the root space, this script will automatically trigger the execution ###"
printf "\n"
read -p "press any key to continue"

## Increasing the cowspace and importing the archlinux-keyring

mount -o remount,size=2G /run/archiso/cowspace
printf "\n"
pacman -Syy archlinux-keyring git
printf "\n"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press any key to continue"
clear

## Unmounting devices in case if any devices are already mounted
umount /mnt/boot
umount -R /mnt


## Disk Partition

printf '\e[1;33m%-6s\e[m' "### Now opening the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
#echo "list of DISKs attached (HDD or SSD)"
printf '\e[1;33m%-6s\e[m' "List of your internal or external devices : "
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
printf '\e[1;33m%-6s\e[m' "Which one to do partition (in full form like /dev/sdX. X means sda/sdb/sdc etc.)"
echo "Enter your choice:"
read DEVICE_NUMBER
cfdisk $DEVICE_NUMBER
clear
printf '\e[1;33m%-6s\e[m' "To format and mount, choose your partition in full form you have just created from the list below :"
#lsblk -l | grep disk | awk '{print "/dev/" $1}'
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
echo "Enter your choice:"
read DEVICE_NUMBER
printf '\e[1;33m%-6s\e[m' "formatting..."
mkfs.ext4 $DEVICE_NUMBER
printf '\e[1;33m%-6s\e[m' "format successful"
printf "\n"
printf '\e[1;33m%-6s\e[m' "mounting root partition..."
mount $DEVICE_NUMBER /mnt
printf '\e[1;33m%-6s\e[m' "mount successful"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press any key to continue"
clear


## Installing the base system 
printf '\e[1;33m%-6s\e[m' "##  Now installing the base system and other important stuff... ##"
pacstrap /mnt base base-devel parted btrfs-progs f2fs-tools ntp net-tools iw wireless_tools networkmanager wpa_actiond wpa_supplicant dialog alsa-utils espeakup rp-pppoe pavucontrol bluez bluez-utils pulseaudio-bluetooth brltty
printf "\n"
read -p " Done! press any key to continue..."
clear


## Generating the fstab
printf '\e[1;33m%-6s\e[m' "##  Now generating the fstab, hold on... ##"
genfstab -U /mnt > /mnt/etc/fstab
printf "\n"
read -p "Success! press any key to continue..."
clear


## Entering the chroot into the new installed system
printf '\e[1;33m%-6s\e[m' "##  Now entering the chroot level to make some changes to the system... ##"
read -p "press any key to continue"
arch-chroot /mnt
mkinitcpio -p linux

#### Doing some basic stuff

printf '\e[1;33m%-6s\e[m' "## Set your root password: ##"
passwd
printf "\n"
read -p "press any key to continue"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Enter the computers hostname: ##"
read $HOSTNAME
echo $HOSTNAME > /etc/hostname
printf "\n"
echo " Done! "
read -p "press any key to continue"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Add new user and set password for the user account: ##"
echo "Enter the username:"
read $USERNAME
useradd -m -G wheel $USERNAME
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /mnt/etc/sudoers
echo "Enter the password for the user:"
passwd $USERNAME
echo "Success!"
read -p "press any key to continue"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
wireless_dev=`ip link | grep wl | awk '{print $2}' | sed 's/://'`
echo " $wireless_dev is found as your wireless device. Enabling... "
systemctl enable dhcpcd@${wireless_dev}.service
echo " SUCCESS! "
wired_dev=`ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://'`
echo " $wired_dev is found as your lan device. Enabling... "
systemctl enable dhcpcd@${wired_dev}.service
echo " SUCCESS! "
echo "Enabling Network manager service during boot..."
systemctl enable NetworkManager.service
echo " SUCCESS! "
echo "Enabling other necessary services..."
systemctl enable bluetooth.service
systemctl enable ppp@${wired_dev}.service
systemctl enable ntpd.service
echo "DONE!"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Setting your locale and generating the locale language: ##"
sed -i '/en_US.UTF-8 UTF-8/s/^#//' /mnt/etc/locale.gen
locale-gen
localectl set-locale LANG=en_US.UTF-8
echo "Locale generation successful!"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now select your timezone: ##"
tzselect
timedatectl set-timezone 'Asia/Dhaka'
timedatectl set-ntp true
echo "SUCCESS!"
read -p "press any key to continue..."
clear


## Installation and configuring GRUB
printf '\e[1;33m%-6s\e[m' "####  Now installing the GRUB for making the system bootable and detecting other OS in your HDD or SSD... ####"
pacman -Syy grub os-prober --noconfirm
grub-install --recheck $DEVICE_NUMBER
grub-mkconfig -o /boot/grub/grub.cfg
printf "\n"
read -p "Succes! press any key to proceed..."
clear


### Installing Desktop environment
printf '\e[1;33m%-6s\e[m' "######### Now Installing a Desktop environment: #########"
printf "\n"
sed -i -e '$a\\n[arch-anywhere]\nServer = http://arch-anywhere.org/repo/$arch\nSigLevel = Never' /mnt/etc/pacman.conf
sed -i -e '$a\\n[archlinuxfr]\nServer = http://repo.archlinux.fr/$arch\nSigLevel = Never' /mnt/etc/pacman.conf
pacman -Syy yaourt xf86-video-vesa mesa xf86-video-intel xorg-server xorg-utils xorg-xinit xterm xfce4 unrar unzip p7zip lzop cpio xarchiver xfce4-goodies gtk-engine-murrine lightdm-gtk-greeter --noconfirm
printf "\n"
echo "Enabling login manager services..."
systemctl enable lightdm.service
echo "Done!"
read -p "press any key to continue..."
clear


## Unmounting devices in case if any devices are already mounted
umount /mnt/boot
umount -R /mnt
printf '\e[1;33m%-6s\e[m' "###### All dirty work is done & devices are already unmounted! ######"
printf "\n"
read -p "press any key to reboot and unplug your USB or any CD-DVD drive..."
exit
reboot

