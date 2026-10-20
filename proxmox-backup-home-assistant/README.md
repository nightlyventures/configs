# Proxmox backup with Home Assistant

Home Assistant wakes a Proxmox Backup Server (PBS) at 03:00, starts a backup on Proxmox VE (PVE) and shuts PBS down when the backup is complete.

- Video: [Two NUCs Beat My All-in-One Homelab](https://youtu.be/GT0eXgGsZFI)
- Write-up: [Automating Proxmox Backups with Home Assistant](https://www.nightlyventures.com/p/automating-proxmox-backups-with-home-assistant), with the PBS, PVE and Home Assistant settings that these files rely on

Tested with Home Assistant 2026.10, Proxmox VE 9.2 and Proxmox Backup Server 4.1.

## Files

| File | What it does |
|---|---|
| `configuration.yaml` | Enables Wake on LAN and adds two REST commands: one starts a backup on PVE, one shuts PBS down. |
| `automations.yaml` | The *PBS Backup Cycle* automation: wake PBS, wait for it, start the backup, wait for the PVE webhook, shut PBS down. |
| `secrets.yaml.example` | The two API token lines for Home Assistant's `secrets.yaml`. |

## Usage

1. Make the settings in the write-up first: the PBS and PVE API tokens, PBS as storage in PVE, and the webhook notification in PVE.
2. Add `configuration.yaml` to your Home Assistant configuration, add the two lines of `secrets.yaml.example` to your `secrets.yaml`, and add the automation from `automations.yaml`.
3. Replace the placeholders:

| Placeholder | Replace with |
|---|---|
| `PVE_IP`, `PBS_IP` | The IP addresses of PVE and PBS |
| `PBS_MAC` | The MAC address of the PBS machine |
| `binary_sensor.pbs_online` | The entity ID of the Ping sensor for PBS |
| `YOUR_PVE_TOKEN_SECRET`, `YOUR_PBS_TOKEN_SECRET` | The secrets of the `hass` API tokens |

The URL in `pve_start_backup` uses `pve` as the node name. Change it if your PVE node has another name.

## Things that go wrong

- PVE and PBS write the token differently: `PVEAPIToken=root@pam!hass=secret` uses an equals sign, `PBSAPIToken=root@pam!hass:secret` uses a colon. A wrong separator gives a 401.
- The PBS token needs two permissions: `Admin` on `/` for the shutdown and `DatastoreAdmin` on the datastore for the backups. A missing permission gives a 401 that doesn't say which one.
- The Ping integration builds the entity ID from the host you enter. Look it up under Settings → Devices & Services → Entities and use it in the automation.
- A 506 error means the content type is wrong. Both REST commands set `application/x-www-form-urlencoded` because Home Assistant sends `application/octet-stream` by default.
- If PBS uses a self-signed certificate, PVE needs its fingerprint when you add PBS as storage.
- If PBS doesn't wake, check that ErP is disabled and Wake on LAN is enabled for S4/S5 in the BIOS.
- The automation stops without starting a backup if the Ping sensor is still off 10 minutes after the magic packet. It shuts PBS down after 4 hours even if the backup webhook never arrives.
