#!/bin/bash
#Incremental backup script
#Takes the latest daily backup set and pushes it to amazon glacier via a tar file

set -eu

. ./lincremental.cfg
. ./lincremental_functions

ORIGINAL="$TRGBASE/daily.0"
UPLOAD="$AWS_UPLOAD_DIR/upload.tar"
READY_LOCK_FILE="$LOCK_DIR/upload.ready"
LAST_UPLOAD_FILE="$LOCK_DIR/upload.last"
LINCREMENTAL="lincremental"

lock $LOCK_DIR "glacier"

function cleanup {
    $RM -fv $READY_LOCK_FILE
    $RM -fv $UPLOAD
}

#create the upload folder if it does not exist
if [ ! -d $AWS_UPLOAD_DIR ] ; then
	$MKDIR -v $AWS_UPLOAD_DIR
fi

#Check to see if we are resuming a partial upload
if [ ! -f $READY_LOCK_FILE ] ; then
    #Starting from scratch, create the upload file

    #if the original dir does not exist, we can't do anything, exit
    if [ ! -d $ORIGINAL ] ; then
            $ECHO "Can't find original backup set at $ORIGINAL, exiting."
        exit 1
    fi

    #Make sure we wait the desired time between uploads
    if [ -f $LAST_UPLOAD_FILE ] ; then
        let "LAST=$($DATE -r $LAST_UPLOAD_FILE +%s)"
        let "NOW=$($DATE +%s)"
        ELAPSED=$(( $(($NOW - $LAST)) / 60 / 60 / 24 )) #days
        $ECHO "$ELAPSED days since last backup"
        if [ "$ELAPSED" -lt "$AWS_DAYS_BETWEEN_UPLOADS" ] ; then
            $ECHO "No need to make another backup so soon, exiting"
            exit 0
        fi
    fi

    DESCRIPTION="$LINCREMENTAL $($DATE -r $ORIGINAL)"

    #create a tar from original to upload to glacier
    $TAR $TAR_OPT $UPLOAD -C $TRGBASE "daily.0"

    #encrypt the backup file if desired
    if [ ! -z "$GPG_PUBLIC_KEY" ] ; then
        $GPG -v -r $GPG_PUBLIC_KEY -o "$UPLOAD.gpg" --encrypt $UPLOAD
        $RM -fv $UPLOAD
        UPLOAD="$UPLOAD.gpg"
    fi

    #Indicate that next time we come in, we don't have to create
    #the archive again. Note that we can't just use the upload file as a lock
    #because it may have been created, but not yet finished.
    $TOUCH $READY_LOCK_FILE

    #Keep track of the last time we started an upload
    $TOUCH $LAST_UPLOAD_FILE

    #upload the file
    $ECHO "Uploading"
    $GLACIER upload $AWS_VAULT $UPLOAD --description "$DESCRIPTION"
else
    #Resuming a multipart upload
    if [ ! -z "$GPG_PUBLIC_KEY" ] ; then
        UPLOAD="$UPLOAD.gpg"
    fi

    if [ ! -f $UPLOAD ] ; then
        $ECHO "Can't resume as the upload file ($UPLOAD) is missing, cleaning up and exiting."
        cleanup
        exit 1
    fi

    #Pull the glacier multipart upload id out
    MULTIPART_ID=$($GLACIER listmultiparts $AWS_VAULT | $GREP $LINCREMENTAL | $CUT --bytes=3-94)

    #Handle case where there is no multipart upload in progress
    #E.g. lock file was touched, but upload never started (network possibly down)
    if [ -z "$MULTIPART_ID" ] ; then
        $ECHO "Can't resume as there is no multipart upload in progress, cleaning up and exiting."
        cleanup
        exit 1
    fi

    $ECHO "Resuming multipart upload $MULTIPART_ID"
    $GLACIER upload --uploadid $MULTIPART_ID $AWS_VAULT $UPLOAD
fi

#Clean up
cleanup

#Test plan for this script:
#single run success -done
#dead before touch lockfile, then restart -done
#dead after upload started, then restart -done
#dead after upload resumed, then restart -done
#resume sucess -done
#dead after touch, but *before* upload started -done
#lock file exists but upload file doesn't -done