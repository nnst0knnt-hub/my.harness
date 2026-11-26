# レビューは、`MUST`の指摘が0件になったら終え、`MUST`の範囲は質の問いを足しても広げない

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-05 |
| 関わる設計 | [`rules/review.md`の節「ラベルの付け方」](../../rules/review.md#ラベルの付け方)、[`rules/quality.md`](../../rules/quality.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

問題を探すよう頼まれたレビュー役は、問題が無くてもたいてい何か指摘する。すべての指摘を追うと、終わらず、余分な作り込みも増える。

## 判断

マージを止める`MUST`の範囲を絞り、`MUST`が0件になったらレビューを終える。質の問いを足しても、範囲は広げない。範囲と問いのラベルは、冒頭の表の「関わる設計」に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| `MUST`を絞り、0件で終える | 採った | 正しさと依頼に関わる問題は残さず、ほかの指摘は、直すかを人が選べる。 |
| すべての指摘を直してから終える | 採らなかった | すべての指摘を追うと、必要のない作り込みが増える。 |
| 質の問いのすべてを`MUST`にする | 採らなかった | 責務や簡単さの指摘は見方で変わり、0件で終わる条件にすると終わらない。 |

## 結果と失うもの

マージを止めない指摘（`SUGGESTION`）のうち、機械で確かめられるものと、ルールや原則で直し方が決まっているものは、書いた側が人に聞かずに直す。直し方が1つに決まっていて、聞くと人の手間とレビューの回数が増えるためである。

レビュー役は、PRが入れていない誤りを「前から」と分け、作った人の誤りに見せない。

## 出典

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)の節「Review against your spec」：「A reviewer that's asked to find problems will always find something.」、「If you fix every finding, you end up with extra abstraction layers and tests for cases that can't happen.」（確かめた日：2026-11-06）
- [How the Claude Code team does code review](https://claude.dev/blog/solving-code-review-at-anthropic/)の節「2. AI review on every pull request」：「Each is tagged Important, Nit, or Pre-existing, so a bug the PR didn't introduce doesn't look like the author's fault.」（確かめた日：2026-10-23）
