#!/bin/bash

./util.sh -i brother-mfc-j4440dw

lpadmin -p Brother -v lpd://brother.lan/BINARY_P1 -P /usr/share/cups/model/Brother/brother_mfcj4440dw_printer_en.ppd

lpstat -v
