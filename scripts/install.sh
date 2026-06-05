#!/usr/bin/env bash
# shellcheck disable=SC2154
#|--/ /+--------------------------+--/ /|#
#|-/ /-| Main installation script |-/ /-|#
#|/ /--+--------------------------+/ /--|#

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
SRC_DIR="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${SRC_DIR}/global_fn.sh"; then
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
cp "${STARTER_SRC_DIR}/pkg_core.lst" "${STARTER_SRC_DIR}/install_pkg.lst"
trap 'mv "${STARTER_SRC_DIR}/install_pkg.lst" "${STARTER_CACHE_DIR}/logs/${DATE_LOG}/install_pkg.lst"' EXIT

echo -e "\n#user packages" >>"${STARTER_SRC_DIR}/install_pkg.lst" # Add a marker for user packages
if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
  cat "${custom_pkg}" >>"${STARTER_SRC_DIR}/install_pkg.lst"
fi

#--------------------------------#
# add nvidia drivers to the list #
#--------------------------------#
if nvidia_detect; then
  nvidia_detect --drivers | sort -u >> "${STARTER_SRC_DIR}/install_pkg.lst"
fi
nvidia_detect --verbose

#----------------#
# get user prefs #
#----------------#
echo ""
if ! chk_list "aurhlpr" "${STARTER_AUR_LIST[@]}"; then
  print_log -c "\nAUR Helpers :: "
  STARTER_AUR_LIST+=("paru-bin") # Add this here instead of in global_fn.sh
  for i in "${!STARTER_AUR_LIST[@]}"; do
    print_log -sec "$((i + 1))" " ${STARTER_AUR_LIST[$i]} "
  done

  prompt_timer 120 "Enter option number [default: paru-bin] | q to quit "

  case "${PROMPT_INPUT}" in
  1) export STARTER_GET_AUR="paru" ;;
  2) export STARTER_GET_AUR="paru-bin" ;;
  q)
    print_log -sec "AUR" -crit "Quit" "Exiting..."
    exit 1
    ;;
  *)
    print_log -sec "AUR" -warn "Defaulting to paru-bin"
    print_log -sec "AUR" -stat "default" "paru-bin"
    export STARTER_GET_AUR="paru-bin"
    ;;
  esac
  if [[ -z "$STARTER_GET_AUR" ]]; then
    print_log -sec "AUR" -crit "No AUR helper found..." "Log file at ${STARTER_CACHE_DIR}/logs/${DATE_LOG}"
    exit 1
  fi
fi

if ! grep -q "^#user packages" "${STARTER_SRC_DIR}/install_pkg.lst"; then
  print_log -sec "pkg" -crit "No user packages found..." "Log file at ${STARTER_CACHE_DIR}/logs/${DATE_LOG}/install.sh"
  exit 1
fi

#--------------------------------#
# install packages from the list #
#--------------------------------#
"${STARTER_SRC_DIR}/install_pkg.sh" "${STARTER_SRC_DIR}/install_pkg.lst"
if nvidia_detect; then
  "${STARTER_SRC_DIR}/extra/update_mod.sh"
fi

#---------------------------#
# resources custom configs  #
#---------------------------#
cat <<"EOF"

 ___ ___ ___ ___ _ _ ___ ___ ___ ___ 
|  _| -_|_ -| . | | |  _|  _| -_|_ -|
|_| |___|___|___|___|_| |___|___|___|


EOF

"${STARTER_SRC_DIR}/install_rsr.sh"
print_log -g "[generate] " "cache ::" "Wallpapers..."
# TODO: load wallpapers
# git clone --recurse-submodules <repo-url>

#---------------------#
# post-install script #
#---------------------#
cat <<"EOF"
             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

"${STARTER_SRC_DIR}/install_pst.sh"

#----------------#
# run commands   #
#----------------#
for file in "$STARTER_CLONE_DIR"/runs/*; do
  [ -f "$file" ] && [ -x "$file" ] && "$file"
done

#------------------------#
# enable system services #
#------------------------#
cat <<"EOF"
                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

"${STARTER_SRC_DIR}/extra/restore_svc.sh"

echo ""
print_log -g "Installation" " :: " "COMPLETED!"
print_log -b "Log" " :: " -y "View logs at ${STARTER_CACHE_DIR}/logs/${DATE_LOG}"
print_log -stat "Starter" "Do you want to reboot the system? (y/N)"
read -r answer

if [[ "$answer" == [Yy] ]]; then
  echo "Rebooting system"
  systemctl reboot
else
  echo "The system will not reboot"
fi
