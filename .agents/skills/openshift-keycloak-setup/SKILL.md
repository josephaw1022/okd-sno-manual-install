---
name: openshift-keycloak-setup
description: Use when installing, configuring, or removing Keycloak on the OKD cluster, including the operator, CNPG database, EDP operator, Entra ID identity provider, homelab realm, and OKD OAuth client.
---

# OpenShift Keycloak Setup

Keycloak is the central OIDC provider for the homelab. Entra ID federates into it, and the cluster console and OpenBao authenticate against its `homelab` realm.

## Instructions

- **Rule reminder:** use `make` targets from `okd/` only.
- Prerequisites: cert-manager with a working ClusterIssuer, CloudNativePG operator, and Istio ingress (see `openshift-networking-certs` and `openshift-istio-ambient`).

## Procedures

### Full setup / teardown
- `make setup-keycloak-all`: master and homelab realms, Entra ID groups, operator, database, OKD client and OAuth.
- `make uninstall-keycloak`: removes the Keycloak CR, Postgres cluster, and operator.

### Step by step
1. `make install-keycloak-operator`
2. `make deploy-keycloak-postgres`
3. `make deploy-keycloak` (alias `create-keycloak`): Keycloak CR with Istio ingress, cert-manager TLS, and the CNPG DB.
4. `make install-keycloak-edp-operator`: manages realms and clients as CRs.
5. `make setup-keycloak-entraid`: Entra ID IdP on the master realm.
6. `make setup-keycloak-homelab-entraid` then `make configure-keycloak-homelab-realm`: homelab realm and the `homelab-user` group.
7. `make create-okd-keycloak-client` then `make setup-okd-keycloak-oauth`: cluster login via Keycloak.

`make install-keycloak` runs steps 1-4 in one go.

## Gotchas

- Order matters. The EDP operator needs a reachable Keycloak, and the OKD OAuth setup needs the client from step 7 to exist first.
- Changing the `OAuth` cluster resource restarts the `oauth-openshift` pods. Briefly expect login failures.
- Keep a break-glass `cluster-admin` path (kubeconfig or the Entra ID admin binding, see `openshift-cluster-entraid-setup`) before changing identity providers.
- OpenBao depends on the homelab realm. Do not uninstall Keycloak without considering `openshift-openbao-setup`.

## References

- `okd/ansible/deploy-keycloak*.yml`, `setup-keycloak-*.yml`, `configure-keycloak-homelab-realm.yml`, `create-okd-keycloak-client.yml`
- `okd/cluster-setup/keycloak-oauth.yaml`

