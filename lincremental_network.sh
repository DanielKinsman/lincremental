#!/bin/bash
#incremental backup script
#Copies all backup sets (hourly, daily, weekly monthly) from one machine to another

set -eu

. /etc/lincremental/lincremental.cfg
. /usr/local/lincremental/lincremental_functions

#the source directory to sync across (note the trailing slash)
NETWORK_SRC="$TRGBASE/"

#if the original dir does not exist, we can't do anything, exit
if [ ! -d $NETWORK_SRC ] ; then
    $ECHO "Can't find original backup sets at $NETWORK_SRC, exiting."
    exit 1
fi

#if NETWORK_TRG is not specified, exit
if [ -z $NETWORK_TRG ] ; then
    $ECHO "Network backups not configured to run, exiting."
    exit 0
fi

lock "$LOCK_DIR" "network"

#the final rsync command
$RSYNC $NETWORK_OPT $NETWORK_SRC $NETWORK_TRG