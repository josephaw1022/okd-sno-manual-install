---
name: homelab-network-context
description: Use when you need to understand the homelab's network topology, IP ranges, gateway, or DNS server locations.
---

# Homelab Network Context

Essential networking details for the homelab environment hosting the OKD cluster.

## Instructions

- Use this skill to verify IP assignments and network boundaries.
- The homelab network is a private LAN, isolated from external Wi-Fi ranges.
- Refer to [references/topology.md](references/topology.md) for a list of critical infrastructure IPs.

## Gotchas

- **Subnet Mask:** Uses a `/16` CIDR (`192.168.0.0/16`), but specific usable range is `192.168.0.0` to `192.168.7.0`.
- **DHCP:** The Nighthawk RAX10 router is the primary DHCP server.
- **DNS Redirection:** The router is configured to use the Pi-hole (`192.168.1.5`) for all LAN DNS resolution.
- **Isolation:** This network is separate from the apartment Wi-Fi range (`172.16.0.0/12`).

## Procedures

### Verifying Connectivity

1. Ensure the target host is within the `192.168.1.x` range for cluster operations.
2. Check `192.168.1.1` for gateway reachability.
