#!/bin/sh
mvn site
cd target/site
perl -i.orig -p ../../htmlpassthrough.re webring.html
perl -i.orig -p ../../htmlpassthrough.re index.html
perl -i.orig -p ../../htmlpassthrough.re bootstrap.html
perl -i.orig -p ../../htmlpassthrough.re bootstrapaudio.html
perl -i.orig -p ../../htmlpassthrough.re connectionsserial.html
perl -i.orig -p ../../htmlpassthrough.re bootstrap3.html
cd ../..
