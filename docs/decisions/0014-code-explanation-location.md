# ファイルごとの説明の文書を置かない

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-23 |
| 関わる設計 | [`CONTRIBUTING.md`の節「コメント」](../../CONTRIBUTING.md#コメント) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

スクリプトとスキルの説明を、どこに書くかを決める必要がある。

## 判断

ファイルごとの説明の文書を置かない。説明は、ファイルの先頭のコメント、関数のコメント、設計の文書、ルートの`README.md`に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| ファイルごとの文書を置かず、コードのそばに書く | 採った | 説明がコードと同じファイルにあり、一緒に直せる。新しく正しい少数の文書は、手入れされていない大量の文書よりよい。 |
| ファイルごとに説明の文書を置く | 採らなかった | コードを直したときに、別の文書を直し忘れやすい。 |

## 結果と失うもの

フォルダーごとの説明の`README.md`は置かず、ルートの1つだけにする。Googleの文書はコードのパッケージの最上位のフォルダーに`README.md`を置くとしていて、このリポジトリは全体を1つのパッケージとして扱うためである。例外は、導入先と同じ形にする`.harness/docs/`の目次（`.harness/docs/README.md`）である。

## 出典

- [Google documentation best practices](https://google.github.io/styleguide/docguide/best_practices.html)の節「Minimum Viable Documentation」：「A small set of fresh and accurate docs is better than a large assembly of "documentation" in various states of disrepair.」（確かめた日：2026-10-23）
- 同じページの節「Update Docs with Code」：「Change your documentation in the same CL as the code change.」（確かめた日：2026-10-23）
- [Google README guide](https://google.github.io/styleguide/docguide/READMEs.html)の節「Where to put your README」：「All top-level directories for a code package should have an up-to-date README.md file.」（確かめた日：2026-10-23）
