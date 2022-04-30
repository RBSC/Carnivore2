#!/bin/bash
SDIR=$(dirname `readlink -f $0`)
DIR=`readlink -f $SDIR/../..`
IMAGE=CfImage.bin
dd if=/dev/zero ibs=1k count=16 | tr "\000" "\377" >$IMAGE
dd if=$DIR/BootBlock/BOOTCMFC.BIN of=$IMAGE conv=notrunc
cat $DIR/ROMs/BIDECMFC.BIN >> $IMAGE
cat $DIR/ROMs/FMPCCMFC.BIN >> $IMAGE
echo Created $IMAGE