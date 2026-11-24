# PVE webhook target `hass-backup`

Datacenter → Notifications → Notification Targets → Edit `hass-backup`:

| Field | Value |
|---|---|
| Method/URL | `POST` `http://HASS_IP:8123/api/webhook/pbs_backup_complete` |
| Header | `Content-Type: application/json` |
| Body | see below |

```
{"severity": "{{ severity }}"}
```

PVE fills in `info` for a successful backup and `error` for a failed one. The Nightly Backup Loop reads it from the webhook and sends a "Backup failed" notification for anything other than `info`. Without this body, the automation can't tell a failed backup from a good one: PVE sends the webhook in both cases.
