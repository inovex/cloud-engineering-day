#!/usr/bin/env bash

# This script installs the classical kubernetes dashboard web application in
# the cluster. Needs (i.e. profits from) a proper ingress controller.

set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source $SCRIPT_DIR/../1_alloc/generated/tf_output.env
[ -z "${DOMAIN:-}" ] && {
  echo "$0: For dashboard ingress, need host. Expected DOMAIN to be defined in dotenv by terraform"
  exit 1
}

HOST="dashboard.$DOMAIN"
echo "$0: Exposing dashboard at http://$HOST"

helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
cat <<EOF | helm upgrade --install headlamp headlamp/headlamp --namespace headlamp --create-namespace --wait -f -
ingress:
  enabled: true
  ingressClassName: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
  - host: "$HOST"
    paths:
    - path: /
      type: ImplementationSpecific
  tls:
  - secretName: headlamp
    hosts:
    - "$HOST"
EOF
kubectl wait --for=condition=Ready certificate/headlamp --namespace headlamp --timeout=300s

echo "Making service token for web login"
token=$(kubectl create token headlamp --namespace headlamp --duration=8h)

echo
echo ">>> Dashboard is ready"
echo ">>> Open https://$HOST in your browser"
echo ">>> Use the following token to login:"
echo " $token"
