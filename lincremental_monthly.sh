#!/bin/bash
#incremental backup script
#takes weekly backups and uses them as monthly backups

set -eu

. /etc/lincremental/lincremental.cfg
. /usr/local/lincremental/lincremental_functions

#If it takes you longer than a month to back up, you
#probably have bigger problems, but what the hell,
#let's lock anyway
lock "$LOCK_DIR" "monthly"

#Delete the oldest snapshot, if it exists
OLDEST="$TRGBASE/monthly.$NUM_MONTHLY"
if [ -d $OLDEST ] ; then
	$RM -rfv "$OLDEST"
fi

#Shift all the other backups back by one
shiftbackupsback "monthly" $NUM_MONTHLY

#Create the new monthly backup from the oldest weekly backup, if it exists
if [ -d $TRGBASE/weekly.$NUM_WEEKLY ] ; then
        $CP -alv "$TRGBASE/weekly.$NUM_WEEKLY" "$TRGBASE/monthly.0"
fi
