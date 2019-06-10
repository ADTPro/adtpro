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
export ADTPRO_HOME="`pwd`/"

# Uncomment and modify one or both of the lines below if you
# want to specify a particular location for Java or ADTPro.
# Note: They must have a trailing backslash as in the examples!
#
# export MY_JAVA_HOME=/usr/local/java/bin/
# export ADTPRO_HOME=~/myuser/adtpro/

OS=`uname`
OS_ARCH=`uname -p`
OS_MACHINE=`uname -m`

# For Linux, use this:
if [ "$OS" = "Linux" ]; then
  ADTPRO_EXTRA_JAVA_PARMS="-Dgnu.io.rxtx.SerialPorts=/dev/ttyUSB0:/dev/ttyAMA0"
  # Prefer OS-supplied librxtxSerial.so
  if [ -a "/usr/lib/librxtxSerial.so" ]; then
    RXTXLIB=/usr/lib
  elif [ "$OS_MACHINE" = "armv7l" ]; then
    RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION%/arm"
  elif [ "$OS_MACHINE" = "i386" -o "$OS_MACHINE" = "i686" ]; then
    RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION%/i686-pc-linux-gnu"
  elif [ "$OS_MACHINE" = "x86_64" ]; then
    RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION%/x86_64-unknown-linux-gnu/librxtxSerial.so"
  else
    echo "Unsupported Linux architecture ${OS_ARCH}."
    exit
  fi
fi

# For OSX, use this:
if [ "$OS" = "Darwin" ]; then
  if [ "$OS_ARCH" = "powerpc" ]; then
    export RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION_OLD%/Mac_OS_X"
  else
    export RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION%/mac-10.5"
  fi
fi

# For Solaris, use this:
if [ "$OS" = "SunOS" ]; then
  export RXTXLIB="${ADTPRO_HOME}lib/rxtx/%RXTX_VERSION%/sparc-sun-solaris2.10-32"
fi

# Set up the library location.
TWEAK="-Djava.library.path="
TWEAK+="${RXTXLIB}"

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

CLASSPATH="${ADTPRO_HOME}lib/ADTPro-2.0.3.jar"
CLASSPATH+=":/usr/share/java/rxtx/RXTXcomm.jar"
CLASSPATH+=":${ADTPRO_HOME}lib/AppleCommander/AppleCommander-1.3.5.13-ac.jar"

${HEADLESS}"${MY_JAVA_HOME}"java -Xms256m -Xmx512m "$TWEAK" "${ADTPRO_EXTRA_JAVA_PARMS}" \
	-cp "${CLASSPATH}" org.adtpro.ADTPro \
	$*
