#!/usr/bin/env bash

set -e

CLUSTER_NAME="$1"
BASE_DOMAIN="$2"
DISK_ID="$3"
SSH_KEY_FILE="$4"

if [[ -z "$CLUSTER_NAME" || -z "$BASE_DOMAIN" || -z "$DISK_ID" || -z "$SSH_KEY_FILE" ]]; then
  echo "Usage: $0 <CLUSTER_NAME> <BASE_DOMAIN> <DISK_ID> <SSH_KEY_FILE>"
  exit 1
fi

echo "Pull secret: $PULL_SECRET"
echo "Cluster name: $CLUSTER_NAME"
echo "Base domain: $BASE_DOMAIN"
echo "Disk ID: $DISK_ID"
echo "SSH key file: $SSH_KEY_FILE"

echo "🔧 Generating install-config.yaml..."

cat > install-config.yaml <<EOF
apiVersion: v1
baseDomain: $BASE_DOMAIN
compute:
- name: worker
  replicas: 0
controlPlane:
  name: master
  replicas: 1
metadata:
  name: $CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
bootstrapInPlace:
  installationDisk: /dev/disk/by-id/$DISK_ID
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: |
  $(cat ~/$SSH_KEY_FILE)
EOF

echo "✅ install-config.yaml created!"
