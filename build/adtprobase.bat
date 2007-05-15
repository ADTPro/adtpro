@REM
@REM ADTPro - Windows startup batch file
@REM
@REM You can set two variables here:
@REM   1. %JAVA_HOME% - to pick a particular java to run under
@REM   2. %ADTPRO_HOME% - to say where you installed ADTPro
@REM
@REM e.g.
@REM
@SET ADTPRO_HOME=.\
@REM SET ADTPRO_HOME=C:\src\workspace\311\adtpro\build\  (need final backslash)
@REM SET MY_JAVA_HOME=C:\Progra~1\IBM\Java142\bin\ (need final backslash)
@REM
@start /min %MY_JAVA_HOME%java -Xms128m -cp %ADTPRO_HOME%%ADTPRO_VERSION%;%ADTPRO_HOME%lib\RXTXcomm.jar org.adtpro.ADTPro
