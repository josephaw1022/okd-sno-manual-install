---
name: openshift-openbao-setup
description: Use when deploying, initializing, unsealing, restarting, or removing OpenBao (HA, Postgres backend, Keycloak OIDC) on the OKD cluster.
---

# OpenShift OpenBao Setup

OpenBao runs in HA via Helm with a CloudNativePG PostgreSQL backend, Istio ingress, and Keycloak OIDC login from the `homelab` realm.

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- Prerequisites: Keycloak with the homelab realm (`openshift-keycloak-setup`), CNPG operator, cert-manager, and Istio ingress.

## Procedures

- Full setup: `make setup-openbao-all` (database, Keycloak client, deployment, OIDC init).
- Step by step: `make deploy-openbao-postgres` → `make create-openbao-keycloak-client` → `make deploy-openbao` → `make init-openbao`.
- After a node reboot or pod restart: `make restart-openbao` (restarts pods and unseals every replica).
- Teardown: `make uninstall-openbao` (Helm release, DB cluster, and Keycloak client).

## Gotchas

- **Sealed after restart:** OpenBao pods come back sealed. Use `make restart-openbao` rather than deleting pods by hand.
- The init output holds unseal keys and the root token. Never print them into logs, commits, or PR descriptions.
- `init-openbao` is meant to run once per fresh backend. Rerunning against an initialized store will fail or be a no-op.
- Uninstalling deletes the Postgres cluster, so all stored secrets are gone.

## References

- `okd/ansible/deploy-openbao*.yml`, `configure-openbao-oidc.yml`, `create-openbao-keycloak-client.yml`, `uninstall-openbao.yml`

