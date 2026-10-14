[English](06-lessons-learned.en.md) | [日本語](06-lessons-learned.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation.

# Lessons Learned and Next Steps

## Lessons from This Validation

1. **AI can handle not only implementation but also verification and fixes**
   - It carried out the whole sequence: splitting the Terraform code, version pinning, formatting, validation, plan review, apply, HTTP connectivity checks, and root cause analysis and fixes.

2. **Outbound traffic design is important in Private Subnets**
   - Making EC2 non-public alone does not make package installation at startup work. When NAT is not used, the VPC Endpoint, Route Table, Endpoint Policy, and Security Group egress must be consistent with each other.

3. **Checking that the ALB is reachable is not sufficient for connectivity verification**
   - The ALB can respond and still return 502. Checking the actual application response from the Target Group made it possible to detect the Nginx installation failure.

4. **Reviewing the plan and confirming that the state converges are effective**
   - The plan before apply was used to review the resources to be created or replaced, and after the fix we confirmed that `terraform plan` showed `No changes`.

## Next Validation Steps

### Phase 2: CI/CD

- Run `terraform fmt -check`, `terraform validate`, and `terraform plan` on Pull Requests.
- Save and display the plan results in a reviewable form.
- Make the execution conditions for apply and destroy clear.

### Phase 3: GitHub Actions OIDC

- Do not place long-lived Access Keys in CI/CD.
- Design the IAM Role and OIDC Trust Policy for GitHub Actions with least privilege.
- Restrict the target repository, branch, and Environment in the Trust Policy.

### Phase 4: Monitoring

- Monitor ALB HTTP codes, Target Group HealthyHostCount, and basic EC2 metrics.
- Consider alarms that can detect 502/5xx and Unhealthy Hosts.
- Manage the monitoring cost and notification paths with Terraform as well.

## Pre-publication Checklist

- [ ] Do not add `terraform.tfstate`, backups, or `.terraform/` to Git.
- [ ] Do not place credentials or real-environment-specific settings in `terraform.tfvars`.
- [ ] Do not include Access Keys, Secret Keys, AWS account IDs, real IPs, or resource IDs in documents, images, or logs.
- [ ] Do not include real-environment URLs that need not be public, such as the ALB URL, in documents.
- [ ] Review `terraform plan` before running `terraform apply`.
