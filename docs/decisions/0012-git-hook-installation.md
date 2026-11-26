# gitのフックを、gitの設定で足す

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-23 |
| 関わる設計 | [`features/protection.md`の節「gitのフック」](../../.harness/docs/features/protection.md#gitのフック) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

`pre-push`と`pre-commit`を、導入先に入れる。導入先には、huskyのような既存のフックがあることがある。

## 判断

gitの設定でフックを足す（`hook.<名前>.command`）。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| gitの設定でフックを足す | 採った | 既存のフックと衝突せず、方法が1つで済む。gitの公式の文書が示す方法である。 |
| `.git/hooks/`に置く | 採らなかった | huskyのような既存のフックがあると、置けない。 |
| gitのバージョンで分ける（2.54より古いgitでは、空いているときだけ`.git/hooks/`に置く） | 採らなかった | 動く範囲はいちばん広いが、方法が2つになり、手順とテストも2通りになる。 |

## 結果と失うもの

git 2.54より古いgitでは動かない。失うのは`pre-push`と`pre-commit`の確かめで、ほかの仕組み（フック、権限、サンドボックス）はgitのバージョンに依らず動く。失うものは、エージェントと環境を確かめるスクリプトが、`architecture.md`の要件「守れないことの提示」のとおりに人に示し、gitを上げれば直る。そのため、`architecture.md`の節「優先順位」の1番目（セキュリティ上必須の所）を弱めるとは扱わず、2番目のシンプルさを3番目の環境に依存しないことより先にして、方法を1つにした。

## 見直す条件

導入のときに、環境を確かめるスクリプト（`scripts/print-protection-status.sh`）で、gitが2.54より古く、上げられないとわかったら（例：管理者の権限が無く、ツールを入れられないPC）、バージョンで分ける案を検討する。

## 出典

- [git-hook 2.54.0](https://git-scm.com/docs/git-hook/2.54.0)の節「DESCRIPTION」：「git config set hook.<some-name>.command <path-to-script>」（確かめた日：2026-10-23）
