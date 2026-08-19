#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

"$UTIL" -i brother-mfc-j4440dw sane-airscan

lpadmin -p Brother -v lpd://brother.lan/BINARY_P1 -P /usr/share/cups/model/Brother/brother_mfcj4440dw_printer_en.ppd

lpstat -v
