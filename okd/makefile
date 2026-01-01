# Makefile for OKD 3-Node Master Cluster with Libvirt

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
API_VIP ?= 192.168.1.9

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
fcos:
	@echo "🔍 Fetching CoreOS ISO URL for $(ARCH)..."
	@ISO_URL=$$(openshift-install coreos print-stream-json \
		| jq -r '.architectures.x86_64.artifacts.metal.formats.iso.disk.location'); \
	[ -n "$$ISO_URL" ] || { echo "❌ No ISO URL found"; exit 1; }; \
	echo "➡️  $$ISO_URL"; \
	curl -L "$$ISO_URL" -o fcos-live.iso



.PHONY: config
config: ## Generate install-config.yaml using a helper script.
	./scripts/generate-install-config.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(SSH_KEY) $(MACHINE_NETWORK_CIDR)


.PHONY: ignition
ignition: ## Generate ignition configurations for 3-node cluster.
	@echo "📦 Generating ignition configs for 3-node cluster..."
	mkdir -p cluster
	cp install-config.yaml cluster/
	openshift-install --dir=cluster create manifests
	openshift-install --dir=cluster create ignition-configs
	@echo "✅ Ignition configs created in cluster/"


.PHONY: format-sno-files
format-sno-files: ## Format all .ign and .json files in cluster/ using jq.
	@echo "✨ Formatting .ign and .json files in cluster/..."
	@find cluster -type f \( -name '*.ign' -o -name '*.json' \) -exec sh -c 'jq . {} > tmp && mv tmp {}' \;
	@echo "✅ Files formatted."



.PHONY: iso
iso: ## Create bootable ISOs for bootstrap and master nodes.
	@echo "💾 Creating master ISO with embedded ignition..."
	@cp fcos-live.iso fcos-master.iso
	@podman run --privileged --pull always --rm \
		-v /dev:/dev \
		-v /run/udev:/run/udev \
		-v $(PWD):/data \
		-w /data \
		quay.io/coreos/coreos-installer:release \
		iso ignition embed -fi cluster/master.ign fcos-master.iso
	@echo "💾 Creating bootstrap ISO with embedded ignition..."
	@cp fcos-live.iso fcos-bootstrap.iso
	@podman run --privileged --pull always --rm \
		-v /dev:/dev \
		-v /run/udev:/run/udev \
		-v $(PWD):/data \
		-w /data \
		quay.io/coreos/coreos-installer:release \
		iso ignition embed -fi cluster/bootstrap.ign fcos-bootstrap.iso
	@echo "✅ ISOs created: fcos-master.iso, fcos-bootstrap.iso"



.PHONY: clean
clean: ## Clean up generated files.
	@echo "🧹 Cleaning up..."
	rm -f oc.tar.gz openshift-install.tar.gz oc openshift-install fcos-live.iso fcos-master.iso fcos-bootstrap.iso
	rm -rf cluster/* install-config.yaml _rendered



.PHONY: build
build: ## Build the OKD 3-node cluster installer (FCOS, config, ignition, format, iso).
	@echo "🔨 Building the OKD 3-Node Cluster Installer..."
	@$(MAKE) fcos
	@$(MAKE) config
	@$(MAKE) ignition
	@$(MAKE) format-sno-files
	@$(MAKE) iso


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
watch-bootstrap: ## SSH into bootstrap node and tail logs.
	@echo "👀 Watching bootstrap services on bootstrap node..."
	@ssh core@$(MASTER0_IP) "journalctl -b -f -u release-image.service -u bootkube.service"


.PHONY: wait-bootstrap
wait-bootstrap: ## Wait for bootstrap to complete.
	@echo "⏳ Waiting for bootstrap to complete..."
	openshift-install --dir=cluster wait-for bootstrap-complete --log-level=info


.PHONY: wait-install
wait-install: ## Wait for installation to complete.
	@echo "⏳ Waiting for installation to complete..."
	openshift-install --dir=cluster wait-for install-complete --log-level=info


.PHONY: approve-csrs
approve-csrs: ## Approve pending CSRs for nodes.
	@echo "✅ Approving pending CSRs..."
	@oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs -r oc adm certificate approve





.PHONY: extract-manifests
extract-manifests: ## Extract bootstrap manifests from the single-node ignition config.
	./scripts/extract-bootstrap-manifests.sh

.PHONY: render-manifests
render-manifests: ## Render manifests using openshift-install (for inspection/customization).
	mkdir -p _rendered
	cp install-config.yaml _rendered/
	openshift-install create manifests --dir _rendered
	@echo "✅ Manifests rendered to _rendered/"
	@echo "📝 Modify files in _rendered/manifests/ and _rendered/openshift/ as needed"
	@echo "👉 Then run: make ignition-from-manifests"


.PHONY: ignition-from-manifests
ignition-from-manifests: ## Generate ignition configs from customized manifests in _rendered/.
	@echo "📦 Generating ignition from customized manifests..."
	@if [ ! -d "_rendered/manifests" ]; then \
	  echo "❌ No manifests found. Run 'make render-manifests' first and customize."; \
	  exit 1; \
	fi
	openshift-install create ignition-configs --dir=_rendered
	@echo "✅ Ignition configs generated in _rendered/"
	@echo "📁 Copying to cluster/ for ISO embedding..."
	mkdir -p cluster/auth
	cp _rendered/master.ign cluster/
	cp _rendered/bootstrap.ign cluster/
	cp _rendered/worker.ign cluster/
	cp _rendered/metadata.json cluster/
	cp -r _rendered/auth/* cluster/auth/
	@echo "✅ Files ready. Run 'make iso' to create the ISOs."


.PHONY: build-custom
build-custom: ## Build with custom manifests: fcos → config → render-manifests → (pause to edit) → ignition-from-manifests → iso
	@echo "🔨 Building OKD 3-Node Cluster with custom manifest support..."
	@$(MAKE) fcos
	@$(MAKE) config
	@$(MAKE) render-manifests
	@echo ""
	@echo "⏸️  PAUSED: Edit manifests in _rendered/manifests/ and _rendered/openshift/"
	@echo "   Then run: make ignition-from-manifests && make format-sno-files && make iso"