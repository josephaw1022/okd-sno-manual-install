---
name: homelab-datadog-cloudprem
description: Use when deploying or removing Datadog BYOC Logs (CloudPrem) with its Postgres and MinIO containers, the in-cluster DatadogAgent, or the Datadog agent on desktop-server.
---

# Homelab Datadog CloudPrem

Datadog BYOC Logs (CloudPrem) running on the cluster, backed by external Podman containers (PostgreSQL and MinIO), with agents on both the cluster and the host.

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- The Datadog API key and settings come from `okd/ansible/group_vars/all.yml`. Never print them.

## Procedures

- Everything: `make configure-datadog-cloudprem-all` (containers, DNS, stack, cluster agent, server agent).
- Undo everything: `make undo-datadog-cloudprem-all`.
- Pieces:
  - `make create-byoc-postgres`, `make create-byoc-minio` (undo with `destroy-byoc-*`)
  - `make install-datadog-operator`
  - `make install-cloudprem-container-stack` (undo with `uninstall-cloudprem-container-stack`)
  - `make configure-datadog-agent-cluster-cloudprem`
  - `make install-datadog-agent-server-host` (undo with `destroy-datadog-agent-server-host`)

## Gotchas

- The BYOC containers must be up before the cluster stack, or CloudPrem pods crash-loop on DB/S3 connection errors.
- `DatadogAgent` CRs need the Datadog Operator installed first.
- Destroying MinIO deletes stored log data.

## References

- `okd/ansible/install-cloudprem.yml`, `create-byoc-*.yml`, `install-datadog-*.yml`
- `okd/cluster-setup/cloudprem/datadog-values.yaml`, `okd/scripts/configure-datadog.sh`

