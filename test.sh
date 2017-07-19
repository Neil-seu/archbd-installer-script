
printf "Which network interface do you use: \n1. Wireless\n2. Wired\n3. Wireless & Wired\n"
printf "\n"
printf "Enter the number:"
read interface
	if [ "$interface" = 1 ]; then
		printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
		wireless_dev=`ip link | grep wl | awk '{print $2}' | sed 's/://'`
		printf "\n"
		echo " $wireless_dev is found as your wireless device. Enabling... "
		arch-chroot /mnt systemctl enable dhcpcd@${wireless_dev}.service
		printf "\n"
		echo " SUCCESS! "
		printf "\n"
		read -p "press enter to continue..."
	elif [ "$interface" = 2 ]; then	
		printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
		##printf "\n"
		wired_dev=`ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://'`
		echo " $wired_dev is found as your lan device. Enabling... "
		arch-chroot /mnt systemctl enable dhcpcd@${wired_dev}.service
		echo " SUCCESS! "
		printf "\n"
		read -p "press enter to continue..."
	elif [ "$interface" = 3 ]; then
		printf '\e[1;33m%-6s\e[m' "## Now detecting and enabling your network devices: ##"
		wireless_dev=`ip link | grep wl | awk '{print $2}' | sed 's/://'`
		printf "\n"
		echo " $wireless_dev is found as your wireless device. Enabling... "
		arch-chroot /mnt systemctl enable dhcpcd@${wireless_dev}.service
		printf "\n"
		echo " SUCCESS! "
		printf "\n"
		wired_dev=`ip link | grep "ens\|eno\|enp" | awk '{print $2}' | sed 's/://'`
		echo " $wired_dev is found as your lan device. Enabling... "
		arch-chroot /mnt systemctl enable dhcpcd@${wired_dev}.service
		echo " SUCCESS! "
		printf "\n"
		read -p "press enter to continue..."
	fi	
printf "\n"
echo "Enabling Network manager service during boot..."
arch-chroot /mnt systemctl enable NetworkManager.service
printf "\n"
echo " SUCCESS! "
printf "\n"
