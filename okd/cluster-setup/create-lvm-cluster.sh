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
            - /dev/vdb
        thinPoolConfig:
          name: thin-pool
          sizePercent: 90
          overprovisionRatio: 10
        nodeSelector:
          nodeSelectorTerms:
            - matchExpressions:
                - key: node-role.kubernetes.io/master
                  operator: Exists
EOF
