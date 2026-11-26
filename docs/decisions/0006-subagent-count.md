# サブエージェントはレビュー役だけを作り、計画は本体の会話で、並行の実装はサブエージェントで行う

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-05 |
| 関わる設計 | [`features/reviewer.md`](../../.harness/docs/features/reviewer.md)、[`parallel-work.md`](../../.harness/docs/features/parallel-work.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

サブエージェントは、本体の会話（人とやり取りするセッション）とは別の文脈で動く。定義のファイルを作るほど、保つファイルが増える。1つの依頼に独立した作業が複数あるときは、作業ごとに文脈を分けると並行で進められる。

## 判断

定義のファイルを作るのは、書いた本人とは別の文脈が要るレビュー役だけにする。

計画は本体の会話で行う。人が計画を承認したあと、独立した作業を並行で進めるときだけ、worktreeごとにサブエージェントが実装、テスト、レビュー、PRの本文の下書きまで行う。並行でないときは、実装も本体の会話で行う。

## 案

### 定義のファイルを作るサブエージェント

| 案 | 結果 | 理由 |
|---|---|---|
| レビュー役の1つだけを作る | 採った | 書いた本人とは別の文脈が要るのは、レビューだけである。 |
| 調査用のサブエージェントを作る | 採らなかった | Claude Codeに、読み取り専用の調査用のサブエージェント（Explore）が入っている。 |
| セキュリティ用を別に作る | 採らなかった | 指示ははっきり分かれるが、2つを保つ必要がある。 |

### 計画と実装の場所

| 案 | 結果 | 理由 |
|---|---|---|
| 計画は本体の会話で行い、承認のあとの実装は、並行のときだけサブエージェントで行う | 採った | 計画は人と何度もやり取りする。並行の実装は、変更の記録に書いた内容で進められ、文脈を分けられる。 |
| 計画と実装をいつも本体の会話で行う | 採らなかった | 独立した作業があっても、順にしか進められない。 |
| 計画と実装をいつもサブエージェントで行う | 採らなかった | 公式の文書は、人と何度もやり取りする作業と、前の工程の文脈を次の工程で使う作業は、本体の会話で行うとしている。 |

## 結果と失うもの

サブエージェントは質問のツールを使えないので、人の判断が要る場面では問いを報告に書いて止まり、本体の会話から答えを受けて再開する。worktreeの外のファイルを直せないので、worktreeのサブエージェントは、メインの作業フォルダーにある変更の記録を、自分のworktreeにコピーしてから直す。

## 見直す条件

セキュリティの確認で同じ種類の依頼を何度もしていると人が気づいたら、セキュリティ用を足す。並行の実装役が止まって進まないことが続いたら、worktreeごとのセッションで進める形に変える。

## 出典

- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)の節「Built-in subagents」：「A fast, read-only agent optimized for searching and analyzing codebases.」（確かめた日：2026-10-23）
- 同じページの節「Choose between subagents and main conversation」：「The task needs frequent back-and-forth or iterative refinement」、「Multiple phases share significant context, such as planning, implementation, and testing」（確かめた日：2026-10-23）
