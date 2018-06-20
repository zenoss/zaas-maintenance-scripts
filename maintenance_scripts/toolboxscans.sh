#!/bin/bash

#
# This script executes out of the box toolbox scans
# on either a scheduled or ad hoc basis. If said scan
# finds an error, will attempt to fix with -f. If scan
# still cannot fix, an event will be generated into the
# configured Zenoss instance in zenoss_json.sh as a warning
# event.
#
# This script is to be run on the Control Center master.
# 
# Usage: ./toolboxscans.sh <scan_name>
#

# Add zenoss_api function to script
cd /opt/zaas/maintenance/scripts

if [[ -f zenoss_json.sh ]]; then
    source ./zenoss_json.sh
else
    echo "Unable to find zenoss_json.sh. Script will exit."
    exit
fi

if [[ -z $1 ]]; then
    echo "Usage: ./toolboxscans.sh <scan_name>"
    echo "Example: ./toolboxscans.sh zodbscan"
    exit
fi

# Declare variables
SCAN="$1"
LOG="$SCAN-$(date +%Y%m%d).log"
LOGDIR="/var/log/serviced/toolboxscans"
IPADDR=$(hostname -i)
DEVICE=$(getZenossDeviceByIP "$IPADDR")
TARGET=$(hostname -s)
COMPONENT="toolboxscans"

# Check if toolbox log directory exists. If not, create it
if [[ ! -d $LOGDIR ]]; then
    mkdir $LOGDIR
    chmod 777 $LOGDIR
fi

# Only run this portion if $SCAN = zodbscan
if [[ $SCAN = "zodbscan" ]]; then

	UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$SCAN has started for $TARGET.")
	serviced service shell --mount '/var/log/serviced/toolboxscans,/opt/zenoss/log/toolbox' zope su - zenoss -c "yes | $SCAN -s"

    # If the scan fails...
    if [[ "$?" != "0" ]]; then
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN has completed with errors." "$UUID"
        sleep 
        UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$SCAN has failed for $TARGET. Running findposkeyerror with -f.")
		mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"		

        SCAN="findposkeyerror"

        serviced service shell --mount '/var/log/serviced/toolboxscans,/opt/zenoss/log/toolbox' zope su - zenoss -c "yes | $SCAN -f -v10"

		# If the scan fails again...
        if [[ "$?" != "0" ]]; then
            UUID=$(writeZenossWarningEvent "$DEVICE" "$COMPONENT" "$SCAN failed to fix for $TARGET. Check /var/log/serviced/toolboxscans for details.")
            mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
            exit 1

        # If -f resolves the issue...
        else
            clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN -f fixed all errors for $TARGET." "$UUID"
            mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
            exit 0
        fi

    # If the scan succeeds...
    else
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN ran successfully for $TARGET."
        mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
        exit 0
    fi
fi

# Only run this if $SCAN = zenrelationscan or zencatalogscan
if [[ $SCAN = "zenrelationscan" ]] || [[ $SCAN = "zencatalogscan" ]]; then

    UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$SCAN has started for $TARGET.")
    serviced service shell --mount '/var/log/serviced/toolboxscans,/opt/zenoss/log/toolbox' zope su - zenoss -c "yes | $SCAN -s"

    # If the scan fails...
    if [[ "$?" != "0" ]]; then
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN has completed with errors." "$UUID"
        sleep 3
        UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$SCAN has failed for $TARGET. Attempting with -f.")

        serviced service shell --mount '/var/log/serviced/toolboxscans,/opt/zenoss/log/toolbox' zope su - zenoss -c "yes | $SCAN -f -s -v10"

        # If the scan fails again...
        if [[ "$?" != "0" ]]; then
            UUID=$(writeZenossWarningEvent "$DEVICE" "$COMPONENT" "$SCAN failed to fix for $TARGET. Check /var/log/serviced/toolboxscans for details.")
            mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
            exit 1

        # If -f resolves the issue...
        else
            clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN -f fixed all errors for $TARGET." "$UUID"
            mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
            exit 0
        fi

    # If the scan succeeds...
    else
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN ran successfully for $TARGET."
        mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
        exit 0
    fi
fi

# Only run this portion if $SCAN = zenossdbpack
if [[ $SCAN = "zenossdbpack" ]]; then

    UUID=$(writeZenossInfoEvent "$DEVICE" "$COMPONENT" "$SCAN has started for $TARGET.")
    serviced service run --mount /var/log/serviced/toolboxscans,/opt/zenoss/log zope zenossdbpack

    # If the scan fails...
    if [[ "$?" != "0" ]]; then
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN has completed with errors." "$UUID"
        sleep 3
        writeZenossWarningEvent "$DEVICE" "$COMPONENT" "$SCAN has failed for $TARGET. Check /var/log/serviced/toolboxscans for details."
        mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
        exit 1
    
    # If the scan succeeds...
    else
        clearZenossEvent "$DEVICE" "$COMPONENT" "$SCAN ran successfully for $TARGET."
        mv $LOGDIR/"$SCAN.log" $LOGDIR/"$LOG"
        exit 0
    fi
fi
