# 学びとAWS比較

## AWS編との設計・運用比較

| 観点 | AWS編 | Azure編 |
| --- | --- | --- |
| L7負荷分散 | Application Load Balancer | Application Gateway Standard_v2 |
| Network | VPC + Public/Private Subnet | VNet + App Gateway専用/Backend Subnet |
| Backend outbound | S3 Gateway Endpoint中心 | 明示的NAT Gateway |
| State locking | S3 native lockfile | Azure Blob lease |
| CI Identity | IAM Role | User-assigned Managed Identity |
| Federation | IAM OIDC Provider/Trust Policy | Entra Federated Identity Credential |
| 権限 | IAM Policy | Azure RBAC |
| ログ | ALB access logをS3へ保存 | Application Gateway access logを専用Blob Storageへ保存 |

AzureではResource Groupをcleanup境界にできる。一方、Application Gateway専用Subnet、2026年以降の明示的outbound、Entra IdentityとAzure RBACの分離が追加の設計要素となる。

| 観点 | 比較結果 |
|---|---|
| Networking | AWSはS3 Gateway EndpointでNATなしを成立させた。AzureはOS package取得に明示的outboundが必要で、低構成のNAT Gatewayを選択した。 |
| Application delivery | ALBよりApplication GatewayのSubnet・GatewayManager NSG要件が強く、構築時間も長い。 |
| Identity | AWSはRoleのTrust/Permission Policyへ集中する。AzureはManaged Identity、Federated Credential、RBAC Scopeが分離し、追跡対象が多い。 |
| GitHub OIDC | Azure側で実測subjectが標準形と異なる環境があり、JWT claimの安全な確認が重要だった。 |
| Remote State | Blob BackendはEntra RBACだけで利用でき、lease lockingが組み込みで扱いやすい。AWSはS3 objectとlockfile権限を別々に設計した。 |
| Monitoring | CloudWatchとAzure Monitorはいずれも標準メトリクス中心で最小構成化できる。AzureはMetric Alertの反映・解消に評価遅延が見えやすかった。 |
| Logging | Azure MonitorからStorageへ直接archiveできるが、設定作成にはListKeys control-plane権限が必要で、Shared Key禁止との設計整理が必要だった。 |
| Cleanup | AzureはResource Groupが明確な境界になる一方、Remote StateとFederationを別bootstrap stateで順序制御する必要がある。 |

## AI実装の評価

- 実装しやすかった点: Terraform schema参照、Resource Group単位の境界確認、Blob lease試験、標準メトリクスによる監視。
- Azure固有の難所: Application Gateway専用Subnet、Service Tag制約、古いAzure CLI、OIDC subject customization、CLI User認証とOIDC Service Principal認証のbackend差。
- AWSより簡単だった点: State lockingがBlob leaseへ内包されること、Resource Groupによるcleanup境界。
- AWSより難しかった点: Identity構成要素の分散、Application Gatewayの制約、明示的outbound、Resource Provider登録判断。

Level 2相当の定型構築・検証はAIへ大部分を任せられる。ただしSubscription選択、高権限承認、外部Account本人確認、コスト・公開endpointの受容、destroy承認は人間の責任として残すべきである。

## GCP編への改善点

- ローカルとCIの全入力を開始時に一覧化し、driftを先に防止する。
- OIDC claimをbootstrap前に安全に実測する。
- workload、State、Identityのcleanup依存順を設計時に文書化する。
- CIに環境稼働フラグを設け、cleanup後の再作成を防止する。
- 障害試験のFired/Resolved待機時間を監視評価窓から事前算定する。
