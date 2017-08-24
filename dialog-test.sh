#!/bin/bash
clear
dialog --backtitle "Archbd Installer Script" --yesno "Welcome to Arch Installer. Proceed?" 10 30 
response=$?
clear
if [[ "$response" -eq "Yes" ]]
    then
       mount -o remount,size=4G /run/archiso/cowspace
       printf "\n"
       printf '\e[1;33m%-6s\e[m' "Updating pacman keys...."
       printf "\n"
	   pacman-db-upgrade
	   pacman-key --init
	   pacman-key --populate archlinux
       pacman-key --refresh-keys
       dialog --backtitle "Archbd Installer Script" --infobox "Updated pacman keys successfully!" 10 30
       sleep 3
       clear
       pacman -Syy archlinux-keyring --noconfirm
       printf "\n"
       dialog --backtitle "Archbd Installer Script" --infobox "Successful!" 10 20
       sleep 3
       clear
    else
       break
fi

dialog --backtitle "Archbd Installer Script" --infobox "Unmounting devices in case if any devices are already mounted. Please wait..." 10 40
umount -R /mnt
clear

dialog --backtitle "Archbd Installer Script" --yesno "Now opening the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! Proceed?" 10 40
response=$?
clear
if [[ "$response" -eq "Yes" ]]
    then
    
