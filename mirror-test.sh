echo "Now choose any mirror :"
printf "\n"
printf "\n"
echo "("Australia--AU" || "Austria--AT" || "Belarus--BY" || "Belgium--BE" || "Brazil--BR" || "Bulgaria--BG" || "Canada--CA" || "Chile--CL" || "China--CN" || "Colombia--CO" || "Czech Republic--CZ" || "Denmark--DK" || "Estonia--EE" || "Finland--FI" || "France--FR" || "Germany--DE" || "Greece--GR" || "Hong Kong--HK" || "Hungary--HU" || "Indonesia--ID" || "India--IN" || "Ireland--IE" || "Israel--IL" || "Italy--IT" || "Japan--JP" || "Kazakhstan--KZ" || "Korea--KR" || "Latvia--LV" || "Luxembourg--LU" || "Macedonia--MK" || "Netherlands--NL" || "New Caledonia--NC" || "New Zealand--NZ" || "Norway--NO" || "Poland--PL" || "Portugal--PT" || "Romania--RO" || "Russian--RU" || "Serbia--RS" || "Singapore--SG" || "Slovakia--SK" || "South Africa--ZA" || "Spain--ES" || "Sri Lanka--LK" || "Sweden--SE" || "Switzerland--CH" || "Taiwan--TW" || "Turkey--TR" || "Ukraine--UA" || "United Kingdom--GB" || "United States--US" || "Uzbekistan--UZ" || "VietNam--VN")"
printf "\n"
echo "Enter your country code:"
read COUNTRY_CODE
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
printf "\n"
