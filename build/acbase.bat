@echo off
REM
REM ADTPro - AppleCommander command line invocation batch file
REM

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

start /min %MY_JAVA_HOME%java -Xms128m -Xmx256m -jar "%ADTPRO_HOME%lib\AppleCommander\AppleCommander-%AC_VERSION%.jar" %*