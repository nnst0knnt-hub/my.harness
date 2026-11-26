# 計画、実装、レビューで同じ質の問いを使い、独立性は別の文脈で保つ

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-05 |
| 関わる設計 | [`rules/quality.md`](../../rules/quality.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

レビューだけが基準を持つと、作る側（計画と実装をするエージェント）は基準を知らないまま書き、レビューの指摘と直しが増える。設計の質（責務、依存、過剰な抽象）も、確かめる基準が無いと見落とす。

## 判断

質の問いを`rules/quality.md`の1か所に置き、計画、実装、レビューで同じ問いを使う。作る側とレビュー役の独立性は、問いを分けずに、別の文脈で動かすことで保つ。工程ごとの使い方と、レビュー役だけが見ることは、冒頭の表の「関わる設計」に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 同じ問いを工程で使い分ける | 採った | Anthropicの記事は、同じ採点の基準を作る側と評価する側の両方に渡している。作る側とレビュー役が食い違わない。 |
| レビュー役だけに基準を持たせる | 採らなかった | 作る側が基準を知らないので、直しが増える。 |
| 工程ごとに別の問いを持つ | 採らなかった | 同じことを複数の場所に書き、食い違う。 |
| 原則の名前（例：SOLID原則）の一覧にする | 採らなかった | 原則を当てはめること自体が目的になりやすく、起きる問題を書いた指摘にならない。 |

観点の選び方は、Googleのレビューの手引きの観点（例：設計、複雑さ、テスト、名前）を、どの入力か変更で何が困るかを問える形に直した。

## 結果と失うもの

問いを読むトークンが、計画、実装、レビューの前に増える。共通のルールに入れず別のファイルにして、常に読むルールとスキルが、計画、実装、レビューの前にだけ読ませる。

## 見直す条件

問いの効果は、スキルとレビュー役ができてから人が測る。問いを入れる前より余分な指摘が増えるか、見落としが減らないなら、問いを見直す。

## 出典

- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)の節「Frontend design: making subjective quality gradable」：「With this in mind, I wrote four grading criteria that I gave to both the generator and evaluator agents in their prompts」（確かめた日：2026-11-06）
- 同じページ：「Separating the agent doing the work from the agent judging it proves to be a strong lever to address this issue.」（確かめた日：2026-11-06）
- [What to look for in a code review](https://google.github.io/eng-practices/review/reviewer/looking-for.html)の節「Design」：「The most important thing to cover in a review is the overall design of the CL.」（確かめた日：2026-11-06）
