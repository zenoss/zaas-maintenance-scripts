# ZaaS Maintenance Scripts

A set of scripts that the ZaaS team @ Zenoss has put together to maintain Zenoss 5x/6x installations.

**These scripts come with no official support and are solely being offered as a means to get you started on maintaining your own Zenoss installation.**

All scripts in the `maintenance_scripts` directory should be carefully reviewed in order to ensure that paths exist and that your Zenoss URL and credentials are set appropriately.

Everything in the `maintenance_scripts` folder can be run ad-hoc as needed, but the main intention for these scripts is to schedule them to be executed by `zenoss_maintenance_scripts.sh` on a nightly interval.

**NOTE: These scripts will not function on a <= 4x installation.**

## zenoss_maintenance_scripts.sh

Orchestrates all scripts in the `maintenance_scripts` directory to run at a cronned interval. Will query your Resource Manager URL for what is configured in `zenoss_json.sh` to check the production state of the device and will only proceed when the production state is "Production" (which by default is state "1000"). It is best to confirm in `zenoss_json.sh` that we are querying for the correct device in your installation. 

If you have configured and installed Zenoss as the root user, open the root user's crontab and set up the following to run this script at midnight:

`0 0 * * * <path-to-scripts>/zenoss_maintenance_scripts.sh`

## zenoss_json.sh

Variables and functions are listed here. Additionally, your Zenoss Resource Manager URL and credentials should be configured in this file in order to properly query your instance for production states and generate events.

## fstrim.sh

Executes fstrim and generates an event in your Zenoss installation with the output.

By default, `zenoss_maintenance_scripts.sh` will run this daily.

## zenbackup.sh

Executes the `serviced backup` command along with generating events in your Zenoss installation on success/failure. Configuration on generating these events can be configured in `zenoss_json.sh`.

By default, `zenoss_maintenance_scripts.sh` will run this daily.

## zenbatchdump.sh

Executes the `zenbatchdump` command along with generating events in your Zenoss installation on success/failure. Configuration on generating these events can be configured in `zenoss_json.sh`.

By default, `zenoss_maintenance_scripts.sh` will run this daily.

## toolboxscans.sh

Executes the `zodbscan`, `findposkeyerror`, `zenrelationscan`, `zencatalogscan` and `zodbpack` commands to check the integrity of your Zenoss installation. If a scan fails to automatically fix the problem, the script will not proceed and will generate a warning event in your Zenoss installation to investigate the problem.

By default, `zenoss_maintenance_scripts.sh` will run these weekly. 

## rolling_snapshots.sh

Executes the `serviced snapshot add` command to take a full application snapshot of your Zenoss installation. This script is not part of the `zenoss_maintenance_scripts.sh` script, but rather should be cronned on its own interval (preferably every hour). 

An example of a cron entry for running every hour would look as follows:

`* */1 * * * <path-to-scripts>/rolling_snapshots.sh`
