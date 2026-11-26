# `configure-repository`は、本体の会話にOpusとeffort `high`を勧める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-15 |
| 関わる設計 | [`skills/configure-repository/SKILL.md`](../../skills/configure-repository/SKILL.md)の節「案の示し方」 |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

`configure-repository`は、導入先ごとに本体の会話のモデルとeffortを人に聞く（[判断の記録](0029-main-conversation-model-location.md)）。公式の記事は、多くの作業ではモデルの既定のeffortを使い、仕事の種類で丁寧さを先にしたいときに変えるよう勧める。ハーネスの作業は、主に既存のプロダクトの改修で、完了と言う前にテストとレビューで確かめる。

## 判断

本体の会話には、Opus（別名`opus`）とeffort `high`を勧める。人が使用量を減らしたいと言えば、Sonnet（別名`sonnet`）か、effort `medium`を示す。

## 案

### モデル

| 案 | 結果 | 理由 |
|---|---|---|
| Opus（別名`opus`） | 採った | 本体の会話は、あいまいな依頼から要件と設計を決める。公式の記事は、複雑かあいまいな作業に大きいモデルを勧める。 |
| Sonnet（別名`sonnet`） | 採らなかった | 使用量を減らすときに示す。公式の記事は決まった手順の作業に小さいモデルを勧めるが、本体の会話は計画も行う。 |
| Fable | 採らなかった | プランによっては追加の料金から払われる（[判断の記録](0024-review-model.md)）。 |
| モデルの名前（例：`claude-opus-5-5`） | 採らなかった | 新しいモデルが出ても替わらず、別名は新しいモデルに替わる。 |

### effort

| 案 | 結果 | 理由 |
|---|---|---|
| `high` | 採った | 公式の文書は、確かめが大事な作業と、既存のコードの不具合の修正に当てる。 |
| `medium`（Opusの既定） | 採らなかった | 使用量を減らすときに示す。公式の文書は、範囲のはっきりした日々の作業（例：新しい機能の実装）に当てる。 |
| `xhigh` | 採らなかった | 公式の文書は、使う量が増えることだけを書き、当てる作業を書かない。ハーネスのリポジトリのセッションの記録（Claude Codeが残す会話のjsonl）では、本体の会話が使用量の半分以上を占めた。 |

## 結果と失うもの

`high`は、既定の`medium`より使用量が増える。勧める値は、レビュー役と違って測らず、公式の文書が作業の種類に当てる値から決めた。

## 見直す条件

- 新しいモデルが出たとき
- 公式の文書のeffortの勧めが変わったとき
- 導入先で、確かめの抜け（例：テストを動かさない、ファイルを読み飛ばす）か、使用量の上限に当たることが続いたとき

## 出典

- [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code)の節「Picking an effort level」：「for most tasks you should use the model’s default effort level」、「Choose it deliberately when you have a strong preference for thoroughness or speed based on your domain or the type of work you do.」（確かめた日：2026-11-15）
- 同じ記事の節「Key takeaways」：「Choose smaller models for more routine tasks and larger models for more complex or ambiguous tasks.」（確かめた日：2026-11-15）
- [Model configuration](https://code.claude.com/docs/en/model-config)の節「Choose an effort level」：`high`の行の「Work where verification matters or edge cases are likely, such as fixing a bug in an existing codebase」（確かめた日：2026-11-15）
- 同じ節：`medium`の行の「On Opus 5.5 and Sonnet 5.5, it fits day-to-day engineering work with a clear scope, such as implementing a new feature」（確かめた日：2026-11-15）
- 同じ節：「Opus 5.5 defaults to `medium`, one level below Opus 5's default of `high`.」（確かめた日：2026-11-15）
- 同じ節：`xhigh`の行の「Deeper reasoning at higher token spend.」（確かめた日：2026-11-15）
- 同じページの節「Model aliases」：「Aliases point to the recommended version for your provider and update over time.」（確かめた日：2026-11-15）
