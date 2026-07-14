# Exercise 0: Getting Started

## Introduction

Before you can deploy cloud infrastructure and work with STACKIT, you need to set up all the required tools and establish authentication.
This exercise ensures everyone has a working development environment ready for the rest of the day's exercises.

## Learning Goals

After completing this exercise, you will be able to:

- Install and verify all required CLI tools
- Authenticate with STACKIT Cloud Portal
- Configure STACKIT CLI with your project
- Create and store a service account key for later access

## Part 1: Install Required Tools

Install the following tools on your system. Use the official installation guides provided below.

### Required Tools

#### stackit-cli

The STACKIT command-line interface for managing cloud resources.

**Install:** [STACKIT CLI Installation Guide](https://github.com/stackitcloud/stackit-cli/blob/main/INSTALLATION.md)

**Verify installation:**

```bash
stackit version
# should be v0.65+
```

#### Terraform

Infrastructure as Code tool for provisioning cloud resources.

**Install:** [Terraform Downloads](https://www.terraform.io/downloads)

**Verify installation:**

```bash
terraform version
# should be version 1.10+
```

#### Helm

Package manager for Kubernetes.

**Install:** [Helm Installation Guide](https://helm.sh/docs/intro/install/)

**Verify installation:**

```bash
helm version
# should be version 4+
```

#### kubectl

Command-line tool for interacting with Kubernetes clusters.

**Install:** [kubectl Installation Guide](https://kubernetes.io/docs/tasks/tools/)

**Verify installation:**

```bash
kubectl version --client
```

#### Cloud Foundry CLI (cf)

CLI tool for interacting with Cloud Foundry deployments.

**Install:** [Cloud Foundry CLI Installation Guide](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html)

**Verify installation:**

```bash
cf --version
```

#### Basic Tools (git, gnu-utils)

**Git**
**Install:** [Git Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

**Verify installation:**

```bash
git --version
```

**GNU Utils** (make, grep, sed, awk, etc.)
These are typically pre-installed on macOS and Linux. Windows users should install them via WSL or Git Bash (see below).

**Verify installation:**

```bash
make --version
grep --version
```

### Windows Users

<details>
<summary>🪟 Windows Installation Note</summary>

For Windows users, we recommend using either:

1. **Windows Subsystem for Linux (WSL):** [WSL Installation Guide](https://learn.microsoft.com/en-us/windows/wsl/install)
2. **Git Bash:** Included with [Git for Windows](https://gitforwindows.org/)

All tools listed above have dedicated installers for Windows. Alternatively, you can use a package manager like [Chocolatey](https://chocolatey.org/) or [Scoop](https://scoop.sh/) to simplify installation.

</details>

## Part 2: Setup STACKIT Access

### Step 1: Verify Your STACKIT Project

1. Open [portal.stackit.cloud](https://portal.stackit.cloud) in your browser
2. Sign in with your company email
3. Open the resource manager (top left corner). You should see a folder "STACKIT-Training" inside the "inovex GmbH" organization - and inside it you should see one project. Take note of the **Project ID** (you'll need it in the next steps)

> [!TIP]
> Your project should be named `ced-20260714-XX`

### Step 2: Authenticate with stackit CLI

Authenticate your local STACKIT CLI with your account:

```bash
stackit auth login
```

This will open your browser to complete the authentication flow. Once authenticated, your credentials will be stored locally.

> [!NOTE]
> The authentication flow is interactive and browser-based. Follow the prompts to complete the login.

### Step 3: Configure Your Default Project

Set your default project so the CLI knows which project to use:

```bash
stackit config set --project-id <YOUR-PROJECT-ID>
```

Replace `<YOUR-PROJECT-ID>` with the Project ID from Step 1.

**Verify the configuration:**

```bash
stackit project describe
```

This command should return details about your project, confirming that the configuration is correct.

<details>
<summary>💡 Hint: Finding Your Project ID</summary>

If you're unsure about your Project ID, you can list all projects available to your account:

```bash
stackit project list
```

Look for your project in the output and copy its ID from the `ID` column.

</details>

### Step 4: Create a Service Account Key

Service account keys allow programmatic access to STACKIT resources (used by Terraform and other tools).

Create a service account key in the project either via the UI or with the CLI:

```bash
stackit service-account create --name "terraform"
stackit service-account key create --email <SERVICE-ACCOUNT-EMAIL> --expires-in-days 2 -ojson > sa_key.json

# You also need to give the service account permissions
stackit project member add <SERVICE-ACCOUNT-EMAIL> --role editor
```

> [!IMPORTANT]
> Store the `sa_key.json` file in a safe location. You'll use it later for Terraform and other CLI tools. **Do not commit it to version control.**

<details>
<summary>💡 Hint: Best Practices for Service Account Keys</summary>

- Store the key file outside of your project directory
- Consider storing it in `~/.stackit/` or a similar secure location
- Add `sa_key.json` and `*.sa_key.json` to your `.gitignore` to prevent accidental commits
- Treat service account keys like passwords—keep them confidential

</details>

## Part 3: Clone or downlaod this repository

For the next exercises you will need the files from this repository locally on your computer.
Either download the repository using the GitHub UI, or clone it:

```bash
git clone https://github.com/inovex/cloud-engineering-day.git
```

## Summary

You've successfully set up your development environment! You now have:

- All required CLI tools installed and verified
- Authenticated with STACKIT Cloud Portal
- Configured STACKIT CLI with your default project
- Created and stored a service account key for programmatic access

Your environment is now ready for the remaining exercises. In the next exercise, you'll use these tools to deploy a landing zone on STACKIT Cloud.
