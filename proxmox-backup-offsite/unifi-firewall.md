# UniFi firewall rules for the offsite PBS

Zone-based firewall on a UniFi gateway (tested on a UDM-SE with Network 11.0). The offsite PBS sits in the VPN zone with one tunnel address, `OFFSITE_PBS_IP`. Every rule matches that one address, so other VPN clients are not affected.

Settings → Zones → Create Policy:

| Name | Action | Source | Destination | Port | Connection state |
|---|---|---|---|---|---|
| Offsite PBS → Home PBS (8007) | Allow | VPN, `OFFSITE_PBS_IP` | Internal, `HOME_PBS_IP` | TCP 8007 | All |
| Home Assistant → Offsite PBS (8007) | Allow | Internal, `HASS_IP` | VPN, `OFFSITE_PBS_IP` | TCP 8007 | All |
| PVE → Offsite PBS (8007) | Allow | Internal, `PVE_IP` | VPN, `OFFSITE_PBS_IP` | TCP 8007 | All |
| Mac → Offsite PBS (management) | Allow | Internal, your computer (by MAC address) | VPN, `OFFSITE_PBS_IP` | TCP 8007, 22 | All |
| Block Offsite PBS → Internal | Block | VPN, `OFFSITE_PBS_IP` | Internal, any | any | New |
| Block Internal → Offsite PBS | Block | Internal, any | VPN, `OFFSITE_PBS_IP` | any | New |

UniFi adds the return rules for the allow rules itself.

## Things that go wrong

- A block rule with Connection State *All* also blocks the replies to traffic you allowed. Set it to Custom → New.
- The policy table sorts by name, not by the order in which rules are evaluated. The real order is the ID column: within a zone pair, the lowest ID goes first.
- Reorder didn't work for me. Deleting and recreating the block rule did: a new rule gets the highest ID in its zone pair, so it ends up below the allow rules.
- The firewall is only half of it. A device reaches the offsite PBS through the tunnel only if its address is also in `AllowedIPs` on the offsite PBS. Otherwise WireGuard drops the packets, whatever the firewall says.
