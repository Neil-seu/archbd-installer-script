#!/bin/bash
clear
dialog --backtitle "Archbd Installer Script" --yesno "Welcome to Arch Installer. Proceed?" 10 30 
response=$?
clear
if [[ "$response" -eq "Yes" ]]
    then
       mount -o remount,size=4G /run/archiso/cowspace
       printf "\n"
       dialog --backtitle "Archbd Installer Script" --yesno "Do you want to refresh pacman keys (recommended)?" 10 30
       response=$?
       if [[ "$response" -eq "Yes" ]]
       	   then
       		printf '\e[1;33m%-6s\e[m' "Updating pacman keys...."
       		printf "\n"
	   	pacman-db-upgrade
	   	pacman-key --init
	   	pacman-key --populate archlinux
       		pacman-key --refresh-keys
       		dialog --backtitle "Archbd Installer Script" --infobox "Updated pacman keys successfully!" 10 30
       		sleep 3
       		clear
	   else
	   	break
	fi	
       pacman -Syy archlinux-keyring --noconfirm
       printf "\n"
       dialog --backtitle "Archbd Installer Script" --infobox "Successful!" 10 20
       sleep 3
       clear
    else
       break
fi

dialog --backtitle "Archbd Installer Script" --infobox "Unmounting devices in case if any devices are already mounted. \
	Please wait..." 10 40
	umount -R /mnt
	sleep 3
	clear

dialog --backtitle "Archbd Installer Script" --yesno "Now opening the cfdisk for bios-mbr scheme. \
	This script doesn't support uefi-gpt. \
	So use with caution! \
	Press No if you don't want to configure your partition. Proceed?" 10 70
	response=$?
	clear
	if [[ "$response" -eq "Yes" ]] then
    		printf '\e[1;33m%-6s\e[m' "List of your internal or external devices : "
		printf '\n'
		printf '\n'
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
		dialog --backtitle "Archbd Installer Script" --infobox "Partition Successfully configured!" 10 30
		sleep 3
		clear
	else
		break
	fi
	
	
dialog --backtitle "Archbd Installer Script" --yesno "Do you want to configure mirrorlist?" 10 30
	response=$?
	clear
	if [[ "$response" -eq "Yes" ]] then
		
