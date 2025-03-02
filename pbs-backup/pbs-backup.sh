#!/bin/bash

USERNAME="Backups-Manager"
REALM="pbs"
DISK="pbs"
DATASTORE="Backups"
REPO="$USERNAME@$REALM@$DISK:$DATASTORE"

export HOSTNAME=${HOSTNAME:-no-hostname}
export PBS_PASSWORD=$(cat /root/.pbs_pass)

proxmox-backup-client namespace create $HOSTNAME --repository $REPO

proxmox-backup-client backup root.pxar:/ --keyfile /etc/pve/priv/storage/Proliant.enc \
                                         --ns $HOSTNAME \
                                         --repository $REPO

proxmox-backup-client prune host/node1 --keep-daily 7 \
                                       --keep-weekly 4 \
                                       --keep-monthly 6 \
                                       --keep-yearly 2 \
                                       --repository $REPO
