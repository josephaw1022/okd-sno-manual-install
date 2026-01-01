#!/usr/bin/env bash

set -e

CLUSTER_NAME="$1"
BASE_DOMAIN="$2"
SSH_KEY_FILE="$3"
MACHINE_NETWORK_CIDR="${4:-192.168.0.0/21}"

if [[ -z "$CLUSTER_NAME" || -z "$BASE_DOMAIN" || -z "$SSH_KEY_FILE" ]]; then
  echo "Usage: $0 <CLUSTER_NAME> <BASE_DOMAIN> <SSH_KEY_FILE> [MACHINE_NETWORK_CIDR]"
  echo "  MACHINE_NETWORK_CIDR defaults to 192.168.0.0/21 if not specified"
  exit 1
fi

echo "Cluster name: $CLUSTER_NAME"
echo "Base domain: $BASE_DOMAIN"
echo "SSH key file: $SSH_KEY_FILE"
echo "Machine network CIDR: $MACHINE_NETWORK_CIDR"

echo "🔧 Generating install-config.yaml for 3-node master cluster..."

cat > install-config.yaml <<EOF
apiVersion: v1
baseDomain: $BASE_DOMAIN
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 3
metadata:
  name: $CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: $MACHINE_NETWORK_CIDR
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: |
  $(cat $SSH_KEY_FILE)
EOF

echo "✅ install-config.yaml created for 3-node master cluster!"
