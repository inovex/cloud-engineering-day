# Exercise 02: Deploying an Application on STACKIT Cloud Foundry

In this exercise you will deploy Nextcloud to STACKIT Cloud Foundry (SCF).
Cloud Foundry takes your application code, selects the right buildpack, builds a container image, and runs it with a public route — all from a single command.

Learning goals:

- Deploy an application to SCF using `cf push`
- Monitor a running application with live log streaming
- Understand that CF containers are ephemeral and what that means for persistent data

## Prerequisites

- The CF CLI (`cf`) is installed

## Step 0: Create a Cloud Foundry Organization and Space

Navigate to "Cloud Foundry" in the [STACKIT Portal](https://portal.stackit.cloud) and create a new organization.
Once the organization is created, change its plan to "small".
Then create a space inside the organization.

Log in to Cloud Foundry:

```bash
cf login -a https://api.system.01.cf.eu01.stackit.cloud --sso
```

Target your organization and space:

```bash
cf target -o <organization-name> -s <space-name>
```

## Step 1: Bootstrap the Application

The exercise directory contains a script that downloads the official Nextcloud release and places a minimal configuration file.

> [!IMPORTANT]
> Run the bootstrap script from inside this exercise directory:
>
> ```bash
> chmod +x ./prepare-nextcloud-on-scf.sh
> ./prepare-nextcloud-on-scf.sh
> ```

This creates an `htdocs/` directory with the Nextcloud source code.
The `config.php` file sets `trusted_domains` to `*` so that CF's dynamically assigned hostname is accepted.

## Step 2: Deploy to SCF

> [!IMPORTANT]
> Set a application name in `manifest.yaml` and deploy it:
>
> ```bash
> cf push
> ```

Cloud Foundry uploads your code, runs the PHP buildpack, and assigns a public route.
Once the push completes, the CLI prints the URL of your application. This will take a few minutes.
Open it in your browser.

<details>
<summary>💡 Hint: What does the manifest.yml do?</summary>

The `manifest.yml` in this directory tells CF how to run the application:

```yaml
applications:
- name: nextcloud-scf
  memory: 4096M
  disk_quota: 4G
  instances: 1
  buildpack: php_buildpack
  path: .
  env:
    BP_WEB_DIR: "htdocs"
```

`BP_WEB_DIR` tells the PHP buildpack that the web root is the `htdocs/` subdirectory.
</details>

## Step 3: Complete the Setup Wizard

Nextcloud shows a setup wizard on the first visit.
Complete the wizard to create your admin account and initialize the application.

> [!NOTE]
> When asked for the database, select SQLite.
> It is the only option that works without an external database service.

## Step 4: Stream Live Logs

Open a second terminal and stream logs from your running application:

```bash
cf logs nextcloud-scf
```

Switch back to your browser and navigate around in Nextcloud.
Watch how HTTP requests, PHP output, and application events appear in real time in your terminal.

Press `Ctrl+C` to stop streaming when you are done.

## Step 5: Statelessness

CF containers start fresh every time they restart — they carry no local state from previous runs.

> [!IMPORTANT]
> Follow these steps to observe statelessness:
>
> 1. Upload a file to Nextcloud via the browser (any small file works).
> 2. Confirm the file appears in your file list.
> 3. Restart the application:
>    ```bash
>    cf restart nextcloud-scf
>    ```
> 4. Wait for the app to come back, then reload the URL.

The Nextcloud setup wizard reappears.
The SQLite database, your admin account, and the uploaded file are gone.
The container started from a clean slate.

> [!NOTE]
> In production, applications must store all persistent state outside the container.
> On STACKIT this means using managed services such as STACKIT Object Storage (S3-compatible) for files and STACKIT DBaaS for the database.
> CF itself connects applications to these services via the service binding mechanism.

## Verification

Check that your application is running:

```bash
cf app nextcloud-scf
```

You should see output similar to:

```
name:              nextcloud-scf
requested state:   started
routes:            nextcloud-scf.example.cf.stackit.cloud
instances:         1/1
memory usage:      4096M
```

## Cleanup

Delete the application and its route when you are done:

```bash
cf delete nextcloud-scf -r
```

The `-r` flag also removes the associated route.

## Summary

You deployed a real PHP application to STACKIT Cloud Foundry with a single `cf push` command.
Cloud Foundry detected the PHP buildpack automatically, built a container, and exposed the application via a public route.
You used `cf logs` to watch live application activity and confirmed that CF containers are stateless — any data written to the local disk is lost on restart.
This is why cloud-native applications must externalise all persistent state to managed services.
