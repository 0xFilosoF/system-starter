#!/usr/bin/env bash
# shellcheck disable=SC2154
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| 0xFilosoF                |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat <<"EOF"

-------------------
        .
       / \      
      /^  \    
     /  _  \  
    /  | | ~\
   /.-'   '-.\ 

--------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
STARTER_SRC_DIR="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${STARTER_SRC_DIR}/global_fn.sh"; then
	echo "Error: unable to source global_fn.sh..."
	exit 1
fi

DATE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"

if [[ ! -f /etc/arch-release ]]; then
  print_log -sec "system" -crit "Arch Linux required" "Log file at ${cacheDir}/logs/${DATE_LOG}"
  exit 1
fi

export DATE_LOG

#--------------------#
# pre-install script #
#--------------------#
cat <<"EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

"${STARTER_SRC_DIR}/install_pre.sh"

#------------#
# installing #
#------------#
cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

#----------------------#
# prepare package list #
#----------------------#
shift $((OPTIND - 1))
custom_pkg=$1
cp "${scrDir}/pkg_core.lst" "${scrDir}/install_pkg.lst"
trap 'mv "${STARTER_SRC_DIR}/install_pkg.lst" "${STARTER_CACHE_DIR}/logs/${DATE_LOG}/install_pkg.lst"' EXIT

echo -e "\n#user packages" >>"${STARTER_SRC_DIR}/install_pkg.lst" # Add a marker for user packages
if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
  cat "${custom_pkg}" >>"${STARTER_SRC_DIR}/install_pkg.lst"
fi

#--------------------------------#
# add nvidia drivers to the list #
#--------------------------------#
if nvidia_detect; then
  if [ ${flg_Nvidia} -eq 1 ]; then
    nvidia_detect --drivers | sort -u >> "${STARTER_SRC_DIR}/install_pkg.lst"
  else
    print_log -warn "Nvidia" "Nvidia GPU detected but ignored..."
  fi
fi
nvidia_detect --verbose

# TODO:
#----------------#
# get user prefs #
#----------------#
echo ""
if ! chk_list "aurhlpr" "${aurList[@]}"; then
  print_log -c "\nAUR Helpers :: "
  aurList+=("yay-bin" "paru-bin") # Add this here instead of in global_fn.sh
  for i in "${!aurList[@]}"; do
    print_log -sec "$((i + 1))" " ${aurList[$i]} "
  done

  prompt_timer 120 "Enter option number [default: yay-bin] | q to quit "

  case "${PROMPT_INPUT}" in
  1) export getAur="yay" ;;
  2) export getAur="paru" ;;
  3) export getAur="yay-bin" ;;
  4) export getAur="paru-bin" ;;
  q)
    print_log -sec "AUR" -crit "Quit" "Exiting..."
    exit 1
    ;;
  *)
    print_log -sec "AUR" -warn "Defaulting to yay-bin"
    print_log -sec "AUR" -stat "default" "yay-bin"
    export getAur="yay-bin"
    ;;
  esac
  if [[ -z "$getAur" ]]; then
    print_log -sec "AUR" -crit "No AUR helper found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
    exit 1
  fi
fi

if ! chk_list "myShell" "${shlList[@]}"; then
  print_log -c "Shell :: "
  for i in "${!shlList[@]}"; do
    print_log -sec "$((i + 1))" " ${shlList[$i]} "
  done
  prompt_timer 120 "Enter option number [default: zsh] | q to quit "

  case "${PROMPT_INPUT}" in
  1) export myShell="zsh" ;;
  2) export myShell="fish" ;;
  q)
    print_log -sec "shell" -crit "Quit" "Exiting..."
    exit 1
    ;;
  *)
    print_log -sec "shell" -warn "Defaulting to zsh"
    export myShell="zsh"
    ;;
  esac
  print_log -sec "shell" -stat "Added as shell" "${myShell}"
  echo "${myShell}" >>"${scrDir}/install_pkg.lst"

  if [[ -z "$myShell" ]]; then
    print_log -sec "shell" -crit "No shell found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
    exit 1
  else
    print_log -sec "shell" -stat "detected :: " "${myShell}"
  fi
fi

if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
  print_log -sec "pkg" -crit "No user packages found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}/install.sh"
  exit 1
fi

#--------------------------------#
# install packages from the list #
#--------------------------------#
"${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
