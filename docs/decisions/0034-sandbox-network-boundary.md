# 当たらない書き方のpushを、サンドボックスの通信で止める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「止める境界」「サンドボックス」](../../.harness/docs/features/protection.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 権限のルールとフックの`if`は、同じプログラムを別の形で動かすと当たらない（例：`git -C . push --no-verif origin main`）。この書き方はgitの`pre-push`も飛ばす。
- GitHubの非公開・無料のプランでは、ブランチ保護を使えない。
- auto modeの判定役は、既定で、既定のブランチへのpushも許す。

## 判断

GitHubとGitLabへの通信を、サンドボックスの中では拒否する。通信が要るコマンドは、判定のスクリプトを通ったものだけを外に出し、その形は関わる設計に書く。

## 案

### 最後に止める仕組み

| 案 | 結果 | 理由 |
|---|---|---|
| サンドボックスの通信で止める | 採った | コマンドの書き方に依らず、OSが止める。つないだpushは失敗するか判定のスクリプトが止め、作業用のブランチへのpushは、1つで動かせば通る。 |
| すべてのシェルのコマンドでフックを動かし、文字列に`push`か`gh`があれば判定する | 採らなかった | スクリプトの中のpushが見えない。 |
| GitHubのブランチ保護だけが止めると書いて残す | 採らなかった | 非公開・無料のプランの導入先では止まらない。 |
| 管理者の設定で、権限とサンドボックスを変えられなくする | 採らなかった | 管理者の権限が無いPCでは書けない。 |

### サンドボックスの中の通信の止め方

| 案 | 結果 | 理由 |
|---|---|---|
| 拒否する通信先（`deniedDomains`）に足す | 採った | どのモードでも、通信先を付けたコマンドでも止まる。 |
| 許す一覧の外をすべて拒否する（`strictAllowlist`） | 採らなかった | PCのすべてのプロジェクトで、通信先を前もって足すまで取得が失敗する。 |
| 通信先を許さないだけにする | 採らなかった | 人が通信先の確認を許したときと、auto modeで判定役が通信先を付けたコマンドを認めたときに通信できる。 |

## 結果と失うもの

外に出す`git push`、`git fetch`、`gh`、`glab`は、ほかのコマンドとつながずに動かす。サンドボックスの中の`git clone`と、GitHubとGitLabからの依存の取得は失敗する。ほかのホストのリモートは、導入先ごとに拒否する通信先へ足す。IPアドレスへの通信は、拒否する通信先に当たらない。

## 見直す条件

Claude Codeの`excludedCommands`、拒否する通信先、`updatedInput`の当て方が変わったときと、すべての導入先でブランチ保護を使えるとわかったときに見直す。

## 出典

- [Configure permissions](https://code.claude.com/docs/en/permissions)の節「What a Bash rule doesn’t match」：「isn’t a security boundary around the program.」（確かめた日：2026-11-16）
- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Hosts outside your allowed domains」：「A connection to a host in `deniedDomains` is refused in every permission mode too.」（確かめた日：2026-11-16）
- 同じページの節「Per-command allowed domains in auto mode」：「The classifier reviews the hosts together with the command.」（確かめた日：2026-11-16）
- 同じページの節「Network isolation」：「Strict allowlist: if you set `strictAllowlist` to `true` in user, managed, or CLI `--settings` settings, Claude Code denies sandboxed commands access to any host outside the allowlist instead of prompting.」（確かめた日：2026-11-16）
- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)の節「What the classifier blocks by default」の「Allowed by default」：「Pushing to any branch of the repository you're working in, including the default branch.」（確かめた日：2026-11-16）
