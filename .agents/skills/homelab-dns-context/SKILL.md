---
name: homelab-dns-context
description: Use when you need to understand or configure the DNS setup for the homelab and the OKD cluster, including Pi-hole records.
---

# Homelab DNS Context

DNS infrastructure management for the homelab and OKD cluster.

## Instructions

- Use this skill to understand how DNS records are propagated to the Pi-hole.
- All cluster-specific DNS logic is encapsulated in `okd/dnsmasq/okd.conf`.
- Refer to [references/records.md](references/records.md) for the full list of static OKD records.

## Procedures

### Updating DNS Records

1. Modify `okd/dnsmasq/okd.conf`.
2. Execute `make update-dns` from the `okd/` directory.
3. This runs an Ansible playbook to sync the config to the Pi-hole VM and restart services.

## Gotchas

- **Manual VM Setup:** The Pi-hole VM (`192.168.1.5`) is NOT automated. It was manually created on the Lenovo Laptop host (`192.168.1.6`) via Cockpit.
- **Dual Interfaces:** The Pi-hole VM uses two NICs: one for the default VM network and one for the `192.168.1.0/24` LAN.
- **No DHCP:** Pi-hole does NOT handle DHCP; the Netgear router handles all IP assignments.
- **Service Restart:** Updating DNS via Ansible restarts `pihole-FTL` on the VM.
