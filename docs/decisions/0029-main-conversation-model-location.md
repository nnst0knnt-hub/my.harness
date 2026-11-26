# 本体の会話のモデルとeffortを、導入先の`.claude/settings.local.json`に書く

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-11 |
| 関わる設計 | [`.harness/docs/architecture.md`の節「導入」](../../.harness/docs/architecture.md#導入) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

本体の会話のモデルとeffortで、作業の精度と使用量が変わる。導入先ごとに、求める精度と、人が使える使用量は違う。Claude Codeの設定には、モデルとeffortを決める場所が複数あり、どこに書くかで、設定が当たる範囲と、人が途中で変えられるかが変わる。

## 判断

本体の会話のモデルとeffortは、導入先の`.claude/settings.local.json`の`model`と`effortLevel`に書く。`configure-repository`が人に聞いて書き、すでに値があれば上書きせず、人に示して決めてもらう。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 導入先の`.claude/settings.local.json` | 採った | その導入先の自分だけの設定で、導入先のgitに入らない。人が途中で`/model`や`/effort`で変えられる。 |
| 人の設定（`~/.claude/settings.json`） | 採らなかった | PCのすべてのリポジトリに当たり、導入先ごとに決められない。 |
| 共有のプロジェクトの設定（`.claude/settings.json`） | 採らなかった | 導入先のgitに入り、`architecture.md`の要件「導入先を変えない」に反する。 |
| 環境変数（`ANTHROPIC_MODEL`、`CLAUDE_CODE_EFFORT_LEVEL`） | 採らなかった | 設定のファイルより先に当たる。effortは、人が途中で`/effort`を選んでも変えられない。 |
| スキルのfrontmatterの`model`と`effort` | 採らなかった | その回の返事の間だけ当たり、Agent Skillsの仕様の項目にも無い。 |
| プラグインの設定の`agent` | 採らなかった | 本体の会話がプラグインのエージェントとして動き、Claude Codeの既定の指示の文がそのエージェントの本文に替わる。 |

## 結果と失うもの

導入先ごとに、人がモデルとeffortを決める手間が1回増える。勧める値は、[値の判断の記録](0032-main-conversation-model-value.md)に書く。

人が`/model`や`/effort`で既定として保存した値は、人の設定に入り、導入先の値のほうが先に当たる。そのため、その導入先では次のセッションで導入先の値に戻り、続けて変えるには`.claude/settings.local.json`を直す。

## 見直す条件

Claude Codeの設定の置き場所か、effortを決める順が変わったときに見直す。

## 出典

- [Model configuration](https://code.claude.com/docs/en/model-config)の節「Setting your model」：「configure permanently in your settings file using the `model` field」（確かめた日：2026-11-14）
- 同じページの節「Adjust effort level」：「Claude Code resolves the session's effort level in this order, taking the first that applies」と、その1番目の「The `CLAUDE_CODE_EFFORT_LEVEL` environment variable」（確かめた日：2026-11-14）
- 同じ節：「A top-level `effortLevel` in project, local, or managed settings, or one passed with `--settings`, applies to every model.」（確かめた日：2026-11-14）
- 同じページの節「Setting your model」：「`/model` saves your choice as the default for new sessions by writing the `model` field in your user settings.」（確かめた日：2026-11-15）
- 同じページの節「Adjust effort level」：「Claude Code saves the level per model, under the `modelSettings` key in your user settings, so each model keeps its own saved level.」（確かめた日：2026-11-15）
- [All settings](https://code.claude.com/docs/en/settings-reference)の節「`modelSettings`」：「the highest-precedence settings file that sets either an `effortLevel` for that model or a top-level `effortLevel` that applies to that model decides」（確かめた日：2026-11-24）
- [Settings files and precedence](https://code.claude.com/docs/en/settings)の節「Settings precedence」：「Settings precedence, highest first: managed settings, command line, project local, shared project, user.」（確かめた日：2026-11-15）
- 同じ節：「`ANTHROPIC_MODEL` exported in your shell applies over the `model` key from any file」（確かめた日：2026-11-15）
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)の節「Invoke subagents explicitly」：「a custom subagent's system prompt replaces the default Claude Code system prompt entirely」（確かめた日：2026-11-14）
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)の節「Frontmatter reference」：`model`の行の「The override applies for the rest of the current turn and isn't saved to settings.」（確かめた日：2026-11-14）
