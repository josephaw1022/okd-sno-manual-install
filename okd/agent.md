
## Instructions to install OpenShift with Cilium CNI

can you read this snippet from this isovalent blog post 


```
$ openshift-install create install-config
? SSH Public Key /home/dean/.ssh/ocp413.pub
? Platform vsphere
? vCenter vcenter.isovalent.rocks
? Username administrator@vsphere.local
? Password [? for help] *********
INFO Connecting to vCenter vvcenter.isovalent.rocks    
INFO Defaulting to only available datacenter: Datacenter 
INFO Defaulting to only available cluster: Cluster 
? Default Datastore Datastore
INFO Defaulting to only available network: Network 1
? Virtual IP Address for API 192.168.200.142
? Virtual IP Address for Ingress 192.168.200.143
? Base Domain isovalent.rocks
? Cluster Name ocp413
? Pull Secret [? for help] ***************************************************************************************************
INFO Install-Config created in .
This will output a file called install-config.yaml, which contains all the infrastructure information that the tool will provision, in addition to the associated cloud provider, in this example, VMware vSphere.

The file contents will be similar to the below.

Whichever way we create the file, we will need to edit this file to ensure that networkType is set to Cilium, and the Network Address CIDRs are configured as necessary for our environment.

additionalTrustBundlePolicy: Proxyonly
apiVersion: v1
baseDomain: isovalent.rocks
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: ocp413
networking:
  clusterNetwork:
  - cidr: 10.244.0.0/16
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: Cilium
  serviceNetwork:
  - 172.30.0.0/16
platform:
  vsphere:
    apiVIPs:
    - 192.168.200.142
    failureDomains:
    - name: generated-failure-domain
      region: generated-region
      server: vcenter.isovalent.rocks
      topology:
        computeCluster: /Datacenter/host/Cluster
        datacenter: Datacenter
        datastore: /Datacenter/datastore/vSANDatastore
        networks:
        - Network1
        resourcePool: /Datacenter/host/Cluster1/Resources/Compute-ResourcePool/openshift/
      zone: generated-zone
    ingressVIPs:
    - 192.168.200.143
    vcenters:
    - datacenters:
      - Datacenter
      password: Isovalent.Rocks1!
      port: 443
      server: vcenter.isovalent.rocks
      user: administrator@vsphere.local
publish: External
pullSecret: '{"auths":{"cloud.openshift.com":.......}
sshKey: |
  ssh-rsa ...... isovalent@rocks
Now run the following command to create the OpenShift manifests file:

$ openshift-install create manifests
Next we need to copy across the Cilium manifests into this folder.

For Cilium OSS wecan run the following commands, which downloads the repo to /tmp, then copies the manifests for our configured Cilium version into the manifests folder, and removes the repo from /tmp:

$ cilium_version="1.14.3"
$ git_dir="/tmp/cilium-olm"
$ git clone https://github.com/isovalent/olm-for-cilium.git ${git_dir}
$ cp ${git_dir}/manifests/cilium.v${cilium_version}/* "manifests/"
$ test -d ${git_dir} && rm -rf -- ${git_dir}

# Test the Cilium files have populated the manifests folder
$ ls manifests/cluster-network-*-cilium-*
For Isovalent Enterprise for Cilium OLM files, the method is the same once we've downloaded the files.

OpenShift will by default create a cluster-network-02-operator.yml file. Within this file, the networkType should be set to Cilium and all relevant clusterNetwork and serviceNetwork CIDRs should be defined, as per the configuration from the install-config.yaml file.

To configure Cilium, we can modify the cluster-network-07-cilium-ciliumconfig.yaml file. The below example shows the configuration for Hubble Metrics and Prometheus Service Monitors enabled:

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
  k8sServiceHost: api.ocp-test.simon.local
  k8sServicePort: 6443
  ipam:
    mode: "cluster-pool"
    operator:
      clusterPoolIPv4PodCIDRList: "10.244.0.0/16"
      clusterPoolIPv4MaskSize: 24
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
      - "kafka:labelsContext=source_namespace,source_workload,destination_namespace,destination_workload,traffic_direction;sourceContext=workload-name|reserved-identity;destinationContext=workload-name|reserved-identity"
      - "httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction;sourceContext=workload-name|reserved-identity;destinationContext=workload-name|reserved-identity"
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
It is also possible to update the configuration values once the cluster is running by changing the CiliumConfig object, e.g. with kubectl edit ciliumconfig -n cilium cilium. We may need to restart the Cilium agent pods for certain options to take effect.

How do I create the OpenShift Cluster with Cilium?
We are now ready to create the OpenShift Cluster and can proceed by running the command:

$ openshift-install create cluster
For more granular output we can use the following command argument for output to the terminal.

--log-level string   log level (e.g. "debug | info | warn | error") (default "info")
Full debug information is also contained in the hidden file .openshift_install.log in the location where the command is run from.

Below is an example output from creating the cluster with the informational log level set.

INFO Consuming Openshift Manifests from target directory 
INFO Consuming Worker Machines from target directory 
INFO Consuming Master Machines from target directory 
INFO Consuming Common Manifests from target directory 
INFO Consuming OpenShift Install (Manifests) from target directory 
INFO Obtaining RHCOS image file from 'https://rhcos.mirror.openshift.com/art/storage/prod/streams/4.13-9.2/builds/413.92.202307260246-0/x86_64/rhcos-413.92.202307260246-0-vmware.x86_64.ova?sha256=4b2caacc4d5dc69aabe3733a86e0a5ac0b41bbe1c090034c4fa33faf582a0476' 
INFO The file was found in cache: /home/dean/.cache/openshift-installer/image_cache/rhcos-413.92.202307260246-0-vmware.x86_64.ova. Reusing... 
INFO Creating infrastructure resources...         
INFO Waiting up to 20m0s (until 4:07PM) for the Kubernetes API at https://api.ocp413.isovalent.rocks:6443... 
INFO API v1.26.9+636f2be up                       
INFO Waiting up to 1h0m0s (until 4:49PM) for bootstrapping to complete... 
INFO Destroying the bootstrap resources...        
INFO Waiting up to 40m0s (until 4:43PM) for the cluster at https://api.ocp413.isovalent.rocks:6443 to initialize... 
INFO Checking to see if there is a route at openshift-console/console... 
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/home/dean/ocp413/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.ocp413.isovalent.rocks 
INFO Login to the console with user: "kubeadmin", and password: "DyquU-FckQQ-CpN9g-7A57f" 
INFO Time elapsed: 30m33s
How do I test Network Connectivity with Cilium?
For this guide the final piece is to run the standard Cilium tests on my cluster to confirm network connectivity.

We've run the provided export KUBECONFIG in the terminal output to connect to our cluster.

Before the Cilium network tests will run, due to the SecurityConstraintContext (SCC) that's implemented by OpenShift out of the box as a hardened security posture, we will need to apply a configuration to handle this.

$ kubectl apply -f - <<EOF
apiVersion: security.openshift.io/v1
kind: SecurityContextConstraints
metadata:
  name: cilium-test
allowHostPorts: true
allowHostNetwork: true
users:
  - system:serviceaccount:cilium-test:default
priority: null
readOnlyRootFilesystem: false
runAsUser:
  type: MustRunAsRange
seLinuxContext:
  type: MustRunAs
volumes: null
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostPID: false
allowPrivilegeEscalation: false
allowPrivilegedContainer: false
allowedCapabilities: null
defaultAddCapabilities: null
requiredDropCapabilities: null
groups: null
EOF
Now we can proceed to configure the tests to run, first create a namespace for the test to run:

$ kubectl create ns cilium-test
Deploy the checks with the command:

$ kubectl apply -n cilium-test -f https://raw.githubusercontent.com/cilium/cilium/1.14.3/examples/kubernetes/connectivity-check/connectivity-check.yaml
This will configure a series of deployments that will use various connectivity paths to connect to each other. Connectivity paths include with and without service load-balancing and various network policy combinations. The pod name indicates the connectivity variant and the readiness and liveness gate indicates success or failure of the test:

$ kubectl get pods -n cilium-test
NAME                                                    READY   STATUS    RESTARTS   AGE
echo-a-568cb98744-tlvwv                                 1/1     Running   0          67s
echo-b-64db4dfd5d-q8kpj                                 1/1     Running   0          67s
echo-b-host-6b7bb88666-qnhz4                            1/1     Running   0          67s
host-to-b-multi-node-clusterip-6cfc94d779-5v2x7         1/1     Running   0          66s
host-to-b-multi-node-headless-5458c6bff-2v7m7           1/1     Running   0          66s
pod-to-a-allowed-cnp-55cb67b5c5-ltclc                   1/1     Running   0          66s
pod-to-a-c9b8bf6f7-z4k2h                                1/1     Running   0          66s
pod-to-a-denied-cnp-85fb9df657-ndg2n                    1/1     Running   0          66s
pod-to-b-intra-node-nodeport-55784cc5c9-t42kj           1/1     Running   0          66s
pod-to-b-multi-node-clusterip-5c46dd6677-jgzvf          1/1     Running   0          66s
pod-to-b-multi-node-headless-748dfc6fd7-2ggvq           1/1     Running   0          66s
pod-to-b-multi-node-nodeport-f6464499f-84t92            1/1     Running   0          66s
pod-to-external-1111-96c489555-srcvb                    1/1     Running   0          66s
pod-to-external-fqdn-allow-google-cnp-5f747dfc7-8jsxw   1/1     Running   0          66s
Note: If you deploy the connectivity check to a single node cluster, pods that check multi-node functionalities will remain in the Pending state. This is expected since these pods need at least 2 nodes to be scheduled successfully.

Summary
This tutorial takes you as far as the initial deployment of Red Hat OpenShift and Cilium including network connectivity testing. To continue to run this cluster further for development or production use-cases, I recommend continuing to follow the official Red Hat OpenShift documentation covering post installation cluster tasks. You can also join the Cilium Slack workspace to join in the discussion for all things Cilium related.

As you can see, it's quick and easy to install Cilium into our Red Hat OpenShift environment, with minimal additional configuration from our existing workflows.

With Cilium installed in our cluster, we can now take advantage of features and use-cases such as:
```


basically I need you to modify the makefile so that there is a target that creates the manifests dir (it may already exist, but just to be sure). and then have another target that copies the cilium manifests from a specified location into the manifests dir. Have the specified location be some random $(mktemp -d ) dir that the user has to populate with the cilium manifests before running the make target.

then modify the install-config.yaml to set networkType to Cilium and then keep rest of the file same as before.

then have the makefile target that creates the cluster use the manifests dir when creating the cluster



