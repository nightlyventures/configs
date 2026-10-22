# Vaultwarden behind Caddy

Caddy in front of Vaultwarden, both in Proxmox containers, with a real HTTPS certificate from a Cloudflare DNS challenge. Away from home the family reaches it through Tailscale.

- Video: [Replace Apple Passwords with Vaultwarden on Proxmox](https://youtu.be/_aY7uoH34yA)
- Write-up: [Self-Host Vaultwarden on Proxmox](https://www.nightlyventures.com/p/self-host-vaultwarden-proxmox-apple-passwords), with every step from the two containers to the family organization

Tested with Caddy 2.11.7 and Vaultwarden 1.37.4 (October 2026).

## Files

| File | What it does |
|---|---|
| `Caddyfile` | The site block: certificate through the Cloudflare DNS challenge, then a reverse proxy to Vaultwarden on port 8000. Two commented blocks cover the Tailscale-only and the public setup. |
| `caddy.env.example` | The Cloudflare API token, read from a file that only root can open. Also shows the DuckDNS variant. |
| `caddy-override.conf` | A systemd override for the Caddy service: loads `caddy.env` and starts Caddy without `--environ`, so the token stays out of the system log. |
| `tailscale-grants.example.json` | A grants section for the Tailscale access policy: you keep full access, family members reach Caddy on port 443 only. |

## Usage

1. Replace the placeholders:

| Placeholder | Replace with |
|---|---|
| `vault.example.com` | Your vault hostname |
| `VAULTWARDEN_LAN_IP` | The address of the Vaultwarden container |
| `YOUR_TOKEN` | The Cloudflare API token |
| `you@example.com`, `CADDY_TAILSCALE_IP` | Your Tailscale login and the Tailscale address of the Caddy container |

2. Put `Caddyfile` in `/etc/caddy/`, `caddy.env.example` at `/etc/caddy/caddy.env` and `caddy-override.conf` through `systemctl edit caddy`. Merge the grants into your existing Tailscale policy instead of pasting over it.
3. Check and restart: `caddy validate --config /etc/caddy/Caddyfile --envfile /etc/caddy/caddy.env`, then `systemctl restart caddy`.

## Things that go wrong

- Stock Caddy has no DNS provider modules. Build it with `xcaddy build --with github.com/caddy-dns/cloudflare` and check that `caddy list-modules --skip-standard` shows `dns.providers.cloudflare`.
- A 502 means Caddy can't reach Vaultwarden. Check the IP in `reverse_proxy`, that Vaultwarden listens on port 8000 without TLS, and that the firewall rule that accepts Caddy sits above the rule that drops everything else.
- Without `Zone > Zone > Read` on the Cloudflare token, the certificate request fails.
- The stock Caddy service prints every environment variable, including the token, to the system log. The override replaces `ExecStart` to prevent that.
- A narrow Tailscale grant doesn't cancel a broader one. Remove the default allow-all rule, and test with a family account.
- If the Caddy container's Tailscale key expires, syncing away from home stops for everyone. Disable key expiry for that machine.
