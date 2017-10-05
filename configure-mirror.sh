	#!/bin/bash

	#####################################
	######### Mirror Ranking ############
	#####################################
	
	mirror_rank() {

	dialog --backtitle "Archbd Installer Script" --yesno "Do you want to configure mirrorlist?" 10 30
	response=$?
	clear
	if [[ "$response" -eq "Yes" ]]
		then

		# check if any .bak file in pacman directory

		if [[ -f /etc/pacman.d/mirrorlist.bak ]]; then
			rm /etc/pacman.d/mirrorlist.bak
		fi	

		HEIGHT=15
		WIDTH=40
		CHOICE_HEIGHT=4
		BACKTITLE="Archbd Installer Script"
		TITLE="Arch Mirrorlist"
		MENU="Choose one of the following options:"

	OPTIONS=(1 "ALL Mirrors"
	         2 "Australia"
	         3 "Austria"
	         4 "Belarus"
	    	 5 "Belgium"
	    	 6 "Brazil" 
	    	 7 "Bulgaria" 
	    	 8 "Canada" 
	    	 9 "Chile" 
	    	 10 "China" 
	    	 11 "Colombia" 
	    	 12 "Czech-Republic" 
	    	 13 "Denmark" 
	    	 14 "Estonia" 
	    	 15 "Finland" 
	    	 16 "France" 
	    	 17 "Germany" 
	    	 18 "Greece" 
	    	 19 "Hong Kong" 
	    	 20 "Hungary" 
	    	 21 "Indonesia" 
	    	 22 "India" 
	    	 23 "Ireland" 
	    	 24 "Israel" 
	    	 25 "Italy" 
	    	 26 "Japan" 
	    	 27 "kazakhstan" 
	    	 28 "Korea" 
	    	 29 "Latvia" 
	    	 30 "Luxembourg" 
	    	 31 "Macedonia" 
	    	 32 "Netherlands" 
	    	 33 "New-Caledonia" 
	    	 34 "New-Zealand" 
	    	 35 "Norway" 
	    	 36 "Poland" 
	    	 37 "Portugal" 
	    	 38 "Romania" 
	    	 39 "Russia" 
	    	 40 "Serbia" 
	    	 41 "Singapore" 
	    	 42 "Slovakia" 
	    	 43 "South Africa" 
	    	 44 "spain" 
	    	 45 "SriLanka" 
	    	 46 "Sweden" 
	    	 47 "Switzerland" 
	    	 48 "Taiwan" 
	    	 49 "Turkey" 
	    	 50 "Ukraine" 
	    	 51 "United-Kingdom" 
	    	 52 "United-States" 
	    	 53 "Uzbekistan" 
	    	 54 "Vietnam")

	CHOICE=$(dialog --clear \
	                --backtitle "$BACKTITLE" \
	                --title "$TITLE" \
	                --menu "$MENU" \
	                $HEIGHT $WIDTH $CHOICE_HEIGHT \
	                "${OPTIONS[@]}" \
	                2>&1 >/dev/tty)

	clear
	case $CHOICE in
	        1)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=all&use_mirror_status=on"
	            tempfile=$(mktemp --suffix=-mirrorlist)											## making a temporary file where chosen mirror list will be placed and place it in a variable
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"						## Getting latest mirrorlist and saving to temp file
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak						## Backing up and place the new mirrorlist
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors -n 10 /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        2)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
			    url="https://www.archlinux.org/mirrorlist/?country=AU&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        3)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=AT&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        4)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=BY&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
			5)
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=BE&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        6)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=BR&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        7)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=BG&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;  
	        8)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CA&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        9)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CL&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        10)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CN&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        11)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CO&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        12)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CZ&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        13)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=DK&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        14)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=EE&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        15)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=FI&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        16)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=FR&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        17)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=DE&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        18)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=GR&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        19)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=HK&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        20)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=HU&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        21)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=ID&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        22)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=IN&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        23)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=IE&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        24)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=IL&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        25)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=IT&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        26)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=JP&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;
	        27)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=KZ&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        28)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=KR&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;; 
	        29)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=LV&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        30)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=LU&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        31)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=MK&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        32)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=NL&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        33)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=NC&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        34)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=NZ&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        35)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=NO&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        36)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=PL&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        37)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=PT&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        38)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=RO&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        39)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=RU&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        40)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=RS&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        41)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=SG&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        42)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=SK&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        43)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=ZA&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        44)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=ES&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        45)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=LK&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        46)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=SE&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        47)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=CH&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        48)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=TW&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        49)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=TR&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        50)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=UA&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        51)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=GB&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        52)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=US&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        53)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=UZ&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                 
	        54)
	        	dialog --backtitle "Archbd Installer Script" --infobox "Mirror fetching and ranking, Please wait..." 10 70
	            url="https://www.archlinux.org/mirrorlist/?country=VN&use_mirror_status=on" 
	            tempfile=$(mktemp --suffix=-mirrorlist)
				wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
				mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
				mv -i "$tempfile" /etc/pacman.d/mirrorlist
				cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
				rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
				chmod +r /etc/pacman.d/mirrorlist
				rm /etc/pacman.d/mirrorlist.tmp
				dialog --backtitle "Archbd Installer Script" --infobox "Mirror successfully generated!" 10 30
				sleep 3
	            ;;                                                                                                                                                                                                                                                                           
	esac
	clear

		else
			break
	fi		

	}
