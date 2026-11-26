# CIの設定のファイルを変えるpushで、人に確認を求める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「CIの設定のファイルを変えるpush」](../../.harness/docs/features/protection.md#ciの設定のファイルを変えるpush) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- CIの設定のファイル（例：`.github/workflows/`、`.gitlab-ci.yml`）は、作業用のブランチへのpushでCIを動かす。変えると、secrets（CIのジョブに渡す秘密の値）を外へ送るジョブを足せる。
- CIの設定のファイルは手元のテストでは動かず、PRのレビューで気づくのはpushのあとで、secretsの漏れは取り消せない。
- 手元の追跡のブランチと親のcommitの情報は、サンドボックスの中から書き換えられる。

## 判断

判定のスクリプトが、送るcommitのCIの設定のファイルを、リモートの送り先のブランチの今の先頭（無ければ既定のブランチの今の先頭）と比べ、違えば確認を求める。

## 案

### 確かめる場所

| 案 | 結果 | 理由 |
|---|---|---|
| 判定のスクリプト | 採った | 外に出るすべてのpushが通り、確認を求める判定を返せる。 |
| CIの設定のファイルへのEditとWriteのask | 採らなかった | ファイルを書かずにcommitを作る書き方（例：`git update-index`）と、シェルからの書き込みで越えられる。 |
| gitの`pre-push`のフック | 採らなかった | 確認を求められず止めるだけなので、人が認めたpushも人が動かすことになる。 |

### 比べる元

| 案 | 結果 | 理由 |
|---|---|---|
| リモートの今の先頭 | 採った | サンドボックスの中から書き換えられない。 |
| 手元の追跡のブランチ | 採らなかった | 送るcommitを指すように書き換えると、変更が無いように見える。 |
| 既定のブランチとの分岐点 | 採らなかった | 親のcommitの情報を偽ると、CIの設定のファイルを変えたcommitを分岐点に選ばせられる。 |

## 結果と失うもの

pushのたびにリモートへの問い合わせが1回増え、SSHの鍵の承認が毎回出る環境では、承認が2回になる。既存のジョブが動かすコード（例：テスト）の変更では、そのジョブのsecretsを守れない。既定のブランチがあとでCIの設定のファイルを変えると、古いブランチの最初のpushで確認が1回増える。

## 見直す条件

ホストが、pushの前にCIの設定の変更を止める機能を、導入先のプランで使えるようになったときと、問い合わせの時間が目標の5秒を超えるとわかったときに見直す。

## 出典

- [CI/CD pipelines](https://docs.gitlab.com/ci/pipelines/)：「Branch pipelines run every time you push a commit to a branch, with no configuration required.」（確かめた日：2026-11-19）
- [GitLab CI/CD variables](https://docs.gitlab.com/ci/variables/)：「Code pushed to the `.gitlab-ci.yml` file could compromise your variables.」（確かめた日：2026-11-19）
- [git-replace](https://git-scm.com/docs/git-replace)：「Replacement references will be used by default by all Git commands except those doing reachability traversal (prune, pack transfer and fsck).」（確かめた日：2026-11-19）
