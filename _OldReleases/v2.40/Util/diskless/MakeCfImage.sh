#!/bin/bash
SDIR=$(dirname `readlink -f $0`)
DIR=`readlink -f $SDIR/../..`
IMAGE=CfImage.bin
dd if=/dev/zero ibs=1k count=32 | tr "\000" "\377" >$IMAGE
dd if=$DIR/BootMenu/BOOTCMFC.BIN of=$IMAGE conv=notrunc
cat $DIR/BIOSes/BIDECMFC.BIN >> $IMAGE
cat $DIR/BIOSes/FMPCCMFC.BIN >> $IMAGE
echo Created $IMAGE