@echo off
SET ADTPRO_EXTRA_JAVA_PARMS=-Duser.language=pt -Duser.country=BR
SET ADTPRO_HOME=%CD%\ADTPro-v.r.m\
cd %ADTPRO_HOME%
call adtpro.bat
cd ..