#!/bin/bash

# Get running containers
containers_id=($(pct list | tail -n +2 | sed '/running/!d' | cut -f1 -d ' '))
containers_name=($(pct list | tail -n +2 | sed '/running/!d' | tr -s ' ' | cut -f3 -d ' '))

num_snapshots=3

DEFAULT='\033[0m'

RED='\033[0;31m'
failed_updates=0

GREEN='\033[0;32m'
success_updates=0

# Tries to create a snapshot, abort on failure, print an error message and move to next LXC.
function create_snap() {
    saved_date=$(date +%s)
    echo "[info] Creating snapshot update-$saved_date"

    pct snapshot "$1" "upgrade-$saved_date" || return 1
    echo -e "${GREEN}Done.${DEFAULT}"
}

# Runs update on the LXC.
function update_ct() {
    echo "[info] Updating $2"

    pct exec "$1" -- bash -c "apt update && apt upgrade -y" || return 1
    echo -e "${GREEN}Done.${DEFAULT}"
}

function clear_snap() {
    echo "[info] Deleting old snapshots..."
    snapshots=($(pct listsnapshot "$1" | grep -o "upgrade-[[:digit:]]*" | sort -r))

    for ((snaps = ${#snapshots[@]}; snaps > num_snapshots; snaps--)); do
        echo "[info] Deleting ${snapshots[i - 1]}"
        pct delsnapshot "$1" "${snapshots[i - 1]}"
    done
    echo -e "${GREEN}Done!${DEFAULT}"
}

for ((i = 0; i < ${#containers_id[@]}; i++)); do
    container_id=${containers_id[i]}
    container_name=${containers_name[i]}

    #Check exit-code of create_snap
    if ! create_snap "$container_id" "$container_name"; then
        echo -e "${RED}[error] Skipping $container_name${DEFAULT}"
        ((failed_updates = failed_updates + 1))
        continue
    fi

    # Check exit-code of update_ct
    if ! update_ct "$container_id" "$container_name"; then
        echo -e "${RED}[error] Could not update $container_name${DEFAULT}"
        ((failed_updates = failed_updates + 1))
        continue
    fi

    clear_snap "$container_id"

    ((success_updates = success_updates + 1))
done
wait

echo "[info] Successfully updated $success_updates, failing $failed_updates containers."
