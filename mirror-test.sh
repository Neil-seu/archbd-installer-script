echo "Now choose any mirror :"
printf "\n"
printf "\n"
countries=(
1. ALL			11. Colombia--CO		21. Indonesia--ID		31. Macedonia--MK  		41. Singapore--SG   		51. United Kingdom--GB
2. Australia--AU	12. Czech Republic--CZ		22. India--IN			32. Netherlands--NL		42. Slovakia--SK		52. United States--US
3. Austria--AT 		13. Denmark--DK			23. Ireland--IE			33. New Caledonia--NC		43. South Africa--ZA		53. Uzbekistan--UZ
4. Belarus--BY		14. Estonia--EE			24. Israel--IL			34. New Zealand--NZ		44. Spain--ES			54. VietNam--VN
5. Belgium--BE		15. Finland--FI			25. Italy--IT			35. Norway--NO			45. Sri Lanka--LK
6. Brazil--BR		16. France--FR			26. Japan--JP			36. Poland--PL			46. Sweden--SE
7. Bulgaria--BG		17. Germany--DE			27. Kazakhstan--KZ		37. Portugal--PT		47. Switzerland--CH
8. Canada--CA		18. Greece--GR			28. Korea--KR			38. Romania--RO			48. Taiwan--TW
9. Chile--CL		19. Hong Kong--HK		29. Latvia--LV			39. Russian--RU			49. Turkey--TR
10. China--CN		20. Hungary--HU			30. Luxembourg--LU		40. Serbia--RS			50. Ukraine--UA
)
echo ${countries[@]}
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
