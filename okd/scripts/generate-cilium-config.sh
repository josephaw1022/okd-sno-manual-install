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
  sessionAffinity: true
  securityContext:
    privileged: true
  kubeProxyReplacement: strict
  k8sServiceHost: ${API_HOST}
  k8sServicePort: 6443
  ipam:
    mode: "cluster-pool"
    operator:
      clusterPoolIPv4PodCIDRList: "10.128.0.0/14"
      clusterPoolIPv4MaskSize: 20
  cni:
    binPath: "/var/lib/cni/bin"
    confPath: "/var/run/multus/cni/net.d"
    exclusive: false
    customConf: false
  prometheus:
    enabled: true
    serviceMonitor: {enabled: true}
  nodeinit:
    enabled: true
  extraConfig:
    bpf-lb-sock-hostns-only: "true"
    export-aggregation: "connection"
    export-aggregation-ignore-source-port: "false"
    export-aggregation-state-filter: "new closed established error"
  hubble:
    enabled: true
    metrics:
      enabled:
      - dns:labelsContext=source_namespace,destination_namespace
      - drop:labelsContext=source_namespace,destination_namespace
      - tcp:labelsContext=source_namespace,destination_namespace
      - icmp:labelsContext=source_namespace,destination_namespace
      - port-distribution
      - flow:labelsContext=source_namespace,destination_namespace;sourceContext=workload-name|reserved-identity;destinationContext=workload-name|reserved-identity
      serviceMonitor: {enabled: true}
    relay: {enabled: true}
  operator:
    unmanagedPodWatcher:
      restart: false
    metrics:
      enabled: true
    prometheus:
      enabled: true
      serviceMonitor: {enabled: true}
EOF

echo "✅ CiliumConfig generated: ${OUTPUT_FILE}"
echo "   k8sServiceHost: ${API_HOST}"
