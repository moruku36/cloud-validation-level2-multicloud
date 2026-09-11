# 学びとAWS / Azure比較

## 初期設計時点

| 観点 | AWS | Azure | GCP |
|---|---|---|---|
| Zone分離 | AZごとのSubnet | Subnetはリージョン、VMをZone指定 | Subnetはリージョン、Regional MIGがZone分散 |
| L7公開 | ALB | Application Gateway | Global External Application Load Balancer |
| Backend管理 | EC2 2台をTarget Group登録 | VM NICをBackend Pool登録 | Instance Template + Regional MIGをBackend登録 |
| Private egress | S3 Gateway Endpointでpackage取得 | NAT Gateway | Cloud NAT。外部package repositoryへ80/443のみ |
| Federation | IAM OIDC Provider + Role | Entra Federated Credential + Managed Identity | Workload Identity Pool/Provider + Service Account impersonation |
| State locking | S3 native lockfile | Blob lease | GCS backend標準locking |
| cleanup境界 | tagとState | Resource GroupとState | label・命名・State。Project全体削除は禁止 |

GCPはRegional MIGによる同一Template・Zone分散・autohealingが最も自然で、個別VM管理よりAIが望ましい構成を選びやすい。一方、WIFのPool、Provider、attribute condition、principal URI、Service Account IAMという分解は、AWS/Azure以上に文字列とscopeの検証が重要になる。

## Monitoring

- GCPは固定VM IDよりRegional MIGのcapacity、VM name prefix、Load Balancer metricを監視軸にすると自己修復と整合する。
- Health Check logのLogging resource typeと、log-based metricがMonitoringで公開するresource typeは一致しない場合がある。metric descriptorを確認する必要がある。
- Alert Policyはprovider schemaを通ってもMonitoring APIのduration/comparison制約で拒否される場合がある。部分apply後はState refreshし、未作成resourceだけのplanになっていることを確認する。
- MIG操作、managed metric収集、Incident評価はいずれも非同期である。障害試験はCompute実状態、時系列、Incidentを分けて観測する。
- 1台縮退では冗長性によりHTTP 200を維持でき、容量アラートのFired/Resolvedを安全に検証できた。
- AWS/Azureと同様、通知先は組織運用情報が必要になる境界であり、今回の公開検証ではAlert Policyまでをコード化した。

## AWS / Azure / GCP 最終比較

| 観点 | AWS | Azure | GCP |
|---|---|---|---|
| Networking | AZ別SubnetとSG。S3 Gateway EndpointでNAT不要 | VNet/SubnetはRegion単位。private VMのpackage取得にNATを明示 | Regional Subnet + firewall。Cloud NATを限定egressに使用 |
| Compute | EC2 2台を個別管理 | Zone指定VM 2台 | Instance Template + Regional MIGでZone分散・自己修復 |
| Load Balancing | Regional ALB | Application Gateway Standard_v2 | Global External Application Load Balancer |
| IAM / Identity | IAM Role/PolicyのAction・Resource設計 | Entra Identity + Azure RBAC scope | Service Account、custom role、impersonationを分離 |
| OIDC | OIDC Provider + STS trust subject | Federated Credential | WIF Pool/Provider + attribute mapping + exact principal |
| Remote State | S3 + native lockfile | Blob + lease | GCS + backend標準locking |
| CI/CD | PR plan / Environment apply | PR plan / Environment apply | 同様。PR/Apply SAを分離しforkをworkflowでも拒否 |
| Monitoring | CloudWatch native metric + ALB logs | Azure Monitor metric + Diagnostic Settings | Uptime Check + managed metric + log-based metric |
| Logging | ALB logを専用S3へ保存 | Application Gateway logをStorageへ保存 | 標準Cloud Logging `_Default`へ保存 |
| 障害検知 | target/EC2 alarm | Application Gateway/VM alert | MIG capacity AlertのFired/Resolvedを実証 |
| コスト | NAT Gatewayを避けて低減 | Application Gateway/NATの固定費が大きい | Global LB/Cloud NATが固定費中心。監視は標準metric中心 |
| cleanup | root後にState/OIDCを分離削除 | Resource Group境界が明確 | State/label/nameとAPI照合。WIF等はsoft-delete semanticsあり |

GCPで簡単だった点は、Regional MIGへBackendの分散・自己修復を集約できること、GCS backendが標準lockingを持つこと、標準Cloud LoggingへLB/Health Check logを集約できることだった。

難しかった点は、GitHubのstable numeric IDを含む`sub`とWIF principalの完全一致、Cloud LoggingからMonitoringへ渡るresource type mapping、Alert Policy API固有のcomparison/duration制約、MIGとmanaged metricの非同期性である。AWS/AzureよりIdentity文字列の構成要素が多く、問題がWIF Provider、attribute condition、Service Account IAMのどこにあるかを段階的に分ける必要があった。

## cleanupの学び

- root Remote Stateが空になったことを確認してからState Bucketを削除する。
- State backupはGit管理外へ保存し、SHA-256を確認する。
- Project全体の件数ではなく、State由来のname/labelとAPI結果を突き合わせる。
- 既存default networkと既存Service Accountを明示的な非対象として最後まで確認する。
- cleanup後はGitHubの有効化フラグを`false`にし、資格情報が残っていてもworkflowが再作成へ進まない二重防御にする。

## Level 2評価

3クラウドとも、設計、Terraform、Remote State、OIDC、CI/CD、最低限の監視、障害試験、cleanupはAI主体で実装可能だった。人間は高権限・IAM置換・アカウント本人確認など、責任境界の承認に集中できる。一方、Provider/API制約やFederation claimはplanだけでは確定しないため、AIにはログの匿名化、部分apply後のState確認、権限を拡張しない停止判断が必須である。
