#!/bin/bash

cd package
zip -r ../cec_kwin.zip .
cd ..

kpackagetool6 --type=KWin/Script -i ./cec_kwin.zip
