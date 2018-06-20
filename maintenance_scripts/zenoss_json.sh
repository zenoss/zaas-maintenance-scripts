#!/bin/sh

# Your Zenoss server settings.
# The URL to access your Zenoss5 Endpoint
ZENOSS_URL="ENTER_YOUR_ZENOSS_URL_HERE"
ZENOSS_USERNAME="ENTER_USER_WITH_ZENMANAGER_ACCESS_HERE"
ZENOSS_PASSWORD="ENTER_USER_PASSWORD_HERE"

# Generic call to make Zenoss JSON API calls easier on the shell.
zenoss_api () {
    ROUTER_ENDPOINT=$1
    ROUTER_ACTION=$2
    ROUTER_METHOD=$3
    DATA=$4

    if [ -z "${DATA}" ]; then
        echo "Usage: zenoss_api <endpoint> <action> <method> <data>"
        return 1
    fi

# add a -k for the curl call to ignore the default cert
    curl \
        -k \
		-s \
        -u "$ZENOSS_USERNAME:$ZENOSS_PASSWORD" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"action\":\"$ROUTER_ACTION\",\"method\":\"$ROUTER_METHOD\",\"data\":[$DATA], \"tid\":1}" \
        "$ZENOSS_URL/zport/dmd/$ROUTER_ENDPOINT"
}

function writeZenossErrorEvent {
	zenoss_api evconsole_router EventsRouter add_event '{"summary":"'"$3"'","device":"'"$1"'","component":"'"$2"'","severity":"4","evclasskey":"","evclass":"/Cmd"}' > /dev/null
}

function writeZenossInfoEvent {
	zenoss_api evconsole_router EventsRouter add_event '{"summary":"'"$3"'","device":"'"$1"'","component":"'"$2"'","severity":"2","evclasskey":"","evclass":"/Cmd"}' | python -c 'import sys, json; print json.load(sys.stdin)["uuid"]'
}

function writeZenossWarningEvent {
	zenoss_api evconsole_router EventsRouter add_event '{"summary":"'"$3"'","device":"'"$1"'","component":"'"$2"'","severity":"3","evclasskey":"","evclass":"/Cmd"}' | python -c 'import sys, json; print json.load(sys.stdin)["uuid"]'
}

function clearZenossEvent {
	zenoss_api evconsole_router EventsRouter add_event '{"summary":"'"$3"'","device":"'"$1"'","component":"'"$2"'","severity":"0","evclasskey":"'"$4"'","evclass":"/Cmd"}' > /dev/null
}	

function getZenossDeviceByIP {
	zenoss_api device_router DeviceRouter getDevices '{"keys":"","uid":"/zport/dmd/Devices/ControlCenter","params":{"ipAddress":"'"$1"'"}}' | python -c 'import sys, json; print json.load(sys.stdin)["result"]["devices"][0]["name"]'
}

function getZenossProductionState {
	zenoss_api device_router DeviceRouter getDevices '{"keys":"","uid":"/zport/dmd/Devices/ControlCenter","params":{"ipAddress":"'"$1"'"}}' | python -c 'import sys, json; print json.load(sys.stdin)["result"]["devices"][0]["productionState"]'
}
