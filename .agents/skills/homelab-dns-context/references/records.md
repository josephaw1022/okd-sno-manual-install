# Homelab & OKD DNS Records

Static records managed via `dnsmasq` configs (`/etc/dnsmasq.d/`) on the Pi-hole VM (`192.168.1.5`).

## Core A Records

| FQDN | IP Address | Target |
|------|------------|--------|
| `api.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `api-int.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `*.apps.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `master-0.okd.kubesoar.com` | 192.168.1.22 | Control Plane |
| `master-1.okd.kubesoar.com` | 192.168.1.23 | Control Plane |
| `master-2.okd.kubesoar.com` | 192.168.1.24 | Control Plane |
| `pihole.kubesoar.com` | 192.168.1.5 | Pi-hole VM |
| `postgres.kubesoar.com` | 192.168.1.25 | BYOC Logs PostgreSQL |
| `minio.kubesoar.com` | 192.168.1.26 | BYOC Logs MinIO |

## Homelab Wildcard (`homelab.conf`)

| FQDN | IP Address | Target |
|------|------------|--------|
| `*.homelab.kubesoar.com` | 192.168.1.230 | MetalLB / Istio ingress |

## SRV Records
- `_etcd-server-ssl._tcp.okd.kubesoar.com` points to master nodes on port 2380.

## PTR Records
- Reverse DNS lookups for `192.168.1.10-12` map to `master-0`..`master-2` as defined in `okd.conf`.

Quay records are written separately to `/etc/dnsmasq.d/quay.conf` by `make add-quay-dns` (see `ansible/add-quay-dns-to-pihole.yml`).
