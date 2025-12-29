#!/bin/bash
set -euo pipefail

# Check that argocd CLI is installed
if ! command -v argocd &> /dev/null; then
    echo "argocd CLI could not be found. Please install it first."
    exit 1
fi


# Log in to Argo CD using SSO with port forwarding
argocd login --port-forward --port-forward-namespace openshift-gitops --server-name openshift-gitops-server --sso


# wait for 2 seconds to ensure login is complete
sleep 2


# Get argocd apps list to verify login
argocd app list --port-forward --port-forward-namespace openshift-gitops --server-name openshift-gitops-server

