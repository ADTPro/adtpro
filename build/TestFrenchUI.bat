@echo off
SET ADTPRO_EXTRA_JAVA_PARMS=-Duser.language=fr -Duser.country=FR
SET ADTPRO_HOME=%CD%\ADTPro-v.r.m\
cd %ADTPRO_HOME%
call adtpro.bat
cd ..