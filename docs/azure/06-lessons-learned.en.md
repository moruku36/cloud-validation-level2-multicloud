[English](06-lessons-learned.en.md) | [日本語](06-lessons-learned.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation. The results describe this single experiment only and are not a guarantee of reproducibility or production readiness.

# Lessons Learned and AWS Comparison

## Design and Operations Comparison with the AWS Edition

| Aspect | AWS edition | Azure edition |
| --- | --- | --- |
| L7 load balancing | Application Load Balancer | Application Gateway Standard_v2 |
| Network | VPC + Public/Private Subnet | VNet + App Gateway dedicated/Backend Subnet |
| Backend outbound | Centered on S3 Gateway Endpoint | Explicit NAT Gateway |
| State locking | S3 native lockfile | Azure Blob lease |
| CI Identity | IAM Role | User-assigned Managed Identity |
| Federation | IAM OIDC Provider/Trust Policy | Entra Federated Identity Credential |
| Permissions | IAM Policy | Azure RBAC |
| Logs | ALB access logs saved to S3 | Application Gateway access logs saved to dedicated Blob Storage |

In Azure, the Resource Group can serve as the cleanup boundary. On the other hand, the Application Gateway dedicated Subnet, explicit outbound from 2026 onward, and the separation of Entra Identity and Azure RBAC become additional design elements.

| Aspect | Comparison result |
|---|---|
| Networking | AWS achieved operation without NAT through the S3 Gateway Endpoint. Azure needed explicit outbound for OS package retrieval, and a low-spec NAT Gateway was chosen. |
| Application delivery | Application Gateway has stronger Subnet and GatewayManager NSG requirements than ALB, and also takes longer to build. |
| Identity | AWS concentrates on the Role's Trust/Permission Policy. In Azure, Managed Identity, Federated Credential, and RBAC Scope are separate, so there are more things to track. |
| GitHub OIDC | On the Azure side, there were environments where the measured subject differed from the standard form, so safely checking the JWT claims was important. |
| Remote State | The Blob Backend can be used with Entra RBAC alone, and built-in lease locking is easy to handle. In AWS, permissions for the S3 object and the lockfile were designed separately. |
| Monitoring | Both CloudWatch and Azure Monitor can be minimized by centering on standard metrics. In Azure, evaluation delay was more visible in the reflection and resolution of Metric Alerts. |
| Logging | Azure Monitor can archive directly to Storage, but creating the setting required the ListKeys control-plane permission, and it needed to be reconciled with the prohibition of Shared Key. |
| Cleanup | In Azure the Resource Group is a clear boundary, but Remote State and Federation need ordered control through a separate bootstrap state. |

## Evaluation of the AI Implementation

- Points that were easy to implement: referencing the Terraform schema, confirming boundaries per Resource Group, Blob lease testing, and monitoring with standard metrics.
- Azure-specific difficulties: the Application Gateway dedicated Subnet, Service Tag constraints, an older Azure CLI, OIDC subject customization, and the backend difference between CLI User authentication and OIDC Service Principal authentication.
- Points easier than AWS: State locking being built into Blob lease, and the cleanup boundary provided by the Resource Group.
- Points harder than AWS: the dispersion of Identity components, Application Gateway constraints, explicit outbound, and decisions on Resource Provider registration.

Most routine build and validation work at a Level 2 equivalent can be left to AI. However, Subscription selection, approval of high privileges, identity verification of external Accounts, acceptance of cost and public endpoints, and destroy approval should remain human responsibilities.

## Improvements for the GCP Edition

- List all local and CI inputs at the start to prevent drift beforehand.
- Safely measure the OIDC claims before bootstrap.
- Document the cleanup dependency order of workload, State, and Identity at design time.
- Provide an environment-active flag in CI to prevent re-creation after cleanup.
- Calculate in advance the Fired/Resolved wait time of failure tests from the monitoring evaluation window.
