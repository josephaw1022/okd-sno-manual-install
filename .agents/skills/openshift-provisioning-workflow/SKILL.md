---
name: openshift-provisioning-workflow
description: High-level overview of the OKD cluster setup process. Use this to understand the end-to-end flow from planning IPs and DNS to starting the VMs.
---

# OKD Cluster Setup (High-Level)

This skill covers what is done at a high level for setting up our OKD cluster. It's simple and focuses on the main steps.

## How it's run
All of these tasks are done through the **Makefile** in the `okd/` directory. The Makefile does the heavy lifting for us by running **bash scripts** and **Ansible playbooks** behind the scenes.

## 1. Versioning is Everything

The **openshift-installer version** used when creating the ISO is very important. Each OpenShift/OKD release comes with an `openshift-installer` binary specific to that version. The version of OKD has a **1-1 relationship** with the `openshift-installer`.

## 2. Infrastructure Pre-reqs

- **IP Planning & DNS:** We must know the IPs of our soon-to-be nodes. This has to be planned out and done. Update the DNS server for the cluster if it hasn't been updated yet via `make update-dns`.
  - _Refer to `homelab-dns-context` skill for more context on the dns setup._
- **API Load Balancer:** You must create the Nginx load balancer for our soon-to-be cluster API server. It load balances between the 3 nodes and provides the IP that our DNS points to for our API domains.
  - _Refer to `openshift-api-loadbalancer` skill for more context on the load balancer setup._

## 3. The Setup Flow

- **Install the Binary:** We install the correct version of the `openshift-installer`.
- **Make Configs:** We make an `install-config` and an `agent-assisted installer config`. This is done for us in the makefile (via `make build` or `make agent-iso`, however, `make build` is prefered).
- **Create the ISO:** We use the `openshift-installer` binary to create an ISO that will be used by all 3 of the VMs that act as nodes (via `make build`).
- **Copy the ISO:** We copy the generated ISO from our laptop to the server that will be running the nodes. The nodes are straight-up Linux VMs running on our desktop-server (via `make copy-iso`).
  - _Refer to `homelab-hardware-context` skill for more context on the server._
- **Start the VMs:** We use that ISO to actually create and start the VMs on our server (via `make start-vms`).
  - _Refer to `openshift-node-setup` skill for more context on the nodes._

And boom! Our cluster has our nodes, the DNS setup, and the API load balancer setup.
