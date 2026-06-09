#!/usr/bin/env bash
# shellcheck disable=SC2154
#|--/ /+------------------------------------------------+--/ /|#
#|-/ /-| Script to extract resources (fonts and themes) |-/ /-|#
#|/ /--+------------------------------------------------+/ /--|#

SRC_DIR=$(dirname "$(realpath "$0")")
export log_section="extract"
# shellcheck disable=SC1091
if ! source "${SRC_DIR}/global_fn.sh"; then
    echo -e "\e[31mError: unable to source global_fn.sh...\e[0m"
    exit 1
fi

# fonts & icons
while read -r lst; do
    # Skip lines starting with #
    if [[ "$lst" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    # Check if the line has the correct number of fields
    if [ "$(echo "$lst" | awk -F '|' '{print NF}')" -ne 2 ]; then
        continue
    fi

    fnt=$(awk -F '|' '{print $1}' <<<"$lst")
    tgt=$(awk -F '|' '{print $2}' <<<"$lst")
    tgt=$(eval "echo $tgt")

    if [ ! -d "${tgt}" ]; then
        if ! mkdir -p "${tgt}"; then
            print_log -warn "create" "directory as root instead..."
            sudo mkdir -p "${tgt}"
        fi

    fi

    if [ -w "${tgt}" ]; then
        # shellcheck disable=SC2154
        tar -xzf "${STARTER_CLONE_DIR}/resources/arcs/${fnt}.tar.gz" -C "${tgt}/"
    else
        print_log -warn "not writable" "Extracting as root: ${tgt} "
        if ! sudo tar -xzf "${STARTER_CLONE_DIR}/resources/arcs/${fnt}.tar.gz" -C "${tgt}/" 2>/dev/null; then
            print_log -err "extraction by root FAILED" " giving up..."
            print_log "The above error can be ignored if the '${tgt}' is not writable..."
        fi
    fi
    print_log "${fnt}.tar.gz" -r " --> " "${tgt}... "

done <"${STARTER_SRC_DIR}/store_fnt.lst"
echo ""
print_log -stat "rebuild" "font cache"
fc-cache -f

# dotfiles
if ! pkg_installed 'stow'; then
    print_log -stat "install" "stow"
    sudo pacman -S --noconfirm --needed stow
fi

CLONE_DIR="${CLONE_DIR:-$STARTER_CLONE_DIR}"

print_log -g "[DOTFILES] " -b "extract :: " "dotfiles..."
rm -rf "${HOME}/dotfiles"
cp -r "${CLONE_DIR}/dotfiles" "${HOME}/dotfiles"
mkdir -p "${HOME}/.config"
cd "$HOME/dotfiles" || exit
stow .
