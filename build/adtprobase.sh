#!/bin/sh
#
# ADTPro - *nix startup shell script
#
# You can set two variables here:
#   1. $MY_JAVA_HOME - to pick a particular java to run under
#   2. $ADTPRO_HOME - to say where you installed ADTPro
#
# e.g.
#
# export MY_JAVA_HOME=/usr/local/java/bin/ (need final slash)
# export ADTPRO_HOME=~/myuser/adtpro/  (need final slash)
#
# For Linux, uncomment this:
#  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$ADTPRO_HOME"rxtx/Linux/i686-unknown-linux-gnu
#
# For OSX, uncomment these three lines:
   export TWEAK1="-Djava.library.path="
   export TWEAK2="rxtx/Mac_OS_X"
   export TWEAK=$TWEAK1$ADTPRO_HOME$TWEAK2
# (Also remember to run fixperm.sh in the rxtx directory for OSX...)
#
# For Solaris, uncomment this:
#  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$ADTPRO_HOME"rxtx/Solaris/sparc-solaris/sparc32-sun-solaris2.8
#
# Execute the thing.
# We want to execute Java (1), set a larger-than-default heap size (2), tell the OS where to find a 
# native library to support rxtx (3), set the classpath to include ADTPro (4) and RXTXcomm (5), 
# tell Java what the class to execute is, then finally put it all in the background.  To wit:
"$MY_JAVA_HOME"java -Xms256m -Xmx512m $TWEAK -cp "$ADTPRO_HOME"%ADTPRO_VERSION%:"$ADTPRO_HOME"rxtx/RXTXcomm.jar org.adtpro.ADTPro &
#               (1)     (2)     (2)     (3)                              (4)                            (5)            (6)        (7)