# サンドボックスの外での再実行を止める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「サンドボックス」](../../.harness/docs/features/protection.md#サンドボックス) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeは、サンドボックスの中で失敗したコマンドを、サンドボックスの外で動かし直すことがある。動かし直したコマンドには、読み書きと通信の制限がかからない。許可のルールに当たるコマンドは、確認なしで動かし直される。

## 判断

PCの設定で`allowUnsandboxedCommands: false`にし、外での再実行を止める。pushの認証は、外に出す形（[通信の境界の判断の記録](0034-sandbox-network-boundary.md)）で外で動くので、再実行に頼らない。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 再実行を止める | 採った | 当たらない書き方のpushと、`cat .env`のような読み取りが、外で動き直さない。 |
| 再実行を許し、再実行の指定にaskのルール（`Bash(dangerouslyDisableSandbox:true)`）を足す | 採らなかった | 再実行のたびに確認が出て、人が認めると、制限のかからないまま動く。 |
| 今のまま（既定で再実行を許す） | 採らなかった | 許可のルールに当たる読み取り（例：`Bash(cat *)`）は、確認なしで外で動き、秘密情報を読める。 |

## 結果と失うもの

サンドボックスに合わないツール（例：docker）は、そのツールを使うプロジェクトの設定で外に出す形を足すまで失敗する。

## 見直す条件

外に出す形を足しても動かせないツールが作業に要るとわかったとき、または、Claude Codeの再実行の仕組みが変わったときに見直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「The unsandboxed retry escape hatch」：「The retried command runs unsandboxed.」、「it also approves the retry, so the command runs outside the sandbox with no prompt」（確かめた日：2026-11-16）
- 同じページの同じ節：「add an ask rule for `Bash(dangerouslyDisableSandbox:true)` to be prompted on Bash retries」（確かめた日：2026-11-16）
- 同じページの節「Turn off the retry with strict sandbox mode」：「While the sandbox is running, commands Claude runs are then sandboxed unless they match an `excludedCommands` entry.」、「Strict sandbox mode applies to the commands Claude runs.」（確かめた日：2026-11-16）
