# スキルは、フックが渡すハーネスの場所から、ハーネスの`rules/`を読む

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-14 |
| 関わる設計 | [`features/skill.md`](../../.harness/docs/features/skill.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

スキルの手順は、ハーネスの`rules/`のファイル（例：`rules/quality.md`）を読む。導入先では、作業フォルダーは導入先のリポジトリで、ハーネスのリポジトリは別のフォルダーにある。スキルの本文に読む場所の書き方を決めないと、エージェントが導入先の中で`rules/`を探すか、場所を推測する。

## 判断

`SessionStart`のフックが、ハーネスの場所（ハーネスのリポジトリを置いたフォルダーの絶対パス）を渡す。スキルの本文には「ハーネスの`rules/quality.md`」と書き、エージェントは渡された場所から読む。スキルの`references/`と`assets/`は、Agent Skillsの仕様のとおり、スキルのフォルダーからの相対パスで書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| フックが渡すハーネスの場所から読む | 採った | 常に読むルールと同じ書き方で読める。ほかのエージェントでも、セッションの始めに場所を渡せれば、同じ本文で動く。 |
| スキルの本文で`${CLAUDE_PLUGIN_ROOT}`を使う | 採らなかった | Claude Codeがプラグインのスキルでだけ置き換える書き方で、`architecture.md`の要件「エージェントに依存しない作り」に合わない。 |

レビュー役はClaude Codeのサブエージェントで、ほかのエージェントでは使わないので、定義のファイル（`agents/reviewer.md`）の本文で`${CLAUDE_PLUGIN_ROOT}`を使う。

## 結果と失うもの

ハーネスのリポジトリ以外の導入先では、ハーネスのファイルが作業フォルダーの外にあるので、読むたびに確認が出る。そのため、PCごとの設定で読み取りを許す（[判断の記録](0028-harness-file-permission.md)）。フックの出力はサブエージェントの始めの文脈に入らないので、サブエージェントには、呼ぶ側が依頼文でハーネスの場所を渡す。

## 見直す条件

ほかのエージェントで使うと決め、そのエージェントにセッションの始めに文脈を渡す仕組みが無いとわかったときに見直す。

## 出典

- [Extend Claude with skills](https://code.claude.com/docs/en/skills)の節「Available string substitutions」：「In a plugin skill, Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` in the same two places.」（確かめた日：2026-11-14）
- [Specification](https://agentskills.io/specification)（Agent Skills）の節「File references」：「When referencing other files in your skill, use relative paths from the skill root」（確かめた日：2026-11-14）
