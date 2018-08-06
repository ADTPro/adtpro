#!/bin/sh
#
# ADTPro - *nix startup shell script
#
# Note:
#   Invoke with the name of the communications button to push
#   in order to start with that mode active (i.e. './adtpro.sh ethernet')
#
# You can set two variables here:
#   1. $MY_JAVA_HOME - to pick a particular java to run under
#   2. $ADTPRO_HOME - to say where you installed ADTPro
#
# Set default ADTPRO_HOME to be the fully qualified
# current working directory.
export ADTPRO_HOME="`dirname \"$0\"`"
cd "$ADTPRO_HOME"
export ADTPRO_HOME=`pwd`

# Uncomment and modify one or both of the lines below if you
# want to specify a particular location for Java or ADTPro.
# NOTE: be sure to include a trailing slash on MY_JAVA_HOME,
# but not on ADTPRO_HOME.
#
# export MY_JAVA_HOME=/usr/local/java/bin/
# export ADTPRO_HOME=~/myuser/adtpro

OS=`uname`
OS_ARCH=`uname -p`

# For Linux, use this:
if [ "$OS" = "Linux" ]; then
  if [ -f /usr/bin/raspi-config ]; then
    export RXTXLIB=lib/rxtx/%RXTX_VERSION%/arm
    ADTPRO_EXTRA_JAVA_PARMS="-Dgnu.io.rxtx.SerialPorts=/dev/ttyUSB0:/dev/ttyAMA0"
  elif [ "$OS_ARCH" = "i686" ]; then
    export RXTXLIB=lib/rxtx/%RXTX_VERSION%/i686-pc-linux-gnu
  else
    if [ "$OS_ARCH" = "i386" ]; then
      export RXTXLIB=lib/rxtx/%RXTX_VERSION%/i686-pc-linux-gnu
    else  
      export RXTXLIB=lib/rxtx/%RXTX_VERSION%/x86_64-unknown-linux-gnu
    fi
  fi
fi

# For OSX, use this:
if [ "$OS" = "Darwin" ]; then
  if [ "$OS_ARCH" = "powerpc" ]; then
    export RXTXLIB=lib/rxtx/%RXTX_VERSION_OLD%/Mac_OS_X
  else
    export RXTXLIB=lib/rxtx/%RXTX_VERSION%/mac-10.5
  fi
fi

# For Solaris, use this:
if [ "$OS" = "SunOS" ]; then
  export RXTXLIB=lib/rxtx/%RXTX_VERSION%/sparc-sun-solaris2.10-32
fi

# Set up the library location.
export TWEAK1="-Djava.library.path="
export TWEAK="$TWEAK1$ADTPRO_HOME/$RXTXLIB"

if [ "$1x" = "headlessx" ]; then
  shift
  if [ "$1x" = "x" ] || [ ! -f /usr/bin/xvfb-run ]; then
    if [ ! -f /usr/bin/xvfb-run ]; then
      echo "Headless operation requires xvfb."
    else
      echo "usage: adtpro.sh [ headless ] [ serial | ethernet | audio | localhost ]"
    fi
    exit 1
  else
    HEADLESS="xvfb-run --auto-servernum "
  fi
fi

$HEADLESS"$MY_JAVA_HOME"java -Xms256m -Xmx512m "$TWEAK" $ADTPRO_EXTRA_JAVA_PARMS -cp ./lib/%ADTPRO_VERSION%:./"$RXTXLIB"/../RXTXcomm.jar:./lib/AppleCommander/AppleCommander-%AC_VERSION%.jar org.adtpro.ADTPro $*
