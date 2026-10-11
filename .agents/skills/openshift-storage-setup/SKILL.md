---
name: openshift-storage-setup
description: Use when setting up or troubleshooting persistent storage on the OKD cluster, including node data disks, LVMS, Local Storage Operator, ODF, and KubeVirt HostPath Provisioner.
---

# OpenShift Storage Setup

Each master VM gets a raw data volume attached as `vdb`, which storage operators then consume.

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- Node VM lifecycle is covered in `openshift-node-setup`.

## Procedures

### 1. Data disks (libvirt on desktop-server)
- `make create-node-data-disks`: creates `node-0..node-2` volumes.
- `make attach-node-data-disks`: attaches them to the masters as `vdb`.
- Reverse: `make detach-node-data-disks`, then `make delete-node-data-disks`.
- Clean stray volumes: `make cleanup-non-qcow-volumes`.

### 2. Pick a storage backend
| Goal | Targets |
|---|---|
| Dynamic local LVM PVs (preferred for SNO-like lab) | `make install-lvms` then `make create-lvms-cluster` (`/dev/vdb`) |
| Static hostpath PVs | `make install-local-storage` |
| Ceph/Rook | `make install-odf` (heavy, needs the OKDerators catalog from `make setup-okderators`) |
| VM disks for KubeVirt | `make install-kubevirt-hpp` (or `install-kubevirt` plus a backend above) |

## Gotchas

- Detach or delete a data disk only after workloads using it are gone, or PVs become orphaned.
- LVMS needs an empty, unformatted `vdb`. Wipe or recreate the volume if a previous install left signatures.
- ODF is resource-hungry. Check node CPU and RAM headroom before installing.
- Running several default StorageClasses causes ambiguous PVC binding. Keep exactly one default.

## References

- `okd/ansible/*-node-data-disks.yml`, `install-lvms.yml`, `install-local-storage.yml`, `install-odf.yml`, `install-kubevirt.yml`
- `okd/cluster-setup/create-lvms-cluster.sh`, `storage.yml`, `kubevirt.yaml`

