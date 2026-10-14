[English](05-results.en.md) | [日本語](05-results.md)

> This is an English translation added on 2026-10-14. The dates, data, results, and caveats of the original record are preserved. No new experiment was run for this translation. The results describe this single experiment only and are not a guarantee of reproducibility or production readiness.

# Validation Results

## Final Results

- Azure CLI login: succeeded
- Target Subscription selection: succeeded (actual ID not disclosed)
- Region: Japan East / Japan West available
- VM SKU: Standard_B1s available in Japan East
- B-series quota: 2 VMs can be created
- First Terraform safe plan: 30 to add, 0 to change, 0 to destroy, 0 replacements
- Public IPs on Backend NICs: 0
- SSH rules facing the Internet: 0
- Web access: HTTP 200 via Application Gateway
- Application Gateway backend health: both Healthy
- VMs: both Running
- Root plan after apply: `No changes`
- bootstrap: 12 to add, 0 to change, 0 to destroy, 0 replacements
- Plan after bootstrap apply: `No changes`
- Remote State: migration to Azure Blob succeeded
- State locking: conflict rejection and recovery after release by Blob lease confirmed in actual operation
- Root plan after State migration: `No changes`
- GitHub OIDC Azure login: succeeded
- GitHub Actions Remote State initialization: succeeded
- main workflow: ran successfully through validate / plan / apply
- Because of a difference in CI inputs, only the 12 additional tags were deleted; the inputs were unified and only the tags were repaired
- Local `terraform plan` after the repair: `No changes`
- GitHub Actions with the repair reflected: OIDC / Remote State / validate / plan / apply succeeded
- CI `terraform plan` after the repair: `No changes`
- CI apply after the repair: 0 added, 0 changed, 0 deleted
- Monitoring: 12 added, 0 changed, 0 deleted, `No changes` after apply
- Failure test: stopping 1 VM caused the Backend-unhealthy Alert to be Fired, HTTP 200 continued, and it became Resolved after recovery
- Root plan before cleanup: `No changes`
- Bootstrap plan before cleanup: `No changes`
- root cleanup: 41 managed resources deleted
- bootstrap cleanup: 12 managed resources deleted
- After cleanup: 0 remaining of the target Resource Groups, validation-tagged resources, Storage, and Identity-related RBAC
- Resource Group outside the validation: retained as intended

## Aggregate

Only what can be confirmed from the records and the GitHub Actions API was aggregated.

| Item | Confirmed value |
|---|---:|
| Until the first validate success | 2 times |
| Until the first safe plan success | 2 times |
| Until the first apply completion | 2 times |
| Recorded major errors and operational events | 11 |
| Events whose cause the AI identified and fixed | 11 |
| GitHub Actions failures | 2 times |
| Unintended Terraform diffs | 1 time (additional tag only) |
| destroy / replace executed | 0 times |
| Safety checks avoiding destroy / replace | at least 4 times |
| `No changes` confirmations | at least 11 times in records and logs |

Human interventions were aggregated by decision category, not by number of clicks. There were 5 categories: Subscription specification, approval of the Remote State public endpoint design, GitHub settings and identity verification, approval of the tag repair apply, and approval of the final cleanup. The AI performed the technical fixes, and no automatic expansion of permissions was performed.

## Cleanup Results

1. Reconciled the State of root (41) and bootstrap (12) against the Azure Resource Group boundary.
2. Confirmed that both root and bootstrap showed `No changes`.
3. Backed up the Remote root state and the bootstrap state outside Git management and confirmed the SHA-256.
4. Applied the delete-only plan for the 41 root resources.
5. Because of an Azure propagation delay immediately after Application Gateway deletion, the NSG Rule deletion was rejected once. After confirming 0 Application Gateways and 3 remaining State entries, a delete-only plan for only those 3 was regenerated and deleted.
6. Confirmed root state 0, Not Found of the workload Resource Group, and the existence of the final Remote State Blob.
7. Applied the delete-only plan for the 12 bootstrap resources.
8. Confirmed that the 2 validation Resource Groups, validation-tagged resources, known Storage, and Role Assignments for the deleted Identities were all 0.

No bulk deletion across the entire Subscription was performed. One Resource Group outside the validation was kept unchanged.
