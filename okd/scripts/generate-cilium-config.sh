#!/usr/bin/env bash

set -e

CLUSTER_NAME="${1}"
BASE_DOMAIN="${2}"
OUTPUT_FILE="${3:-cluster/openshift/cluster-network-07-cilium-ciliumconfig.yaml}"

if [[ -z "$CLUSTER_NAME" || -z "$BASE_DOMAIN" ]]; then
  echo "Usage: $0 <CLUSTER_NAME> <BASE_DOMAIN> [OUTPUT_FILE]"
  exit 1
fi

API_HOST="api.${CLUSTER_NAME}.${BASE_DOMAIN}"

echo "📝 Generating CiliumConfig for ${API_HOST}..."

cat > "${OUTPUT_FILE}" <<EOF
apiVersion: cilium.io/v1alpha1
kind: CiliumConfig
metadata:
  name: cilium
  namespace: cilium
spec:
  kubeProxyReplacement: "true"
  k8sServiceHost: ${API_HOST}
  k8sServicePort: "6443"
  ipam:
    mode: "cluster-pool"
    operator:
      clusterPoolIPv4PodCIDRList: "10.128.0.0/14"
      clusterPoolIPv4MaskSize: 23
  cni:
    binPath: "/var/lib/cni/bin"
    confPath: "/var/run/multus/cni/net.d"
    exclusive: false
  nodeinit:
    enabled: true
  securityContext:
    privileged: true
  sessionAffinity: true
  prometheus:
    enabled: true
    serviceMonitor: {enabled: false}
  hubble:
    enabled: true
    tls: {enabled: false}
    relay: {enabled: true}
  operator:
    unmanagedPodWatcher:
      restart: false
EOF

echo "✅ CiliumConfig generated: ${OUTPUT_FILE}"
echo "   k8sServiceHost: ${API_HOST}"
