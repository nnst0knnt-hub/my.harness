# レビュー役のモデルとeffortを、過去のレビューで測った結果で決める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-14 |
| 関わる設計 | [`agents/reviewer.md`](../../agents/reviewer.md)の`model`と`effort` |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

レビュー役のモデルとeffort（考える深さの段階）で、`MUST`の見逃しと使用量が変わる。公式の費用の手引きはふつうのコーディングにSonnetを勧めるが、レビューに使うモデルを決める公式の文書は無い。見逃しの害は使用量の差より大きく、1回の結果では揺れと区別できない。

## 判断

レビュー役は、全体のレビューも直しの差分のレビューも、Opus（別名`opus`）のeffort `xhigh`にする。安い組み合わせに替えるのは、過去に直した`MUST`のあるレビューで、2回続けて同じだけ`MUST`を見つけたときに限る。

| 組み合わせ | レビュー役 |
|---|---|
| 標準 | Opusの`xhigh`を、レビューの深さで決めた数だけ動かす。 |
| 使用量に余裕があるとき | 1回目に、Sonnet（別名`sonnet`）の`high`を1つ足し、独立に動かす。 |

本体の会話、並行の実装役、調べ役（Explore）は測らない。本体の会話は人が選び、置き場所は[判断の記録](0029-main-conversation-model-location.md)に書く。Fableは、プランによっては追加の料金から払われるので、人が頼むか、見込みを示して承認を得てから使う。

## 案

過去のレビュー3回分（スクリプトとテストの変更、文書の変更、直しの差分で、直した`MUST`計9件）を、その時点のコミットで、同じ依頼文で動かした。使用量は、Opusの`xhigh`との比である。

| 案 | 結果 | 理由 |
|---|---|---|
| Opusの`xhigh` | 採った | `MUST`として9件中5件を見つけ、最も多かった。 |
| Opusの`high` | 採らなかった | 直しの差分を除く2回分（7件）で1件、使用量は約6割だった。 |
| Sonnetの`high` | 採った | 余裕があるときの2つ目にした。`MUST`は9件中3件で、Opusが見逃した1件を含み、使用量は約3割だったが、ほかの2件は`SUGGESTION`にしたので、終える条件では見逃しになる。 |
| 公式の勧めで決める | 採らなかった | 背景のとおり、決める文書が無い。 |

## 結果と失うもの

同じ組み合わせでも、1回のレビューが見つける`MUST`は過去の半分ほどで、回ごとに違う。1つのレビュー役では見逃しが残る。LLMの判定役は誤りを見逃しやすく、少数が誤りとすれば誤りとみなす形（minority-veto）で見逃しが減るとする研究がある。余裕があるときの組み合わせは、どのレビュー役の`MUST`も直すので、この形に当たる。

## 見直す条件

- 新しいモデルが出たとき
- 人のレビューで、`MUST`の見逃しが見つかったとき
- プランが変わったとき

## 出典

- [Manage costs effectively](https://code.claude.com/docs/en/costs)の節「Choose the right model」：「Sonnet handles most coding tasks well and costs less than Opus.」（確かめた日：2026-11-14）
- [Model configuration](https://code.claude.com/docs/en/model-config)の節「Fable and usage credits」：「Depending on your plan and seat tier, Fable usage can bill to usage credits instead of drawing on your plan's included limits.」（確かめた日：2026-11-14）
- [Beyond Consensus: Mitigating the Agreeableness Bias in LLM Judge Evaluations](https://arxiv.org/abs/2510.11822)の要旨：「they are remarkably poor at identifying invalid ones (i.e., True Negative Rate <25%).」（確かめた日：2026-11-14）
- 同じ要旨：「We introduce an optimal minority-veto strategy that is resilient to missing data and mitigates this bias to a large extent.」（確かめた日：2026-11-14）
