[English](README.en.md) | [日本語](README.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation.

# Bootstrap

An independent Terraform stack that creates the Azure Blob Remote State and the Workload Identity for GitHub Actions.

## Resources Created

- Resource Group dedicated to State
- Storage Account / private Blob container
- Blob Versioning / Blob and Container Soft Delete
- User-assigned Managed Identities for PR and for apply
- GitHub OIDC Federated Identity Credentials
- RBAC limited to the Workload Resource Group and the State Container
- Temporary Data Plane RBAC used for Local State migration and cleanup

The Subscription ID, Tenant ID, Client ID, and actual Storage Account name are not recorded in public documents.

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Destroy this stack after destroying Root and deleting the Remote State blob.
