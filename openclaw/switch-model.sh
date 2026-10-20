#!/bin/bash
# Switch the primary OpenClaw model and restart the gateway.
# Usage: ./switch-model.sh {coder|qwen3|glm|gpt-oss}
set -euo pipefail

CONFIG="$HOME/.openclaw/openclaw.json"

case "${1:-}" in
  coder|qwen3-coder)       MODEL="ollama/qwen3-coder-32k" ;;
  qwen3|qwen3-14b)         MODEL="ollama/qwen3-32k" ;;
  glm|glm-4.7-flash)       MODEL="ollama/glm-4.7-flash-32k" ;;
  gpt-oss|gpt-oss-20b)     MODEL="ollama/gpt-oss-20b-32k" ;;
  *)
    echo "Usage: $0 {coder|qwen3|glm|gpt-oss}"
    exit 1
    ;;
esac

sed -i "s|\"primary\": \"ollama/[^\"]*\"|\"primary\": \"$MODEL\"|" "$CONFIG"
echo "-> $MODEL"

systemctl --user restart openclaw-gateway
systemctl --user --no-pager status openclaw-gateway | head -3
