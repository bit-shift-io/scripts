#!/bin/bash

# amd NPU specific software
./util.sh -i xrt xrt-plugin-amdxdna
sudo tee /etc/security/limits.conf > /dev/null << EOL
* soft memlock unlimited
* hard memlock unlimited
EOL
echo "Reboot required for AMD NPU"

# amd rocm gpu
./util.sh -i rocblas hipblas rocm-smi-lib hsa-rocr
# sdks: rocm-hip-sdk or rocm-opencl-sdk
sudo usermod -aG render,video $USER
echo "Reboot required for AMD ROCM"

echo "Complete"
