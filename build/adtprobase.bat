@REM
@REM ADTPro - Windows startup batch file
@REM
@REM You can set two variables here:
@REM   1. %JAVA_HOME% - to pick a particular java to run under
@REM   2. %ADTPRO_HOME% - to say where you installed ADTPro
@REM
@REM e.g. uncomment (remove the "@REM" from in front) and customize
@REM      the following SET statements.  
@REM Note: They must have a trailing backslash as in the examples!

@SET ADTPRO_HOME=%CD%\
@REM SET ADTPRO_HOME=C:\src\workspace\311\adtpro\build\
@REM SET MY_JAVA_HOME=C:\Progra~1\IBM\Java142\bin\

@PATH=%PATH%;%ADTPRO_HOME%\lib\rxtx\Windows\i368-mingw32
@start /min %MY_JAVA_HOME%java -Xms128m -Xmx256m -cp %ADTPRO_HOME%%ADTPRO_VERSION%;%ADTPRO_HOME%rxtx\RXTXcomm.jar org.adtpro.ADTPro