# コミットメッセージの止める語は、ハーネスのリポジトリだけ`commit-msg`で止める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「gitのフック」](../../.harness/docs/features/protection.md#gitのフック)、[`CONTRIBUTING.md`の節「機械で確かめるもの」](../../CONTRIBUTING.md#機械で確かめるもの) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 止める語の一覧（`data/banned-word-list.txt`）は、ハーネスの日本語の文章のルールである。
- 導入先のコミットメッセージは、導入先のチームが決めた語と形で書く（例：英語、Conventional Commits）。
- ハーネスのリポジトリのコミットメッセージは、ハーネスの文章のルールで書く。フックが無ければ、書いたあとにエージェントが手で`scripts/find-banned-word.sh`を当てるしかない。

## 判断

このリポジトリだけ、gitの`commit-msg`のフックで、`scripts/find-banned-word.sh`をコミットメッセージに当てる。設定の足し方は、`CONTRIBUTING.md`に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| このリポジトリだけで止める | 採った | 手で当て忘れても、commitのときに止まる。導入先の語と形を止めない。 |
| 導入先にも入れる | 採らなかった | 導入先のチームの語と形を、ハーネスの日本語の一覧で止めてしまう。 |
| 入れず、手で当てるままにする | 採らなかった | 当て忘れると、止める語がコミットメッセージに残る。マージのあとは直せない。 |

## 結果と失うもの

導入先では、今と同じく、エージェントが書いたあとに確認を当てる（[`rules/always-read.md`の節「書く前に読むファイル」](../../rules/always-read.md#書く前に読むファイル)）。`commit-msg`も`--no-verify`で飛ばせるので、権限のdenyのルールが補助として止める。

## 見直す条件

導入先で、止める語の入ったコミットメッセージへの指摘が続いたときに見直す。

## 出典

- [githooks](https://git-scm.com/docs/githooks)の節「commit-msg」：「Exiting with a non-zero status causes the command to abort.」（確かめた日：2026-11-16）
