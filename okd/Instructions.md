# OKD SNO Setup – Quick Instructions


**Reference:**
[https://docs.okd.io/latest/installing/installing_sno/install-sno-installing-sno.html](https://docs.okd.io/latest/installing/installing_sno/install-sno-installing-sno.html)



## DNS Setup

- You need a dns server on your private network. This can be any kind of DNS server that allows you to create A and CNAME records. For my home lab, I use Pi-hole which uses dnsmasq under the hood. However, you can also use a cloud DNS provider if youre provisioning your OKD node on a cloud like AWS or Azure. You also can use bind9 or any other DNS server software if you prefer those DNS servers for those who are going the on prem route.

example of okd.conf file which lies in /etc/dnsmasq.d/ for Pi-hole / dnsmasq:

```
# API server - external clients and internal cluster nodes
address=/api.okd.kubesoar.com/192.168.1.9

# Internal API - internal cluster nodes only
address=/api-int.okd.kubesoar.com/192.168.1.9

# Apps wildcard - external clients and internal cluster nodes
address=/.apps.okd.kubesoar.com/192.168.1.9

# Node hostname - single control plane node
address=/control-plane0.okd.kubesoar.com/192.168.1.9

# PTR record for the control plane node
ptr-record=9.1.168.192.in-addr.arpa,control-plane0.okd.kubesoar.com

```


## Configure values in makefile now

- configure these values in the makefile before proceeding with the rest of the instructions below:

```
OKD_VERSION ?= 4.20.0-okd-scos.8
ARCH ?= x86_64
CLUSTER_NAME ?= okd
BASE_DOMAIN ?= kubesoar.com
DISK_ID ?= wwn-0x500a0751435cebaf
SSH_KEY ?= ~/.ssh/id_ed25519.pub
NODE_IP ?= 192.168.1.9
```

- then run `make oc` and `make installer` to install oc and the openshift-install binary.
- then run `make build` which will install the centos stream 9 core os iso, create the configuration file, and create a bootable usb drive for installation.
- use balena etcher or rufus to flash the iso to a usb drive
- then boot the target machine


---

## SSH Access to Node

```bash
ssh -i ~/.ssh/id_ed25519 core@192.168.1.9
```

---

## Fix Hostname Issue on Node

```bash
# first ssh into the node using the command above. Then once ssh'd in, run the following command to set the hostname properly:
sudo hostnamectl set-hostname control-plane0.okd.kubesoar.com # or whatever your desired hostname is
```

---

## LDAP / FreeIPA CA Extraction

*(Skip if using Entra ID)*

```bash
sudo podman cp idm-server:/etc/ipa/ca.crt /tmp/freeipa-ca.crt
```

Download locally → Upload in OKD Console under LDAP configuration.

---

## Entra ID (Azure AD)

- create an app registration in Azure AD

- create an client secret for the app registration
- add redirect URI: `https://oauth-openshift.apps.okd.kubesoar.com/oauth2callback/azure` (use web type)
- for token configuration, add `email`, `groups`, and `preferred_username` as optional claims
- under API permissions, add `User.Read` and `email` permissions for Microsoft Graph


- then on the okd side, create an oauth resource using the `entraid-oauth.yaml` file in this repo (in the `cluster-setup` dir). Be sure to replace the placeholders with your actual values.

---

## Fix Console TLS Certificate Warning

### 1. Generate Cert (DNS-01)

```bash
sudo certbot certonly \
  --manual \
  --preferred-challenges dns \
  -d "*.apps.okd.kubesoar.com"
```

Add the TXT record in Azure DNS → wait for propagation.

### 2. Copy & Apply Certificate

```bash
sudo cp /etc/letsencrypt/live/apps.okd.kubesoar.com/fullchain.pem .
sudo cp /etc/letsencrypt/live/apps.okd.kubesoar.com/privkey.pem .

sudo chown $USER:$USER fullchain.pem privkey.pem
chmod 600 fullchain.pem privkey.pem

oc create secret tls wildcard-apps-okd-kubesoar \
  -n openshift-ingress \
  --cert=fullchain.pem \
  --key=privkey.pem \
  --dry-run=client -o yaml | oc apply -f -

oc patch ingresscontroller default \
  -n openshift-ingress-operator \
  --type=merge \
  -p '{"spec":{"defaultCertificate":{"name":"wildcard-apps-okd-kubesoar"}}}'
```

### 3. Restart Ingress Pods

```bash
oc delete pod -n openshift-ingress \
  -l ingresscontroller.operator.openshift.io/owning-ingresscontroller=default
```
