# Makefile for OKD 3-Node Master Cluster with Libvirt (Agent-Based Installer)

OKD_VERSION ?= 4.20.0-okd-scos.8
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
SSH_KEY ?= ~/.ssh/id_ed25519.pub
MACHINE_NETWORK_CIDR ?= 192.168.0.0/21

# Node IPs for 3 master nodes
MASTER0_IP ?= 192.168.1.10
MASTER1_IP ?= 192.168.1.11
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
deps: ## Install dependencies (podman).
	@echo "🔧 Installing dependencies (podman)..."
	sudo dnf install -y podman

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