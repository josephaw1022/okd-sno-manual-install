#!/usr/bin/env bash

# Note: Not using 'set -e' because some commands may return non-zero but are harmless

CLUSTER_NAME="${1}"
BASE_DOMAIN="${2}"
CILIUM_VERSION="${3:-1.15.1}"
OUTPUT_DIR="cluster/openshift"

if [[ -z "$CLUSTER_NAME" || -z "$BASE_DOMAIN" ]]; then
  echo "Usage: $0 <CLUSTER_NAME> <BASE_DOMAIN> [CILIUM_VERSION]"
  exit 1
fi

API_HOST="api.${CLUSTER_NAME}.${BASE_DOMAIN}"

echo "📝 Generating Cilium ${CILIUM_VERSION} manifests for OKD (no OLM)..."
echo "   Cluster: ${CLUSTER_NAME}.${BASE_DOMAIN}"
echo "   API: ${API_HOST}"

mkdir -p "${OUTPUT_DIR}"

# Add Cilium Helm repo
helm repo add cilium https://helm.cilium.io/ 2>/dev/null || true
helm repo update cilium > /dev/null 2>&1

# Generate the manifests using helm template (no cluster connection needed)
helm template cilium cilium/cilium \
  --version "${CILIUM_VERSION}" \
  --namespace cilium \
  --set cluster.name="${CLUSTER_NAME}" \
  --set cluster.id=1 \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost="${API_HOST}" \
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
  > "${OUTPUT_DIR}/cilium-combined.yaml"

# Split the big manifest into numbered files for proper ordering
echo "📋 Splitting manifests into separate files..."
pushd "${OUTPUT_DIR}" > /dev/null
awk 'BEGIN{file="cilium-part-0.yaml"} /^---$/{file=sprintf("cilium-part-%d.yaml",++i);next} {print > file}' cilium-combined.yaml

# Rename files with proper prefixes for OpenShift ordering
counter=0
for file in cilium-part-*.yaml; do
  if [ -f "$file" ] && [ -s "$file" ]; then
    # Pad counter to 5 digits for proper sorting
    newname="cluster-network-06-cilium-$(printf "%05d" $counter).yaml"
    mv "$file" "$newname" 2>/dev/null || true
    ((counter++))
  fi
done

# Remove the combined file
rm -f cilium-combined.yaml
popd > /dev/null

echo "✅ Cilium manifests generated in ${OUTPUT_DIR}/"
echo "   Total files: ${counter}"
echo "   k8sServiceHost: ${API_HOST}"
echo "   Deployment: Direct Helm (no OLM) for OKD compatibility"
