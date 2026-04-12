---
name: openshift-api-loadbalancer
description: Use when managing or troubleshooting the Nginx-based load balancer (okd-lb) for the OKD cluster.
---
# OpenShift API Load Balancer

Dedicated Nginx-based load balancer (`okd-lb`) that manages entry for the OKD cluster API and ingress traffic.

## Core Architecture
- **Software:** Nginx is the dedicated Kubernetes API load balancer server.
- **Deployment:** Runs as a Podman container on the `desktop-server` host.
- **Networking (Macvlan):** Uses Podman's `macvlan` driver to obtain a dedicated IP (`192.168.1.20`) on the LAN. This avoids using the `desktop-server` IP and simplifies DNS mapping for `api`, `api-int`, and `apps`.

## Procedures
Execute these commands from the `okd/` directory:
- **Create/Start:** `make create-lb` (deploys the Nginx container and macvlan network).
- **Destroy:** `make destroy-lb`.

## Reference
- **Service Mapping:** [references/ports.md](references/ports.md) (6443, 22623, 80, 443).
- **Hardcoded IP:** `192.168.1.20`. Ensure an A-record exists with the DNS server for this IP.
- **Interface:** Requires `eno1` on the host to support the `macvlan` network.
