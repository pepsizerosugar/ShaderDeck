#!/bin/bash

set -o pipefail

LOG_FILE_PATH="$(dirname "$0")/ShaderDeck.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE_PATH"
}

show_and_log_message() {
    local type=${1:-'info'}
    local title=${2:-'ShaderDeck'}
    local message=${3:-'ShaderDeck'}

    log_message "$title - $message"
    zenity --"$type" --title="$title" --text="$message" --width=300
}

get_storage_info() {
    local path="$1"
    local info
    info=$(df -h "$path" | awk 'NR>1 {print $2, $4}')
    echo "$info"
}

get_shader_size() {
    local path="$1"
    if [ ! -d "$path" ]; then
        log_message "Path not found: $path"
        echo "0B 0%"
        return 1
    fi
    shopt -s lastpipe
    local size
    size=$(du -sh "$path" 2>/dev/null | grep -E -o "^[0-9\.]*[KMG]?") || echo "0B"
    local storage_info
    IFS=' ' read -r -a storage_info <<< "$(get_storage_info "$path")"
    local total_size=${storage_info[0]}
    echo "$size $(echo "$size / $total_size" | bc -l | awk '{printf "%.2f%%", $1 * 100}')"
}


get_shader_sizes() {
    if [ -b "/dev/mmcblk0p1" ]; then
        sdcard=$(findmnt -n --raw --evaluate --output=target -S /dev/mmcblk0p1 || echo "")
        if [ -z "$sdcard" ]; then
            show_and_log_message error "SD Card not mounted" "SD Card is not mounted."
            exit 1
        fi
        sdcard_shader_size=$(get_shader_size "${sdcard}/steamapps/shadercache")
        if [[ "$sdcard_shader_size" =~ "Path not found" ]]; then
            show_and_log_message error "Shader cache does not exist" "Shader cache does not exist on SD card."
            exit 1
        fi
    fi
    internal_shader_size=$(get_shader_size "$HOME/.steam/steam/steamapps/shadercache")
}

remove_shader_cache() {
    local path="$1"
    local storage_type="$2"
    if [ ! -d "$path" ]; then
        show_and_log_message error "Shader cache does not exist" "Shader cache does not exist on $storage_type storage."
        return 1
    fi
    log_message "Removing shader cache from $storage_type storage."
    (
        echo "0"
        if ! rm -rf "$path" 2>/dev/null; then
            show_and_log_message error "Failed to remove shader cache" "Failed to remove shader cache from $storage_type storage."
            return 1
        else
            echo "100"
        fi
    ) |
    zenity --progress --title="Removing Shader Cache" --text="Removing shader cache from $storage_type storage..." --percentage=0 --auto-close --width=300

    if [ "$?" = -1 ]; then
        show_and_log_message error "Shader cache removal cancelled" "Shader cache removal cancelled."
    else
        show_and_log_message info "Success" "Shader cache successfully removed from $storage_type storage."
    fi
}

move_shader_cache() {
    local src="$1"
    local dest="$2"
    if [ ! -d "$src" ]; then
        show_and_log_message error "Shader cache does not exist" "Shader cache does not exist on internal storage."
        return 1
    fi
    log_message "Moving shader cache from internal storage to SD card."
    (
        echo "0"
        if ! mv "$src" "$dest" 2>/dev/null; then
            show_and_log_message error "Failed to move shader cache" "Failed to move shader cache to SD card."
            return 1
        else
            if ! ln -s "${dest}/shadercache" "$src" 2>/dev/null; then
                show_and_log_message error "Failed to create symbolic link" "Failed to create symbolic link for shader cache."
                return 1
            fi
            echo "100"
        fi
    ) |
    zenity --progress --title="Moving Shader Cache" --text="Moving shader cache to SD card..." --percentage=0 --auto-close --width=300

    if [ "$?" = -1 ]; then
        show_and_log_message error "Shader cache move cancelled" "Shader cache move cancelled."
    else
        show_and_log_message info "Success" "Shader cache successfully moved to SD card."
    fi
}

log_message "Presenting options to the user"
get_shader_sizes
SDCARD_INFO=()
read -r -a SDCARD_INFO <<< "$sdcard_shader_size"
INTERNAL_INFO=()
read -r -a INTERNAL_INFO <<< "$internal_shader_size"

if [ -n "$sdcard" ]; then
    options=(
        "Remove ${INTERNAL_INFO[0]:-0B} (occupying ${INTERNAL_INFO[1]:-0%}) of shader cache from internal storage."
        "Remove ${SDCARD_INFO[0]:-0B} (occupying ${SDCARD_INFO[1]:-0%}) of shader cache from SD card."
        "Move ${INTERNAL_INFO[0]:-0B} (occupying ${INTERNAL_INFO[1]:-0%}) of shader cache from internal storage to SD card."
        "Quit"
    )
else
    options=(
        "Remove ${INTERNAL_INFO[0]:-0B} (occupying ${INTERNAL_INFO[1]:-0%}) of shader cache from internal storage."
        "SD Card Not Found"
        "Quit"
    )
fi

while opt=$(zenity --width=500 --height=300 --title="ShaderDeck" --list --column="Options" "${options[@]}"); do
  get_shader_sizes
    case "$opt" in
        "Quit" )
            break
            ;;
        "${options[0]}" )
            remove_shader_cache "$HOME/.steam/steam/steamapps/shadercache" "internal"
            ;;
        "${options[1]}" )
            if [ -n "$sdcard" ]; then
                remove_shader_cache "${sdcard}/steamapps/shadercache" "SD card"
            else
                show_and_log_message error "SD Card not found" "SD Card not found for removing shader cache."
            fi
            ;;
        "${options[2]}" )
            if [ -n "$sdcard" ]; then
                move_shader_cache "$HOME/.steam/steam/steamapps/shadercache" "${sdcard}/steamapps"
            else
                show_and_log_message error "SD Card not found" "SD Card not found for moving shader cache."
            fi
            ;;
        * )
            show_and_log_message error "Invalid option" "Invalid option selected."
            ;;
    esac
done
