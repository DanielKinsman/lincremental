#!/bin/bash
#incremental backup script
#creates the initial backup

set -eu

. ./lincremental.cfg
. ./lincremental_functions

#the specific directory to store this backup in
TRG="$TRGBASE/hourly.0"

#create TRGBASE if it does not already exist
if [ ! -d $TRGBASE ] ; then
	$MKDIR -v $TRGBASE
fi

#list of files to exclude from backups
if [ ! -e $EXCLUDES ] ; then
        $ECHO "*wrapped-passphrase" > $EXCLUDES
fi

#Exit if an initial backup has already been made
if [ -d $TRGBASE/hourly.0 ] ; then
	echo "Initial backup folder $TRGBASE/hourly.0 already exists, exiting."
	exit
fi

#the final rsync command
$RSYNC $OPT $SRC $TRG

#Update the mtime of hourly.0 to reflect the snapshot time
$TOUCH $TRG
