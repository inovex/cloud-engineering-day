# Sub-exercise 3: Deploy Nextcloud Application

## Introduction

Now that your Kubernetes platform is fully bootstrapped, it's time to deploy an actual application: **Nextcloud**, a feature-rich file sharing and collaboration platform.

This exercise demonstrates the complete application deployment workflow: selecting a pre-built Helm chart, customizing its values, deploying it into your cluster, and verifying it works. The same pattern applies to any Helm-deployable application.

Nextcloud will:

- Store files persistently using Longhorn storage from Sub-exercise 2
- Be accessible via the Traefik ingress from Sub-exercise 2
- Use automatic TLS certificates from cert-manager (Sub-exercise 2)
- Store metadata in the MariaDB database from Sub-exercise 1

This ties together all the infrastructure and platform components into a working application.

## Learning Goals

After completing this sub-exercise, you will:

- Understand Helm charts and how to customize deployments via `values.yaml`
- Deploy a complex, stateful application (Nextcloud) into Kubernetes
- Verify application health and accessibility
- Troubleshoot common application deployment issues
- Understand how infrastructure, platform, and application layers integrate

## Prerequisites

Before starting, ensure:

- ✅ **Sub-exercise 1 is complete**: Terraform provisioned infrastructure including MariaDB database
- ✅ **Sub-exercise 2 is complete**: Platform services (Traefik, cert-manager, Headlamp, Longhorn) are running
- ✅ **Helm 3 is installed**: [Installation guide](https://helm.sh/docs/intro/install/)
- ✅ **kubectl is connected** to your cluster: `kubectl cluster-info` works

**Estimated time**: 5 minutes setup + 8 minutes initialization = 13 minutes total

## Part 1: Understanding Nextcloud Deployment

### What is Helm?

Helm is a package manager for Kubernetes. A **Helm chart** is a pre-built application package that includes:

- Kubernetes manifests (deployment, service, ingress, etc.)
- Configuration templates
- Default values

Instead of writing 50+ lines of YAML, you just customize a few values in `values.yaml`.

### The Nextcloud Chart

The Nextcloud Helm chart includes:

- **Deployment**: Nextcloud web application container
- **Service**: Internal networking for Nextcloud
- **Ingress**: External access via your domain
- **PersistentVolume**: Nextcloud data storage (managed by Longhorn)
- **ConfigMap/Secret**: Configuration and credentials

### How Configuration Flows

```
Terraform (Sub-ex 1)  →  Database & S3 credentials
           ↓
tf_output.env         →  Pre-filled in values.yaml
           ↓
values.yaml (this step) → Customized by you (admin credentials, etc.)
           ↓
Helm Chart            →  Deploys Nextcloud with your configuration
           ↓
Running Nextcloud     →  Accessible at https://nextcloud.<your-domain>
```

## Part 2: Generate and Customize Helm Values

### Step 1: Generate values.yaml

The Terraform step already pre-filled a template with infrastructure values. Copy it to this directory:

```bash
make values.yaml
```

Or manually:

```bash
cp 1_alloc/generated/nextcloud_chart_values.yml values.yaml
```

This file now contains:

- Database host, port, username, password (from MariaDB)
- S3 bucket credentials
- Domain name
- And many other settings

### Step 2: Review the Configuration

Open `values.yaml` and review the key sections:

**Nextcloud admin user** (lines ~50-60):

```yaml
nextcloud:
  username: admin            # Admin login username
  password: admin123         # Admin login password (change this!)
```

**Database connection** (lines ~80-90):

```yaml
externalDatabase:
  type: mysql
  host: <database-host>
  user: <database-user>
  password: <database-password>
```

**Ingress configuration** (lines ~200-220):

```yaml
ingress:
  enabled: true
  hosts:
    - host: nextcloud.<your-domain>
      paths:
        - path: /
```

> [!IMPORTANT]
> Change the admin password! Replace `admin123` with a strong password:
>
> ```yaml
> nextcloud:
>   username: admin
>   password: MySecurePassword123!
> ```

### Step 3: Verify Other Important Settings

**Trusted Domains** (ensures Nextcloud accepts requests to your domain):

```yaml
nextcloud:
  configs:
    trusted_domains.config.php: |
      $CONFIG = array (
        'trusted_domains' => array (
          'nextcloud.<your-domain>',
        ),
      );
```

**Resource Limits** (prevent resource exhaustion):

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 512Mi
```

These should already be set appropriately, but review them.

<details>
<summary>💡 Hint: Understanding values.yaml Customization</summary>

The `values.yaml` file uses YAML format. Common patterns:

- Strings: `key: "value"`
- Numbers: `key: 123`
- Booleans: `key: true`
- Lists: `key: [item1, item2]`
- Objects/Dicts:

  ```yaml
  parent:
    child1: value1
    child2: value2
  ```

Most defaults are good; you mainly need to customize:

1. Admin credentials
2. Domain name (usually already filled by Terraform)
3. Resource limits (if you have a small cluster)

</details>

## Part 3: Deploy Nextcloud with Helm

### Step 1: Add the Nextcloud Helm Repository

```bash
helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update
```

This registers where Helm should download the Nextcloud chart from.

### Step 2: Install Nextcloud

> [!IMPORTANT]
> Deploy Nextcloud using your customized values:
>
> ```bash
> make install
> ```
>
> Or manually:
>
> ```bash
> helm install nextcloud1 nextcloud/nextcloud \
>   -f values.yaml \
>   -n nextcloud1 \
>   --create-namespace
> ```
>
> This creates a new namespace `nextcloud1` and deploys Nextcloud into it.

You should see output like:

```
NAME: nextcloud1
NAMESPACE: nextcloud1
STATUS: deployed
REVISION: 1
```

### Step 3: Monitor Deployment Progress

Nextcloud takes time to initialize. Watch the pod:

```bash
kubectl logs -f nextcloud1-<pod-id> -n nextcloud1
```

Or use the dashboard you installed in Sub-exercise 2:

```bash
kubectl port-forward -n headlamp svc/headlamp 8080:80
```

Then visit <http://localhost:8080> and look for the `nextcloud1` namespace.

**Expected initialization sequence:**

```
[ 1/3 ] Installing Nextcloud 31.0.8.1 ...
[ 2/3 ] Initializing database...
[ 3/3 ] Setting up admin user...
Initialization complete!
```

This can take 5-10 minutes depending on database performance.

## Part 4: Verify Nextcloud is Running

### Check Pod Status

```bash
kubectl get pods -n nextcloud1
```

Expected output:

```
NAME                           READY   STATUS    RESTARTS   AGE
nextcloud1-6d8c7d9f5c-abc12    1/1     Running   0          2m
```

All pods should be `Running` and `READY 1/1`.

### Check Ingress

```bash
kubectl get ingress -n nextcloud1
```

Expected:

```
NAME        HOSTS                       ADDRESS         PORTS   AGE
nextcloud1  nextcloud.yourdomain.com    <external-ip>   80,443  2m
```

### Test TLS Certificate

Verify that cert-manager created a certificate:

```bash
kubectl get certificates -n nextcloud1
```

Expected:

```
NAME               READY   SECRET                  AGE
nextcloud1-tls     True    nextcloud1-tls-secret   2m
```

If `READY` is `False`, wait a bit. cert-manager needs DNS validation which can take 1-2 minutes.

### Access Nextcloud from Your Browser

Once the pod is `Running` and ingress is ready, open your browser:

```
https://nextcloud.<your-domain>
```

(Replace `<your-domain>` with the actual domain you configured in Terraform)

> [!NOTE]
> It might take a moment for the ingress to be fully ready. If you get a connection error, wait 30 seconds and refresh.

You should see the Nextcloud login page:

```
Nextcloud
Username or email
Password
```

Log in with the credentials you set in `values.yaml`:

- **Username**: `admin` (or whatever you set)
- **Password**: Your strong password

## Part 5: Verify Functionality

Once logged in to Nextcloud:

### Create a Test File

1. Click the **+** button in the top left
2. Select **Create new file** or **Create new folder**
3. Create a test file

This verifies:

- ✅ Web application is responding
- ✅ Database is working (user session, file metadata)
- ✅ Storage is accessible

### Upload a File

1. Click the **Upload** button (or drag and drop)
2. Upload a small file (text, image, etc.)
3. Verify the file appears in Nextcloud

This verifies:

- ✅ File upload works
- ✅ Persistent storage (Longhorn) is functioning
- ✅ Data persists across pod restarts

### Check Persistent Storage

View the persistent volume that Nextcloud is using:

```bash
kubectl get pvc -n nextcloud1
```

Expected:

```
NAME                   STATUS   VOLUME                        CAPACITY
nextcloud1-nextcloud   Bound    pvc-abc123...                 8Gi
```

This shows that Longhorn is providing storage to Nextcloud.

## Troubleshooting

### Pod Stuck in "Pending"

**Cause**: Usually insufficient cluster resources or storage issues

**Solution**:

1. Check pod status: `kubectl describe pod -n nextcloud1 nextcloud1-*`
2. Check node resources: `kubectl top nodes`
3. If disk space is full: `kubectl describe persistentvolumeclaims -n nextcloud1`

### Pod CrashLoopBackOff

**Cause**: Application error, usually database connection or initialization failure

**Solution**:

1. Check logs: `kubectl logs -n nextcloud1 nextcloud1-* --tail=50`
2. Check database connectivity from the pod
3. Verify database credentials in `values.yaml` match what Terraform created

### Cannot Access HTTPS / Certificate Error

**Cause**: TLS certificate not ready yet

**Solution**:

1. Wait 2-3 minutes for cert-manager to provision certificate
2. Check certificate status: `kubectl describe certificate -n nextcloud1`
3. If stuck, check cert-manager logs: `kubectl logs -n cert-manager cert-manager-*`

### Admin User Already Exists Error

If you upgrade or reinstall and get: "The Login is already being used"

**Solution**: In `values.yaml`, change the admin username:

```yaml
nextcloud:
  username: admin2  # Change from "admin" to "admin2"
```

Then reinstall:

```bash
helm uninstall nextcloud1 -n nextcloud1
make install
```

### Wipe Database

If you need to completely reset the database:

<details>
<summary>⚠️ Advanced: Wipe MariaDB Database</summary>

Open a MySQL client pod and connect to the database:

```bash
kubectl run mysql-client --image=mysql:5.7 -it --rm --restart=Never -- /bin/bash
```

Then inside the pod:

```bash
mysql -h<host> -u<user> -p<password>
```

At the MySQL prompt:

```sql
SHOW DATABASES;
DROP DATABASE <nextcloud_db>;
EXIT;
```

Then reinstall Nextcloud. It will reinitialize on the empty database.

</details>

### Delete Persistent Volume

If you need to clean up the Nextcloud persistent volume:

```bash
kubectl get pvc -n nextcloud1
kubectl delete pvc <pvc-name> -n nextcloud1
```

Nextcloud will create a new empty volume on the next deployment.

## What's Next

Congratulations! You've successfully deployed a complete, production-like Kubernetes setup with:

1. ✅ Infrastructure provisioned with Terraform
2. ✅ Foundational platform services installed (ingress, TLS, storage, dashboard)
3. ✅ A full-featured web application running (Nextcloud)

### Possible next steps to explore

- **Persistence**: Upload files to Nextcloud and kill the pod; watch it restart with data intact
- **Scaling**: Modify `values.yaml` to increase Nextcloud replicas for high availability
- **Dashboard**: Use Headlamp or `kubectl port-forward` to explore cluster resources
- **Monitoring**: Add observability tools to track application performance
- **GitOps**: Use Flux or Argo CD to automate deployments via Git repositories
- **Additional Apps**: Deploy other applications (databases, caches, microservices)

## Summary

In this sub-exercise, you:

- Generated and customized a Helm chart values file for Nextcloud
- Deployed Nextcloud into your Kubernetes cluster using Helm
- Verified the application was accessible and functional
- Understood how infrastructure, platform, and application layers integrate

**Key insights:**

- Helm charts dramatically simplify application deployment
- Configuration values flow from infrastructure (Terraform) → platform (Kubernetes) → application (Nextcloud)
- Modern applications rely on foundational services (ingress, storage, certificates)
- Kubernetes and Helm enable reproducible, scalable application deployments

**Architecture achieved:**

```
STACKIT Cloud (Infrastructure)
  ├── Terraform-provisioned: SKE cluster, MariaDB, S3, DNS
  │
  ├── Kubernetes Platform Services
  │   ├── Traefik (Ingress)
  │   ├── cert-manager (TLS)
  │   ├── Longhorn (Storage)
  │   └── Headlamp (Dashboard)
  │
  └── Nextcloud Application
      ├── Web UI (Traefik → Nextcloud Pod)
      ├── Data Storage (Longhorn PVC)
      └── Metadata (MariaDB)
```
