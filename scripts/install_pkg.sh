#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091
#|---/ /+----------------------------------------+---/ /|#
#|--/ /-| Script to install pkgs from input list |--/ /-|#
#|-/ /--| 0xFilosoF                              |-/ /--|#
#|/ /---+----------------------------------------+/ /---|#

SRC_DIR=$(dirname "$(realpath "$0")")
if ! source "${SRC_DIR}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

export log_section="package"

"${STARTER_SRC_DIR}/install_aur.sh" "${STARTER_GET_AUR}" 2>&1
chk_list "aurhlpr" "${STARTER_AUR_LIST[@]}"
LIST_PKG="${1:-"${STARTER_SRC_DIR}/pkg_core.lst"}"
ARCH_PKG=()
AUR_PKG=()
OFS=$IFS
IFS='|'

#-----------------------------#
# remove blacklisted packages #
#-----------------------------#
if [ -f "${STARTER_SRC_DIR}/pkg_black.lst" ]; then
    grep -v -f <(grep -v '^#' "${STARTER_SRC_DIR}/pkg_black.lst" | sed 's/#.*//;s/ //g;/^$/d') <(sed 's/#.*//' "${STARTER_SRC_DIR}/install_pkg.lst") > "${STARTER_SRC_DIR}/install_pkg_filtered.lst"
    mv "${STARTER_SRC_DIR}/install_pkg_filtered.lst" "${STARTER_SRC_DIR}/install_pkg.lst"
fi

while read -r pkg deps; do
    pkg="${pkg// /}"
    if [ -z "${pkg}" ]; then
        continue
    fi

    if [ -n "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            pass=$(cut -d '#' -f 1 "${LIST_PKG}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi

    if pkg_installed "${pkg}"; then
        print_log -y "[skip] " "${pkg}"
    elif pkg_available "${pkg}"; then
        repo=$(pacman -Si "${pkg}" | awk -F ': ' '/Repository / {print $2}' | tr '\n' ' ')
        print_log -b "[queue] " "${pkg}" -b " :: " -g "${repo}"
        ARCH_PKG+=("${pkg}")
    elif aur_available "${pkg}"; then
        print_log -b "[queue] " "${pkg}" -b " :: " -g "aur"
        AUR_PKG+=("${pkg}")
    else
        print_log -r "[error] " "unknown package ${pkg}..."
    fi
done < <(cut -d '#' -f 1 "${LIST_PKG}")

IFS=${OFS}

install_packages() {
    local -n pkg_array=$1
    local pkg_type=$2
    local install_cmd=$3

    if [[ ${#pkg_array[@]} -gt 0 ]]; then
        print_log -b "[install] " "$pkg_type packages..."
        $install_cmd --noconfirm -S "${pkg_array[@]}"
    fi
}

echo ""
install_packages ARCH_PKG "arch" "sudo pacman"
echo ""
install_packages AUR_PKG "aur" "${aurhlpr}"
