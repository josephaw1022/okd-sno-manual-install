# Makefile for OKD 3-Node Master Cluster with Libvirt (Agent-Based Installer)

OKD_VERSION ?= 4.21.0-okd-scos.ec.13
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

# Cilium CNI settings
CILIUM_VERSION ?= 1.16.5

OC_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-client-linux-$(OKD_VERSION).tar.gz
INSTALLER_URL = https://github.com/okd-project/okd/releases/download/$(OKD_VERSION)/openshift-install-linux-$(OKD_VERSION).tar.gz

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


##@ ISO & Manifest Generation

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


.PHONY: cluster-manifests
cluster-manifests: ## Generate cluster manifests for modification before ISO creation.
	@echo "📋 Generating cluster manifests..."
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


.PHONY: install-cilium-cli
install-cilium-cli: ## Install Cilium CLI if not present.
	@if ! command -v cilium &> /dev/null; then \
		echo "📦 Installing Cilium CLI..."; \
		CILIUM_CLI_VERSION=$$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt); \
		CLI_ARCH=amd64; \
		curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/$${CILIUM_CLI_VERSION}/cilium-linux-$${CLI_ARCH}.tar.gz{,.sha256sum}; \
		sha256sum --check cilium-linux-$${CLI_ARCH}.tar.gz.sha256sum; \
		sudo tar xzvfC cilium-linux-$${CLI_ARCH}.tar.gz /usr/local/bin; \
		rm cilium-linux-$${CLI_ARCH}.tar.gz{,.sha256sum}; \
		echo "✅ Cilium CLI installed"; \
	else \
		echo "✅ Cilium CLI already installed"; \
	fi


.PHONY: generate-cilium-manifests
generate-cilium-manifests: create-manifests install-cilium-cli ## Generate Cilium manifests for OKD without OLM.
	@echo "📋 Generating Cilium v$(CILIUM_VERSION) manifests for OKD (no OLM)..."
	chmod +x ./scripts/generate-cilium-manifests-okd.sh
	./scripts/generate-cilium-manifests-okd.sh $(CLUSTER_NAME) $(BASE_DOMAIN) $(CILIUM_VERSION)
	@echo "✅ Cilium manifests generated for OKD"


.PHONY: clean-cilium-tmp
clean-cilium-tmp: ## Clean up temporary Cilium OLM directory.
	@echo "🧹 Cleaning up Cilium temp directory..."
	rm -rf $(CILIUM_TMP_DIR)
	@echo "✅ Cleaned $(CILIUM_TMP_DIR)"


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
build: ## Build the agent-based installer ISO for 3-node cluster with Cilium CNI manifests.
	@echo "🔨 Building the OKD 3-Node Agent Installer ISO..."
	@$(MAKE) config
	@$(MAKE) generate-cilium-manifests
	@$(MAKE) agent-iso
	@echo ""
	@echo "✅ ISO ready: cluster/agent.x86_64.iso"
	@echo "📋 Optional: make delete-iso (to clean up old ISO on server)"
	@echo "📋 Next step: make copy-iso"
	@echo ""
	@echo "⚠️  IMPORTANT: After cluster bootstrap, run 'make install-cilium' to install CNI"


.PHONY: build-with-manifest-edit
build-with-manifest-edit: ## Build ISO with ability to edit default manifests before ISO creation.
	@echo "🔨 Building OKD manifests for editing..."
	@$(MAKE) config
	@$(MAKE) cluster-manifests
	@$(MAKE) generate-cilium-manifests
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


.PHONY: destroy-vms
destroy-vms: ## Destroy all VMs and delete disk images via Ansible.
	@echo "💥 Destroying VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml destroy-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs destroyed"


.PHONY: start-vms
start-vms: ## Start all stopped VMs on the libvirt server via Ansible.
	@echo "▶️ Starting all stopped VMs..."
	@pushd ansible > /dev/null && \
	ansible-playbook -i inventory.yml start-vms.yml && \
	popd > /dev/null
	@echo "✅ VMs started"
	@echo ""
	@echo "📋 After nodes are ready, run 'make install-cilium' to add Cilium CNI so that the master nodes can communicate to the bootstrap node and the pods can communicate"


.PHONY: reboot-non-bootstrap
reboot-non-bootstrap: ## Reboot master-1 and master-2 (non-bootstrap nodes).
	@echo "🔄 Rebooting non-bootstrap nodes (master-1 and master-2)..."
	@pushd ansible > /dev/null && \
	MASTER1_IP=$(MASTER1_IP) MASTER2_IP=$(MASTER2_IP) \
	ansible-playbook -i inventory.yml reboot-non-bootstrap.yml && \
	popd > /dev/null
	@echo "✅ Non-bootstrap nodes rebooted"


##@ Infrastructure (DNS, Load Balancer)

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


##@ Cilium CNI

.PHONY: install-cilium
install-cilium: install-cilium-cli ## Install Cilium CNI on running OKD cluster (post-bootstrap).
	@echo "🗑️ Removing existing Cilium workloads (if any)..."
	-kubectl delete -i=false namespace cilium cilium-secrets --ignore-not-found=true --wait=true 2>/dev/null || true
	-@kubectl get clusterroles -o name 2>/dev/null | grep -E 'cilium|hubble' | xargs -r kubectl delete -i=false --ignore-not-found=true 2>/dev/null || true
	-@kubectl get clusterrolebindings -o name 2>/dev/null | grep -E 'cilium|hubble' | xargs -r kubectl delete -i=false --ignore-not-found=true 2>/dev/null || true
	-@kubectl get crd -o name 2>/dev/null | grep cilium | xargs -r kubectl delete -i=false --ignore-not-found=true 2>/dev/null || true
	-@kubectl get ingressclass -o name 2>/dev/null | grep cilium | xargs -r kubectl delete -i=false --ignore-not-found=true 2>/dev/null || true
	-@kubectl get gatewayclass -o name 2>/dev/null | grep cilium | xargs -r kubectl delete -i=false --ignore-not-found=true 2>/dev/null || true
	-@kubectl get configmap -n kube-system cilium-config --ignore-not-found=true -o name 2>/dev/null | xargs -r kubectl delete -i=false -n kube-system --ignore-not-found=true 2>/dev/null || true
	@echo "🌐 Installing Cilium $(CILIUM_VERSION) on OKD cluster..."
	cilium install \
		--version $(CILIUM_VERSION) \
		--set cluster.name=$(CLUSTER_NAME) \
		--set cluster.id=1 \
		--set kubeProxyReplacement=true \
		--set k8sServiceHost=api.$(CLUSTER_NAME).$(BASE_DOMAIN) \
		--set k8sServicePort=6443 \
		--set ipam.mode=cluster-pool \
		--set ipam.operator.clusterPoolIPv4PodCIDRList="{10.128.0.0/14}" \
		--set ipam.operator.clusterPoolIPv4MaskSize=20 \
		--set cni.binPath=/var/lib/cni/bin \
		--set cni.confPath=/etc/kubernetes/cni/net.d \
		--set cni.exclusive=false \
		--set securityContext.privileged=true \
		--set nodeinit.enabled=true \
		--set hubble.enabled=true \
		--set hubble.relay.enabled=true \
		--set hubble.ui.enabled=true \
		--set ingressController.enabled=true \
		--set ingressController.loadbalancerMode=shared \
		--set ingressController.enableProxyProtocol=true \
		--set gatewayAPI.enabled=true \
		--set gatewayAPI.enableProxyProtocol=true \
		--wait=false
	@echo "✅ Cilium installed - run 'cilium status' to verify"


.PHONY: cilium-status
cilium-status: ## Check Cilium CNI status.
	@cilium status


.PHONY: fix-multus-cni
fix-multus-cni: ## Fix multus CNI by symlinking Cilium config to multus autoconfig dir.
	@echo "🔧 Fixing multus CNI configuration..."
	@./cluster-setup/fix-multus-cni.sh
	@echo "✅ Multus CNI fixed"


.PHONY: uninstall-cilium
uninstall-cilium: ## Uninstall Cilium CNI from cluster.
	@echo "🗑️ Uninstalling Cilium..."
	cilium uninstall --wait
	@echo "✅ Cilium uninstalled"


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
