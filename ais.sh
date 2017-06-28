#!/bin/sh
#ArchInstallerSrcipt
clear
printf '\e[1;33m%-6s\e[m' "################## Welcome to the Arch Installer Script #####################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### To increase the root space, this script will automatically trigger the execution ###"
printf "\n"
read -p "press any key to continue"
mount -o remount,size=2G /run/archiso/cowspace
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press any key to continue"
clear
printf '\e[1;33m%-6s\e[m' "### Now opening the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
#cfdisk $device
echo "list of DISKs attached (HDD or SSD)"
#lsblk -l | grep disk | awk '{print "/dev/" $1}'
lsblk -o name,mountpoint,label,size,uuid
echo ""
echo "Which one to do partition (in full form like /dev/sdX. X means sda/sdb/sdc etc.)"
echo "Enter your choice:$DEVICE_NUMBER"
read DEVICE_NUMBER
cfdisk $DEVICE_NUMBER
clear
echo "To format and mount, choose your partition in full form you have just created from the list below :"
#lsblk -l | grep disk | awk '{print "/dev/" $1}'
lsblk -o name,mountpoint,label,size,uuid
echo ""
read DEVICE_NUMBER
echo "formatting..."
mkfs.ext4 $DEVICE_NUMBER
echo "format successful"
echo "mounting root partition..."
mount $DEVICE_NUMBER /mnt
echo "mount successful"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
clear
printf '\e[1;37m%-6s\e[m' "##################################################################"
printf "\n"
read -p "press any key to continue"
