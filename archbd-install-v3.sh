#!/usr/bin/env bash
#
# archbd-install.sh v3 - Arch Linux installer (UEFI + BIOS)
# Original: (C) 2017 Md. Tariqul Islam Neil (Neil-seu) - License: GPL v3.0
#
# Usage (from the official Arch ISO, as root):
#     bash archbd-install.sh                 # interactive (dialog menus)
#     bash archbd-install.sh -p              # plain text prompts instead of dialog
#     bash archbd-install.sh -c my.conf      # answers from a file, asks the rest
#     bash archbd-install.sh -n              # dry run: ask, show the plan, change no disk
#
# Highlights: muted dark dialog theme, ext4 / btrfs / xfs, optional LUKS2 root
# encryption on UEFI, dynamic locale/keymap choices, selectable software groups,
# optional security lab packages, zram, VM guest tools, local mirrors first.
# Destructive layouts require an explicit ERASE confirmation even in config mode.

set -Eeuo pipefail
LOG=/tmp/archbd-install.log
USE_DIALOG=n
PLAIN_UI=${ARCHBD_PLAIN:+y}
trap 'on_error "$LINENO" "${FUNCNAME[0]:-main}"' ERR

# ---------------------------------------------------------------- defaults --
DEFAULT_TIMEZONE="Asia/Dhaka"
DEFAULT_LOCALE="en_US.UTF-8"
DEFAULT_KEYMAP="us"
DEFAULT_MIRROR_COUNTRIES="BD,IN,SG"   # nearby countries; type 'all' at the prompt for worldwide
DEFAULT_ESP_SIZE="512MiB"
# Extra mirrors to try first, e.g. in a config file:
#   PREFERRED_MIRRORS=("https://mirror.example.org/archlinux")
PREFERRED_MIRRORS=()

# ----------------------------------------------------------------- helpers --
c()    { printf '\e[1;%sm%s\e[0m\n' "$1" "$2"; }
info() { c 33 "==> $*"; }
ok()   { c 32 "OK: $*"; }
warn() { c 31 "!!  $*"; }
die()  { if [[ ${USE_DIALOG:-n} == y ]]; then clear; fi; warn "$*"; exit 1; }

usage() {
    cat <<'USAGE'
Usage: archbd-install.sh [-c CONFIG] [-n] [-p] [-h]
  -c CONFIG   read answers from CONFIG (shell variables); anything missing is asked
  -n          dry run: ask questions and print the plan, but change no disk
  -p          plain text prompts instead of dialog menus
  -h          this help
USAGE
}

# ---------------------------------------------------------------- UI layer ---
# One set of question functions, two front-ends: dialog menus (default when the
# dialog tool and a terminal are available) or plain text prompts (-p, or when
# dialog is missing). Answers preset in a config file skip the question in both.
# Never call these through $(...): dialogs and the "quit?" prompt must run in
# the main shell, so results are returned by variable name instead.
DLG_TITLE="ArchBD installer"
UI_BACKTITLE="ArchBD Installer v3  -  Arch Linux"
DLG_TTY=${ARCHBD_TTY:-/dev/tty}
MENU_DEFAULT=""
MENU_BACK=n
DLG_FAILS=0
declare -A MENU_DESC=()

ui_theme() {   # muted midnight palette: charcoal/navy canvas, amber text, teal focus
    cat <<'RC'
aspect = 0
separate_widget = ""
tab_len = 0
visit_items = OFF
use_shadow = ON
use_colors = ON
screen_color = (WHITE,BLUE,OFF)
shadow_color = (BLACK,BLACK,ON)
dialog_color = (WHITE,BLUE,OFF)
title_color = (YELLOW,BLUE,ON)
border_color = (CYAN,BLUE,ON)
border2_color = (CYAN,BLUE,OFF)
button_active_color = (BLACK,CYAN,ON)
button_inactive_color = (WHITE,BLUE,OFF)
button_key_active_color = (BLACK,CYAN,ON)
button_key_inactive_color = (YELLOW,BLUE,ON)
button_label_active_color = (BLACK,CYAN,ON)
button_label_inactive_color = (WHITE,BLUE,ON)
inputbox_color = (YELLOW,BLUE,OFF)
inputbox_border_color = (CYAN,BLUE,ON)
inputbox_border2_color = (CYAN,BLUE,OFF)
searchbox_color = (WHITE,BLUE,OFF)
searchbox_title_color = (YELLOW,BLUE,ON)
searchbox_border_color = (CYAN,BLUE,ON)
searchbox_border2_color = (CYAN,BLUE,OFF)
position_indicator_color = (YELLOW,BLUE,ON)
menubox_color = (WHITE,BLUE,OFF)
menubox_border_color = (CYAN,BLUE,ON)
menubox_border2_color = (CYAN,BLUE,OFF)
item_color = (WHITE,BLUE,OFF)
item_selected_color = (BLACK,CYAN,ON)
tag_color = (YELLOW,BLUE,ON)
tag_selected_color = (BLACK,CYAN,ON)
tag_key_color = (YELLOW,BLUE,ON)
tag_key_selected_color = (BLACK,CYAN,ON)
check_color = (WHITE,BLUE,OFF)
check_selected_color = (BLACK,CYAN,ON)
uarrow_color = (GREEN,BLUE,ON)
darrow_color = (GREEN,BLUE,ON)
itemhelp_color = (YELLOW,BLUE,OFF)
form_active_text_color = (BLACK,CYAN,ON)
form_text_color = (WHITE,BLUE,ON)
form_item_readonly_color = (CYAN,BLUE,ON)
gauge_color = (BLACK,GREEN,ON)
RC
}

ui_init() {   # decides between dialog and plain prompts
    USE_DIALOG=n
    if [[ ${PLAIN_UI:-n} == y ]]; then return 0; fi
    if [[ ! -t 0 || ! -t 1 ]]; then return 0; fi
    if ! command -v dialog >/dev/null; then
        echo "Installing the 'dialog' menu tool (tiny, live session only)..."
        timeout 90 pacman -Sy --noconfirm dialog >/dev/null 2>&1 || true
    fi
    if ! command -v dialog >/dev/null; then
        warn "dialog is not available, using plain text prompts instead."
        return 0
    fi
    if [[ ${ARCHBD_THEME:-dark} != classic ]]; then
        ui_theme > /tmp/archbd-dialogrc
        export DIALOGRC=/tmp/archbd-dialogrc
        # safety net: if this dialog version rejects the theme, fall back to its defaults
        if ! dialog --print-maxsize 2>&1 >"$DLG_TTY" | grep -q MaxSize; then unset DIALOGRC; fi
    fi
    USE_DIALOG=y
}

dlg() { dialog --backtitle "$UI_BACKTITLE" "$@" 2>&1 >"$DLG_TTY"; }

dlg_yesno() {   # dlg_yesno "text" [y|n default] -> rc 0 = yes
    local _t=${1//\\n/$'\n'} _h _rc=0
    local -a _x=()
    if [[ ${2:-n} != y ]]; then _x=(--defaultno); fi
    _h=$(( $(fold -s -w 62 <<<"$_t" | wc -l) + 6 ))
    dlg --title "$DLG_TITLE" "${_x[@]}" --yesno "$_t" "$_h" 68 >/dev/null || _rc=$?
    # every failed dialog ends up here (via confirm_quit), so this is where a broken
    # dialog is noticed: stop with advice instead of looping forever
    if (( _rc > 1 )); then
        DLG_FAILS=$(( DLG_FAILS + 1 ))
        if (( DLG_FAILS >= 12 )); then
            die "The dialog interface keeps failing on this terminal. Re-run with -p for plain text prompts."
        fi
    else
        DLG_FAILS=0
    fi
    return "$_rc"
}

dlg_msg() {   # dlg_msg "title" "text"
    local _t=${2//\\n/$'\n'} _h
    _h=$(( $(fold -s -w 62 <<<"$_t" | wc -l) + 6 ))
    dlg --title "$1" --msgbox "$_t" "$_h" 68 >/dev/null || true
}

dlg_textbox() {   # dlg_textbox "title" file ["exit label"]  (scrollable)
    local _rows _h
    _rows=$(tput lines 2>/dev/null || echo 24)
    _h=$(( _rows - 3 ))
    if (( _h > 30 )); then _h=30; fi
    dlg --title "$1" --exit-label "${3:-Continue}" --textbox "$2" "$_h" 78 >/dev/null || true
}

confirm_quit() {
    if dlg_yesno "Quit the installer?\n\nNothing has been changed on your disks yet." n; then
        clear
        echo "Cancelled - nothing was changed."
        exit 130
    fi
}

dlg_input() {   # dlg_input OUTVAR "text" ["default"]
    local _o=$1 _t=${2//\\n/$'\n'} _a _h
    _h=$(( $(fold -s -w 66 <<<"$_t" | wc -l) + 7 ))
    while true; do
        if _a=$(dlg --title "$DLG_TITLE" --inputbox "$_t" "$_h" 72 "${3:-}"); then
            printf -v "$_o" '%s' "$_a"
            return 0
        fi
        confirm_quit
    done
}

dlg_password() {   # dlg_password OUTVAR "text"
    local _o=$1 _t=${2//\\n/$'\n'} _a _h
    _h=$(( $(fold -s -w 66 <<<"$_t" | wc -l) + 7 ))
    while true; do
        if _a=$(dlg --title "$DLG_TITLE" --insecure --passwordbox "$_t" "$_h" 72); then
            printf -v "$_o" '%s' "$_a"
            return 0
        fi
        confirm_quit
    done
}

dlg_menu() {   # dlg_menu OUTVAR "text" "default-tag" tag item [tag item ...]
    local _o=$1 _t=${2//\\n/$'\n'} _d=$3 _a _n _mh _h _rows _tl
    shift 3
    local -a _x=()
    if [[ -n $_d ]]; then _x=(--default-item "$_d"); fi
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
        if [[ $MENU_BACK == y ]]; then return 1; fi
        confirm_quit
    done
}

ask() {   # ask VAR "prompt" ["default"] -> sets VAR
    local _v=$1 _p=${2//\\n/$'\n'} _r
    if [[ $USE_DIALOG == y ]]; then
        dlg_input "$_v" "$_p" "${3:-}"
        return 0
    fi
    read -r -p "$_p${3:+ [$3]}: " _r
    printf -v "$_v" '%s' "${_r:-${3:-}}"
}

ask_secret() {   # ask_secret VAR "prompt" -> sets VAR (input not shown)
    local _v=$1 _r
    if [[ $USE_DIALOG == y ]]; then
        dlg_password "$_v" "$2"
        return 0
    fi
    read -rs -p "${2//\\n/$'\n'}: " _r
    echo
    printf -v "$_v" '%s' "$_r"
}

confirm() {   # confirm "question" [y|n default] -> rc 0 = yes
    if [[ $USE_DIALOG == y ]]; then dlg_yesno "$1" "${2:-n}"; return; fi
    local def=${2:-n} hint reply
    if [[ $def == y ]]; then hint="Y/n"; else hint="y/N"; fi
    read -r -p "${1//\\n/$'\n'} [$hint]: " reply
    reply=${reply:-$def}
    [[ $reply =~ ^[Yy]([Ee][Ss])?$ ]]
}

notice() {   # a message the user must see: msgbox, or red text in plain mode
    if [[ $USE_DIALOG == y ]]; then dlg_msg "Please note" "$*"; else warn "${*//\\n/$'\n'}"; fi
}

say() {   # say "title" "text": friendly information (msgbox, or plain text)
    if [[ $USE_DIALOG == y ]]; then
        dlg_msg "$1" "$2"
    else
        echo; info "$1"; echo "${2//\\n/$'\n'}"; echo
    fi
}

get() {   # get VAR "prompt" [default]
    if [[ ! -v $1 ]]; then ask "$1" "$2" "${3:-}"; fi
}

get_yn() {   # get_yn VAR "question" [y|n]
    local var=$1
    if [[ ! -v $var ]]; then
        if confirm "$2" "${3:-n}"; then printf -v "$var" y; else printf -v "$var" n; fi
    fi
}

get_choice() {   # get_choice VAR "prompt" opt1 opt2 ...   (uses MENU_DESC[opt] and MENU_DEFAULT if set)
    local var=$1 prompt=$2 pick="" o
    shift 2
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

get_valid() {   # get_valid VAR "prompt" "default" check_fn "error text"
    local var=$1 prompt=$2 default=$3 check=$4 msg=$5 reply
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

get_password() {   # get_password VAR "prompt" (asks twice, never empty)
    local var=$1 p1 p2
    if [[ -v $var ]]; then return 0; fi
    while true; do
        ask_secret p1 "$2"
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

valid_hostname() { [[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9-]*$ ]]; }
valid_username() { [[ $1 =~ ^[a-z_][a-z0-9_-]*$ ]]; }
valid_timezone() { [[ -n $1 && -f /usr/share/zoneinfo/$1 ]]; }
valid_locale()   { [[ ! -f /usr/share/i18n/SUPPORTED ]] || awk -v l="$1" '$1 == l { f = 1 } END { exit !f }' /usr/share/i18n/SUPPORTED; }
valid_keymap()   { [[ ! -d /usr/share/kbd/keymaps ]] || [[ -n $(find /usr/share/kbd/keymaps -name "$1.map.gz" -print -quit) ]]; }

get_timezone() {   # dialog: Region -> City menus; plain: type Region/City
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

choose_partition() {   # choose_partition VAR "prompt" [optional]
    local var=$1 prompt=$2 optional=${3:-} line
    local -a parts=() items=()
    if [[ -v $var ]]; then
        if [[ -n ${!var} ]]; then need_block "${!var}"; fi
        return 0
    fi
    if [[ $USE_DIALOG != y ]]; then
        ask "$var" "$prompt${optional:+ (blank = none)}"
        if [[ -n ${!var} ]]; then need_block "${!var}"; fi
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
    if [[ ${!var} == none ]]; then printf -v "$var" ''; fi
}

view_log() {   # scrollable, cleaned-up copy of the install log
    local body=/tmp/archbd-install.body.log clean=/tmp/archbd-install.clean.log
    if [[ ! -s $LOG ]]; then notice "There is no log yet."; return 0; fi
    sed -n '/ARCHBD INSTALL START/,$p' "$LOG" > "$body"
    if [[ ! -s $body ]]; then cp "$LOG" "$body"; fi
    sed -E 's#\x1b\[[0-9;?]*[ -/]*[@-~]##g; s#\x1b[()][A-Z0-9]##g; s#\x1b[=>78Mc]##g' "$body" \
        | tr '\r' '\n' | cat -s > "$clean"
    DLG_TITLE="Install log"
    dlg_textbox "Install log - arrows / PgUp / PgDn scroll, Enter closes" "$clean" "Close"
}

on_error() {   # on_error LINE FUNCTION   (ERR trap)
    trap - ERR
    if [[ $USE_DIALOG == y ]]; then clear; fi
    printf '\n\e[1;31mFailed in %s (line %s). Installation stopped.\e[0m\n' "$2" "$1" >&2
    printf 'Full log: less -R %s\nIMPORTANT: do NOT blindly rerun with the same disk config. Auto/custom mode erases the selected disk. Inspect the log and disk state first.\n' "$LOG" >&2
    if [[ $USE_DIALOG == y && -s $LOG ]]; then
        DLG_TITLE="Something went wrong"
        if dlg_yesno "The installer stopped in '$2' (line $1).\n\nOpen the log now? Scroll it with the arrow keys and PageUp/PageDown." y; then
            view_log || true
        fi
        clear
        printf 'Failed in %s (line %s). Log: less -R %s\n' "$2" "$1" "$LOG" >&2
    fi
}

welcome() {
    if [[ $USE_DIALOG != y ]]; then return 0; fi
    dlg_msg "Welcome" "ArchBD installer v3\n\nThis guides you through installing Arch Linux ($BOOT_MODE boot).\n\nKeys:  arrows = move   Tab = switch buttons\n       Enter = confirm   Esc = cancel\n\nNothing is changed on your disks until you confirm the final plan."
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

# ------------------------------------------------------- partition sizes ---
size_to_mib() {   # "4G" -> 4096 | "rest" -> rest | ""/"none" -> (nothing) | invalid -> return 1
    local s=${1,,} mib
    s=${s#"${s%%[![:space:]]*}"}; s=${s%"${s##*[![:space:]]}"}   # trim
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

fmt_mib() {   # 4096 -> 4G | 1536 -> 1.5G | 512 -> 512M | rest -> rest
    local m=$1
    if [[ $m == rest ]]; then
        echo "rest"
    elif (( m >= 1024 )); then
        awk -v m="$m" 'BEGIN { g = m / 1024; if (g == int(g)) printf "%dG\n", g; else printf "%.1fG\n", int(g * 10) / 10 }'
    else
        echo "${m}M"
    fi
}

ask_size() {   # ask_size VAR "prompt" "default"  (asks until valid; a preset VAR is only validated)
    local var=$1 prompt=$2 default=$3 reply
    if [[ -v $var ]]; then
        size_to_mib "${!var}" >/dev/null || die "Invalid size in $var: '${!var}' (examples: 512M, 4G, rest, none)"
        return 0
    fi
    while true; do
        ask reply "$prompt\n\nExamples: 512M, 4G, 1.5G  |  rest = all that is left  |  none = skip" "$default"
        if size_to_mib "$reply" >/dev/null; then
            printf -v "$var" '%s' "$reply"
            return 0
        fi
        notice "That is not a valid size.\n\nExamples: 512M, 4G, 1.5G, rest, none."
    done
}

write_partition_table() {   # uses BOOT_MODE, INSTALL_DISK, ESP_MIB, SWAP_MIB, ROOT_MIB, HOME_MIB
    local table boot_flag=""
    if [[ $BOOT_MODE == uefi ]]; then table="label: gpt"; else table="label: dos"; boot_flag=", bootable"; fi
    table+=$'\n'
    if [[ $BOOT_MODE == uefi ]]; then table+="size=${ESP_MIB}MiB, type=U"$'\n'; fi
    if [[ -n $SWAP_MIB ]]; then table+="size=${SWAP_MIB}MiB, type=S"$'\n'; fi
    if [[ $ROOT_MIB == rest ]]; then
        table+="type=L${boot_flag}"$'\n'
    else
        table+="size=${ROOT_MIB}MiB, type=L${boot_flag}"$'\n'
    fi
    if [[ -n $HOME_MIB ]]; then
        if [[ $HOME_MIB == rest ]]; then table+="type=L"$'\n'; else table+="size=${HOME_MIB}MiB, type=L"$'\n'; fi
    fi
    printf '%s' "$table" | sfdisk --quiet "$INSTALL_DISK"
}

# ------------------------------------------------------------ filesystems ---
make_fs() {    # make_fs FS DEVICE LABEL
    case $1 in
        ext4)  mkfs.ext4 -F -L "$3" "$2" ;;
        btrfs) mkfs.btrfs -f -L "$3" "$2" ;;
        xfs)   mkfs.xfs  -f -L "$3" "$2" ;;
        *)     die "Unsupported filesystem: $1" ;;
    esac
    udevadm settle   # let udev notice the new filesystem before anything mounts it
}

mount_opts() { # mount_opts FS
    case $1 in
        btrfs) echo "noatime,compress=zstd:1" ;;
        *)     echo "noatime" ;;
    esac
}

# ---------------------------------------------------------------- logging ---
# The Linux console cannot scroll back, so the whole session is recorded and
# you can read it afterwards with:  less -R /tmp/archbd-install.log
# The script re-runs itself inside script(1), which keeps a real terminal, so
# cfdisk, menus and colours all keep working.
start_logging() {
    [[ -z ${ARCHBD_LOGGING:-} ]] || return 0
    command -v script >/dev/null || return 0
    [[ -t 0 && -t 1 ]] || return 0
    export ARCHBD_LOGGING=1
    local cmd
    cmd=$(printf '%q ' bash "$0" "$@")
    exec script -qefc "$cmd" "$LOG"
}

# -------------------------------------------------------------- arguments ---
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
        sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    fi
}

# --------------------------------------------------------- system questions -
pick_from_live_list() { # pick_from_live_list OUTVAR title source-command default; searchable filter + menu
    local out=$1 title=$2 source=$3 def=${4:-} query pick
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
        info "Arch installer v2 - answer the questions now, installation runs afterwards."
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
        pick_from_live_list LOCALE "Locale (system language)" "awk '{sub(/^#[[:space:]]*/, ""); if (NF >= 2 && $2 == "UTF-8") print $1}' /etc/locale.gen" "$DEFAULT_LOCALE"
    else valid_locale "$LOCALE" || die "Unknown locale: $LOCALE"; fi
    if [[ ! -v KEYMAP ]]; then
        pick_from_live_list KEYMAP "Console keyboard layout" "localectl list-keymaps 2>/dev/null | sed 's/\.map$//'" "$DEFAULT_KEYMAP"
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

    DLG_TITLE="Disk encryption"
    get_yn ENCRYPT_ROOT "Encrypt the root filesystem with LUKS2?\n\nThe EFI System Partition stays unencrypted and will be mounted at /boot. You will enter a disk-unlock passphrase at every boot. Keep a recovery copy of the passphrase. Separate /home partitions, if selected, are not encrypted by this option." n
    ENCRYPT_ROOT=${ENCRYPT_ROOT:-n}
    validate "$ENCRYPT_ROOT" ENCRYPT_ROOT y n
    if [[ $ENCRYPT_ROOT == y && $BOOT_MODE != uefi ]]; then
        die "LUKS2 root encryption is currently supported by this installer only in UEFI mode. Boot-time unlocking for BIOS/GRUB needs a separate tested boot design; no disk changes have been made."
    fi

    DLG_TITLE="Extras"
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
    get_yn SECURITY_PROFILE "Install the optional penetration-testing lab toolkit?\n\nInstalls curated auditing tools only. It does not run scans or enable attack services. Use only on systems you own or are authorized to test." n
    get_yn WANT_FIREWALL "Enable a firewall (ufw)?\n\nBlocks incoming connections, allows outgoing ones." n
}

# ------------------------------------------------------ hardware detection --
detect_hardware() {
    VIRT=$(systemd-detect-virt || true)
    GPU_INFO=""
    if [[ $VIRT == none ]]; then
        GPU_INFO=$(lspci | grep -Ei 'vga|3d|display' || true)
        if grep -qi nvidia <<<"$GPU_INFO"; then
            DLG_TITLE="Graphics"
            MENU_DESC=([nvidia-open]="RTX 20-series / GTX 16-series and newer"
                       [nouveau]="Open-source Mesa driver, any card (pick for GTX 10xx and older)")
            get_choice NVIDIA_CHOICE "An NVIDIA graphics card was detected.\nWhich driver do you want?" nvidia-open nouveau
            validate "$NVIDIA_CHOICE" NVIDIA_CHOICE nvidia-open nouveau
        fi
    fi
}

# ------------------------------------------------------------------ layout --
choose_disk() {   # sets INSTALL_DISK (menu), skipping the live USB
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

name_partitions() {   # names the partitions in creation order: EFI, swap, root, home
    local n=1
    EFI_PART=""; SWAP_PART=""; HOME_PART=""
    if [[ $BOOT_MODE == uefi ]]; then EFI_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1)); fi
    if [[ -n $SWAP_MIB ]]; then SWAP_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1)); fi
    ROOT_PART=$(part_path "$INSTALL_DISK" "$n"); n=$((n + 1))
    if [[ -n $HOME_MIB ]]; then HOME_PART=$(part_path "$INSTALL_DISK" "$n"); fi
    FORMAT_EFI=y
    if [[ -n $HOME_PART ]]; then FORMAT_HOME=y; else FORMAT_HOME=n; fi
}

layout_auto() {
    WIPE_DISK=y
    choose_disk
    if [[ ! -v ESP_SIZE ]]; then ESP_SIZE=$DEFAULT_ESP_SIZE; fi
    ESP_MIB=0
    if [[ $BOOT_MODE == uefi ]]; then ESP_MIB=$(size_to_mib "$ESP_SIZE") || die "Invalid ESP_SIZE: $ESP_SIZE"; fi
    SWAP_MIB=""; ROOT_MIB=rest; HOME_MIB=""
    name_partitions
}

custom_sizes() {   # custom_sizes USABLE_MIB: asks for the sizes and checks them; returns 1 (after a message) if they do not work
    local usable=$1 used left root_final
    ESP_MIB=0
    if [[ $BOOT_MODE == uefi ]]; then
        ask_size ESP_SIZE "EFI/boot partition size" "$DEFAULT_ESP_SIZE"
        ESP_MIB=$(size_to_mib "$ESP_SIZE")
        if ! [[ $ESP_MIB =~ ^[0-9]+$ ]] || (( ESP_MIB < 100 )); then
            notice "The EFI partition needs a fixed size of at least 100M (512M is recommended)."
            return 1
        fi
    fi

    ask_size SWAP_SIZE "Swap partition size\n(none = use compressed RAM swap, zram, instead)" "none"
    SWAP_MIB=$(size_to_mib "$SWAP_SIZE")
    if [[ $SWAP_MIB == rest ]]; then notice "Swap cannot be 'rest'; give it a fixed size."; return 1; fi

    ask_size ROOT_SIZE "Root partition size\n(rest = everything that is left)" "rest"
    ROOT_MIB=$(size_to_mib "$ROOT_SIZE")
    if [[ -z $ROOT_MIB ]]; then notice "The root partition cannot be 'none'."; return 1; fi

    if [[ $ROOT_MIB == rest ]]; then
        if [[ -v HOME_SIZE && -n $(size_to_mib "$HOME_SIZE" || true) ]]; then
            notice "Root is 'rest', which leaves no room for /home. Give root a fixed size."
            return 1
        fi
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
        notice "These sizes add up to $(fmt_mib "$used") but the disk only has $(fmt_mib "$usable") usable.\n\nPlease choose smaller sizes."
        return 1
    fi

    if [[ $ROOT_MIB == rest ]]; then
        if (( left < 8192 )); then
            notice "Only $(fmt_mib "$left") would be left for root; it needs at least 8G."
            return 1
        fi
        root_final=$left
    else
        if (( ROOT_MIB < 8192 )); then
            notice "Root needs at least 8G (you gave $(fmt_mib "$ROOT_MIB"))."
            return 1
        fi
        root_final=$ROOT_MIB
        if [[ $HOME_MIB == rest ]]; then
            if (( left < 1024 )); then
                notice "Only $(fmt_mib "$left") would be left for /home; it needs at least 1G."
                return 1
            fi
        elif (( left > 0 )); then
            say "Unallocated space" "$(fmt_mib "$left") will stay unallocated."
        fi
    fi
    if [[ $DE != none ]] && (( root_final < 20480 )); then
        notice "Root will be only $(fmt_mib "$root_final"); a desktop install is happier with 20G or more."
    fi
    return 0
}

layout_custom() {
    WIPE_DISK=y
    choose_disk
    local disk_mib usable preset=n intro
    disk_mib=$(( $(lsblk -bdno SIZE "$INSTALL_DISK") / 1048576 ))
    usable=$(( disk_mib - 2 ))   # room for the partition tables and alignment

    DLG_TITLE="Custom layout"
    intro="Disk $INSTALL_DISK is $(fmt_mib "$disk_mib") and will be completely ERASED.\n\nType sizes like 512M, 4G or 1.5G (1G = 1024M).\n'rest' = all remaining space, 'none' = skip.\n\nPartitions are created in this order: "
    if [[ $BOOT_MODE == uefi ]]; then
        intro+="EFI/boot, swap, root, home."
    else
        intro+="swap, root, home.\n(BIOS boot needs no separate boot partition.)"
    fi
    say "Custom layout" "$intro"

    if [[ -v ROOT_SIZE ]]; then preset=y; fi
    while true; do
        if custom_sizes "$usable"; then break; fi
        if [[ $preset == y ]]; then die "The sizes in the config file do not work (see the message above)."; fi
        unset ESP_SIZE SWAP_SIZE ROOT_SIZE HOME_SIZE
    done
    name_partitions
}

layout_manual() {
    WIPE_DISK=n
    DLG_TITLE="Existing partitions"
    if [[ ! -v ROOT_PART ]]; then
        show_block_devices
        if [[ $DRY_RUN != y ]] && confirm "Open cfdisk to create or edit partitions first?" n; then
            choose_disk
            if [[ $BOOT_MODE == uefi ]]; then
                say "cfdisk" "UEFI: use a GPT disk with an EFI System partition (about 512M) plus a root partition.\nChoose [Write] to save, then [Quit]."
            else
                say "cfdisk" "BIOS: use a DOS (MBR) label with a bootable root partition.\nChoose [Write] to save, then [Quit]."
            fi
            cfdisk "$INSTALL_DISK"
            show_block_devices
        fi
    fi

    DLG_TITLE="Choose partitions"
    choose_partition ROOT_PART "Which partition is the ROOT (/) partition?\n\nIt will be FORMATTED."
    if [[ $BOOT_MODE == uefi ]]; then
        choose_partition EFI_PART "Which partition is the EFI System partition?"
        get_yn FORMAT_EFI "Format the EFI partition?\n\nSay NO if another operating system already uses it." n
    else
        EFI_PART=""; FORMAT_EFI=n
    fi

    choose_partition SWAP_PART "Which partition should be used as swap?\n\nIt will be formatted." optional
    choose_partition HOME_PART "Which partition should be /home?" optional
    if [[ -n $HOME_PART ]]; then
        get_yn FORMAT_HOME "Format $HOME_PART?\n\nSay NO to keep the existing data." n
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
    DLG_TITLE="Partitioning"
    MENU_DESC=([auto]="Wipe one disk: EFI/boot + root (root gets the rest)"
               [custom]="Wipe one disk and YOU choose the sizes (boot, swap, root, home)"
               [manual]="Use partitions that already exist (or make them in cfdisk)")
    get_choice PARTITION_MODE "How do you want to partition?" auto custom manual
    validate "$PARTITION_MODE" PARTITION_MODE auto custom manual

    case $PARTITION_MODE in
        auto)   layout_auto ;;
        custom) layout_custom ;;
        manual) layout_manual ;;
    esac

    DLG_TITLE="Swap and boot"
    if [[ -n $SWAP_PART ]]; then
        ENABLE_ZRAM=n
    else
        get_yn ENABLE_ZRAM "Use compressed RAM swap (zram)?\n\nRecommended when you have no swap partition." y
    fi
    get_yn ENABLE_OSPROBER "Dual-boot with another operating system?\n\nThis enables os-prober so GRUB can find it." n

    if [[ $PARTITION_MODE == manual ]]; then
        TARGET_DISK="/dev/$(lsblk -no pkname "$ROOT_PART" | head -n1)"
    else
        TARGET_DISK=$INSTALL_DISK
    fi
}

plan_text() {   # the plan, as plain text; lines starting with "!!" are warnings
    printf '%-14s %s\n' "Boot mode:"  "$BOOT_MODE${VIRT:+ (virt: $VIRT)}"
    printf '%-14s %s\n' "Hostname:"   "$HOST_NAME"
    printf '%-14s %s\n' "User:"       "$USERNAME_"
    printf '%-14s %s\n' "Timezone:"   "$TIMEZONE"
    printf '%-14s %s\n' "Desktop:"    "$DE"
    printf '%-14s %s\n' "Filesystem:" "$FS_TYPE"
    printf '%-14s %s\n' "LUKS2 root:" "${ENCRYPT_ROOT:-n}"
    if [[ ${ENCRYPT_ROOT:-n} == y ]]; then echo "!! Encryption currently covers root only. A separate /home partition is not encrypted. Keep the passphrase safe and back up the LUKS header after installation."; fi
    printf '%-14s %s\n' "Software groups:" "${APP_CATEGORIES:-none}"
    printf '%-14s %s\n' "Custom packages:" "${CUSTOM_PACKAGES:-none}"
    printf '%-14s %s\n' "Security lab:" "${SECURITY_PROFILE:-n}"
    printf '%-14s %s\n' "Mirrors:"    "${MIRROR_COUNTRIES:-worldwide}"
    echo
    if [[ $WIPE_DISK == y ]]; then
        echo "!! ERASE EVERYTHING on $INSTALL_DISK and create:"
        if [[ $BOOT_MODE == uefi ]]; then
            printf '     %-16s %8s  EFI System (FAT32)\n' "$EFI_PART" "$(fmt_mib "$ESP_MIB")"
        fi
        if [[ -n $SWAP_MIB ]]; then
            printf '     %-16s %8s  swap\n' "$SWAP_PART" "$(fmt_mib "$SWAP_MIB")"
        fi
        printf '     %-16s %8s  root (%s)\n' "$ROOT_PART" "$(fmt_mib "$ROOT_MIB")" "$FS_TYPE"
        if [[ -n $HOME_MIB ]]; then
            printf '     %-16s %8s  /home (%s)\n' "$HOME_PART" "$(fmt_mib "$HOME_MIB")" "$FS_TYPE"
        fi
    else
        if [[ ${ENCRYPT_ROOT:-n} == y ]]; then
            echo "!! FORMAT $ROOT_PART as LUKS2, then create $FS_TYPE inside /dev/mapper/cryptroot (root)"
            echo "!! The EFI partition stays unencrypted and is mounted at /boot. Back up the LUKS header after installation."
        else
            echo "!! FORMAT $ROOT_PART as $FS_TYPE (root)"
        fi
        if [[ $FORMAT_EFI == y ]]; then echo "!! FORMAT $EFI_PART as FAT32 (EFI)"; fi
        if [[ -n $SWAP_PART ]]; then echo "!! mkswap $SWAP_PART (swap)"; fi
        if [[ -n $HOME_PART ]]; then
            if [[ $FORMAT_HOME == y ]]; then
                echo "!! FORMAT $HOME_PART as $FS_TYPE (/home)"
            else
                echo "   keep existing data on $HOME_PART (/home)"
            fi
        fi
        if [[ $FORMAT_EFI != y && -n $EFI_PART ]]; then echo "   keep existing $EFI_PART (EFI)"; fi
    fi
    echo
    if [[ $BOOT_MODE == bios ]]; then
        printf '%-14s %s\n' "Bootloader:" "GRUB (BIOS) on $TARGET_DISK"
    else
        printf '%-14s %s\n' "Bootloader:" "GRUB (UEFI)"
    fi
    printf '%-14s %s\n' "zram:" "$ENABLE_ZRAM"
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
        awk '/^!!/ { printf "\033[1;31m%s\033[0m\n", $0; next } { print }' "$plan"
        echo
    fi

    if [[ $DRY_RUN == y ]]; then
        if [[ $USE_DIALOG == y ]]; then clear; fi
        ok "Dry run finished - nothing was changed on your disks."
        exit 0
    fi
    if [[ $WIPE_DISK == y || ${ENCRYPT_ROOT:-n} == y ]]; then
        DLG_TITLE="Destructive operation confirmation"
        ask answer "Type ERASE to confirm the disk operation.\n\nTarget: ${INSTALL_DISK:-$ROOT_PART}\nThis cannot be undone. Encryption passphrase loss means data loss. Do not rely on ASSUME_YES for destructive operations." ""
        [[ $answer == ERASE ]] || die "Aborted by user."
    elif [[ ${ASSUME_YES:-n} != y ]]; then
        DLG_TITLE="Last confirmation"
        ask answer "Type YES (capitals) to start the installation.\n\nYour selected partitions will be changed exactly as shown in the plan." ""
        [[ $answer == YES ]] || die "Aborted by user."
    fi
}

# --------------------------------------------------- mirrors and keyring ----
# How the mirror step works, in plain words:
#   1. Mirrors close to you are tried first. For some countries we know the
#      official local mirrors (builtin_mirrors_for); you can add your own with
#      PREFERRED_MIRRORS=(...) in the config file.
#   2. Each one gets a quick check of a few seconds: does it answer, and was it
#      synced in the last 24 hours? (every mirror publishes a 'lastsync' file)
#   3. The ones that pass go to the top of the mirrorlist, and the ISO's own
#      mirrors stay below them as a backup. pacman falls through the list in
#      order, so a failing mirror never stops the install.
#   4. If no nearby mirror passes, reflector builds a list from the official
#      status data, sorted by mirror score (no downloads, so it is quick).
#      Set MIRROR_SORT=rate in the config for reflector's slow real speed test.
builtin_mirrors_for() {   # builtin_mirrors_for COUNTRY_CODE_OR_NAME
    case ${1^^} in
        BD|BANGLADESH) echo "https://mirror.xeonbd.com/archlinux https://mirror.limda.net/archlinux" ;;
    esac
}

probe_mirror() {   # probe_mirror BASE_URL -> prints "reply_seconds minutes_since_sync", or fails
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
    if [[ -n $MIRROR_COUNTRIES ]]; then args+=(--country "$MIRROR_COUNTRIES"); fi
    echo "  Asking reflector (sorted by '$sort', gives up after 90 s)..."
    if timeout 90 reflector "${args[@]}"; then
        ok "Mirrorlist created by reflector."
    else
        warn "reflector failed or timed out; keeping the ISO's mirror list."
    fi
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
    IFS=',' read -ra codes <<<"$MIRROR_COUNTRIES"
    for code in "${codes[@]}"; do
        code=${code// /}
        # shellcheck disable=SC2046
        for url in $(builtin_mirrors_for "$code"); do candidates+=("$url"); done
    done

    if (( ${#candidates[@]} )); then
        echo "  Checking nearby mirrors (must answer and be synced within 24 h):"
        for url in "${candidates[@]}"; do
            if res=$(probe_mirror "$url"); then
                read -r secs age <<<"$res"
                printf '    OK    %-42s answered in %ss, synced %s min ago\n' "$url" "$secs" "$age"
                timed+=("$secs $url")
            else
                printf '    SKIP  %-42s no answer, or out of date\n' "$url"
            fi
        done
    fi

    if (( ${#timed[@]} )); then
        mapfile -t sorted < <(printf '%s\n' "${timed[@]}" | sort -n | cut -d' ' -f2-)
        {
            echo "# Written by archbd-install.sh: nearby mirrors first, ISO mirrors as backup"
            for url in "${sorted[@]}"; do echo "Server = ${url%/}/\$repo/os/\$arch"; done
            grep -m5 '^Server' "$iso_copy" || true
        } > "$list"
        ok "Using ${#sorted[@]} nearby mirror(s) first, ISO mirrors as backup."
    else
        reflector_fallback
    fi

    info "Refreshing the keyring..."
    pacman -Sy --noconfirm archlinux-keyring
}

# ----------------------------------------------- partition, format, mount ---
apply_layout() {
    swapoff -a || true
    if mountpoint -q /mnt; then umount -R /mnt; fi

    if [[ $WIPE_DISK == y ]]; then
        local live_src live_disk
        live_src=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)
        live_disk="/dev/$(lsblk -no pkname "$live_src" 2>/dev/null | head -n1 || true)"
        [[ -z $live_src || $INSTALL_DISK != "$live_disk" ]] || die "Refusing to erase the disk that contains the live Arch ISO ($INSTALL_DISK)."
    fi
    for part in "$ROOT_PART" "${EFI_PART:-}" "${SWAP_PART:-}" "${HOME_PART:-}"; do
        [[ -n $part ]] || continue
        if findmnt -rn -S "$part" >/dev/null 2>&1; then
            die "$part is currently mounted. Unmount it before installing; no partitions were formatted by this check."
        fi
    done

    if [[ $WIPE_DISK == y ]]; then
        info "Partitioning $INSTALL_DISK..."
        wipefs -af "$INSTALL_DISK"
        write_partition_table
        partprobe "$INSTALL_DISK"
        udevadm settle
    fi

    info "Preparing root storage ($FS_TYPE)..."
    local opts sv part ROOT_DEVICE="$ROOT_PART"
    opts=$(mount_opts "$FS_TYPE")
    wipefs -a "$ROOT_PART"
    if [[ ${ENCRYPT_ROOT:-n} == y ]]; then
        command -v cryptsetup >/dev/null || die "cryptsetup is required for encryption."
        cryptsetup luksFormat --type luks2 --label archcrypt "$ROOT_PART"
        cryptsetup open "$ROOT_PART" cryptroot
        ROOT_DEVICE=/dev/mapper/cryptroot
        ENCRYPTED_ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
        [[ -n $ENCRYPTED_ROOT_UUID ]] || die "Could not read the LUKS UUID."
    fi
    make_fs "$FS_TYPE" "$ROOT_DEVICE" archroot

    # Always mount with an explicit -t: auto-detection can fail right after mkfs
    # (stale udev data) and then mount guesses types one by one and gives up.
    if [[ $FS_TYPE == btrfs ]]; then
        mount -t btrfs "$ROOT_DEVICE" /mnt
        for sv in @ @log @pkg @snapshots; do btrfs subvolume create "/mnt/$sv"; done
        if [[ -z $HOME_PART ]]; then btrfs subvolume create /mnt/@home; fi
        umount /mnt

        mount -t btrfs -o "$opts,subvol=@" "$ROOT_DEVICE" /mnt
        mkdir -p /mnt/home /mnt/var/log /mnt/var/cache/pacman/pkg /mnt/.snapshots
        mount -t btrfs -o "$opts,subvol=@log"       "$ROOT_DEVICE" /mnt/var/log
        mount -t btrfs -o "$opts,subvol=@pkg"       "$ROOT_DEVICE" /mnt/var/cache/pacman/pkg
        mount -t btrfs -o "$opts,subvol=@snapshots" "$ROOT_DEVICE" /mnt/.snapshots
        if [[ -z $HOME_PART ]]; then mount -t btrfs -o "$opts,subvol=@home" "$ROOT_DEVICE" /mnt/home; fi
    else
        mount -t "$FS_TYPE" -o "$opts" "$ROOT_DEVICE" /mnt
        mkdir -p /mnt/home
    fi

    if [[ -n $HOME_PART ]]; then
        if [[ $FORMAT_HOME == y ]]; then
            wipefs -a "$HOME_PART"
            make_fs "$FS_TYPE" "$HOME_PART" archhome
            mount -t "$FS_TYPE" -o "$opts" "$HOME_PART" /mnt/home
        else
            local home_fs
            home_fs=$(blkid -p -o value -s TYPE "$HOME_PART" || true)
            [[ -n $home_fs ]] || die "Cannot detect a filesystem on $HOME_PART (format it, or check it first)."
            mount -t "$home_fs" -o noatime "$HOME_PART" /mnt/home
        fi
    fi

    if [[ $BOOT_MODE == uefi ]]; then
        if [[ $FORMAT_EFI == y ]]; then
            mkfs.fat -F32 "$EFI_PART"
            udevadm settle
        fi
        if [[ ${ENCRYPT_ROOT:-n} == y ]]; then
            mkdir -p /mnt/boot
            mount -t vfat "$EFI_PART" /mnt/boot
        else
            mkdir -p /mnt/boot/efi
            mount -t vfat "$EFI_PART" /mnt/boot/efi
        fi
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
    if [[ ${ENCRYPT_ROOT:-n} == y ]]; then BASE_PKGS+=(cryptsetup); fi
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

    # ---- curated multi-select software groups (official repositories only)
    local cat
    for cat in ${APP_CATEGORIES:-}; do
        case $cat in
            everyday)  EXTRA_PKGS+=(firefox vlc libreoffice-fresh gimp gparted htop zsh zsh-syntax-highlighting rsync unzip 7zip unrar) ;;
            developer) EXTRA_PKGS+=(vim neovim git-lfs python python-pip python-virtualenv go rust docker docker-compose) ;;
            sysadmin)  EXTRA_PKGS+=(btop fastfetch lsof strace tcpdump nmap traceroute bind iperf3 smartmontools testdisk) ;;
            creative)  EXTRA_PKGS+=(krita inkscape audacity obs-studio kdenlive darktable) ;;
            security)  EXTRA_PKGS+=(wireshark-qt aircrack-ng john hashcat hydra sqlmap nikto yara clamav) ;;
            *) die "Unknown APP_CATEGORIES entry '$cat'. Allowed: everyday developer sysadmin creative security" ;;
        esac
    done
    if [[ ${SECURITY_PROFILE:-n} == y ]]; then
        EXTRA_PKGS+=(nmap wireshark-qt tcpdump aircrack-ng john hashcat hydra sqlmap nikto gobuster ffuf yara ghidra radare2 binwalk sleuthkit testdisk)
    fi
    local custom_pkg
    local -a custom_pkg_list=()
    read -r -a custom_pkg_list <<< "${CUSTOM_PACKAGES:-}"
    for custom_pkg in "${custom_pkg_list[@]}"; do
        [[ $custom_pkg =~ ^[A-Za-z0-9@._+-]+$ ]] || die "Invalid package name: $custom_pkg"
        EXTRA_PKGS+=("$custom_pkg")
    done

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

validate_package_catalog() {
    local pkg
    local -a missing=()
    info "Checking selected package names against the current official repository databases..."
    for pkg in "${BASE_PKGS[@]}" "${EXTRA_PKGS[@]}"; do
        pacman -Si "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    if (( ${#missing[@]} )); then
        printf '%s\n' "Unavailable package names: ${missing[*]}" | tee -a "$LOG" >&2
        die "Some selected packages are not available in the current enabled repositories. No target-disk formatting has started; adjust the profile or repository configuration first."
    fi
    ok "All selected package names are available in the enabled repositories."
}

# ---------------------------------------------------------------- install ---
progress_step() { # progress_step start_pct end_pct label command...; phase checkpoints, not byte-accurate download progress
    local start_pct=$1 end_pct=$2 label=$3 rc=0 pid gauge_pid fifo current last='Preparing...' stage_log stage_dir proc_state
    shift 3
    if [[ $USE_DIALOG != y ]]; then
        info "$label"
        "$@"
        return
    fi
    stage_dir=$(mktemp -d /tmp/archbd-stage.XXXXXX)
    fifo="$stage_dir/gauge.fifo"
    stage_log="$stage_dir/command.log"
    mkfifo "$fifo"
    dialog --title "ArchBD installation" --gauge "Phase progress. Full command output is logged to $LOG." 9 78 0 < "$fifo" &
    gauge_pid=$!
    exec 3>"$fifo"
    rm -f "$fifo"
    printf 'XXX\n%s\n%s\nXXX\n' "$start_pct" "$label" >&3
    ( trap - ERR; "$@" ) >"$stage_log" 2>&1 &
    pid=$!
    while true; do
        proc_state=$(ps -o stat= -p "$pid" 2>/dev/null || true)
        [[ -n $proc_state && $proc_state != Z* ]] || break
        current=$(grep -E 'installing |upgrading |checking keys in keyring|Generating .*initramfs|Installing the base system|Configuring the new system' "$stage_log" 2>/dev/null | tail -n1 || true)
        [[ -n $current ]] && last=$current
        printf 'XXX\n%s\n%s\nCurrent activity: %s\nXXX\n' "$start_pct" "$label" "$last" >&3 || true
        sleep 1
    done
    wait "$pid" || rc=$?
    cat "$stage_log" >> "$LOG"
    if (( rc == 0 )); then
        printf 'XXX\n%s\n%s complete\nXXX\n' "$end_pct" "$label" >&3 || true
    else
        printf 'XXX\n%s\nFAILED: %s. See %s\nXXX\n' "$start_pct" "$label" "$LOG" >&3 || true
    fi
    exec 3>&-
    wait "$gauge_pid" 2>/dev/null || true
    rm -rf "$stage_dir"
    return "$rc"
}

install_base() {
    info "Installing the base system (log: $LOG)..."
    pacstrap -K /mnt "${BASE_PKGS[@]}"
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

install_software_helper() {
    install -Dm755 /dev/stdin /mnt/usr/local/bin/archbd-software <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || exec sudo "$0" "$@"
usage() {
    cat <<'USAGE'
Usage: archbd-software [--save] GROUP... | custom PACKAGE...
Groups: everyday developer sysadmin creative security
Examples:
  sudo archbd-software everyday developer
  sudo archbd-software security
  sudo archbd-software custom ripgrep fd bat
The tool uses official enabled pacman repositories and performs a full system
upgrade together with package installation. It does not install AUR packages.
USAGE
}
save=y
profile_custom=""
if [[ ${1:-} == --profile ]]; then
    [[ -r /etc/archbd/software-profile.conf ]] || { echo "No saved profile at /etc/archbd/software-profile.conf" >&2; exit 1; }
    # shellcheck source=/etc/archbd/software-profile.conf
    source /etc/archbd/software-profile.conf
    profile_groups=${APP_CATEGORIES:-}
    if [[ ${SECURITY_PROFILE:-n} == y && " $profile_groups " != *" security "* ]]; then profile_groups+=" security"; fi
    read -r -a profile_group_array <<< "$profile_groups"
    set -- "${profile_group_array[@]}"
    profile_custom=${CUSTOM_PACKAGES:-}
fi
[[ $# -gt 0 || -n $profile_custom ]] || { usage; exit 2; }
if [[ ${1:-} == --no-save ]]; then save=n; shift; fi
mode=groups
if [[ ${1:-} == custom ]]; then mode=custom; shift; fi
packages=()
groups=()
for arg in "$@"; do
    if [[ $mode == custom ]]; then
        [[ $arg =~ ^[A-Za-z0-9@._+-]+$ ]] || { echo "Invalid package name: $arg" >&2; exit 2; }
        packages+=("$arg")
        continue
    fi
    groups+=("$arg")
    case $arg in
        everyday)  packages+=(firefox vlc libreoffice-fresh gimp gparted htop zsh zsh-syntax-highlighting rsync unzip 7zip unrar) ;;
        developer) packages+=(git-lfs python python-pip python-virtualenv go rust docker docker-compose) ;;
        sysadmin)  packages+=(btop fastfetch lsof strace tcpdump nmap traceroute bind iperf3 smartmontools testdisk) ;;
        creative)  packages+=(krita inkscape audacity obs-studio kdenlive darktable) ;;
        security)  packages+=(wireshark-qt aircrack-ng john hashcat hydra sqlmap nikto yara clamav) ;;
        *) echo "Unknown group: $arg" >&2; usage; exit 2 ;;
    esac
done
if [[ -n $profile_custom ]]; then
    read -r -a profile_custom_array <<< "$profile_custom"
    packages+=("${profile_custom_array[@]}")
fi
if (( ${#packages[@]} == 0 )); then echo "No packages selected."; exit 0; fi
mapfile -t packages < <(printf '%s\n' "${packages[@]}" | awk '!seen[$0]++')
missing=()
for pkg in "${packages[@]}"; do
    [[ $pkg =~ ^[A-Za-z0-9@._+-]+$ ]] || { echo "Invalid package name: $pkg" >&2; exit 2; }
    pacman -Si "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
done
if (( ${#missing[@]} )); then
    printf 'Unavailable package(s): %s\n' "${missing[*]}" >&2
    echo "Check repository availability; nothing was installed." >&2
    exit 1
fi
pacman -Syu --needed "${packages[@]}"
if [[ $save == y ]]; then
    install -d -m 755 /etc/archbd
    if [[ $mode == custom ]]; then
        saved_groups=""
        saved_custom="${packages[*]}"
        saved_security=n
    else
        saved_groups="${groups[*]}"
        saved_custom="${profile_custom:-}"
        saved_security=n
        [[ " ${groups[*]} " == *" security "* ]] && saved_security=y
    fi
    {
        printf 'APP_CATEGORIES=%q\n' "$saved_groups"
        printf 'SECURITY_PROFILE=%q\n' "$saved_security"
        printf 'CUSTOM_PACKAGES=%q\n' "$saved_custom"
    } > /etc/archbd/software-profile.conf
    chmod 644 /etc/archbd/software-profile.conf
    echo "Saved profile to /etc/archbd/software-profile.conf. Reapply it with: sudo archbd-software --profile"
fi
HELPER
}

configure_system() {
    info "Configuring the new system..."
    printf '%s\n' "${EXTRA_PKGS[@]}" | awk '!seen[$0]++' > /mnt/root/extra-pkgs.txt
    printf '%s\n' "${SERVICES[@]}" | awk '!seen[$0]++' > /mnt/root/services.txt
    if [[ $FS_TYPE == btrfs ]]; then install_snapper_helper; fi
    install_software_helper
    install -d -m 755 /mnt/etc/archbd
    {
        printf 'APP_CATEGORIES=%q\n' "${APP_CATEGORIES:-}"
        printf 'SECURITY_PROFILE=%q\n' "${SECURITY_PROFILE:-n}"
        printf 'CUSTOM_PACKAGES=%q\n' "${CUSTOM_PACKAGES:-}"
    } > /mnt/etc/archbd/software-profile.conf
    chmod 644 /mnt/etc/archbd/software-profile.conf

    {
        echo '#!/usr/bin/env bash'
        echo 'set -euo pipefail'
        printf 'HOST_NAME=%q\nUSERNAME_=%q\nTIMEZONE=%q\nLOCALE=%q\nKEYMAP=%q\n' \
            "$HOST_NAME" "$USERNAME_" "$TIMEZONE" "$LOCALE" "$KEYMAP"
        printf 'BOOT_MODE=%q\nTARGET_DISK=%q\nENABLE_OSPROBER=%q\nENABLE_ZRAM=%q\n' \
            "$BOOT_MODE" "$TARGET_DISK" "$ENABLE_OSPROBER" "$ENABLE_ZRAM"
        printf 'ENCRYPT_ROOT=%q\nENCRYPTED_ROOT_UUID=%q\n' "${ENCRYPT_ROOT:-n}" "${ENCRYPTED_ROOT_UUID:-}"
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
pacman -Syu --noconfirm

# --- keep the installed system's mirrors fresh (reflector.timer)
mkdir -p /etc/xdg/reflector
{
    printf '%s\n' --save /etc/pacman.d/mirrorlist --protocol https --age 24 --completion-percentage 90 --number 10 --sort score
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

# --- encrypted root boot configuration
if [[ $ENCRYPT_ROOT == y ]]; then
    # Use systemd-based initramfs unlocking. ESP is mounted at /boot so the
    # kernel/initramfs remain readable before the encrypted root is opened.
    sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
    sed -i 's|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX="rd.luks.name='"$ENCRYPTED_ROOT_UUID"'=cryptroot root=/dev/mapper/cryptroot"|' /etc/default/grub
    mkinitcpio -P
fi

# --- bootloader
if [[ $BOOT_MODE == uefi ]]; then
    if [[ $ENCRYPT_ROOT == y ]]; then
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Arch --recheck
    else
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch --recheck
    fi
    if [[ $VIRT != none ]]; then
        # VMs often lose NVRAM boot entries; also install the fallback path EFI/BOOT/BOOTX64.EFI
        if [[ $ENCRYPT_ROOT == y ]]; then
            grub-install --target=x86_64-efi --efi-directory=/boot --removable --recheck
        else
            grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --recheck
        fi
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


set_passwords() {
    info "Setting passwords..."
    printf 'root:%s\n%s:%s\n' "$ROOT_PASSWORD" "$USERNAME_" "$USER_PASSWORD" | arch-chroot /mnt chpasswd
    unset ROOT_PASSWORD USER_PASSWORD
    ok "Passwords set."
}

finish() {
    cp "$LOG" /mnt/var/log/archbd-install.log 2>/dev/null || true
    info "Unmounting..."
    swapoff -a || true
    umount -R /mnt
    local mins=$((SECONDS / 60)) secs=$((SECONDS % 60)) tip="" choice
    if [[ $FS_TYPE == btrfs ]]; then
        tip="\n\nTip: after the first boot run  sudo archbd-setup-snapper  to turn on snapshots."
    fi
    ok "All done in ${mins}m ${secs}s. Remove the USB/DVD before booting."
    if [[ -n $tip ]]; then echo "${tip//\\n/$'\n'}"; fi

    if [[ -v REBOOT ]]; then
        if [[ $REBOOT == y ]]; then reboot; fi
        return 0
    fi
    if [[ $USE_DIALOG == y ]]; then
        DLG_TITLE="Installation complete"
        while true; do
            MENU_BACK=y
            if ! dlg_menu choice "Arch Linux is installed (took ${mins}m ${secs}s).\n\nRemove the USB/DVD before booting.$tip" "reboot" \
                    reboot "Reboot now" log "Read the install log" shell "Stay in the live system"; then
                choice=shell
            fi
            MENU_BACK=n
            case $choice in
                reboot) clear; reboot; return 0 ;;
                log)    view_log ;;
                shell)  clear; echo "Staying in the live system. Type 'reboot' when you are ready."; return 0 ;;
            esac
        done
    else
        get_yn REBOOT "Reboot now?" y
        if [[ $REBOOT == y ]]; then reboot; fi
    fi
}

# ------------------------------------------------------------------- main ---
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
    info "ARCHBD INSTALL START - $(date '+%F %T')  (log: $LOG)"
    progress_step 5 15 "Selecting mirrors and refreshing package keys" mirrors_and_keyring
    validate_package_catalog
    apply_layout
    progress_step 20 50 "Installing base system and kernel" install_base
    progress_step 55 84 "Configuring desktop, bootloader and services" configure_system
    progress_step 90 96 "Setting account passwords" set_passwords
    finish
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
    main "$@"
fi
