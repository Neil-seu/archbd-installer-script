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
read -p "press enter to continue..."

## Increasing the cowspace and importing the archlinux-keyring

mount -o remount,size=4G /run/archiso/cowspace
printf "\n"
printf '\e[1;33m%-6s\e[m' "Updating pacman keys...."
printf "\n"
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

## Disk Partition

printf '\e[1;33m%-6s\e[m' "### Now opening the cfdisk for bios-mbr scheme. \n This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "List of your internal or external devices : "
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "Which one to do partition? Type it in full form like /dev/sdX.\n X means sda/sdb/sdc etc."
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
printf '\e[1;32m%-6s\e[m' "mount successful!"
printf "\n"
printf '\e[1;32m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press enter to continue..."
clear


#### Installing the base system 
echo "Now choose any mirror :"
printf "\n"
printf "\n"
echo "("Australia--AU" || "Austria--AT" || "Belarus--BY" || "Belgium--BE" || "Brazil--BR" || "Bulgaria--BG" || "Canada--CA" || "Chile--CL" || "China--CN" || "Colombia--CO" || "Czech Republic--CZ" || "Denmark--DK" || "Estonia--EE" || "Finland--FI" || "France--FR" || "Germany--DE" || "Greece--GR" || "Hong Kong--HK" || "Hungary--HU" || "Indonesia--ID" || "India--IN" || "Ireland--IE" || "Israel--IL" || "Italy--IT" || "Japan--JP" || "Kazakhstan--KZ" || "Korea--KR" || "Latvia--LV" || "Luxembourg--LU" || "Macedonia--MK" || "Netherlands--NL" || "New Caledonia--NC" || "New Zealand--NZ" || "Norway--NO" || "Poland--PL" || "Portugal--PT" || "Romania--RO" || "Russian--RU" || "Serbia--RS" || "Singapore--SG" || "Slovakia--SK" || "South Africa--ZA" || "Spain--ES" || "Sri Lanka--LK" || "Sweden--SE" || "Switzerland--CH" || "Taiwan--TW" || "Turkey--TR" || "Ukraine--UA" || "United Kingdom--GB" || "United States--US" || "Uzbekistan--UZ" || "VietNam--VN")"
printf "\n"
echo "Enter your country code:"
read COUNTRY_CODE
printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
	url="https://www.archlinux.org/mirrorlist/?country=${COUNTRY_CODE}&use_mirror_status=on"
	## making a temporary file where chosen mirror list will be placed and place it in a variable
	tempfile=$(mktemp --suffix=-mirrorlist)
	## Getting latest mirrorlist and saving to temp file
	wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
	## Backing up and place the new mirrorlist
	mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
	mv -i "$tempfile" /etc/pacman.d/mirrorlist
	cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
	rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
	rm /etc/pacman.d/mirrorlist.tmp
printf "\n"
printf '\e[1;32m%-6s\e[m' "##  Mirrorlist Successfully Generated! ##" 
printf "\n"
read -p "press enter to continue..."
clear
printf '\e[1;33m%-6s\e[m' "##  Now installing the base system and other important stuff... ##"
pacstrap /mnt base base-devel parted btrfs-progs f2fs-tools fakechroot ntp net-tools iw wireless_tools networkmanager wpa_actiond wpa_supplicant dialog alsa-utils espeakup rp-pppoe pavucontrol bluez bluez-utils pulseaudio-bluetooth brltty
printf "\n"
read -p " Done! press enter to continue..."
clear




#### Doing some basic stuff

printf '\e[1;33m%-6s\e[m' "## Set your root password: ##"
printf "\n"
arch-chroot /mnt passwd
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Enter the computers hostname: ##"
printf "\n"
read HOSTNAME
echo "$HOSTNAME" > /mnt/etc/hostname
printf "\n"
echo " Done! "
printf "\n"
read -p "press enter to continue..."
printf "\n"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Setting your locale and generating the locale language: ##"
sed -i 's/^#en_US\.UTF-8 UTF-8/en_US\.UTF-8 UTF-8/' /mnt/etc/locale.gen
echo LANG=en_US.UTF-8 > /mnt/etc/locale.conf
echo KEYMAP=us >> /mnt/etc/vconsole.conf
arch-chroot /mnt locale-gen
printf "\n"
echo "Locale generation successful!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now select your timezone: ##"
printf "\n"
arch-chroot /mnt tzselect >> /mnt/etc/localtime
echo "SUCCESS!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Add new user and set password for the user account: ##"
printf "\n"
echo "Enter the username:"
printf "\n"
read usr
arch-chroot /mnt useradd -m -g users -G storage,power,wheel -s /mnt/bin/bash $usr
sed -i 's/^#\%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
printf "\n"
echo "Enter the password for the user:"
printf "\n"
arch-chroot /mnt passwd $usr
printf "\n"
echo "Success!"
printf "\n"
read -p "press enter to continue..."
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
wireless_dev=`ip link | grep wl | awk '{print $2}' | sed 's/://'`
printf "\n"
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
printf "\n"
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
clear

## Generating the fstab
printf '\e[1;33m%-6s\e[m' "##  Now generating the fstab, hold on... ##"
printf "\n"
genfstab -U /mnt >> /mnt/etc/fstab
printf "\n"
read -p "Success! press enter to continue..."
clear


## Configuring mkinitcpio
printf '\e[1;33m%-6s\e[m' "##  Now Configuring mkinitcpio... ##"
printf "\n"
arch-chroot /mnt mkinitcpio -p linux
printf "\n"
printf '\e[1;32m%-6s\e[m' " Done!"
printf "\n"
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

##### Installing Desktop environment and necessary drivers
printf '\e[1;33m%-6s\e[m' "######### Now Installing a Desktop environment: #########"
printf "\n"
sed -i '/\[multilib]/s/^#//g' /mnt/etc/pacman.conf
sed -i '/Include \= \/etc\/pacman\.d\/mirrorlist/s/^#//g' /mnt/etc/pacman.conf
sed -i -e '$a\\n[archlinuxfr]\nServer = http://repo.archlinux.fr/$arch\nSigLevel = Never' /mnt/etc/pacman.conf
printf "\n"
pacstrap /mnt xf86-video-vesa yaourt xorg xorg-xinit xorg-twm xorg-xclock xterm xfce4 lightdm unrar unzip p7zip cpio xarchiver xfce4-goodies gtk-engine-murrine lightdm-gtk-greeter --noconfirm
printf "\n"
echo "Enabling login manager services..."
arch-chroot /mnt systemctl enable lightdm.service
sed -i 's/^#exec startxfce4/exec startxfce4/' /mnt/home/$USERNAME/.xinitrc
printf "\n"
echo "Done!"
printf "\n"
clear
printf "Now choose your gpu to install it's driver: \n1. Nvidia\n2. AMD\n3. Intel\n"
read gpu
	if ["$gpu" -eq 1]; then
		echo "Selecting driver Nvidia..."
		pacstrap /mnt lib32-mesa-libgl xf86-video-nouveau --noconfirm
	elif ["$gpu" -eq 2]; then
		echo "Selecting driver AMD..."
		pacstrap /mnt xf86-video-amdgpu xf86-video-ati lib32-mesa-libgl --noconfirm
	elif ["$gpu" -eq 3]; then
		echo "Selecting driver Intel..."
		 pacstrap /mnt xf86-video-intel lib32-mesa-libgl --noconfirm
	else 
		echo "Unknown parameter"
	fi	
     
echo "All drivers are successfully installed!"
printf "\n"
read -p "press enter to continue..."
clear

#### Installing Some common softwares
printf '\e[1;33m%-6s\e[m' "######### Let's install some common software: #########"
printf "\n"
pacstrap /mnt chromium firefox deluge codeblocks gimp gpick vlc smplayer smplayer-skins simplescreenrecorder gparted htop libreoffice-fresh bleachbit thunderbird --noconfirm
printf "\n"
echo "Success!"
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
reboot
