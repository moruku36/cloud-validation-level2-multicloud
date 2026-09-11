# 実行結果

## 2026-09-07 初期レビュー

| 項目 | 匿名化した結果 |
|---|---|
| gcloud | 583.0.0 |
| Terraform | 1.9.8 |
| gcloud Identity | 2件登録、active Identityあり |
| 選択中Project | 設定済み、ACTIVE、Billing有効 |
| 日本Region | Tokyo / OsakaともUP、各3 Zone UP |
| 既存境界 | Compute 0、Storage Bucket 0、WIF Pool 0。default VPC 1と既存Service Account 2を保護対象として記録 |
| API | STSを含む必要APIを有効化済み |
| Terraform | root / bootstrapともfmt、init、validate成功 |
| root plan | 17 create、0 change、0 destroy。既存Resource変更なし |
| bootstrap plan | 13 create、0 change、0 destroy。State/WIF/IAM専用 |
| root apply | 17 added、0 changed、0 destroyed。VM 2台RUNNING、Backend 2台HEALTHY、HTTP 200 |
| bootstrap apply | 13 added、0 changed、0 destroyed。State Bucket、WIF、PR/Apply Identity、最小権限Roleを作成 |
| Remote State | GCSへ移行済み。backup SHA-256一致、lineage一致、17リソース、移行後No changes |
| Apply SA binding | VM実行Identityに対する`serviceAccountUser` 1件だけを追加 |

## 比較データ

推測せず、実行記録で確認できた数だけ更新する。

| 指標 | 現在値 |
|---|---:|
| root validate成功まで | 1回 |
| bootstrap validate成功まで | 1回 |
| root safe plan成功まで | 1回 |
| bootstrap safe plan成功まで | 4回（CLI解析失敗2、設定型エラー1、成功1） |
| apply成功まで | 初回root 1回、初回bootstrap 1回、各WIF binding修復 1回、Monitoring 4 attempt、cleanup root/bootstrap各1回 |
| 主要エラー | 10事象（troubleshootingのエラー見出し数。Monitoring API事象は原因2件を含む） |
| AI自律修正 | 8件（人間によるWIF binding置換承認が必要だった2件を除く） |
| 人間介入 | 4件（初回GCP書込み承認、PR/Apply binding置換承認、GitHub本人確認） |
| IAM承認 | 3件（初回bootstrap、PR binding置換、Apply binding置換。恒久Credentialなし） |
| GitHub Actions失敗 | 4 run（GitHub APIのworkflow run記録。rerun attemptは別加算しない） |
| 意図しない実環境drift | 0件 |
| CI plan不整合 | 1件（backend宣言欠落による18 add。applyせず回避） |
| 想定外destroy / replace | 0件 |
| No changes確認 | 13件（初回3、WIF 5、Monitoring 3、cleanup前2） |

ADC未設定は既存gcloudログインの短時間tokenでplan/applyを実施した。tokenは環境変数だけで利用し、ログ・ファイル・GitHubへ保存していない。集計はコマンド記録、troubleshooting見出し、GitHub API run一覧で確認できた範囲に限定した。

## GitHub OIDC / Apply workflow結果

- PR用・Apply用ともstable GitHub owner/repository IDを含むexact subjectでWIF認証成功
- Applyはmain限定の`terraform-production` Environmentから実行
- 長期Credential、Service Account Key、権限追加なし
- GCS Remote State初期化成功
- root planはNo changes
- saved planのapplyは`0 added / 0 changed / 0 destroyed`
- GCS backendは標準lockingを有効にしたまま完了
- 一時OIDC claim確認jobは削除済み

## Monitoring結果

- Uptime Check 1、Alert Policy 5、Health Check log-based metric 1をTerraform管理
- 既存Load Balancer access logとHealth Check logを標準Cloud Loggingへ保存
- PR planは既存Web resourceの変更・置換なし
- main applyはAPI入力制約を2段階で修正後に成功。最終追加は1件のみ
- 障害試験ではMIGを2台から1台へ一時縮小してもHTTP 200を継続
- 容量低下metric、Incident Open（Fired）、2台Healthy復旧、Incident Closedを確認
- 復旧後のroot planはNo changes
- MonitoringのためのIAM追加、長期Credential、Service Account Keyはなし

## Cleanup結果

- cleanup前: root State 25項目、bootstrap State 13項目、両plan No changes
- backup: GCS root Stateとbootstrap Local StateをGit管理外へ保存し、SHA-256を確認
- root destroy plan: 0 add、0 change、25 destroy、全件delete-only
- root destroy後: State 0。管理対象Compute / Network / Load Balancer / Monitoring / Logging / VM実行SAはactive 0
- bootstrap destroy plan: 0 add、0 change、13 destroy、全件delete-only
- bootstrap destroy後: State Bucket / WIF Pool・Provider / PR・Apply SA / custom role / IAM bindingはactive 0
- 保護対象: 既存default network 1件、既存Service Account 2件を残存確認
- Project削除、Billing変更、IAM拡張、Service Account Key作成は未実施
- Remote State Bucket削除前にroot State 0を確認したため、削除後にroot planを再実行しない正しい順序を維持
- GitHub: `GCP_ENVIRONMENT_ACTIVE=false`へ変更後、PR static checks成功、cloud planは認証前にSkipped。main Apply workflowもjob全体がSkipped
