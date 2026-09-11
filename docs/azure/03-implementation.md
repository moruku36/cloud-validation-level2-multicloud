# Terraform実装

## コード構成

- `provider.tf`: Terraform / AzureRM versionとProvider登録方針
- `variables.tf`: Region、CIDR、VM、Application Gateway capacity
- `locals.tf`: 命名と共通tags
- `main.tf`: Resource Group
- `network.tf`: VNet、Subnet、NSG、NAT Gateway
- `application-gateway.tf`: Application Gateway Standard_v2
- `compute.tf`: NIC、Private Linux VM、Nginx cloud-init
- `outputs.tf`: HTTP URLとセキュリティ不変条件

## セキュリティ

- Credential、Subscription ID、Tenant IDをコードへ記録しない。
- VMにPublic IPを関連付けない。
- SSH 22のNSG規則を作らない。
- Backend受信はApplication Gateway SubnetからTCP 80だけ許可する。
- OSパッケージ取得はNAT Gateway経由のHTTP/HTTPSだけを許可する。
- Provider登録をTerraformが暗黙実行しないよう無効化する。

## 試行記録

作成時点: Azureへの変更0件。`init`は成功。初回`validate`でAzureRM 5.2.0の属性変更を1件検出し、Provider schemaに基づいて修正した。初回planはApplication Gateway probeのHost要件で停止し、失敗planをapplyせずコードを修正した。

修正後の`fmt -check`、`validate`、planは成功した。planは30追加、0変更、0削除で、destroy/recreateは0件。Backend NICのPublic IP関連付けは0件、SSH 22の受信規則も0件だった。

初回applyは29リソース作成後、`AzurePlatformDNS` Service TagをAllowに使用したNSG規則だけがAzure APIに拒否された。無効な規則を削除し、作成済みリソースのState整合性を再planで確認する。
