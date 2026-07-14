# Sub-exercise 2: Install Cluster Foundations

## Introduction

Now that you have an empty Kubernetes cluster running, it's time to install the **foundational platform services** that all applications depend on. These are cluster-level components that handle cross-cutting concerns like:

- **Ingress**: Routing external traffic into your cluster
- **Certificate Management**: Automatic TLS/SSL certificates
- **Dashboard**: Visual interface for cluster management
- **Storage**: Persistent volumes for stateful applications

This is often called **cluster bootstrapping** or **platform engineering**. In production environments, teams use tools like Flux or Argo CD to automate this step; for this exercise, we'll do it manually to understand each component.

## Learning Goals

After completing this sub-exercise, you will:

- Connect `kubectl` to your provisioned cluster
- Understand the four foundational platform services and why each is needed
- Deploy Helm charts to install services into Kubernetes
- Verify that platform services are running correctly
- Understand how outputs from Terraform flow into platform configuration

## Prerequisites

Before starting, ensure:

- ✅ **Sub-exercise 1 is complete**: Your Terraform cluster is fully provisioned
- ✅ **kubectl is installed**: [Download here](https://kubernetes.io/docs/tasks/tools/)
- ✅ **Helm 3 is installed**: [Installation guide](https://helm.sh/docs/intro/install/)
- ✅ **Generated kubeconfig**: Available from Terraform step 1

**Estimated time**: 10-15 minutes

## Part 1: Connect kubectl to Your Cluster

Before running any commands, you need to tell `kubectl` which cluster to manage.

### Option 1: Use the Generated Kubeconfig (Recommended)

From the `1_alloc/` directory, export the kubeconfig that Terraform generated:

```bash
export KUBECONFIG="$(realpath 1_alloc/generated/kubeconfig-*.yaml)"
```

### Option 2: Use STACKIT CLI

Alternatively, let the STACKIT CLI manage your kubeconfig:

```bash
stackit ske kubeconfig create <cluster-name> --login
```

(Replace `<cluster-name>` with the name of your cluster from the Terraform configuration)

### Verify the Connection

Test that `kubectl` can reach your cluster:

```bash
kubectl cluster-info
```

Expected output:

```
Kubernetes control plane is running at https://...
CoreDNS is running at https://.../api/v1/namespaces/kube-system/services/coredns:dns/proxy
```

Also verify you can list nodes:

```bash
kubectl get nodes
```

Expected: At least one node in `Ready` state

<details>
<summary>💡 Hint: Troubleshooting kubectl Connection Issues</summary>

**Error: "Unable to connect to server"**

- Verify `KUBECONFIG` is set: `echo $KUBECONFIG`
- Ensure the kubeconfig file exists: `ls -la $KUBECONFIG`
- Try re-exporting: `export KUBECONFIG="$(realpath 1_alloc/generated/kubeconfig-*.yaml)"`

**Error: "Unauthorized"**

- The cluster may still be initializing (takes a few minutes after Terraform completes)
- Wait 2-3 minutes and try again

</details>

## Part 2: Understanding the Four Platform Services

### 1. Traefik (Ingress Controller)

**What it does**: Routes external HTTP/HTTPS traffic to services running inside your cluster.

**Why you need it**: Without an ingress controller, your applications are only accessible within the cluster. Traefik makes them accessible from the internet.

**Key capabilities**:

- Route traffic based on hostnames (e.g., `nextcloud.yourdomain.com` → Nextcloud service)
- Load balancing across multiple instances
- WebSocket support
- Middleware for authentication, headers, etc.

### 2. cert-manager (Certificate Management)

**What it does**: Automatically provisions and renews TLS certificates from Let's Encrypt.

**Why you need it**: Without TLS, all traffic is unencrypted. cert-manager automates certificate lifecycle so you don't have to manually renew certificates every 90 days.

**Key capabilities**:

- Automatically creates certificates for your ingress hostnames
- Renews certificates before expiration
- Works seamlessly with Traefik

### 3. Headlamp (Dashboard)

**What it does**: Provides a web UI for managing your Kubernetes cluster.

**Why you need it**: While `kubectl` is powerful, a visual dashboard makes it easier to explore resources, view logs, and debug issues.

**Key capabilities**:

- Browse pods, services, deployments, and other resources
- View container logs
- Port-forward to services
- Inspect resource definitions

### 4. Longhorn (Storage)

**What it does**: Provides distributed, highly-available persistent storage for containerized applications.

**Why you need it**: Many applications need persistent data that survives pod restarts or node failures. Longhorn replicates data across nodes for fault tolerance.

**Key capabilities**:

- Persistent volumes that can be attached to multiple pods
- Automatic replication for high availability
- Snapshots and backups
- Thin provisioning

## Part 3: Install Platform Services

### Setup: Load Terraform Outputs

The installation scripts need information from Terraform (domain name, database credentials, etc.). This is stored in an environment file:

```bash
source 1_alloc/generated/tf_output.env
```

This loads variables like:

- `DOMAIN`: Your DNS domain
- `PROJECT_ID`: Your STACKIT project ID
- Database credentials
- S3 credentials
- Etc.

Verify it worked:

```bash
echo "Domain: $DOMAIN"
echo "Project: $PROJECT_ID"
```

### Install All Services (Recommended)

To install all four services in the correct dependency order:

```bash
make install-all
```

This runs all scripts in sequence and ensures services start up properly.

**Estimated time**: 8-10 minutes (mostly waiting for services to initialize)

### Or Install Individually (For Learning)

You can also install services one at a time:

> [!IMPORTANT]
> Run these commands in order (they have dependencies):
>
> ```bash
> make install-ingress       # Step 1: Traefik ingress controller
> make install-cert-manager  # Step 2: Certificate management
> make install-dashboard     # Step 3: Headlamp dashboard
> make install-storage       # Step 4: Longhorn storage
> ```

<details>
<summary>💡 Hint: Understanding the Installation Scripts</summary>

Each `make` target runs a shell script that:

1. Adds Helm chart repositories (the registries where Helm charts are published)
2. Creates namespaces (isolated environments within the cluster)
3. Installs Helm charts with appropriate values
4. Waits for pods to be ready

You can examine the scripts to see exactly what's being installed:

- `21_install-ingress-controller.sh`
- `22_install-cert-manager.sh`
- `23_install-headlamp.sh`
- `24_install-longhorn.sh`

</details>

## Part 4: Verify Installation

### Check That Pods Are Running

List all pods in the cluster and verify services are healthy:

```bash
kubectl get pods -A
```

Expected: Pods in various namespaces (`kube-system`, `traefik`, `cert-manager`, `headlamp`, `longhorn-system`) should all be in `Running` state.

<details>
<summary>💡 Hint: Waiting for Pods to Be Ready</summary>

Some services take a minute or two to initialize. If you see `Pending` or `ContainerCreating` status, wait a bit and check again:

```bash
watch kubectl get pods -a
```

Press Ctrl+C to exit the watch.

</details>

### Verify Each Service

#### Traefik (Ingress)

```bash
kubectl get svc -n traefik
```

Should show a `LoadBalancer` service with an external IP or hostname.

#### cert-manager

```bash
kubectl get pods -n cert-manager
```

Should show cert-manager pods in `Running` state.

#### Headlamp (Dashboard)

```bash
kubectl get svc -n headlamp
```

Should show the Headlamp service. To access it:

```bash
kubectl port-forward -n headlamp svc/headlamp 8080:80
```

Then open <http://localhost:8080> in your browser.

#### Longhorn (Storage)

```bash
kubectl get pods -n longhorn-system
```

Should show Longhorn manager and engine pods.

Access the Longhorn dashboard (useful for managing volumes):

```bash
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8081:80
```

Then open <http://localhost:8081> in your browser.

### Check for Certificate Resources

cert-manager should have created certificates for your ingress. View them:

```bash
kubectl get certificates -A
```

## Troubleshooting

### Pods Won't Start

**Symptoms**: Pods stuck in `Pending`, `CrashLoopBackOff`, or `ImagePullBackOff`

**Solutions**:

1. Check pod logs: `kubectl logs -n <namespace> <pod-name>`
2. Describe the pod for events: `kubectl describe pod -n <namespace> <pod-name>`
3. Ensure node has sufficient resources: `kubectl describe nodes`

### Services Don't Have External IPs

**Symptoms**: `LoadBalancer` services show `<pending>` for external IP

**Cause**: This is normal on some cloud platforms. Check the load balancer status in STACKIT console.

### Certificate Not Being Issued

**Symptoms**: Ingress doesn't have a certificate; certificate stays in `Pending`

**Solution**:

1. Check cert-manager logs: `kubectl logs -n cert-manager cert-manager-*`
2. Describe the certificate: `kubectl describe certificate -A`
3. Ensure your domain is reachable for Let's Encrypt validation

## What's Next

Once all platform services are running:

1. ✅ Your cluster has a public ingress controller
2. ✅ TLS certificates are being managed automatically
3. ✅ You have a dashboard for cluster management
4. ✅ You have persistent storage for applications

Your Kubernetes platform is now ready for applications! Proceed to [Sub-exercise 3: Deploy Nextcloud Application](../3_nextcloud/README.md) to deploy a complete web application.

## Summary

In this sub-exercise, you:

- Connected `kubectl` to your provisioned cluster
- Installed four foundational Kubernetes services: Traefik, cert-manager, Headlamp, and Longhorn
- Verified that each service is running and accessible
- Understood why each service is critical to the platform

**Key insights:**

- Platform engineering is about laying the foundation that applications depend on
- Kubernetes enables modular, composable platform services
- Helm makes it easy to deploy complex services from pre-built charts
- Proper sequencing is important: ingress and certificates must be set up before applications
