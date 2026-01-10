#!/usr/bin/env bash

set -e

CLUSTER_NAME="$1"
BASE_DOMAIN="$2"
SSH_KEY_FILE="$3"
MACHINE_NETWORK_CIDR="${4:-192.168.0.0/21}"
MASTER0_IP="${5:-192.168.1.10}"
MASTER1_IP="${6:-192.168.1.11}"
MASTER2_IP="${7:-192.168.1.12}"

if [[ -z "$CLUSTER_NAME" || -z "$BASE_DOMAIN" || -z "$SSH_KEY_FILE" ]]; then
  echo "Usage: $0 <CLUSTER_NAME> <BASE_DOMAIN> <SSH_KEY_FILE> [MACHINE_NETWORK_CIDR] [MASTER0_IP] [MASTER1_IP] [MASTER2_IP]"
  echo "  MACHINE_NETWORK_CIDR defaults to 192.168.0.0/21"
  echo "  MASTER IPs default to 192.168.1.10, .11, .12"
  exit 1
fi

echo "Cluster name: $CLUSTER_NAME"
echo "Base domain: $BASE_DOMAIN"
echo "SSH key file: $SSH_KEY_FILE"
echo "Machine network CIDR: $MACHINE_NETWORK_CIDR"
echo "Master IPs: $MASTER0_IP, $MASTER1_IP, $MASTER2_IP"

echo "🔧 Generating install-config.yaml for 3-node master cluster (agent-based)..."

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
    hostPrefix: 20
  machineNetwork:
  - cidr: $MACHINE_NETWORK_CIDR
  networkType: Cilium
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: |
  $(cat $SSH_KEY_FILE)
EOF

echo "✅ install-config.yaml created!"

echo "🔧 Generating agent-config.yaml..."

cat > agent-config.yaml <<EOF
apiVersion: v1alpha1
kind: AgentConfig
metadata:
  name: $CLUSTER_NAME
rendezvousIP: $MASTER0_IP
hosts:
  - hostname: master-0
    role: master
    interfaces:
      - name: enp1s0
        macAddress: 52:54:00:00:00:10
    networkConfig:
      interfaces:
        - name: enp1s0
          type: ethernet
          state: up
          ipv4:
            enabled: true
            address:
              - ip: $MASTER0_IP
                prefix-length: 21
            dhcp: false
      dns-resolver:
        config:
          server:
            - 192.168.1.5
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.1.1
            next-hop-interface: enp1s0
  - hostname: master-1
    role: master
    interfaces:
      - name: enp1s0
        macAddress: 52:54:00:00:00:11
    networkConfig:
      interfaces:
        - name: enp1s0
          type: ethernet
          state: up
          ipv4:
            enabled: true
            address:
              - ip: $MASTER1_IP
                prefix-length: 21
            dhcp: false
      dns-resolver:
        config:
          server:
            - 192.168.1.5
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.1.1
            next-hop-interface: enp1s0
  - hostname: master-2
    role: master
    interfaces:
      - name: enp1s0
        macAddress: 52:54:00:00:00:12
    networkConfig:
      interfaces:
        - name: enp1s0
          type: ethernet
          state: up
          ipv4:
            enabled: true
            address:
              - ip: $MASTER2_IP
                prefix-length: 21
            dhcp: false
      dns-resolver:
        config:
          server:
            - 192.168.1.5
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.1.1
            next-hop-interface: enp1s0
EOF

echo "✅ agent-config.yaml created!"
echo ""
echo "📋 Next: run 'make agent-iso' to generate the agent installer ISO"
