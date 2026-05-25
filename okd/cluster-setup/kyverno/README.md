# Kyverno install — security posture (OKD / OpenShift)

Controller Deployments rely on chart defaults (**non‑root UID, capability drop-all, RuntimeDefault seccomp,
read‑only roots**). Workloads only use **`emptyDir`** and **`projected`** volumes — compatible with the
built‑in **`restricted-v2` SCC** (`system:serviceaccounts` authorize it cluster‑wide).

No custom SCC is bundled here; granting Kyverno a clone of **`privileged`** is unnecessary once chart
constraints match `restricted‑v2` and the namespace PSA labels.

Kyverno’s own [platform notes](https://kyverno.io/docs/installation/platform-notes/#notes-for-openshift-users)
describe OpenShift nuances; **values-openshift.yaml** is deliberately empty `{}` unless you must override.

Namespace labels enforce **`pod-security.kubernetes.io/*: restricted`** (PSA) to match workload claims.

## Upgrading from earlier repo revisions

If you previously applied **`SecurityContextConstraints/kyverno-custom`** from this repo, remove it:

```bash
oc delete securitycontextconstraints.security.openshift.io/kyverno-custom
```

## If pods fail admission

Rare chart or platform versions may still require small SCC relief. Prefer tightening Helm values again
before adding a **minimal** custom SCC (clone `restricted-v2` and add only the missing capability or volume
type).

