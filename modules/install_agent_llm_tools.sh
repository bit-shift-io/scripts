#!/bin/bash


./util.sh -i opencode claude-code openai-codex antigravity-cli
# dead: gemini-cli

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
echo "opencode config..."
opencode --version
tee $HOME/.config/opencode/opencode.json > /dev/null << EOL
{
  "\$schema": "https://opencode.ai/config.json",
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


# claude config
echo "claude config..."
tee $HOME/.claude/settings.json > /dev/null << EOL
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8080/v1",
    "ANTHROPIC_API_KEY": "local-llama",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "qwen3-coder-30b",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "qwen2.5-coder-7b",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "qwen3.6-35b"
  }
}
EOL


# codex config
echo "codex config..."
tee $HOME/.codex/config.toml > /dev/null << EOL
# Default settings
model = "qwen3-coder-30b.gguf"
model_provider = "llama-server"
model_catalog_json = "$HOME/.codex/models.json"

[model_providers.llama-server]
name = "llama-server"
base_url = "http://localhost:8080/v1"
wire_api = "responses"

# Define your model profiles
[profiles.coder-7b]
model = "qwen2.5-coder-7b.gguf"
model_provider = "llama-server"

[profiles.qwen3-14b]
model = "qwen3-14b.gguf"
model_provider = "llama-server"

[profiles.qwen3-35b]
model = "qwen3.6-35b.gguf"
model_provider = "llama-server"

[profiles.qwen3-30b]
model = "qwen3-coder-30b.gguf"
model_provider = "llama-server"
model_reasoning_effort = "high"
personality = "pragmatic"
EOL

tee $HOME/.codex/models.json > /dev/null << EOL
{
  "models": [
    {
      "slug": "qwen2.5-coder-7b.gguf",
      "display_name": "Qwen 2.5 Coder 7B",
      "context_window": 131072,
      "max_context_window": 131072,
      "effective_context_window_percent": 95,
      "auto_compact_token_limit": null,
      "visibility": "list",
      "shell_type": "default",
      "supported_in_api": true,
      "priority": 10,
      "default_reasoning_level": "none",
      "supported_reasoning_levels": [
        { "effort": "none", "description": "Standard" }
      ],
      "base_instructions": "",
      "supports_reasoning_summaries": false,
      "default_reasoning_summary": "none",
      "support_verbosity": false,
      "truncation_policy": { "mode": "bytes", "limit": 10000 },
      "supports_parallel_tool_calls": true,
      "experimental_supported_tools": [],
      "input_modalities": ["text"]
    },
    {
      "slug": "qwen3-14b.gguf",
      "display_name": "Qwen 3 14B",
      "context_window": 131072,
      "max_context_window": 131072,
      "effective_context_window_percent": 95,
      "auto_compact_token_limit": null,
      "visibility": "list",
      "shell_type": "default",
      "supported_in_api": true,
      "priority": 20,
      "default_reasoning_level": "none",
      "supported_reasoning_levels": [
        { "effort": "none", "description": "Standard" }
      ],
      "base_instructions": "",
      "supports_reasoning_summaries": false,
      "default_reasoning_summary": "none",
      "support_verbosity": false,
      "truncation_policy": { "mode": "bytes", "limit": 10000 },
      "supports_parallel_tool_calls": true,
      "experimental_supported_tools": [],
      "input_modalities": ["text"]
    },
    {
      "slug": "qwen3.6-35b.gguf",
      "display_name": "Qwen 3.6 35B",
      "context_window": 131072,
      "max_context_window": 131072,
      "effective_context_window_percent": 95,
      "auto_compact_token_limit": null,
      "visibility": "list",
      "shell_type": "default",
      "supported_in_api": true,
      "priority": 30,
      "default_reasoning_level": "none",
      "supported_reasoning_levels": [
        { "effort": "none", "description": "Standard" }
      ],
      "base_instructions": "",
      "supports_reasoning_summaries": false,
      "default_reasoning_summary": "none",
      "support_verbosity": false,
      "truncation_policy": { "mode": "bytes", "limit": 10000 },
      "supports_parallel_tool_calls": true,
      "experimental_supported_tools": [],
      "input_modalities": ["text"]
    },
    {
      "slug": "qwen3-coder-30b.gguf",
      "display_name": "Qwen 3 Coder 30B",
      "context_window": 131072,
      "max_context_window": 131072,
      "effective_context_window_percent": 95,
      "auto_compact_token_limit": null,
      "visibility": "list",
      "shell_type": "default",
      "supported_in_api": true,
      "priority": 40,
      "default_reasoning_level": "none",
      "supported_reasoning_levels": [
        { "effort": "none", "description": "Standard" },
        { "effort": "high", "description": "Pragmatic Reasoning" }
      ],
      "base_instructions": "",
      "supports_reasoning_summaries": true,
      "default_reasoning_summary": "none",
      "support_verbosity": false,
      "truncation_policy": { "mode": "bytes", "limit": 10000 },
      "supports_parallel_tool_calls": true,
      "experimental_supported_tools": [],
      "input_modalities": ["text"]
    }
  ]
}

EOL

echo "Complete"
