[English](01-scenario.en.md) | [日本語](01-scenario.md)

> This is an English translation added on 2026-10-14. It preserves the dates, data and caveats of the source record (Japanese original). No new experiment was run.

# Validation Scenario

## Purpose

Verify whether AI can implement a Level 2-equivalent Web infrastructure on GCP through design, Terraform, Identity, CI/CD, State, monitoring, failure testing, and cleanup.

## Phases

1. Check the anonymized environment, permissions, and existing resources
2. Plan/apply the Web infrastructure with Local State and confirm HTTP 200
3. Create a dedicated GCS Bucket and WIF with the bootstrap State
4. Back up the Local State and confirm its SHA-256, then migrate to GCS
5. Confirm GitHub Actions PR plan, protected main apply, and fork skip
6. Add Monitoring, and confirm a safe Backend failure and recovery
7. Stop the cloud jobs, and after collecting evidence, clean up root and then bootstrap, in that order
8. Confirm that only the validation-derived resources are at 0 / Not Found

## Stop Conditions

Do not execute automatically if any of the following is required: adding Owner/Editor, a Service Account Key, changing API / Billing / Project settings, modifying existing Resources, unexpected replace, a large cost increase, or relaxing Security.
