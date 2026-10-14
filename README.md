# Level 2 Multi-cloud Terraform Validation

[English](README.md) | [日本語](README.ja.md)

A consolidated repository comparing AI-driven Terraform lifecycles across AWS, Azure, and Google Cloud, including provider-specific implementation, evidence, and final reports.

## Compare the providers

The consolidated lab compares Terraform lifecycle implementation, networking, identity federation, remote-state locking, CI/CD, monitoring, failure testing, and cleanup across AWS, Azure, and Google Cloud. Provider directories retain their detailed records.

The comparison distinguishes implementation evidence, AI mistakes and recovery, and work requiring human responsibility. Browse `docs/` for cross-cloud analysis and `scripts/` for the local validation tooling.

## Level definition and roles (clarification added 2026-10-14)

This note clarifies the explanation of the existing experiment; the original experiment dates, figures, comparisons, evidence, and source commits are unchanged.

The Level 1–3 labels in this project are inspired by the progression seen in cloud vendors’ certification frameworks: foundational knowledge at Level 1, intermediate administration and implementation at Level 2, and more advanced architecture design and decision-making at Level 3. Level 2 draws on domains covered by certifications such as [Azure Administrator Associate](https://learn.microsoft.com/en-us/credentials/certifications/azure-administrator/), [AWS Solutions Architect – Associate](https://aws.amazon.com/certification/certified-solutions-architect-associate/), and [Google Cloud Associate Cloud Engineer](https://cloud.google.com/learn/certification/cloud-engineer). Vendor frameworks and scopes differ; these labels do not represent an official cross-vendor standard, complete exam coverage, or certification equivalence. For the more advanced architect level, see [AWS Solutions Architect – Professional](https://aws.amazon.com/certification/certified-solutions-architect-professional/), [Azure Solutions Architect Expert](https://learn.microsoft.com/en-us/credentials/certifications/azure-solutions-architect/), [Google Cloud Professional Cloud Architect](https://cloud.google.com/learn/certification/cloud-architect), and the [Google Cloud certification overview](https://cloud.google.com/learn/certification).

Roles: the repository owner designed the overall experiment (an IaaS setup of a load balancer, two VMs, and network connectivity, with monitoring, chaos testing, fault tolerance, and API operation as requirements) and carried AWS results, tickets, and know-how into Azure, and Azure lessons into GCP. Codex selected the concrete AWS/Azure/GCP components and performed most of the build and technical troubleshooting. The apparent speed-up in later builds is the owner's observation from a sequential, single-operator experiment; it is not a controlled causal result, evidence of model learning, or proof of job replacement. Overall design, IAM permissions, monitoring policy, and credential boundaries still need to be understood, designed, and configured by a human: AI implemented concrete policies and monitoring definitions, while humans remain responsible for the policies and boundaries.

## Contents

- [aws/](aws)
- [azure/](azure)
- [docs/](docs)
- [gcp/](gcp)
- [scripts/](scripts)

## Detailed documentation

The [Japanese guide](README.ja.md) retains the complete original setup instructions, configuration, examples, project status, and limitations. Supporting documents keep their existing language.
