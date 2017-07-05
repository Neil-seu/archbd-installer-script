clear
printf '\e[1;33m%-6s\e[m' "################## Welcome to the Arch Post Installer Script ######################"
printf "\n"
echo "#####################################################################"
printf "\n"
printf '\e[1;33m%-6s\e[m' "## Add new user and set password for the user account: ##"
printf "\n"
echo "Enter the username:"
printf "\n"
read USERNAME
useradd -m -g users -G wheel -s /bin/bash $USERNAME
sed -i 's/^#\%wheel ALL=(ALL) ALL/\%wheel ALL=(ALL) ALL/' /mnt/etc/sudoers
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
clear
