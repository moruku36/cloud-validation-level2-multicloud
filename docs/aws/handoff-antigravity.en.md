[English](handoff-antigravity.en.md) | [日本語](handoff-antigravity.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation. This is a historical handoff document: the commands, steps, and prompt quoted below are source text translated as a record, are not current instructions, and must not be executed from here. The AWS validation environment described has since been deleted (see [Final Results and Cleanup](09-final-results-and-cleanup.en.md)), so states described as "current" below reflect the time this handoff was written.

# Handoff for Antigravity

## Purpose of This Validation

This repository is for validating how safely AI agents can be entrusted with AWS infrastructure implementation and Terraform operations. The goal is not merely to create resources but to make the following sequence reproducible while leaving the final decisions to humans.

1. Build a minimal AWS web foundation with Terraform.
2. Safely design external exposure, communication paths, and State management.
3. Run Terraform from GitHub Actions without long-lived Access Keys.
4. Separate execution permissions between Pull Requests and main merges.
5. Leave changes, failures, and decisions as publishable documents.

Please have Antigravity first read this document, `README.md`, `docs/aws/01-scenario.md` through `docs/aws/07-cicd-oidc-remote-state.md`, `.github/workflows/`, and `aws/bootstrap/`. Real-environment identifiers, credentials, and State do not exist in the repository.

## Current Achievements

The following have been confirmed in the real environment.

- Built with Terraform, in the AWS Tokyo region, a VPC, two Public/Private Subnets each, an Internet Gateway, an Application Load Balancer, and two Private EC2 instances.
- The EC2 instances have no Public IP, and SSH is not exposed to the internet. The only traffic allowed from outside is HTTP to the ALB.
- Only HTTP 80 is allowed from the ALB to the EC2 instances. The EC2 instances perform only the necessary HTTPS communication via the S3 Gateway Endpoint, and Nginx is running on Amazon Linux.
- HTTP 200 through the ALB has been confirmed.
- The Terraform State has been migrated to the S3 backend. S3 Versioning, SSE-S3, Public Access Block, and TLS enforcement are configured, and the S3 native lockfile is used with `use_lockfile = true` instead of DynamoDB.
- bootstrap manages the State Bucket, the GitHub OIDC Provider, and the IAM Role for GitHub Actions together with its inline policy.
- In GitHub Actions, PRs from the same repository run fmt / validate / OIDC / Remote State plan. Jobs that use AWS permissions are not run for fork-originated PRs.
- On a main merge, OIDC authentication, plan, and apply are run using the `terraform-production` Environment.
- Both the PR workflow and the apply workflow after the main merge succeeded in OIDC authentication, the final plan was `No changes`, and the apply succeeded with 0 added, 0 changed, 0 deleted.

## Current Design

### Terraform Configuration

- Root: Application foundation. Separated into `provider.tf`, `variables.tf`, `main.tf`, and `outputs.tf`.
- `bootstrap/`: Initial configuration of the Remote State and GitHub OIDC/IAM. Uses a State separate from the Root.
- `backend.tf`: Not under Git management. Contains only the S3 backend's `use_lockfile = true`.
- `backend.tf.example`: Template for the backend settings.
- `terraform.tfvars` and bootstrap's production tfvars: Not under Git management. No credentials are written.

### GitHub Actions

- `.github/workflows/terraform-pr.yml`
  - Runs fmt and validate on all PRs.
  - Only PRs originating from the same repository obtain `id-token: write`, authenticate with OIDC, and run a read-only plan using the Remote State.
  - There is no apply in the PR workflow.
- `.github/workflows/terraform-apply.yml`
  - Runs on a push to main that includes changes to the target files.
  - Specifies the `terraform-production` Environment.
  - After OIDC authentication, saves the plan and applies that same plan.

### AWS Authentication and State

- No AWS Access Key / Secret Access Key is placed in GitHub Secrets.
- Only the values corresponding to the region, State Bucket, State Key, and Role ARN have been set in the GitHub Repository Variables. The values themselves must not be written in logs, documents, or code.
- The OIDC Provider's Audience is restricted to `sts.amazonaws.com`.
- The Role Trust Policy allows, in a restricted manner, the same-repository PR subject and the `terraform-production` Environment subject.
- On this GitHub account, a custom format that includes the owner/repository ID is issued as the OIDC subject. The actual subject string is passed through the bootstrap tfvars that is outside Git management, and only the general form is described in public documents.
- The State Role's permissions are limited to the necessary operations on the State Object and the `.tflock` Object. Because of SSE-S3, KMS permissions are not needed.

## Important Findings During Implementation

1. If HTTPS communication from the Private EC2 to S3 is not allowed in the Security Group, package retrieval fails and the ALB returns 502. TCP 443 to the AWS-managed S3 Prefix List was allowed, and HTTP 200 was confirmed after re-creating EC2.
2. In line with HashiCorp's current S3 backend specification, `use_lockfile = true` was adopted instead of DynamoDB locking.
3. GitHub's OIDC subject was not the standard `repo:<owner>/<repository>:...` but a custom format that includes the repository ID. We confirmed the one for PRs and the one for the Environment with short-lived diagnostic jobs, and matched the Trust Policy with the minimum scope. The diagnostic jobs have been deleted.
4. Even just refreshing the bootstrap State, the plan stops if the S3/IAM read permissions are insufficient. We adopted an operating policy in which the temporary bootstrap policy is used only when needed, is restricted to existing resources, and permissions are not automatically expanded when they are insufficient.

## Checks Before Antigravity Starts Work

Please start with checks that make no changes, in the following order.

```powershell
git status
git switch main
git pull --ff-only origin main
terraform fmt -check -recursive
terraform validate
terraform plan
```

Notes:

- Do not output, save, or commit AWS credentials, State, real backend values, real resource IDs, the ALB URL, the Account ID, or Role ARNs.
- Before `terraform apply`, a GitHub main merge, IAM changes, State migration, or destroy, always review the plan or diff and obtain explicit human approval.
- If AccessDenied occurs, do not add permissions automatically. Identify the Action, Resource, and target Terraform resource and stop.
- Do not run `bootstrap/` for ordinary Root changes. Handle it with a least-privilege temporary Identity only when the State backend, OIDC, or Role policy needs to be changed.
- Do not reuse broad application permissions or temporary administrative permissions for State or bootstrap operations.
- `terraform destroy` deletes the validation environment, so run it only when the user explicitly requests it.

## Remaining Validations

The following items are not yet performed or are candidates for deeper investigation. It is safe to proceed from the top.

1. **CI/CD apply involving an actual change**
   - The current apply workflow has been confirmed up to a successful apply with `No changes`.
   - Next, propose a low-risk and reversible Terraform change in a PR, and verify in sequence the PR plan diff, review, main merge, apply, and the post-apply plan.
   - Have a human approve the change content and the expected diff first. Avoid changes involving the replacement of the ALB/EC2, deletion of the network, or widening of the exposure scope.
2. **GitHub operational guardrails**
   - Check, and configure as needed, Branch Protection for main, required PR reviews, and required status checks.
   - Verify the required reviewers and deployment protection rules of the `terraform-production` Environment against the required operational level.
   - Because a PR from the same repository can obtain the OIDC Role, review and Branch Protection are especially important for PRs that include workflow changes.
3. **Continuous review of least-privilege IAM**
   - The GitHub Actions Role's EC2/ELB management permissions include Actions for which Resource restriction is difficult under the AWS API specifications. Evaluate narrowing candidates based on the Actions actually used, such as from CloudTrail.
   - If the temporary IAM inline policy used for bootstrap remains, delete it with a dedicated cleanup procedure after confirming it is no longer needed. Do not add deletion permissions to the everyday policy.
4. **Monitoring and operability**
   - Design and add CloudWatch Alarms such as ALB HTTP 5xx, Target Group UnHealthyHostCount, and EC2 StatusCheckFailed.
   - Decide the notification destination, log retention period, and cost ceiling with a human before implementing.
5. **Failure and safety tests**
   - Verify, in a non-destructive way, that fork PRs cannot use AWS permissions, that PRs are not applied, and that the system waits or fails safely on a State lock conflict.
   - Periodically verify the S3 State Bucket's public access block, TLS enforcement, versioning, and lockfile permissions.
6. **Termination and cleanup verification**
   - Only at the end of validation, run destroy after reviewing the destroy plan with a human, and separately decide how to handle the S3 State and Versioned Objects and the bootstrap resources.

## Starting Prompt to Give to Antigravity

This can be handed over as is. (This is the quoted source text from the original handoff; it is a historical record and is not a current instruction.)

```text
This repository is a validation environment for AWS + Terraform + GitHub Actions OIDC.
First read README.md, docs/aws/handoff-antigravity.md, docs/aws/07-cicd-oidc-remote-state.md, .github/workflows/, and aws/bootstrap/, and understand the current design and safety constraints.

Do not output, save, or commit real-environment credentials, State, real backend values, AWS Account ID, Role ARNs, resource IDs, or the ALB URL.
At the start of work, confirm there are no changes with git status, updating main, terraform fmt -check, validate, and plan.
Before apply, IAM changes, main merge, State operations, and destroy, review the plan, and on unexpected diffs or AccessDenied, do not expand permissions automatically; stop and report the cause.

The next candidate is to take a low-risk and reversible Terraform change from a PR through to main and confirm the actual change through CI/CD apply. Before implementing, present the change content, the expected plan, and the scope of impact.
```
