[English](03-implementation.en.md) | [日本語](03-implementation.md)

> This is an English translation added on 2026-10-14. It preserves the dates, data and caveats of the source record (Japanese original). No new experiment was run.

# Terraform Implementation

## Resources Planned for root Management

- Custom mode VPC / Regional Subnet
- Cloud Router / Cloud NAT
- Ingress Firewall that allows only Backend TCP 80 from Health Check / GFE
- Egress Firewall that allows only TCP 80/443 from VMs, plus an Egress deny for everything else
- Zero-permission VM runtime Service Account
- Instance Template / Regional MIG (2 Zones, 2 instances, autohealing)
- Global IPv4 / Backend Service / URL Map / Target HTTP Proxy / Global Forwarding Rule
- Cloud Monitoring / Cloud Logging configuration for the later phase

## Resources Planned for bootstrap Management

- Dedicated GCS State Bucket
- Service Accounts for PR and Apply
- Workload Identity Pool / GitHub OIDC Provider
- `roles/iam.workloadIdentityUser` binding for the exact subject
- State Object IAM
- Terraform-dedicated custom role and Project IAM binding

## Quality and Safety Measures

- Terraform `>= 1.9.0, < 2.0.0`
- Google Provider pinned to `7.43.0`. The verified 7.x line was adopted rather than the 8.x released just before
- `.gitattributes` fixes Terraform, YAML, and Markdown to LF
- State, plan, tfvars, backup, and key are covered by `.gitignore`
- Real Project identifiers are injected from required variables or CI Secrets
- Instance Template uses `create_before_destroy`, and the MIG uses rolling replace, prioritizing service continuity
