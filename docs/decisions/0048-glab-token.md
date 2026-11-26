# `glab`のトークンを、導入先のプロジェクトとスキルの操作に絞る

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-22 |
| 関わる設計 | [`docs/setup-guide.md`の節「`glab`を入れる」](../setup-guide.md#glabを入れる)、[`features/protection.md`の節「`glab`の判定」](../../.harness/docs/features/protection.md#glabの判定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 外で動く`glab`は、PCの人のトークンでGitLabを読み書きする。判定が確認なしで通した呼び出しも、人が確認で認めた呼び出しも、トークンが許す範囲に届く。
- GitLabの個人のトークンには、範囲（scope）で権限を決めるLegacy tokenと、使えるプロジェクトとリソースごとの操作を選べるFine-grained tokenがある。ほかに、プロジェクトのアクセストークンがある。
- `glab`の判定は、トークンと秘密の値を返す形を止める。どのトークンを使うかは、PCごとに人が選ぶ。

## 判断

導入の手引きで、導入先のプロジェクトだけを選び、スキルが使う7つの権限を付けたFine-grained tokenを勧める。判定の止める形は、トークンの種類に依らず残す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 導入先のプロジェクトとスキルの操作だけに絞ったFine-grained token | 採った | 判定が通した呼び出しも、人が認めた呼び出しも、選んだプロジェクトと操作の外に届かない。 |
| Legacy tokenの`api`の範囲 | 採らなかった | APIの読み書きをすべて許す。Fine-grained tokenを作れないGitLabでだけ使う。 |
| プロジェクトのアクセストークン | 採らなかった | gitlab.comでは、PremiumかUltimateの契約が要り、Freeのプランで使えない。 |

## 結果と失うもの

スキルの`glab`のエンドポイントを変えるたびに、導入の手引きの権限の表も直す。権限が足りないと、そのコマンドがGitLabに断られるためである。gitをHTTPSで送る導入先では、Codeの権限も足す。

Fine-grained tokenのPCでは、表に無いCI/CDの変数を読めない。それでも、Legacy tokenを使うPCがあり、判定からトークンの種類は見えないので、判定は秘密の値を返す形を止め続ける。

## 見直す条件

判定がPCのトークンの種類と権限を確かめられるようになったときと、GitLabがトークンの種類か権限の分け方を変えたときに見直す。

## 出典

- [Fine-grained personal access tokens](https://docs.gitlab.com/auth/tokens/fine_grained_access_tokens/)の節「How fine-grained tokens authorize each request」：「The token has a permission for the operation, on the resource in the request path.」（確かめた日：2026-11-22）
- [Access token scopes](https://docs.gitlab.com/security/tokens/access_token_scopes/)の`api`の行：「Grants complete read and write access to the API for the token’s scope.」（確かめた日：2026-11-22）
- [Project access tokens](https://docs.gitlab.com/user/project/settings/project_access_tokens/)：「On GitLab.com, project access tokens require a Premium or Ultimate subscription.」（確かめた日：2026-11-22）
