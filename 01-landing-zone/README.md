# Exercise 1: Deploy a Landing Zone on STACKIT

## Introduction

A **landing zone** is the foundational infrastructure that you set up in a cloud environment.
It provides the basic building blocks for all subsequent deployments:
networking, security controls, and a management server to orchestrate future work.

In this exercise, you'll deploy a minimal landing zone on STACKIT Cloud comprising:

- A **virtual network** with private networking
- **Security controls** (security groups with ingress rules)
- A **jumphost server** (Ubuntu VM) that serves as your entry point to the network
- **DNS records** for convenient access

The diagram below shows what will be deployed:

![Landing Zone Architecture](./graph.png)

> [!NOTE]
> The initial infrastructure deployment takes 5-10 minutes. While Terraform is provisioning your resources, you can read the code walkthrough in the next section to understand how it all works.

## Learning Goals

After completing this exercise, you will be able to:

- Understand what a landing zone is and why it's important
- Deploy cloud infrastructure using Terraform and the STACKIT provider
- Configure network security rules (security group ingress rules)

## Preparation & Prerequisites

Ensure you have the following installed on your system:

- **Terraform CLI** (v1.12+): [Download here](https://www.terraform.io/downloads)
- **STACKIT CLI**: Follow the [STACKIT CLI installation guide](https://github.com/stackitcloud/stackit-cli/blob/main/INSTALLATION.md)
- **SSH key pair**: Generate one with `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa` if you don't have one

### Setup Instructions

1. (Optional) Copy the base files to your working directory:

   ```bash
   cp -r exercises/01-landing-zone/base/ ~/my-landing-zone
   cd ~/my-landing-zone
   ```

2. Create your configuration file:

   ```bash
   cp terraform.tfvars.tpl terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:

   ```hcl
   project_id  = "YOUR-STACKIT-PROJECT-ID"
   name_prefix = "jd"              # Use your initials or short identifier
   name_suffix = "1"               # Chose freely
   domain      = "jd.stackit.zone" # Pick your own domain name in a free STACKIT zone: *.runs.onstackit.cloud or .stackit.{rocks,gg,zone,run}
   ```

4. Initialize Terraform:

   ```bash
   terraform init
   ```

## Part 1: Deploy Base Infrastructure

Let's deploy the base infrastructure to the cloud.

> [!IMPORTANT]
> Run the following command. You'll be asked to review and approve the Terraform plan. Type `yes` to proceed.
> You will need to setup the STACKIT credentials for the terraform CLI.
>
> ```bash
> export STACKIT_SERVICE_ACCOUNT_KEY_PATH=/path/to/sa_key.json
> terraform apply
> ```
>
> This will create show you a list of all resources it wants to create and create them.
>
> **⏱️ Typical deployment time: 5-10 minutes**

Once you've started the apply, move to the next section while it's running.

## Part 2: Understanding the Architecture

While your infrastructure is being deployed, let's walk through what each Terraform file does:

### `main.tf` - Provider Setup

This file configures the STACKIT provider and specifies which provider versions we're using:

```hcl
terraform {
  required_providers {
    stackit = {
      source  = "stackitcloud/stackit"
      version = "0.101.0"
    }
    # ... other providers for cloud-init and random passwords
  }
}

provider "stackit" {
  default_region = "eu01"
}
```

### `variables.tf` - Configuration Inputs

Defines the variables your configuration needs (project ID, naming, SSH keys, etc.). These are populated from `terraform.tfvars`.

### `network.tf` - Network & Security

Creates:

- Virtual Network: An isolated network for your infrastructure
- Security Group*: Acts as a firewall with rules for what traffic is allowed
- Network Interfce: Attaches your jumphost to the network
- Public IP: Makes the jumphost reachable from the internet

### `servers.tf` - Jumphost Server

Defines the Ubuntu VM that will be your entry point into the network. It:

- Uses cloud-init to automatically install software and configure the system
- Sets up SSH access via your public key
- Generates a backup password for emergency access

### `dns.tf` - DNS Records

Creates a DNS zone and a DNS A record that points to your jumphost's public IP address. This lets you access the server by name (e.g., `jumphost.jd.stackit.zone`) instead of by IP address.

### `cloud-init/` - Initialization Scripts

These scripts run when the VM starts for the first time. They install and configure tools like WireGuard and Forgejo Runner.

## Part 3: Add Security Group Rules

By now, your base infrastructure should be deployed! You have a network, a jumphost server, and a security group - but the security group has **no ingress rules**, which means nothing can reach your jumphost yet.

Your task is to add two security group rules to allow traffic into your jumphost:

1. **SSH Rule** (port 22, TCP) - for remote shell access
2. **WireGuard Rule** (port 51820, UDP) - for VPN access

### Task: Apply Security Group Rules

Open `network.tf` in your editor. You'll see two commented-out resource blocks (lines 13f). Your job is to uncomment them and fill them out. The apply your updated infrastructure to reach your jumphost. When connecting via SSH, use the username `ubuntu`.

> [!IMPORTANT]
> In `network.tf`, uncomment and fill out the two `stackit_security_group_rule` resource blocks.

<details>
<summary>💡 Hint: Security Group Rule Structure</summary>

You can look at the documentation of the [STACKIT terraform provider](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs/resources/security_group_rule) to find out what fields are available.

</details>

<details>
<summary>💡 Hint: What Fields you might need</summary>

- **`project_id`**: Must match your STACKIT project. Can we reference the variable here?
- **`security_group_id`**: Links this rule to the security group we created. Try to use a reference instead of hard-coding an ID.
- **`description`**: A human-readable label (use the ones provided in the comments)
- **`direction`**: "ingress" means inbound (outside to jumphost); "egress" means outbound
- **`ether_type`**: "IPv4" for IPv4 addresses (also supports IPv6)
- **`protocol`**: An object with a `name` field. Values: "tcp", "udp", "icmp", etc.
- **`port_range`**: An object with `min` and `max`. For a single port, set both to the same value
- **`ip_range`**: CIDR notation for allowed IP addresses. "0.0.0.0/0" means any IP

</details>

<details>
<summary>💡 Hint: Applying your changes</summary>

To apply your changes, you just need to run `terraform apply` again.

</details>

<details>
<summary>💡 Hint: Connecting to your jumphost</summary>

You should be able to use your SSH key to connect to the instance. You can use `terraform output` to retrieve all the info you need.

</details>

<details>
<summary>🔑 Solution </summary>

Check out the [complete network.tf](./solution/network.tf) file in the solutions
directory. In case your traffic is routed through company proxies, it might be
simpler for the exercise to just allow all IPs (`0.0.0.0/32`). To connect via SSH you need to run:

```bash
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw jumphost_fqdn)

# or alternatively
ssh -i ~/.ssh/id_rsa ubuntu@$(terraform output -raw public_ip)
```

</details>

### Troubleshooting

**Connection refused?**

- Verify the security group rules were created: `terraform state list | grep security_group_rule`
- Wait a moment for the security group rules to propagate in the cloud
- Check that you're using the correct SSH key

**DNS not resolving?**

- The DNS record creation takes a few seconds to propagate
- Use the public IP address directly if DNS isn't working yet
- DNS changes can take up to 60 seconds to propagate globally

## Summary

In this exercise you successfully deployed a small example "Landing Zone" with terraform.
You learned about

- what a "Landing Zone" is
- how terraform enables infrastructure as code (IaC)- version-controlled, reproducible deployments
- how to add new resources to a terraform deployment

### Cleanup (Optional)

> [!WARNING]
> Do not run the cleanup during the training. You can destroy the resources at the end of the day.

When you're done with the training and want to destroy all resources to save costs:

```bash
terraform destroy
```

Type `yes` to confirm. This will remove all infrastructure we created.

## Resources

- [STACKIT Cloud Documentation](https://docs.stackit.cloud/)
- [Terraform STACKIT Provider](https://registry.terraform.io/providers/stackitcloud/stackit/latest/docs)
- [Terraform Getting Started](https://www.terraform.io/intro)
