# 書き方の規則を、分かりやすさ、機械で止める規則、機械で止めない形に分ける

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-05 |
| 関わる設計 | [`rules/writing.md`](../../rules/writing.md)、[`CONTRIBUTING.md`の節「機械で確かめるもの」](../../CONTRIBUTING.md#機械で確かめるもの) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

レビュー役に書き方を見せると、直しで足した文に次の指摘が出て、レビューが終わらない。その分だけ、要件、設計、判定、手順を見るトークンが減る。一方、語と表記の多くは機械で判定でき、読み手が事実を誤って読むかは機械で判定できない。

## 判断

書き方の規則を、誰が確かめるかで、分かりやすさ、機械で止める規則、機械で止めない形の3つに分ける。機械で止める規則は、誤検知が少なく、今の文書か履歴に外れた例があるものに絞る。分け方は、冒頭の表の「関わる設計」に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 3つに分ける | 採った | 厳密に従わせる規則は機械が毎回同じ基準で見つけ、レビューは内容に集まる。公式の手引きも、レビューの依頼でスタイルを外すよう書いている。 |
| 書き方のすべてをレビューで見る | 採らなかった | 指摘と直しが繰り返され、トークンの多くが書き方に使われる。 |
| すべての規則を機械で止める | 採らなかった | 文の分かりやすさは判定できず、誤検知が増えると確認が形だけになる。外れた例の無い規則は、作っても防ぐものが無い。 |
| 機械で止めない形の規則を消す | 採らなかった | 書く人が迷ったときの基準が無くなり、書き方がそろわない。 |

## 結果と失うもの

機械で止めない形の外れは、レビューを通っても残る。読み手が事実を誤って読まないなら、残してよいと考える。

## 見直す条件

同じ形についての人の指摘が続いたとき、その形を機械で止める側へ移す。誤検知が続く規則は、止める側から外す。

## 出典

- [Best practices for Claude Code](https://code.claude.com/docs/en/best-practices)の節「Review against your spec」：「report gaps that affect correctness and skip style」（確かめた日：2026-11-06）
- [How the Claude Code team does code review](https://claude.dev/blog/solving-code-review-at-anthropic/)の節「How we make the reviewer better」：「Noise costs more when the author is an agent.」（確かめた日：2026-11-06）
