#!/bin/bash
# Create an Ollama model for every *.Modelfile in this folder.
# The model is named after the file: qwen3-coder-32k.Modelfile -> qwen3-coder-32k
# Pull the base models (FROM lines) first.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

for mf in "$DIR"/*.Modelfile; do
  name="$(basename "$mf" .Modelfile)"
  echo "-> $name"
  ollama create "$name" -f "$mf"
done

echo
echo "num_ctx per model:"
for mf in "$DIR"/*.Modelfile; do
  name="$(basename "$mf" .Modelfile)"
  printf '%s: ' "$name"
  ollama show "$name" --modelfile | grep -i num_ctx || echo "not set"
done
