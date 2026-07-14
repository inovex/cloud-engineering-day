# Sub-exercise 1: Deploy Kubernetes Cluster with Terraform

## Introduction

In this step, you'll provision a complete Kubernetes cluster and supporting infrastructure on STACKIT using **Terraform**, an Infrastructure-as-Code tool. Instead of clicking through a web console, you'll declare what you want in code and let Terraform handle the rest.

This is a critical first step: without the cluster and associated services (DNS, databases, storage), there's nowhere to deploy applications. Terraform will handle all of this in one coordinated deployment.

## Learning Goals

After completing this sub-exercise, you will:

- Understand Infrastructure as Code (IaC) principles and how Terraform works
- Configure cloud resources declaratively using HCL (HashiCorp Configuration Language)
- Use Terraform workflows (`init`, `plan`, `apply`) to provision real cloud infrastructure
- Understand Terraform state and how it tracks cloud resources
- Extract and use generated outputs (kubeconfig, credentials) for subsequent steps

## Prerequisites

Ensure you have installed:

- **Terraform CLI** (v1.12+): [Download](https://www.terraform.io/downloads)
- **STACKIT CLI**: [Installation guide](https://github.com/stackitcloud/stackit-cli/blob/main/INSTALLATION.md)
- **STACKIT Service Account Key**: Create one in your STACKIT project and download the JSON file
- **A STACKIT Project**: With appropriate permissions to create resources

**Estimated time**: 20 minutes (including cloud provisioning wait time)

## Part 1: Setup & Deploy

Since you've already completed Exercise 1 (Landing Zone), you know the Terraform workflow. This is faster:

> [!IMPORTANT]
>
> 1. Copy the template: `cp terraform.tfvars.tpl terraform.tfvars`
> 2. Edit `terraform.tfvars` with your project ID and a unique domain (e.g., `myname.stackit.zone`)
> 3. Set credentials: `export STACKIT_SERVICE_ACCOUNT_KEY_PATH=/path/to/sa_key.json`
> 4. Initialize: `make init`
> 5. Apply: `make apply` (⏱️ 10-20 minutes)

The Terraform will provision:

- SKE Kubernetes cluster with node pools
- MariaDB database
- S3 object storage
- DNS domain
- Observability stack
- Generated files (`kubeconfig`, `tf_output.env`, etc.) for the next step

## Part 2: Understanding What Gets Deployed

This Terraform project provisions these components:

| File               | Purpose                                   |
| ------------------ | ----------------------------------------- |
| `main.tf`          | STACKIT provider configuration            |
| `ske.tf`           | Kubernetes cluster with node pools        |
| `dns.tf`           | DNS domain and records                    |
| `mariadb.tf`       | Managed database for applications         |
| `s3.tf`            | Object storage bucket                     |
| `observability.tf` | Monitoring and logging integration        |
| `helm-template.tf` | **Generates output files** for next steps |

After `terraform apply` completes, check the `generated/` directory for:

- `kubeconfig-*.yaml`: Credentials for kubectl
- `tf_output.env`: Environment variables (domain, database credentials, etc.)
- `nextcloud_chart_values.yml`: Pre-filled Helm deployment values

## Part 3: Verify Deployment

Once `terraform apply` completes:

```bash
# View Terraform outputs
make output

# List generated files
ls -la generated/
```

You should see:

- ✅ Cluster endpoint and credentials in `kubeconfig-*.yaml`
- ✅ Resource details in `tf_output.env`
- ✅ Helm values in `nextcloud_chart_values.yml`

(Optional) Verify in the STACKIT Portal:

- SKE cluster is running
- Database instance exists
- Storage bucket was created
- DNS records are configured

## Troubleshooting

**Terraform apply fails with credential errors:**

- Verify `STACKIT_SERVICE_ACCOUNT_KEY_PATH` is set and points to a valid JSON file
- Try `stackit auth token` to test authentication

## Summary

You've provisioned a complete Kubernetes platform infrastructure on STACKIT:

- Terraform configured your project details and deployed all resources
- Generated output files bridge infrastructure → platform setup → application deployment
- The separation of concerns (IaC separate from k8s config and app deployment) enables team collaboration

Next: [Sub-exercise 2: Install Cluster Foundations](../2_basics/README.md)
