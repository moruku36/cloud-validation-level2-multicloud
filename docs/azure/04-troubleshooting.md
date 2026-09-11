# トラブルシューティング

検証中のエラーを次の形式で追記する。

## 記録形式

- 症状
- エラーメッセージ（実IDは匿名化）
- 原因
- Azure固有仕様
- Terraform Providerの挙動
- 修正内容
- 修正後の結果
- AI自律修正 / 人間承認の区別

## 初期確認で発生した事象

### 同名Subscriptionが複数存在

- 症状: Subscription表示名だけの`az account set`が複数一致で失敗した。
- 原因: ログイン中の一覧に同じ表示名のSubscriptionが複数存在した。
- 修正: ユーザー提供画面で確認できたID先頭をメモリ上でだけ照合し、一意のSubscriptionを選択した。
- 情報管理: 完全なSubscription ID、Tenant IDはファイルや公開ログへ保存していない。

### AzureRM 5.xのApplication Gateway属性変更

- 症状: 初回`terraform validate`が`enable_http2`をUnsupported argumentとして拒否した。
- 原因: AzureRM 5.2.0では属性名が`http2_enabled`である。
- Terraform Providerの挙動: 旧版の例にある属性名は現行schemaで利用できない。
- 修正: `terraform providers schema -json`で現行属性を確認し、`http2_enabled`へ修正した。
- 区分: AIがコードだけを自律修正。Azure変更・権限追加なし。

### Application Gateway probeのHost要件

- 症状: 初回planがHTTP probeについて`host`と`pick_host_name_from_backend_http_settings`のいずれかが必要として停止した。
- 原因: AzureRM ProviderがHTTP/HTTPS probeのHost headerを必須検証する。
- 修正: 任意Hostを受けるNginxに対し、probe専用Hostとして`127.0.0.1`を明示した。
- 修正後の方針: planを破棄して再生成する。失敗planはapplyしない。
- 区分: AIが自律修正。Azure変更・Security緩和なし。

### `AzurePlatformDNS` Service TagのAllow規則が拒否された

- 症状: 初回applyは29リソースを作成後、Backend NSGのDNS許可規則でHTTP 400となった。
- エラー: `SecurityRuleInvalidAccessType`。`AzurePlatformDNS`に対するAccess `Allow`は無効で、許可値は`Deny`と返された。
- 原因: `AzurePlatformDNS`はAzureプラットフォームDNSを明示的に遮断するための特殊Service Tagであり、Allow規則には使用できない。
- 修正: 無効なAllow規則だけをコードから削除した。Azure提供DNSを遮断する規則は追加しない。
- 安全性: 作成済み29リソースはState管理下。権限追加、Public IP追加、SSH公開、egress拡張は行っていない。
- 区分: AIがログからAzure固有仕様を特定し自律修正。

### 古いAzure CLIにFederated Credential用サブコマンドがない

- 症状: ローカルのAzure CLI 2.35.0では`az identity federated-credential`が利用できなかった。
- 原因: 現行機能より古いCLIを利用していた。
- 修正: CLI更新や権限追加は行わず、Azure Resource Manager APIを読み取り専用で呼び出してissuer、audience、subjectを検証した。
- 修正後の結果: PR用・apply用の2資格情報と、限定されたclaim条件を確認できた。
- 区分: AIが互換性問題を自律回避。Azureリソース変更なし。

### GitHub VariableへTerraform CLI警告が混入

- 症状: State関連の3つのGitHub Variableに、期待値の前へローカルTerraform CLI設定ディレクトリのアクセス警告が含まれた。
- 原因: `terraform output -raw`の標準出力と警告出力を結合した文字列を、そのままブラウザ入力へ渡した。
- 影響: OIDCテスト前に検出したため、GitHub ActionsやAzureリソースへの影響はない。
- 修正: project専用CLI設定を明示し、Storage Account名は形式検証済みの単一値だけを抽出した。3変数を上書き後、警告文字列が全Variableから消えたことを画面上で検証した。
- 区分: GitHubの本人確認だけ人間が承認し、原因特定・修正・再検証はAIが実施した。

### GitHub OIDCのsubject形式が標準形と異なる

- 症状: GitHub OIDC token取得後、Entra IDが`AADSTS700213`でFederated Credentialとのsubject不一致を返した。
- 原因: 対象GitHubアカウントでは、subjectのrepository部分へ安定したOwner IDとRepository IDを付加するカスタマイズが有効だった。
- 修正: 実測subjectのrepository部分をGit管理外の入力として受け取り、PR用とEnvironment用subjectを組み立てるbootstrap変数を追加した。
- 安全性: issuerとaudience、repository、event種別の限定は維持し、RBACは変更していない。
- 修正後の結果: GitHub ActionsからのAzure OIDC loginが成功した。

### Remote State backendがCLI Service Principal認証を拒否

- 症状: OIDC login成功後、`terraform init`がAzure CLIはUser認証だけをサポートするとして停止した。
- 原因: root backendにローカル移行用の`use_cli = true`を固定していた。GitHubのAzure CLI sessionはFederated Service Principalである。
- 修正: backend本体はMicrosoft Entra認証だけを固定し、ローカルではbackend既定のAzure CLIユーザー認証、GitHubでは`ARM_USE_OIDC=true`とOIDC用ARM環境変数を利用するよう分離した。
- 安全性: Storage Key、SAS、Client Secretは追加しておらず、RBACも変更していない。

### CI applyが追加タグを削除

- 症状: OIDC、Remote State、validate、plan、applyは成功したが、apply結果が0追加・12変更・0削除となった。
- 原因: ローカルのGit管理外`terraform.tfvars`だけに`Purpose`追加タグがあり、GitHub Actionsでは`tags`変数の空Map既定値が使われた。
- 影響: 12リソースから`Purpose`タグだけが削除された。リソース削除・置換、ネットワーク・VM・Application Gateway設定変更はない。
- 修正: 公開可能な`Purpose`タグを変数の既定値へ移し、ローカルとCIの入力を一致させた。
- 安全対応: 修復planが12件のin-place tag更新だけで、destroy / recreate、ネットワーク、Identity、Monitoringの変更を含まないことを確認してからapplyした。
- 結果: 修復後のローカル`terraform plan`は`No changes`となり、実環境と構成の一致を確認した。
- 区分: AIがworkflowログから差分を発見して原因を特定し、安全性を検証した。人間は修復applyを承認し、AIが適用と再確認を実施した。

### Cleanup時のApplication Gateway削除伝播遅延

- 症状: Application Gateway削除完了直後、GatewayManager許可NSG Ruleの削除が400で拒否された。
- 原因: Azure側でApplication GatewayとSubnetの関連付け判定が一時的に残っていた。
- 安全対応: 権限・NSG・Stateを手動変更せず停止し、Application Gatewayが0件であることと残存State 3件を確認した。
- 修正: Azure側の削除反映を待ち、残存3件だけのdelete-only planを再生成して適用した。
- 結果: NSG、Resource Groupを削除し、root state 0件とResource GroupのNot Foundを確認した。
- 区分: AIが原因特定、残存境界確認、安全な再planと再実行を行った。権限追加なし。
