cat <<'EOF' | oc apply -f -
apiVersion: local.storage.openshift.io/v1alpha1
kind: LocalVolumeSet
metadata:
  name: local-block-storage
  namespace: openshift-local-storage
spec:
  nodeSelector:
    nodeSelectorTerms:
      - matchExpressions:
          - key: node-role.kubernetes.io/master
            operator: Exists
  storageClassName: local-block
  volumeMode: Block
  deviceInclusionSpec:
    deviceTypes:
      - disk
    minSize: 100Gi
EOF