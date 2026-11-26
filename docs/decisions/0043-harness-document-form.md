# ハーネスの要求、要件、全体の設計を、導入先と同じ`.harness/docs/`の形で書く

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-17 |
| 関わる設計 | [`.harness/docs/architecture.md`の節「判断」](../../.harness/docs/architecture.md#判断)、[`features/harness-folder.md`の節「置くファイル」](../../.harness/docs/features/harness-folder.md#置くファイル) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

ハーネスのリポジトリの文書の置き場所と形が導入先の`.harness/docs/`と違うと、人には違う理由が見えない。導入先の`.harness/docs/`と同じテンプレートを、このリポジトリの作業で確かめることもできない。

## 判断

要求、要件、全体の設計は`.harness/docs/architecture.md`に、語の意味は`.harness/docs/ubiquitous-language.md`に、構成要素ごとの設計は`.harness/docs/features/`に書く。導入の手引きと判断の記録は、チームの文書（導入先なら、チームがgitに入れて共有する文書）として`docs/`に置き、`architecture.md`の冒頭の表から指す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 導入先と同じ`.harness/docs/`の形（`architecture.md`、`ubiquitous-language.md`、`features/`）にする | 採った | このリポジトリの作業でも`implement-change`が導入先と同じ今の説明を直すので、テンプレートの誤りが導入先より先に見つかる。人が、構造とファイル名がそろうほうを選んだ。 |
| `docs/`に置き、導入先と違う理由を書く | 採らなかった | ファイルを動かさずに済むが、テンプレートをこのリポジトリで確かめられない。 |
| 判断の記録も`.harness/docs/decisions/`へ移す | 採らなかった | 導入先の形に無いフォルダーになる。導入先では比べた案を変更の記録に書くので、足すと同じ判断を2か所に書く導入先が出る。 |

## 結果と失うもの

ハーネスの要求と要件が`.harness/`の中に入るので、初めて読む人は、`README.md`から`.harness/docs/architecture.md`へ進む。導入先のテンプレートを変えたら、このリポジトリの`.harness/docs/`も、新しいテンプレートと同じ形に直す。

## 見直す条件

導入先の`.harness/docs/`に判断の記録の置き場所を足すと決めたら、判断の記録を`docs/`に置くかを見直す。
