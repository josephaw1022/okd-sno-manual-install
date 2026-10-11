---
name: openshift-cluster-troubleshooting
description: Use when the OKD cluster install stalls, nodes are NotReady, CSRs are pending, the API is unreachable, or after a power loss or reboot. Covers watch targets and the known bootstrap and CRI-O/Multus workarounds.
---

# OpenShift Cluster Troubleshooting

Triage order for install and boot problems. Go from cheapest check to most invasive.

## Instructions

- **Rule reminder:** `make` targets from `okd/` only. Read-only `oc`/`kubectl` inspection is fine.
- A repo hook (`.cursor/hooks/deny-kubectl-delete-without-noninteractive.sh`) restricts `kubectl delete`. Read that script before attempting deletes.

## Procedures

### 1. Is the VM layer healthy?
`make start-vms` (starts stopped VMs), `make enable-vm-autostart` (survive host reboots).

### 2. Watch an install
- `make watch-all` (tmux, 4 panes), `make kill-watch` to stop.
- Single node: `watch-bootstrap` (master-0, the rendezvous node), `watch-master-1`, `watch-master-2`.
- `make wait-install` blocks until the install completes.

### 3. Nodes not joining
- `make approve-csrs` approves pending node CSRs.
- `make reboot-non-bootstrap` reboots master-1 and master-2.
- `make clean-known-hosts` fixes SSH host-key warnings after a rebuild.

### 4. Known stuck states
- `openshift-apiserver` API registration blocked: `make fix-bootstrap`.
- CRI-O boot watchdog deadlock from a leftover `00-multus.conf`: `make unblock-crio-multus`.
- DNS or API failures: see the `homelab-dns-context` and `openshift-api-loadbalancer` skills.

### 5. Full redeploy
`make rebuild` (clean, rebuild ISO, copy, create VMs). Destructive: confirm with the user first.

## Gotchas

- `make clean` and `make rebuild` discard generated install state, including the kubeconfig and auth under `cluster/`.
- Install certs and bootstrap tokens expire, so a cluster left down for a long time may need CSR approvals on startup.
