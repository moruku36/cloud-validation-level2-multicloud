[English](01-scenario.en.md) | [日本語](01-scenario.md)

> This is an English translation added on 2026-10-14. The dates, data, and caveats of the original record are preserved. No new experiment was run for this translation.

# Validation Scenario

## Objective

Verify whether AI can select an Azure-native design from abstract web infrastructure requirements and safely automate the work from build through cleanup.

## Phases

1. Check the local environment and the Azure Subscription
2. Build the web infrastructure with Local State
3. Confirm HTTP 200 via Application Gateway
4. Migrate to Azure Blob Remote State
5. GitHub OIDC with Managed Identity and Federated Credential
6. Pull Request plan and main apply under Environment protection
7. Azure Monitor and Application Gateway Access Log
8. Failure testing while preserving service continuity
9. Quantitative comparison with the AWS edition
10. Ordered cleanup of Root, State, Identity, and RBAC

## Measured Items

- Number of attempts until the first Terraform success
- Number of errors and Azure-specific causes
- Number of human interventions
- Number of AI autonomous fixes
- plan/apply/destroy results
- Build time and actual cost
