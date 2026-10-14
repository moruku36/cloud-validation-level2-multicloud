[English](04-troubleshooting.en.md) | [日本語](04-troubleshooting.md)

> This is an English translation added on 2026-10-14. It preserves the dates, data and caveats of the source record (Japanese original). No new experiment was run.

# Troubleshooting

## 2026-09-07: Could not launch gcloud, located outside the sandbox, directly

- Symptom: Windows Access denied during the first CLI check
- Cause: The Google Cloud SDK was installed in a user directory outside the working area
- Fix: Switched to an approved execution with the read-only purpose stated explicitly
- Result: Confirmed gcloud, authentication, Project, and Region while keeping them anonymized
- Classification: AI autonomous diagnosis and fix. No IAM change

## 2026-09-07: PowerShell variable not expanded into Terraform `-chdir`

- Symptom: `chdir $repo: The system cannot find the file specified`
- Cause: The external command argument `-chdir=$repo` was not expanded as expected
- Fix: Passed `"-chdir=$repo"` explicitly as a single argument
- Result: init and validate succeeded for both root and bootstrap
- Classification: AI autonomous diagnosis and fix. No cloud change

## 2026-09-07: Application Default Credentials not configured

- Symptom: Could not obtain an ADC access token
- Cause: The gcloud CLI user login and the ADC used by Terraform are managed separately
- Response: Without saving a new ADC file, passed a short-lived token issued from the existing gcloud login only to the plan process
- Result: read-only plan succeeded for root / bootstrap. ADC for normal local operation remains unconfigured

## 2026-09-07: bootstrap plan argument parsing error

- Symptom: `Too many command line arguments` occurred twice
- Cause: Interpretation of arguments passed directly from PowerShell to Terraform broke down when running bootstrap
- Fix: Put the arguments in an array and passed them to Terraform with splatting
- Result: Reached evaluation of the Terraform configuration
- Classification: AI autonomous diagnosis and fix. No cloud change

## 2026-09-07: set/list type mismatch in custom role permissions

- Symptom: `Invalid value for "seqs" parameter: all arguments must be lists or tuples`
- Cause: `permissions`, which is a set type in the Provider schema, was passed directly to `concat`
- Fix: Made only the type explicit with `tolist()`. Permission contents and scope unchanged
- Result: bootstrap validate and plan succeeded
- Classification: AI autonomous diagnosis and fix. No IAM addition or cloud change

## 2026-09-07: CI plan treated the 18 existing resources as new

- Symptom: WIF authentication and `terraform init` succeeded, but the PR plan showed `18 to add`
- Cause: Even `backend.tf`, which does not contain the real Bucket name, was covered by `.gitignore`, so the GCS backend declaration did not exist after CI checkout
- Fix: Tracked a `backend.tf` containing only an empty `backend "gcs" {}`; the Bucket name and prefix continue to be injected from the Workflow
- Safety judgment: The PR Workflow has no apply, and no Cloud Resource change occurred
- Classification: AI autonomous diagnosis and fix. No IAM expansion

## 2026-09-07: PR OIDC subject did not match the exact IAM member

- Symptom: After WIF setup, `iam.serviceAccounts.getAccessToken` was denied during GCS backend initialization
- Investigation: Temporarily output only the GitHub OIDC `sub` and `aud`, without showing the token body, header, or signature
- Cause: The actual `sub` was in a format containing the stable numeric IDs of the owner/repository, which did not match Terraform's name-only subject
- Fix: Changed only the PR subject to `repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:pull_request`
- Safety judgment: Kept the exact subject, attribute condition, audience, Apply subject, and existing Roles. No permission added
- Application: Replaced only 1 PR IAM member with create-before-destroy, and confirmed bootstrap plan No changes
- Result: PR WIF authentication and GCS Remote State connection succeeded, and the root plan was No changes
- Follow-up: Removed the temporary debug step limited to `sub` / `aud`
- Classification: AI autonomous diagnosis and fix. The human approved only the binding replacement

## 2026-09-07: Apply Environment OIDC subject did not match the exact IAM member

- Symptom: The Terraform subject for Apply contained only the repository name and did not match GitHub's Environment token
- Investigation: Confirmed only `sub` and `aud` in a temporary job with normal apply stopped. Token and credentials were not shown
- Cause: The Environment token's `sub` also contains the stable numeric IDs of the owner/repository
- Fix: Changed only the Apply subject to `repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:environment:terraform-production`
- Safety judgment: Kept the exact constraint, attribute condition, audience, PR binding, and Service Account permissions
- Application: Replaced 1 Apply IAM member with create-before-destroy
- Result: bootstrap/root plan No changes. main WIF authentication, GCS backend, No changes plan, and a 0-resource apply succeeded
- Classification: AI performed the investigation, fix, and verification. The human approved the binding replacement

## 2026-09-07: API validation error in Monitoring Alert Policy

- Symptom: In the main apply, after 5 of 7 resources were created, creation of the Backend Health and HTTP 5xx Alert Policies failed with HTTP 400
- Cause 1: A duration of 0 seconds was specified on a condition that sets `evaluation_missing_data`
- Cause 2: The unsupported `COMPARISON_GE` was specified in a metric-threshold condition
- Fix 1: Changed the Backend Health duration to 60 seconds
- Fix 2: Expressed "5 or more" equivalently as `COMPARISON_GT` with threshold 4
- Safety check: The corrected plan covered only the 2 Alert Policies not yet created. No change or deletion of the existing resources or the 5 partially created ones
- IAM: An API input constraint, not a permission shortage. No Role or permission added
- Classification: AI autonomous diagnosis and fix

## 2026-09-07: Resource mapping of the Health Check log-based metric

- Symptom: The Logging metric existed, but the Alert filter's `resource.type="gce_instance_group"` caused HTTP 400 because it is not a known descriptor
- Cause: Cloud Logging's `gce_instance_group` is mapped to `global` when ingested into Cloud Monitoring as a log-based metric
- Confirmation: Read-only confirmation that the metric exists via the Logging API, and that the metric descriptor's resource type is `global` via the Monitoring API
- Fix: Changed only the Alert filter to `resource.type="global"`. The Logging-side filter remains limited to the target MIG
- IAM: No addition or change
- Classification: AI autonomous diagnosis and fix

## 2026-09-07: Detection delay in the failure test

- Symptom: Even after changing the MIG target size to 1, `instance_group/size` immediately afterward remained 2 and no Incident was shown
- Cause: Completion of MIG scale-down, collection of the managed metric, and the 120-second condition evaluation are each asynchronous
- Isolation: Separately checked the Compute API target size, the managed instance count, the Monitoring time series, and Alert Policy validity
- Result: After the time series continued at 1, the Incident became Open, and after the 2 instances were restored it transitioned to Closed
- Fix: No Terraform change. Set an upper limit on observation and waited while monitoring the service with HTTP 200
- Classification: AI autonomous diagnosis and recovery
