#!/bin/bash

set -o pipefail

LOG_FILE="$HOME/shader_cache_management.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

show_and_log_message() {
    local type="$1"
    local title="$2"
    local message="$3"

    log_message "$title - $message"
    zenity --"$type" --title="$title" --text="$message" --width=300
}

getShaderSize() {
    local path="$1"
    if [ ! -d "$path" ]; then
        log_message "Path not found: $path"
        echo "0B"
        return 1
    fi
    shopt -s lastpipe
    size=$(du -sh "$path" 2>/dev/null | grep -E -o ".*[GMK]") || echo "0B"
    echo "$size"
}

removeShaderCache() {
    local path="$1"
    local storageType="$2"
    if [ ! -d "$path" ]; then
        show_and_log_message error "Shader cache does not exist" "Shader cache does not exist on $storageType storage."
        return 1
    fi
    log_message "Removing shader cache from $storageType storage."
    (
        echo "0"
        if ! rm -rf "$path" 2>/dev/null; then
            show_and_log_message error "Failed to remove shader cache" "Failed to remove shader cache from $storageType storage."
            return 1
        else
            echo "100"
        fi
    ) |
    zenity --progress --title="Removing Shader Cache" --text="Removing shader cache from $storageType storage..." --percentage=0 --auto-close --width=300

    if [ "$?" = -1 ]; then
        show_and_log_message error "Shader cache removal cancelled" "Shader cache removal cancelled."
    else
        show_and_log_message info "Success" "Shader cache successfully removed from $storageType storage."
    fi
}


moveShaderCache() {
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


SDCARD=""
if [ -b "/dev/mmcblk0p1" ]; then
    SDCARD=$(findmnt -n --raw --evaluate --output=target -S /dev/mmcblk0p1 || echo "")
    if [ -z "$SDCARD" ]; then
        show_and_log_message error "SD Card not mounted" "SD Card is not mounted."
        exit 1
    fi
    SDCARD_SHADER_SIZE=$(getShaderSize "${SDCARD}/steamapps/shadercache")
    if [ "$SDCARD_SHADER_SIZE" = "Path not found: ${SDCARD}/steamapps/shadercache" ]; then
        show_and_log_message error "Shader cache does not exist" "Shader cache does not exist on SD card."
        exit 1
    fi
fi

INTERNAL_SHADER_SIZE=$(getShaderSize "$HOME/.steam/steam/steamapps/shadercache")

log_message "Presenting options to the user"
if [ -n "$SDCARD" ]; then
    options=(
        "Remove ${INTERNAL_SHADER_SIZE:=0B} of shader cache from internal storage."
        "Remove ${SDCARD_SHADER_SIZE:=0B} of shader cache from SD card."
        "Move ${INTERNAL_SHADER_SIZE:=0B} of shader cache from internal storage to SD card."
        "Quit"
    )
else
    options=(
        "Remove ${INTERNAL_SHADER_SIZE:=0B} of shader cache from internal storage."
        "SD Card Not Found"
        "Quit"
    )
fi

while opt=$(zenity --width=500 --height=250 --title="Steam Deck Shader Cache Management" --list --column="Options" "${options[@]}"); do
    case "$opt" in
        "${options[0]}" )
            removeShaderCache "$HOME/.steam/steam/steamapps/shadercache" "internal"
            ;;
        "${options[1]}" )
            if [ -n "$SDCARD" ]; then
                removeShaderCache "${SDCARD}/steamapps/shadercache" "SD card"
            else
                show_and_log_message error "SD Card not found" "SD Card not found for removing shader cache."
            fi
            ;;
        "${options[2]}" )
            if [ -n "$SDCARD" ]; then
                moveShaderCache "$HOME/.steam/steam/steamapps/shadercache" "${SDCARD}/steamapps"
            else
                show_and_log_message error "SD Card not found" "SD Card not found for moving shader cache."
            fi
            ;;
        "Quit" )
            break
            ;;
        * )
            show_and_log_message error "Invalid option" "Invalid option selected."
            ;;
    esac
done
