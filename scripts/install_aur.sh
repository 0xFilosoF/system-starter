#!/usr/bin/env bash
#|--/ /+-------------------------------------------+--/ /|#
#|-/ /-| Script to install aur helper, yay or paru |-/ /-|#
#|/ /--+-------------------------------------------+/ /--|#

SRC_DIR=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${SRC_DIR}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# shellcheck disable=SC2154
if chk_list "aurhlpr" "${STARTER_AUR_LIST[@]}"; then
    print_log -sec "AUR" -stat "Detected" "${aurhlpr}"
    exit 0
fi

aurhlpr="${1:-paru-bin}"

if [ -d "$HOME/Projects" ]; then
    print_log -sec "AUR" -stat "exist" "$HOME/Projects directory..."
    rm -rf "$HOME/Projects/${aurhlpr}"
else
    mkdir "$HOME/Projects"
    echo -e "[Desktop Entry]\nIcon=default-folder-git" >"$HOME/Projects/.directory"
    print_log -sec "AUR" -stat "created" "$HOME/Projects directory..."
fi

if pkg_installed git; then
    git clone "https://aur.archlinux.org/${aurhlpr}.git" "$HOME/Projects/${aurhlpr}"
else
    print_log -sec "AUR" -stat "missing" "'git' as dependency..."
    exit 1
fi

cd "$HOME/Projects/${aurhlpr}" || exit
# shellcheck disable=SC2154
if makepkg -si; then
    print_log -sec "AUR" -stat "installed" "${aurhlpr} aur helper..."
    exit 0
else
    print_log -r "AUR" -stat "failed" "${aurhlpr} installation failed..."
    echo "${aurhlpr} installation failed..."
    exit 1
fi
