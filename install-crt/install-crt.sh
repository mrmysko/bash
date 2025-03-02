#!/bin/bash

# Get running containers
containers_id=($(pct list | tail -n +2 | sed '/running/!d' | cut -f1 -d ' '))
containers_name=($(pct list | tail -n +2 | sed '/running/!d' | tr -s ' ' | cut -f3 -d ' '))

crt="intermediate_ca.crt"

DEFAULT='\033[0m'

RED='\033[0;31m'
failed_updates=0

GREEN='\033[0;32m'
success_updates=0

for ((i = 0; i < ${#containers_id[@]}; i++)); do
    container_id=${containers_id[i]}
    container_name=${containers_name[i]}

    pct push "${container_id}" "${crt}" "/usr/local/share/ca-certificates/${crt}"
    pct exec ${container_id} -- bash -c "update-ca-certificates"

done

echo "[info] Installed certificates."
