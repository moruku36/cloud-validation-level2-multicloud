# Terraform実装

## root管理予定Resource

- Custom mode VPC / Regional Subnet
- Cloud Router / Cloud NAT
- Health Check・GFEからBackend TCP 80だけを許可するIngress Firewall
- VMからTCP 80/443だけを許可するEgress Firewallと、それ以外のEgress deny
- ゼロ権限のVM runtime Service Account
- Instance Template / Regional MIG（2 Zone、2台、autohealing）
- Global IPv4 / Backend Service / URL Map / Target HTTP Proxy / Global Forwarding Rule
- 後続フェーズのCloud Monitoring / Cloud Logging構成

## bootstrap管理予定Resource

- 専用GCS State Bucket
- PR用・Apply用Service Account
- Workload Identity Pool / GitHub OIDC Provider
- exact subjectの`roles/iam.workloadIdentityUser` binding
- State Object IAM
- Terraform専用custom roleとProject IAM binding

## 品質・安全策

- Terraform `>= 1.9.0, < 2.0.0`
- Google Provider `7.43.0`固定。公開直後の8.xではなく検証済み7.x系を採用
- `.gitattributes`でTerraform、YAML、MarkdownをLF固定
- State、plan、tfvars、backup、keyを`.gitignore`対象化
- 実Project識別子は必須variableまたはCI Secretから注入
- Instance Templateは`create_before_destroy`、MIGはrolling replaceでサービス継続を優先
