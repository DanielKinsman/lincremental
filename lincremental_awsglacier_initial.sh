#!/bin/bash
#Incremental backup script
#Takes all backup sets (hourly, daily, weekly monthly) and pushes them to amazon glacier via tar files
#This script does the initial master upload

set -eu

. ./lincremental.cfg
. ./lincremental_functions

#the directory where normal rsync lincremental backups are (note trailing slash)
ORIGINAL="$TRGBASE/"

MASTER="$AWS_SIMULCRUM/master/"
MASTERTAR="$AWS_SIMULCRUM/master.tar"
CURRENT="$AWS_SIMULCRUM/current/"
READY_LOCK_FILE="$LOCK_DIR/master.ready"

#if the original dir does not exist, we can't do anything, exit
if [ ! -d $ORIGINAL ] ; then
        $ECHO "Can't find original backup sets at $ORIGINAL, exiting."
	exit 1
fi

lock $LOCK_DIR "glacier"

#create the simulcrum folder if it does not exist
if [ ! -d $AWS_SIMULCRUM ] ; then
	$MKDIR -v $AWS_SIMULCRUM
fi

#Check to see if we are resuming a partial upload
if [ -! f $READY_LOCK_FILE ] ; then
    #Starting from scratch, create the master folder
    $RSYNC $AWS_OPT $ORIGINAL $MASTER

    #create a tar from master to upload to glacier
    #(tars preserve hard links so take up much less space)
    $TAR -cvf $MASTERTAR -C $AWS_SIMULCRUM master

    #encrypt the backup file if desired
    if [ ! -z "$GPG_PUBLIC_KEY" ] ; then
        $GPG -v -r $GPG_PUBLIC_KEY -o "$MASTERTAR.gpg" --encrypt $MASTERTAR
        $RM -fv $MASTERTAR
        MASTERTAR="$MASTERTAR.gpg"
    fi

    #indicate that next time we come in, we don't have to create
    #the archive again
    $TOUCH $READY_LOCK_FILE

    #upload the file
    $GLACIER upload $AWS_VAULT $MASTERTAR --description $MASTERTAR
else
    #Resuming a multipart upload
    if [ ! -z "$GPG_PUBLIC_KEY" ] ; then
        MASTERTAR="$MASTERTAR.gpg"
    fi

    #todo: handle case where lock file was touched, but upload never started

    #Pull the glacier multipart upload id out
    MULTIPART_ID=$GLACIER listmultiparts $AWS_VAULT | $GREP $MASTERTAR | $CUT --bytes=3-94
    $GLACIER upload --uploadid $MULTIPART_ID $AWS_VAULT $MASTERTAR
fi

#with tar of master successfully created, master it becomes our
#current representation of what is on glacier
$MV $MASTER $CURRENT

#Don't need the tar anymore
$RM -fv $READY_LOCK_FILE
$RM -fv $MASTERTAR

#Test plan for this script:
#single run success
#dead before touch lockfile, then restart
#dead after upload started, then restart
#dead after upload resumed, then restart
#resume sucess
#dead after touch, but *before* upload started