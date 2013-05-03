#!/bin/bash
#incremental backup script
#takes daily backups and uses them as weekly backups

set -eu

. ./lincremental.cfg
. ./lincremental_functions

#If it takes you longer than a week to back up, you
#probably have bigger problems, but what the hell,
#let's lock anyway
lock "$LOCK_DIR" "weekly"

#Delete the oldest snapshot, if it exists
OLDEST="$TRGBASE/weekly.$NUM_WEEKLY"
if [ -d $OLDEST ] ; then
	$RM -rfv "$OLDEST"
fi

#Shift all the other backups back by one
shiftbackupsback "weekly" $NUM_WEEKLY

#Create the new weekly backup from the oldest daily backup, if it exists
if [ -d $TRGBASE/daily.$NUM_DAILY ] ; then
        $CP -alv "$TRGBASE/daily.$NUM_DAILY" "$TRGBASE/weekly.0"
fi
