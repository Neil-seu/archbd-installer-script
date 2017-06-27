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
printf '\e[1;33m%-6s\e[m' "### Now opening the cfdisk for bios-mbr scheme. This script doesn't support uefi-gpt. So use with caution! ###"
printf "\n"
#cfdisk $device
#UMOUNT PARTITIONS {{{
umount_partitions(){
mounted_partitions=(`lsblk | grep ${MOUNTPOINT} | awk '{print $7}' | sort -r`)
swapoff -a
for i in ${mounted_partitions[@]}; do
umount $i
done
}
#}}}
#SELECT DEVICE {{{
select_device(){
devices_list=(`lsblk -d | awk '{print "/dev/" $1}' | grep 'sd\|hd\|vd\|nvme'`);
PS3="$prompt1"
echo -e "Attached Devices:\n"
lsblk -lnp -I 2,3,8,9,22,34,56,57,58,65,66,67,68,69,70,71,72,91,128,129,130,131,132,133,134,135 | awk '{print $1,$4,$6,$7}'| column -t
echo -e "\n"
echo -e "Select device to partition:\n"
select device in "${devices_list[@]}"; do
if contains_element "${device}" "${devices_list[@]}"; then
break
else
invalid_option
fi
done
BOOT_MOUNTPOINT=$device
}
#}}}
#CREATE PARTITION SCHEME {{{
create_partition_scheme(){
LUKS=0
LVM=0
print_title "https://wiki.archlinux.org/index.php/Partitioning "
print_info "Partitioning a hard drive allows one to logically divide the available space into sections that can be accessed independently of one another."
print_warning "Maintain Current does not work with LUKS"
partition_layouts=("Default" "LVM" "LVM+LUKS" "Maintain Current")
PS3="$prompt1"
echo -e "Select partition scheme:"
select OPT in "${partition_layouts[@]}"; do
partition_layout=$OPT
case "$REPLY" in
1)
create_partition
;;
2)
create_partition
setup_lvm
;;
3)
create_partition
setup_luks
setup_lvm
;;
4)
modprobe dm-mod
vgscan &> /dev/null
vgchange -ay &> /dev/null
;;
*)
invalid_option
;;
esac
[[ -n $OPT ]] && break
done
}
#}}}
#SETUP PARTITION{{{
create_partition(){
apps_list=("cfdisk" "cgdisk" "fdisk" "gdisk" "parted");
PS3="$prompt1"
echo -e "Select partition program:"
select OPT in "${apps_list[@]}"; do
if contains_element "$OPT" "${apps_list[@]}"; then
select_device
case $OPT in
parted)
parted -a opt ${device}
;;
*)
$OPT ${device}
;;
esac
break
else
invalid_option
fi
done
}



printf '\e[1;37m%-6s\e[m' "##################################################################"
printf "\n"
read -p "press any key to continue"
