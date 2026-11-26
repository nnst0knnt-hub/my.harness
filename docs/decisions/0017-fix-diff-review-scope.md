# 直しの差分のレビューでは、読む範囲を絞る

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-30 |
| 関わる設計 | [`rules/review.md`の節「レビュー役への頼み方」](../../rules/review.md#レビュー役への頼み方) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

書いた側の会話と同じく、レビュー役も、ツールを使うたびに、それまでの会話とツールの結果をすべて送る。読むファイルが多いほど、1回のレビューで使うトークンが増える。

## 判断

直しの差分のレビューでは、関わるファイルの全文を読まない。読む範囲は、[`rules/review.md`の節「レビュー役への頼み方」](../../rules/review.md#レビュー役への頼み方)の3つに絞る。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 読む範囲を絞る | 採った | 差分の外は、1回目の全体のレビューで見ている。使うトークンは、読む文脈の大きさで増える。 |
| 毎回、関わるファイルの全文を読む | 採らなかった | 差分が小さくても、読む量が全体のレビューに近くなる。 |

## 結果と失うもの

直しで差分の外が誤るようになった所（例：名前を変えて、古い名前の参照が残る）を、レビュー役が見落としやすくなる。書いた側が、同じ種類の誤りをPRの変更の全体で探して直すことで補う。

## 見直す条件

直しの差分のレビューのあとに、差分の外の誤りが見つかることが続いたとき。

## 出典

- [Manage costs effectively](https://code.claude.com/docs/en/costs)の節「Reduce token usage」：「Token costs scale with context size: the more context Claude processes, the more tokens you use.」（確かめた日：2026-10-30）
- 同じページの節「Why usage climbs in a long session」：「Claude Code sends your full conversation with every request, and each time Claude uses tools it sends another request carrying that batch of tool results.」、「every subagent, and every agent a dynamic workflow spawns, sends its own requests on top of the main conversation's.」（確かめた日：2026-10-30）
