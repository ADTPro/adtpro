#!/bin/sh

# mkdmg.sh - makes an OSX disk image from directory contents
# From Philip Weaver: http://www.informagen.com/JarBundler/DiskImage.html

BASE="$1"
SRC="$2"
DEST="$3"
VOLUME="$4"

echo Base Directory $1
echo Source $2
echo Destination $3
echo Volume $4

TEMP="TEMPORARY"

cd $BASE

hdiutil create -megabytes 5 $DEST$TEMP.dmg -layout NONE
MY_DISK=`hdid -nomount $DEST$TEMP.dmg`
newfs_hfs -v $VOLUME $MY_DISK
hdiutil eject $MY_DISK
hdid $DEST$TEMP.dmg
chflags -R nouchg,noschg "$SRC"
ditto -rsrcFork -v "$SRC" "/Volumes/$VOLUME"
hdiutil eject $MY_DISK
hdiutil convert -format UDCO $DEST$TEMP.dmg -o $DEST$VOLUME.dmg
hdiutil internet-enable -yes $DEST$VOLUME.dmg
mv $DEST$VOLUME.dmg $DEST.dmg
rm $DEST$TEMP.dmg
