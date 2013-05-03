#!/bin/bash
#incremental backup script
#takes hourly backups and uses them as daily backups

set -eu

. ./lincremental.cfg
. ./lincremental_functions

lock "$LOCK_DIR" "daily"

#Delete the oldest snapshot, if it exists
OLDEST="$TRGBASE/daily.$NUM_DAILY"
if [ -d $OLDEST ] ; then
	$RM -rfv "$OLDEST"
fi

#Shift all the other backups back by one
shiftbackupsback "daily" $NUM_DAILY

#Create the new daily backup from the oldest hourly backup, if it exists
if [ -d $TRGBASE/hourly.$NUM_HOURLY ] ; then
        $CP -alv "$TRGBASE/hourly.$NUM_HOURLY" "$TRGBASE/daily.0"
fi
