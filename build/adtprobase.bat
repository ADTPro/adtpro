@REM
@REM ADTPro - Windows startup batch file
@REM
@REM You can set two variables here:
@REM   1. %JAVA_HOME% - to pick a particular java to run under
@REM   2. %ADTPRO_HOME% - to say where you installed ADTPro
@REM
@REM e.g. uncomment (remove the "@REM" from in front) and customize
@REM      the following two SET statements.  
@REM Note: They must have a trailing backslash as in the examples!

@REM SET ADTPRO_HOME=C:\src\workspace\311\adtpro\build\
@REM SET MY_JAVA_HOME=C:\Progra~1\IBM\Java142\bin\

@REM Note: The following statement needs a trailing backslash!
@SET ADTPRO_HOME=%CD%

@PATH=%PATH%;%ADTPRO_HOME%\lib\rxtx\Windows\i368-mingw32
@SET CWD=%CD%
@CD %ADTPRO_HOME%\lib
@start /min %MY_JAVA_HOME%java -Xms128m -cp %ADTPRO_VERSION%;rxtx\RXTXcomm.jar org.adtpro.ADTPro
@CD %CWD%