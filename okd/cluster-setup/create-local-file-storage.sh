#! /usr/bin/env bash
# Creates LocalVolume for local file storage using directory on host nodes

cat <<'EOF' | oc apply -f -
apiVersion: local.storage.openshift.io/v1
kind: LocalVolume
metadata:
  name: local-storage-filesystem
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
      - matchExpressions:
          - key: node-role.kubernetes.io/master
            operator: Exists
  storageClassDevices:
    - storageClassName: local-storage-fs
      volumeMode: Filesystem
      fsType: xfs
      devicePaths:
        - /var/mnt/local-storage
EOF


for node in master-0 master-1 master-2; do
  echo "Creating directory on $node..."
  oc debug node/$node -- chroot /host mkdir -p /var/mnt/local-storage/vol1 2>/dev/null
done


