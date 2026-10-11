---
name: openshift-networking-certs
description: Use when working on MetalLB, the homelab wildcard DNS, cert-manager with the Cloudflare ClusterIssuer, the Let's Encrypt ingress wildcard cert, or the Cloudflare Tunnel on the OKD cluster.
---

# OpenShift Networking and Certificates

LoadBalancer IPs (MetalLB), TLS (cert-manager and certbot, both using Cloudflare DNS-01), and public exposure (Cloudflare Tunnel).

## Instructions

- **Rule reminder:** `make` targets from `okd/` only.
- Cloudflare API credentials live in `okd/ansible/group_vars/all.yml`. Never echo them.
- For DNS records see `homelab-dns-context`. For the API/apps load balancer see `openshift-api-loadbalancer`.

## Procedures

### MetalLB
- `make install-metallb-all`: MetalLB, L2 pool, and the `*.homelab.kubesoar.com` wildcard in Pi-hole.
- Pieces: `install-metallb`, `install-metallb-l2-config`, `configure-homelab-dns`. Reverse with `uninstall-metallb-l2-config` and `uninstall-metallb`.

### cert-manager
1. `make install-cert-manager`
2. `make configure-cloudflare-clusterissuer`
3. Remove: `make uninstall-cert-manager`

### Cluster ingress wildcard cert
1. `make create-ingress-cert`: certbot container, Cloudflare DNS-01.
2. `make apply-ingress-cert`: applies to the OKD ingress.

### Cloudflare Tunnel
- `make deploy-cloudflared` / `make destroy-cloudflared`

## Gotchas

- Let's Encrypt has rate limits. Do not loop on `create-ingress-cert`.
- The MetalLB pool must be unused LAN addresses outside the router's DHCP range (see `homelab-network-context`).
- Replacing the ingress cert rolls the router pods, so expect a brief console blip.
- Destroying the Cloudflare tunnel immediately removes any public hostname served through it.

## References

- `okd/ansible/install-metallb*.yml`, `install-cert-manager.yml`, `configure-cloudflare-clusterissuer.yml`, `apply-ingress-cert.yml`, `deploy-cloudflared.yml`
- `okd/cluster-setup/metallb-setup.yaml`

