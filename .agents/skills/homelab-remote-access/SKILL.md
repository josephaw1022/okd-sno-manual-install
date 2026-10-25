---
name: homelab-remote-access
description: "Use when configuring or troubleshooting remote access to the homelab: Tailscale exit node and subnet routing, the macvlan shim, and Cockpit on laptop-server and desktop-server."
---

# Homelab Remote Access

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- Host details: `homelab-hardware-context`. LAN layout: `homelab-network-context`.

## Procedures

### Tailscale
- `make configure-tailscale-laptop`: laptop-server as exit node and subnet router.
- `make start-tailscale-supermicro`: bring up Tailscale on the supermicro server.
- Client side (this laptop): `make tailscale-up`, `tailscale-allow-lan`, `tailscale-status`, `tailscale-down`, `tailscale-reset`.

### macvlan shim
- `make configure-macvlan-shim-laptop`: persistent shim so the host and subnet router can reach macvlan containers and VMs, such as the LB and Pi-hole.

### Cockpit
- `make setup-cockpit-all` (or `-laptop` / `-desktop`): install, move to port 443, issue the cert, and transfer it.
- Certs only: `create-desktop-server-cert`, `transfer-cockpit-cert-laptop`, `transfer-cockpit-cert-desktop`.

### Cluster login
- `make oc-login` (browser), `make use-kubeconfig` (replaces `~/.kube/config`).

## Gotchas

- Macvlan containers cannot reach their own host without the shim. Missing shim symptoms: LB or Pi-hole reachable from the LAN but not from laptop-server.
- Tailscale exit-node mode on this laptop breaks LAN and local DNS unless `tailscale-allow-lan` is applied.
- Moving Cockpit to 443 conflicts with anything else bound there. Check before running.
- `use-kubeconfig` overwrites `~/.kube/config`.

