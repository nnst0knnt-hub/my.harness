# `git pull`をサンドボックスの外に出さない

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「判定のスクリプト」](../../.harness/docs/features/protection.md#判定のスクリプト)、[節「サンドボックス」](../../.harness/docs/features/protection.md#サンドボックス) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- `git pull`は、取得のあとに作業フォルダーを書き換える。
- 外に出したコマンドは、サンドボックスの外ですべての権限で動く（[通信の境界の判断の記録](0034-sandbox-network-boundary.md)）。外の`git pull`は、エージェントが用意したcommit（例：手元のブランチや`.`から取るcommit）で、サンドボックスの中から書けないファイル（例：`.claude/settings.json`、`.harness/rules/`）を書ける。
- 向き先のブランチ（PRをマージする先のブランチ、例：`main`）を最新にする作業は、毎回のPRの前後にある。

## 判断

`git pull`を外に出す形から外し、判定のスクリプトで止める。向き先のブランチを最新にするときは、`git fetch origin <向き先のブランチ>`のあとに、サンドボックスの中で`git merge --ff-only origin/<向き先のブランチ>`を動かす。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 外に出さず、`git fetch`と中の`git merge --ff-only`に分ける | 採った | 中のマージは、サンドボックスの中から書けないファイルを書けずに止まる。取得は外に出す`git fetch`で動く。 |
| 外に出し、判定のスクリプトで簡単な形だけを通す | 採らなかった | 取る先の名前を判定しても、取るcommitの中身は判定できず、そのファイルを書ける。 |
| 外に出し、毎回確認を求める | 採らなかった | 向き先のブランチを最新にするたびに確認が出て、人が認めるとそのファイルを書ける。 |

## 結果と失うもの

`git pull`の代わりに、`git fetch`と`git merge --ff-only`の2つを動かす。中のマージがサンドボックスの中から書けないファイルを変えるcommitを取り込もうとすると、失敗する。そのときは、人がClaude Codeの外で取り込む。

## 見直す条件

Claude Codeのサンドボックスが、外に出したコマンドにも書き込みの制限を当てられるようになったときに見直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Run commands outside the sandbox with `excludedCommands`」：「An excluded command runs with your full access.」（確かめた日：2026-11-16）
- 同じページの節「Protected paths」：「If `git merge` or `git checkout` fails with `unable to unlink old` on one of these paths」（確かめた日：2026-11-16）
