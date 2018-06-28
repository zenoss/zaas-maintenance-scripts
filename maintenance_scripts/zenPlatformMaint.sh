#!/bin/env bash

PARAMS=""

if [ $# -lt 1 ] ; then
    echo "USAGE $0:"
    echo "-b | --do-backup"
    echo "  Perform a zenbatchbup & serviced backup"
    echo "-f | --do-fstrim"
    echo "  Perform an fstrim (cron'd weekly by default)"
    echo "-z | --do-zodbscan"
    echo "  Perform a zenoss toolbox zodbscan"
    echo "-r | --do-zenrelationscan"
    echo "  Perform a zenoss toolbox zenrelationscan"
    echo "-c | --do-zencatalogscan"
    echo "  Perform a zenoss toolbox zencatalogscan" 
    echo "-p | --do-zenossdbpack"
    echo "  Perform a zenossdbpack (cron'd weekly by default)"
    echo "-v"
    echo "  Print info messages at the start of each task"
fi
while (( "$#" )); do
  case "$1" in
    -b|--do-backup)
      doBackup="TRUE"
      shift 1
      ;;
    -f|--do-fstrim)
      doFstrim="TRUE"
      shift 1
      ;;
    -z|--do-zodbscan)
      doZodbscan="TRUE"
      shift 1
      ;;
    -r|--do-zenrelationscan)
      dozenRelationscan="TRUE"
      shift 1
      ;;
    -c|--do-zencatalogscan)
      dozenCatalogscan="TRUE"
      shift 1
      ;;
    -p|--do-zenossdbpack)
      doZenossdbpack="TRUE"
      shift 1
      ;;
    -v)
      infoLog="TRUE"
      shift 1
      ;;
    --all)
      doBackup="TRUE"
      doFstrim="TRUE"
      doZodbscan="TRUE"
      dozenRelationscan="TRUE"
      dozenCatalogscan="TRUE"
      doZenossdbpack="TRUE"
      shift 1
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"
scriptDIR=`echo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" | /bin/sed 's/libexec/bin/'`

cd $scriptDIR
if [ ! -z "$doBackup" ] ; then
    #TODO: Add service's 'serviced-backupprune' script
    if [ ! -z "$infoLog" ] ; then echo "Running backup step: zenbatchdump..."; fi
    ./zenbatchdump.sh
    #TODO: Would also be nice to perform event triggers & notifications export
    if [ ! -z "$infoLog" ] ; then echo "Running backup step: zenbackup..."; fi
    ./zenbackup.sh
fi
if [ ! -z "$doFstrim" ] ; then
    if [ ! -z "$infoLog" ] ; then echo "Running fstrim..."; fi
    ./fstrim.sh
fi
if [ ! -z "$doZenossdbpack" ] ; then
    if [ ! -z "$infoLog" ] ; then echo "Running zenossdbpack..."; fi
    ./toolboxscans.sh "zenossdbpack"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi
if [ ! -z "$doZodbscan" ] ; then
    if [ ! -z "$infoLog" ] ; then echo "Running zodbscan..."; fi
    ./toolboxscans.sh "zodbscan"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi
if [ ! -z "$dozenRelationscan" ] ; then
    if [ ! -z "$infoLog" ] ; then echo "Running zenrelationscan..."; fi
    ./toolboxscans.sh "zenrelationscan"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi
if [ ! -z "$dozenCatalogscan" ] ; then
    if [ ! -z "$infoLog" ] ; then echo "Running zencatalogscan..."; fi
    ./toolboxscans.sh "zencatalogscan"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
fi