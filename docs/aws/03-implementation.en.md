[English](03-implementation.en.md) | [日本語](03-implementation.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation.

# Implementation

## Terraform Configuration

| File | Role |
| --- | --- |
| `provider.tf` | Terraform / AWS Provider version pinning, region, common tags |
| `variables.tf` | Inputs such as region, CIDRs, AZs, and instance type |
| `main.tf` | VPC, Subnets, Route Tables, Security Groups, S3 Endpoint, ALB, EC2 |
| `outputs.tf` | Outputs of the ALB URL, the list of EC2 IDs, and the VPC ID |
| `terraform.tfvars.example` | Example override settings that are safe to publish |

Terraform is constrained to `>= 1.8.0, < 2.0.0`, and the AWS Provider is pinned to an exact version.

## Implementation Decisions

### Installing Nginx on Private EC2

Because no NAT Gateway is placed for the Private EC2 instances, packages are not retrieved over the general internet. The S3 Gateway Endpoint is associated with the Private Route Table, and an Endpoint Policy permits only read access to the Amazon Linux 2023 repository bucket.

In addition, the EC2 Security Group's outbound traffic is limited to TCP 443 to the AWS-managed S3 Prefix List.

### Security Groups

- ALB: Receives TCP 80 from the Internet and sends TCP 80 to the EC2 Security Group.
- EC2: Receives TCP 80 from the ALB Security Group. For outbound traffic, only TCP 443 to the S3 Prefix List is allowed.

### Nginx Configuration

Nginx is installed and started through the EC2 `user_data`, and a simple HTML page that includes the host name is placed. When `user_data` related to the Nginx installation changes, the EC2 instance is replaced so that initialization is reliably redone.

## Execution Flow

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
# Review the contents
terraform apply tfplan
terraform output -raw alb_url
```

Credentials are passed through AWS SSO, a profile, or temporary environment variables of the execution environment, and are not stored in the Terraform configuration or in Git.
