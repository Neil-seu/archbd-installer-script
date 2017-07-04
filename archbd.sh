#!/bin/sh
###############################################################
### Arch Installer Srcipt
###
### Copyright (C) 2017 Md. Tariqul Islam Neil
### short link: https://goo.gl/PgF5ik
###
### By: Neil (Neil-seu)
### Email: tariqulislamseu@gmail.com
###
### Any questions, comments, or bug reports or suggestions and ideas may be sent to above
### email address. Enjoy, and keep on using Arch.
###
### License: GPL v3.0
###############################################################
clear
printf '\e[1;33m%-6s\e[m' "################## Welcome to the Arch Installer Script ######################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### To increase the root space, this script will automatically trigger the execution ###"
printf "\n"
read -p "press enter to continue"

## Increasing the cowspace and importing the archlinux-keyring

mount -o remount,size=2G /run/archiso/cowspace
printf "\n \n"
printf '\e[1;33m%-6s\e[m' "Updating pacman keys...."
	  pacman-db-upgrade
		pacman-key --init
		pacman-key --populate archlinux
    pacman-key --refresh-keys
printf '\e[1;32m%-6s\e[m' "Updated pacman keys successfully!" 
printf "\n"		
pacman -Syy archlinux-keyring git --noconfirm
printf "\n"
printf '\e[1;32m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press enter to continue..."
clear

## Unmounting devices in case if any devices are already mounted
umount -R /mnt


## Disk Partition

printf '\e[1;33m%-6s\e[m' "### Now opening the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "List of your internal or external devices : "
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "Which one to do partition in full form like /dev/sdX. X means sda/sdb/sdc etc."
printf "\n"
printf "\n"
echo "Enter your choice:"
read DEVICE_NUMBER
cfdisk $DEVICE_NUMBER
clear
printf '\e[1;33m%-6s\e[m' "To format and mount, choose your partition in full form like /dev/sdX() you have just created from the list below :"
printf "\n"
printf "\n"
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
echo "Enter your choice:"
read DEVICE_NUMBER
printf '\e[1;33m%-6s\e[m' "formatting..."
mkfs.ext4 $DEVICE_NUMBER
printf '\e[1;32m%-6s\e[m' "format successful!"
printf "\n"
printf '\e[1;33m%-6s\e[m' "mounting root partition..."
mount $DEVICE_NUMBER /mnt
printf "\n"
printf '\e[1;32m%-6s\e[m' "mount successful"
printf "\n"
printf '\e[1;32m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press enter to continue..."
clear


#### Installing the base system 
echo "Now choose any mirror :"
printf "\n"
printf "\n"
echo "("Australia--AU" "Austria--AT" "Belarus--BY" "Belgium--BE" "Brazil--BR" "Bulgaria--BG" "Canada--CA" "Chile--CL" "China--CN" "Colombia--CO" "Czech Republic--CZ" "Denmark--DK" "Estonia--EE" "Finland--FI" "France--FR" "Germany--DE" "Greece--GR" "Hong Kong--HK" "Hungary--HU" "Indonesia--ID" "India--IN" "Ireland--IE" "Israel--IL" "Italy--IT" "Japan--JP" "Kazakhstan--KZ" "Korea--KR" "Latvia--LV" "Luxembourg--LU" "Macedonia--MK" "Netherlands--NL" "New Caledonia--NC" "New Zealand--NZ" "Norway--NO" "Poland--PL" "Portugal--PT" "Romania--RO" "Russian--RU" "Serbia--RS" "Singapore--SG" "Slovakia--SK" "South Africa--ZA" "Spain--ES" "Sri Lanka--LK" "Sweden--SE" "Switzerland--CH" "Taiwan--TW" "Turkey--TR" "Ukraine--UA" "United Kingdom--GB" "United States--US" "Uzbekistan--UZ" "Viet Nam--VN")"
printf "\n"
PS3="$prompt1"
echo "Enter your country code:"
read COUNTRY_CODE
printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
	url="https://www.archlinux.org/mirrorlist/?country=${COUNTRY_CODE}&use_mirror_status=on"
	## making a temporary file where chosen mirror list will be placed and place it in a variable
	tempfile = $(mktmp --suffix=-mirrorlist}
	## Getting latest mirrorlist and saving to temp file
	wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
	## Backing up and place the new mirrorlist
	mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	mv -i "$tempfile" /etc/pacman.d/mirrorlist
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
	rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
	rm /etc/pacman.d/mirrorlist.tmp
printf "\n"
echo "Mirrorlist successfully generated!"  
printf "\n"
read -p "press enter to continue..."
clear
printf '\e[1;33m%-6s\e[m' "##  Now installing the base system and other important stuff... ##"
pacstrap /mnt base base-devel parted btrfs-progs f2fs-tools fakechroot ntp net-tools iw wireless_tools networkmanager wpa_actiond wpa_supplicant dialog alsa-utils espeakup rp-pppoe pavucontrol bluez bluez-utils pulseaudio-bluetooth brltty
printf "\n"
read -p " Done! press enter to continue..."
clear


## Generating the fstab
printf '\e[1;33m%-6s\e[m' "##  Now generating the fstab, hold on... ##"
printf "\n"
genfstab -U /mnt > /mnt/etc/fstab
printf "\n"
read -p "Success! press enter to continue..."
clear


## Configuring mkinitcpio
printf '\e[1;33m%-6s\e[m' "##  Now Configuring mkinitcpio... ##"
printf "\n \n"
arch-chroot /mnt mkinitcpio -p linux
printf "\n"
printf '\e[1;32m%-6s\e[m' " Done!"
read -p "press enter to continue..."
clear



## Installation and configuring GRUB
printf '\e[1;33m%-6s\e[m' "####  Now installing the GRUB for making the system bootable and detecting other OS in your HDD or SSD... ####"
printf "\n"
printf "\n"
pacstrap /mnt grub os-prober --noconfirm
clear
printf '\e[1;33m%-6s\e[m' "####  Now choose your HDD or SSD like /dev/sdX. X means sda/sdb/sdc: ####"
printf "\n"
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
echo "Enter your choice:"
printf "\n"
read DEVICE_NUMBER
arch-chroot /mnt grub-install --recheck $DEVICE_NUMBER
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
printf "\n"
printf "\n"
read -p "Succes! press enter to proceed..."
clear

#### Doing some basic stuff

printf '\e[1;33m%-6s\e[m' "## Set your root password: ##"
printf "\n"
passwd
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Enter the computers hostname: ##"
printf "\n"
read $HOSTNAME
echo $HOSTNAME > /etc/hostname
printf "\n"
echo " Done! "
printf "\n"
read -p "press enter to continue"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Add new user and set password for the user account: ##"
printf "\n"
echo "Enter the username:"
printf "\n"
read USERNAME
useradd -m -G wheel $USERNAME
sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /mnt/etc/sudoers
printf "\n"
echo "Enter the password for the user:"
printf "\n"
passwd $USERNAME
printf "\n"
echo "Success!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
wireless_dev=`ip link | grep wl | awk '{print $2}' | sed 's/://'`
echo " $wireless_dev is found as your wireless device. Enabling... "
arch-chroot /mnt systemctl enable dhcpcd@${wireless_dev}.service
printf "\n"
echo " SUCCESS! "
printf "\n"
read -p "press enter to continue..."
printf "\n"
wired_dev=`ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://'`
echo " $wired_dev is found as your lan device. Enabling... "
arch-chroot /mnt systemctl enable dhcpcd@${wired_dev}.service
echo " SUCCESS! "
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "Enabling Network manager service during boot..."
arch-chroot /mnt systemctl enable NetworkManager.service
echo " SUCCESS! "
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "Enabling other necessary services..."
arch-chroot /mnt systemctl enable bluetooth.service
arch-chroot /mnt systemctl enable ppp@${wired_dev}.service
arch-chroot /mnt systemctl enable ntpd.service
echo "DONE!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
printf "\n"
echo "#####################################################################"
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Setting your locale and generating the locale language: ##"
sed -i '/en_US.UTF-8 UTF-8/s/^#//' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt localectl set-locale LANG=en_US.UTF-8
printf "\n"
echo "Locale generation successful!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now select your timezone: ##"
printf "\n"
tzselect
timedatectl set-timezone 'Asia/Dhaka'
arch-chroot /mnt timedatectl set-ntp true
echo "SUCCESS!"
printf "\n"
read -p "press enter to continue..."
clear



## Unmounting devices in case if any devices are already mounted
umount -R /mnt
printf '\e[1;32m%-6s\e[m' "###### All dirty work is done & devices are already unmounted! ######"
printf "\n"
printf "\n"
read -p "press enter to reboot and unplug your USB or any CD-DVD drive..."
printf "\n"
exit
reboot

