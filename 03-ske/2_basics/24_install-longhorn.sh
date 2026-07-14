#!/usr/bin/env bash
set -euo pipefail

# Multi Node RWX Persistent Volumes:
# Stackits default PVC can only be mounted on one node at a time when in RWX
# mode. Instead, STACKIT suggests using a custom driver:
# https://docs.stackit.cloud/stackit/en/how-to-setup-rwx-storage-on-ske-175112491.html
# see also https://github.com/stackitcloud/ske-longhorn-rwx
kubectl apply -f https://raw.githubusercontent.com/stackitcloud/ske-longhorn-rwx/main/enableISCSI.yml

# Note: This minimal setup lacks a backup.

helm repo add longhorn https://charts.longhorn.io

cat <<EOF | helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --wait -f -
defaultSettings:
  # 1. Force data eviction to neighboring nodes immediately when a drain begins
  nodeDrainPolicy: "always-evict"

  # 2. Prevent deadlocks by killing stuck pods on un-evictable or deleted nodes
  nodeDownPodDeletionPolicy: "delete-both-statefulset-and-deployment-pod"

  # 3. Aggressively clean up hanging pods if a volume attachment breaks during a transition
  autoDeletePodWhenVolumeDetachedUnexpectedly: true

  # 4. Allow failovers to proceed even if a volume drops to a degraded health state temporarily
  allowVolumeCreationWithDegradedAvailability: true
EOF

echo "==> Applying STACKIT SKE specific RWX StorageClass..."
cat <<STORAGECLASS | kubectl apply -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: longhorn-test
provisioner: driver.longhorn.io
allowVolumeExpansion: true
reclaimPolicy: Delete
volumeBindingMode: Immediate
parameters:
  numberOfReplicas: "3"
  staleReplicaTimeout: "2880"
  fromBackup: ""
  fsType: "ext4"
STORAGECLASS

echo "==> Success! Longhorn is configured."
