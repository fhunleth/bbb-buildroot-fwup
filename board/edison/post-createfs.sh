#!/bin/sh

set -e

TARGETDIR=$1
FWUPCONF_NAME=$2

PROJECT_ROOT=$TARGETDIR/../../..
IMAGESDIR=$TARGETDIR/../images
FWUP_CONFIG=$PROJECT_ROOT/board/edison/$FWUPCONF_NAME
FWUP=$PROJECT_ROOT/buildroot/output/host/usr/bin/fwup

FW_PATH=$PROJECT_ROOT/buildroot/output/images/edison.fw
IMG_PATH=$PROJECT_ROOT/buildroot/output/images/edison.img
XFSTK_IMG_PATH=$PROJECT_ROOT/buildroot/output/images/edison.xfstk.img

# Build the firmware image (.fw file)
echo "Creating firmware file..."
PROJECT_ROOT=$PROJECT_ROOT $FWUP -c -f $FWUP_CONFIG -o $FW_PATH

# Build a raw image that can be directly written to eMMC
echo "Creating raw eMMC image file..."
rm -f $IMG_PATH
$FWUP -a -d $IMG_PATH -i $FW_PATH -t complete

# Intel's XFSTK tool reads the OSIP header to determine
# where to write all bytes that follow, so the raw image needs to be modified.
# Note that the constant 2048 below must match the u-boot offset
# in the fwup config file.
echo "Creating image for Intel's XFSTK tool..."
dd if=$IMG_PATH of=$XFSTK_IMG_PATH count=1 2>/dev/null
dd if=$IMG_PATH of=$XFSTK_IMG_PATH skip=2048 seek=1 conv=notrunc 2>/dev/null

