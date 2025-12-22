# 1. Create/Switch to the datadog namespace
oc new-project datadog 2>/dev/null || oc project datadog

# 2. Prompt for secrets securely
echo "Enter your Datadog API Key:"
read -s DD_API_KEY
echo "Enter your Datadog App Key:"
read -s DD_APP_KEY

# 3. Generate a random Cluster Agent token
DD_CLUSTER_TOKEN=$(openssl rand -hex 32)

# 4. Create the Kubernetes Secret
oc create secret generic datadog-secret \
  --from-literal=api-key=$DD_API_KEY \
  --from-literal=app-key=$DD_APP_KEY \
  --from-literal=token=$DD_CLUSTER_TOKEN \
  --namespace=datadog

# 5. Create the DatadogAgent CR referencing the secrets
cat <<EOF | oc apply -f -
apiVersion: datadoghq.com/v2alpha1
kind: DatadogAgent
metadata:
  name: datadogagent-sample
  namespace: datadog
spec:
  features:
    admissionController:
      enabled: true
    apm:
      enabled: true
    autoscaling:
      workload:
        enabled: true
    clusterChecks:
      enabled: true
      useClusterChecksRunners: true
    eventCollection:
      unbundleEvents: true
    externalMetricsServer:
      enabled: true
      useDatadogMetrics: true
    liveProcessCollection:
      enabled: true
    logCollection:
      containerCollectAll: true
      enabled: true
    npm:
      enabled: true
    orchestratorExplorer:
      enabled: true
  global:
    clusterAgentTokenSecret:
      keyName: token
      secretName: datadog-secret
    clusterName: okd-homelab
    credentials:
      apiSecret:
        keyName: api-key
        secretName: datadog-secret
      appSecret:
        keyName: app-key
        secretName: datadog-secret
    criSocketPath: /var/run/crio/crio.sock
    kubelet:
      tlsVerify: false
    site: us5.datadoghq.com
  override:
    clusterAgent:
      containers:
        cluster-agent:
          securityContext:
            readOnlyRootFilesystem: false
      env:
      - name: DD_AUTOSCALING_FAILOVER_ENABLED
        value: "true"
      replicas: 2
      serviceAccountName: datadog-agent-scc
    clusterChecksRunner:
      replicas: 2
    nodeAgent:
      env:
      - name: DD_AUTOSCALING_FAILOVER_ENABLED
        value: "true"
      hostNetwork: true
      securityContext:
        runAsUser: 0
        seLinuxOptions:
          level: s0
          role: system_r
          type: spc_t
          user: system_u
      serviceAccountName: datadog-agent-scc
EOF