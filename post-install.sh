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

##### Installing Desktop environment and necessary drivers
printf '\e[1;33m%-6s\e[m' "######### Now Installing a Desktop environment: #########"
printf "\n"
sed -i -e '$a\\n[archlinuxfr]\nServer = http://repo.archlinux.fr/$arch\nSigLevel = Never' /mnt/etc/pacman.conf
pacman -Syy yaourt xf86-video-vesa mesa xorg-server xorg-utils xorg-xinit xterm xfce4 unrar unzip p7zip lzop cpio xarchiver xfce4-goodies gtk-engine-murrine lightdm-gtk-greeter --noconfirm
printf "\n"
echo "Enabling login manager services..."
systemctl enable lightdm.service
echo "Done!"
printf "\n"
echo "Now choose your gpu to install it's driver :"
OPTIONS="nvidia amd intel"
      select opt in $OPTIONS; do
            if [ "$opt" = "nvidia" ]; then
                pacman -Syy lib32-mesa-libgl xf86-video-nouveau --noconfirm
                exit
               elif [ "$opt" = "amd" ]; then
                pacman -Syy xf86-video-amdgpu xf86-video-ati lib32-mesa-libgl --noconfirm
                exit
               elif [ "$opt" = "intel" ]; then
                pacman -Syy xf86-video-intel lib32-mesa-libgl --noconfirm
                exit
             fi
       done
echo "All drivers are successfully installed!"
printf "\n"
read -p "press enter to continue..."
clear


#### Installing Some common softwares
printf '\e[1;33m%-6s\e[m' "######### Would you mind to install some common software? I guess not! Let's do this: #########"
printf "\n"
pacman -Syyu chromium firefox deluge codeblocks gimp gpick vlc smplayer smplayer-skins simplescreenrecorder gparted htop libreoffice-fresh bleachbit thunderbird --noconfirm
printf "\n"
echo "Success!"
read -p "press enter to continue..."
clear

printf '\e[1;33m%-6s\e[m' "######### All work is done!! #########"
printf "\n"
read -p "press enter key to reboot..."
reboot
