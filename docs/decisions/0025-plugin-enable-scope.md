# ハーネスのプラグインを、PCの全体ではなく導入先ごとに有効にする

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-11 |
| 関わる設計 | [`.harness/docs/architecture.md`の節「導入」](../../.harness/docs/architecture.md#導入) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeのプラグインは、有効にする範囲を、PCのすべてのリポジトリ（user）、リポジトリで作業する全員（project）、そのリポジトリの自分だけ（local）から選ぶ。ハーネスのプラグインは、セッションの始めにルールを渡し、スキルとレビュー役を使えるようにする。範囲を決めないと、ハーネスを入れていないリポジトリにもルールが渡るか、導入先のgitに設定のファイルが入る。

## 判断

ハーネスのプラグインは、導入先ごとに`claude plugin install --scope local`で有効にする。Claude Codeは、有効にしたことを導入先の`.claude/settings.local.json`の`enabledPlugins`に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 導入先ごと（local） | 採った | 導入したリポジトリだけでルールとスキルを使え、導入先のgitに入らない。 |
| PCのすべてのリポジトリ（user、`~/.claude/settings.json`） | 採らなかった | 導入していないリポジトリでもルールが渡り、導入先ごとのルールが無いまま、ハーネスの手順で作業が進む。 |
| リポジトリで作業する全員（project、`.claude/settings.json`） | 採らなかった | 設定のファイルが導入先のgitに入り、`architecture.md`の要件「導入先を変えない」に反する。 |

## 結果と失うもの

導入先ごとに、コマンドを1回動かす手間が増える。導入のスキルの`configure-repository`はプラグインの中にあり、有効にする前の導入先では呼べないので、このコマンドだけは`configure-repository`より先に人が動かす。

## 見直す条件

チームに広げて、プラグインを導入先のgitの設定で有効にすると決めたときに見直す。

## 出典

- [Install and manage plugins](https://code.claude.com/docs/en/discover-plugins)の節「Choose an install scope」：「Local scope: the plugin is enabled for you in this repository only. The entry goes in `.claude/settings.local.json`.」（確かめた日：2026-11-14）
- 同じ節：「User scope: the plugin is enabled for you in every project on this machine.」（確かめた日：2026-11-14）
- 同じ節：「The entry goes in `.claude/settings.json`, which you commit.」（確かめた日：2026-11-14）
