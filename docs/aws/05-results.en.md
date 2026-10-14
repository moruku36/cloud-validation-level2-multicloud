[English](05-results.en.md) | [日本語](05-results.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation.

# Validation Results

## Results

| Item | Result |
| --- | --- |
| Terraform formatting | `terraform fmt -check` succeeded |
| Terraform validation | `terraform validate` succeeded |
| Initial plan | Applied after reviewing the plan to add the required resources |
| Web connectivity | Confirmed HTTP 200 for the Nginx page through the ALB |
| Final plan | `No changes` |
| Deletion | All Terraform-managed resources can be deleted with `terraform destroy` |

## Resources Created

- VPC and Internet Gateway
- Two Public Subnets, two Private Subnets, and Route Tables with associations
- S3 Gateway Endpoint
- ALB, Listener, and Target Group
- Two Security Groups with minimal traffic rules
- Two Private EC2 instances and their Target Group registration

## Security Checks

- No Public IP is assigned to the EC2 instances.
- SSH from the internet to the EC2 instances is not allowed.
- HTTP exposure is limited to TCP 80 on the ALB.
- HTTP to the EC2 instances uses the ALB Security Group as its source.
- Package retrieval from the EC2 instances is limited to TCP 443 to the S3 Prefix List.

This document does not include real-environment URLs, IP addresses, AWS account IDs, access keys, or resource IDs.
