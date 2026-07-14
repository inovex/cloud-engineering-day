# Exercise 5: Observability

## Introduction

In this exercise, you'll connect your Nextcloud deployment to the STACKIT Observability instance that you provisioned in Exercise 3.
You'll use Grafana Alloy as a unified collector for both logs and metrics.
Alloy runs as a DaemonSet on your Kubernetes cluster and ships all data directly to your observability stack, where you can visualize it in Grafana.

## Learning Goals

After completing this exercise, you will:

- Understand how Grafana Alloy collects logs and metrics from Kubernetes
- Configure credentials securely using Kubernetes Secrets
- Deploy Alloy as a DaemonSet to your cluster
- Query logs and metrics in Grafana
- Create dashboards to monitor your Nextcloud deployment

## Part 1: Gather Your Credentials

Before you install Alloy, you need to collect the credentials and endpoints from your STACKIT Observability instance.
These will be stored in a Kubernetes Secret that Alloy reads at runtime.

### Step 1: Get Your Observability Instance ID and Endpoints

Run the following commands to find your credentials:

```bash
# List your observability instances
stackit observability instance list

# Get the endpoint URLs for your instance (replace <ID> with the instance ID)
stackit observability instance describe <ID>

# Get the Grafana credentials from Terraform output
terraform -chdir=../03-ske/1_alloc output -json grafana_access
```

You'll see output similar to:

```json
{
  "dashboard_url": "https://...",
  "grafana_url": "https://...",
  "push_username": "your-username",
  "push_password": "your-password",
  "metrics_url": "https://...",
  "otlp_logs_url": "https://..."
}
```

### Step 2: Fill in the Credentials Secret

All necessary files for this exercise are in this directory.
Copy `cp secret.yaml.template secret.yaml` file:

> [!IMPORTANT]
>
> Open `secret.yaml` and fill in the values from the terraform output

> [!WARNING]
> `secret.yaml` will contain real credentials.
> Do not commit it to git.
> It should be `.gitignore`d already

<details>
<summary>💡 Hint: Mapping terraform output vaules</summary>

You should be able to find all values conveniently in the terraform output:

> 1. **USERNAME:** Copy from `push_username` in the Terraform output
> 2. **PASSWORD:** Copy from `push_password` in the Terraform output
> 3. **OTLP_LOGS_ENDPOINT:** Copy the `otlp_logs_url` from the instance describe output and **remove the `/v1/logs` suffix**
> 4. **METRICS_PUSH_URL:** Copy the `metrics_url` from the instance describe output

</details>

## Part 2: Install Grafana Alloy

Once you've filled in `secret.yaml`, installation is straightforward:

### Step 1: Run the Installation

```bash
make install
```

This script will:

1. Create the `observability` namespace
2. Apply the credentials Secret
3. Add the Grafana Helm repository
4. Install/upgrade Alloy as a DaemonSet

### Step 2: Verify the Deployment

Check that the Alloy pods are running on all nodes:

```bash
kubectl get pods -n observability
```

You should see one `alloy-*` pod per node in your cluster.
All pods should show `Running` status.

Check the logs to ensure there are no errors:

```bash
kubectl logs -n observability -l app.kubernetes.io/name=alloy --tail=50
```

You should see messages like:

```
level=info msg="Listening for HTTP requests" addr=127.0.0.1:12345
```

If you see authentication errors or connection failures, verify your credentials in `secret.yaml` are correct.

<details>
<summary>💡 Hint: Troubleshooting Alloy Pods</summary>

If pods are stuck in a pending state or are not running:

1. Check pod events: `kubectl describe pod -n observability <pod-name>`
2. Check resource requests: `kubectl get pod -n observability -o json | jq '.items[].spec.containers[].resources'`
3. Check node availability: `kubectl get nodes`

If logs show connection errors:

1. Verify `secret.yaml` credentials are correct
2. Test connectivity: `curl -u <USERNAME>:<PASSWORD> <OTLP_LOGS_ENDPOINT>`

</details>

## Part 3: Access Grafana and Create Observability Queries

Now that Alloy is collecting logs and metrics, you can access Grafana to visualize the data.

### Step 1: Open Grafana

Get your Grafana URL:

```bash
stackit observability instance describe <ID>
```

Or find it in the STACKIT Portal under your Observability instance.

Open the URL in your browser and log in via SSO.

### Step 2: Import the Nextcloud Dashboard

Grafana has community dashboards you can import to visualize Nextcloud metrics.

In Grafana, navigate to **Dashboards → Import** and paste the dashboard ID:

```text
24356
```

(This is the "Nextcloud Overview by TSandrini" dashboard)

Alternatively, go to [grafana.com/grafana/dashboards/24356](https://grafana.com/grafana/dashboards/24356), copy the ID, and paste it in the Grafana import dialog.

After importing:

1. Select the Prometheus data source (Thanos)
2. Set the time range to "Last 5 minutes"
3. You should see Nextcloud metrics like CPU, memory, requests, etc.

> [!NOTE]
> It may take a minute or two for metrics to appear.
> If you see "No data", verify that Alloy pods are running and scraping the Nextcloud exporter.

### Step 3: Query Logs

Loki (Grafana's log aggregation system) receives logs from Alloy via OTLP.

In Grafana, navigate to **Explore** and select the **Loki** data source.

In the query editor, run a simple query to see Nextcloud logs:

```logql
{k8s_namespace_name="nextcloud"}
```

You should see log entries from Nextcloud pods.

> [!TIP]
> Loki converts dots to underscores when ingesting via OTLP, so `k8s.namespace.name` becomes `k8s_namespace_name`.
> Other useful labels include:
>
> - `k8s_pod_name`
> - `k8s_container_name`
> - `k8s_deployment_name`

Try other queries:

```logql
# Errors only
{k8s_namespace_name="nextcloud"} |~ "error|ERROR|warning|WARNING"

# Specific pod
{k8s_pod_name="nextcloud-0"}

# Specific container
{k8s_container_name="nextcloud"}
```

### Step 4: Query Metrics

In Grafana **Explore**, switch to the **Prometheus** data source.

Run some basic metric queries:

```promql
# Some metrics are forwarded automatically by the SKE integration
kube_node_info{}

nextcloud_files_total{}
```

### Step 5: Query cAdvisor Container Metrics

Alloy scrapes cAdvisor metrics from the kubelet on each node (`/metrics/cadvisor`).
These give you per-container CPU, memory, network, and disk I/O metrics.

In Grafana **Explore → Prometheus**, try:

```promql
# CPU usage per container (rate over 5 minutes)
rate(container_cpu_usage_seconds_total{namespace="nextcloud"}[5m])

# Memory usage per container
container_memory_working_set_bytes{namespace="nextcloud"}

# Network receive rate
rate(container_network_receive_bytes_total{namespace="nextcloud"}[5m])
```

You can also import the **Kubernetes / Compute Resources / Pod** dashboard (ID `6417`) for a ready-made view of container resource usage.

Combine metrics into simple graphs to understand your deployment's performance.

### Step 5: Explore Pre-populated SKE Dashboards

In addition to the Nextcloud metrics you've just queried, your Observability instance is automatically populated with data from your SKE cluster integration that was configured in Exercise 3.

In Grafana, explore these pre-populated dashboards:

**SKE Dashboard:**
Navigate to **Dashboards** and look for dashboards starting with "SKE" or "Kubernetes".
These dashboards are automatically populated with cluster-level metrics such as:

- Node CPU and memory usage
- Pod distribution across nodes
- Network I/O statistics
- Container resource usage

**Load Balancers:**
In Grafana, navigate to **Explore → Prometheus** and query:

```promql
# Load Balancer metrics
stackit_load_balancer_info{}
```

Or browse the available dashboards for "Load Balancer" which shows:

- Load balancer status and availability
- Traffic patterns
- Health check statistics
- Connection counts

These metrics were automatically sent to your Observability instance because the Terraform configuration in Exercise 3 set up the SKE-to-Observability integration.

## Part 5: Debug Alloy (Optional)

If metrics or logs aren't appearing, you can inspect Alloy's internal state via its debug UI:

```bash
make ui
```

This port-forwards Alloy's UI to `http://localhost:12345`.
Open it in your browser to see:

- **Status:** Component health and connectivity
- **Logs:** Real-time debug output
- **Pipeline:** Data flow between components

If you see red errors in the pipeline, check:

1. Credentials in `secret.yaml` are correct
2. Endpoints are reachable (not behind a firewall)
3. Alloy pod logs: `kubectl logs -n observability -l app.kubernetes.io/name=alloy`

## Verification

You have successfully completed this exercise when:

- Alloy pods are running in the `observability` namespace
- Logs appear in Grafana (Explore → Loki)
- Metrics appear in Grafana (Explore → Prometheus or the Nextcloud dashboard)
- You can query both logs and metrics manually

## Summary

You've successfully connected your Kubernetes cluster to STACKIT Observability:

- Installed Grafana Alloy as a unified log and metrics collector
- Configured secure credential management via Kubernetes Secrets
- Deployed Alloy as a DaemonSet to collect data from all nodes
- Imported a Nextcloud dashboard to visualize metrics
- Queried logs and metrics using LogQL and PromQL

Your observability stack is now live.
All logs and metrics from your Nextcloud deployment are being collected and can be monitored in Grafana.
You can now track performance, troubleshoot issues, and understand your application's behavior in production.
