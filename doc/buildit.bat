@REM
@REM Sorry, this is hopelessly tied to my environment...
@REM I hope folks don't really want to build the doc themselves.
@REM
call c:\dev\env
rmdir /q /s target
call mvn site
cd target\site
perl -i.orig -p ..\..\htmlpassthrough.re webring.html
perl -i.orig -p ..\..\htmlpassthrough.re index.html
perl -i.orig -p ..\..\htmlpassthrough.re bootstrap.html
perl -i.orig -p ..\..\htmlpassthrough.re bootstrapaudio.html
perl -i.orig -p ..\..\htmlpassthrough.re connectionsserial.html
perl -i.orig -p ..\..\htmlpassthrough.re bootstrap3.html
perl -i.orig -p ..\..\htmlpassthrough.re lc.html
cd ..\..
