#!/bin/sh

# Assuming the ip65 project (https://github.com/cc65/ip65) is a filesystem peer to
# the ADTPro project being built, this script will copy over the necessary pieces.
# If a new ip65 lib is being used or built, this will get it into ADTPro.

mkdir lib/ip65/inc 2> /dev/null
cp ../../ip65/inc/* lib/ip65/inc
cp ../../ip65/ip65.lib lib/ip65/ip65.lib
cp ../../ip65/drivers/a2combo.lib lib/ip65/a2combo.lib
cp ../../ip65/drivers/a2uther2.lib lib/ip65/a2uther2.lib
