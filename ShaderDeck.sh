#!/bin/bash

set -o pipefail

SDCARD=""
SDCARD_SHADER_SIZE=""
INTERNAL_SHADER_SIZE=""
LOG_FILE="$HOME/shader_cache_management.log"

logMessage() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

showAndLogMessage() {
    local type="$1"
    local title="$2"
    local message="$3"

    logMessage "$title - $message"
    zenity --"$type" --title="$title" --text="$message" --width=300
}

getStorageInfo() {
    local path="$1"
    local info=$(df -h "$path" | awk 'NR>1 {print $2, $4}')
    echo $info
}

getShaderSize() {
    local path="$1"
    if [ ! -d "$path" ]; then
        logMessage "Path not found: $path"
        echo "0B 0%"
        return 1
    fi
    shopt -s lastpipe
    local size=$(du -sh "$path" 2>/dev/null | grep -E -o "^[0-9\.]*[KMG]?") || echo "0B"
    local storage_info=($(getStorageInfo "$path"))
    local total_size=${storage_info[0]}
    local available_size=${storage_info[1]}
    echo "$size $(echo "$size / $total_size" | bc -l | awk '{printf "%.2f%%", $1 * 100}')"
}

getShaderSizes() {
    if [ -b "/dev/mmcblk0p1" ]; then
        SDCARD=$(findmnt -n --raw --evaluate --output=target -S /dev/mmcblk0p1 || echo "")
        if [ -z "$SDCARD" ]; then
            showAndLogMessage error "SD Card not mounted" "SD Card is not mounted."
            exit 1
        fi
        SDCARD_SHADER_SIZE=$(getShaderSize "${SDCARD}/steamapps/shadercache")
        if [[ "$SDCARD_SHADER_SIZE" =~ "Path not found" ]]; then
            showAndLogMessage error "Shader cache does not exist" "Shader cache does not exist on SD card."
            exit 1
        fi
    fi
    INTERNAL_SHADER_SIZE=$(getShaderSize "$HOME/.steam/steam/steamapps/shadercache")
}

removeShaderCache() {
    local path="$1"
    local storageType="$2"
    if [ ! -d "$path" ]; then
        showAndLogMessage error "Shader cache does not exist" "Shader cache does not exist on $storageType storage."
        return 1
    fi
    logMessage "Removing shader cache from $storageType storage."
    (
        echo "0"
        if ! rm -rf "$path" 2>/dev/null; then
            showAndLogMessage error "Failed to remove shader cache" "Failed to remove shader cache from $storageType storage."
            return 1
        else
            echo "100"
        fi
    ) |
    zenity --progress --title="Removing Shader Cache" --text="Removing shader cache from $storageType storage..." --percentage=0 --auto-close --width=300

    if [ "$?" = -1 ]; then
        showAndLogMessage error "Shader cache removal cancelled" "Shader cache removal cancelled."
    else
        showAndLogMessage info "Success" "Shader cache successfully removed from $storageType storage."
    fi
}

moveShaderCache() {
    local src="$1"
    local dest="$2"
    if [ ! -d "$src" ]; then
        showAndLogMessage error "Shader cache does not exist" "Shader cache does not exist on internal storage."
        return 1
    fi
    logMessage "Moving shader cache from internal storage to SD card."
    (
        echo "0"
        if ! mv "$src" "$dest" 2>/dev/null; then
            showAndLogMessage error "Failed to move shader cache" "Failed to move shader cache to SD card."
            return 1
        else
            if ! ln -s "${dest}/shadercache" "$src" 2>/dev/null; then
                showAndLogMessage error "Failed to create symbolic link" "Failed to create symbolic link for shader cache."
                return 1
            fi
            echo "100"
        fi
    ) |
    zenity --progress --title="Moving Shader Cache" --text="Moving shader cache to SD card..." --percentage=0 --auto-close --width=300

    if [ "$?" = -1 ]; then
        showAndLogMessage error "Shader cache move cancelled" "Shader cache move cancelled."
    else
        showAndLogMessage info "Success" "Shader cache successfully moved to SD card."
    fi
}

logMessage "Presenting options to the user"
getShaderSizes
SDCARD_INFO=($SDCARD_SHADER_SIZE)
INTERNAL_INFO=($INTERNAL_SHADER_SIZE)

if [ -n "$SDCARD" ]; then
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
  getShaderSizes
    case "$opt" in
        "Quit" )
            break
            ;;
        "${options[0]}" )
            removeShaderCache "$HOME/.steam/steam/steamapps/shadercache" "internal"
            ;;
        "${options[1]}" )
            if [ -n "$SDCARD" ]; then
                removeShaderCache "${SDCARD}/steamapps/shadercache" "SD card"
            else
                showAndLogMessage error "SD Card not found" "SD Card not found for removing shader cache."
            fi
            ;;
        "${options[2]}" )
            if [ -n "$SDCARD" ]; then
                moveShaderCache "$HOME/.steam/steam/steamapps/shadercache" "${SDCARD}/steamapps"
            else
                showAndLogMessage error "SD Card not found" "SD Card not found for moving shader cache."
            fi
            ;;
        * )
            showAndLogMessage error "Invalid option" "Invalid option selected."
            ;;
    esac
done
