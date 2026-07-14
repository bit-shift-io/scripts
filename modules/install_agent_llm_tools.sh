#!/bin/bash


echo "installing opencode..."
./util.sh -i opencode

opencode run "init prompt"

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
        },
      }
    }
  }
}

EOL

echo "Complete"
