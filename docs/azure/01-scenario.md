# 検証シナリオ

## 目的

AIが抽象的なWeb基盤要件からAzureネイティブな設計を選択し、構築からcleanupまでを安全に自動化できるか検証する。

## フェーズ

1. ローカル環境とAzure Subscriptionの確認
2. Local StateによるWeb基盤構築
3. Application Gateway経由のHTTP 200確認
4. Azure Blob Remote Stateへの移行
5. Managed IdentityとFederated CredentialによるGitHub OIDC
6. Pull Request planとEnvironment保護下のmain apply
7. Azure MonitorとApplication Gateway Access Log
8. サービス継続性を保った障害試験
9. AWS編との定量比較
10. Root、State、Identity、RBACの順序付きcleanup

## 計測項目

- Terraform初回成功までの試行回数
- エラー件数とAzure固有原因
- 人間介入回数
- AI自律修正回数
- plan/apply/destroy結果
- 構築時間と実コスト

