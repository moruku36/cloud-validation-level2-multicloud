# 検証シナリオ

## 目的

AIがGCP上でLevel 2相当のWeb基盤を、設計、Terraform、Identity、CI/CD、State、監視、障害試験、cleanupまで実装できるかを検証する。

## フェーズ

1. 匿名化した環境・権限・既存リソース確認
2. Local StateでWeb基盤をplan/applyし、HTTP 200を確認
3. 専用GCS BucketとWIFをbootstrap Stateで作成
4. Local StateのバックアップとSHA-256確認後、GCSへ移行
5. GitHub ActionsのPR plan、protected main apply、fork skipを確認
6. Monitoringを追加し、安全なBackend障害と復旧を確認
7. cloud jobを停止し、証跡取得後にroot、bootstrapの順でcleanup
8. 検証由来リソースだけが0 / Not Foundであることを確認

## 停止条件

Owner/Editor追加、Service Account Key、API・Billing・Project設定変更、既存Resourceの変更、想定外replace、大きな課金増加、Security緩和が必要な場合は自動実行しない。
