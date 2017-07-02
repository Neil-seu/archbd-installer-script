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
echo -e "${Yellow}*> Updating pacman keys..."
	  pacman-db-upgrade
		pacman-key --init
		pacman-key --populate archlinux
    pacman-key --refresh-keys
echo -e "${Green}*> Updated: ${Yellow}Updated pacman keys successfully!" 
printf "\n"		
pacman -Syy archlinux-keyring git --noconfirm
printf "\n"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press enter to continue..."
clear

## Unmounting devices in case if any devices are already mounted
##umount /mnt/boot
##umount -R /mnt


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
printf '\e[1;33m%-6s\e[m' "format successful!"
printf "\n"
printf '\e[1;33m%-6s\e[m' "mounting root partition..."
mount $DEVICE_NUMBER /mnt
printf "\n"
printf '\e[1;33m%-6s\e[m' "mount successful"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press enter to continue..."
clear


#### Installing the base system 
##echo "Now choose any mirror :"
##printf "\n"
##printf "\n"
##echo "("Australia" "Austria" "Belarus" "Belgium" "Brazil" "Bulgaria" "Canada" "Chile" "China" "Colombia" "Czech Republic" "Denmark" "Estonia" "Finland" "France" "Germany" "Greece" "Hong Kong" "Hungary" "Indonesia" "India" "Ireland" "Israel" "Italy" "Japan" "Kazakhstan" "Korea" "Latvia" "Luxembourg" "Macedonia" "Netherlands" "New Caledonia" "New Zealand" "Norway" "Poland" "Portugal" "Romania" "Russian" "Serbia" "Singapore" "Slovakia" "South Africa" "Spain" "Sri Lanka" "Sweden" "Switzerland" "Taiwan" "Turkey" "Ukraine" "United Kingdom" "United States" "Uzbekistan" "Viet Nam")"
##printf "\n"
##echo "Enter your choice :"
##read COUNTRY 
##printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
##reflector --verbose --country '$COUNTRY' --sort rate --save /etc/pacman.d/mirrorlist
##printf "\n"
##echo "Mirrorlist successfully generated!"  
##printf "\n"
printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
printf "\n"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 10 -c Germany /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
printf "\n"
echo "Mirrorlist successfully generated!"
printf "\n"
printf '\e[1;33m%-6s\e[m' "##  Now installing the base system and other important stuff... ##"
pacstrap /mnt base base-devel parted btrfs-progs f2fs-tools ntp net-tools iw wireless_tools networkmanager wpa_actiond wpa_supplicant dialog alsa-utils espeakup rp-pppoe pavucontrol bluez bluez-utils pulseaudio-bluetooth brltty
printf "\n"
read -p " Done! press enter to continue..."
clear

archchroot(){
  echo "arch-chroot /mnt /root"
  cp $0 /mnt/root
  chmod 755 /mnt/root/$(basename "$0")
  arch-chroot /mnt /root/$(basename "$0") --chroot $1 $2
  rm /mnt/root/$(basename "$0")
  echo "exit"
}

## Generating the fstab
printf '\e[1;33m%-6s\e[m' "##  Now generating the fstab, hold on... ##"
genfstab -U /mnt > /mnt/etc/fstab
printf "\n"
read -p "Success! press enter to continue..."
clear


## Entering the chroot into the new installed system
printf '\e[1;33m%-6s\e[m' "##  Now entering the chroot level to make some changes to the system... ##"
printf "\n \n"
arch-chroot /mnt mkinitcpio -p linux
read -p "press enter to continue..."
clear



## Installation and configuring GRUB
printf '\e[1;33m%-6s\e[m' "####  Now installing the GRUB for making the system bootable and detecting other OS in your HDD or SSD... ####"
printf "\n"
printf "\n"
pacman -Syy grub os-prober --noconfirm
printf '\e[1;33m%-6s\e[m' "####  Now choose your root partition: ####"
printf "\n"
lsblk -o name,mountpoint,label,size,uuid
printf "\n"
echo "Enter your choice:"
printf "\n"
read DEVICE_NUMBER
archchroot grub-install --target=i386-pc --recheck $DEVICE_NUMBER
archchroot grub-mkconfig -o /boot/grub/grub.cfg
printf "\n"
printf "\n"
read -p "Succes! press enter to proceed..."
clear




## Unmounting devices in case if any devices are already mounted
umount /mnt/boot
umount -R /mnt
printf '\e[1;33m%-6s\e[m' "###### All dirty work is done & devices are already unmounted! ######"
printf "\n"
printf "\n"
read -p "press enter to reboot and unplug your USB or any CD-DVD drive..."
printf "\n"
reboot

