# CIの設定のファイルの一覧に、導入先の`.harness/config`で場所を足せる

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「CIの設定のファイルを変えるpush」](../../.harness/docs/features/protection.md#ciの設定のファイルを変えるpush) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

判定のスクリプトは、CIの設定のファイルを変えるpushに確認を求める。CIの設定のファイルの場所は、導入先で違う。GitLabでは、`include`で同じブランチのほかのファイルを読め、プロジェクトの設定でCIの設定のファイルのパスを変えられる。

## 判断

既定の一覧（`.github/workflows/`、`.github/actions/`、`.gitlab-ci.yml`）に、導入先の`.harness/config`の`protection.ciSettingPath`で場所を足せる。`configure-repository`が、導入先のCIの設定から、足す場所を案にする。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 既定の一覧に、`.harness/config`で足せる | 採った | 保護するブランチと同じ形（既定の一覧と、厳しくする向きにだけ足せる`.harness/config`）で読め、導入先ごとの場所も確かめられる。 |
| 既定の一覧だけにする | 採らなかった | 導入先ごとの場所（例：`include`で読むファイル）を変えたpushに、確認が出ない。 |
| `.github/`と`.gitlab/`の下のすべてにする | 採らなかった | PRとIssueのテンプレートを直すたびに確認が出る。 |

## 結果と失うもの

`configure-repository`の案から漏れた場所と、導入のあとに足したCIの設定のファイルは、人が`.harness/config`に足すまで確かめない。

## 見直す条件

保護するブランチの一覧の形を変えるときに、同じ形にそろえて見直す。

## 出典

- [CI/CD YAML syntax reference](https://docs.gitlab.com/ci/yaml/)の節「`include:local`」：「The `.gitlab-ci.yml` file and the local file must be on the same branch.」（確かめた日：2026-11-23）
- [Customize pipeline configuration](https://docs.gitlab.com/ci/pipelines/settings/)の節「Specify a custom CI/CD configuration file」：「However, you can specify an alternate filename path, including locations outside the project.」（確かめた日：2026-11-23）
