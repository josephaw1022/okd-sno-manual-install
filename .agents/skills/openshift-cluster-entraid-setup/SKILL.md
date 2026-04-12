---
name: openshift-cluster-entraid-setup
description: Use when setting up or managing Entra ID (Azure AD) OAuth authentication for an OKD/OpenShift cluster. This skill covers the creation of Azure App Registrations, cluster secrets, and the OAuth configuration resource.
---

# OpenShift Entra ID Setup

This skill provides instructions and context for configuring Entra ID (formerly Azure AD) as an identity provider for an OKD/OpenShift cluster using the OpenID Connect (OIDC) protocol.

## Overview

OpenShift includes a built-in `OAuth` Custom Resource Definition (CRD) that allows you to connect to external OIDC providers. This enables non-Kubernetes-based users to authenticate to the cluster using their existing corporate credentials.

## Azure Resources

The setup process involves creating an **Azure App Registration** to represent the OKD cluster in Entra ID.

### App Registration Details

- **Display Name**: Typically follows the pattern `OKD-<cluster_name>-OAuth`.
- **Redirect URI**: The callback URL for the cluster's OAuth server.
  - Pattern: `https://oauth-openshift.apps.<cluster_name>.<base_domain>/oauth2callback/azure`
  - Example: `https://oauth-openshift.apps.okd.kubesoar.com/oauth2callback/azure`

### Microsoft Graph Permissions

The App Registration requires the following **API Permissions** (Scopes) from Microsoft Graph:

- `User.Read` (Sign in and read user profile)
- `email` (View users' email address)
- `openid` (Sign users in)
- `profile` (View users' basic profile)

## Implementation Details

The configuration is typically automated via the cluster's `makefile`.

### Automation via Makefile
- **`make setup-entraid`**: This is the primary target that handles the complete Entra ID OAuth setup. It validates Azure credentials, creates the App Registration, sets permissions, generates secrets, and applies the configuration to the cluster.

The Ansible playbook `okd/ansible/setup-entraid-oauth.yml` is the core component executed by this target.

### 1. App Secret Generation

The setup script generates a client secret for the Azure App Registration.

### 2. Cluster Secret

A Kubernetes Secret is created in the `openshift-config` namespace (usually named `azure-oauth-client-secret`). This secret contains the `clientSecret` from the Azure App Registration.

### 3. OAuth Configuration

The cluster's `OAuth` object (named `cluster`) is updated to include `azure` as an identity provider. It references:

- The `clientID` of the Azure App Registration.
- The `issuer` URL (e.g., `https://login.microsoftonline.com/<tenant_id>/v2.0`).
- The cluster secret containing the `clientSecret`.

## Post-Setup & Access

After the script has successfully run:

1. **Sign In**: Users should navigate to the OpenShift console and select "azure" to sign in through the Microsoft portal.
2. **Permissions**: By default, newly authenticated Azure users will have **no extra permissions** in the cluster.
3. **Cluster Admin Access**: The cluster admin has created a `ClusterRoleBinding` that maps their Azure email identity to the `cluster-admin` role. This ensures that when logging in via Azure, they retain full administrative control.

## References

- `okd/ansible/setup-entraid-oauth.yml`
- `okd/cluster-setup/entraid-oauth.yaml`
- `okd/ansible/templates/entraid-oauth.yaml.j2`
- `okd/makefile` (target: `setup-entraid`)
