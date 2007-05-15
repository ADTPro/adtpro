#\!/bin/sh
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
# For OSX, uncomment this:
   export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$ADTPRO_HOME"rxtx/Mac_OS_X
# (Also remember to run fixperm.sh in the rxtx directory for OSX...)
#
# For Solaris, uncomment this:
#  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$ADTPRO_HOME"rxtx/Solaris/sparc-solaris/sparc32-sun-solaris2.8
#
# Execute the thing:
"$MY_JAVA_HOME"java -Xms256m -cp "$ADTPRO_HOME"%ADTPRO_VERSION%:"$ADTPRO_HOME"rxtx/RXTXcomm.jar org.adtpro.ADTPro &
