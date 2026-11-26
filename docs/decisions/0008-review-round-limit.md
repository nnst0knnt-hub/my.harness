# レビューは、3回目で直し方を見直し、5回で止め、人が決めたあとは`MUST`が残ればすぐ止める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-30 |
| 関わる設計 | [`rules/review.md`の節「レビューを終える条件」](../../rules/review.md#レビューを終える条件)、[節「レビュー役への頼み方」](../../rules/review.md#レビュー役への頼み方) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

エージェントどうしで書いてレビューすると、直しが終わらないことがある。一方、レビューを終えたか止めたあとに人が直すと決めた指摘も、直しにレビューが要る。

## 判断

レビューの回数の上限と、`MUST`が残ったときの直し方と止め方を決めた。中身は、冒頭の表の「関わる設計」に書く。

## 案

### 回数

| 案 | 結果 | 理由 |
|---|---|---|
| 3回目で書いた側が直し方を見直し、5回で止める | 採った | Claude Codeのチームと同じく、3回で書いた側（作ったエージェント）が見直す。4回目のレビューは見直した直しを、5回目は4回目の指摘の直しを確かめる。 |
| 3回で止めて人に聞く | 採らなかった | 直し方を選ぶたびに人の判断が要る。 |
| 回数を決めず、指摘が無くなるまで直す | 採らなかった | 終わらないことがある。 |
| 2回目からも毎回全体をレビューする | 採らなかった | Claude Codeのチームでは、繰り返し出た指摘の約6割が、1回目のレビューのときからあったコードへの指摘だった。 |
| 指摘された1か所ずつ直す | 採らなかった | 同じ種類の別の所が次の回で指摘される。 |

### 人が決めたあとのレビュー

| 案 | 結果 | 理由 |
|---|---|---|
| 人が決めたあとのレビューを5回の数に入れず、`MUST`が残ればすぐ止める | 採った | 人が決めた直しを、上限に関係なく確かめられる。すぐ止めるので、エージェントどうしの直しが続かない。 |
| 5回の数に入れる | 採らなかった | 5回目のあとに人が直すと決めると、その直しをレビューできない。 |
| 5回の数に入れず、`MUST`が0件になるまで続けて直す | 採らなかった | エージェントどうしの直しが、上限なしに続く。 |

## 結果と失うもの

- 残った`MUST`を人が見るのは、最大で5回目のあとになる。4回目と5回目の分のトークンが増える。
- 直しで文書やコメントに足す主張は、確かめてから書く。誤った主張は正しさの`MUST`になるためである。
- 人が直すと決めるたびに、レビューが1回増える。

## 見直す条件

5回で止まるPRが続くとき。

## 出典

- [How the Claude Code team does code review](https://claude.dev/blog/solving-code-review-at-anthropic/)の節「How we make the reviewer better」：「An agent author and an agent reviewer can keep each other busy indefinitely.」、「When we ran git blame on what the reviewer kept flagging, about 59% of it was code that had been there since the reviewer's first pass.」、「After three rounds, the reviewer asks the author to step back and reconsider the approach.」、「Diff-only re-review after the first few passes.」、「Flag the class of bug, so the author fixes every instance, not one line.」（確かめた日：2026-10-30）
