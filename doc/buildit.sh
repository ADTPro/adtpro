#!/bin/sh
rm -rf target
mvn site
cd target/site
perl -i.orig -p ../../htmlpassthrough.re index.html
perl -i.orig -p ../../htmlpassthrough.re bootstrap.html
perl -i.orig -p ../../htmlpassthrough.re bootstrapaudio.html
perl -i.orig -p ../../htmlpassthrough.re connectionsserial.html
perl -i.orig -p ../../htmlpassthrough.re bootstrap3.html
perl -i.orig -p ../../htmlpassthrough.re lc.html
cd ../..
