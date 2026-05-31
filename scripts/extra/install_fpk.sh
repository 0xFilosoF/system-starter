#!/usr/bin/env bash
#|--/ /+-----------------------------------+--/ /|#
#|-/ /-| Script to install flatpaks (user) |-/ /-|#
#|/ /--+-----------------------------------+/ /--|#

BASE_DIR=$(dirname "$(realpath "$0")")
SRC_DIR=$(dirname "$(dirname "$(realpath "$0")")")

source "${SRC_DIR}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

if ! pkg_installed flatpak; then
    sudo pacman -S flatpak
fi

flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flats=$(awk -F '#' '{print $1}' "${BASE_DIR}/custom_flat.lst" | sed 's/ //g' | xargs)

flatpak install --user -y flathub ${flats}
flatpak remove --unused

gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | sed "s/'//g")
gtk_icon=$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")

flatpak --user override --filesystem=~/.themes
flatpak --user override --filesystem=~/.icons

flatpak --user override --filesystem=~/.local/share/themes
flatpak --user override --filesystem=~/.local/share/icons

flatpak --user override --env=GTK_THEME=${gtk_theme}
flatpak --user override --env=ICON_THEME=${gtk_icon}
