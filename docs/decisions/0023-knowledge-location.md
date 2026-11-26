# 導入先について理解したことと作業の進み具合を、自動の記憶ではなく`.harness/docs/`に書く

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-11 |
| 関わる設計 | [`features/harness-folder.md`の節「自動の記憶との分け方」「前提」](../../.harness/docs/features/harness-folder.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeの自動の記憶（Claude Codeが、PCごとに自分で書いて次のセッションで読むメモ）が保存するメモの種類には、コードから読み取れない進行中の作業と決めたことがある。`.harness/docs/`にも、導入先について理解したこと（例：背景、導入先の業務のルール、理由）と、作業の進み具合（例：変更の記録の作業の手順のチェック）を書く。書く先を決めないと、同じことがスキルごとに違う場所に書かれ、次のセッションのエージェントがどこを探すかを決められない。

## 判断

導入先について理解したことと作業の進み具合は`.harness/docs/`に書き、スキルには自動の記憶へ書かせない。書く対象と弱点は、冒頭の表の「関わる設計」に書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| `.harness/docs/`に書き、スキルは自動の記憶に書かない | 採った | ほかのエージェントもリポジトリの中のファイルとして読め、スキルが決めた形で探せる（例：ブランチ名から変更の記録を探す）。チームに広げるときに、`.git/info/exclude`から外してコミットできる。 |
| `.harness/docs/`と自動の記憶の両方に書く | 採らなかった | 同じことが2か所にあり、片方だけが古くなる。 |
| 自動の記憶だけに書く | 採らなかった | Claude Codeだけが読み込むので、要件「エージェントに依存しない作り」（[`.harness/docs/architecture.md`の節「構成の要件」](../../.harness/docs/architecture.md#構成の要件)）に合わない。既定ではリポジトリの外のフォルダー（`~/.claude/projects/<project>/memory/`）に、人の好みのような個人のメモと一緒に置かれるので、チームに広げるときにそのままコミットできない。 |

## 結果と失うもの

導入先の`.harness/docs/`がほかのPCで読めないことは、自動の記憶も同じである（[`features/skill.md`](../../.harness/docs/features/skill.md)）。`.harness/docs/`を選んで新しく増える弱点は、gitで追跡しないファイルとして、導入先のフォルダーと一緒に消えることである（例：`git clean -fdx`、`git clean -fdX`、cloneのし直し）。自動の記憶は既定ではリポジトリの外にあるので、これらの操作では消えない。

## 出典

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)の節「Auto memory」：「project: ongoing work, deadlines, and decisions that Claude can't derive from the code or git history」（確かめた日：2026-11-14）
- 同じ節：「user: your role, expertise, and working preferences」（確かめた日：2026-11-14）
- 同じページの節「Storage location」：「Each project gets its own memory directory at `~/.claude/projects/<project>/memory/`.」（確かめた日：2026-11-14）
