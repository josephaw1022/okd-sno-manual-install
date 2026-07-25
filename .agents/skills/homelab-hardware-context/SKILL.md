---
name: homelab-hardware-context
description: Use when you need to understand the physical servers, their operating systems, or hardware specifications in the homelab.
---

# Homelab Hardware Context

Provides essential information about the physical infrastructure supporting the homelab and OKD cluster.

## Instructions

- Use this skill to identify the correct host for virtual machines or container workloads.
- Always prefer managing these servers via Cockpit on port 9090.
- Refer to [references/inventory.md](references/inventory.md) for detailed hardware specifications.

## Procedures

### Accessing Server Management

1. Navigate to `https://<server-ip>:9090` in a web browser.
2. Log in with system credentials to access terminals, logs, and performance metrics.

## Gotchas

- **Cockpit Port:** Both servers use port **9090** for Cockpit.
- **OS Versions:** Lenovo runs AlmaLinux 9.7, while Supermicro runs AlmaLinux 10.1.
- **Dell PowerEdge:** This server is currently idle and not part of the active OKD cluster infrastructure.
