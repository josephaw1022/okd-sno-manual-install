# OKD 3-Node Master Cluster Setup – Agent-Based Installer with Libvirt

This guide covers setting up a 3-node OKD master cluster on a CentOS Stream 10 server using libvirt/KVM and the **agent-based installer**. This approach uses a single ISO for all nodes - no separate bootstrap VM required.

**Features:**
- **Cilium CNI** - Uses Cilium as the Container Network Interface instead of OVNKubernetes
- Agent-based installation (single ISO for all nodes)
- Automated VM provisioning via Ansible

**Target Environment:**
- CentOS Stream 10 server with 125GB RAM, 13 CPUs
- VMs created via libvirt/virt-manager
- Network: 192.168.0.0/21 (private router network)

**Reference:**
- [OKD Installation on Any Platform](https://docs.okd.io/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html)
- [Cilium OLM for OpenShift](https://github.com/isovalent/olm-for-cilium)



## Prerequisites

### On your local machine (where you generate the ISO):
- podman
- jq
- openshift-install and oc CLI tools
- Ansible (for deployment to server)

### On the libvirt server (CentOS Stream 10):
- libvirt, qemu-kvm, virt-manager
- Sufficient resources (125GB RAM, 13 CPUs recommended)

```bash
# Install libvirt on CentOS Stream 10
sudo dnf install -y libvirt qemu-kvm virt-manager virt-install
sudo systemctl enable --now libvirtd
```


## DNS Setup

You need a DNS server on your private network. This repo includes an Ansible playbook to configure Pi-hole/dnsmasq automatically.

First, ensure your Pi-hole server is configured in `ansible/inventory.yml`:

```yaml
pihole:
  hosts:
    pihole-server:
      ansible_host: 192.168.1.5  # Your Pi-hole IP
      dnsmasq_conf_dir: /etc/dnsmasq.d
```

Then deploy the DNS configuration:

```bash
make update-dns
```

This copies the dnsmasq config from `dnsmasq/okd.conf` to your Pi-hole server and restarts the DNS service.

**Manual Setup:** If you prefer to configure DNS manually, see the example config in `dnsmasq/okd.conf`.


## Load Balancer Setup (Optional but Recommended)

For high availability, set up an nginx load balancer that distributes traffic across all master nodes:

```bash
# Create the load balancer container on a macvlan network
make create-lb
```

This creates an nginx container at `192.168.1.20` that load balances:
- API server (6443) → all masters
- Machine Config Server (22623) → all masters  
- HTTP/HTTPS ingress (80/443) → all masters

To remove the load balancer:

```bash
make destroy-lb
```


## Configure Values in Makefile

Edit the makefile to match your environment:

```makefile
OKD_VERSION ?= 4.20.0-okd-scos.8
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
SSH_KEY ?= ~/.ssh/id_ed25519.pub
MACHINE_NETWORK_CIDR ?= 192.168.0.0/21

# Node IPs
MASTER0_IP ?= 192.168.1.10
MASTER1_IP ?= 192.168.1.11
MASTER2_IP ?= 192.168.1.12

# Gateway/DNS
GATEWAY_IP ?= 192.168.1.1

# Cilium CNI settings
CILIUM_VERSION ?= 1.15.1

# Libvirt VM settings
VM_CPUS ?= 4
VM_MEMORY ?= 41984
VM_DISK_SIZE ?= 120

# Remote server
SERVER_HOST ?= 192.168.1.100
SERVER_USER ?= root
```


## Installation Steps

### Step 1: Install CLI Tools (on your local machine)

```bash
make oc
make installer
```

### Step 2: Build the Agent ISO

```bash
make build
```

This will:
1. Generate `install-config.yaml` for 3-node cluster (with `networkType: None` to skip default CNI)
2. Generate `agent-config.yaml` with static IPs and MAC addresses
3. Create the agent installer ISO (`cluster/agent.x86_64.iso`)

**Note:** Cilium CNI is installed post-bootstrap via `make install-cilium` (see Step 7). The embedded manifest approach doesn't work because the bootstrap node can't apply manifests without network connectivity.

**Important:** The `agent-config.yaml` maps MAC addresses to IPs. Make sure the MAC addresses in the config match what you'll use in the VMs.

### Step 3: Configure Ansible Inventory

Edit `ansible/inventory.yml` to match your server:

```yaml
all:
  children:
    libvirt_hosts:
      hosts:
        okd-server:
          ansible_host: 192.168.1.100  # Your server IP
          vm_cpus: 4
          vm_memory_mb: 41984
          vm_disk_size_gb: 120
```

### Step 4: Create Ansible Credentials File

Create `ansible/group_vars/all.yml` with your SSH/sudo credentials:

```yaml
# Ansible connection credentials
# NOTE: For production, encrypt this file with: ansible-vault encrypt group_vars/all.yml
ansible_password: your_ssh_password
ansible_become_password: your_sudo_password
```

### Step 5: Copy ISO to Server

```bash
make copy-iso
```

### Step 6: Create VMs

```bash
make create-vms
```

This creates 3 master VMs, all booting from the same agent ISO. The first node (master-0) is the "rendezvous" host that coordinates the installation.

### Step 7: Wait for Nodes to Boot

After running `make create-vms`, the VMs will boot and begin the agent-based installation process. However, since we use `networkType: None` in the install config, the cluster won't have a CNI and pods won't be able to communicate.

**Important:** The bootstrap process will stall until you install Cilium CNI.

Wait for the 2 non-rendezvous master nodes (master-1 and master-2) to shut down - after initial boot, they will install CoreOS and then power off.

### Step 8: Start All VMs

```bash
make start-vms
```

### Step 9: Set Up Kubeconfig

This is required so the Cilium CLI can communicate with the cluster:

```bash
make use-kubeconfig
```

### Step 10: Install Cilium CNI

This is required for the bootstrap to proceed:

```bash
make install-cilium
```

This installs Cilium with the correct CNI paths for OKD (`/etc/kubernetes/cni/net.d`). After Cilium is installed, the pods on the bootstrap/rendezvous node will be able to communicate with pods on the other master nodes.

### Step 11: Verify Cilium is Running

```bash
cilium status
```

You should see all components showing `OK` and nodes becoming `Ready`.

### Step 12: Monitor Installation

```bash
# Wait for install to complete
make wait-install

# Or watch logs on the rendezvous node
make watch-bootstrap
```

### Step 13: Access the Cluster

```bash
make use-kubeconfig
oc get nodes
oc get co
```

---

## Post-Installation

### Verify Cilium CNI

After the cluster is up, verify Cilium is running:

```bash
cilium status
oc get pods -n kube-system -l app.kubernetes.io/name=cilium
```

To enable Hubble observability:

```bash
cilium upgrade --set hubble.enabled=true --set hubble.relay.enabled=true --set hubble.ui.enabled=true
```

### Entra ID (Azure AD)

- Create an app registration in Azure AD
- Create a client secret for the app registration
- Add redirect URI: `https://oauth-openshift.apps.okd.kubesoar.com/oauth2callback/azure` (use web type)
- For token configuration, add `email`, `groups`, and `preferred_username` as optional claims
- Under API permissions, add `User.Read` and `email` permissions for Microsoft Graph

Then on the OKD side, create an oauth resource using the `entraid-oauth.yaml` file in this repo (in the `cluster-setup` dir).

---

### Fix Console TLS Certificate Warning

#### 1. Generate Cert (DNS-01)

```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d "*.apps.okd.kubesoar.com"
```

Add the TXT record in your DNS → wait for propagation.

#### 2. Apply Certificate to Cluster

```bash
make apply-ingress-cert
```

---

## Troubleshooting

### SSH Access to Nodes

```bash
ssh -i ~/.ssh/id_ed25519 core@192.168.1.10  # master-0
ssh -i ~/.ssh/id_ed25519 core@192.168.1.11  # master-1
ssh -i ~/.ssh/id_ed25519 core@192.168.1.12  # master-2
```

### Clean Up and Start Over

```bash
# Destroy all VMs
make destroy-vms

# Clean generated files
make clean
```

### Fix Hostname Issue on Node

```bash
sudo hostnamectl set-hostname master-0.okd.kubesoar.com
```

### View Agent Logs on Rendezvous Node

```bash
ssh core@192.168.1.10 "journalctl -b -f -u agent.service"
```

### Approve CSRs (if nodes aren't joining)

```bash
make approve-csrs
```
