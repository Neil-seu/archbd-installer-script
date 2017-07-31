echo "Now choose any mirror :"
printf "\n"
printf "\n"
countries=(" 1. Australia--AU 2. Austria--AT 3. Belarus--BY 4. Belgium--BE 5. Brazil--BR 6. Bulgaria--BG 7. Canada--CA 8. Chile--CL 9. China--CN 10. Colombia--CO 11. Czech Republic--CZ 12. Denmark--DK 13. Estonia--EE 14. Finland--FI 15. France--FR 16. Germany--DE 17. Greece--GR 18. Hong Kong--HK 19. Hungary--HU 20. Indonesia--ID 21. India--IN 22. Ireland--IE 23. Israel--IL 24. Italy--IT 25. Japan--JP 26. Kazakhstan--KZ 27. Korea--KR 28. Latvia--LV 29. Luxembourg--LU 30. Macedonia--MK 31. Netherlands--NL 32. New Caledonia--NC 33. New Zealand--NZ 34. Norway--NO 35. Poland--PL 36. Portugal--PT 37. Romania--RO 38. Russian--RU 39. Serbia--RS 40. Singapore--SG 41. Slovakia--SK 42. South Africa--ZA 43. Spain--ES 44. Sri Lanka--LK 45. Sweden--SE 46. Switzerland--CH 47. Taiwan--TW 48. Turkey--TR 49. Ukraine--UA 50. United Kingdom--GB 51. United States--US 52. Uzbekistan--UZ 53. VietNam--VN " )
for names in "${countries[@]}"; do
	echo -en "$value\t"
done | column
printf "\n"
printf "\n"
echo "Enter your country code:"
read COUNTRY_CODE
printf "\n"	
	if [[ "$COUNTRY_CODE" == *"ALL"* ]]; then
		printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
		rm /etc/pacman.d/mirrorlist.bak
		url="https://www.archlinux.org/mirrorlist/?country=all&use_mirror_status=on"
		tempfile=$(mktemp --suffix=-mirrorlist)
		wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
		mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
		mv -i "$tempfile" /etc/pacman.d/mirrorlist
		cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
		rankmirrors -n 10 /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
		rm /etc/pacman.d/mirrorlist.tmp
	else	
		printf '\e[1;33m%-6s\e[m' "##  Configuring and ranking arch mirror list. Please wait... ##"
		url="https://www.archlinux.org/mirrorlist/?country=${COUNTRY_CODE}&use_mirror_status=on"
		## making a temporary file where chosen mirror list will be placed and place it in a variable
		tempfile=$(mktemp --suffix=-mirrorlist)
		## Getting latest mirrorlist and saving to temp file
		wget -qO- "$url" | sed 's/^#Server/Server/g' > "$tempfile"
		## Backing up and place the new mirrorlist
		mv -i /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
		mv -i "$tempfile" /etc/pacman.d/mirrorlist
		cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.tmp
		rankmirrors /etc/pacman.d/mirrorlist.tmp > /etc/pacman.d/mirrorlist
		rm /etc/pacman.d/mirrorlist.tmp
	fi	
printf "\n"
echo "Mirror Updated Successfully!"
read -p "Press enter to refresh database..."
printf "\n"
pacman -Syy
exit
