---
name: homelab-quay-registry
description: Use when deploying, verifying, debugging, or tearing down the Quay registry stack (Quay, Postgres, Valkey, Clair, Nginx) on laptop-server, or wiring the cluster to it (pull secret, pull-through cache mirrors, Entra ID login).
---

# Homelab Quay Registry

Podman-container Quay stack on `laptop-server` serving `quay.kubesoar.com`, plus the cluster-side configuration that consumes it.

## Instructions

- **Rule reminder:** run everything via `make` from `okd/`. Never run playbooks directly.
- Registry credentials and settings come from `okd/ansible/group_vars/all.yml`.
- Prefer `make verify-quay` first when diagnosing anything.

## Procedures

### 1. Deploy the stack
- Full deploy (DNS, cert, Postgres, Valkey, Clair, registry, Nginx): `make create-quay-stack`
- Individual pieces, in dependency order: `create-quay-ingress-cert` → `create-quay-postgres` → `create-quay-valkey` → `create-quay-clair` → `create-quay-registry` → `create-quay-nginx`
- Quay DNS records: `make add-quay-dns` (see `homelab-dns-context`).

### 2. Operate and debug
- Health check: `make verify-quay`
- Logs: `make quay-logs`, `make clair-logs`
- Change `config.yaml` (e.g. superusers): `make update-quay-config`
- Renew/sync the Let's Encrypt cert: `make transfer-quay-cert` (restarts containers)
- Entra ID login for Quay: `make setup-quay-entraid`

### 3. Connect the cluster
1. `make setup-quay-pull-secret` adds Quay creds to the global pull secret (inspect with `make get-pull-secret`).
2. `make apply-quay-cache-mirrors` applies the IDMS/ITMS for Quay and Docker Hub pull-through caches.
3. `make verify-quay-cache-mirrors` checks IDMS/ITMS, node `registries.conf`, kubelet pull secret, and a test pull.
4. Undo mirrors: `make delete-quay-cache-mirrors`.

### 4. Tear down
`make destroy-quay-stack` (removes containers and network; data volumes are lost).

## Gotchas

- Applying mirror sets triggers MachineConfig rollouts, so nodes may reboot one at a time. Wait for the MCPs to settle before applying more node-level changes.
- If cert transfer succeeds but clients still see an old cert, the Nginx container needs a restart (`transfer-quay-cert` does this).
- Cluster pulls fail with auth errors if the pull secret was not refreshed after rotating Quay credentials.

## References

- `okd/ansible/create-quay-*.yml`, `verify-quay-stack.yml`, `update-quay-config.yml`
- `okd/cluster-setup/quay-cache-mirrors.yaml`

