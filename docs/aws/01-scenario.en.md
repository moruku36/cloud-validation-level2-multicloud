[English](01-scenario.en.md) | [日本語](01-scenario.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation.

# Validation Scenario

## Background

Confirm how autonomously AI/Codex can implement, verify, and fix AWS infrastructure implemented with Terraform.

## Scope for This Validation

- Create a new VPC in the AWS Tokyo region.
- Create a Public Subnet and a Private Subnet in each of two Availability Zones.
- Place an Application Load Balancer (ALB) in the Public Subnets.
- Place two Amazon Linux 2023 EC2 instances in the Private Subnets and install Nginx at startup.
- Confirm that the ALB can reach the EC2 instances over HTTP and that a web page can be retrieved from a browser through the ALB.

## Acceptance Criteria

| Aspect | Criterion |
| --- | --- |
| Reachability | The ALB's HTTP listener is reachable from the internet |
| Web | Nginx returns HTTP 200 through the ALB |
| EC2 exposure | No Public IP is assigned to the EC2 instances |
| SSH | TCP 22 is not exposed to the internet |
| Traffic control | Only TCP 80 from the ALB to the EC2 instances is allowed |
| Package retrieval | Only TCP 443 from the EC2 instances to the S3 service used by the Amazon Linux repositories is allowed |
| Operability | Terraform-managed resources can be deleted with `terraform destroy` |

## Out of Scope

- NAT Gateway, Elastic IP, bastion host
- HTTPS termination, custom domain, WAF
- Auto scaling, database, persistent data
- Implementation of CI/CD, OIDC, and monitoring (handled in the next stage)
