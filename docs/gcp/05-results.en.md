[English](05-results.en.md) | [日本語](05-results.md)

> This is an English translation added on 2026-10-14. It preserves the dates, data and caveats of the source record (Japanese original). No new experiment was run.

# Execution Results

## 2026-09-07 Initial Review

| Item | Anonymized result |
|---|---|
| gcloud | 583.0.0 |
| Terraform | 1.9.8 |
| gcloud Identity | 2 registered, with an active Identity |
| Selected Project | Configured, ACTIVE, Billing enabled |
| Japan Regions | Tokyo / Osaka both UP, 3 Zones UP each |
| Existing boundaries | Compute 0, Storage Bucket 0, WIF Pool 0. 1 default VPC and 2 existing Service Accounts recorded as protected targets |
| API | Required APIs including STS already enabled |
| Terraform | fmt, init, validate succeeded for both root / bootstrap |
| root plan | 17 create, 0 change, 0 destroy. No change to existing Resources |
| bootstrap plan | 13 create, 0 change, 0 destroy. Dedicated to State/WIF/IAM |
| root apply | 17 added, 0 changed, 0 destroyed. 2 VMs RUNNING, 2 Backends HEALTHY, HTTP 200 |
| bootstrap apply | 13 added, 0 changed, 0 destroyed. Created State Bucket, WIF, PR/Apply Identity, and least-privilege Roles |
| Remote State | Migrated to GCS. backup SHA-256 matched, lineage matched, 17 resources, No changes after migration |
| Apply SA binding | Added only 1 `serviceAccountUser` for the VM runtime Identity |

## Comparison Data

Update only with counts confirmed from the execution records, without guessing.

| Metric | Current value |
|---|---:|
| Attempts until root validate succeeded | 1 |
| Attempts until bootstrap validate succeeded | 1 |
| Attempts until root safe plan succeeded | 1 |
| Attempts until bootstrap safe plan succeeded | 4 (CLI parsing failure 2, configuration type error 1, success 1) |
| Attempts until apply succeeded | Initial root 1, initial bootstrap 1, 1 repair for each WIF binding, Monitoring 4 attempts, cleanup root/bootstrap 1 each |
| Major errors | 10 events (number of error headings in troubleshooting. The Monitoring API event includes 2 causes) |
| AI autonomous fixes | 8 (excluding the 2 that needed human approval for WIF binding replacement) |
| Human interventions | 4 (initial GCP write approval, PR/Apply binding replacement approvals, GitHub identity verification) |
| IAM approvals | 3 (initial bootstrap, PR binding replacement, Apply binding replacement. No permanent Credentials) |
| GitHub Actions failures | 4 runs (workflow run records from the GitHub API. Rerun attempts are not counted separately) |
| Unintended real-environment drift | 0 |
| CI plan inconsistencies | 1 (18 adds due to the missing backend declaration; avoided without applying) |
| Unexpected destroy / replace | 0 |
| No changes confirmations | 13 (3 initial, 5 WIF, 3 Monitoring, 2 before cleanup) |

Because ADC was not configured, plan/apply was performed using a short-lived token from the existing gcloud login. The token was used only via an environment variable and was not saved to logs, files, or GitHub. The tallies are limited to what could be confirmed from command records, troubleshooting headings, and the GitHub API run list.

## GitHub OIDC / Apply Workflow Results

- WIF authentication succeeded for both PR and Apply using exact subjects containing the stable GitHub owner/repository IDs
- Apply is run from the `terraform-production` Environment, restricted to main
- No long-lived Credentials, Service Account Keys, or added permissions
- GCS Remote State initialization succeeded
- root plan was No changes
- The saved plan apply was `0 added / 0 changed / 0 destroyed`
- The GCS backend completed with its native locking kept enabled
- The temporary OIDC claim check job has been deleted

## Monitoring Results

- Terraform manages 1 Uptime Check, 5 Alert Policies, and 1 Health Check log-based metric
- Existing Load Balancer access logs and Health Check logs are stored in standard Cloud Logging
- The PR plan had no change or replacement of existing Web resources
- The main apply succeeded after fixing the API input constraints in two stages. Only 1 final addition
- In the failure test, HTTP 200 continued even when the MIG was temporarily shrunk from 2 instances to 1
- Confirmed the capacity-drop metric, Incident Open (Fired), recovery to 2 Healthy instances, and Incident Closed
- The root plan after recovery was No changes
- No IAM addition, long-lived Credentials, or Service Account Keys for Monitoring

## Cleanup Results

- Before cleanup: root State 25 items, bootstrap State 13 items, both plans No changes
- Backup: saved the GCS root State and bootstrap Local State outside Git management and confirmed SHA-256
- root destroy plan: 0 add, 0 change, 25 destroy, all delete-only
- After root destroy: State 0. Managed Compute / Network / Load Balancer / Monitoring / Logging / VM runtime SA at 0 active
- bootstrap destroy plan: 0 add, 0 change, 13 destroy, all delete-only
- After bootstrap destroy: State Bucket / WIF Pool and Provider / PR and Apply SAs / custom role / IAM bindings at 0 active
- Protected targets: confirmed that 1 existing default network and 2 existing Service Accounts remain
- Project deletion, Billing changes, IAM expansion, and Service Account Key creation were not performed
- Because root State 0 was confirmed before deleting the Remote State Bucket, the correct order of not re-running the root plan after deletion was maintained
- GitHub: after changing to `GCP_ENVIRONMENT_ACTIVE=false`, PR static checks succeeded and the cloud plan was Skipped before authentication. The entire job of the main Apply workflow was also Skipped
