#!/bin/sh

# mkdmg.sh - makes an OSX disk image from directory contents
# From Philip Weaver: http://www.informagen.com/JarBundler/DiskImage.html

BASE="$1"
SRC="$2"
DEST="$3"
VOLUME="$4"
MEGABYTES="$5"

echo Base Directory $1
echo Source $2
echo Destination $3
echo Volume $4
echo Megabytes $5

TEMP="TEMPORARY"

cd $BASE

hdiutil create -megabytes $MEGABYTES $DEST$TEMP.dmg -layout NONE
MY_DISK=`hdid -nomount $DEST$TEMP.dmg`
newfs_hfs -v $VOLUME $MY_DISK
hdiutil eject $MY_DISK
hdid $DEST$TEMP.dmg
chflags -R nouchg,noschg "$SRC"
ditto -rsrcFork -v "$SRC" "/Volumes/$VOLUME"

mkdir "/Volumes/$VOLUME/.background"
cp ../src/org/adtpro/resources/ADTProMacInstallBackground.png "/Volumes/$VOLUME/.background/background.png"
cp ADTProDMG.icns "/Volumes/$VOLUME/.VolumeIcon.icns"
SetFile -c icns "/Volumes/$VOLUME/.VolumeIcon.icns"
SetFile -a C "/Volumes/$VOLUME"
./lib/setfileicon ADTProFolder.icns "/Volumes/$VOLUME/$VOLUME"
./lib/setfileicon ADTPro.icns "/Volumes/$VOLUME/$VOLUME/$VOLUME.app"
rm -rf /Volumes/$VOLUME/.Trashes
rm -rf /Volumes/$VOLUME/.fseventsd

echo '
   tell application "Finder"
     tell disk "'${VOLUME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 723, 305}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".background:background.png"
           make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
           set position of item "'${VOLUME}'" of container window to {83, 101}
           set position of item "Applications" of container window to {242, 101}
           update without registering applications
           close
           open
           delay 5
     end tell
   end tell
' | osascript

hdiutil eject $MY_DISK
hdiutil convert -format UDCO $DEST$TEMP.dmg -o $DEST$VOLUME.dmg
hdiutil internet-enable -yes $DEST$VOLUME.dmg
mv $DEST$VOLUME.dmg $DEST.dmg
rm $DEST$TEMP.dmg
