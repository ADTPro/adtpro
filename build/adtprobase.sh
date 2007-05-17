#!/bin/sh
#
# ADTPro - *nix startup shell script
#
# You can set two variables here:
#   1. $MY_JAVA_HOME - to pick a particular java to run under
#   2. $ADTPRO_HOME - to say where you installed ADTPro
#
# e.g. uncomment and modify one or both of the lines below:
#
# export MY_JAVA_HOME=/usr/local/java/bin/ (need final slash)
# export ADTPRO_HOME=~/myuser/adtpro/  (need final slash)
#
OS=`uname`

# For Linux, use this:
if [ "$OS" = "Linux" ]; then
  export RXTXLIB=rxtx/Linux/i686-unknown-linux-gnu
fi

# For OSX, use this:
# (Also remember to run fixperm.sh in the rxtx directory once on OSX...)
if [ "$OS" = "Darwin" ]; then
  here="`dirname \"$0\"`"
  cd "$here"
  export RXTXLIB=rxtx/Mac_OS_X
fi

# For Solaris, use this:
if [ "$OS" = "Solaris" ]; then
  export RXTXLIB=rxtx/Solaris/sparc-solaris/sparc32-sun-solaris2.8
fi

# Set up the library location.
export TWEAK1="-Djava.library.path="
export TWEAK=$TWEAK1$ADTPRO_HOME$RXTXLIB

# Set up a comfortable Java execution environment.
# We want to execute Java (1), set a larger-than-default heap size (2),
# tell the OS where to find a native library to support rxtx (3), set
# the classpath to include ADTPro (4) and RXTXcomm (5), tell Java what
# the class to execute is, then finally put it all in the background (7).  
# To wit:
"$MY_JAVA_HOME"java -Xms256m -Xmx512m $TWEAK -cp "$ADTPRO_HOME"%ADTPRO_VERSION%:"$ADTPRO_HOME"rxtx/RXTXcomm.jar org.adtpro.ADTPro &
#               (1)     (2)     (2)     (3)                              (4)                            (5)            (6)        (7)