# ShaderDeck

![Version](https://img.shields.io/badge/Version-1.0.2-green) ![Update](https://img.shields.io/badge/Update-2024.04.05-blue) ![Compatibility](https://img.shields.io/badge/Compatible-Steam_Deck-orange) ![GitHub all releases](https://img.shields.io/github/downloads/pepsizerosugar/ShaderDeck/total?color=purple)

* ShaderDeck manage the shader cache on your Steam Deck, enhancing your gaming experience by optimizing storage space and performance.

## Features

- **Clear Shader Cache**: Free up storage by removing unnecessary shader cache files.
- **Move Shader Cache**: Easily move shader caches between internal storage and SD card.

## 0. Change Log

### 1.0.2 (2024.04.05)

- [pepsi-011] fix: log file location, shell script rules
- [pepsi-012] fix: function name
- [pepsi-013] fix: default value of message
- [pepsi-015] fix: get_shader_sizes call order

## 1. Getting Started

### 1-1. Installation

1. Prepare your Steam Deck.
2. Switch to the desktop mode.
3. Open the web browser and download the latest version of ShaderDeck from
   the [release page](https://github.com/pepsizerosugar/ShaderDeck/releases) that file format is `ShaderDeck.sh`.

### 1-2. How to Use at Desktop Mode

1. Open the file manager and navigate to the download folder.
2. Do the following steps in the file manager.
    1. Right-click(R2) on the downloaded file(witch is `ShaderDeck.sh`) and select `Properties`.
    2. Go to the `Permissions` tab and check the `Is executable` option.
    3. And click the 'OK' button at the bottom of the window.
3. Double-click(Touch or R2) on the file(witch is `ShaderDeck.sh`) to run it.
4. Follow the instructions in the window to complete the management.

### 1-3. How to Use at Gaming Mode

1. Open the file manager and navigate to the download folder.
2. Do the following steps in the file manager.
    1. Right-click(R2) on the downloaded file(witch is `ShaderDeck.sh`) and select `Properties`.
    2. Select `Add to Steam` option.
3. Return to the gaming mode.
4. Press STEAM button on the left side of the device.
5. Select `Library` from the menu.
6. Select `NON-STEAM` tab from the library.
7. Select `ShaderDeck.sh` from the list.
8. Press the `A` button to run it.

## 2. Extra

### 2-1. Reference

* Zenity Documentation: https://help.gnome.org/users/zenity/
* Bash Scripting Guide: https://www.gnu.org/software/bash/manual/
