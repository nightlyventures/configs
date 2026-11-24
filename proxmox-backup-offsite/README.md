# Offsite Proxmox Backup Server

A second Proxmox Backup Server (PBS) at another house, on a ZimaBoard 2 with two mirrored drives. It pulls a copy of the home PBS every night through a WireGuard tunnel. Home Assistant starts the sync after the nightly backup and sends a notification when a backup fails or goes stale.

This builds on [`proxmox-backup-home-assistant/`](../proxmox-backup-home-assistant/): the automation here is the extended version of the one in that folder.

- Video: [VIDEO_TITLE](VIDEO_URL)
- Write-up: [Offsite Proxmox Backups with a ZimaBoard 2](https://www.nightlyventures.com/p/offsite-proxmox-backups-zimaboard-2), with the PBS users, tokens, sync job and retention settings that these files rely on

Tested with Proxmox Backup Server 4.2 (offsite) and 4.1 (home), Proxmox VE 9.2, Home Assistant 2026.11 and UniFi Network 11.0 (November 2026).

## Files

| File | What it does |
|---|---|
| `offsite-pbs/wg0.conf.example` | The WireGuard client config on the offsite PBS, with the three changes to the config that UniFi generates. |
| `offsite-pbs/zfs.conf` | Caps the ZFS read cache at 3 GiB, so the 8 GB of RAM is left for PBS. |
| `unifi-firewall.md` | The six firewall policies that limit what the offsite PBS and the home network can reach. |
| `pve/storage.cfg.example` | The home PBS by hostname without a fingerprint, and the offsite PBS as read-only restore storage. |
| `pve/hass-backup-webhook.md` | The PVE webhook target that sends the backup result to Home Assistant. |
| `home-assistant/configuration.yaml` | REST commands: start the backup, start the offsite sync, read the sync status, list the offsite backup groups, list running tasks, shut the home PBS down. |
| `home-assistant/automations.yaml` | *Nightly Backup Loop* (backup, offsite sync, notifications, shutdown) and *Backup freshness check* (daily at 09:00). |
| `home-assistant/secrets.yaml.example` | The three API token lines for Home Assistant's `secrets.yaml`. |

## Usage

1. Install PBS on the offsite machine, create the ZFS mirror and add `offsite-pbs/zfs.conf`.
2. Create the WireGuard client in UniFi, change the downloaded config as in `wg0.conf.example`, and add the firewall policies from `unifi-firewall.md`.
3. Create the users, tokens, remote and pull sync job from the write-up. Leave the sync job without a schedule: Home Assistant starts it.
4. Add the REST commands, the secrets and the automations to Home Assistant, and change the PVE webhook target.
5. Replace the placeholders:

| Placeholder | Replace with |
|---|---|
| `OFFSITE_PBS_IP` | The tunnel address of the offsite PBS |
| `HOME_PBS_IP`, `PVE_IP`, `HASS_IP`, `MAC_IP` | The LAN addresses at home |
| `HOME_SUBNET` | Your home network, for example `192.168.1.0` |
| `HOME_PBS_MAC` | The MAC address of the home PBS, for Wake-on-LAN |
| `SYNC_JOB_ID` | The ID of the sync job on the offsite PBS (Datastore → Sync Jobs) |
| `vpn.example.com`, `pbs.example.com` | Your WireGuard endpoint and the hostname of the home PBS |
| `YOUR_DATASTORE` | The name of the datastore on the home PBS |
| `notify.mobile_app_YOUR_PHONE` | Your notify action |
| `binary_sensor.pbs_online` | The entity ID of the Ping sensor for the home PBS |
| `YOUR_*` | Keys and token secrets |

## Things that go wrong

- No handshake and no error: after creating or changing the client in UniFi, press Apply.
- wg-quick fails on the `DNS =` line from UniFi, because PBS has no resolvconf. Remove it.
- With the home subnet in `AllowedIPs` while the box is still at home, it sends its own LAN into the tunnel, and SSH drops. Use single `/32` addresses at home and switch to the subnet just before it leaves.
- Home Assistant sends `application/octet-stream` without a `content_type`. PBS rejects it without starting a task, and Home Assistant only reports that the answer "could not be decoded as JSON".
- The sync job ID goes in the URL path, not in the payload.
- The PBS token header uses a colon before the secret (`PBSAPIToken=ha@pbs!trigger:SECRET`). PVE uses an equals sign.
- With privilege separation, a token only gets what its user also has. Add each permission to the user and to the token.
- The `ha@pbs!trigger` token needs DatastoreBackup and DatastoreAudit on `/datastore/offsite` and RemoteSyncOperator on `/remote`. Without the last one: "permission check failed".
- Backup groups that already exist under another owner fail the owner check on the first sync. Use Change Owner on those groups.
- A fingerprint pinned in PVE or in the remote breaks the connection when the certificate is renewed. The backups then fail every night, and PVE still sends the webhook.
- A container restored from the offsite copy keeps the IP, hostname and Start at boot setting of the original. Disconnect its network before you start it.

## Security notes

- The offsite datastore is not encrypted, so whoever has the box has your backups. It also holds the WireGuard key and the `sync@pbs!offsite` token. If it's lost or stolen, delete its WireGuard client in UniFi and remove the `sync@pbs!offsite` token on the home PBS: that closes the tunnel and the read access to your home datastore. If you'd rather encrypt, set an encryption key on the PBS storage in PVE, and keep a copy of the key outside your homelab.
- The tokens from the Nightly Backup Loop are powerful. `root@pam!hass` on PVE, without privilege separation, is full root, and on the home PBS it has Admin. Whoever takes over Home Assistant can delete your guests and your local backups. The offsite copy survives that: Home Assistant's token on the offsite PBS has DatastoreBackup and DatastoreAudit, which can't delete snapshots, and PVE's `pve@pbs!restore` token is read-only. To narrow the PVE side, use a token with privilege separation and only VM.Backup on `/vms` and Datastore.AllocateSpace on `/storage/pbs`. I haven't tested that variant.
- The webhook ID works like a password. Anyone on your network who knows it can report a "successful" backup. Use a long random `webhook_id` in the automation and the PVE target. The freshness check catches a faked success the next morning anyway.
- The REST commands use `verify_ssl: false` because PBS starts with a self-signed certificate. If your home PBS has a public certificate, call it by hostname and set `verify_ssl: true`. Traffic to the offsite PBS goes through the WireGuard tunnel.
