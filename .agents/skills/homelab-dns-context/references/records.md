# OKD DNS Records

Static records managed via `dnsmasq` for the `okd.kubesoar.com` cluster.

## Core A Records
| FQDN | IP Address | Target |
|------|------------|--------|
| `api.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `api-int.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `*.apps.okd.kubesoar.com` | 192.168.1.20 | Load Balancer |
| `master-0.okd.kubesoar.com` | 192.168.1.22 | Control Plane |
| `master-1.okd.kubesoar.com` | 192.168.1.23 | Control Plane |
| `master-2.okd.kubesoar.com` | 192.168.1.24 | Control Plane |

## SRV Records
- `_etcd-server-ssl._tcp.okd.kubesoar.com` points to master nodes on port 2380.

## PTR Records
- Reverse DNS lookups for `192.168.1.22-24` map back to the respective master nodes.
