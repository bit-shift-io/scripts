#!/bin/bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/util.sh"

# amd NPU specific software
"$UTIL" -i xrt xrt-plugin-amdxdna
sudo tee /etc/security/limits.conf > /dev/null << EOL
* soft memlock unlimited
* hard memlock unlimited
EOL
echo "Reboot required for AMD NPU"

# amd rocm gpu
"$UTIL" -i rocblas hipblas rocm-smi-lib hsa-rocr
# sdks: rocm-hip-sdk or rocm-opencl-sdk
sudo usermod -aG render,video $USER
echo "Reboot required for AMD ROCM"

echo "Complete"
