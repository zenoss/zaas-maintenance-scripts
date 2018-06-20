#!/bin/bash

#
# fstrim
#

# Add zenoss_api function to script
cd /opt/zaas/maintenance/scripts

if [[ -f zenoss_json.sh ]]; then
    source ./zenoss_json.sh
else
    echo "Unable to find zenoss_json.sh. Script will exit."
    exit
fi

IPADDR=$(hostname -i)
TARGET=$(hostname -s)
DEVICE=$(getZenossDeviceByIP "$IPADDR")
COMPONENT="FSTrim"

UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has started for $TARGET.")
OUTPUT=$(/usr/sbin/fstrim -av)

sleep 5
clearZenossEvent "$DEVICE" "$COMPONENT" "$COMPONENT job has completed for $TARGET. Results: $OUTPUT" "$UUID"
