#!/bin/bash

# Put together to create rolling snapshots for Zenoss 5/6. 
# This script will take snapshots at a cron'd interval and 
# will only hold a maximum of two snapshots any any given time.

# If backups are running, exit. As backups lock the DFS, we cannot and do not
# want to attempt to take a snapshot during this time. 
if pgrep "zenbackup" > /dev/null; then exit; fi
if pgrep "rolling_snapshots" > /dev/null; then exit; fi

cd /opt/zaas/maintenance/scripts

if [[ -f zenoss_json.sh ]]; then
    source ./zenoss_json.sh
else
    echo "Unable to find zenoss_json.sh. Script will exit."
    exit
fi

PRODUCTIONSTATE=$(getZenossProductionState "$IPADDR")

# Check production state of device. If not production, do not take a snapshot and instead, exit.
if [[ $PRODUCTIONSTATE -ne "1000" ]]; then
    PRODUCTIONSTATE=$(getZenossProductionState "$IPADDR")

    if [[ $PRODUCTIONSTATE -ne "1000" ]]; then
        exit
    fi
fi

# Take a new snapshot
formattedDate=$(date -u "+%Y-%m-%d %H:%M:%S UTC")
serviced snapshot add $(serviced service list resmgr --format='{{.ID}}') --tag "Zenoss automated snapshot - $formattedDate" > /dev/null

# If < 2 snapshots, do not remove.
# If == 3 snapshots, delete the oldest.
# If > 3 snapshots, remove all snapshots but the most recent 2.
numberOfSnapshots=$(serviced snapshot list -t | grep -c "Zenoss automated snapshot")

if [[ $numberOfSnapshots -ge "3" ]]; then
    for snapshot in $(serviced snapshot list -t | grep "Zenoss automated snapshot" | sort | head -n -2 | awk '{print $1}'); do serviced snapshot rm "$snapshot"; done
else
    exit
fi
