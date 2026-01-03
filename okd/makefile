# Makefile for OKD 3-Node Master Cluster with Libvirt (Agent-Based Installer)

OKD_VERSION ?= 4.20.0-okd-scos.15
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
SSH_KEY ?= ~/.ssh/id_ed25519.pub
MACHINE_NETWORK_CIDR ?= 192.168.0.0/21

# Node IPs for 3 master nodes
MASTER0_IP ?= 192.168.1.10
MASTER1_IP ?= 192.168.1.13
MASTER2_IP ?= 192.168.1.12

# Gateway/DNS server
GATEWAY_IP ?= 192.168.1.1

# Libvirt VM settings
VM_CPUS ?= 4
VM_MEMORY ?= 41984
VM_DISK_SIZE ?= 120

# Remote server settings
SERVER_HOST ?= 192.168.1.100
SERVER_USER ?= root

OC_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-client-linux-$(OKD_VERSION).tar.gz
INSTALLER_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-install-linux-$(OKD_VERSION).tar.gz

.PHONY: help
help: ## Show available Makefile commands.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

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

.PHONY: fcos
fcos: ## Download the FCOS ISO (for reference, agent-iso creates its own).
	@echo "🔍 Fetching CoreOS ISO URL for $(ARCH)..."
	@ISO_URL=$$(openshift-install coreos print-stream-json \
		| jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'); \
	[ -n "$$ISO_URL" ] || { echo "❌ No ISO URL found"; exit 1; }; \
	echo "➡️  $$ISO_URL"; \
	curl -L "$$ISO_URL" -o fcos-live.iso



.PHONY: config
config: ## Generate install-config.yaml and agent-config.yaml.
	./scripts/generate-install-config.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(SSH_KEY) $(MACHINE_NETWORK_CIDR) $(MASTER0_IP) $(MASTER1_IP) $(MASTER2_IP)


.PHONY: agent-iso
agent-iso: ## Generate the agent-based installer ISO (single ISO for all nodes).
	@echo "📦 Generating agent-based installer ISO..."
	mkdir -p cluster
	cp install-config.yaml cluster/
	cp agent-config.yaml cluster/
	openshift-install --dir=cluster agent create image
	@echo "✅ Agent ISO created: cluster/agent.x86_64.iso"


.PHONY: format-files
format-files: ## Format all .ign and .json files in cluster/ using jq.
	@echo "✨ Formatting .ign and .json files in cluster/..."
	@find cluster -type f \( -name '*.ign' -o -name '*.json' \) -exec sh -c 'jq . {} > tmp && mv tmp {}' \;
	@echo "✅ Files formatted."



.PHONY: clean
clean: ## Clean up generated files.
	@echo "🧹 Cleaning up..."
	rm -f oc.tar.gz openshift-install.tar.gz oc openshift-install fcos-live.iso
	rm -rf cluster/* install-config.yaml agent-config.yaml _rendered



.PHONY: build
build: ## Build the agent-based installer ISO for 3-node cluster.
	@echo "🔨 Building the OKD 3-Node Agent Installer ISO..."
	@$(MAKE) config
	@$(MAKE) agent-iso
	@echo ""
	@echo "✅ ISO ready: cluster/agent.x86_64.iso"
	@echo "📋 Copy this ISO to your libvirt server and boot all 3 VMs from it"


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
	@ssh core@$(MASTER0_IP) "journalctl -b -f -u agent.service"


.PHONY: wait-install
wait-install: ## Wait for installation to complete.
	@echo "⏳ Waiting for installation to complete..."
	openshift-install --dir=cluster agent wait-for install-complete --log-level=info


.PHONY: approve-csrs
approve-csrs: ## Approve pending CSRs for nodes.
	@echo "✅ Approving pending CSRs..."
	@oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs -r oc adm certificate approve





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


.PHONY: copy-iso
copy-iso: ## Copy the agent ISO to the libvirt server via Ansible.
	@echo "📤 Copying ISO to server..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml copy-iso.yml && \
	popd > /dev/null
	@echo "✅ ISO copied to server"


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


.PHONY: destroy-vms
destroy-vms: ## Destroy all VMs and delete disk images via Ansible.
	@echo "💥 Destroying VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs destroyed"


.PHONY: update-dns
update-dns: ## Update Pi-hole DNS config for OKD cluster.
	@echo "🌐 Updating Pi-hole DNS configuration..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml update-pihole-dns.yml && \
	popd > /dev/null
	@echo "✅ DNS updated"


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


.PHONY: apply-ingress-cert
apply-ingress-cert: ## Apply Let's Encrypt wildcard cert to OKD ingress.
	@echo "🔒 Applying ingress certificate..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml apply-ingress-cert.yml && \
	popd > /dev/null
	@echo "✅ Ingress certificate applied"


