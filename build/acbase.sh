#!/bin/sh
#
# ADTPro - AppleCommander command line invocation script
#
# Set default ADTPRO_HOME to be the fully qualified
# current working directory.

export ADTPRO_HOME="`dirname \"$0\"`"
cd "$ADTPRO_HOME"
export ADTPRO_HOME=`pwd`

# You can set two variables here:
#   1. $MY_JAVA_HOME - to pick a particular java to run under
#   2. $ADTPRO_HOME - to say where you installed ADTPro
#
# Uncomment and modify one or both of the lines below if you
# want to specify a particular location for Java or ADTPro.
# NOTE: be sure to include a trailing slash on MY_JAVA_HOME,
# but not on ADTPRO_HOME.
#
# export MY_JAVA_HOME=/usr/local/java/bin/
# export ADTPRO_HOME=~/myuser/adtpro

"$MY_JAVA_HOME"java -Xms256m -Xmx512m -jar lib/AppleCommander/AppleCommander-%AC_VERSION%.jar $*
