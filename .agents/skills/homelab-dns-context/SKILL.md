---
name: homelab-dns-context
description: Use when you need to understand, provision, configure, update records, or tear down the DNS setup (Pi-hole VM) for the homelab and OKD cluster.
---

# Homelab DNS Context

DNS infrastructure management for the homelab and OKD cluster using a dedicated Pi-hole VM on `laptop-server`.

## Instructions

- Use this skill to understand, provision, configure, and tear down DNS services and records.
- All cluster-specific DNS logic is encapsulated in `okd/dnsmasq/okd.conf`.
- Homelab ingress wildcard DNS logic is encapsulated in `okd/dnsmasq/homelab.conf`.
- Refer to [references/records.md](references/records.md) for the full list of static OKD and homelab records.
- **Rule reminder:** All operations must be executed via `make` targets from the `okd/` directory. Do not run Ansible playbooks directly.

## Procedures

### 1. Creating and Installing the DNS Server VM

1. Provision the DNS server VM on `laptop-server` (`192.168.1.4`):
   ```bash
   make create-dns-server-vm-on-laptop-server
   ```
   *Underlying playbook:* `ansible/create-dns-server-vm-on-laptop-server.yml`. Provisions a libvirt VM named `pihole` (IP `192.168.1.5`, 2 vCPUs, 4GB RAM, 32GB disk in storage pool `System`) from a Fedora Cloud image with cloud-init and bridged LAN networking.

2. Install and configure Pi-hole on the VM:
   ```bash
   make install-pihole-on-dns-server-vm
   ```
   *Underlying playbook:* `ansible/install-pihole-on-dns-server-vm.yml`. Unattended install, upstream resolvers `1.1.1.1`/`1.0.0.1`, sets the web password, enables `etc_dnsmasq_d = true` in `pihole.toml`, rebuilds gravity, and starts `pihole-FTL`. Web UI: `http://192.168.1.5/admin`.

3. Sync the cluster DNS records:
   ```bash
   make update-dns
   ```

### 2. Updating DNS Records

- **OKD cluster records:** edit `okd/dnsmasq/okd.conf`, then `make update-dns` (`ansible/update-pihole-dns.yml`; copies to `/etc/dnsmasq.d/okd.conf` and restarts `pihole-FTL`).
- **Homelab wildcard (`*.homelab.kubesoar.com`):** edit `okd/dnsmasq/homelab.conf`, then `make configure-homelab-dns`.
- **Quay records:** `make add-quay-dns` (writes `/etc/dnsmasq.d/quay.conf`).

### 3. Deleting the DNS Server VM

```bash
make delete-dns-server-vm-on-laptop-server
```
*Underlying playbook:* `ansible/delete-dns-server-vm-on-laptop-server.yml`. Force-stops and undefines the `pihole` VM (including NVRAM) and removes its disk and cloud-init seed files from the `System` storage pool. Safe to run when the VM is already gone.

## Gotchas

- **Automated lifecycle:** The Pi-hole VM (`192.168.1.5`) is created, installed, and deleted by Ansible via the Makefile. It is no longer a manual Cockpit-built VM.
- **Order matters:** Create the VM before installing Pi-hole; deleting the VM destroys all Pi-hole state, so re-run install and `make update-dns` (plus `configure-homelab-dns` / `add-quay-dns`) after recreating it.
- **Pi-hole v6 snippets:** `etc_dnsmasq_d = true` in `/etc/pihole/pihole.toml` is required for `/etc/dnsmasq.d/` configs to load; the install playbook handles it.
- **No DHCP:** Pi-hole does NOT handle DHCP; the Netgear router handles all IP assignments.
- **Service restart:** Updating DNS via Ansible restarts `pihole-FTL` on the VM.
