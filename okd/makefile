# Makefile for Single Node OKD Install

OKD_VERSION ?= 4.19.0-okd-scos.3
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
DISK_ID ?= wwn-0x500a0751435cebaf
SSH_KEY ?= ~/.ssh/id_ed25519.pub

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

.PHONY: download-oc
download-oc: ## Download the OKD oc CLI.
	@echo "⬇️ Downloading oc CLI..."
	curl -L $(OC_URL) -o oc.tar.gz
	tar zxf oc.tar.gz
	chmod +x oc
	sudo mv ./oc /usr/local/bin/

.PHONY: download-installer
download-installer: ## Download the OKD openshift-install binary.
	@echo "⬇️ Downloading openshift-install..."
	@tempdir=$$(mktemp -d) && \
	cd $$tempdir && \
	curl -L $(INSTALLER_URL) -o openshift-install.tar.gz && \
	tar zxvf openshift-install.tar.gz && \
	chmod +x openshift-install && \
	sudo mv ./openshift-install /usr/local/bin/

.PHONY: fetch-fcos
fetch-fcos: ## Fetch the Fedora CoreOS (FCOS) ISO for the given architecture.
	@echo "🔍 Fetching FCOS ISO URL..."
	export ISO_URL=`openshift-install coreos print-stream-json | grep location | grep $(ARCH) | grep iso | cut -d\" -f4` && \
	curl -L $$ISO_URL -o fcos-live.iso

.PHONY: config
config: ## Generate install-config.yaml using a helper script.
	./scripts/generate-install-config.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(DISK_ID) $(SSH_KEY)


.PHONY: gen-ignition
gen-ignition: ## Generate single-node ignition configuration.
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
	rm -rf sno install-config.yaml
