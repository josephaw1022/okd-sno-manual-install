# Makefile for OKD 3-Node Master Cluster with Libvirt (Agent-Based Installer)

# OKD values
OKD_VERSION ?= 4.22.0-okd-scos.10

# Openshift values
# OKD_VERSION ?= 4.21.10
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
SSH_KEY ?= ~/.ssh/id_ed25519.pub
MACHINE_NETWORK_CIDR ?= 192.168.0.0/21

# Node IPs for 3 master nodes
MASTER0_IP ?= 192.168.1.22
MASTER1_IP ?= 192.168.1.23
MASTER2_IP ?= 192.168.1.24

# Gateway/DNS server
GATEWAY_IP ?= 192.168.1.1

# Libvirt VM settings
VM_CPUS ?= 4
VM_MEMORY ?= 41984
VM_DISK_SIZE ?= 120
NODE_DATA_DISK_SIZE_GB ?= 200
NODE_DATA_DISK_ALLOCATION_GB ?= 1
NODE_DATA_POOL ?= okd-storage

# Remote server settings
SERVER_HOST ?= 192.168.1.9
SERVER_USER ?= root

# Laptop server single-VM settings
LAPTOP_VM_NAME ?= pihole
LAPTOP_VM_HOSTNAME ?= pihole.kubesoar.com
LAPTOP_VM_VCPUS ?= 2
LAPTOP_VM_MEMORY_MB ?= 4096
LAPTOP_VM_DISK_SIZE_GB ?= 32
LAPTOP_VM_FEDORA_RELEASE ?= 44
LAPTOP_VM_CLOUD_IMAGE_NAME ?= Fedora-Cloud-Base-Generic-44-1.7.x86_64.qcow2
LAPTOP_VM_IP ?= 192.168.1.5
LAPTOP_VM_PREFIX ?= 24
LAPTOP_VM_GATEWAY ?= 192.168.1.1
LAPTOP_VM_DNS ?= 192.168.1.5
LAPTOP_VM_MAC_ADDRESS ?= 52:54:00:00:00:06
LAPTOP_VM_STORAGE_POOL ?= System
PIHOLE_WEBPASSWORD ?= changeme
PIHOLE_UPSTREAM_DNS_1 ?= 1.1.1.1
PIHOLE_UPSTREAM_DNS_2 ?= 1.0.0.1

## OKD values
OC_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-client-linux-$(OKD_VERSION).tar.gz
INSTALLER_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-install-linux-$(OKD_VERSION).tar.gz

## Openshift values
# OC_URL = https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(OCP_VERSION)/openshift-client-linux-$(OCP_VERSION).tar.gz
# INSTALLER_URL = https://mirror.openshift.com/pub/openshift-v4/clients/ocp/$(OCP_VERSION)/openshift-install-linux-$(OCP_VERSION).tar.gz

##@ General

.PHONY: help
help: ## Show available Makefile commands.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Dependencies

.PHONY: deps
deps: ## Install dependencies (podman, nmstate).
	@echo "🔧 Installing dependencies..."
	sudo dnf install -y podman nmstate

.PHONY: oc
oc: ## Download the OKD oc CLI.
	@echo "⬇️ Downloading oc CLI..."
	curl -L $(OC_URL) -o oc.tar.gz
	tar zxf oc.tar.gz
	chmod +x oc
	sudo mv ./oc /usr/local/bin/

.PHONY: installer
installer: ## Download the OKD openshift-install binary.
	@echo "⬇️ Downloading openshift-install..."
	@tempdir=$$(mktemp -d) && \
	cd $$tempdir && \
	curl -L $(INSTALLER_URL) -o openshift-install.tar.gz && \
	tar zxvf openshift-install.tar.gz && \
	chmod +x openshift-install && \
	sudo mv ./openshift-install /usr/local/bin/

.PHONY: uninstall-installer
uninstall-installer: ## Remove the openshift-install binary from /usr/local/bin.
	@echo "🗑️ Removing openshift-install..."
	sudo rm -f /usr/local/bin/openshift-install
	@echo "✅ openshift-install removed"

.PHONY: fcos
fcos: ## Download the FCOS ISO (for reference, agent-iso creates its own).
	@echo "🔍 Fetching CoreOS ISO URL for $(ARCH)..."
	@ISO_URL=$$(openshift-install coreos print-stream-json \
		| jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'); \
	[ -n "$$ISO_URL" ] || { echo "❌ No ISO URL found"; exit 1; }; \
	echo "➡️  $$ISO_URL"; \
	curl -L "$$ISO_URL" -o fcos-live.iso


##@ Pi-hole & DNS

.PHONY: create-dns-server-vm-on-laptop-server
create-dns-server-vm-on-laptop-server: ## Create DNS server VM on laptop-server (192.168.1.4) via Ansible.
	@echo "💻 Creating DNS server VM on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-dns-server-vm-on-laptop-server.yml \
	  -e "laptop_vm_name=$(LAPTOP_VM_NAME)" \
	  -e "laptop_vm_hostname=$(LAPTOP_VM_HOSTNAME)" \
	  -e "laptop_vm_vcpus=$(LAPTOP_VM_VCPUS)" \
	  -e "laptop_vm_memory_mb=$(LAPTOP_VM_MEMORY_MB)" \
	  -e "laptop_vm_disk_size_gb=$(LAPTOP_VM_DISK_SIZE_GB)" \
	  -e "laptop_vm_fedora_release=$(LAPTOP_VM_FEDORA_RELEASE)" \
	  -e "laptop_vm_cloud_image_name=$(LAPTOP_VM_CLOUD_IMAGE_NAME)" \
	  -e "laptop_vm_ip=$(LAPTOP_VM_IP)" \
	  -e "laptop_vm_prefix=$(LAPTOP_VM_PREFIX)" \
	  -e "laptop_vm_gateway=$(LAPTOP_VM_GATEWAY)" \
	  -e "laptop_vm_dns=$(LAPTOP_VM_DNS)" \
	  -e "laptop_vm_mac_address=$(LAPTOP_VM_MAC_ADDRESS)" \
	  -e "laptop_vm_storage_pool=$(LAPTOP_VM_STORAGE_POOL)" && \
	popd > /dev/null
	@echo "✅ DNS server VM created (or already present)"


.PHONY: delete-dns-server-vm-on-laptop-server
delete-dns-server-vm-on-laptop-server: ## Delete DNS server VM on laptop-server (192.168.1.4) via Ansible.
	@echo "🗑️ Deleting DNS server VM on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml delete-dns-server-vm-on-laptop-server.yml \
	  -e "laptop_vm_name=$(LAPTOP_VM_NAME)" \
	  -e "laptop_vm_storage_pool=$(LAPTOP_VM_STORAGE_POOL)" && \
	popd > /dev/null
	@echo "✅ DNS server VM deleted (if present)"


.PHONY: install-pihole-on-dns-server-vm
install-pihole-on-dns-server-vm: ## Install Pi-hole on the DNS server VM (pihole-server).
	@echo "🧩 Installing Pi-hole on DNS server VM..."
	@pushd ansible > /dev/null && \
	PIHOLE_WEBPASSWORD=$(PIHOLE_WEBPASSWORD) \
	ansible-playbook -i inventory.yml install-pihole-on-dns-server-vm.yml \
	  -e "pihole_upstream_dns_1=$(PIHOLE_UPSTREAM_DNS_1)" \
	  -e "pihole_upstream_dns_2=$(PIHOLE_UPSTREAM_DNS_2)" && \
	popd > /dev/null
	@echo "✅ Pi-hole installation complete"


.PHONY: update-dns
update-dns: ## Update Pi-hole DNS config for OKD cluster.
	@echo "🌐 Updating Pi-hole DNS configuration..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml update-pihole-dns.yml && \
	popd > /dev/null
	@echo "✅ DNS updated"


.PHONY: add-quay-dns
add-quay-dns: ## Add Quay DNS records to Pi-hole and verify resolution.
	@echo "🌐 Adding Quay DNS records to Pi-hole..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml add-quay-dns-to-pihole.yml && \
	popd > /dev/null
	@echo "✅ Quay DNS updated and verified"


##@ Cockpit Management

.PHONY: install-cockpit-laptop
install-cockpit-laptop: ## Install Cockpit and extensions on laptop-server.
	@echo "💻 Installing Cockpit on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-cockpit-laptop.yml && \
	popd > /dev/null

.PHONY: install-cockpit-desktop
install-cockpit-desktop: ## Install Cockpit and extensions on desktop-server.
	@echo "💻 Installing Cockpit on desktop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-cockpit-desktop.yml && \
	popd > /dev/null

.PHONY: configure-cockpit-port-laptop
configure-cockpit-port-laptop: ## Configure Cockpit to run on port 443 on laptop-server.
	@echo "⚙️ Configuring Cockpit port to 443 on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml configure-cockpit-port-laptop.yml && \
	popd > /dev/null

.PHONY: configure-cockpit-port-desktop
configure-cockpit-port-desktop: ## Configure Cockpit to run on port 443 on desktop-server.
	@echo "⚙️ Configuring Cockpit port to 443 on desktop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml configure-cockpit-port-desktop.yml && \
	popd > /dev/null

.PHONY: create-laptop-server-cert
create-laptop-server-cert: ## Generate Let's Encrypt cert for laptop-server.kubesoar.com using certbot container.
	@echo "🔐 Generating Let's Encrypt certificate for laptop-server.kubesoar.com..."
	sudo $(CONTAINER_ENGINE) run --rm -it \
	  -v /etc/letsencrypt:/etc/letsencrypt:z \
	  -v /var/lib/letsencrypt:/var/lib/letsencrypt:z \
	  $(CERTBOT_IMAGE) certonly \
	  --manual \
	  --preferred-challenges dns \
	  -d "laptop-server.kubesoar.com"

.PHONY: create-desktop-server-cert
create-desktop-server-cert: ## Generate Let's Encrypt cert for desktop-server.kubesoar.com using certbot container.
	@echo "🔐 Generating Let's Encrypt certificate for desktop-server.kubesoar.com..."
	sudo $(CONTAINER_ENGINE) run --rm -it \
	  -v /etc/letsencrypt:/etc/letsencrypt:z \
	  -v /var/lib/letsencrypt:/var/lib/letsencrypt:z \
	  $(CERTBOT_IMAGE) certonly \
	  --manual \
	  --preferred-challenges dns \
	  -d "desktop-server.kubesoar.com"

.PHONY: transfer-cockpit-cert-laptop
transfer-cockpit-cert-laptop: ## Transfer Let's Encrypt cert for laptop-server to laptop-server Cockpit.
	@echo "📤 Transferring certificate to laptop-server Cockpit..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml transfer-cockpit-cert-laptop.yml && \
	popd > /dev/null

.PHONY: transfer-cockpit-cert-desktop
transfer-cockpit-cert-desktop: ## Transfer Let's Encrypt cert for desktop-server to desktop-server Cockpit.
	@echo "📤 Transferring certificate to desktop-server Cockpit..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml transfer-cockpit-cert-desktop.yml && \
	popd > /dev/null

.PHONY: setup-cockpit-laptop
setup-cockpit-laptop: install-cockpit-laptop configure-cockpit-port-laptop create-laptop-server-cert transfer-cockpit-cert-laptop ## Complete Cockpit setup on laptop-server (install, port 443, cert generation, and cert transfer).

.PHONY: setup-cockpit-desktop
setup-cockpit-desktop: install-cockpit-desktop configure-cockpit-port-desktop create-desktop-server-cert transfer-cockpit-cert-desktop ## Complete Cockpit setup on desktop-server (install, port 443, cert generation, and cert transfer).

.PHONY: setup-cockpit-all
setup-cockpit-all: setup-cockpit-laptop setup-cockpit-desktop ## Run complete Cockpit setup for both laptop-server and desktop-server.


##@ ISO & Manifest Generation

.PHONY: config
config: ## Generate install-config.yaml and agent-config.yaml.
	./scripts/generate-install-config.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(SSH_KEY) $(MACHINE_NETWORK_CIDR) $(MASTER0_IP) $(MASTER1_IP) $(MASTER2_IP)


.PHONY: agent-iso
agent-iso: ## Generate the agent-based installer ISO (single ISO for all nodes).
	@echo "📦 Generating agent-based installer ISO..."
	rm -rf cluster
	mkdir -p cluster
	cp install-config.yaml cluster/
	cp agent-config.yaml cluster/
	openshift-install --dir=cluster agent create image
	@echo "✅ Agent ISO created: cluster/agent.x86_64.iso"


.PHONY: cluster-manifests
cluster-manifests: ## Generate cluster manifests for modification before ISO creation.
	@echo "📋 Generating cluster manifests..."
	rm -rf cluster
	mkdir -p cluster
	cp install-config.yaml cluster/
	cp agent-config.yaml cluster/
	openshift-install --dir=cluster agent create cluster-manifests
	@echo "✅ Manifests generated in cluster/cluster-manifests/"
	@echo "📝 Modify manifests as needed, then run 'make agent-iso-from-manifests'"


.PHONY: agent-iso-from-manifests
agent-iso-from-manifests: ## Generate ISO from pre-existing/modified manifests (no manifest regeneration).
	@echo "📦 Generating agent ISO from existing manifests..."
	@if [ ! -d "cluster/cluster-manifests" ]; then \
		echo "❌ No manifests found. Run 'make cluster-manifests' first."; \
		exit 1; \
	fi
	openshift-install --dir=cluster agent create image
	@echo "✅ Agent ISO created: cluster/agent.x86_64.iso"

.PHONY: create-manifests
create-manifests: ## Create the manifests directory structure for custom manifests.
	@echo "📁 Creating manifests directory structure..."
	mkdir -p cluster/openshift
	@echo "✅ Manifests directory created: cluster/openshift/"


.PHONY: format-files
format-files: ## Format all .ign and .json files in cluster/ using jq.
	@echo "✨ Formatting .ign and .json files in cluster/..."
	@find cluster -type f \( -name '*.ign' -o -name '*.json' \) -exec sh -c 'jq . {} > tmp && mv tmp {}' \;
	@echo "✅ Files formatted."


##@ Build & Deploy

.PHONY: clean
clean: ## Clean up generated files.
	@echo "🧹 Cleaning up..."
	rm -f oc.tar.gz openshift-install.tar.gz oc openshift-install fcos-live.iso
	rm -rf cluster install-config.yaml agent-config.yaml _rendered



.PHONY: build
build: ## Build the agent-based installer ISO for 3-node cluster.
	@echo "🔨 Building the OKD 3-Node Agent Installer ISO..."
	@$(MAKE) config
	@$(MAKE) agent-iso
	@echo ""
	@echo "✅ ISO ready: cluster/agent.x86_64.iso"
	@echo "📋 Optional: make delete-iso (to clean up old ISO on server)"
	@echo "📋 Next step: make copy-iso"
	@echo ""


.PHONY: build-with-manifest-edit
build-with-manifest-edit: ## Build ISO with ability to edit default manifests before ISO creation.
	@echo "🔨 Building OKD manifests for editing..."
	@$(MAKE) config
	@$(MAKE) cluster-manifests
	@echo "✅ Manifests ready for editing in cluster/cluster-manifests/"
	@echo "📝 Edit manifests as needed, then run: make agent-iso-from-manifests"
	@echo "📋 After ISO creation: make copy-iso && make create-vms"


.PHONY: rebuild
rebuild: ## Clean, rebuild ISO, copy to server, and create VMs (full redeploy).
	@echo "🔄 Full rebuild and redeploy..."
	@$(MAKE) clean
	@$(MAKE) delete-iso
	@$(MAKE) build
	@$(MAKE) copy-iso
	@$(MAKE) create-vms
	@echo ""
	@echo "✅ Rebuild complete! VMs are starting."
	@echo "📋 Next: make watch-all (or make watch-bootstrap + make wait-install)"


##@ Cluster Access & Monitoring

.PHONY: use-kubeconfig
use-kubeconfig: ## Replace ~/.kube/config with cluster/auth/kubeconfig
	@echo "🔁 Replacing ~/.kube/config with cluster/auth/kubeconfig..."
	@pushd cluster/auth > /dev/null && \
	if [ -f kubeconfig ]; then \
	  mkdir -p $$HOME/.kube && \
	  cp kubeconfig $$HOME/.kube/config && \
	  chmod 600 $$HOME/.kube/config && \
	  echo "✅ kubeconfig moved to ~/.kube/config"; \
	else \
	  echo "❌ kubeconfig not found in cluster/auth"; \
	fi && \
	popd > /dev/null


.PHONY: clean-known-hosts
clean-known-hosts: ## Remove entries with master IPs from known_hosts.
	@echo "🧼 Cleaning known_hosts entries for master IPs..."
	@KNOWN_HOSTS_FILE=$$HOME/.ssh/known_hosts; \
	if [ -f $$KNOWN_HOSTS_FILE ]; then \
	  grep -v "$(MASTER0_IP)\|$(MASTER1_IP)\|$(MASTER2_IP)" $$KNOWN_HOSTS_FILE > $$KNOWN_HOSTS_FILE.tmp && \
	  mv $$KNOWN_HOSTS_FILE.tmp $$KNOWN_HOSTS_FILE && \
	  echo "✅ Removed entries for master IPs"; \
	else \
	  echo "⚠️ No known_hosts file found at $$KNOWN_HOSTS_FILE"; \
	fi


.PHONY: watch-bootstrap
watch-bootstrap: ## SSH into rendezvous node (master-0) and tail logs.
	@echo "👀 Watching bootstrap services on rendezvous node (master-0)..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@$(MASTER0_IP) "journalctl -b -f -u agent.service"


.PHONY: watch-master-1
watch-master-1: ## SSH into master-1 and tail logs.
	@echo "👀 Watching logs on master-1..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@$(MASTER1_IP) "journalctl -b -f -u agent.service"


.PHONY: watch-master-2
watch-master-2: ## SSH into master-2 and tail logs.
	@echo "👀 Watching logs on master-2..."
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@$(MASTER2_IP) "journalctl -b -f -u agent.service"


.PHONY: wait-install
wait-install: ## Wait for installation to complete.
	@echo "⏳ Waiting for installation to complete..."
	openshift-install --dir=cluster agent wait-for install-complete --log-level=info


.PHONY: watch-all
watch-all: clean-known-hosts ## Launch tmux with 4 panes monitoring all nodes and install progress.
	@echo "🖥️ Creating tmux session with 4 panes..."
	@tmux kill-session -t okd-install 2>/dev/null || true
	@tmux new-session -d -s okd-install -c $(CURDIR)
	@tmux split-window -h -t okd-install -c $(CURDIR)
	@tmux select-pane -t okd-install:0.0
	@tmux split-window -v -t okd-install -c $(CURDIR)
	@tmux select-pane -t okd-install:0.2
	@tmux split-window -v -t okd-install -c $(CURDIR)
	@tmux send-keys -t okd-install:0.0 'make watch-bootstrap' C-m
	@tmux send-keys -t okd-install:0.1 'make wait-install' C-m
	@tmux send-keys -t okd-install:0.2 'make watch-master-1' C-m
	@tmux send-keys -t okd-install:0.3 'make watch-master-2' C-m
	@tmux select-pane -t okd-install:0.0
	@tmux attach -t okd-install


.PHONY: kill-watch
kill-watch: ## Kill the tmux monitoring session.
	@echo "💀 Killing tmux session..."
	@tmux kill-session -t okd-install 2>/dev/null && echo "✅ Session killed" || echo "⚠️ No session found"


.PHONY: approve-csrs
approve-csrs: ## Approve pending CSRs for nodes.
	@echo "✅ Approving pending CSRs..."
	@oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs -r oc adm certificate approve


##@ Remote Access & Authentication

TAILSCALE_EXIT_NODE ?= 100.110.200.108
TAILSCALE_ADVERTISED_ROUTES ?= 192.168.1.0/24
OKD_API_URL ?= https://api.$(CLUSTER_NAME).$(BASE_DOMAIN):6443

.PHONY: configure-tailscale-laptop setup-tailscale-laptop
configure-tailscale-laptop: ## Configure laptop-server as Tailscale exit node & subnet router via Ansible.
	@echo "⚙️ Configuring laptop-server as Tailscale exit node and subnet router..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml configure-tailscale-laptop.yml \
	  -e "tailscale_advertised_routes=$(TAILSCALE_ADVERTISED_ROUTES)" && \
	popd > /dev/null

setup-tailscale-laptop: configure-tailscale-laptop

.PHONY: start-tailscale-supermicro start-tailscale-desktop
start-tailscale-supermicro: ## Start and connect Tailscale on the supermicro server via Ansible.
	@echo "🔗 Starting Tailscale on supermicro server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml start-tailscale-supermicro.yml && \
	popd > /dev/null
	@echo "✅ Tailscale started on supermicro server"

start-tailscale-desktop: start-tailscale-supermicro

.PHONY: tailscale-up tailscale
tailscale-up: ## Connect to Tailscale with exit node, accept routes, and allow local LAN access.
	@echo "🔗 Connecting to Tailscale (exit-node: $(TAILSCALE_EXIT_NODE), local LAN allowed)..."
	tailscale up --exit-node=$(TAILSCALE_EXIT_NODE) --accept-routes --exit-node-allow-lan-access

tailscale: tailscale-up

.PHONY: tailscale-allow-lan allow-lan
tailscale-allow-lan: ## Allow direct access to local network and local DNS while using exit node.
	@echo "🌐 Enabling direct local LAN access with exit node..."
	tailscale set --exit-node-allow-lan-access

allow-lan: tailscale-allow-lan

.PHONY: tailscale-down tailscale-disconnect
tailscale-down: ## Disconnect exit node from Tailscale.
	@echo "🔌 Disconnecting Tailscale exit node..."
	tailscale set --exit-node=

tailscale-disconnect: tailscale-down

.PHONY: tailscale-reset reset-ts reset-ts-laptop
tailscale-reset: ## Reset Tailscale settings on this laptop back to default values.
	@echo "🔄 Resetting Tailscale settings on this laptop to defaults..."
	tailscale up --reset

reset-ts: tailscale-reset
reset-ts-laptop: tailscale-reset

.PHONY: tailscale-status
tailscale-status: ## Check Tailscale status and active exit node.
	tailscale status

.PHONY: oc-login login
oc-login: ## Log in to OKD cluster via web browser.
	@echo "🔐 Logging in to OKD cluster ($(OKD_API_URL))..."
	oc login --web --server=$(OKD_API_URL)

login: oc-login


##@ Manifest Inspection

.PHONY: extract-manifests
extract-manifests: ## Extract manifests from the agent config (for inspection).
	./scripts/extract-bootstrap-manifests.sh

.PHONY: render-manifests
render-manifests: ## Render manifests using openshift-install (for inspection/customization).
	mkdir -p _rendered
	cp install-config.yaml _rendered/
	cp agent-config.yaml _rendered/
	openshift-install --dir=_rendered agent create cluster-manifests
	@echo "✅ Manifests rendered to _rendered/"
	@echo "📝 Modify files in _rendered/cluster-manifests/ as needed"


##@ VM Management (Libvirt)

.PHONY: copy-iso
copy-iso: ## Copy the agent ISO to the libvirt server via Ansible.
	@echo "📤 Copying ISO to server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml copy-iso.yml && \
	popd > /dev/null
	@echo "✅ ISO copied to server"
	@echo "📋 Next step: make create-vms"


.PHONY: delete-iso
delete-iso: ## Delete the agent ISO from the libvirt server via Ansible.
	@echo "🗑️ Deleting ISO from server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml delete-iso.yml && \
	popd > /dev/null
	@echo "✅ ISO deleted from server"


.PHONY: create-vms
create-vms: ## Create the VMs on the libvirt server via Ansible.
	@echo "🖥️ Creating VMs on server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs created"
	@echo ""
	@echo "📋 Next steps:"
	@echo "   1. Terminal 1: make watch-bootstrap (monitor bootstrap node)"
	@echo "   2. Terminal 2: make wait-install (watch installation progress)"
	@echo "   3. After install: make use-kubeconfig (configure kubectl access)"
	@echo ""
	@echo "💡 Tip: If watch-bootstrap fails with SSH errors, run: make clean-known-hosts"


.PHONY: stop-vms
stop-vms: ## Stop all OKD master VMs via Ansible.
	@echo "⏹️ Stopping OKD VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml stop-vms.yml && \
	popd > /dev/null
	@echo "✅ OKD VMs stopped"


.PHONY: destroy-vms
destroy-vms: ## Destroy all VMs and delete disk images via Ansible.
	@echo "💥 Destroying VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs destroyed"


.PHONY: cleanup-non-qcow-volumes
cleanup-non-qcow-volumes: ## Delete non-qcow2 and non-agent-ISO volumes from the default libvirt pool.
	@echo "🧹 Removing non-qcow2 and non-agent-ISO volumes..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml cleanup-non-qcow-volumes.yml && \
	popd > /dev/null
	@echo "✅ Volume cleanup complete"


.PHONY: create-node-data-disks
create-node-data-disks: ## Create one raw data volume (node-0..node-2) in libvirt for each node.
	@echo "💾 Creating per-node data volumes in pool $(NODE_DATA_POOL) (size: $(NODE_DATA_DISK_SIZE_GB)G, allocation: $(NODE_DATA_DISK_ALLOCATION_GB)G)..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-node-data-disks.yml \
	  -e "pool_name=$(NODE_DATA_POOL)" \
	  -e "node_data_disk_size_gb=$(NODE_DATA_DISK_SIZE_GB)" \
	  -e "node_data_disk_allocation_gb=$(NODE_DATA_DISK_ALLOCATION_GB)" && \
	popd > /dev/null
	@echo "✅ Per-node data volumes created"


.PHONY: delete-node-data-disks
delete-node-data-disks: ## Delete node-0..node-2 volumes from the selected libvirt pool.
	@echo "🗑️ Deleting per-node data volumes from pool $(NODE_DATA_POOL)..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml delete-node-data-disks.yml \
	  -e "pool_name=$(NODE_DATA_POOL)" && \
	popd > /dev/null
	@echo "✅ Per-node data volumes deleted (if present)"


.PHONY: detach-node-data-disks
detach-node-data-disks: ## Detach vdb from master VMs (if attached).
	@echo "🔌 Detaching per-node data volumes from VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml detach-node-data-disks.yml && \
	popd > /dev/null
	@echo "✅ Data volumes detached from VMs (if present)"


.PHONY: attach-node-data-disks
attach-node-data-disks: ## Attach node-0..node-2 volumes to master VMs as vdb.
	@echo "🔌 Attaching per-node data volumes from pool $(NODE_DATA_POOL) to VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml attach-node-data-disks.yml \
	  -e "pool_name=$(NODE_DATA_POOL)" && \
	popd > /dev/null
	@echo "✅ Data volumes attached to VMs"


.PHONY: start-vms
start-vms: ## Start all stopped VMs on the libvirt server via Ansible.
	@echo "▶️ Starting all stopped VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml start-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs started"


.PHONY: enable-vm-autostart
enable-vm-autostart: ## Enable autostart for currently running OKD master VMs.
	@echo "🔁 Enabling autostart for running OKD master VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml enable-vm-autostart.yml && \
	popd > /dev/null
	@echo "✅ Autostart enabled for running OKD master VMs"


.PHONY: reboot-non-bootstrap
reboot-non-bootstrap: ## Reboot master-1 and master-2 (non-bootstrap nodes).
	@echo "🔄 Rebooting non-bootstrap nodes (master-1 and master-2)..."
	@pushd ansible > /dev/null && \
	MASTER1_IP=$(MASTER1_IP) MASTER2_IP=$(MASTER2_IP) \
	ansible-playbook -i inventory.yml reboot-non-bootstrap.yml && \
	popd > /dev/null
	@echo "✅ Non-bootstrap nodes rebooted"


##@ Infrastructure (Load Balancer)

.PHONY: create-lb
create-lb: ## Create nginx load balancer container on macvlan network.
	@echo "🔄 Creating nginx load balancer..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-lb.yml && \
	popd > /dev/null
	@echo "✅ Load balancer created"


.PHONY: destroy-lb
destroy-lb: ## Destroy nginx load balancer container and network.
	@echo "💥 Destroying nginx load balancer..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-lb.yml && \
	popd > /dev/null
	@echo "✅ Load balancer destroyed"




##@ Quay Registry Stack (laptop-server)

.PHONY: create-quay-ingress-cert create-quay-cert
create-quay-ingress-cert: ## Generate Let's Encrypt cert for quay.kubesoar.com using certbot container (DNS-01 challenge).
	@echo "🔐 Generating Let's Encrypt certificate for quay.$(BASE_DOMAIN) using $(CONTAINER_ENGINE)..."
	sudo $(CONTAINER_ENGINE) run --rm -it \
	  -v /etc/letsencrypt:/etc/letsencrypt:z \
	  -v /var/lib/letsencrypt:/var/lib/letsencrypt:z \
	  $(CERTBOT_IMAGE) certonly \
	  --manual \
	  --preferred-challenges dns \
	  -d "quay.$(BASE_DOMAIN)"
	@echo "✅ Certificate generated for quay.$(BASE_DOMAIN)"

create-quay-cert: create-quay-ingress-cert


.PHONY: transfer-quay-cert
transfer-quay-cert: ## Sync Let's Encrypt cert for quay.kubesoar.com to local repo, transfer to laptop-server, and restart containers.
	@echo "📤 Syncing Let's Encrypt certificate to local repo..."
	sudo cp /etc/letsencrypt/live/quay.$(BASE_DOMAIN)/fullchain.pem certs/quay/quay.crt
	sudo cp /etc/letsencrypt/live/quay.$(BASE_DOMAIN)/privkey.pem certs/quay/quay.key
	sudo chown $$(id -u):$$(id -g) certs/quay/quay.crt certs/quay/quay.key
	@echo "📤 Transferring certificate to laptop-server and restarting Quay containers..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml transfer-quay-cert.yml && \
	popd > /dev/null
	@echo "✅ Certificate transferred and containers restarted"


.PHONY: create-quay-postgres
create-quay-postgres: ## Create PostgreSQL container for Quay on laptop-server.
	@echo "🐘 Creating PostgreSQL container for Quay on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-quay-postgres.yml && \
	popd > /dev/null
	@echo "✅ Quay PostgreSQL container created"


.PHONY: create-quay-valkey
create-quay-valkey: ## Create Valkey cache container for Quay on laptop-server.
	@echo "🔴 Creating Valkey container for Quay on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-quay-valkey.yml && \
	popd > /dev/null
	@echo "✅ Quay Valkey container created"


.PHONY: create-quay-registry
create-quay-registry: ## Create Quay registry container on laptop-server.
	@echo "📦 Creating Quay registry container on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-quay-registry.yml && \
	popd > /dev/null
	@echo "✅ Quay registry container created"


.PHONY: create-quay-nginx
create-quay-nginx: create-quay-ingress-cert ## Create Quay Nginx ingress container on laptop-server.
	@echo "🌐 Creating Quay Nginx ingress container on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-quay-nginx.yml && \
	popd > /dev/null
	@echo "✅ Quay Nginx ingress container created"


.PHONY: create-quay-stack
create-quay-stack: create-quay-ingress-cert add-quay-dns ## Deploy full Quay stack (DNS, Cert, Postgres, Valkey, Registry, Nginx) on laptop-server.
	@echo "🚀 Deploying full Quay stack on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-quay-stack.yml && \
	popd > /dev/null
	@echo "✅ Full Quay stack deployed on laptop-server"


.PHONY: destroy-quay-stack
destroy-quay-stack: ## Destroy Quay stack containers and network on laptop-server.
	@echo "💥 Destroying Quay stack on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-quay-stack.yml && \
	popd > /dev/null
	@echo "✅ Quay stack destroyed"


.PHONY: update-quay-config
update-quay-config: ## Update Quay config.yaml (e.g. superusers) on laptop-server and reload.
	@echo "⚙️ Updating Quay configuration on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml update-quay-config.yml && \
	popd > /dev/null
	@echo "✅ Quay configuration updated"


.PHONY: quay-logs
quay-logs: ## View Quay registry container logs on laptop-server.
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml check-quay-logs.yml && \
	popd > /dev/null


.PHONY: verify-quay
verify-quay: ## Verify Quay stack health, containers, endpoints, and connectivity.
	@echo "🔍 Verifying Quay stack on laptop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml verify-quay-stack.yml && \
	popd > /dev/null
	@echo "✅ Verification complete"


.PHONY: setup-quay-entraid
setup-quay-entraid: ## Configure Microsoft Entra ID (Azure AD) OAuth/OIDC for Quay registry on laptop-server.
	@echo "🔐 Setting up Entra ID OAuth for Quay registry..."
	@pushd ansible > /dev/null && \
	TENANT=$${AZURE_TENANT_ID:-$$(az account show --query tenantId -o tsv 2>/dev/null)}; \
	SUB=$${AZURE_SUBSCRIPTION_ID:-$$(az account show --query id -o tsv 2>/dev/null)}; \
	if [ -z "$$TENANT" ] || [ -z "$$SUB" ]; then \
		echo "❌ Azure credentials not found. Run 'az login' first."; \
		exit 1; \
	fi; \
	ansible-playbook -i inventory.yml setup-quay-entraid.yml \
		-e "azure_tenant_id=$$TENANT" \
		-e "azure_subscription_id=$$SUB" && \
	popd > /dev/null
	@echo "✅ Entra ID OAuth configured for Quay registry"




##@ Cluster Configuration

.PHONY: setup-entraid
setup-entraid: ## Configure Entra ID (Azure AD) OAuth for OKD cluster.
	@echo "🔐 Setting up Entra ID OAuth..."
	@pushd ansible > /dev/null && \
	TENANT=$${AZURE_TENANT_ID:-$$(az account show --query tenantId -o tsv 2>/dev/null)}; \
	SUB=$${AZURE_SUBSCRIPTION_ID:-$$(az account show --query id -o tsv 2>/dev/null)}; \
	if [ -z "$$TENANT" ] || [ -z "$$SUB" ]; then \
		echo "❌ Azure credentials not found. Run 'az login' first."; \
		exit 1; \
	fi; \
	ansible-playbook -i inventory.yml setup-entraid-oauth.yml \
		-e "azure_tenant_id=$$TENANT" \
		-e "azure_subscription_id=$$SUB" && \
	popd > /dev/null
	@echo "✅ Entra ID OAuth configured"


.PHONY: ansible-deps
ansible-deps: ## Install Ansible Galaxy collection dependencies.
	@echo "📦 Installing Ansible Galaxy requirements..."
	@pushd ansible > /dev/null && \
	ansible-galaxy install -r requirements.yml && \
	popd > /dev/null
	@echo "✅ Ansible dependencies installed"


CONTAINER_ENGINE ?= podman
CERTBOT_IMAGE ?= docker.io/certbot/certbot:latest

.PHONY: create-ingress-cert
create-ingress-cert: ## Generate Let's Encrypt wildcard cert using certbot container (DNS-01 challenge).
	@echo "🔐 Generating Let's Encrypt wildcard certificate for *.apps.$(CLUSTER_NAME).$(BASE_DOMAIN) using $(CONTAINER_ENGINE)..."
	sudo $(CONTAINER_ENGINE) run --rm -it \
	  -v /etc/letsencrypt:/etc/letsencrypt:z \
	  -v /var/lib/letsencrypt:/var/lib/letsencrypt:z \
	  $(CERTBOT_IMAGE) certonly \
	  --manual \
	  --preferred-challenges dns \
	  -d "*.apps.$(CLUSTER_NAME).$(BASE_DOMAIN)"
	@echo "✅ Certificate generated. Run 'make apply-ingress-cert' to apply it to OKD ingress."


.PHONY: apply-ingress-cert
apply-ingress-cert: ## Apply Let's Encrypt wildcard cert to OKD ingress.
	@echo "🔒 Applying ingress certificate..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml apply-ingress-cert.yml && \
	popd > /dev/null
	@echo "✅ Ingress certificate applied"


.PHONY: apply-kubelet-config
apply-kubelet-config: ## Apply kubelet config to increase max pods.
	@echo "⚙️ Applying kubelet config..."
	oc apply -f cluster-setup/kubelet-config.yaml
	@echo "✅ Kubelet config applied"


.PHONY: delete-kubelet-config
delete-kubelet-config: ## Delete kubelet config.
	@echo "🗑️ Deleting kubelet config..."
	oc delete -f cluster-setup/kubelet-config.yaml
	@echo "✅ Kubelet config deleted"


.PHONY: fix-bootstrap
fix-bootstrap: ## Create bootstrap configmap to unblock openshift-apiserver API registration.
	@echo "🔧 Creating bootstrap configmap..."
	@printf 'apiVersion: v1\nkind: ConfigMap\nmetadata:\n  name: bootstrap\n  namespace: kube-system\ndata:\n  status: complete\n' | oc apply -f -
	@echo "✅ Bootstrap configmap created - openshift-apiserver should now register Route API"


.PHONY: unblock-crio-multus
unblock-crio-multus: ## Temporarily move leftover 00-multus.conf on master nodes to resolve CRI-O boot watchdog deadlock.
	@echo "🔧 Moving 00-multus.conf out of CNI directory on master nodes..."
	@for ip in $(MASTER0_IP) $(MASTER1_IP) $(MASTER2_IP); do \
		echo "Connecting to $$ip..."; \
		ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null core@$$ip \
			"if [ -f /etc/kubernetes/cni/net.d/00-multus.conf ]; then sudo mv /etc/kubernetes/cni/net.d/00-multus.conf /tmp/00-multus.conf && echo \"Moved on $$ip\"; else echo \"Not present on $$ip\"; fi"; \
	done
	@echo "✅ Moved 00-multus.conf. CRI-O can now initialize cleanly."


##@ Operators

.PHONY: setup-okderators
setup-okderators: ## Install OKDerators catalog source for community operators.
	@echo "📦 Setting up OKDerators catalog..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml setup-okderators.yml && \
	popd > /dev/null
	@echo "✅ OKDerators catalog installed"


.PHONY: install-odf
install-odf: ## Install OKD Data Foundation (Ceph/Rook storage).
	@echo "💾 Installing OKD Data Foundation..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-odf.yml && \
	popd > /dev/null
	@echo "✅ ODF operator installed"


.PHONY: install-gitops
install-gitops: ## Install OKD GitOps (ArgoCD).
	@echo "🔄 Installing OKD GitOps..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-gitops.yml && \
	popd > /dev/null
	@echo "✅ GitOps installed"


.PHONY: install-cert-manager
install-cert-manager: ## Install cert-manager operator (required by RabbitMQ topology operator).
	@echo "📜 Installing cert-manager operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-cert-manager.yml && \
	popd > /dev/null
	@echo "✅ cert-manager operator installed"


.PHONY: install-stolostron
install-stolostron: ## Install Stolostron (Open Cluster Management / ACM).
	@echo "🌐 Installing Stolostron (ACM)..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-stolostron.yml && \
	popd > /dev/null
	@echo "✅ Stolostron installed"


.PHONY: install-kubevirt
install-kubevirt: ## Install KubeVirt (OKD Virtualization).
	@echo "🖥️ Installing KubeVirt..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-kubevirt.yml && \
	popd > /dev/null
	@echo "✅ KubeVirt installed"


.PHONY: install-kubevirt-hpp
install-kubevirt-hpp: ## Install KubeVirt with HostPath Provisioner for local storage.
	@echo "🖥️ Installing KubeVirt with HostPath Provisioner..."
	@pushd ansible > /dev/null && \
	SETUP_HPP=true ansible-playbook -i inventory.yml install-kubevirt.yml && \
	popd > /dev/null
	@echo "✅ KubeVirt with HPP installed"


.PHONY: install-local-storage
install-local-storage: ## Install Local Storage Operator with hostpath storage class.
	@echo "💾 Installing Local Storage Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-local-storage.yml && \
	popd > /dev/null
	@echo "✅ Local Storage Operator installed"


# LVMS bundle tag override (auto-selected from cluster version when unset).
LVMS_BUNDLE_TAG ?=

.PHONY: install-lvms
install-lvms: ## Install LVMS (LVM Storage) operator without OKDerators catalog.
	@if ! command -v operator-sdk >/dev/null 2>&1; then \
	  echo "❌ operator-sdk is not installed. Install operator-sdk and retry."; \
	  exit 1; \
	fi
	@echo "💾 Installing LVMS (LVM Storage) operator..."
	@pushd ansible > /dev/null && \
	LVMS_BUNDLE_TAG="$(LVMS_BUNDLE_TAG)" ansible-playbook -i inventory.yml install-lvms.yml && \
	popd > /dev/null
	@echo "✅ LVMS operator installed"


.PHONY: create-lvms-cluster
create-lvms-cluster: ## Create LVMCluster CR for dynamic local storage (/dev/vdb on masters).
	@echo "💾 Creating LVMCluster..."
	@bash cluster-setup/create-lvms-cluster.sh
	@echo "✅ LVMCluster created"


# AWX Operator (Helm chart: https://ansible-community.github.io/awx-operator-helm/)

AWX_HELM_RELEASE ?= awx-operator
# Pin Helm chart semver (see ansible-community awx-operator-helm Chart.yaml `version`; appVersion is bundled operator).

AWX_OPERATOR_HELM_CHART_VERSION ?= 3.2.1


.PHONY: install-awx-operator
install-awx-operator: ## Install AWX Operator for Ansible automation (Helm chart, not OperatorHub).
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🤖 Installing AWX Operator Helm release ($(AWX_HELM_RELEASE)), chart $(AWX_OPERATOR_HELM_CHART_VERSION)..."
	@pushd ansible > /dev/null && \
	AWX_HELM_RELEASE="$(AWX_HELM_RELEASE)" AWX_OPERATOR_HELM_CHART_VERSION="$(AWX_OPERATOR_HELM_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-awx-operator.yml && \
	popd > /dev/null
	@echo "✅ AWX Operator installed"


.PHONY: uninstall-awx-operator
uninstall-awx-operator: ## Remove AWX Operator Helm release only (does not delete the awx namespace or AWX CRs).
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling AWX Operator Helm release $(AWX_HELM_RELEASE) in namespace awx..."
	helm uninstall "$(AWX_HELM_RELEASE)" \
	  --namespace awx \
	  --wait \
	  --ignore-not-found
	@echo "✅ Helm release removal requested (release $(AWX_HELM_RELEASE))"


## Kyverno (namespace via kustomize; Helm installs the chart release)
KYVERNO_NAMESPACE ?= kyverno
KYVERNO_RELEASE ?= kyverno
# Pin chart version (Kyverno Helm chart 3.8.1 / app v1.18.1); override to upgrade.
KYVERNO_CHART_VERSION ?= 3.8.1


.PHONY: install-kyverno
install-kyverno: ## Install Kyverno (namespace via kustomize, then Helm; chart defaults ↔ restricted-v2 SCC).
	@echo "📋 Applying Kyverno namespace..."
	@echo "⚠️  Helm values live beside manifests; only kustomize resources are applied (see cluster-setup/kyverno/kustomization.yaml)."
	oc apply -k cluster-setup/kyverno/
	@echo "📦 Installing Kyverno Helm release ($(KYVERNO_RELEASE))..."
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@if ! helm repo list 2>/dev/null | grep -q '^kyverno[[:space:]]'; then \
	  helm repo add kyverno https://kyverno.github.io/kyverno/; \
	fi
	helm repo update kyverno
	helm upgrade --install "$(KYVERNO_RELEASE)" kyverno/kyverno \
	  --namespace "$(KYVERNO_NAMESPACE)" \
	  --create-namespace=false \
	  -f cluster-setup/kyverno/values-openshift.yaml \
	  -f cluster-setup/kyverno/values-ha.yaml \
	  $(if $(KYVERNO_CHART_VERSION),--version $(KYVERNO_CHART_VERSION),)
	@echo "✅ Kyverno Helm release installed (namespace $(KYVERNO_NAMESPACE))"


.PHONY: uninstall-kyverno
uninstall-kyverno: ## Remove Kyverno Helm release and namespace.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall release; delete the namespace manually if needed."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Helm release $(KYVERNO_RELEASE) (namespace $(KYVERNO_NAMESPACE))..."
	helm uninstall "$(KYVERNO_RELEASE)" \
	  --namespace "$(KYVERNO_NAMESPACE)" \
	  --wait \
	  --ignore-not-found
	@echo "🗑️ Deleting namespace $(KYVERNO_NAMESPACE)..."
	oc delete namespace "$(KYVERNO_NAMESPACE)" --ignore-not-found
	@echo "✅ Kyverno Helm release and namespace removed"


.PHONY: create-awx-postgres
create-awx-postgres: ## Create external PostgreSQL container for AWX.
	@echo "🐘 Creating PostgreSQL container for AWX..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-postgres.yml && \
	popd > /dev/null
	@echo "✅ PostgreSQL container created"


.PHONY: create-awx-instance
create-awx-instance: ## Create an AWX instance for Ansible automation.
	@echo "🤖 Creating AWX instance..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-awx-instance.yml && \
	popd > /dev/null
	@echo "✅ AWX instance created"


##@ Developer Operators

.PHONY: install-rabbitmq-topology-operator
install-rabbitmq-topology-operator: ## Install RabbitMQ Messaging Topology Operator.
	@echo "🐇 Installing RabbitMQ Messaging Topology Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-rabbitmq-topology-operator.yml && \
	popd > /dev/null
	@echo "✅ RabbitMQ Messaging Topology Operator installed"


.PHONY: install-strimzi-kafka-operator
install-strimzi-kafka-operator: ## Install Strimzi Kafka Operator.
	@echo "🧵 Installing Strimzi Kafka Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-strimzi-kafka-operator.yml && \
	popd > /dev/null
	@echo "✅ Strimzi Kafka Operator installed"


.PHONY: install-cloudnative-pg-operator
install-cloudnative-pg-operator: ## Install CloudNativePG operator.
	@echo "🐘 Installing CloudNativePG operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-cloudnative-pg-operator.yml && \
	popd > /dev/null
	@echo "✅ CloudNativePG operator installed"


.PHONY: install-opstree-redis-operator
install-opstree-redis-operator: ## Install Opstree Redis Operator.
	@echo "🔴 Installing Opstree Redis Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-opstree-redis-operator.yml && \
	popd > /dev/null
	@echo "✅ Opstree Redis Operator installed"


.PHONY: install-minio-operator
install-minio-operator: ## Install MinIO Operator (upstream kustomize; not in OKD OperatorHub).
	@echo "🪣 Installing MinIO Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-minio-operator.yml && \
	popd > /dev/null
	@echo "✅ MinIO Operator installed"


.PHONY: install-developer-operators
install-developer-operators: ## Install RabbitMQ, Strimzi, CloudNativePG, Opstree Redis, and MinIO operators in one run.
	@echo "📦 Installing developer operators..."
	@echo "   Prerequisite: run 'make install-cert-manager' first if RabbitMQ topology is not yet installed."
	@$(MAKE) install-rabbitmq-topology-operator
	@$(MAKE) install-strimzi-kafka-operator
	@$(MAKE) install-cloudnative-pg-operator
	@$(MAKE) install-opstree-redis-operator
	@$(MAKE) install-minio-operator
	@echo "✅ Developer operators installation complete"


##@ Datadog Configuration

# Datadog server-host agent image override.
DD_AGENT_IMAGE ?= gcr.io/datadoghq/agent:7


.PHONY: create-byoc-postgres
create-byoc-postgres: ## Create PostgreSQL container for Datadog BYOC Logs.
	@echo "🐘 Creating BYOC PostgreSQL container..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-byoc-postgres.yml && \
	popd > /dev/null
	@echo "✅ BYOC PostgreSQL container created"


.PHONY: create-byoc-minio
create-byoc-minio: ## Create MinIO container for Datadog BYOC Logs.
	@echo "🪣 Creating BYOC MinIO container..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml create-byoc-minio.yml && \
	popd > /dev/null
	@echo "✅ BYOC MinIO container created"


.PHONY: destroy-byoc-postgres
destroy-byoc-postgres: ## Destroy PostgreSQL container for Datadog BYOC Logs.
	@echo "💥 Destroying BYOC PostgreSQL container..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-byoc-postgres.yml && \
	popd > /dev/null
	@echo "✅ BYOC PostgreSQL container destroyed"


.PHONY: destroy-byoc-minio
destroy-byoc-minio: ## Destroy MinIO container for Datadog BYOC Logs.
	@echo "💥 Destroying BYOC MinIO container..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-byoc-minio.yml && \
	popd > /dev/null
	@echo "✅ BYOC MinIO container destroyed"


.PHONY: install-cloudprem-container-stack
install-cloudprem-container-stack: ## Install Datadog BYOC Logs CloudPrem stack on cluster (uses external containers).
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "☁️ Installing Datadog CloudPrem BYOC Logs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-cloudprem.yml && \
	popd > /dev/null
	@echo "✅ CloudPrem installed"


.PHONY: uninstall-cloudprem-container-stack
uninstall-cloudprem-container-stack: ## Uninstall Datadog BYOC Logs CloudPrem stack from cluster.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Datadog CloudPrem BYOC Logs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml uninstall-cloudprem.yml && \
	popd > /dev/null
	@echo "✅ CloudPrem removed"


.PHONY: install-datadog-agent-server-host
install-datadog-agent-server-host: ## Deploy Datadog agent Podman container on desktop-server.
	@echo "📊 Installing Datadog agent on desktop-server..."
	@echo "   First run pulls a large container image and may take a few minutes."
	@pushd ansible > /dev/null && \
	DD_AGENT_IMAGE="$(DD_AGENT_IMAGE)" \
	ansible-playbook -i inventory.yml install-datadog-agent-server-host.yml && \
	popd > /dev/null
	@echo "✅ Datadog agent installed"


.PHONY: install-datadog-operator
install-datadog-operator: ## Install Datadog Operator required for DatadogAgent CRs.
	@echo "🧩 Installing Datadog Operator..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml install-datadog-operator.yml && \
	popd > /dev/null
	@echo "✅ Datadog Operator installed"


.PHONY: destroy-datadog-agent-server-host
destroy-datadog-agent-server-host: ## Remove Datadog agent Podman container from desktop-server.
	@echo "💥 Removing Datadog agent from desktop-server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-datadog-agent-server-host.yml && \
	popd > /dev/null
	@echo "✅ Datadog agent removed"


.PHONY: configure-datadog-agent-cluster-cloudprem
configure-datadog-agent-cluster-cloudprem: ## Configure in-cluster DatadogAgent CR to send logs to CloudPrem.
	@echo "📈 Configuring in-cluster DatadogAgent for CloudPrem logs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml configure-datadog-agent-cloudprem.yml && \
	popd > /dev/null
	@echo "✅ DatadogAgent configured for CloudPrem"


.PHONY: configure-datadog-cloudprem-all
configure-datadog-cloudprem-all: ## Run full Datadog CloudPrem setup (containers, DNS, stack, cluster agent, server agent).
	@echo "🚀 Running full Datadog CloudPrem setup..."
	@$(MAKE) create-byoc-postgres
	@$(MAKE) create-byoc-minio
	@$(MAKE) update-dns
	@$(MAKE) install-cloudprem-container-stack
	@$(MAKE) install-datadog-operator
	@$(MAKE) configure-datadog-agent-cluster-cloudprem
	@$(MAKE) install-datadog-agent-server-host
	@echo "✅ Datadog CloudPrem full setup complete"


.PHONY: undo-datadog-cloudprem-all
undo-datadog-cloudprem-all: ## Undo Datadog CloudPrem setup (server agent, cluster stack, BYOC containers).
	@echo "↩️ Undoing Datadog CloudPrem setup..."
	@$(MAKE) destroy-datadog-agent-server-host
	@$(MAKE) uninstall-cloudprem-container-stack
	@$(MAKE) destroy-byoc-minio
	@$(MAKE) destroy-byoc-postgres
	@echo "✅ Datadog CloudPrem teardown complete"


##@ Istio Ambient Mesh (Helm)

ISTIO_NAMESPACE ?= istio-system
ISTIO_HELM_REPO_NAME ?= istio
ISTIO_HELM_REPO_URL ?= https://istio-release.storage.googleapis.com/charts
ISTIO_BASE_RELEASE ?= istio-base
ISTIOD_RELEASE ?= istiod
ISTIO_CNI_RELEASE ?= istio-cni
ISTIO_ZTUNNEL_RELEASE ?= ztunnel
ISTIO_INGRESS_RELEASE ?= istio-ingress
ISTIO_INGRESS_CLASS_NAME ?= istio
ISTIO_CHART_VERSION ?=
GATEWAY_API_CRDS_URL ?= https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml


.PHONY: install-istio-gateway-api-crds
install-istio-gateway-api-crds: ## Install Gateway API CRDs (latest stable release, 1.5+ when available).
	@echo "🛣️ Installing Gateway API CRDs..."
	@pushd ansible > /dev/null && \
	GATEWAY_API_CRDS_URL="$(GATEWAY_API_CRDS_URL)" \
	ansible-playbook -i inventory.yml install-istio-gateway-api-crds.yml && \
	popd > /dev/null
	@echo "✅ Gateway API CRDs installed"


.PHONY: uninstall-istio-gateway-api-crds
uninstall-istio-gateway-api-crds: ## Uninstall Gateway API CRDs.
	@echo "🗑️ Uninstalling Gateway API CRDs..."
	@pushd ansible > /dev/null && \
	GATEWAY_API_CRDS_URL="$(GATEWAY_API_CRDS_URL)" \
	ansible-playbook -i inventory.yml uninstall-istio-gateway-api-crds.yml && \
	popd > /dev/null
	@echo "✅ Gateway API CRDs uninstall requested"


.PHONY: install-istio-crds
install-istio-crds: ## Install Istio CRDs and cluster roles from Helm base chart.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "📦 Installing Istio base chart (CRDs)..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_HELM_REPO_NAME="$(ISTIO_HELM_REPO_NAME)" \
	ISTIO_HELM_REPO_URL="$(ISTIO_HELM_REPO_URL)" \
	ISTIO_BASE_RELEASE="$(ISTIO_BASE_RELEASE)" \
	ISTIO_CHART_VERSION="$(ISTIO_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-istio-crds.yml && \
	popd > /dev/null
	@echo "✅ Istio CRDs installed"


.PHONY: uninstall-istio-crds
uninstall-istio-crds: ## Uninstall Istio base chart release (CRDs chart).
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Istio base chart release..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_BASE_RELEASE="$(ISTIO_BASE_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-istio-crds.yml && \
	popd > /dev/null
	@echo "✅ Istio base release uninstall requested"


.PHONY: install-istio
install-istio: ## Install Istiod control plane in ambient profile using Helm.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🧠 Installing Istiod (ambient profile)..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_HELM_REPO_NAME="$(ISTIO_HELM_REPO_NAME)" \
	ISTIO_HELM_REPO_URL="$(ISTIO_HELM_REPO_URL)" \
	ISTIOD_RELEASE="$(ISTIOD_RELEASE)" \
	ISTIO_CHART_VERSION="$(ISTIO_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-istio.yml && \
	popd > /dev/null
	@echo "✅ Istiod installed"


.PHONY: uninstall-istio
uninstall-istio: ## Uninstall Istiod control plane Helm release.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Istiod..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIOD_RELEASE="$(ISTIOD_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-istio.yml && \
	popd > /dev/null
	@echo "✅ Istiod uninstall requested"


.PHONY: install-istio-cni
install-istio-cni: ## Install Istio CNI (ambient profile) using Helm.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🕸️ Installing Istio CNI (ambient profile)..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_HELM_REPO_NAME="$(ISTIO_HELM_REPO_NAME)" \
	ISTIO_HELM_REPO_URL="$(ISTIO_HELM_REPO_URL)" \
	ISTIO_CNI_RELEASE="$(ISTIO_CNI_RELEASE)" \
	ISTIO_CHART_VERSION="$(ISTIO_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-istio-cni.yml && \
	popd > /dev/null
	@echo "✅ Istio CNI installed"


.PHONY: uninstall-istio-cni
uninstall-istio-cni: ## Uninstall Istio CNI Helm release.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Istio CNI..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_CNI_RELEASE="$(ISTIO_CNI_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-istio-cni.yml && \
	popd > /dev/null
	@echo "✅ Istio CNI uninstall requested"


.PHONY: install-istio-ztunnel
install-istio-ztunnel: ## Install ztunnel data plane for ambient mesh using Helm.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🔒 Installing ztunnel..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_HELM_REPO_NAME="$(ISTIO_HELM_REPO_NAME)" \
	ISTIO_HELM_REPO_URL="$(ISTIO_HELM_REPO_URL)" \
	ISTIO_ZTUNNEL_RELEASE="$(ISTIO_ZTUNNEL_RELEASE)" \
	ISTIO_CHART_VERSION="$(ISTIO_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-istio-ztunnel.yml && \
	popd > /dev/null
	@echo "✅ ztunnel installed"


.PHONY: uninstall-istio-ztunnel
uninstall-istio-ztunnel: ## Uninstall ztunnel Helm release.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling ztunnel..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_ZTUNNEL_RELEASE="$(ISTIO_ZTUNNEL_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-istio-ztunnel.yml && \
	popd > /dev/null
	@echo "✅ ztunnel uninstall requested"


.PHONY: install-istio-ingress
install-istio-ingress: ## Install Istio ingress gateway Helm chart.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "🌐 Installing Istio ingress gateway..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_HELM_REPO_NAME="$(ISTIO_HELM_REPO_NAME)" \
	ISTIO_HELM_REPO_URL="$(ISTIO_HELM_REPO_URL)" \
	ISTIO_INGRESS_RELEASE="$(ISTIO_INGRESS_RELEASE)" \
	ISTIO_CHART_VERSION="$(ISTIO_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-istio-ingress.yml && \
	popd > /dev/null
	@echo "✅ Istio ingress gateway installed"


.PHONY: uninstall-istio-ingress
uninstall-istio-ingress: ## Uninstall Istio ingress gateway Helm release.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling Istio ingress gateway..."
	@pushd ansible > /dev/null && \
	ISTIO_NAMESPACE="$(ISTIO_NAMESPACE)" \
	ISTIO_INGRESS_RELEASE="$(ISTIO_INGRESS_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-istio-ingress.yml && \
	popd > /dev/null
	@echo "✅ Istio ingress gateway uninstall requested"


.PHONY: install-istio-ingress-class
install-istio-ingress-class: ## Install IngressClass resource for Istio ingress controller.
	@echo "🚦 Installing Istio ingress class..."
	@pushd ansible > /dev/null && \
	ISTIO_INGRESS_CLASS_NAME="$(ISTIO_INGRESS_CLASS_NAME)" \
	ansible-playbook -i inventory.yml install-istio-ingress-class.yml && \
	popd > /dev/null
	@echo "✅ Istio ingress class installed"


.PHONY: uninstall-istio-ingress-class
uninstall-istio-ingress-class: ## Uninstall IngressClass resource for Istio ingress controller.
	@echo "🗑️ Uninstalling Istio ingress class..."
	@pushd ansible > /dev/null && \
	ISTIO_INGRESS_CLASS_NAME="$(ISTIO_INGRESS_CLASS_NAME)" \
	ansible-playbook -i inventory.yml uninstall-istio-ingress-class.yml && \
	popd > /dev/null
	@echo "✅ Istio ingress class uninstall requested"


.PHONY: install-istio-all
install-istio-all: ## Install full Istio ambient stack: Gateway API CRDs, base, istiod, cni, ztunnel, ingress, ingress class.
	@echo "🚀 Installing full Istio ambient stack..."
	@$(MAKE) install-istio-gateway-api-crds
	@$(MAKE) install-istio-crds
	@$(MAKE) install-istio
	@$(MAKE) install-istio-cni
	@$(MAKE) install-istio-ztunnel
	@$(MAKE) install-istio-ingress
	@$(MAKE) install-istio-ingress-class
	@echo "✅ Full Istio ambient stack installation complete"


.PHONY: uninstall-istio-all
uninstall-istio-all: ## Uninstall full Istio ambient stack in reverse order.
	@echo "↩️ Uninstalling full Istio ambient stack..."
	@$(MAKE) uninstall-istio-ingress-class
	@$(MAKE) uninstall-istio-ingress
	@$(MAKE) uninstall-istio-ztunnel
	@$(MAKE) uninstall-istio-cni
	@$(MAKE) uninstall-istio
	@$(MAKE) uninstall-istio-crds
	@$(MAKE) uninstall-istio-gateway-api-crds
	@echo "✅ Full Istio ambient stack uninstall complete"


##@ MetalLB (Helm)

METALLB_NAMESPACE ?= metallb-system
METALLB_HELM_REPO_NAME ?= metallb
METALLB_HELM_REPO_URL ?= https://metallb.github.io/metallb
METALLB_HELM_RELEASE ?= metallb
METALLB_CHART_VERSION ?=
METALLB_ADDRESS_RANGE ?= 192.168.1.230-192.168.1.249
METALLB_IPADDRESSPOOL_NAME ?= default-address-pool
METALLB_L2ADVERTISEMENT_NAME ?= default-l2-advertisement


.PHONY: install-metallb
install-metallb: ## Install MetalLB via upstream Helm chart (not OperatorHub).
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Install Helm 3.x and retry."; \
	  exit 1; \
	fi
	@echo "📦 Installing MetalLB Helm chart..."
	@pushd ansible > /dev/null && \
	METALLB_NAMESPACE="$(METALLB_NAMESPACE)" \
	METALLB_HELM_REPO_NAME="$(METALLB_HELM_REPO_NAME)" \
	METALLB_HELM_REPO_URL="$(METALLB_HELM_REPO_URL)" \
	METALLB_HELM_RELEASE="$(METALLB_HELM_RELEASE)" \
	METALLB_CHART_VERSION="$(METALLB_CHART_VERSION)" \
	ansible-playbook -i inventory.yml install-metallb.yml && \
	popd > /dev/null
	@echo "✅ MetalLB installed"


.PHONY: uninstall-metallb
uninstall-metallb: ## Uninstall MetalLB Helm release and SCC bindings.
	@if ! command -v helm >/dev/null 2>&1; then \
	  echo "❌ helm is not installed. Cannot uninstall Helm release."; \
	  exit 1; \
	fi
	@echo "🗑️ Uninstalling MetalLB Helm chart..."
	@pushd ansible > /dev/null && \
	METALLB_NAMESPACE="$(METALLB_NAMESPACE)" \
	METALLB_HELM_RELEASE="$(METALLB_HELM_RELEASE)" \
	ansible-playbook -i inventory.yml uninstall-metallb.yml && \
	popd > /dev/null
	@echo "✅ MetalLB uninstall requested"


.PHONY: install-metallb-l2-config
install-metallb-l2-config: ## Install MetalLB IPAddressPool and L2Advertisement resources.
	@echo "🛣️ Installing MetalLB L2 configuration..."
	@pushd ansible > /dev/null && \
	METALLB_NAMESPACE="$(METALLB_NAMESPACE)" \
	METALLB_ADDRESS_RANGE="$(METALLB_ADDRESS_RANGE)" \
	METALLB_IPADDRESSPOOL_NAME="$(METALLB_IPADDRESSPOOL_NAME)" \
	METALLB_L2ADVERTISEMENT_NAME="$(METALLB_L2ADVERTISEMENT_NAME)" \
	ansible-playbook -i inventory.yml install-metallb-l2-config.yml && \
	popd > /dev/null
	@echo "✅ MetalLB L2 configuration installed"


.PHONY: uninstall-metallb-l2-config
uninstall-metallb-l2-config: ## Uninstall MetalLB IPAddressPool and L2Advertisement resources.
	@echo "🗑️ Uninstalling MetalLB L2 configuration..."
	@pushd ansible > /dev/null && \
	METALLB_NAMESPACE="$(METALLB_NAMESPACE)" \
	METALLB_IPADDRESSPOOL_NAME="$(METALLB_IPADDRESSPOOL_NAME)" \
	METALLB_L2ADVERTISEMENT_NAME="$(METALLB_L2ADVERTISEMENT_NAME)" \
	ansible-playbook -i inventory.yml uninstall-metallb-l2-config.yml && \
	popd > /dev/null
	@echo "✅ MetalLB L2 configuration uninstall requested"
