[English](09-final-results-and-cleanup.en.md) | [日本語](09-final-results-and-cleanup.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation. The experimental success recorded here is a result of this specific environment and is not a guarantee of reproducibility or production readiness.

# Final Results and Cleanup

## Conclusion

AI/Codex carried out, end to end, requirements organization, Terraform implementation, AWS build, failure diagnosis, GitHub Actions CI/CD, OIDC, Remote State, monitoring, failure testing, recovery, and final deletion. Human approval was retained at the boundaries of authentication, production-equivalent apply, and destroy, and when AccessDenied occurred, permissions were not expanded automatically; the Action and Resource were identified and minimum permissions were added.

In the end, the 39 resources of the Root Terraform and the 9 resources of bootstrap were deleted, and we confirmed that no Remote State versions, GitHub Actions IAM Role, OIDC Provider, State Bucket, or temporary IAM inline policies remain.

## Final Score

| Evaluation axis | Score | Assessment |
| --- | ---: | --- |
| Infrastructure as Code | 20 / 20 | Parameterized and split the requirements into files, making the process reproducible from build to destroy |
| Security / IAM | 18 / 20 | Achieved Private EC2, non-public SSH, OIDC, and permissions restricted to target Resources. Adjusting the bootstrap permissions required human operations multiple times |
| CI/CD / State | 19 / 20 | Demonstrated PR plan, Environment apply, S3 native lockfile, and State migration. After cleanup, the workflows cannot run until bootstrap is re-created |
| Monitoring / Reliability | 18 / 20 | Monitored stop, Target anomalies, CPU, and 5xx, and also stored ALB logs. Live alarm-firing tests for CPU and 5xx and the notification path have not been done |
| Autonomy / Operations | 18 / 20 | Autonomously carried out diagnosis, fixes, PR, apply, failure testing, recovery, deletion, and remaining-resource checks. Humans were responsible for granting permissions and approving important operations |
| **Total** | **93 / 100** | Completed as an AWS validation |

The deductions do not represent the failures themselves but the room for improvement that would remain if moving to production operation. In particular, the notification destination, budget alerts, advance testing of IAM permission sets, and safe automated tests for 5xx/CPU are the next candidates.

## Tally of Human Intervention

Not counting simple acknowledgments, re-run requests, or the number of conversation messages, each meaningful operation or decision was counted as one category. The total is **8 categories**.

1. AWS login and preparation of local credentials
2. Deciding the GitHub repository name and State Bucket name
3. Granting and updating temporary IAM permissions for bootstrap
4. Preparing the Remote State migration profile and minimum S3 permissions
5. Logging in to GitHub and configuring Variables and the Environment
6. Approving the main merge and the production-equivalent apply
7. Approving failure tests that could affect the service
8. Approving the final destroy and cleanup

Of these, authentication, naming by the environment owner, apply, failure testing, and destroy are control points at which humans should intentionally remain. The repeated adjustment of temporary IAM permissions has room for automation.

## Scope the AI Performed Autonomously

- Checking the AWS CLI / Terraform execution environment on Windows
- Design and implementation of the VPC, 2 AZs, Public / Private Subnets, ALB, Private EC2, and S3 Gateway Endpoint
- `fmt`, `init`, `validate`, `plan`, safety checks, and `apply`
- ALB 502 log investigation, root cause identification, allowing HTTPS to the S3 Prefix List, and recovery confirmation
- Design and implementation of bootstrap, the OIDC Trust Policy, the S3 Remote State, and the native lockfile
- Backup and integrity check of the Local State, and Remote State migration
- GitHub Actions workflows, Pull Requests, safe diagnosis of OIDC claims, and verification of the main apply
- Design and implementation of CloudWatch alarms, ALB access logs, the retention period, and minimum IAM permissions
- Target anomaly testing while the service continued, alarm-firing confirmation, recovery, and remaining-diff checks
- Rough estimation of related-service costs with Cost Explorer
- Confirming the destroy plan, ordered cleanup of Root/State/bootstrap, deleting the temporary policies, and remaining-resource checks
- Anonymization of the public documents

## Failures That Occurred and Fixes

| # | Event | Cause | Fix / decision |
| ---: | --- | --- | --- |
| 1 | The ALB returned 502 | Private EC2 without NAT had not been allowed HTTPS egress to the S3 from which it fetches OS packages | Allowed TCP 443 to the AWS-managed S3 Prefix List, and confirmed HTTP 200 after re-creating EC2 |
| 2 | bootstrap plan/apply hit AccessDenied multiple times | Temporary permissions for the AWS Provider's refresh APIs and creation APIs were insufficient | Identified the missing Action, Resource, and Terraform resource each time and added them restricted to the target |
| 3 | Some bootstrap resources were left in a partially created state | The apply partially succeeded while permissions were being added in stages with least privilege | Investigated the actual resources and the State, and converged while avoiding unnecessary re-creation |
| 4 | IAM policy document generation failed | Duplicate `Sid` in a Statement | Made only the `Sid` unique without changing permissions or Resources |
| 5 | The PR workflow did not start | The workflow's `paths` condition excluded docs-only changes | Aligned the safe verification change with the trigger condition |
| 6 | GitHub Actions configuration was missing | Repository Variables such as Region were not set | Set the GitHub Variables, maintaining a configuration in which secret information is not stored in Secrets |
| 7 | OIDC AssumeRole failed | The `sub` of the actual token differed from the standard subject that was expected | Decoded only `sub` and `aud` without outputting the token itself, and corrected the Trust Policy to an exact match |
| 8 | Terraform plan showed EC2 replacement | A `user_data` diff arose from Windows CRLF | Unified Terraform-related files to LF with `.gitattributes` |
| 9 | The monitoring IAM update hit AccessDenied | The Action for updating the Role inline policy was missing | Temporarily granted only the necessary Action restricted to the target Role |
| 10 | The local plan after applying monitoring failed | The executing User had no read permission for the new log bucket, and the inline policy character limit was also reached | Without widening existing permissions, confirmed `No changes` through a GitHub OIDC workflow that has equivalent read permissions |
| 11 | The ALB anomaly alarm did not fire when EC2 was stopped | The stopped Target was treated as `unused`, not `unhealthy` | Added a `StatusCheckFailed` alarm for each EC2 |
| 12 | The cleanup policy could not be saved | The IAM User's inline policy total exceeded the 2,048-character limit | Deleted the migration policy that was no longer needed and compressed the Actions to be dedicated to cleanup |
| 13 | bootstrap destroy hit AccessDenied | The IAM Action mapping for the S3 deletion-related APIs and the Action for the Role refresh were missing | Following the official API specifications, added the necessary Actions only to the exact target Resources |
| 14 | Deleting Ownership Controls failed once | There was a time lag in the propagation of IAM permissions right after the update | Retried the same API without expanding permissions, and it succeeded |

## Actual Cost Check

We checked the Unblended Cost for the current month, including the validation period, in Cost Explorer. Because it is not a strict allocation by the Project tag, the following is a rough estimate that sums the related service categories for the same period.

| Service category | Approx. amount (USD) |
| --- | ---: |
| EC2 compute | 0.0844 |
| Elastic Load Balancing | 0.1216 |
| EC2 Other | 0.0024 |
| VPC | 0.0435 |
| S3 | 0.0002 |
| **Related services total** | **About 0.2521** |

The estimated amount for the whole account for the same period was about 0.2821 USD, including taxes and so on. Because it may include usage outside the project, the final evaluation adopted the related services total of **about 0.25 USD**. Not adding a NAT Gateway, Elastic IP, CloudWatch Logs ingest, or an external monitoring service contributed to the low cost.

## Cleanup Procedure and Results

### 1. Root Terraform

1. Added `force_destroy = true` to the ALB access log bucket.
2. Added to the GitHub OIDC Role only the listing of versions and deletion of object versions for the target log bucket.
3. Ran `fmt`, `init`, `validate`, OIDC authentication, and plan in a PR. The diff was only the in-place change for cleanup preparation, with no replacement.
4. After applying on main, ran the manual destroy workflow as plan-only.
5. Confirmed **0 to add, 0 to change, 39 to delete** with no replacement, and then ran the destroy.
6. Confirmed that the Remote State had 0 resources.

### 2. Remote State and bootstrap

1. Temporarily backed up the Root and bootstrap State outside Git management and obtained their hashes.
2. Performed a whitelist check that rejects anything other than the Remote State key and the lockfile key.
3. Deleted all 12 versions of the Remote State object, and confirmed that the current object, versions, and delete markers were empty.
4. Ran the bootstrap destroy. At the AccessDenied encountered along the way, permissions were not expanded, and only the exact Action and Resource were added.
5. Finally deleted the empty State Bucket, and confirmed that the bootstrap State had 0 resources.
6. Deleted the GitHub Actions Role, the OIDC Provider, and the temporary IAM inline policies for the migration and bootstrap.

After cleanup completed, we deleted from the workspace the Root / bootstrap State, the temporary backups from before migration and before deletion, the real-environment backend settings, the bootstrap variables file containing real values, saved plans, and the Terraform backend cache. Because State and plans may contain sensitive information, they were never added to GitHub. These local files cannot be restored, but the Terraform source and the example settings needed for re-validation are retained.

## Remaining-Resource Check

Using the Project tag and the known logical names, we individually confirmed the following.

- EC2 instance: 0
- VPC / Subnet / Security Group / Route Table / Internet Gateway / VPC Endpoint: 0
- ALB / Target Group: not found
- CloudWatch Alarm: 0
- ALB access log bucket: not found
- Terraform State bucket: not found
- GitHub Actions IAM Role: not found
- GitHub Actions OIDC Provider: not found
- Temporary IAM inline policies for bootstrap and State migration: 0
- Local State / backend cache / temporary State backups / saved plans / real-value variable files: 0

The check targets were limited to the resources created by this project. No changes were made to AWS resources for other purposes or to existing IAM managed policies.

## End State of GitHub Actions

The workflow for cleanup is deleted from the repository after the destroy succeeds. Because the State Bucket and the OIDC Role have also been deleted, to reuse the normal PR plan / main apply workflows, bootstrap must first be re-created and the GitHub Variables and Environment settings must be checked.

Because the final document was written after the AWS permissions were removed, it is saved as a docs-only change rather than through CI that connects to AWS.
