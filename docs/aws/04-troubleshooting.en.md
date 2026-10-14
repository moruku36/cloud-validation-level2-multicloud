[English](04-troubleshooting.en.md) | [日本語](04-troubleshooting.md)

> **Note:** This is an English translation added on 2026-10-14. It preserves the dates, data, and caveats of the original Japanese record. No new experiment was run for this translation.

# Troubleshooting

## The ALB Returns 502 Bad Gateway

### Symptom

The ALB's HTTP URL was reachable, but the response was `502 Bad Gateway`.

### Cause

In a configuration that places EC2 in Private Subnets and does not use a NAT Gateway, the path for retrieving the packages needed to install Nginx must be defined explicitly. The S3 Gateway Endpoint had been created, but the EC2 Security Group's outbound traffic was entirely closed, so the instances could not make HTTPS connections to the Amazon Linux repositories.

As a result, the Nginx installation could not complete, and the instances could not return a healthy HTTP response to the ALB Target Group.

### Fix

1. Retrieved the AWS-managed S3 Prefix List with a data source.
2. Added an outbound rule for TCP 443 to that Prefix List to the EC2 Security Group.
3. Replaced the EC2 instances so that `user_data` would run again.
4. Accessed the ALB URL again and confirmed HTTP 200.

### Prevention

In a design that installs packages at startup in a Private Subnet, design and verify the path to the package source together with the Security Group's outbound traffic. When NAT is not used, explicitly define the VPC Endpoints to the required AWS services and the minimum necessary rules.
