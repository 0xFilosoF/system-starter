#!/usr/bin/env bash
#|--/ /+-------------------------+--/ /|#
#|-/ /-| Service restore script  |-/ /-|#
#|/ /---+------------------------+/ /--|#

BASE_DIR=$(dirname "$(realpath "$0")")
SRC_DIR=$(dirname "$(dirname "$(realpath "$0")")")

source "${SRC_DIR}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

handle_service() {
    local service_chk="$1"
    
    if [[ $(systemctl list-units --all -t service --full --no-legend "${service_chk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${service_chk}.service" ]]; then
        print_log -y "[skip] " -b "active " "Service ${service_chk}"
    else
        print_log -y "enable " "Service ${service_chk}"
        sudo systemctl enable "${service_chk}.service"
    fi
}

# Main processing
print_log -sec "services" -stat "restore" "system services..."

while IFS='|' read -r service context command || [ -n "$service" ]; do
    # Skip empty lines and comments
    [[ -z "$service" || "$service" =~ ^[[:space:]]*# ]] && continue
    
    # Trim whitespace
    service=$(echo "$service" | xargs)
    handle_service "$service"
done < "${BASE_DIR}/custom_svc.lst"

print_log -sec "services" -stat "completed" "service updated successfully"
