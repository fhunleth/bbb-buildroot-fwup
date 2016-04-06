#!/bin/sh

set -e

TARGETDIR=$1
FWUPCONF_NAME=$2

FWUP_CONFIG=$BR2_EXTERNAL/board/raspberrypi/$FWUPCONF_NAME
FWUP=$HOST_DIR/usr/bin/fwup

FW_PATH=$BINARIES_DIR/raspberrypi.fw
IMG_PATH=$BINARIES_DIR/raspberrypi.img

# Process the kernel if using device tree
if [ -e $HOST_DIR/usr/bin/mkknlimg ]; then
    $HOST_DIR/usr/bin/mkknlimg \
        $BINARIES_DIR/zImage $BINARIES_DIR/zImage.mkknlimg
fi

# Build the firmware image (.fw file)
echo "Creating firmware file..."
PROJECT_ROOT=$BR2_EXTERNAL $FWUP -c -f $FWUP_CONFIG -o $FW_PATH

# Build a raw image that can be directly written to
# an SDCard (remove an exiting file so that the file that
# is written is of minimum size. Otherwise, fwup just modifies
# the file. It will work, but may be larger than necessary.)
echo "Creating raw SDCard image file..."
rm -f $IMG_PATH
$FWUP -a -d $IMG_PATH -i $FW_PATH -t complete


