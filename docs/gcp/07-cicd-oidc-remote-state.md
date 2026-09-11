# CI/CD・Workload Identity Federation・Remote State

## 認証設計とCI/CDフロー

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant GH as GitHub Actions Runner
    participant OIDC as GitHub OIDC Token Service
    participant WIF as Workload Identity Pool / Provider
    participant SA as Service Account (PR / Apply)
    participant GCS as GCS Remote State Bucket
    participant GCP as Google Cloud Resource APIs

    Note over Dev,GH: PR 作成時 (terraform-pr.yml)
    Dev->>GH: Pull Request オープン
    GH->>OIDC: ID Token 要求 (id-token: write)
    OIDC-->>GH: 短期 JWT (sub: repo:owner@id/repo@id:pull_request)
    GH->>WIF: STS 認証リクエスト (JWT 交換)
    WIF->>WIF: attribute mapping & exact subject 検証
    WIF->>SA: PR用 Service Account へ Impersonate (roles/iam.workloadIdentityUser)
    SA-->>GH: 短期 GCP OAuth2 Access Token (Viewer 権限)
    GH->>GCS: -lock=false で State 読取 (roles/storage.objectViewer)
    GH->>GCP: Read-only API 呼出 (terraform plan)
    GH-->>Dev: PRコメントに差分表示

    Note over Dev,GH: main マージ時 (terraform-apply.yml)
    Dev->>GH: main ブランチへマージ (Environment: terraform-production)
    GH->>OIDC: ID Token 要求
    OIDC-->>GH: 短期 JWT (sub: ...:environment:terraform-production)
    GH->>WIF: STS 認証リクエスト
    WIF->>SA: Apply用 Service Account へ Impersonate (CRUD 権限)
    SA-->>GH: 短期 GCP OAuth2 Access Token
    GH->>GCS: GCS ネイティブ排他ロック取得
    GH->>GCP: terraform apply (リソース作成・更新)
    GH->>GCS: 更新後 tfstate 保存 & ロック解放
    GH-->>Dev: Apply 完了通知
```

- Issuerは`https://token.actions.githubusercontent.com`のみ
- Provider条件は`repository_owner`と`repository`を固定
- PR subjectは`repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:pull_request`のexact形式
- Apply subjectは`repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:environment:terraform-production`のexact形式
- fork PRは同じbase repository subjectになり得るため、Workflowでも`head.repo.full_name == github.repository`を必須化
- Service Account Key、Client Secret、長期Credentialは作成しない
- PR SAはread-only custom roleとState Object Viewer
- Apply SAはrootが管理するResource familyのCRUD custom roleとState Object Admin

## Remote State

- GCS専用Bucket
- Uniform Bucket-Level Access
- Public Access Prevention `enforced`
- Object Versioning
- Google管理サーバー側暗号化
- prefix: `terraform/root`
- Terraform GCS Backend標準のState locking
- PR planだけ`-lock=false`とし、State書込み権限を付与しない

移行時はLocal Stateをignored directoryへ保存し、移行元とbackupのSHA-256一致後に`terraform init -migrate-state`を実行する。移行前後のState resource数、lineage、serial、plan結果を秘密値を出さず確認する。

## 移行結果

- Local Stateをignored directoryへコピーし、移行元とbackupのSHA-256一致を確認
- `terraform init -migrate-state -force-copy`で`terraform/root` prefixへ移行
- GCS上のState object、lineage一致、State内17リソースを確認
- 移行に伴いState serialは1増加したが、既存Resourceの差分はなし
- 通常のlockingを有効にしたplanが成功し、終了後に孤立lockがないことを確認
- 移行後のroot planはNo changes

## GitHub設定

Repository / Environment Secrets:

- `GCP_PROJECT_ID`
- `GCP_WIF_PROVIDER`
- `GCP_PR_SERVICE_ACCOUNT`
- `GCP_APPLY_SERVICE_ACCOUNT`
- `GCP_TF_STATE_BUCKET`

Repository Variable:

- `GCP_ENVIRONMENT_ACTIVE`

`terraform-production`はmain限定とする。cleanup後は`GCP_ENVIRONMENT_ACTIVE=false`を維持し、bootstrapとStateを復元するまでcloud jobを起動しない。

## PR OIDC subject検証

初回のRemote State接続では、Service Account access token取得時に`iam.serviceAccounts.getAccessToken`が拒否された。JWT本体を出力しない一時stepで`sub`と`aud`だけを確認した結果、`aud`はWIF Providerと一致した一方、`sub`にはGitHub owner/repositoryの安定numeric IDが含まれていた。

TerraformのPR subjectを次の匿名化形式へ変更した。

```text
repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:pull_request
```

- exact subjectを維持し、wildcardや`principalSet`へ緩和しない
- Providerのrepository name/owner condition、audience、Apply subjectは変更しない
- `roles/iam.workloadIdentityUser`以外の権限を追加しない
- IAM memberは`create_before_destroy`で新binding作成後に旧bindingを削除
- bootstrap apply後のplanはNo changes
- 修正後のPR WorkflowでWIF認証、GCS backend初期化、root plan No changesを確認
- claim確認用の一時デバッグstepは認証成功後に削除

## Apply Environment OIDC subject検証

`terraform-production`をmain限定のまま使用し、通常applyを無効化した一時jobでJWTの`sub`と`aud`だけを確認した。token本体、header、signature、その他claim、Credentialは出力していない。

実`sub`は次の匿名化形式だった。

```text
repo:<OWNER>@<OWNER_ID>/<REPOSITORY>@<REPOSITORY_ID>:environment:terraform-production
```

TerraformのApply subjectだけをこのexact形式へ変更した。PR subject、attribute condition、audience、Service Account権限は変更せず、wildcardと`principalSet`も使用していない。IAM memberは`create_before_destroy`により新binding作成後に旧bindingを削除した。

- bootstrap apply: Apply bindingのみ`1 added / 0 changed / 1 destroyed`
- bootstrap apply後plan: No changes
- root plan: No changes
- 一時claim debug job: 削除済み
- 通常apply job: 再有効化済み
- GitHub Actions: WIF認証、GCS backend初期化、saved plan、applyが成功
- CI plan: No changes
- CI apply: `0 added / 0 changed / 0 destroyed`
- locking: `-lock=false`を使用せず、GCS backendの標準locking経路でplan/apply完了

## Cleanup

1. root/bootstrapのState listとNo changes planを確認
2. GCS root Stateとbootstrap Stateを`.state-backups/`へ保存し、SHA-256を確認
3. rootの25 destroyがdelete-onlyであることを確認してapply
4. root State 0とworkload/Monitoringのactive 0を確認
5. bootstrapの13 destroyがdelete-onlyであることを確認してapply
6. State Bucket、WIF、Service Account、custom role、IAM bindingのactive 0をAPIで確認

State Bucket削除後はroot backendへ接続できないため、root State 0の最終確認を先に行った。Project削除や既存resourceの一括削除は行っていない。

cleanup後の誤再作成防止にはworkflow既存条件`vars.GCP_ENVIRONMENT_ACTIVE == 'true'`を使用する。GitHub側で今後不要となる削除候補は次のとおり。今回は値の削除は行わない。

cleanup後にRepository Variableを`false`へ変更した。PR workflowではstatic checksが成功し、cloud plan jobがOIDC認証・GCS初期化前にSkippedとなった。merge後のmain Apply workflowもjob全体がSkippedとなり、削除済みWIF/GCSへの接続や再作成planへ進まないことを確認した。

- Repository / Environment Secrets: `GCP_PROJECT_ID`、`GCP_WIF_PROVIDER`、`GCP_PR_SERVICE_ACCOUNT`、`GCP_APPLY_SERVICE_ACCOUNT`、`GCP_TF_STATE_BUCKET`
- Repository Variable: `GCP_ENVIRONMENT_ACTIVE`
- Environment: `terraform-production`

再構築する場合はbootstrapを先にapplyし、GitHub設定を新しい実値へ更新してから有効化フラグを`true`にする。
