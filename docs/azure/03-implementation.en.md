[English](03-implementation.en.md) | [日本語](03-implementation.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation.

# Terraform Implementation

## Code Structure

- `provider.tf`: Terraform / AzureRM versions and Provider registration policy
- `variables.tf`: Region, CIDR, VM, and Application Gateway capacity
- `locals.tf`: Naming and common tags
- `main.tf`: Resource Group
- `network.tf`: VNet, Subnet, NSG, NAT Gateway
- `application-gateway.tf`: Application Gateway Standard_v2
- `compute.tf`: NIC, private Linux VM, Nginx cloud-init
- `outputs.tf`: HTTP URL and security invariants

## Security

- Do not record credentials, Subscription ID, or Tenant ID in code.
- Do not associate a Public IP with the VMs.
- Do not create an NSG rule for SSH 22.
- Allow Backend inbound only as TCP 80 from the Application Gateway Subnet.
- Allow OS package retrieval only as HTTP/HTTPS via the NAT Gateway.
- Disable implicit Provider registration by Terraform.

## Attempt Record

At the time of writing: 0 changes to Azure. `init` succeeded. The first `validate` detected one attribute change in AzureRM 5.2.0, which was fixed based on the Provider schema. The first plan stopped on the Host requirement of the Application Gateway probe; the failed plan was not applied and the code was fixed.

After the fix, `fmt -check`, `validate`, and plan succeeded. The plan showed 30 to add, 0 to change, 0 to destroy, with 0 destroy/recreate. There were 0 Public IP associations on Backend NICs and 0 inbound rules for SSH 22.

The first apply created 29 resources, after which only the NSG rule that used the `AzurePlatformDNS` Service Tag for Allow was rejected by the Azure API. The invalid rule is to be removed, and State consistency of the already created resources is to be confirmed by re-running plan.
