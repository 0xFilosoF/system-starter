#!/usr/bin/env bash
#|--/ /+--------------------------------------+--/ /|#
#|-/ /-| Script to apply post install configs |-/ /-|#
#|/ /--+--------------------------------------+/ /--|#

SRC_DIR=$(dirname "$(realpath "$0")")
if ! source "${SRC_DIR}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

CLONE_DIR="${CLONE_DIR:-$STARTER_CLONE_DIR}"

# sddm
if pkg_installed sddm; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi

    if [ ! -f /etc/sddm.conf.d/starter.conf.bkp ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring sddm..."
        print_log -g "[DISPLAYMANAGER] " -b " :: " "Select sddm theme:" -r "\n[1]" -b " Qylock" -r "\n[2]" -b " Astronaut"
        read -p " :: Enter option number : " -r sddmopt

        case $sddmopt in
        1) sddmtheme="Qylock" ;;
        *) sddmtheme="Astronaut" ;;
        esac

        sudo tar -xzf "${CLONE_DIR}/Source/arcs/Sddm_${sddmtheme}.tar.gz" -C "$HOME/Projects"
        "$HOME/Projects/${sddmtheme,,}/init.sh"
        sudo touch /etc/sddm.conf.d/starter.conf.bkp

        print_log -g "[DISPLAYMANAGER] " -b " :: " "sddm configured with ${sddmtheme} theme..."
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is already configured..."
    fi
else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is not installed..."
fi

# dolphin
if pkg_installed dolphin && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

else
    print_log -y "[FILEMANAGER]" -b " :: " "dolphin is not installed..."
    print_log -y "[FILEMANAGER]" -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
fi

if ! pkg_installed flatpak; then
    echo ""
    print_log -g "[FLATPAK]" -b " list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${STARTER_SRC_DIR}/extra/custom_flat.lst"
    print_log -g "[FLATPAK]" -b " install :: " "flatpaks"
    "${STARTER_SRC_DIR}/extra/install_fpk.sh"
else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is already installed"
fi
