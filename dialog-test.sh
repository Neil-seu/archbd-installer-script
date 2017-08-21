#!/bin/bash
clear
dialog --backtitle "Archbd Installer Script" --yesno "Welcome to Arch Installer. Proceed?" 10 30 
response=$?
clear
case $response in
    0) sudo pacman -Syyu;;
    1) exit;;
esac
