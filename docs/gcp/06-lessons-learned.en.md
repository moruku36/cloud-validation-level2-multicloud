[English](06-lessons-learned.en.md) | [日本語](06-lessons-learned.md)

> This is an English translation added on 2026-10-14. It preserves the dates, data and caveats of the source record (Japanese original). No new experiment was run.

# Lessons Learned and AWS / Azure Comparison

## At the Initial Design Stage

| Aspect | AWS | Azure | GCP |
|---|---|---|---|
| Zone separation | Subnet per AZ | Subnet is regional, VMs are pinned to Zones | Subnet is regional, Regional MIG distributes across Zones |
| L7 exposure | ALB | Application Gateway | Global External Application Load Balancer |
| Backend management | 2 EC2 instances registered to a Target Group | VM NICs registered to a Backend Pool | Instance Template + Regional MIG registered as the Backend |
| Private egress | Package retrieval via S3 Gateway Endpoint | NAT Gateway | Cloud NAT. Only 80/443 to external package repositories |
| Federation | IAM OIDC Provider + Role | Entra Federated Credential + Managed Identity | Workload Identity Pool/Provider + Service Account impersonation |
| State locking | S3 native lockfile | Blob lease | GCS backend native locking |
| Cleanup boundary | tag and State | Resource Group and State | label, naming, and State. Deleting the whole Project is prohibited |

On GCP, the same Template, Zone distribution, and autohealing of a Regional MIG are the most natural fit, making it easier for AI to choose the desirable configuration than with individual VM management. On the other hand, the decomposition into WIF Pool, Provider, attribute condition, principal URI, and Service Account IAM makes verification of strings and scope more important than on AWS/Azure.

## Monitoring

- On GCP, using Regional MIG capacity, the VM name prefix, and Load Balancer metrics as the monitoring axes, rather than fixed VM IDs, is consistent with self-healing.
- The Logging resource type of the Health Check log and the resource type that the log-based metric exposes in Monitoring may not match. The metric descriptor must be checked.
- An Alert Policy may be rejected by the Monitoring API's duration/comparison constraints even after passing the provider schema. After a partial apply, refresh the State and confirm that the plan covers only the resources not yet created.
- MIG operations, managed metric collection, and Incident evaluation are all asynchronous. In failure testing, observe the actual Compute state, the time series, and the Incident separately.
- With a 1-instance scale-down, redundancy kept HTTP 200, and the Fired/Resolved of the capacity alert could be verified safely.
- As with AWS/Azure, the notification destination is a boundary that requires organizational operations information, so in this public validation only up to the Alert Policy was codified.

## AWS / Azure / GCP Final Comparison

| Aspect | AWS | Azure | GCP |
|---|---|---|---|
| Networking | Per-AZ Subnets and SG. S3 Gateway Endpoint makes NAT unnecessary | VNet/Subnet are per Region. NAT explicitly used for package retrieval by private VMs | Regional Subnet + firewall. Cloud NAT used for limited egress |
| Compute | 2 EC2 instances managed individually | 2 Zone-pinned VMs | Instance Template + Regional MIG for Zone distribution and self-healing |
| Load Balancing | Regional ALB | Application Gateway Standard_v2 | Global External Application Load Balancer |
| IAM / Identity | Action/Resource design of IAM Role/Policy | Entra Identity + Azure RBAC scope | Separates Service Account, custom role, and impersonation |
| OIDC | OIDC Provider + STS trust subject | Federated Credential | WIF Pool/Provider + attribute mapping + exact principal |
| Remote State | S3 + native lockfile | Blob + lease | GCS + backend native locking |
| CI/CD | PR plan / Environment apply | PR plan / Environment apply | Same. Separate PR/Apply SAs, and forks also rejected in the workflow |
| Monitoring | CloudWatch native metric + ALB logs | Azure Monitor metric + Diagnostic Settings | Uptime Check + managed metric + log-based metric |
| Logging | ALB logs stored in a dedicated S3 | Application Gateway logs stored in Storage | Stored in standard Cloud Logging `_Default` |
| Failure detection | target/EC2 alarm | Application Gateway/VM alert | Demonstrated Fired/Resolved of the MIG capacity Alert |
| Cost | Reduced by avoiding NAT Gateway | Fixed costs of Application Gateway/NAT are large | Global LB/Cloud NAT are the main fixed costs. Monitoring is mainly standard metrics |
| Cleanup | State/OIDC deleted separately after root | Resource Group boundary is clear | Cross-check State/label/name against the API. WIF and similar have soft-delete semantics |

The easy points on GCP were that Backend distribution and self-healing could be consolidated into a Regional MIG, that the GCS backend has native locking, and that LB/Health Check logs could be consolidated into standard Cloud Logging.

The difficult points were the exact match between the `sub` containing GitHub's stable numeric IDs and the WIF principal, the resource type mapping that passes from Cloud Logging to Monitoring, the comparison/duration constraints specific to the Alert Policy API, and the asynchronous nature of the MIG and managed metrics. The Identity strings have more components than on AWS/Azure, so it was necessary to isolate step by step whether the problem lay in the WIF Provider, the attribute condition, or the Service Account IAM.

## Cleanup Lessons

- Delete the State Bucket only after confirming that the root Remote State is empty.
- Save State backups outside Git management and confirm SHA-256.
- Cross-check State-derived name/label against API results, not counts across the entire Project.
- Explicitly treat the existing default network and existing Service Accounts as out of scope, and confirm them to the end.
- After cleanup, set GitHub's enable flag to `false`, as a double defense so that the workflow does not proceed to re-creation even if credentials remain.

## Level 2 Evaluation

On all three clouds, design, Terraform, Remote State, OIDC, CI/CD, minimal monitoring, failure testing, and cleanup could be implemented primarily by AI. Humans can concentrate on approving responsibility boundaries such as high privileges, IAM replacement, and account identity verification. On the other hand, Provider/API constraints and Federation claims cannot be determined from the plan alone, so it is essential for the AI to anonymize logs, check State after a partial apply, and make stop decisions that do not expand permissions.
