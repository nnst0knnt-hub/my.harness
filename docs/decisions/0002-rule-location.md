# ルールの本文をハーネスに1か所だけ置き、`SessionStart`のフックで渡す

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-23 |
| 関わる設計 | [`features/always-read-rule.md`](../../.harness/docs/features/always-read-rule.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

ハーネスは、まず作者が自分だけで使い、チームの合意が無いうちは導入先のgitに何も入れない（[`.harness/docs/architecture.md`の節「制約」](../../.harness/docs/architecture.md#制約)）。ルールの本文を導入先ごとにコピーすると、直すたびにすべての導入先を直すことになる。常に読むルールは共通のルールと導入先ごとのルールの2つで、導入先ごとのルールは導入先によって場所が変わる。

## 判断

ルールの本文は、ハーネスのリポジトリに1か所だけ置き、導入先のgitに入れない。Claude Codeでは、プラグインの`SessionStart`のフックで、セッションの始めに共通のルールと導入先ごとのルールの両方を渡す。

## 案

### 置き場所

| 案 | 結果 | 理由 |
|---|---|---|
| ハーネスに1か所だけ置き、導入先のgitに入らない個人の設定から読み込ませる | 採った | 導入先のgitを変えずに、自分だけで使い始められる。 |
| 導入先のリポジトリに`AGENTS.md`と`.agents/skills`を置く | 採らなかった | エージェントをまたいで読まれるが、リポジトリに置く仕組みで、置くにはチームの合意が要る。Claude Codeは、`CLAUDE.md`があると`AGENTS.md`を既定で読まない。 |

### 渡し方

| 案 | 結果 | 理由 |
|---|---|---|
| `SessionStart`のフックで渡す | 採った | 導入先ごとに読むファイルが変わっても、1つの方法で渡せる。 |
| `~/.claude/CLAUDE.md`にimportの行を書く | 採らなかった | importは固定のパスしか書けず、導入先ごとに変わるルールを渡せない。渡す方法が、フックとimportの2つになる。 |
| プラグインの中に`CLAUDE.md`を置く | 採らなかった | プラグインのルートの`CLAUDE.md`は読まれない。 |

## 結果と失うもの

チームに広げるまでは、チームの人がハーネスのルールを導入先のリポジトリで読めない。フックが渡せる字数に上限があるので、常に読むルールの字数の上限を決め、確認のスクリプトで確かめる。

## 出典

- [AGENTS.md](https://agents.md/)の節「How to use AGENTS.md?」：「Create an AGENTS.md file at the root of the repository.」（確かめた日：2026-10-23）
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)の節「AGENTS.md」：表の「An `AGENTS.md` and a `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it」の行の「Your `CLAUDE.md` files only」（確かめた日：2026-10-23）
- [Plugin manifest reference](https://code.claude.com/docs/en/plugins-reference)の節「Standard layout」：「A CLAUDE.md at the plugin root isn't loaded as context」（確かめた日：2026-10-23）
