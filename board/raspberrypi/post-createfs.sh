#!/bin/sh

set -e

TARGETDIR=$1
FWUPCONF_NAME=$2

PROJECT_ROOT=$TARGETDIR/../../..
FWUP_CONFIG=$PROJECT_ROOT/board/raspberrypi/$FWUPCONF_NAME
FWUP=$PROJECT_ROOT/buildroot/output/host/usr/bin/fwup

FW_PATH=$PROJECT_ROOT/buildroot/output/images/raspberrypi.fw
IMG_PATH=$PROJECT_ROOT/buildroot/output/images/raspberrypi.img

# Build the firmware image (.fw file)
echo "Creating firmware file..."
PROJECT_ROOT=$PROJECT_ROOT $FWUP -c -f $FWUP_CONFIG -o $FW_PATH

# Build a raw image that can be directly written to
# an SDCard (remove an exiting file so that the file that
# is written is of minimum size. Otherwise, fwup just modifies
# the file. It will work, but may be larger than necessary.)
echo "Creating raw SDCard image file..."
rm -f $IMG_PATH
$FWUP -a -d $IMG_PATH -i $FW_PATH -t complete


