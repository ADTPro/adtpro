@echo off
SET ADTPRO_EXTRA_JAVA_PARMS=-Duser.language=es -Duser.country=MX
SET ADTPRO_HOME=%CD%\ADTPro-v.r.m\
cd %ADTPRO_HOME%
call adtpro.bat
cd ..