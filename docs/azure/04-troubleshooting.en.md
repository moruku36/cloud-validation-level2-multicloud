[English](04-troubleshooting.en.md) | [日本語](04-troubleshooting.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation.

# Troubleshooting

Errors during validation are to be appended in the following format.

## Record Format

- Symptom
- Error message (actual IDs anonymized)
- Cause
- Azure-specific behavior
- Terraform Provider behavior
- Fix
- Result after the fix
- Distinction between AI autonomous fix / human approval

## Events Encountered During Initial Checks

### Multiple Subscriptions with the same name

- Symptom: `az account set` with only the Subscription display name failed because multiple Subscriptions matched.
- Cause: The list of the logged-in account contained multiple Subscriptions with the same display name.
- Fix: The leading part of the ID that could be confirmed on the screen provided by the user was matched only in memory, and the unique Subscription was selected.
- Information handling: The full Subscription ID and Tenant ID were not saved to files or public logs.

### Application Gateway attribute change in AzureRM 5.x

- Symptom: The first `terraform validate` rejected `enable_http2` as an Unsupported argument.
- Cause: In AzureRM 5.2.0 the attribute name is `http2_enabled`.
- Terraform Provider behavior: Attribute names found in examples for older versions are not available in the current schema.
- Fix: Confirmed the current attribute with `terraform providers schema -json` and corrected it to `http2_enabled`.
- Classification: The AI autonomously fixed the code only. No Azure changes and no added permissions.

### Application Gateway probe Host requirement

- Symptom: The first plan stopped, stating that either `host` or `pick_host_name_from_backend_http_settings` is required for the HTTP probe.
- Cause: The AzureRM Provider strictly validates the Host header of HTTP/HTTPS probes.
- Fix: Since Nginx accepts any Host, `127.0.0.1` was specified explicitly as a probe-only Host.
- Policy after the fix: Discard the plan and regenerate it. The failed plan is not applied.
- Classification: Autonomously fixed by the AI. No Azure changes and no Security relaxation.

### Allow rule for the `AzurePlatformDNS` Service Tag was rejected

- Symptom: The first apply created 29 resources and then returned HTTP 400 on the DNS allow rule of the Backend NSG.
- Error: `SecurityRuleInvalidAccessType`. It was returned that Access `Allow` is invalid for `AzurePlatformDNS` and the permitted value is `Deny`.
- Cause: `AzurePlatformDNS` is a special Service Tag meant for explicitly blocking Azure platform DNS and cannot be used in an Allow rule.
- Fix: Only the invalid Allow rule was removed from the code. No rule that blocks Azure-provided DNS is added.
- Safety: The 29 resources already created are under State management. No permissions were added, no Public IP was added, SSH was not exposed, and egress was not expanded.
- Classification: The AI identified the Azure-specific behavior from the log and fixed it autonomously.

### Older Azure CLI lacks the subcommand for Federated Credentials

- Symptom: `az identity federated-credential` was not available in the local Azure CLI 2.35.0.
- Cause: An older CLI than the current feature set was in use.
- Fix: Without updating the CLI or adding permissions, the Azure Resource Manager API was called read-only to verify the issuer, audience, and subject.
- Result after the fix: The 2 credentials (for PR and for apply) and their restricted claim conditions were confirmed.
- Classification: The AI autonomously worked around the compatibility issue. No Azure resource changes.

### Terraform CLI warning mixed into GitHub Variables

- Symptom: In the 3 State-related GitHub Variables, an access warning about the local Terraform CLI configuration directory was included before the expected value.
- Cause: A string combining the standard output and the warning output of `terraform output -raw` was passed as-is to the browser input.
- Impact: It was detected before the OIDC test, so there was no impact on GitHub Actions or Azure resources.
- Fix: A project-specific CLI configuration was specified explicitly, and only a single format-validated value was extracted for the Storage Account name. After overwriting the 3 variables, it was verified on screen that the warning string had disappeared from all Variables.
- Classification: A human approved only the GitHub identity verification; the AI performed root-cause identification, the fix, and re-verification.

### GitHub OIDC subject format differs from the standard form

- Symptom: After obtaining the GitHub OIDC token, Entra ID returned `AADSTS700213` for a subject mismatch with the Federated Credential.
- Cause: In the target GitHub account, a customization that appends the stable Owner ID and Repository ID to the repository part of the subject was enabled.
- Fix: Added a bootstrap variable that receives the repository part of the measured subject as input outside Git management and assembles the PR subject and the Environment subject.
- Safety: The restrictions on issuer, audience, repository, and event type were maintained, and RBAC was not changed.
- Result after the fix: Azure OIDC login from GitHub Actions succeeded.

### Remote State backend rejected CLI Service Principal authentication

- Symptom: After a successful OIDC login, `terraform init` stopped, stating that Azure CLI supports only User authentication.
- Cause: The root backend had `use_cli = true`, intended for local migration, fixed in place. The Azure CLI session in GitHub is a Federated Service Principal.
- Fix: The backend itself is fixed to Microsoft Entra authentication only, and it was separated so that locally the backend's default Azure CLI user authentication is used, while in GitHub `ARM_USE_OIDC=true` and the ARM environment variables for OIDC are used.
- Safety: No Storage Key, SAS, or Client Secret was added, and RBAC was not changed.

### CI apply removed an additional tag

- Symptom: OIDC, Remote State, validate, plan, and apply succeeded, but the apply result was 0 added, 12 changed, 0 deleted.
- Cause: Only the local, Git-unmanaged `terraform.tfvars` had the additional `Purpose` tag, and in GitHub Actions the empty-Map default of the `tags` variable was used.
- Impact: Only the `Purpose` tag was removed from 12 resources. There was no resource deletion or replacement, and no change to network, VM, or Application Gateway settings.
- Fix: The publishable `Purpose` tag was moved into the default value of the variable so that local and CI inputs match.
- Safety measures: Before applying, it was confirmed that the repair plan consisted only of 12 in-place tag updates and contained no destroy / recreate and no changes to network, Identity, or Monitoring.
- Result: After the repair, the local `terraform plan` showed `No changes`, confirming that the actual environment matches the configuration.
- Classification: The AI found the diff in the workflow log, identified the cause, and verified safety. A human approved the repair apply, and the AI performed the apply and the re-check.

### Application Gateway deletion propagation delay during cleanup

- Symptom: Immediately after the Application Gateway deletion completed, deletion of the NSG Rule that allowed GatewayManager was rejected with 400.
- Cause: On the Azure side, the determination of the association between the Application Gateway and the Subnet remained temporarily.
- Safety measures: It stopped without manually changing permissions, NSG, or State, and confirmed that there were 0 Application Gateways and 3 remaining State entries.
- Fix: Waited for the deletion to be reflected on the Azure side, then regenerated and applied a delete-only plan for only the remaining 3.
- Result: The NSG and Resource Group were deleted, and root state 0 and Not Found of the Resource Group were confirmed.
- Classification: The AI performed root-cause identification, confirmation of the remaining boundary, and a safe re-plan and re-run. No permissions were added.
