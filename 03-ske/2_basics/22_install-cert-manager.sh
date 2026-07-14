#!/usr/bin/env bash

# This script installs the let's encrypt cert-manager for HTTPS certificates.
# Create the Ingress controller before.

set -euo pipefail

helm upgrade --install cert-manager --namespace cert-manager --create-namespace oci://quay.io/jetstack/charts/cert-manager \
  --set webhook.timeoutSeconds=15 \
  --set crds.enabled=true \
  --wait

cat <<CLUSTER_ISSUER | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: kursteilnehmer@stackit.cloud # for notification only; not validated
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        ingress:
          ingressClassName: traefik
CLUSTER_ISSUER
