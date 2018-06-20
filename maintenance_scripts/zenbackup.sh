#!/bin/bash

#
# This script will assist in taking an automated
# backup of your Zenoss 5x/6x instance. As Zenoss
# backups can become quite large in size, you should
# implement some method to control the number of backups
# on the filesystem by either shipping them off site or 
# controlling how many you keep around on disk.
#

# Add zenoss_api function to script
cd /opt/zaas/maintenance/scripts

if [[ -f zenoss_json.sh ]]; then
    source ./zenoss_json.sh
else
    echo "Unable to find zenoss_json.sh. Script will exit."
    exit
fi

# Declare variables
TARGET=$(hostname -s)
SRC_DIR="/opt/serviced/var/backups"
LOG_DIR="$SRC_DIR/log"
LOGFILE="zenbackup-cron-$(date +\%Y\%m\%d).log"
IPADDR=$(hostname -i)
DEVICE=$(getZenossDeviceByIP "$IPADDR")
COMPONENT="zenbackup"

# Make sure log directory exists
if [[ ! -d $LOG_DIR ]]; then
    mkdir $LOG_DIR
    chmod 777 $LOG_DIR
fi

# Before we take a backup, remove any automated snapshots.
# This is due to backups locking the DFS, which restricts
# you from managing snapshots during the backup process.
# You don't want a snapshot growing out of control and 
# then not being able to get yourself out of a scary situation.
for snapshot in $(serviced snapshot list -t | grep "Zenoss automated snapshot" |  awk '{print $1}'); do serviced snapshot rm "$snapshot"; done

# Run backup
UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has started for $TARGET.")
BACKUP=$(/usr/bin/serviced backup /opt/serviced/var/backups)
sleep 5

SIZE=$(du -k $SRC_DIR/"$BACKUP" | cut -f1)

# Check if backup exists and is larger than 0B
if [[ -f "$SRC_DIR/$BACKUP" ]] && [[ "$SIZE" -gt 0 ]]; then
    clearZenossEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has completed successfully for $TARGET." "$UUID"
else
    clearZenossEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has failed for $TARGET." "$UUID"
    writeZenossWarningEvent "$DEVICE" "$COMPONENT" "$COMPONENT job failed for $TARGET. See logs for details."
fi
