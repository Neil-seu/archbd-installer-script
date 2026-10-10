#!/usr/bin/env bash
#
# archbd-install.sh v2 - Arch Linux installer (UEFI + BIOS)
# Original: (C) 2017 Md. Tariqul Islam Neil (Neil-seu) - License: GPL v3.0
#
# Usage (from the official Arch ISO, as root):
#     bash archbd-install.sh                 # interactive
#     bash archbd-install.sh -c my.conf      # answers from a file, asks the rest
#     bash archbd-install.sh -n              # dry run: ask, show the plan, change nothing
#
# Highlights: ext4 / btrfs (subvolumes + snapper) / xfs, automatic or manual
# partitioning, optional /home partition, zram, VM guest tools, config files.

set -Eeuo pipefail
LOG=/tmp/archbd-install.log
trap 'printf "\n\e[1;31mFailed on line %s. Installation stopped (log: %s).\e[0m\n" "$LINENO" "$LOG" >&2' ERR

# ---------------------------------------------------------------- defaults --
DEFAULT_TIMEZONE="Asia/Dhaka"
DEFAULT_LOCALE="en_US.UTF-8"
DEFAULT_KEYMAP="us"
ESP_SIZE="512MiB"

# ----------------------------------------------------------------- helpers --
c()    { printf '\e[1;%sm%s\e[0m\n' "$1" "$2"; }
info() { c 33 "==> $*"; }
ok()   { c 32 "OK: $*"; }
warn() { c 31 "!!  $*"; }
die()  { warn "$*"; exit 1; }

usage() {
    cat <<'USAGE'
Usage: archbd-install.sh [-c CONFIG] [-n] [-h]
  -c CONFIG   read answers from CONFIG (shell variables); anything missing is asked
  -n          dry run: ask questions and print the plan, but change nothing
  -h          this help
USAGE
}

ask() {   # ask "prompt" [default]  -> prints the answer
    local reply
    read -r -p "$1${2:+ [$2]}: " reply
    echo "${reply:-${2:-}}"
}

confirm() {   # confirm "question" [y|n default]
    local def=${2:-n} hint reply
    [[ $def == y ]] && hint="Y/n" || hint="y/N"
    read -r -p "$1 [$hint]: " reply
    reply=${reply:-$def}
    [[ $reply =~ ^[Yy]([Ee][Ss])?$ ]]
}

# "get" helpers: skip the question when the variable is already set (config file)
get() {       # get VAR "prompt" [default]
    local var=$1
    if [[ ! -v $var ]]; then printf -v "$var" '%s' "$(ask "$2" "${3:-}")"; fi
}

get_yn() {    # get_yn VAR "question" [y|n]
    local var=$1
    if [[ ! -v $var ]]; then
        if confirm "$2" "${3:-n}"; then printf -v "$var" y; else printf -v "$var" n; fi
    fi
}

get_choice() {   # get_choice VAR "prompt" opt1 opt2 ...
    local var=$1 PS3="$2 " pick=""
    shift 2
    if [[ ! -v $var ]]; then
        select pick in "$@"; do [[ -n ${pick:-} ]] && break; done
        printf -v "$var" '%s' "$pick"
    fi
}

validate() {  # validate VALUE NAME opt1 opt2 ...
    local v=$1 name=$2 o
    shift 2
    for o in "$@"; do [[ $v == "$o" ]] && return 0; done
    die "Invalid $name '$v' (allowed: $*)"
}

need_block() { [[ -b $1 ]] || die "$1 is not a block device."; }

part_path() {  # part_path /dev/sda 2 -> /dev/sda2 ; /dev/nvme0n1 2 -> /dev/nvme0n1p2
    if [[ $1 =~ [0-9]$ ]]; then echo "${1}p$2"; else echo "$1$2"; fi
}

# ------------------------------------------------------------ filesystems ---
make_fs() {    # make_fs FS DEVICE LABEL
    case $1 in
        ext4)  mkfs.ext4 -F -L "$3" "$2" ;;
        btrfs) mkfs.btrfs -f -L "$3" "$2" ;;
        xfs)   mkfs.xfs  -f -L "$3" "$2" ;;
        *)     die "Unsupported filesystem: $1" ;;
    esac
}

mount_opts() { # mount_opts FS
    case $1 in
        btrfs) echo "noatime,compress=zstd:1" ;;
        *)     echo "noatime" ;;
    esac
}

# -------------------------------------------------------------- arguments ---
parse_args() {
    local opt OPTIND=1
    CONFIG_FILE=""; DRY_RUN=n
    while getopts ":c:nh" opt; do
        case $opt in
            c) CONFIG_FILE=$OPTARG ;;
            n) DRY_RUN=y ;;
            h) usage; exit 0 ;;
            *) usage; exit 1 ;;
        esac
    done
    if [[ -n $CONFIG_FILE ]]; then
        [[ -f $CONFIG_FILE ]] || die "Config file not found: $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        ok "Loaded answers from $CONFIG_FILE"
    fi
}

# -------------------------------------------------------------- preflight ---
preflight() {
    [[ $EUID -eq 0 ]] || die "Run as root (on the Arch ISO you already are)."

    if [[ -d /sys/firmware/efi/efivars ]]; then BOOT_MODE=uefi; else BOOT_MODE=bios; fi
    ok "Boot mode: $BOOT_MODE"

    if [[ $DRY_RUN != y ]]; then
        ping -c1 -W3 archlinux.org &>/dev/null ||
            die "No internet. For Wi-Fi use: iwctl station wlan0 connect <SSID>  (then re-run)"
        timedatectl set-ntp true
        # The ISO runs reflector at boot; stop it so it cannot race with ours
        systemctl stop reflector.service 2>/dev/null || true
        # Faster downloads on the live system
        sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    fi
}

# --------------------------------------------------------- system questions -
gather_system() {
    clear
    info "Arch installer v2 - answer the questions now, installation runs afterwards."
    echo

    get HOST_NAME "Hostname" "archbd"
    [[ $HOST_NAME =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]] || die "Invalid hostname: $HOST_NAME"

    get USERNAME_ "New username"
    [[ $USERNAME_ =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid username (lowercase letters, digits, - and _ only): '$USERNAME_'"

    get TIMEZONE "Timezone (Region/City)" "$DEFAULT_TIMEZONE"
    [[ -f /usr/share/zoneinfo/$TIMEZONE ]] || die "Unknown timezone: $TIMEZONE"

    get LOCALE "Locale" "$DEFAULT_LOCALE"
    if [[ -f /usr/share/i18n/SUPPORTED ]] && ! grep -q "^${LOCALE} " /usr/share/i18n/SUPPORTED; then
        die "Unknown locale: $LOCALE"
    fi

    get KEYMAP "Console keymap" "$DEFAULT_KEYMAP"
    if [[ -d /usr/share/kbd/keymaps ]] && [[ -z $(find /usr/share/kbd/keymaps -name "$KEYMAP.map.gz" -print -quit) ]]; then
        die "Unknown keymap: $KEYMAP"
    fi

    get MIRROR_COUNTRIES "Mirror country code(s), comma-separated, blank = worldwide" ""

    echo
    info "Desktop environment:"
    get_choice DE "Choose (number):" xfce gnome kde cinnamon mate lxqt none
    validate "$DE" DE xfce gnome kde cinnamon mate lxqt none

    echo
    info "Root filesystem:"
    echo "  ext4  = simple and rock solid"
    echo "  btrfs = subvolumes, compression, snapshots (snapper + GRUB snapshot menu)"
    echo "  xfs   = great for big files, no shrinking"
    get_choice FS_TYPE "Choose (number):" ext4 btrfs xfs
    validate "$FS_TYPE" FS_TYPE ext4 btrfs xfs

    echo
    get_yn WANT_APPS "Install common apps (Firefox, VLC, LibreOffice, GIMP, GParted, htop, zsh...)?" y
    get_yn WANT_FIREWALL "Enable a firewall (ufw: deny incoming, allow outgoing)?" n
}

# ------------------------------------------------------ hardware detection --
detect_hardware() {
    VIRT=$(systemd-detect-virt || true)
    GPU_INFO=""
    if [[ $VIRT == none ]]; then
        GPU_INFO=$(lspci | grep -Ei 'vga|3d|display' || true)
        if grep -qi nvidia <<<"$GPU_INFO"; then
            echo
            info "NVIDIA GPU detected:"
            echo "  nvidia-open = proprietary-stack driver for RTX 20-series / GTX 16-series and newer"
            echo "  nouveau     = open source Mesa driver (NVK), works on any card"
            echo "  (GTX 10-series and older need a legacy driver from the AUR: pick nouveau for now)"
            get_choice NVIDIA_CHOICE "Choose (number):" nvidia-open nouveau
            validate "$NVIDIA_CHOICE" NVIDIA_CHOICE nvidia-open nouveau
        fi
    fi
}

# ------------------------------------------------------------------ layout --
choose_disk() {   # sets INSTALL_DISK (menu), skipping the live USB
    if [[ -v INSTALL_DISK ]]; then need_block "$INSTALL_DISK"; return; fi

    local live_src live_disk="" line
    local -a disks=() menu=()
    live_src=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
    if [[ -n $live_src ]]; then
        live_disk="/dev/$(lsblk -no pkname "$live_src" 2>/dev/null | head -n1 || true)"
    fi

    mapfile -t disks < <(lsblk -dpno NAME,SIZE,MODEL -e 7,11)
    for line in "${disks[@]}"; do
        [[ ${line%% *} == "$live_disk" ]] && continue
        menu+=("$line")
    done
    [[ ${#menu[@]} -gt 0 ]] || die "No installable disks found."

    local PS3="Disk number: " pick=""
    select pick in "${menu[@]}"; do [[ -n ${pick:-} ]] && break; done
    INSTALL_DISK=${pick%% *}
}

layout_auto() {
    WIPE_DISK=y
    choose_disk
    if [[ $BOOT_MODE == uefi ]]; then
        EFI_PART=$(part_path "$INSTALL_DISK" 1)
        ROOT_PART=$(part_path "$INSTALL_DISK" 2)
    else
        EFI_PART=""
        ROOT_PART=$(part_path "$INSTALL_DISK" 1)
    fi
    FORMAT_EFI=y
    SWAP_PART=""
    HOME_PART=""
    FORMAT_HOME=n
}

layout_manual() {
    WIPE_DISK=n
    if [[ ! -v ROOT_PART ]]; then
        clear
        lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
        echo
        if [[ $DRY_RUN != y ]] && confirm "Open cfdisk to create/edit partitions first?" n; then
            choose_disk
            if [[ $BOOT_MODE == uefi ]]; then
                warn "UEFI: use a GPT disk with an EFI System partition (~512M) plus a root partition."
            else
                warn "BIOS: use a DOS (MBR) label with a bootable root partition."
            fi
            cfdisk "$INSTALL_DISK"
            clear
            lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS
            echo
        fi
    fi

    get ROOT_PART "Root partition (e.g. /dev/sda2)"
    need_block "$ROOT_PART"

    if [[ $BOOT_MODE == uefi ]]; then
        get EFI_PART "EFI System partition (e.g. /dev/sda1)"
        need_block "$EFI_PART"
        get_yn FORMAT_EFI "Format the EFI partition? (say NO if another OS already uses it)" n
    else
        EFI_PART=""; FORMAT_EFI=n
    fi

    get SWAP_PART "Swap partition (blank = none)"
    [[ -z $SWAP_PART ]] || need_block "$SWAP_PART"

    get HOME_PART "Separate /home partition (blank = none)"
    if [[ -n $HOME_PART ]]; then
        need_block "$HOME_PART"
        get_yn FORMAT_HOME "Format $HOME_PART? (NO keeps the existing data)" n
    else
        FORMAT_HOME=n
    fi

    local p s
    local -a seen=()
    for p in "$ROOT_PART" "$EFI_PART" "$SWAP_PART" "$HOME_PART"; do
        [[ -z $p ]] && continue
        for s in "${seen[@]:-}"; do
            [[ $s == "$p" ]] && die "$p was given for two different purposes."
        done
        seen+=("$p")
    done
}

choose_layout() {
    echo
    info "Partitioning:"
    echo "  auto   = wipe ONE whole disk and create EFI/boot + root automatically"
    echo "  manual = use partitions you pick (or create them with cfdisk)"
    get_choice PARTITION_MODE "Choose (number):" auto manual
    validate "$PARTITION_MODE" PARTITION_MODE auto manual

    if [[ $PARTITION_MODE == auto ]]; then layout_auto; else layout_manual; fi

    if [[ -n $SWAP_PART ]]; then
        ENABLE_ZRAM=n
    else
        get_yn ENABLE_ZRAM "Use compressed RAM swap (zram)?" y
    fi
    get_yn ENABLE_OSPROBER "Dual-boot with another OS? (enables os-prober in GRUB)" n

    if [[ $PARTITION_MODE == auto ]]; then
        TARGET_DISK=$INSTALL_DISK
    else
        TARGET_DISK="/dev/$(lsblk -no pkname "$ROOT_PART" | head -n1)"
    fi
}

show_summary() {
    echo
    info "Installation plan"
    printf '  %-14s %s\n' "Boot mode:"   "$BOOT_MODE${VIRT:+ (virt: $VIRT)}"
    printf '  %-14s %s\n' "Hostname:"    "$HOST_NAME"
    printf '  %-14s %s\n' "User:"        "$USERNAME_"
    printf '  %-14s %s\n' "Timezone:"    "$TIMEZONE"
    printf '  %-14s %s\n' "Desktop:"     "$DE"
    printf '  %-14s %s\n' "Filesystem:"  "$FS_TYPE"
    if [[ $WIPE_DISK == y ]]; then
        warn "ERASE EVERYTHING on $INSTALL_DISK:"
        [[ $BOOT_MODE == uefi ]] && printf '      %s  EFI System (%s, FAT32)\n' "$EFI_PART" "$ESP_SIZE"
        printf '      %s  root (%s, rest of disk)\n' "$ROOT_PART" "$FS_TYPE"
    else
        warn "FORMAT $ROOT_PART as $FS_TYPE"
        [[ $FORMAT_EFI == y ]] && warn "FORMAT $EFI_PART as FAT32"
        [[ -n $SWAP_PART ]] && warn "mkswap $SWAP_PART"
        if [[ -n $HOME_PART ]]; then
            if [[ $FORMAT_HOME == y ]]; then warn "FORMAT $HOME_PART as $FS_TYPE (/home)"; else echo "  keep existing data on $HOME_PART (/home)"; fi
        fi
        [[ $FORMAT_EFI != y && -n $EFI_PART ]] && echo "  keep existing $EFI_PART (EFI)"
    fi
    printf '  %-14s %s\n' "Bootloader:" "GRUB ($BOOT_MODE)$([[ $BOOT_MODE == bios ]] && echo " on $TARGET_DISK")"
    printf '  %-14s %s\n' "zram:" "$ENABLE_ZRAM"
    echo

    if [[ $DRY_RUN == y ]]; then
        ok "Dry run finished - nothing was changed."
        exit 0
    fi
    if [[ ${ASSUME_YES:-n} != y ]]; then
        [[ $(ask "Type YES (capitals) to start") == YES ]] || die "Aborted by user."
    fi
}

# --------------------------------------------------- mirrors and keyring ----
mirrors_and_keyring() {
    info "Ranking mirrors with reflector..."
    local args=(--protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist)
    if [[ -n $MIRROR_COUNTRIES ]]; then args+=(--country "$MIRROR_COUNTRIES"); fi
    if reflector "${args[@]}"; then
        ok "Mirrorlist updated."
    else
        warn "reflector failed; keeping the existing mirrorlist."
    fi
    info "Refreshing the keyring..."
    pacman -Sy --noconfirm archlinux-keyring
}

# ----------------------------------------------- partition, format, mount ---
apply_layout() {
    swapoff -a || true
    if mountpoint -q /mnt; then umount -R /mnt; fi

    if [[ $WIPE_DISK == y ]]; then
        info "Partitioning $INSTALL_DISK..."
        wipefs -af "$INSTALL_DISK"
        if [[ $BOOT_MODE == uefi ]]; then
            sfdisk --quiet "$INSTALL_DISK" <<EOF
label: gpt
,${ESP_SIZE},U
,,L
EOF
        else
            sfdisk --quiet "$INSTALL_DISK" <<EOF
label: dos
,,L,*
EOF
        fi
        partprobe "$INSTALL_DISK"
        udevadm settle
    fi

    info "Creating $FS_TYPE on $ROOT_PART..."
    local opts sv
    opts=$(mount_opts "$FS_TYPE")
    wipefs -a "$ROOT_PART"
    make_fs "$FS_TYPE" "$ROOT_PART" archroot

    if [[ $FS_TYPE == btrfs ]]; then
        mount "$ROOT_PART" /mnt
        for sv in @ @log @pkg @snapshots; do btrfs subvolume create "/mnt/$sv"; done
        if [[ -z $HOME_PART ]]; then btrfs subvolume create /mnt/@home; fi
        umount /mnt

        mount -o "$opts,subvol=@" "$ROOT_PART" /mnt
        mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg /mnt/.snapshots
        mount -o "$opts,subvol=@log"       "$ROOT_PART" /mnt/var/log
        mount -o "$opts,subvol=@pkg"       "$ROOT_PART" /mnt/var/cache/pacman/pkg
        mount -o "$opts,subvol=@snapshots" "$ROOT_PART" /mnt/.snapshots
        if [[ -z $HOME_PART ]]; then mount -o "$opts,subvol=@home" "$ROOT_PART" /mnt/home; fi
    else
        mount -o "$opts" "$ROOT_PART" /mnt
        mkdir -p /mnt/home
    fi

    if [[ -n $HOME_PART ]]; then
        if [[ $FORMAT_HOME == y ]]; then
            wipefs -a "$HOME_PART"
            make_fs "$FS_TYPE" "$HOME_PART" archhome
            mount -o "$opts" "$HOME_PART" /mnt/home
        else
            mount -o noatime "$HOME_PART" /mnt/home
        fi
    fi

    if [[ $BOOT_MODE == uefi ]]; then
        if [[ $FORMAT_EFI == y ]]; then mkfs.fat -F32 "$EFI_PART"; fi
        mkdir -p /mnt/boot/efi
        mount "$EFI_PART" /mnt/boot/efi
    fi

    if [[ -n $SWAP_PART ]]; then
        mkswap "$SWAP_PART"
        swapon "$SWAP_PART"
    fi
    ok "Filesystems created and mounted under /mnt."
}

# ---------------------------------------------------------- package lists ---
build_package_lists() {
    BASE_PKGS=(base linux linux-firmware base-devel sudo nano git wget
               networkmanager grub ntfs-3g dosfstools exfatprogs
               bash-completion man-db man-pages pacman-contrib reflector)
    if [[ $BOOT_MODE == uefi ]]; then BASE_PKGS+=(efibootmgr); fi
    if [[ $ENABLE_ZRAM == y ]]; then BASE_PKGS+=(zram-generator); fi
    if [[ $ENABLE_OSPROBER == y ]]; then BASE_PKGS+=(os-prober); fi
    if grep -q GenuineIntel /proc/cpuinfo; then BASE_PKGS+=(intel-ucode); fi
    if grep -q AuthenticAMD /proc/cpuinfo; then BASE_PKGS+=(amd-ucode); fi

    case $FS_TYPE in
        btrfs) BASE_PKGS+=(btrfs-progs) ;;
        xfs)   BASE_PKGS+=(xfsprogs) ;;
    esac

    SERVICES=(NetworkManager bluetooth fstrim.timer paccache.timer reflector.timer systemd-timesyncd)

    EXTRA_PKGS=(pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol
                bluez bluez-utils
                gst-plugins-good gst-plugins-bad gst-libav ffmpeg
                noto-fonts noto-fonts-emoji ttf-liberation ttf-roboto)

    if [[ $FS_TYPE == btrfs ]]; then EXTRA_PKGS+=(snapper grub-btrfs inotify-tools); fi

    if [[ $WANT_FIREWALL == y ]]; then
        EXTRA_PKGS+=(ufw)
        SERVICES+=(ufw)
    fi

    # ---- desktop + display manager
    DM=""
    case $DE in
        xfce)     EXTRA_PKGS+=(xorg-server xfce4 xfce4-goodies network-manager-applet file-roller lightdm lightdm-gtk-greeter); DM=lightdm ;;
        gnome)    EXTRA_PKGS+=(gnome gnome-tweaks); DM=gdm ;;
        kde)      EXTRA_PKGS+=(plasma-meta konsole dolphin kate ark sddm); DM=sddm ;;
        cinnamon) EXTRA_PKGS+=(xorg-server cinnamon nemo-fileroller gnome-terminal lightdm lightdm-gtk-greeter); DM=lightdm ;;
        mate)     EXTRA_PKGS+=(xorg-server mate mate-extra network-manager-applet lightdm lightdm-gtk-greeter); DM=lightdm ;;
        lxqt)     EXTRA_PKGS+=(xorg-server lxqt breeze-icons network-manager-applet sddm); DM=sddm ;;
        none)     ;;
    esac
    if [[ -n $DM ]]; then SERVICES+=("$DM"); fi

    # ---- optional apps
    if [[ $WANT_APPS == y ]]; then
        EXTRA_PKGS+=(firefox vlc libreoffice-fresh gimp gparted htop zsh zsh-syntax-highlighting
                     rsync unzip p7zip unrar)
    fi

    # ---- VM guest tools / GPU drivers
    case $VIRT in
        oracle)   EXTRA_PKGS+=(virtualbox-guest-utils); SERVICES+=(vboxservice) ;;
        kvm|qemu) EXTRA_PKGS+=(qemu-guest-agent spice-vdagent); SERVICES+=(qemu-guest-agent) ;;
        vmware)   EXTRA_PKGS+=(open-vm-tools); SERVICES+=(vmtoolsd vmware-vmblock-fuse) ;;
        none)
            if grep -qi intel <<<"$GPU_INFO"; then
                EXTRA_PKGS+=(mesa vulkan-intel intel-media-driver lib32-mesa lib32-vulkan-intel)
            fi
            if grep -qiE 'amd|ati|radeon' <<<"$GPU_INFO"; then
                EXTRA_PKGS+=(mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon)
            fi
            if grep -qi nvidia <<<"$GPU_INFO"; then
                if [[ ${NVIDIA_CHOICE:-nouveau} == nvidia-open ]]; then
                    EXTRA_PKGS+=(nvidia-open nvidia-utils lib32-nvidia-utils)
                else
                    EXTRA_PKGS+=(mesa vulkan-nouveau lib32-mesa)
                fi
            fi
            ;;
    esac
}

# ---------------------------------------------------------------- install ---
install_base() {
    info "Installing the base system (log: $LOG)..."
    pacstrap -K /mnt "${BASE_PKGS[@]}" 2>&1 | tee -a "$LOG"
    genfstab -U /mnt > /mnt/etc/fstab
    if [[ $FS_TYPE == btrfs ]]; then
        # fixed subvolume IDs break snapshot rollbacks; mount by name only
        sed -i 's/subvolid=[0-9]*,//' /mnt/etc/fstab
    fi
    ok "Base installed, fstab generated."
}

install_snapper_helper() {
    install -Dm755 /dev/stdin /mnt/usr/local/bin/archbd-setup-snapper <<'HELPER'
#!/usr/bin/env bash
# Run once after the first boot:  sudo archbd-setup-snapper
set -euo pipefail
[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"
findmnt -n -o FSTYPE / | grep -q btrfs || { echo "Root is not btrfs."; exit 1; }
if snapper list-configs 2>/dev/null | grep -q '^root'; then
    echo "Snapper is already configured for /."; exit 0
fi

# snapper wants to create its own /.snapshots; swap in our @snapshots subvolume
umount /.snapshots 2>/dev/null || true
rmdir /.snapshots 2>/dev/null || true
snapper -c root create-config /
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

snapper -c root set-config TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 \
    TIMELINE_LIMIT_WEEKLY=0 TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 \
    NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5
pacman -S --needed --noconfirm snap-pac
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer grub-btrfs.path
snapper -c root create --description "fresh install"
echo "Done. Snapshots are taken around every pacman transaction and listed in the GRUB menu."
HELPER
}

configure_system() {
    info "Configuring the new system..."
    printf '%s\n' "${EXTRA_PKGS[@]}" > /mnt/root/extra-pkgs.txt
    printf '%s\n' "${SERVICES[@]}"  > /mnt/root/services.txt
    if [[ $FS_TYPE == btrfs ]]; then install_snapper_helper; fi

    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        printf 'HOST_NAME=%q\nUSERNAME_=%q\nTIMEZONE=%q\nLOCALE=%q\nKEYMAP=%q\n' \
            "$HOST_NAME" "$USERNAME_" "$TIMEZONE" "$LOCALE" "$KEYMAP"
        printf 'BOOT_MODE=%q\nTARGET_DISK=%q\nENABLE_OSPROBER=%q\nENABLE_ZRAM=%q\n' \
            "$BOOT_MODE" "$TARGET_DISK" "$ENABLE_OSPROBER" "$ENABLE_ZRAM"
        printf 'WANT_FIREWALL=%q\nVIRT=%q\nMIRROR_COUNTRIES=%q\n' \
            "$WANT_FIREWALL" "$VIRT" "$MIRROR_COUNTRIES"
        cat <<'CHROOT'

# --- time, locale, hostname
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc || echo "warning: could not set the hardware clock"
sed -i "s/^#\(${LOCALE} UTF-8\)/\1/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE"   > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOST_NAME"     > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOST_NAME.localdomain $HOST_NAME
HOSTS

# --- pacman tweaks (TotalDownload/CheckSpace are obsolete or default now)
sed -i 's/^#Color/Color/; s/^#VerbosePkgLists/VerbosePkgLists/; s/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
grep -q '^ILoveCandy' /etc/pacman.conf || sed -i '/^VerbosePkgLists/a ILoveCandy' /etc/pacman.conf
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# --- keep the installed system's mirrors fresh (reflector.timer)
mkdir -p /etc/xdg/reflector
{
    printf '%s\n' --save /etc/pacman.d/mirrorlist --protocol https --latest 20 --sort rate
    if [[ -n $MIRROR_COUNTRIES ]]; then printf '%s\n' --country "$MIRROR_COUNTRIES"; fi
} > /etc/xdg/reflector/reflector.conf

# --- desktop, audio, drivers
if [[ -s /root/extra-pkgs.txt ]]; then
    pacman -S --needed --noconfirm - < /root/extra-pkgs.txt
fi

# --- user
useradd -m -G wheel -s /bin/bash "$USERNAME_"
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

# --- zram swap
if [[ $ENABLE_ZRAM == y ]]; then
    printf '[zram0]\nzram-size = min(ram / 2, 4096)\ncompression-algorithm = zstd\n' > /etc/systemd/zram-generator.conf
fi

# --- firewall
if [[ $WANT_FIREWALL == y ]]; then
    sed -i 's/^ENABLED=.*/ENABLED=yes/' /etc/ufw/ufw.conf
fi

# --- bootloader
if [[ $BOOT_MODE == uefi ]]; then
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --recheck
    if [[ $VIRT != none ]]; then
        # VMs often lose NVRAM boot entries; also install the fallback path EFI/BOOT/BOOTX64.EFI
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --recheck
    fi
else
    grub-install --target=i386-pc --recheck "$TARGET_DISK"
fi
if [[ $ENABLE_OSPROBER == y ]]; then
    if grep -q '^#\?GRUB_DISABLE_OS_PROBER' /etc/default/grub; then
        sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    else
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
    fi
fi
grub-mkconfig -o /boot/grub/grub.cfg

# --- services
xargs -r systemctl enable < /root/services.txt

rm -f /root/extra-pkgs.txt /root/services.txt
CHROOT
    } > /mnt/root/archbd-chroot.sh

    arch-chroot /mnt bash /root/archbd-chroot.sh
    rm -f /mnt/root/archbd-chroot.sh
    ok "System configured."
}

set_password() {   # set_password USER [PLAINTEXT]  (plaintext only comes from a config file)
    local user=$1 pw=${2:-}
    if [[ -n $pw ]]; then
        echo "$user:$pw" | arch-chroot /mnt chpasswd
    else
        until arch-chroot /mnt passwd "$user"; do warn "Try again."; done
    fi
}

set_passwords() {
    echo
    info "Passwords"
    set_password root "${ROOT_PASSWORD:-}"
    set_password "$USERNAME_" "${USER_PASSWORD:-}"
    unset ROOT_PASSWORD USER_PASSWORD
}

finish() {
    cp "$LOG" /mnt/var/log/archbd-install.log 2>/dev/null || true
    info "Unmounting..."
    swapoff -a || true
    umount -R /mnt
    ok "All done in $((SECONDS / 60))m $((SECONDS % 60))s. Remove the USB/DVD before booting."
    if [[ $FS_TYPE == btrfs ]]; then
        echo "  btrfs tip: after the first boot run  sudo archbd-setup-snapper  to enable snapshots."
    fi
    get_yn REBOOT "Reboot now?" y
    if [[ $REBOOT == y ]]; then reboot; fi
}

# ------------------------------------------------------------------- main ---
main() {
    parse_args "$@"
    preflight
    gather_system
    detect_hardware
    choose_layout
    show_summary
    mirrors_and_keyring
    apply_layout
    build_package_lists
    install_base
    configure_system
    set_passwords
    finish
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
