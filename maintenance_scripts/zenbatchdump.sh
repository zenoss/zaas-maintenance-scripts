#!/bin/bash

#
# Zenoss 5x batch dump
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
DOCKER_SRC_DIR="/mnt/pwd"
IPADDR=$(hostname -i)
DEVICE=$(getZenossDeviceByIP $IPADDR)
PRODUCTIONSTATE=$(getZenossProductionState "$IPADDR")
COMPONENT="zenbatchdump"

# Make sure log directory exists
if [[ ! -d $LOG_DIR ]]; then
    mkdir $LOG_DIR
    chmod 777 $LOG_DIR
fi

# Run zenbatchdump
cd $SRC_DIR
UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has started for $TARGET.")
BACKUP="zenbatchdump-$(date +\%Y\%m\%d).tgz"
LOG="zenbatchdump-cron-$(date +\%Y\%m\%d).log"
serviced service shell zope su -c "source ~zenoss/.bashrc;/opt/zenoss/bin/zenbatchdump --outFile=$DOCKER_SRC_DIR/$BACKUP" > $LOG_DIR/$LOG 2>&1 - zenoss
sleep 5

SIZE=$(du -k $SRC_DIR/$BACKUP | cut -f1)

# Check if backup exists and is larger than 0B
if [[ -f "$SRC_DIR/$BACKUP" ]] && [[ $SIZE -gt 0 ]]; then
    clearZenossEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has completed successfully for $TARGET." "$UUID"
else
    clearZenossEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has failed for $TARGET." "$UUID"
    writeZenossWarningEvent "$DEVICE" "$COMPONENT" "$COMPONENT job failed for $TARGET. See logs for details."
fi
