# `Stop`のフックを使わない

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-23 |
| 関わる設計 | [`features/protection.md`の節「フック」「判断」](../../.harness/docs/features/protection.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeの`Stop`のフックは、エージェントが返事を終えようとしたときに動く。公式の文書は、このフックで確認のスクリプトを動かし、失敗すれば作業に戻す方法を紹介している。

## 判断

`Stop`のフックを使わない。これは、公式の推奨から外れる。編集のあとにフックで整形のコマンドを動かす方法も、同じ理由（フックがサンドボックスの外で、導入先のコードを動かす）で使わない。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| エージェントがサンドボックスの中で確認を動かして出力を示し、レビュー役が証拠と差分を確かめる | 採った | gitの設定でフックを足し、動かすgitが2.54以上の導入先では、エージェントのcommitで`pre-commit`がサンドボックスの中で動き、CIのある導入先では、最後にCIで確かめる。 |
| `Stop`のフックで確認を動かす | 採らなかった | フックはサンドボックスの外で動き、テストのコマンドは導入先のコードを動かすので、エージェントが書き換えたコードがサンドボックスの外で動く。避けるにはOSごとにフックの中でサンドボックスを作る必要があり、仕組みが複雑になる。 |

## 結果と失うもの

確認を動かすことが、仕組みで必ず止める方法ではなくなり、ルールとレビューに頼る分だけ弱くなる。問題に気づくのが、後になる。

## 出典

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)の節「Give Claude a check to run」：「runs your script whenever Claude tries to end its turn, and sends Claude back to work if the script exits with code 2.」（確かめた日：2026-11-06）
