#!/bin/bash
# Creates an LVMCluster for dynamic PV provisioning using LVMS (LVM Storage)
# This replaces LocalVolumeSet which only creates 1 PV per disk.
# With LVMS thin provisioning, you can create unlimited PVCs dynamically.

cat <<'EOF' | oc apply -f -
apiVersion: lvm.topolvm.io/v1alpha1
kind: LVMCluster
metadata:
  name: lvmcluster-block
  namespace: openshift-lvm-storage
spec:
  storage:
    deviceClasses:
      - name: vg-block
        default: true
        deviceSelector:
          paths:
            - /dev/vdb  # 500GB disk on each node (master-0, master-1, master-2)
        thinPoolConfig:
          name: thin-pool
          sizePercent: 90         # Use 90% of disk for thin pool
          overprovisionRatio: 10  # Allow 10x overprovisioning
        nodeSelector:
          nodeSelectorTerms:
            - matchExpressions:
                - key: node-role.kubernetes.io/master
                  operator: Exists
EOF

echo ""
echo "LVMCluster created. StorageClass 'lvms-vg-block' will be available shortly."
echo "This enables dynamic PV provisioning - create as many PVCs as you want!"
