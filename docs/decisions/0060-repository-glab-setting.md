# 中身のあるリポジトリの`glab`の設定に、確認を求める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「`glab`の判定」](../../.harness/docs/features/protection.md#glabの判定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

リポジトリの`glab`の設定（`.git/glab-cli/config.yml`）は、Readのdenyが無ければサンドボックスの中から書け、外で動く`glab`が設定として読む。PCの勧める設定のReadのdeny（`**/.git/glab-cli/**`）があると、サンドボックスは、作業フォルダーに空の`.git/glab-cli/`を置く。

## 判断

`glab`の判定で、gitのフォルダーと作業フォルダーの一番上の`.git/`に、中身のある`glab-cli`（リンク、項目があるか中を読めないフォルダー、空でないファイル、ほかの種類）があれば、確認を求める。`configure-repository`は、導入先の書き込みの禁止に`./.git/glab-cli`を足す案を示す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 中身があれば、中を読まずに確認を求める | 採った | どのキーが送り先とトークンを変えるかを確かめきれなくても、エージェントが書いた設定が、人の知らないまま外で使われない。 |
| 設定のキーを読み、送り先とトークンを変えるものだけに確認を求める | 採らなかった | 変えるキーを文書で確かめきれず、`glab`がキーを足すと黙って通す。 |
| 空のものも含め、`glab-cli`があれば確認を求める | 採らなかった | 勧める設定のPCでは、サンドボックスが置く空のフォルダーで、すべての`glab`に確認が出る。空のものは、`glab`が設定として読めない。 |

## 結果と失うもの

worktreeでは`./.git`がファイルで書き込みの禁止が当たらないので、判定の確かめが残る。リポジトリの`glab`の設定を使う導入先では、`glab`のたびに確認が出る。

## 見直す条件

`glab`の文書が、リポジトリの設定で読むキーを示すようになったときに見直す。

## 出典

- [Configure the CLI](https://docs.gitlab.com/cli/configuration/)の節「Configuration levels」：「The local configuration file is available at `.git/glab-cli/config.yml` in the current working Git directory.」（確かめた日：2026-11-23）
