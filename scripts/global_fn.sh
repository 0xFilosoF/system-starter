#!/usr/bin/env bash
#|---/ /+------------------+---/ /|#
#|--/ /-| Global functions |--/ /-|#
#|-/ /--| 0xFilosoF        |-/ /--|#
#|/ /---+------------------+/ /---|#

set -e

STARTER_SRC_DIR="$(dirname "$(realpath "$0")")"
STARTER_CLONE_DIR="$(dirname "${STARTER_SRC_DIR}")" # fallback, we will use CLONE_DIR now
STARTER_CLONE_DIR="${CLONE_DIR:-${STARTER_CLONE_DIR}}"
STARTER_CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STARTER_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/system-starter"
STARTER_PACMAN_CMD=${STARTER_CLONE_DIR}/utils/pm.sh
STARTER_AUR_LIST=("paru")

export STARTER_CLONE_DIR
export STARTER_CFG_DIR
export STARTER_CACHE_DIR
export STARTER_AUR_LIST

pkg_installed() {
    local pkg_in=$1

    if pacman -Q "${pkg_in}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

chk_list() {
    vr_type="$1"
    local in_list=("${@:2}")
    for pkg in "${in_list[@]}"; do
        if pkg_installed "${pkg}"; then
            printf -v "${vr_type}" "%s" "${pkg}"
            # shellcheck disable=SC2163 # dynamic variable
            export "${vr_type}" # export the variable // reference of the variable
            return 0
        fi
    done
    # print_log -sec "install" -warn "no package found in the list..." "${inList[@]}"
    return 1
}

pkg_available() {
    local pkg_in=$1

    if ${STARTER_PACMAN_CMD} query "${pkg_in}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

aur_available() {
    local pkg_in=$1

    # shellcheck disable=SC2154
    if ${STARTER_PACMAN_CMD} info "${pkg_in}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

nvidia_detect() {
    local -a dGPU
    readarray -t dGPU < <(
        lspci -k | grep -E "(VGA|3D)" | awk -F ': ' '{print $NF}'
    )

    case "$1" in
        --verbose)
            for indx in "${!dGPU[@]}"; do
                echo -e "\033[0;32m[gpu$indx]\033[0m detected :: ${dGPU[indx]}"
            done
            return 0
            ;;

        --drivers)
            if ! printf '%s\n' "${dGPU[@]}" | grep -qi nvidia; then
                return 1
            fi

            while read -r kernel; do
                printf '%s\n' "${kernel}-headers"
            done < <(cat /usr/lib/modules/*/pkgbase 2>/dev/null | sort -u)

            printf '%s\n' \
                "nvidia-open-dkms" \
                "nvidia-utils" \
                "lib32-nvidia-utils"

            return 0
            ;;
    esac

    if printf '%s\n' "${dGPU[@]}" | grep -qi nvidia; then
        return 0
    else
        return 1
    fi
}

prompt_timer() {
    set +e
    unset PROMPT_INPUT
    local timsec=$1
    local msg=$2
    while [[ ${timsec} -ge 0 ]]; do
        echo -ne "\r :: ${msg} (${timsec}s) : "
        read -rt 1 -n 1 PROMPT_INPUT && break
        ((timsec--))
    done
    export PROMPT_INPUT
    echo ""
    set -e
}

print_log() {
    local executable="${0##*/}"
    local log_file="${STARTER_CACHE_DIR}/logs/${DATE_LOG}/${executable}.log"
    mkdir -p "$(dirname "${log_file}")"
    local section=${log_section:-}
    {
        [ -n "${section}" ] && echo -ne "\e[32m[$section] \e[0m"
        while (("$#")); do
            case "$1" in
            -r | +r)
                echo -ne "\e[31m$2\e[0m"
                shift 2
                ;; # Red
            -g | +g)
                echo -ne "\e[32m$2\e[0m"
                shift 2
                ;; # Green
            -y | +y)
                echo -ne "\e[33m$2\e[0m"
                shift 2
                ;; # Yellow
            -b | +b)
                echo -ne "\e[34m$2\e[0m"
                shift 2
                ;; # Blue
            -m | +m)
                echo -ne "\e[35m$2\e[0m"
                shift 2
                ;; # Magenta
            -c | +c)
                echo -ne "\e[36m$2\e[0m"
                shift 2
                ;; # Cyan
            -wt | +w)
                echo -ne "\e[37m$2\e[0m"
                shift 2
                ;; # White
            -n | +n)
                echo -ne "\e[96m$2\e[0m"
                shift 2
                ;; # Neon
            -stat)
                echo -ne "\e[30;46m $2 \e[0m :: "
                shift 2
                ;; # status
            -crit)
                echo -ne "\e[97;41m $2 \e[0m :: "
                shift 2
                ;; # critical
            -warn)
                echo -ne "WARNING :: \e[30;43m $2 \e[0m :: "
                shift 2
                ;; # warning
            +)
                echo -ne "\e[38;5;$2m$3\e[0m"
                shift 3
                ;; # Set color manually
            -sec)
                echo -ne "\e[32m[$2] \e[0m"
                shift 2
                ;; # section use for logs
            -err)
                echo -ne "ERROR :: \e[4;31m$2 \e[0m"
                shift 2
                ;; #error
            *)
                echo -ne "$1"
                shift
                ;;
            esac
        done
        echo ""
    } | if [ -n "${DATE_LOG}" ]; then
        tee >(sed 's/\x1b\[[0-9;]*m//g' >>"${log_file}")
    else
        cat
    fi
}
