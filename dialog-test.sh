#!/bin/bash
clear
dialog --backtitle "Archbd Installer Script" --yesno "Welcome to Arch Installer. Proceed?" 10 30 
response=$?
clear
if [[ "$response" -eq "Yes" ]]
    then
       mount -o remount,size=4G /run/archiso/cowspace;
       printf "\n";
       printf '\e[1;33m%-6s\e[m' "Updating pacman keys....";
       printf "\n";
	   pacman-db-upgrade;
	   pacman-key --init;
	   pacman-key --populate archlinux;
       pacman-key --refresh-keys;
       dialog --infobox "Updated pacman keys successfully!" 10 30; 
       sleep 3;
       clear;
       pacman -Syy archlinux-keyring --noconfirm;
       printf "\n";
       dialog --infobox "Successful!" 10 20;
       sleep 3;
       clear;
    else
       exit;
fi
