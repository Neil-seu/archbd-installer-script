cat << 'EOF' > archbd-install-v5.sh
#!/usr/bin/env bash
# archbd-install-v5.sh - Arch Linux installer (UEFI + BIOS)

set -Eeuo pipefail
LOG=/tmp/archbd-install.log
USE_DIALOG=n
PLAIN_UI=${ARCHBD_PLAIN:+y}
trap 'on_error "$LINENO" "${FUNCNAME[0]:-main}"' ERR

DEFAULT_TIMEZONE="Asia/Dhaka"
DEFAULT_LOCALE="en_US.UTF-8"
DEFAULT_KEYMAP="us"
DEFAULT_MIRROR_COUNTRIES="BD,IN,SG"
DEFAULT_ESP_SIZE="512MiB"
PREFERRED_MIRRORS=()

c()    { local _c=${1:-33} _s=${2:-}; printf '\e[1;%sm%s\e[0m\n' "$_c" "$_s"; }
info() { c 33 "==> $*"; }
ok()   { c 32 "OK: $*"; }
warn() { c 31 "!!  $*"; }
die()  { if [[ ${USE_DIALOG:-n} == y ]]; then clear; fi; warn "$*"; exit 1; }

usage() {
    cat <<'USAGE'
Usage: archbd-install-v5.sh [-c CONFIG] [-n] [-p] [-h]
USAGE
}

DLG_TITLE="ArchBD installer"
UI_BACKTITLE="ArchBD Installer v5  -  Arch Linux"
DLG_TTY=${ARCHBD_TTY:-/dev/tty}
MENU_DEFAULT=""
MENU_BACK=n
DLG_FAILS=0
declare -A MENU_DESC=()

ui_theme() {
    cat <<'RC'
aspect = 0
separate_widget = ""
tab_len = 0
visit_items = OFF
use_shadow = ON
use_colors = ON
screen_color = (CYAN,TEAL,ON)
shadow_color = (BLACK,BLACK,ON)
dialog_color = (YELLOW,TEAL,OFF)
title_color = (CYAN,TEAL,ON)
border_color = (CYAN,TEAL,ON)
border2_color = (CYAN,TEAL,OFF)
button_active_color = (BLACK,CYAN,ON)
button_inactive_color = (YELLOW,TEAL,OFF)
button_key_active_color = (BLACK,CYAN,ON)
button_key_inactive_color = (CYAN,TEAL,ON)
button_label_active_color = (BLACK,CYAN,ON)
button_label_inactive_color = (YELLOW,TEAL,ON)
inputbox_color = (YELLOW,TEAL,OFF)
inputbox_border_color = (CYAN,TEAL,ON)
inputbox_border2_color = (CYAN,TEAL,OFF)
searchbox_color = (YELLOW,TEAL,OFF)
searchbox_title_color = (CYAN,TEAL,ON)
searchbox_border_color = (CYAN,TEAL,ON)
searchbox_border2_color = (CYAN,TEAL,OFF)
position_indicator_color = (CYAN,TEAL,ON)
menubox_color = (YELLOW,TEAL,OFF)
menubox_border_color = (CYAN,TEAL,ON)
menubox_border2_color = (CYAN,TEAL,OFF)
item_color = (YELLOW,TEAL,OFF)
item_selected_color = (BLACK,CYAN,ON)
tag_color = (CYAN,TEAL,ON)
tag_selected_color = (BLACK,CYAN,ON)
tag_key_color = (CYAN,TEAL,ON)
tag_key_selected_color = (BLACK,CYAN,ON)
check_color = (YELLOW,TEAL,OFF)
check_selected_color = (BLACK,CYAN,ON)
uarrow_color = (CYAN,TEAL,ON)
darrow_color = (CYAN,TEAL,ON)
itemhelp_color = (CYAN,TEAL,OFF)
form_active_text_color = (BLACK,CYAN,ON)
form_text_color = (YELLOW,TEAL,ON)
form_item_readonly_color = (CYAN,TEAL,ON)
gauge_color = (BLACK,CYAN,ON)
RC
}

ui_init() {
    USE_DIALOG=n
    if [[ ${PLAIN_UI:-n} == y ]]; then return 0; fi
    if [[ ! -t 0 || ! -t 1 ]]; then return 0; fi
    if ! command -v dialog >/dev/null 2>&1; then
        echo "Installing 'dialog'..."
        pacman -Sy --needed --noconfirm dialog >/dev/null 2>&1 || true
    fi
    if ! command -v dialog >/dev/null 2>&1; then
        warn "dialog is not available, using plain text prompts instead."
        return 0
    fi
    ui_theme > /tmp/archbd-dialogrc
    export DIALOGRC=/tmp/archbd-dialogrc
    USE_DIALOG=y
}

dlg() { dialog --backtitle "$UI_BACKTITLE" "$@" 2>&1 >"$DLG_TTY"; }

dlg_yesno() {
    local _t=${1:-} _h _rc=0
    _t=${_t//\\n/$'\n'}
    local -a _x=()
    if [[ ${2:-n} != y ]]; then _x=(--defaultno); fi
    _h=$(( $(fold -s -w 62 <<<"$_t" | wc -l) + 6 ))
    dlg --title "$DLG_TITLE" "${_x[@]}" --yesno "$_t" "$_h" 68 >/dev/null || _rc=$?
    return "$_rc"
}

dlg_msg() {
    local _t=${2:-} _h
    _t=${_t//\\n/$'\n'}
    _h=$(( $(fold -s -w 62 <<<"$_t" | wc -l) + 6 ))
    dlg --title "${1:-}" --msgbox "$_t" "$_h" 68 >/dev/null || true
}

dlg_textbox() {
    local _rows _h
    _rows=$(tput lines 2>/dev/null || echo 24)
    _h=$(( _rows - 3 ))
    if (( _h > 30 )); then _h=30; fi
    dlg --title "${1:-}" --exit-label "${3:-Continue}" --textbox "$2" "$_h" 78 >/dev/null || true
}

confirm_quit() {
    if dlg_yesno "Quit the installer?\n\nNothing has been changed on your disks yet." n; then
        clear
        echo "Cancelled - nothing was changed."
        exit 130
    fi
}

dlg_input() {
    local _o=${1:-} _t=${2:-} _a _h
    _t=${_t//\\n/$'\n'}
    _h=$(( $(fold -s -w 66 <<<"$_t" | wc -l) + 7 ))
    while true; do
        if _a=$(dlg --title "$DLG_TITLE" --inputbox "$_t" "$_h" 72 "${3:-}"); then
            printf -v "$_o" '%s' "$_a"
            return 0
        fi
        confirm_quit
    done
}

dlg_password() {
    local _o=${1:-} _t=${2:-} _a _h
    _t=${_t//\\n/$'\n'}
    _h=$(( $(fold -s -w 66 <<<"$_t" | wc -l) + 7 ))
    while true; do
        if _a=$(dlg --title "$DLG_TITLE" --insecure --passwordbox "$_t" "$_h" 72); then
            printf -v "$_o" '%s' "$_a"
            return 0
        fi
        confirm_quit
    done
}

dlg_menu() {
    local _o=${1:-} _t=${2:-} _d=${3:-} _a="" _n=0 _mh=0 _h=0 _rows=24 _tl=0
    _t=${_t//\\n/$'\n'}
    shift 3 2>/dev/null || true
    local -a _x=()
    if [[ -n ${_d:-} ]]; then _x=(--default-item "$_d"); fi
    _n=$(( $# / 2 ))
    _rows=$(tput lines 2>/dev/null || echo 24)
    _tl=$(fold -s -w 68 <<<"$_t" | wc -l)
    _mh=$(( _n > 12 ? 12 : _n ))
    if (( _mh + _tl + 7 > _rows - 1 )); then _mh=$(( _rows - 1 - _tl - 7 )); fi
    if (( _mh < 3 )); then _mh=3; fi
    _h=$(( _tl + _mh + 7 ))
    while true; do
        if _a=$(dlg --title "$DLG_TITLE" "${_x[@]}" --menu "$_t" "$_h" 74 "$_mh" "$@"); then
            printf -v "$_o" '%s' "$_a"
            return 0
        fi
        if [[ ${MENU_BACK:-n} == y ]]; then return 1; fi
        confirm_quit
    done
}

ask() {
    local _v=${1:-} _p=${2:-} _r
    _p=${_p//\\n/$'\n'}
    if [[ $USE_DIALOG == y ]]; then
        dlg_input "$_v" "$_p" "${3:-}"
        return 0
    fi
    read -r -p "$_p${3:+ [$3]}: " _r
    printf -v "$_v" '%s' "${_r:-${3:-}}"
}

ask_secret() {
    local _v=${1:-} _r _prompt=${2:-}
    _prompt=${_prompt//\\n/$'\n'}
    if [[ $USE_DIALOG == y ]]; then
        dlg_password "$_v" "$_prompt"
        return 0
    fi
    read -rs -p "$_prompt: " _r
    echo
    printf -v "$_v" '%s' "$_r"
}

confirm() {
    if [[ $USE_DIALOG == y ]]; then dlg_yesno "${1:-}" "${2:-n}"; return; fi
    local def=${2:-n} hint reply
    if [[ $def == y ]]; then hint="Y/n"; else hint="y/N"; fi
    read -r -p "${1//\\n/$'\n'} [$hint]: " reply
    reply=${reply:-$def}
    [[ $reply =~ ^[Yy][Ee]?[Ss]?$ ]]
}

notice() {
    if [[ $USE_DIALOG == y ]]; then dlg_msg "Please note" "$*"; else warn "${*//\\n/$'\n'}"; fi
}

say() {
    if [[ $USE_DIALOG == y ]]; then
        dlg_msg "${1:-}" "${2:-}"
    else
        echo; info "${1:-}"; echo "${2//\\n/$'\n'}"; echo
    fi
}

get() {
    if [[ ! -v $1 ]]; then ask "$1" "${2:-}" "${3:-}"; fi
}

get_yn() {
    local var=${1:-}
    if [[ ! -v $var ]]; then
        if confirm "${2:-}" "${3:-n}"; then printf -v "$var" y; else printf -v "$var" n; fi
    fi
}

get_choice() {
    local var=${1:-} prompt=${2:-} pick="" o
    shift 2 2>/dev/null || true
    if [[ ! -v $var ]]; then
        if [[ $USE_DIALOG == y ]]; then
            local -a items=()
            for o in "$@"; do items+=("$o" "${MENU_DESC[$o]:-}"); done
            dlg_menu pick "$prompt" "$MENU_DEFAULT" "${items[@]}"
        else
            echo "${prompt//\\n/$'\n'}"
            for o in "$@"; do printf '  %-10s %s\n' "$o" "${MENU_DESC[$o]:-}"; done
            local PS3="Choose (number): "
            select pick in "$@"; do [[ -n ${pick:-} ]] && break; done
        fi
        printf -v "$var" '%s' "$pick"
    fi
    MENU_DESC=()
    MENU_DEFAULT=""
}

get_valid() {
    local var=${1:-} prompt=${2:-} default=${3:-} check=${4:-} msg=${5:-} reply
    if [[ -v $var ]]; then
        "$check" "${!var}" || die "$msg: '${!var}'"
        return 0
    fi
    while true; do
        ask reply "$prompt" "$default"
        if "$check" "$reply"; then
            printf -v "$var" '%s' "$reply"
            return 0
        fi
        notice "$msg: '$reply'"
    done
}

get_password() {
    local var=${1:-} p1 p2
    if [[ -v $var ]]; then return 0; fi
    while true; do
        ask_secret p1 "${2:-}"
        ask_secret p2 "Type the password again to confirm"
        if [[ -z $p1 ]]; then
            notice "The password cannot be empty."
        elif [[ $p1 != "$p2" ]]; then
            notice "The two passwords do not match. Please try again."
        else
            printf -v "$var" '%s' "$p1"
            return 0
        fi
    done
}

valid_hostname() { [[ ${1:-} =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]]; }
valid_username() { [[ ${1:-} =~ ^[a-z_][a-z0-9_-]*$ ]]; }
valid_timezone() { [[ -n ${1:-} && -f /usr/share/zoneinfo/$1 ]]; }
valid_locale()   { [[ ! -f /usr/share/i18n/SUPPORTED ]] || awk -v l="${1:-}" '$1 == l { f = 1 } END { exit !f }' /usr/share/i18n/SUPPORTED; }
valid_keymap()   { [[ ! -d /usr/share/kbd/keymaps ]] || [[ -n $(find /usr/share/kbd/keymaps -name "${1:-}.map.gz" -print -quit) ]]; }

get_timezone() {
    if [[ -v TIMEZONE ]]; then
        valid_timezone "$TIMEZONE" || die "Unknown timezone: $TIMEZONE"
        return 0
    fi
    if [[ $USE_DIALOG != y ]]; then
        get_valid TIMEZONE "Timezone (Region/City)" "$DEFAULT_TIMEZONE" valid_timezone "Unknown timezone"
        return 0
    fi
    local region="" city="" pick_def def_region=${DEFAULT_TIMEZONE%%/*} def_city=${DEFAULT_TIMEZONE#*/}
    local -a list=() items=()
    while true; do
        mapfile -t list < <(find /usr/share/zoneinfo -mindepth 1 -maxdepth 1 -type d \
            ! -name posix ! -name right ! -name Etc -printf '%f\n' | sort)
        items=()
        for region in "${list[@]}"; do items+=("$region" ""); done
        items+=("UTC" "Coordinated Universal Time (no region)")
        dlg_menu region "Where are you?\n\nPick your region first, then your city." "$def_region" "${items[@]}"
        if [[ $region == UTC ]]; then TIMEZONE=UTC; return 0; fi

        mapfile -t list < <(find "/usr/share/zoneinfo/$region" \( -type f -o -type l \) -printf '%P\n' | sort)
        items=()
        for city in "${list[@]}"; do items+=("$city" ""); done
        pick_def=""
        if [[ $region == "$def_region" ]]; then pick_def=$def_city; fi
        MENU_BACK=y
        if dlg_menu city "Pick your city in $region.\n\n(Cancel goes back to the regions.)" "$pick_def" "${items[@]}"; then
            MENU_BACK=n
            TIMEZONE="$region/$city"
            return 0
        fi
        MENU_BACK=n
        def_region=$region
    done
}

show_block_devices() {
    local f=/tmp/archbd-lsblk.txt
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINTS > "$f"
    if [[ $USE_DIALOG == y ]]; then
        dlg_textbox "Disks and partitions" "$f" "Continue"
    else
        clear; cat "$f"; echo
    fi
}

choose_partition() {
    local var=${1:-} prompt=${2:-} optional=${3:-} line
    local -a parts=() items=()
    if [[ -v $var ]]; then
        if [[ -n ${!var:-} ]]; then need_block "${!var}"; fi
        return 0
    fi
    if [[ $USE_DIALOG != y ]]; then
        ask "$var" "$prompt${optional:+ (blank = none)}"
        if [[ -n ${!var:-} ]]; then need_block "${!var}"; fi
        return 0
    fi
    mapfile -t parts < <(lsblk -lpno NAME,SIZE,TYPE,FSTYPE,LABEL \
        | awk '$3 == "part" { d = $2; for (i = 4; i <= NF; i++) d = d " " $i; print $1 "|" d }')
    if [[ ${#parts[@]} -eq 0 ]]; then
        die "No partitions found. Create them first (use 'custom' mode, or cfdisk)."
    fi
    if [[ -n $optional ]]; then items+=("none" "No separate partition"); fi
    for line in "${parts[@]}"; do items+=("${line%%|*}" "${line#*|}"); done
    dlg_menu "$var" "$prompt" "" "${items[@]}"
    if [[ ${!var:-} == none ]]; then printf -v "$var" ''; fi
}

view_log() {
    local body=/tmp/archbd-install.body.log clean=/tmp/archbd-install.clean.log
    if [[ ! -s $LOG ]]; then notice "There is no log yet."; return 0; fi
    sed -n '/ARCHBD INSTALL START/,$p' "$LOG" > "$body"
    if [[ ! -s $body ]]; then cp "$LOG" "$body"; fi
    sed -E 's#\x1b\[[0-9;?]*[ -/]*[@-~]##g; s#\x1b[()][A-Z0-9]##g; s#\x1b[=>78Mc]##g' "$body" \
        | tr '\r' '\n' | cat -s > "$clean"
    DLG_TITLE="Install log"
    dlg_textbox "Install log - arrows / PgUp / PgDn scroll, Enter closes" "$clean" "Close"
}

on_error() {
    trap - ERR
    if [[ $USE_DIALOG == y ]]; then clear; fi
    printf '\n\e[1;31mFailed in %s (line %s). Installation stopped.\e[0m\n' "${2:-main}" "${1:-0}" >&2
    printf 'Full log: less -R %s\nIMPORTANT: do NOT blindly rerun with the same disk config. Inspect the log first.\n' "$LOG" >&2
    if [[ $USE_DIALOG == y && -s $LOG ]]; then
        DLG_TITLE="Something went wrong"
        if dlg_yesno "The installer stopped in '${2:-main}' (line ${1:-0}).\n\nOpen the log now?" y; then
            view_log || true
        fi
        clear
    fi
}

welcome() {
    if [[ $USE_DIALOG != y ]]; then return 0; fi
    dlg_msg "Welcome" "ArchBD installer v5\n\nThis guides you through installing Arch Linux (${BOOT_MODE:-uefi} boot).\n\nKeys:  arrows = move   Tab = switch buttons\n       Enter = confirm   Esc = cancel\n\nNothing is changed on your disks until you confirm the final plan."
}

validate() {
    local v=${1:-} name=${2:-} o
    shift 2 2>/dev/null || true
    for o in "$@"; do [[ $v == "$o" ]] && return 0; done
    die "Invalid $name '$v' (allowed: $*)"
}

need_block() { [[ -b ${1:-} ]] || die "${1:-} is not a block device."; }

part_path() {
    if [[ ${1:-} =~ [0-9]$ ]]; then echo "${1}p${2:-}"; else echo "${1:-}${2:-}"; fi
}

size_to_mib() {
    local s=${1:-} mib
    s=${s,,}
    s=${s#"${s%%[![:space:]]*}"}; s=${s%"${s##*[![:space:]]}"}
    case $s in
        ""|none|no|-) return 0 ;;
        rest|all)     echo rest; return 0 ;;
    esac
    [[ $s =~ ^([0-9]+(\.[0-9]+)?)[[:space:]]*(m|g|t)(i?b)?$ ]] || return 1
    mib=$(awk -v n="${BASH_REMATCH[1]}" -v u="${BASH_REMATCH[3]}" \
        'BEGIN { if (u == "g") n *= 1024; else if (u == "t") n *= 1048576; printf "%d", n }')
    (( mib > 0 )) || return 1
    echo "$mib"
}

fmt_mib() {
    local m=${1:-0}
    if [[ $m == rest ]]; then
        echo "rest"
    elif (( m >= 1024 )); then
        awk -v m="$m" 'BEGIN { g = m / 1024; if (g == int(g)) printf "%dG\n", g; else printf "%.1fG\n", int(g * 10) / 10 }'
    else
        echo "${m}M"
    fi
}

ask_size() {
    local var=${1:-} prompt=${2:-} default=${3:-} reply
    if [[ -v $var ]]; then
        size_to_mib "${!var}" >/dev/null || die "Invalid size in $var: '${!var}'"
        return 0
    fi
    while true; do
        ask reply "$prompt\n\nExamples: 512M, 4G, 1.5G  |  rest = all that is left  |  none = skip" "$default"
        if size_to_mib "$reply" >/dev/null; then
            printf -v "$var" '%s' "$reply"
            return 0
        fi
        notice "That is not a valid size."
    done
}

write_partition_table() {
    local table boot_flag=""
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then table="label: gpt"; else table="label: dos"; boot_flag=", bootable"; fi
    table+=$'\n'
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then table+="size=${ESP_MIB:-512}MiB, type=U"$'\n'; fi
    if [[ -n ${SWAP_MIB:-} ]]; then table+="size=${SWAP_MIB}MiB, type=S"$'\n'; fi
    if [[ ${ROOT_MIB:-rest} == rest ]]; then
        table+="type=L${boot_flag}"$'\n'
    else
        table+="size=${ROOT_MIB}MiB, type=L${boot_flag}"$'\n'
    fi
    if [[ -n ${HOME_MIB:-} ]]; then
        if [[ $HOME_MIB == rest ]]; then table+="type=L"$'\n'; else table+="size=${HOME_MIB}MiB, type=L"$'\n'; fi
    fi
    printf '%s' "$table" | sfdisk --force --quiet "${INSTALL_DISK:-}"
}

make_fs() {
    case ${1:-} in
        ext4)  mkfs.ext4 -F -L "${3:-archroot}" "${2:-}" ;;
        btrfs) mkfs.btrfs -f -L "${3:-archroot}" "${2:-}" ;;
        xfs)   mkfs.xfs  -f -L "${3:-archroot}" "${2:-}" ;;
        *)     die "Unsupported filesystem: ${1:-}" ;;
    esac
    udevadm settle
}

mount_opts() {
    case ${1:-} in
        btrfs) echo "noatime,compress=zstd:1" ;;
        *)     echo "noatime" ;;
    esac
}

start_logging() {
    [[ -z ${ARCHBD_LOGGING:-} ]] || return 0
    command -v script >/dev/null || return 0
    [[ -t 0 && -t 1 ]] || return 0
    export ARCHBD_LOGGING=1
    local cmd
    cmd=$(printf '%q ' bash "$0" "$@")
    exec script -qefc "$cmd" "$LOG"
}

parse_args() {
    local opt OPTIND=1
    CONFIG_FILE=""; DRY_RUN=n
    while getopts ":c:nph" opt; do
        case $opt in
            c) CONFIG_FILE=$OPTARG ;;
            n) DRY_RUN=y ;;
            p) PLAIN_UI=y ;;
            h) usage; exit 0 ;;
            *) usage; exit 1 ;;
        esac
    done
    if [[ -n $CONFIG_FILE ]]; then
        [[ -f $CONFIG_FILE ]] || die "Config file not found: $CONFIG_FILE"
        source "$CONFIG_FILE"
        ok "Loaded answers from $CONFIG_FILE"
    fi
}

preflight() {
    [[ $EUID -eq 0 ]] || die "Run as root (on the Arch ISO you already are)."

    if [[ -d /sys/firmware/efi/efivars ]]; then BOOT_MODE=uefi; else BOOT_MODE=bios; fi
    ok "Boot mode: $BOOT_MODE"

    if [[ $DRY_RUN != y ]]; then
        ping -c1 -W3 archlinux.org &>/dev/null ||
            die "No internet. For Wi-Fi use: iwctl station wlan0 connect <SSID>  (then re-run)"
        timedatectl set-ntp true
        systemctl stop reflector.service 2>/dev/null || true
        sed -i 's/^#\?ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
        sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    fi
}

pick_from_live_list() {
    local out=${1:-} title=${2:-} source=${3:-} def=${4:-} query pick
    local tmp=/tmp/archbd-dynamic-list.txt
    eval "$source" | sed '/^[[:space:]]*$/d' | sort -u > "$tmp"
    [[ -s $tmp ]] || die "The live ISO did not provide any choices for $title."
    if [[ $USE_DIALOG != y ]]; then
        ask query "$title (type a value; use the live list in $tmp for reference)" "$def"
        grep -Fxq "$query" "$tmp" || die "Unsupported value for $title: $query"
        printf -v "$out" '%s' "$query"
        return
    fi
    while true; do
        ask query "Search $title (blank shows the full list)" "${def:-}"
        local -a items=() matches=()
        if [[ -n $query ]]; then mapfile -t matches < <(grep -iF -- "$query" "$tmp" | head -n 180); else mapfile -t matches < <(head -n 180 "$tmp"); fi
        if (( ${#matches[@]} == 0 )); then notice "No matches for '$query'. Try a shorter search."; continue; fi
        for pick in "${matches[@]}"; do items+=("$pick" ""); done
        if dlg_menu pick "Choose $title\n\nType a search term to filter the live ISO list." "$def" "${items[@]}"; then
            printf -v "$out" '%s' "$pick"
            return
        fi
    done
}

gather_system() {
    local app_cat
    if [[ $USE_DIALOG != y ]]; then
        clear
        info "Arch installer v5 - answer the questions now, installation runs afterwards."
        echo
    fi

    DLG_TITLE="Your computer"
    get_valid HOST_NAME "Hostname (the name of this computer)" "archbd" valid_hostname \
        "Invalid hostname (letters, digits and '-' only)"

    DLG_TITLE="Your account"
    get_valid USERNAME_ "Username for your new account" "" valid_username \
        "Invalid username (lowercase letters, digits, '-' and '_' only)"
    get_password ROOT_PASSWORD "Password for root (the administrator)"
    get_password USER_PASSWORD "Password for $USERNAME_"

    DLG_TITLE="Region and language"
    get_timezone
    if [[ ! -v LOCALE ]]; then
        pick_from_live_list LOCALE "Locale (system language)" "awk '{sub(/^#[[:space:]]*/, \"\"); if (NF >= 2 && \$2 == \"UTF-8\") print \$1}' /etc/locale.gen" "$DEFAULT_LOCALE"
    else valid_locale "$LOCALE" || die "Unknown locale: $LOCALE"; fi
    if [[ ! -v KEYMAP ]]; then
        pick_from_live_list KEYMAP "Console keyboard layout" "localectl list-keymaps 2>/dev/null | sed 's/\\.map$//'" "$DEFAULT_KEYMAP"
    else valid_keymap "$KEYMAP" || die "Unknown keymap: $KEYMAP"; fi

    DLG_TITLE="Package mirrors"
    get MIRROR_COUNTRIES "Mirror countries (codes, comma-separated)\n\nNearby countries download fastest, e.g. BD,IN,SG.\nType 'all' for worldwide." "$DEFAULT_MIRROR_COUNTRIES"
    if [[ ${MIRROR_COUNTRIES,,} == all ]]; then MIRROR_COUNTRIES=""; fi

    DLG_TITLE="Desktop"
    MENU_DESC=([xfce]="Lightweight and fast (good for VMs)" [gnome]="Modern and polished"
               [kde]="Plasma: feature-rich, very customizable" [cinnamon]="Traditional and beginner friendly"
               [mate]="Classic desktop, light" [lxqt]="Very light, Qt based"
               [none]="No desktop: command line only")
    get_choice DE "Which desktop environment do you want?" xfce gnome kde cinnamon mate lxqt none
    validate "$DE" DE xfce gnome kde cinnamon mate lxqt none

    DLG_TITLE="Filesystem"
    MENU_DESC=([ext4]="Simple and rock solid" [btrfs]="Snapshots + compression (snapper, GRUB menu)"
               [xfs]="Fast with big files; cannot be shrunk")
    get_choice FS_TYPE "Which filesystem for the root partition?" ext4 btrfs xfs
    validate "$FS_TYPE" FS_TYPE ext4 btrfs xfs

    DLG_TITLE="Software selection"
    if [[ ! -v APP_CATEGORIES && ${WANT_APPS:-n} == y ]]; then APP_CATEGORIES="everyday sysadmin"; fi
    if [[ ! -v APP_CATEGORIES ]]; then
        if [[ $USE_DIALOG == y ]]; then
            local picked_apps
            dlg --title "$DLG_TITLE" --checklist "Choose any software groups to install. Space toggles a group." 18 74 8 \
                everyday "Browser, media, office and image tools" on \
                developer "Editors, Git, containers and build tools" off \
                sysadmin "Disk, network and system diagnostics" on \
                creative "Image, audio and video production" off \
                security "Defensive security and lab utilities" off 2> /tmp/archbd-app-categories.txt || confirm_quit
            picked_apps=$(cat /tmp/archbd-app-categories.txt 2>/dev/null || true)
            APP_CATEGORIES=${picked_apps//\"/}
        else
            ask APP_CATEGORIES "Software groups (space-separated: everyday developer sysadmin creative security; blank for none)" "everyday sysadmin"
        fi
    fi
    for app_cat in ${APP_CATEGORIES:-}; do
        case $app_cat in everyday|developer|sysadmin|creative|security) ;; *) die "Unknown software group '$app_cat'." ;; esac
    done
    get CUSTOM_PACKAGES "Additional official-repository package names (space-separated; leave blank for none)" ""
    get_yn SECURITY_PROFILE "Install the optional penetration-testing lab toolkit?" n
    get_yn WANT_FIREWALL "Enable a firewall (ufw)?" n
}

detect_hardware() {
    VIRT=$(systemd-detect-virt || true)
    GPU_INFO=""
    if [[ $VIRT == none ]]; then
        GPU_INFO=$(lspci | grep -Ei 'vga|3d|display' || true)
        if grep -qi nvidia <<<"$GPU_INFO"; then
            DLG_TITLE="Graphics"
            MENU_DESC=([nvidia-open]="RTX 20-series / GTX 16-series and newer"
                       [nouveau]="Open-source Mesa driver, any card")
            get_choice NVIDIA_CHOICE "An NVIDIA graphics card was detected.\nWhich driver do you want?" nvidia-open nouveau
            validate "$NVIDIA_CHOICE" NVIDIA_CHOICE nvidia-open nouveau
        fi
    fi
}

choose_disk() {
    if [[ -v INSTALL_DISK ]]; then need_block "$INSTALL_DISK"; return; fi

    local live_src live_disk="" line name rest
    local -a disks=() menu=() items=()
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

    DLG_TITLE="Choose the disk"
    if [[ $USE_DIALOG == y ]]; then
        for line in "${menu[@]}"; do
            name=${line%% *}
            rest=${line#* }
            rest=${rest#"${rest%%[![:space:]]*}"}
            items+=("$name" "$rest")
        done
        dlg_menu INSTALL_DISK "Which disk do you want to use?\n\n(The live USB/ISO is hidden from this list.)" "" "${items[@]}"
    else
        local PS3="Disk number: " pick=""
        select pick in "${menu[@]}"; do [[ -n ${pick:-} ]] && break; done
        INSTALL_DISK=${pick%% *}
    fi
}

name_partitions() {
    local n=1
    EFI_PART=""; SWAP_PART=""; HOME_PART=""
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then EFI_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1)); fi
    if [[ -n ${SWAP_MIB:-} ]]; then SWAP_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1)); fi
    ROOT_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1))
    if [[ -n ${HOME_MIB:-} ]]; then HOME_PART=$(part_path "$INSTALL_DISK" "$n"); fi
    FORMAT_EFI=y
    if [[ -n $HOME_PART ]]; then FORMAT_HOME=y; else FORMAT_HOME=n; fi
}

layout_auto() {
    WIPE_DISK=y
    choose_disk
    if [[ ! -v ESP_SIZE ]]; then ESP_SIZE=$DEFAULT_ESP_SIZE; fi
    ESP_MIB=0
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then ESP_MIB=$(size_to_mib "$ESP_SIZE") || die "Invalid ESP_SIZE: $ESP_SIZE"; fi
    SWAP_MIB=""; ROOT_MIB=rest; HOME_MIB=""
    name_partitions
}

custom_sizes() {
    local usable=${1:-0} used left root_final
    ESP_MIB=0
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then
        ask_size ESP_SIZE "EFI/boot partition size" "$DEFAULT_ESP_SIZE"
        ESP_MIB=$(size_to_mib "$ESP_SIZE")
        if ! [[ $ESP_MIB =~ ^[0-9]+$ ]] || (( ESP_MIB < 100 )); then
            notice "The EFI partition needs a fixed size of at least 100M."
            return 1
        fi
    fi

    ask_size SWAP_SIZE "Swap partition size\n(none = use compressed RAM swap)" "none"
    SWAP_MIB=$(size_to_mib "$SWAP_SIZE")
    if [[ $SWAP_MIB == rest ]]; then notice "Swap cannot be 'rest'."; return 1; fi

    ask_size ROOT_SIZE "Root partition size\n(rest = everything left)" "rest"
    ROOT_MIB=$(size_to_mib "$ROOT_SIZE")
    if [[ -z $ROOT_MIB ]]; then notice "The root partition cannot be 'none'."; return 1; fi

    if [[ $ROOT_MIB == rest ]]; then
        HOME_SIZE=""; HOME_MIB=""
    else
        ask_size HOME_SIZE "Home partition size\n(none = no separate /home, rest = what is left)" "rest"
        HOME_MIB=$(size_to_mib "$HOME_SIZE")
    fi

    used=$(( ESP_MIB + ${SWAP_MIB:-0} ))
    if [[ $ROOT_MIB != rest ]]; then used=$(( used + ROOT_MIB )); fi
    if [[ -n $HOME_MIB && $HOME_MIB != rest ]]; then used=$(( used + HOME_MIB )); fi
    left=$(( usable - used ))
    if (( left < 0 )); then
        notice "Sizes exceed disk capacity."
        return 1
    fi
    return 0
}

layout_custom() {
    WIPE_DISK=y
    choose_disk
    local disk_mib usable intro
    disk_mib=$(( $(lsblk -bdno SIZE "${INSTALL_DISK:-}") / 1048576 ))
    usable=$(( disk_mib - 2 ))

    DLG_TITLE="Custom layout"
    intro="Disk ${INSTALL_DISK:-} is $(fmt_mib "$disk_mib") and will be ERASED.\n\nType sizes like 512M, 4G or 1.5G."
    say "Custom layout" "$intro"

    while true; do
        if custom_sizes "$usable"; then break; fi
        unset ESP_SIZE SWAP_SIZE ROOT_SIZE HOME_SIZE
    done
    name_partitions
}

layout_manual() {
    WIPE_DISK=n
    DLG_TITLE="Existing partitions"
    if [[ ! -v ROOT_PART ]]; then
        show_block_devices
        if [[ $DRY_RUN != y ]] && confirm "Open cfdisk to edit partitions first?" n; then
            choose_disk
            cfdisk "${INSTALL_DISK:-}"
            show_block_devices
        fi
    fi

    DLG_TITLE="Choose partitions"
    choose_partition ROOT_PART "Which partition is ROOT (/)?\n\nIt will be FORMATTED."
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then
        choose_partition EFI_PART "Which partition is EFI System?"
        get_yn FORMAT_EFI "Format the EFI partition?" n
    else
        EFI_PART=""; FORMAT_EFI=n
    fi

    choose_partition SWAP_PART "Which partition is swap?" optional
    choose_partition HOME_PART "Which partition is /home?" optional
    if [[ -n $HOME_PART ]]; then
        get_yn FORMAT_HOME "Format $HOME_PART?" n
    else
        FORMAT_HOME=n
    fi
}

choose_layout() {
    DLG_TITLE="Partitioning"
    MENU_DESC=([auto]="Wipe one disk: EFI/boot + root"
               [custom]="Wipe one disk and YOU choose sizes"
               [manual]="Use existing partitions")
    get_choice PARTITION_MODE "How do you want to partition?" auto custom manual
    validate "$PARTITION_MODE" PARTITION_MODE auto custom manual

    case $PARTITION_MODE in
        auto)   layout_auto ;;
        custom) layout_custom ;;
        manual) layout_manual ;;
    esac

    DLG_TITLE="Swap and boot"
    if [[ -n ${SWAP_PART:-} ]]; then
        ENABLE_ZRAM=n
    else
        get_yn ENABLE_ZRAM "Use compressed RAM swap (zram)?" y
    fi
    get_yn ENABLE_OSPROBER "Dual-boot with another operating system?" n

    if [[ $PARTITION_MODE == manual ]]; then
        TARGET_DISK="/dev/$(lsblk -no pkname "${ROOT_PART:-}" | head -n1)"
    else
        TARGET_DISK=${INSTALL_DISK:-}
    fi
}

plan_text() {
    printf '%-14s %s\n' "Boot mode:"  "${BOOT_MODE:-uefi}${VIRT:+ (virt: $VIRT)}"
    printf '%-14s %s\n' "Hostname:"   "${HOST_NAME:-}"
    printf '%-14s %s\n' "User:"       "${USERNAME_:-}"
    printf '%-14s %s\n' "Timezone:"   "${TIMEZONE:-}"
    printf '%-14s %s\n' "Desktop:"    "${DE:-}"
    printf '%-14s %s\n' "Filesystem:" "${FS_TYPE:-}"
    echo
}

show_summary() {
    local plan=/tmp/archbd-plan.txt answer
    plan_text > "$plan"
    if [[ $USE_DIALOG == y ]]; then
        DLG_TITLE="Installation plan"
        dlg_textbox "Installation plan - please review carefully" "$plan" "Continue"
    else
        echo
        info "Installation plan"
        cat "$plan"
        echo
    fi

    if [[ $DRY_RUN == y ]]; then
        if [[ $USE_DIALOG == y ]]; then clear; fi
        ok "Dry run finished - nothing was changed on your disks."
        exit 0
    fi
    if [[ ${WIPE_DISK:-n} == y ]]; then
        DLG_TITLE="Destructive operation confirmation"
        ask answer "Type YES (capitals) to start the installation.\n\nTarget: ${INSTALL_DISK:-${ROOT_PART:-}}\nSelected partitions will be formatted." ""
        [[ $answer == YES ]] || die "Aborted by user."
    fi
}

builtin_mirrors_for() {
    case ${1^^} in
        BD|BANGLADESH) echo "https://mirror.xeonbd.com/archlinux https://mirror.limda.net/archlinux" ;;
    esac
}

probe_mirror() {
    local url=${1%/} body ts secs now age
    body=$(curl -fsS --connect-timeout 3 --max-time 6 -w '\n%{time_total}' "$url/lastsync" 2>/dev/null) || return 1
    ts=$(head -n1 <<<"$body")
    secs=$(tail -n1 <<<"$body")
    [[ $ts =~ ^[0-9]+$ ]] || return 1
    now=$(date +%s)
    age=$(( now - ts ))
    if (( age < 0 )); then age=0; fi
    (( age <= 86400 )) || return 1
    printf '%s %s\n' "$secs" "$(( age / 60 ))"
}

reflector_fallback() {
    local sort=${MIRROR_SORT:-score}
    local -a args=(--protocol https --age 24 --completion-percentage 90 --number 10
                   --connection-timeout 3 --download-timeout 3 --sort "$sort"
                   --save /etc/pacman.d/mirrorlist)
    if [[ $sort == rate ]]; then args+=(--latest 20); fi
    if [[ -n ${MIRROR_COUNTRIES:-} ]]; then args+=(--country "$MIRROR_COUNTRIES"); fi
    echo "  Asking reflector..."
    timeout 90 reflector "${args[@]}" || true
}

mirrors_and_keyring() {
    info "Choosing mirrors..."
    local list=/etc/pacman.d/mirrorlist iso_copy=/etc/pacman.d/mirrorlist.iso
    cp -n "$list" "$iso_copy" 2>/dev/null || true

    local -a candidates=() codes=() timed=() sorted=()
    local url code res secs age

    for url in "${PREFERRED_MIRRORS[@]}"; do
        if [[ -n $url ]]; then candidates+=("$url"); fi
    done
    IFS=',' read -ra codes <<<"${MIRROR_COUNTRIES:-}"
    for code in "${codes[@]}"; do
        code=${code// /}
        for url in $(builtin_mirrors_for "$code"); do candidates+=("$url"); done
    done

    if (( ${#candidates[@]} )); then
        for url in "${candidates[@]}"; do
            if res=$(probe_mirror "$url"); then
                read -r secs age <<<"$res"
                timed+=("$secs $url")
            fi
        done
    fi

    if (( ${#timed[@]} )); then
        mapfile -t sorted < <(printf '%s\n' "${timed[@]}" | sort -n | cut -d' ' -f2-)
        {
            echo "# Written by archbd-install-v5.sh"
            for url in "${sorted[@]}"; do echo "Server = ${url%/}/\$repo/os/\$arch"; done
            grep -m5 '^Server' "$iso_copy" || true
        } > "$list"
    else
        reflector_fallback
    fi

    pacman -Sy --noconfirm archlinux-keyring
}

apply_layout() {
    swapoff -a || true
    if mountpoint -q /mnt; then umount -R /mnt; fi

    if [[ ${WIPE_DISK:-n} == y ]]; then
        wipefs -af "${INSTALL_DISK:-}"
        write_partition_table
        partprobe "${INSTALL_DISK:-}"
        udevadm settle
    fi

    local opts sv ROOT_DEVICE="${ROOT_PART:-}"
    opts=$(mount_opts "${FS_TYPE:-ext4}")
    wipefs -af "${ROOT_PART:-}"
    make_fs "${FS_TYPE:-ext4}" "$ROOT_DEVICE" archroot

    if [[ ${FS_TYPE:-ext4} == btrfs ]]; then
        mount -t btrfs "$ROOT_DEVICE" /mnt
        for sv in @ @log @pkg @snapshots; do btrfs subvolume create "/mnt/$sv"; done
        if [[ -z ${HOME_PART:-} ]]; then btrfs subvolume create /mnt/@home; fi
        umount /mnt
        mount -t btrfs -o "$opts,subvol=@" "$ROOT_DEVICE" /mnt
        mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg /mnt/.snapshots
        mount -t btrfs -o "$opts,subvol=@log"       "$ROOT_DEVICE" /mnt/var/log
        mount -t btrfs -o "$opts,subvol=@pkg"       "$ROOT_DEVICE" /mnt/var/cache/pacman/pkg
        mount -t btrfs -o "$opts,subvol=@snapshots" "$ROOT_DEVICE" /mnt/.snapshots
        if [[ -z ${HOME_PART:-} ]]; then mount -t btrfs -o "$opts,subvol=@home" "$ROOT_DEVICE" /mnt/home; fi
    else
        mount -t "${FS_TYPE:-ext4}" -o "$opts" "$ROOT_DEVICE" /mnt
        mkdir -p /mnt/home
    fi

    if [[ -n ${HOME_PART:-} ]]; then
        mount -t "${FS_TYPE:-ext4}" -o noatime "${HOME_PART}" /mnt/home
    fi

    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then
        if [[ ${FORMAT_EFI:-n} == y ]]; then
            mkfs.fat -F32 "${EFI_PART:-}"
            udevadm settle
        fi
        mkdir -p /mnt/boot
        mount -t vfat "${EFI_PART:-}" /mnt/boot
    fi

    if [[ -n ${SWAP_PART:-} ]]; then
        mkswap "${SWAP_PART}"
        swapon "${SWAP_PART}"
    fi
    ok "Filesystems mounted."
}

build_package_lists() {
    BASE_PKGS=(base linux linux-firmware base-devel sudo nano git wget
               networkmanager grub ntfs-3g dosfstools exfatprogs
               bash-completion man-db man-pages pacman-contrib reflector)
    if [[ ${BOOT_MODE:-uefi} == uefi ]]; then BASE_PKGS+=(efibootmgr); fi
    if [[ ${ENABLE_ZRAM:-n} == y ]]; then BASE_PKGS+=(zram-generator); fi
    if [[ ${ENABLE_OSPROBER:-n} == y ]]; then BASE_PKGS+=(os-prober); fi

    SERVICES=(NetworkManager bluetooth fstrim.timer paccache.timer reflector.timer systemd-timesyncd)
    EXTRA_PKGS=(pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol bluez bluez-utils)

    case ${DE:-none} in
        xfce)     EXTRA_PKGS+=(xorg-server xfce4 xfce4-goodies lightdm lightdm-gtk-greeter); DM=lightdm ;;
        gnome)    EXTRA_PKGS+=(gnome gnome-tweaks); DM=gdm ;;
        kde)      EXTRA_PKGS+=(plasma-meta konsole dolphin kate ark sddm); DM=sddm ;;
        cinnamon) EXTRA_PKGS+=(xorg-server cinnamon nemo-fileroller gnome-terminal lightdm lightdm-gtk-greeter); DM=lightdm ;;
        mate)     EXTRA_PKGS+=(xorg-server mate mate-extra lightdm lightdm-gtk-greeter); DM=lightdm ;;
        lxqt)     EXTRA_PKGS+=(xorg-server lxqt sddm); DM=sddm ;;
        none)     ;;
    esac
    if [[ -n ${DM:-} ]]; then SERVICES+=("$DM"); fi
}

progress_step() {
    local start_pct=$1 end_pct=$2 label=$3
    shift 3
    if [[ $USE_DIALOG != y ]]; then
        info "$label"
        "$@"
        return
    fi

    (
        echo "$start_pct"
        echo "XXX"
        echo "$label..."
        echo "XXX"
        "$@" >/dev/null 2>&1
        echo "$end_pct"
        echo "XXX"
        echo "$label complete."
        echo "XXX"
    ) | dialog --backtitle "$UI_BACKTITLE" --title "Installing Arch Linux" --gauge "$label..." 8 70 "$start_pct" 2>&1 >"$DLG_TTY"
}

install_base() {
    pacstrap -K /mnt "${BASE_PKGS[@]}"
    genfstab -U /mnt > /mnt/etc/fstab
}

configure_system() {
    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        printf 'HOST_NAME=%q\nUSERNAME_=%q\nTIMEZONE=%q\nLOCALE=%q\nKEYMAP=%q\n' \
            "${HOST_NAME:-}" "${USERNAME_:-}" "${TIMEZONE:-}" "${LOCALE:-}" "${KEYMAP:-}"
        cat <<'CHROOT'
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc || true
locale-gen
echo "LANG=$LOCALE"   > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOST_NAME"     > /etc/hostname

useradd -m -G wheel -s /bin/bash "$USERNAME_"
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT
    } > /mnt/root/archbd-chroot.sh

    arch-chroot /mnt bash /root/archbd-chroot.sh
    rm -f /mnt/root/archbd-chroot.sh
}

set_passwords() {
    printf 'root:%s\n%s:%s\n' "${ROOT_PASSWORD:-}" "${USERNAME_:-}" "${USER_PASSWORD:-}" | arch-chroot /mnt chpasswd
    unset ROOT_PASSWORD USER_PASSWORD
}

finish() {
    umount -R /mnt
    ok "Installation complete!"
}

main() {
    start_logging "$@"
    parse_args "$@"
    preflight
    ui_init
    welcome
    gather_system
    detect_hardware
    choose_layout
    show_summary
    build_package_lists

    if [[ $USE_DIALOG == y ]]; then clear; fi
    info "ARCHBD INSTALL START - $(date '+%F %T')"
    progress_step 10 30 "Selecting mirrors and updating keyring" mirrors_and_keyring
    apply_layout
    progress_step 35 75 "Installing base system and packages" install_base
    progress_step 80 95 "Configuring desktop and bootloader" configure_system
    progress_step 96 100 "Setting account passwords" set_passwords
    finish
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
EOF