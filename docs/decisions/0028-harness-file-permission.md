# ハーネスのファイルの読み取りと`scripts/`のスクリプトの実行を、PCごとの設定で許す

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-14 |
| 関わる設計 | [`.harness/docs/architecture.md`の節「導入」](../../.harness/docs/architecture.md#導入) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeは、作業フォルダーの外のファイルを読むときに確認を求める。ハーネスのリポジトリ以外の導入先では、ハーネスのファイル（例：`rules/quality.md`、スキルの`assets/`、`scripts/`の、文章を確かめるスクリプト）が作業フォルダーの外にある。そのため、スキルを使うたびに、読むファイルと動かすスクリプトの数だけ確認が出る。

## 判断

PCごとの設定（`~/.claude/settings.json`）の権限で、ハーネスの場所の読み取りと、`scripts/`のスクリプト（読み取りと表示だけをする）の実行だけを許す。ハーネスのファイルの編集は、確認を求めるまま残す。実際の設定と手順は、導入の手引き（`docs/setup-guide.md`）に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| PCごとの設定で、読み取りと`scripts/`のスクリプトの実行だけを許す | 採った | 1回の設定で、そのPCのすべての導入先に当てはまる。`architecture.md`の節「導入」で権限を置く、PCごとの設定と同じ置き場所である。 |
| 導入先ごとに、ハーネスの場所を作業フォルダーに足す（`additionalDirectories`） | 採らなかった | 導入先ごとに同じ設定を書くことになる。足したフォルダーは作業フォルダーと同じ扱いになり、編集を確認なしで受け入れるモード（`acceptEdits`）では、ハーネスのファイルの編集にも確認が出なくなる。 |
| 確認が出るたびに、人が答える | 採らなかった | スキルを使うたびに確認が続き、人の手間が増える。 |

## 結果と失うもの

許すパスは、ハーネスの場所の絶対パスで書く。ハーネスのリポジトリを別のフォルダーへ移すと、許したパスと合わなくなり、また確認が出る。

## 見直す条件

ハーネスを手元のパス以外から入れると決めたとき（例：ほかの人のPCで、GitHubから入れる）に見直す。

## 出典

- [Configure permissions](https://code.claude.com/docs/en/permissions)の節「Permission system」：表のRead-onlyの行の「No, within the working directory and additional directories」（確かめた日：2026-11-14）
- 同じページの節「Additional directories grant file access, not configuration」：「Adding a directory extends where Claude can read and edit files.」（確かめた日：2026-11-14）
- 同じページの節「Permission modes」：`acceptEdits`の行の「for paths in the working directory or `additionalDirectories`」（確かめた日：2026-11-14）
- 同じページの節「How path patterns match」：「Absolute path from filesystem root」（確かめた日：2026-11-14）
