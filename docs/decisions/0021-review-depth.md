# レビューの深さを、変更を誤ったときの害で変える

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-05 |
| 関わる設計 | [`rules/review.md`の節「レビューの深さ」](../../rules/review.md#レビューの深さ)、[`rules/always-read.md`の節「人に確認を求める場面」](../../rules/always-read.md#人に確認を求める場面) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

誤字の修正と権限の変更を同じ手間でレビューすると、前者ではトークンが余り、後者では見落としが増える。レビュー役を増やせば見つかる問題は増えるが、使用量も増える。

## 判断

レビューの深さを、変更を誤ったときの害で軽い、標準、深いの3つに分け、深いでは、観点か範囲で分けたレビュー役を独立に動かす。中身は、冒頭の表の「関わる設計」に書く。

## 案

### 深さの分け方

| 案 | 結果 | 理由 |
|---|---|---|
| 害で3つに分ける | 採った | Anthropicの記事も害に合わせた手間を勧め、製品もQuick、Standard、Deepを選ばせる。 |
| いつも同じ深さにする | 採らなかった | 手間と害が合わない。 |

### レビュー役の増やし方

| 案 | 結果 | 理由 |
|---|---|---|
| 観点か範囲で分け、独立に動かす | 採った | 範囲で分ければ、1つが読む量も減る。 |
| 多数のエージェントに議論させる | 採らなかった | 論文は、議論の形が、独立に複数回答えて集約する形を確実には上回らないとしている。 |
| 同じ範囲を同じ観点で複数回見せる | 採らなかった | 使用量が増えるわりに、見る所が変わらない。 |

## 結果と失うもの

変更の記録に深さを書くエージェントが判断を誤ると、害の大きい変更が軽く見られる。レビュー役が深さを上げるよう提案でき、`rules/`のようなハーネスの変更は軽いに入れないことで補う。

## 見直す条件

深いが標準より多く`MUST`を見つけないとき。比べ方は、レビュー役のモデルとeffortを測るときに一緒に決める。

## 出典

- [How the Claude Code team does code review](https://claude.dev/blog/solving-code-review-at-anthropic/)の節「HOW YOU CAN ADOPT THIS PROCESS」：「Match review effort to risk: a quick pass on routine changes, a deep one where a missed bug is expensive (Quick, Standard or Deep in Code Review).」（確かめた日：2026-11-06）
- [Code Review](https://code.claude.com/docs/en/code-review)：「Quick: a lighter pass.」、「Standard: balanced depth, speed, and cost.」、「Deep: the most thorough pass.」（確かめた日：2026-11-06）
- [Should we be going MAD?](https://arxiv.org/abs/2311.17371)のAbstract：「multi-agent debating systems, in their current form, do not reliably outperform other proposed prompting strategies, such as self-consistency and ensembling using multiple reasoning paths.」（確かめた日：2026-11-06）
