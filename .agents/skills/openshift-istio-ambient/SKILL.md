---
name: openshift-istio-ambient
description: Use when installing, upgrading, troubleshooting, or removing the Istio ambient mesh (Gateway API CRDs, istiod, CNI, ztunnel, ingress, Kiali) on the OKD cluster.
---

# OpenShift Istio Ambient Mesh

Helm-based Istio ambient mesh with Istio ingress, Kiali, and namespace labeling.

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- Install and uninstall in the documented order. Uninstall is the reverse of install.

## Procedures

### Everything
- `make install-istio-all`: Gateway API CRDs, base, istiod, cni, ztunnel, ingress, ingress class, Kiali, and ambient namespace labels.
- `make uninstall-istio-all`: reverse order, plus unlabel.

### Step order
1. `make patch-istio-ovn-routing-via-host`: required so ambient health probes work on OVN-Kubernetes.
2. `make install-istio-gateway-api-crds`
3. `make install-istio-crds`
4. `make install-istio`
5. `make install-istio-cni`
6. `make install-istio-ztunnel`
7. `make install-istio-ingress` and `make install-istio-ingress-class`
8. `make install-istio-kiali`
9. `make label-istio-ambient-namespaces` (sets `istio.io/dataplane-mode=ambient`)

Each has an `uninstall-*` counterpart. `make disable-istio-ovn-routing-via-host` reverts step 1.

## Gotchas

- Patching OVN `routingViaHost` changes the network operator config and can roll network pods. Do it while the cluster is otherwise stable.
- The CNI and ztunnel need privileged SCCs on OpenShift. If pods are stuck, check SCC bindings before reinstalling.
- Labeling a namespace ambient affects its running traffic immediately. Avoid labeling system namespaces.
- Keycloak and OpenBao ingress depend on the Istio ingress gateway.

## References

- `okd/ansible/install-istio*.yml`, `uninstall-istio*.yml`, `unlabel-istio-ambient-namespaces.yml`

