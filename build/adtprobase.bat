@echo off
REM
REM ADTPro - Windows startup batch file
REM
REM Note:
REM   Invoke with the name of the communications button to push
REM   in order to start with that mode active (i.e. 'adtpro ethernet')

SET ADTPRO_HOME=%CD%\

REM You can set two variables here:
REM   1. %JAVA_HOME% - to pick a particular java to run under
REM   2. %ADTPRO_HOME% - to say where you installed ADTPro
REM
REM e.g. uncomment (remove the "REM" from in front of) and
REM      customize the following SET statements.  
REM Note: They must have a trailing backslash as in the examples!
REM 
REM SET ADTPRO_HOME=C:\src\workspace\35\adtpro\build\
REM SET MY_JAVA_HOME=C:\Progra~1\IBM\Java142\bin\

:start
CD "%ADTPRO_HOME%"
start /min %MY_JAVA_HOME%java -Xms128m -Xmx256m %ADTPRO_EXTRA_JAVA_PARMS% -cp "%ADTPRO_HOME%lib\%ADTPRO_VERSION%";"%ADTPRO_HOME%lib\AppleCommander\AppleCommander-%AC_VERSION%.jar";"%ADTPRO_HOME%lib\jssc\jssc-2.9.2.jar" org.adtpro.ADTPro %*
