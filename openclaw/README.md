# OpenClaw

Files for running [OpenClaw](https://docs.openclaw.ai) in a Proxmox VM with local models through Ollama.

- Video: [Self-Host Moltbot in a Proxmox VM (The Secure Way)](https://youtu.be/DG7p0BfO6UI), with the [write-up](https://www.nightlyventures.com/p/self-host-moltbot-on-proxmox) for the VM and install steps
- Video: [3 GPUs, 1 Local AI Agent. Here's Where It Breaks.](https://youtu.be/-fmpLgSs2M8), with the [write-up](https://www.nightlyventures.com/p/run-openclaw-with-local-models-via-ollama) for the Ollama setup

Tested with OpenClaw 2026.1.29 (January–February 2026). Config keys may have changed since; check the [OpenClaw docs](https://docs.openclaw.ai/gateway/local-models) if something doesn't load.

## Files

| File | What it does |
|---|---|
| `ollama/*.Modelfile` | Raise the context window. `-32k` for an RTX 3090 (24 GB), `qwen3-16k` for an RTX 3060 (12 GB). |
| `ollama/apply-modelfiles.sh` | Creates a model for every Modelfile, named after the file, and prints its `num_ctx`. |
| `ollama/override.conf` | Ollama environment variables as a systemd drop-in. |
| `openclaw.example.json` | The model and agent part of `~/.openclaw/openclaw.json`. |
| `switch-model.sh` | Switches the primary model and restarts the gateway. |

## Usage

On the Ollama host:

```bash
ollama pull qwen3-coder      # and any other base models you want
cd ollama && ./apply-modelfiles.sh

sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo cp override.conf /etc/systemd/system/ollama.service.d/
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

On the OpenClaw VM, run `openclaw onboard` first, then merge `models` and `agents` from `openclaw.example.json` into `~/.openclaw/openclaw.json`. Set `baseUrl` to your Ollama host.

Two things that break silently:

- The model `id` must be the name you created from the Modelfile (`qwen3-coder-32k`), not the base model. The base model still runs with Ollama's default context, which is smaller than OpenClaw's system prompt.
- `contextWindow` must match `num_ctx` in the Modelfile: `32768` for the `-32k` models, `16384` for `qwen3-16k`.

Switch models with `./switch-model.sh coder` (or `qwen3`, `glm`, `gpt-oss`).

## Intel iGPU

No dedicated GPU? See [llama-cpp-sycl](https://github.com/nightlyventures/llama-cpp-sycl). Fine for chat, too slow for an agent.
