---
name: openshift-node-setup
description: Use when you need to understand how the OKD nodes (VMs) are created, managed, and destroyed on the desktop-server libvirt host in the homelab.
---

# Openshift Node Setup (Homelab)

This skill describes how the 3-node OKD cluster is provisioned and managed on the `desktop-server` libvirt host in the homelab.
The installation uses the OpenShift Agent-Based Installer, meaning there is no separate bootstrap VM. Instead, `master-0` acts as the rendezvous host and coordinates the installation.

## Cluster Topology

The cluster consists of 3 Master VMs running on the `desktop-server` libvirt host.

- **okd-master-0** (Rendezvous node)
  - IP: 192.168.1.22
  - MAC: `52:54:00:00:00:10`
  - Memory: 30GB
- **okd-master-1**
  - IP: 192.168.1.23
  - MAC: `52:54:00:00:00:11`
  - Memory: 30GB
- **okd-master-2**
  - IP: 192.168.1.24
  - MAC: `52:54:00:00:00:12`
  - Memory: 30GB

**Networking:** VMs use macvtap bridged networking (`direct` mode), attached to the physical interface of the 192.168.1.0/24 network on the `desktop-server` host.

## Node Management Workflow

Nodes are managed using Ansible playbooks wrapped by the `okd/makefile`.

### 1. Generating and Copying the ISO

All 3 nodes boot from a single generated Agent ISO (`agent.x86_64.iso`).

- **Generate ISO:** `make build`
- **Copy ISO to desktop-server:** `make copy-iso`
  - This runs the `ansible/copy-iso.yml` playbook to push the ISO to the server.
  - To clean up old ISOs: `make delete-iso`

### 2. Creating and Starting VMs

- **Command:** `make create-vms`
  - Executes `ansible/create-vms.yml`.
  - Creates qcow2 disk images (120GB default).
  - Defines and starts the VMs on the `desktop-server` using `virt-install`.
- **Start stopped VMs:** `make start-vms`
- **Reboot non-bootstrap nodes:** `make reboot-non-bootstrap`

### 3. Monitoring Installation

- **Rendezvous logs (master-0):** `make watch-bootstrap`
- **Other node logs:** `make watch-master-1`, `make watch-master-2`
- **All nodes (tmux):** `make watch-all`
- **Wait for install completion:** `make wait-install`

### 4. Destroying the Cluster

- **Command:** `make destroy-vms`
  - Executes `ansible/destroy-vms.yml`.
  - Force stops (`virsh destroy`), undefines (`virsh undefine`), and deletes the qcow2 disk images for all 3 master nodes on the `desktop-server` host.

## Gotchas & Troubleshooting

- **SSH Errors during watch:** If `make watch-bootstrap` fails with SSH key errors after a rebuild, run `make clean-known-hosts` to clear the IPs from `~/.ssh/known_hosts`.
