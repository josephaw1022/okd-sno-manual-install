# Makefile for Single Node OKD Install

OKD_VERSION ?= 4.20.0-okd-scos.8
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
DISK_ID ?= wwn-0x500a0751435cebaf
SSH_KEY ?= ~/.ssh/id_ed25519.pub
NODE_IP ?= 192.168.1.9

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
	./scripts/generate-install-config.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(DISK_ID) $(SSH_KEY)


.PHONY: ignition
ignition: ## Generate single-node ignition configuration.
	@echo "📦 Generating ignition configs..."
	mkdir -p sno
	cp install-config.yaml sno
	openshift-install --dir=sno create single-node-ignition-config


.PHONY: format-sno-files
format-sno-files: ## Format all .ign and .json files in sno/ using jq.
	@echo "✨ Formatting .ign and .json files in sno/..."
	@find sno -type f \( -name '*.ign' -o -name '*.json' \) -exec sh -c 'jq . {} > tmp && mv tmp {}' \;
	@echo "✅ Files formatted."



.PHONY: iso
iso: ## Embed the ignition config into the FCOS ISO.
	@echo "💾 Embedding ignition into FCOS ISO..."
	@podman run --privileged --pull always --rm \
		-v /dev:/dev \
		-v /run/udev:/run/udev \
		-v $(PWD):/data \
		-w /data \
		quay.io/coreos/coreos-installer:release \
		iso ignition embed -fi sno/bootstrap-in-place-for-live-iso.ign fcos-live.iso



.PHONY: clean
clean: ## Clean up generated files.
	@echo "🧹 Cleaning up..."
	rm -f oc.tar.gz openshift-install.tar.gz oc openshift-install fcos-live.iso
	rm -rf sno/* install-config.yaml fcos-live.iso _rendered



.PHONY: build
build: ## Build the OKD Single Node Installer e2e with all steps (FCOS, config, ignition, format-sno-files, iso). Does not install oc or openshift-install.
	@echo "🔨 Building the OKD Single Node Installer..."
	@$(MAKE) fcos
	@$(MAKE) config
	@$(MAKE) ignition
	@$(MAKE) format-sno-files
	@$(MAKE) iso


.PHONY: use-kubeconfig
use-kubeconfig: ## Replace ~/.kube/config with sno/auth/kubeconfig
	@echo "🔁 Replacing ~/.kube/config with sno/auth/kubeconfig..."
	@pushd sno/auth > /dev/null && \
	if [ -f kubeconfig ]; then \
	  mkdir -p $$HOME/.kube && \
	  cp kubeconfig $$HOME/.kube/config && \
	  chmod 600 $$HOME/.kube/config && \
	  echo "✅ kubeconfig moved to ~/.kube/config"; \
	else \
	  echo "❌ kubeconfig not found in sno/auth"; \
	fi && \
	popd > /dev/null


.PHONY: clean-known-hosts
clean-known-hosts: ## Remove entries with node IP from known_hosts.
	@echo "🧼 Cleaning known_hosts entries for node IP..."
	@if [ -z "$(NODE_IP)" ]; then \
	  echo "❌ NODE_IP not set. Run with: make clean-known-hosts NODE_IP=192.168.x.x"; \
	  exit 1; \
	fi
	@KNOWN_HOSTS_FILE=$$HOME/.ssh/known_hosts; \
	if [ -f $$KNOWN_HOSTS_FILE ]; then \
	  grep -v "$(NODE_IP)" $$KNOWN_HOSTS_FILE > $$KNOWN_HOSTS_FILE.tmp && \
	  mv $$KNOWN_HOSTS_FILE.tmp $$KNOWN_HOSTS_FILE && \
	  echo "✅ Removed entries for IP: $(NODE_IP)"; \
	else \
	  echo "⚠️ No known_hosts file found at $$KNOWN_HOSTS_FILE"; \
	fi


.PHONY: watch-bootstrap
watch-bootstrap: ## SSH into the node and tail release-image and bootkube logs.
	@echo "👀 Watching bootstrap services on node..."
	@if [ -z "$(NODE_IP)" ]; then \
	  echo "❌ NODE_IP not set. Usage: make watch-bootstrap NODE_IP=192.168.1.6"; \
	  exit 1; \
	fi
	@ssh core@$(NODE_IP) "journalctl -b -f -u release-image.service -u bootkube.service"





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
	openshift-install create single-node-ignition-config --dir=_rendered
	@echo "✅ Ignition configs generated in _rendered/"
	@echo "📁 Copying to sno/ for ISO embedding..."
	mkdir -p sno/auth
	cp _rendered/bootstrap-in-place-for-live-iso.ign sno/
	cp _rendered/metadata.json sno/
	cp -r _rendered/auth/* sno/auth/
	@echo "✅ Files ready. Run 'make iso' to embed into the FCOS ISO."


.PHONY: build-custom
build-custom: ## Build with custom manifests: fcos → config → render-manifests → (pause to edit) → ignition-from-manifests → iso
	@echo "🔨 Building OKD Single Node Installer with custom manifest support..."
	@$(MAKE) fcos
	@$(MAKE) config
	@$(MAKE) render-manifests
	@echo ""
	@echo "⏸️  PAUSED: Edit manifests in _rendered/manifests/ and _rendered/openshift/"
	@echo "   Then run: make ignition-from-manifests && make format-sno-files && make iso"