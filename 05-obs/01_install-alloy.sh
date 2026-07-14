#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Create the namespace first so the Secret can be applied into it.
cat <<EOF | kubectl apply --server-side -f -
apiVersion: v1
kind: Namespace
metadata:
  name: observability
EOF

# Apply credentials Secret before Helm install.
# Edit secret.yaml with your credentials first!
kubectl apply -f --server-side secret.yaml

helm upgrade --install alloy grafana/alloy \
  --namespace observability \
  --create-namespace \
  -f alloy-values.yaml
