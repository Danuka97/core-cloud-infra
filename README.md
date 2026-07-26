# core-cloud-infra

Terraform-managed GCP infrastructure for multiple applications, each with isolated
`dev` / `uat` / `prod` environments, deployed via Cloud Build using a PR-plan /
merge-apply GitOps flow.

## Core concepts

**Hub and spoke.** One admin/bootstrap GCP project (the hub) owns shared
concerns: Terraform state storage, the GitHub connection, CI triggers, and two
secrets (`org-id`, `billing-account-id`). Every application environment (a
spoke) is its own GCP project, created by Terraform itself, so `core-app-dev`
and `core-app-prod` can never accidentally share resources or IAM.

**Secrets never live in tracked files.** `org-id` and `billing-account-id` are
written into Secret Manager once (from `bootstrap/terraform.tfvars`, which is
gitignored) and every other module reads them back via a
`google_secret_manager_secret_version` data source at plan/apply time. No
`.tf` or `.tfvars` file anywhere else in the repo ever contains them.

**Thin environment directories, shared modules.** Every file under
`applications/<app>/<env>/` is a few lines: a `provider` block and one
`module "env"` call. All actual resource logic (project creation, VPC/subnet)
lives in `modules/`, called with different variables per app/environment.
Environments should never define resources directly — if you're tempted to,
the change probably belongs in a module instead.

**State isolation per app and environment.** Each `applications/<app>/<env>/`
has its own `backend.tf` pointing at a unique prefix
(`terraform/state/<app>/<env>`) in the shared state bucket, so a `terraform
apply` in one environment can never read or corrupt another's state.

## Layout

```
bootstrap/                  # one-time hub setup: state bucket, GitHub connection,
                             # CI triggers, IAM, secrets seeding
modules/
  project_factory/          # creates one GCP project (an environment's spoke)
  vpc_network/               # creates a VPC + private subnet in a project
  environment/               # composes project_factory + vpc_network
applications/
  <app-name>/
    dev/   uat/   prod/     # thin per-environment directories, one per app
scaffold_app.sh             # generates a new app's dev/uat/prod directories
cloudbuild.yaml             # CI: detects changed dirs, runs plan or apply
```

## Adding a new application

```
./scaffold_app.sh <app-name>
```

This generates `applications/<app-name>/{dev,uat,prod}/` with `backend.tf`,
`versions.tf`, `main.tf`, `variables.tf`, and `terraform.tfvars` for each
environment, including pre-assigned non-overlapping subnet CIDRs
(`10.10.x` dev, `10.20.x` uat, `10.30.x` prod). Review the generated
`terraform.tfvars` files, commit, and open a PR — do not hand-write new
environment directories from scratch.

## How changes get deployed

1. **Open a PR.** The `plan-infra-prs` Cloud Build trigger diffs your branch
   against the PR base, works out which `applications/<app>/<env>` directories
   are affected, and runs `terraform init` in each. A change to a file under
   `modules/` is treated as affecting every application/environment, since a
   shared module change can silently change any of them.
2. **Security scan.** `checkov` (config: `.checkov.yaml`) scans each affected
   directory's Terraform source for policy violations (open firewalls,
   missing encryption, over-broad IAM, etc.) before anything is planned, so
   an insecure change fails fast without needing GCP credentials.
3. **`terraform plan`** runs and its output shows up in the Cloud Build PR
   check — review it there.
4. **Merge to `main`.** The `apply-infra-push-main` trigger runs the same
   directory-detection, security-scan, and plan steps, then applies the
   exact plan that was already produced (not a fresh plan) via the saved
   `tfplan` artifact.

On push (not PR), the changed-directory detection diffs against the last
commit this pipeline actually applied — tracked via a marker object
(`ci/last-applied-commit.txt`) in the state bucket — rather than just the
immediate parent commit. This matters because merging two PRs to `main` in
quick succession can mean GitHub only fires one push build for the later
merge; diffing against the immediate parent alone would silently miss
whatever the earlier, un-built merge introduced.

Only directories with actual changes are touched — merging a change to
`applications/core-app/prod/terraform.tfvars` will not re-plan `task_manager`.

## Local usage (rare — CI is the normal path)

```
cd applications/<app>/<env>
terraform init
terraform plan
```

You'll need `gcloud auth application-default login` against an account with
access to the relevant GCP projects. Applying locally bypasses the PR review
step, so prefer letting CI apply on merge.

## Bootstrap (one-time, per new hub project)

`bootstrap/` is applied manually, once, to stand up the hub project itself —
it can't run through the CI pipeline it creates, since that pipeline doesn't
exist yet.

```
cd bootstrap
terraform init
terraform apply
```

`bootstrap/terraform.tfvars` holds real secrets (org ID, billing account ID,
GitHub app installation ID) and is gitignored — never commit it. After
`apply`, those values live in Secret Manager and nothing downstream needs the
tfvars file again.
