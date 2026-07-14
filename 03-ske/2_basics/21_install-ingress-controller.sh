#!/usr/bin/env bash

set -euo pipefail

helm upgrade --install traefik --namespace traefik --create-namespace oci://ghcr.io/traefik/helm/traefik \
    --wait

echo
echo ">>> If you want to wait and see how you get a public IP assigned (takes 30-80 seconds), run this command:"
echo " kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' service/traefik --namespace traefik --timeout=300s"
