# Bootstrap

Azure Blob Remote StateとGitHub Actions用Workload Identityを作成する独立Terraform stack。

## 作成対象

- State専用Resource Group
- Storage Account / private Blob container
- Blob Versioning / Blob・Container Soft Delete
- PR用・apply用User-assigned Managed Identity
- GitHub OIDC Federated Identity Credential
- Workload Resource GroupとState Containerに限定したRBAC
- Local State移行とcleanupに使用する一時Data Plane RBAC

Subscription ID、Tenant ID、Client ID、Storage Account実名は公開文書へ記録しない。

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

RootをdestroyしRemote State blobを削除した後に、このstackをdestroyする。

