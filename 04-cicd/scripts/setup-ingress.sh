#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
EXERCISE_DIR="$(dirname "$SCRIPT_DIR")"

if [ -z "${DOMAIN:-}" ]; then
  echo "Error: DOMAIN environment variable is not set."
  echo "Export your cluster domain before running this script:"
  echo "  export DOMAIN=<your-domain>"
  exit 1
fi

HOST="argocd.$DOMAIN"
echo "Exposing ArgoCD at https://$HOST"

HOST="$HOST" envsubst <"$EXERCISE_DIR/argocd-ingress.yaml" | kubectl apply --server-side -f -

echo ""
echo "ArgoCD UI will be available at: https://$HOST"
echo "Run 'make credentials' to print the login credentials."
