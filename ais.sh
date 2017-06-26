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
cfdisk

printf '\e[1;34m%-6s\e[m' "##################################################################"
printf "\n"
read -p "press any key to continue"