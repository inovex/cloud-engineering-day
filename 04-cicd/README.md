# Exercise 4: CI/CD and GitOps

## Introduction

Modern software delivery relies on two complementary practices:

**CI/CD** (Continuous Integration / Continuous Delivery) automates the steps that happen when code is pushed to Git — running tests, building artifacts, and validating infrastructure changes.

**GitOps** takes this further: the desired state of your infrastructure is stored in Git, and an automated operator continuously reconciles the cluster to match that state.
[ArgoCD](https://argo-cd.readthedocs.io/) is the most widely used GitOps operator for Kubernetes.
It watches a Git repository and automatically applies changes to your cluster whenever the repository is updated.

In this exercise, you will set up both.
First, you will create a STACKIT Hosted Git instance and trigger a CI workflow.
Then, you will install ArgoCD and use it to deploy a sample application — driven entirely by Git.

## Learning Goals

After completing this exercise, you will be able to:

- Create a STACKIT Hosted Git instance and enable STACKIT Runners
- Migrate a GitHub repository into Forgejo and trigger a CI workflow
- Install ArgoCD into a Kubernetes cluster using Kustomize
- Expose ArgoCD's web UI via Traefik Ingress with TLS termination
- Deploy and update an application using the GitOps workflow

## Part 1: Set Up CI/CD with Forgejo Workflows

### Step 1: Create a STACKIT Hosted Git Instance

1. In the STACKIT portal, navigate to **Git**
2. Click **Create Instance**
3. Wait for provisioning to complete
4. Open the Forgejo URL shown in the portal — it looks like `https://foo.git.onstackit.cloud`
5. Log in using your STACKIT identity

### Step 2: Enable STACKIT Runners

Runners execute your CI workflows.
STACKIT provides a managed runner that you enable after creating your GIT instance:

1. In the STACKIT portal, navigate to your **Git** instance
2. On the right hand side, under `Continuous integration & Runners` click edit
3. Enable runners and save

> [!NOTE]
> STACKIT provides a built-in managed runner.
> You can see these runners after a few minutes in the repository settings

### Step 3: Copy the Training Repository

> [!IMPORTANT]
> Migrate the training repository into your Forgejo organization:
>
> 1. Click the **+** icon → **New Migration**
> 2. Select **GitHub** as the source type
> 3. Set the URL to `https://github.com/inovex/cloud-engineering-day`
> 4. Set the **Owner** to your organization
> 5. Make sure **This repository will be a mirror** is unchecked
> 6. Click **Migrate Repository**

### Step 4: Trigger the Workflow

The repository contains a sample workflow at `.forgejo/workflows/demo.yaml`.
Take a moment to look at it — it runs on every push and produces a small artifact.

Trigger it by making a commit in the Forgejo UI:

1. Open the migrated repository
2. Click on `README.md`
3. Click the pencil (edit) icon
4. Make any small change (e.g. add a blank line)
5. Click **Commit Changes**

### Step 5: Observe the Workflow Run

1. Go to the **Actions** tab of your repository
2. Click on the running or completed workflow
3. Inspect the job steps and their output
4. Once complete, check the uploaded artifacts

> [!NOTE]
> In a real pipeline, this is where you would likely run `terraform apply`, build container images,
> or run integration tests.
> For this exercise, we move on to GitOps to save time.

---

## Part 2: Install ArgoCD and Log In

Now we will setup ArgoCD to showcase what a CI/CD workflow might look like

---

> [!IMPORTANT]
> Install ArgoCD and expose its UI:
>
> ```bash
> export DOMAIN=argo.<your-domain>   # e.g. argo.foo.stackit.zone -> Take the same domain you used in previous exercises.
> kubectl apply --server-side -k ./argocd
> make expose-ui
> ```

Get the initial admin password:

```bash
make credentials
```

Open `https://argocd.<DOMAIN>` and log in with username `admin` and the password above.

<details>
<summary>💡 Hint: Verify pods are running</summary>

If the UI is not reachable, check that all ArgoCD pods are ready:

```bash
kubectl get pods -n argocd -l app.kubernetes.io/part-of=argocd --watch
```

All pods should show `1/1 Running`. Press `Ctrl+C` once they are.

</details>

<details>
<summary>💡 Hint: Why does ArgoCD run in insecure mode?</summary>

By default ArgoCD terminates TLS itself.
When Traefik is the ingress controller, two TLS layers conflict.
The `argocd-configmap.yaml` patch sets `server.insecure: "true"` so Traefik handles TLS termination cleanly.

</details>

---

## Part 3: Deploy a Sample Application

You will now configure ArgoCD to deploy an application from your Forgejo repository —
the same repository you migrated in Part 1.

### Step 1: Create a Technical User

ArgoCD needs credentials to pull from Forgejo.
Create a dedicated user now — you will need its password shortly.

1. In the STACKIT portal, navigate to your **Git** instance → **Users**
2. Click **Create User**
3. Choose a username (e.g. `argocd-bot`) and set a password
4. Save the user

### Step 2: Grant Repository Access

1. In Forgejo, open your migrated repository
2. Go to **Settings** → **Collaborators**
3. Search for the user you just created and add them with the **Read** role

### Step 3: Register the Repository in ArgoCD

1. Open the ArgoCD UI at `https://argocd.<DOMAIN>`
2. Go to **Settings** → **Repositories** → **Connect Repo**
3. Fill in the form:
   - **Connection method**: HTTPS
   - **Repository URL**: your Forgejo repo URL (e.g. `https://foo.git.onstackit.cloud/my-org/cloud-engineering-day.git`)
   - **Username**: the technical user you created
   - **Password**: the technical user's password
4. Click **Connect**

The repository should show a **Successful** connection status.

### Step 4: Deploy the Application

The file `exercises/04-cicd/application/app.yaml` defines an ArgoCD `Application` resource.
Open it and replace the placeholder `repoURL` with your actual Forgejo repository URL:

```yaml
repoURL: 'https://foo.git.onstackit.cloud/my-org/cloud-engineering-day.git'
```

> [!IMPORTANT]
> Apply the manifest:
>
> ```bash
> kubectl apply -f exercises/04-cicd/application/app.yaml
> ```

Open the ArgoCD UI.
You will see a new application called **podinfo**.
If the URL is still a placeholder, ArgoCD will show a **ComparisonError** — this is expected.
Once you have set the correct URL and re-applied, ArgoCD will sync and the application will turn green.

<details>
<summary>💡 Hint: Application stays in error state</summary>

Check that:
- The `repoURL` in `app.yaml` exactly matches the URL shown in **Settings → Repositories**
- The technical user has been added as a collaborator on the repository
- You re-ran `kubectl apply -f exercises/04-cicd/application/app.yaml` after editing the file

</details>

### Step 5: Make a Change via Git

You will now update the application through Git and watch ArgoCD reconcile it automatically.

In Forgejo, navigate to `exercises/04-cicd/application/hpa.yaml` and click the pencil icon.
Change `minReplicas` from `2` to `3`:

```yaml
  minReplicas: 3
```

Commit the change directly to the `main` branch.

Switch to the ArgoCD UI and watch the **podinfo** application.
Within a minute, ArgoCD will detect the change and sync. You can speed this up by clicking the "Sync" button at the top.
Confirm the new pod appears:

```bash
kubectl get pods -n podinfo
```

```
NAME                       READY   STATUS    RESTARTS   AGE
podinfo-xxxxxxxxxx-aaaaa   1/1     Running   0          5m
podinfo-xxxxxxxxxx-bbbbb   1/1     Running   0          5m
podinfo-xxxxxxxxxx-ccccc   1/1     Running   0          10s
```

This is GitOps: Git is the source of truth, and the cluster automatically converges to match it.

---

## Summary

In this exercise, you:

- Created a STACKIT Hosted Git instance and enabled STACKIT Runners
- Migrated the training repository into Forgejo and triggered a CI workflow
- Installed ArgoCD and exposed its UI with a valid TLS certificate
- Configured ArgoCD to authenticate with your Forgejo repository
- Deployed a sample application using an ArgoCD `Application` manifest
- Updated the application by committing a change in Forgejo and watching ArgoCD reconcile it
