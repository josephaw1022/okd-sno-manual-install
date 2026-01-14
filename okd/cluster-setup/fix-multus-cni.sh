#!/bin/bash
# fix-multus-cni.sh
# Creates symlinks on each node so multus can find the Cilium CNI config
# Note: These symlinks are in /run (tmpfs) and will be lost on reboot

set -e

echo "Getting list of nodes..."
NODES=$(oc get nodes -o jsonpath='{.items[*].metadata.name}')

for NODE in $NODES; do
    echo "Creating CNI symlink on node: $NODE"
    oc debug node/"$NODE" --quiet -- chroot /host ln -sf /etc/kubernetes/cni/net.d/05-cilium.conflist /run/multus/cni/net.d/
done

echo "Restarting multus pods..."
oc delete pod -n openshift-multus -l app=multus

echo "Waiting for multus pods to come up..."
sleep 10

echo "Checking multus pod status..."
oc get pods -n openshift-multus -l app=multus

echo "Checking network operator status..."
oc get co network

echo "Done!"
