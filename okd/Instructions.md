# OKD 3-Node Master Cluster Setup – Agent-Based Installer with Libvirt

This guide covers setting up a 3-node OKD master cluster on a CentOS Stream 10 server using libvirt/KVM and the **agent-based installer**. This approach uses a single ISO for all nodes - no separate bootstrap VM required.

**Target Environment:**
- CentOS Stream 10 server with 125GB RAM, 13 CPUs
- VMs created via libvirt/virt-manager
- Network: 192.168.0.0/21 (private router network)

**Reference:**
[OKD Installation on Any Platform](https://docs.okd.io/latest/installing/installing_platform_agnostic/installing-platform-agnostic.html)



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

You need a DNS server on your private network. Example using Pi-hole/dnsmasq (`/etc/dnsmasq.d/okd.conf`):

```
# API server - points to master-0 (rendezvous host)
address=/api.okd.kubesoar.com/192.168.1.10

# Internal API
address=/api-int.okd.kubesoar.com/192.168.1.10

# Apps wildcard - for ingress
address=/.apps.okd.kubesoar.com/192.168.1.10

# Master nodes
address=/master-0.okd.kubesoar.com/192.168.1.10
address=/master-1.okd.kubesoar.com/192.168.1.11
address=/master-2.okd.kubesoar.com/192.168.1.12

# ETCD SRV records
srv-host=_etcd-server-ssl._tcp.okd.kubesoar.com,master-0.okd.kubesoar.com,2380,0,10
srv-host=_etcd-server-ssl._tcp.okd.kubesoar.com,master-1.okd.kubesoar.com,2380,0,10
srv-host=_etcd-server-ssl._tcp.okd.kubesoar.com,master-2.okd.kubesoar.com,2380,0,10

# PTR records
ptr-record=10.1.168.192.in-addr.arpa,master-0.okd.kubesoar.com
ptr-record=11.1.168.192.in-addr.arpa,master-1.okd.kubesoar.com
ptr-record=12.1.168.192.in-addr.arpa,master-2.okd.kubesoar.com
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
1. Generate `install-config.yaml` for 3-node cluster
2. Generate `agent-config.yaml` with static IPs and MAC addresses
3. Create the agent installer ISO (`cluster/agent.x86_64.iso`)

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

### Step 4: Copy ISO to Server

```bash
cd ansible
ansible-playbook -i inventory.yml copy-iso.yml
```

### Step 5: Create VMs

```bash
ansible-playbook -i inventory.yml create-vms.yml
```

This creates 3 master VMs, all booting from the same agent ISO. The first node (master-0) is the "rendezvous" host that coordinates the installation.

### Step 6: Monitor Installation

```bash
# Wait for install to complete
make wait-install

# Or watch logs on the rendezvous node
make watch-bootstrap
```

### Step 7: Access the Cluster

```bash
make use-kubeconfig
oc get nodes
oc get co
```

---

## Post-Installation

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

#### 2. Copy & Apply Certificate

```bash
sudo cp /etc/letsencrypt/live/apps.okd.kubesoar.com/fullchain.pem .
sudo cp /etc/letsencrypt/live/apps.okd.kubesoar.com/privkey.pem .

sudo chown $USER:$USER fullchain.pem privkey.pem
chmod 600 fullchain.pem privkey.pem

oc create secret tls wildcard-apps-okd-kubesoar \
  -n openshift-ingress \
  --cert=fullchain.pem \
  --key=privkey.pem \
  --dry-run=client -o yaml | oc apply -f -

oc patch ingresscontroller default \
  -n openshift-ingress-operator \
  --type=merge \
  -p '{"spec":{"defaultCertificate":{"name":"wildcard-apps-okd-kubesoar"}}}'
```

#### 3. Restart Ingress Pods

```bash
oc delete pod -n openshift-ingress \
  -l ingresscontroller.operator.openshift.io/owning-ingresscontroller=default
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
cd ansible
ansible-playbook -i inventory.yml destroy-vms.yml

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
