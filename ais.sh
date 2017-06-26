#!/bin/sh
#ArchInstallerSrcipt
printf '\e[1;33m%-6s\e[m' "################## Welcome to the Arch Installer Script #####################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "### To increase the root space, this script will automatically trigger the execution ###"
printf "\n"
read -p "press any key to continue"
mount -o remount,size=2G /run/archiso/cowspace
printf "\n"
printf '\e[1;33m%-6s\e[m' "### Success! ###"
printf "\n"
read -p "press any key to continue"
printf '\e[1;33m%-6s\e[m' "### Now use the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
cfdisk $device
diskpartcfdisk(){
  items=$(lsblk -d -p -n -l -o NAME -e 7,11)
  options=()
  for item in $items; do
    options+=("$item" "")
  done
  device=$(whiptail --backtitle "$apptitle" --title "$txteditparts (cfdisk)" --menu "" 0 0 0 \
    "${options[@]}" \
    3>&1 1>&2 2>&3)
  if [ "$?" = "0" ]; then
    clear
    cfdisk $device
  fi
}



printf '\e[1;37m%-6s\e[m' "##################################################################"
printf "\n"
read -p "press any key to continue"
