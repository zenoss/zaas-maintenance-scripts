#!/bin/bash

# 
# This script orchestrates all of the maintenance tasks needed
# for Zenoss upkeep. Configured for use in a ZaaS environment 
# with version 6.x installed.
#

cd /opt/zaas/maintenance/scripts

if [[ -f zenoss_json.sh ]]; then
    source ./zenoss_json.sh
else
    echo "Unable to find zenoss_json.sh. Script will exit."
    exit
fi

# Declare variables
TARGET=$(hostname -s)
IPADDR=$(hostname -i)
DEVICE=$(getZenossDeviceByIP $IPADDR)
PRODUCTIONSTATE=$(getZenossProductionState "$IPADDR")
TODAY=$(date +%A)

# Check production state of device. If not production, do not take a backup.
if [[ $PRODUCTIONSTATE -ne "1000" ]]; then
    UUID=$(writeZenossInfoEvent "$DEVICE" "Backups" "Backups will not proceed for $TARGET as device is not in a production state.")
    exit    
fi

# Edit MOTD to let users know backups are running
cp /dev/null /etc/motd
echo -en "\033[1;31m" >> /etc/motd
echo "###################################################################" >> /etc/motd
echo "###################################################################" >> /etc/motd
echo -en "\033[0m" >> /etc/motd
echo "------- Backups are currently running. Please do not reboot -------" >> /etc/motd
echo -en "\033[1;31m" >> /etc/motd
echo "###################################################################" >> /etc/motd
echo "###################################################################" >> /etc/motd
echo -en "\033[0m" >> /etc/motd

cd /opt/zaas/maintenance/scripts

# Any custom scripts that you want to run prior to running through
# these maintenance scripts should be placed in the below directory.
# This is mainly for restarts that may need to happen nightly, or 
# workarounds for known defects.
if [[ -z "$(ls -A /opt/zaas/maintenance/custom_scripts)" ]]; then
    continue
else
    run-parts /opt/zaas/maintenance/custom_scripts
fi

# Run through maintenance scripts
./zenbatchdump.sh
./zenbackup.sh
./fstrim.sh

if [[ $TODAY = "Saturday" ]]; then

    # Go through toolbox scans one at a time. Only continue if exit code = 0
    ./toolboxscans.sh "zodbscan"

    if [[ $? -eq 0 ]]; then
        ./toolboxscans.sh "zenrelationscan"

        if [[ $? -eq 0 ]]; then
            ./toolboxscans.sh "zencatalogscan"    
        fi

    fi

    # Run zenossdbpack regardless of whether or not scans above 
    # passed. This should be run on a regular basis weekly.
	./toolboxscans.sh "zenossdbpack"
    
fi

cp /dev/null /etc/motd
