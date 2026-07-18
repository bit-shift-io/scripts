#!/bin/bash


./util.sh -i opencode gemini-cli claude-code openai-codex

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

# open code config
# echo "installing opencode..."
opencode --version

echo "opencode config..."
tee $HOME/.config/opencode/opencode.json > /dev/null << EOL
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "llamacpp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "llama-server",
      "options": {
        "baseURL": "http://blaptop.lan:8080/v1"
      },
      "models": {
        "qwen2.5-coder-7b": {
          "name": "qwen2.5-coder-7b"
        },
        "qwen3-14b": {
          "name": "qwen3-14b"
        },
        "qwen3-coder-30b": {
          "name": "qwen3-coder-30b"
        },
        "qwen3.6-35b": {
          "name": "qwen3.6-35b"
        }
      }
    }
  }
}
EOL

echo "Complete"
