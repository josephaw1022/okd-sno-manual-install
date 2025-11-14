# OKD SNO Setup – Quick Instructions

```bash
export OKD_VERSION=4.19.0-okd-scos.1
export ARCH=x86_64
```

**Reference:**
[https://docs.okd.io/latest/installing/installing_sno/install-sno-installing-sno.html](https://docs.okd.io/latest/installing/installing_sno/install-sno-installing-sno.html)

---

## Pull Secret (Fake Example)

```json
{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}
```

---

## SSH Access to Node

```bash
ssh -i ~/.ssh/id_ed25519 core@192.168.1.9
```

---

## Fix Hostname Issue

```bash
sudo hostnamectl set-hostname control-plane0.okd.kubesoar.com
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

**TODO**

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
