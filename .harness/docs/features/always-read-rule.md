# 常に読むルール

| 項目 | 内容 |
|---|---|
| 確かめたコミット | `b7d78e4` |
| 関わる変更の記録 | なし |

常に読むルールは、共通のルール（ハーネスのリポジトリの`rules/always-read.md`）と、導入先ごとのルール（導入先の`.harness/rules/always-read.md`）をまとめた呼び名である。`SessionStart`のフック（Claude Codeがセッションの始めに動かすスクリプト）が、2つの本文をエージェントへ渡す。この文書には、置き場所、字数の上限、上限を超えたときにフックが省くもの、サブエージェントへの渡し方を書く。

## 背景

人は、同じことをセッションごとに何度も指摘することがある（[`architecture.md`の節「背景」](../architecture.md#背景)）。エージェントが毎回守ることは、作業の種類に関係なく、セッションの始めにエージェントへ渡す必要がある。

## 要求

常に読むルールは、`architecture.md`の名前付きの要件「毎回のルール」（[節「作業の要件」](../architecture.md#作業の要件)）を満たす。ルールが長いと守られにくいので、フックが渡す量を、フックの上限より短く保つ。

## 業務のルール

フックが渡すものと、字数の上限は、次のとおりである。

| 渡すもの | 置き場所 | 字数の上限 |
|---|---|---|
| 共通のルール | ハーネスのリポジトリの`rules/always-read.md` | 3,000字（目安） |
| 導入先ごとのルール | 導入先の`.harness/rules/always-read.md` | 3,000字（目安） |
| フックの出力の全体 | 上の2つに、ハーネスの場所、メインの作業フォルダー、文書の目次、環境の状態を足したもの | 8,000字 |

| ルール | 理由 |
|---|---|
| フックの出力の全体を、8,000字以内にする。 | フックが渡せる上限は10,000字で、超えると、エージェントに渡るのはファイルの場所と先頭の2,000字だけになり、共通のルールも途中で切れる（Hooks reference）。8,000字は、上限の8割である。 |
| 2つのルールの本文は、それぞれ3,000字を目安にする。 | 3,000字に根拠の資料は無い。公式の文書は`CLAUDE.md`を200行より短くするよう勧め、長いと守られにくいとしている（How Claude remembers your project）。 |
| フックは、出力の全体の字数だけで省くかを決める。導入先ごとのルールが3,000字を超えても、全体が8,000字以内なら本文を渡す。 | フックの上限にかかるのは全体の字数で、3,000字は目安である。 |
| 3,000字は、共通のルールではCIが確かめ、導入先ごとのルールでは書く側のスキル（`configure-repository`と`add-rule`）が確かめる。 | フックは目安の超過で本文を省かないので、書くときに確かめる。 |
| 字数は、UTF-8の続きのバイトを除き、改行を含めて数える（`scripts/find-long-rule.sh`と同じ数え方）。 | ロケールと`wc`の実装に依らず、手元とCIで同じ数になる。 |
| 導入先で書き方を決める順は、共通のルールに置く。導入のときに読む既存の書き方の表は、`configure-repository`の`references/`に置く。 | 前者は文章を書くたびに使い、後者は導入のときにだけ使う。 |
| フックは、`.harness/`のファイルがシンボリックリンクなら、たどらずに「読めない」と渡す。 | フックは権限とサンドボックスの外で動く。リンク先が秘密情報（例：`.env`）なら、読み取りを止める権限のルールを通らずに、中身が文脈に入る。 |
| レビュー役と並行の実装役（worktreeで1つの作業を実装するサブエージェント）は、最初に常に読むルールの2つを自分で読む。ハーネスの場所とメインの作業フォルダーは、呼ぶ側の本体の会話が依頼文で渡す。 | フックの出力は、このサブエージェントの始めの文脈に入らない（この文書の節「前提」）。 |
| レビュー役は、共通のルールをプラグインの場所（定義の本文の`${CLAUDE_PLUGIN_ROOT}`）から読み、導入先ごとのルールを、依頼文で受け取ったメインの作業フォルダーから読む。並行の実装役は、両方を依頼文で受け取った場所から読む。 | レビュー役の定義はプラグインの中にあり、Claude Codeが`${CLAUDE_PLUGIN_ROOT}`をプラグインの絶対パスに置き換える。実装役は定義のファイルを持たないサブエージェントで、依頼文のほかに場所を知る方法が無い。 |

出力の全体が8,000字を超えたら、フックは次の順に省く。共通のルールは、どの段でも省かない。

1. 導入先ごとのルールの本文を省き、場所と「開いて読む」の文だけを渡す。
2. それでも超えたら、導入先ごとのルールの本文を戻し、文書の目次を場所だけにする。
3. それでも超えたら、導入先ごとのルールと文書の目次の両方を、場所だけにする。

2で本文を戻すのは、目次だけが大きい導入先でも、ルールの本文を渡せるようにするためである。

## 関わるコードの名前

役割は、[`architecture.md`の節「コードの配置」](../architecture.md#コードの配置)に書く。

- `rules/always-read.md`
- `hooks/print-session-context.sh`
- `scripts/find-long-rule.sh`

## 前提

| 前提 | 理由 |
|---|---|
| `SessionStart`のフックの出力は、フォーク（本体の会話の文脈を引き継ぐサブエージェント）でないサブエージェントの始めの文脈に入らない。 | 公式の文書の、フォークでないサブエージェントの始めの文脈の一覧に、フックの出力が無い（Create custom subagents）。 |

## 判断

| 判断 | 誰が決めたか | 理由 |
|---|---|---|
| ルールの本文は、ハーネスのリポジトリに1か所だけ置き、導入先のgitに入れない。Claude Codeでは、プラグインの`SessionStart`のフックで、2つのルールを渡す。 | [判断の記録](../../../docs/decisions/0002-rule-location.md) | 導入先のgitを変えずに、どの導入先にも同じ共通のルールを渡せる。 |
| 常に読むルールには、判断の基準と短い指示だけを入れ、書き方の本文は書く前にファイルを開いて読ませる。 | [判断の記録](../../../docs/decisions/0004-always-read-rule-scope.md) | 毎回渡す量を、字数の上限の中に保つ。 |

## 出典

- [Hooks reference](https://code.claude.com/docs/en/hooks)の節「JSON output」：「A hook's additionalContext, systemMessage, and initialUserMessage strings, and its plain stdout, are capped at 10,000 characters」（確かめた日：2026-10-23）
- 同じ節：「It replaces the output with the file path and a preview of up to the first 2,000 characters.」（確かめた日：2026-11-14）
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)の節「Write effective instructions」：「target under 200 lines per CLAUDE.md file.」、「Longer files consume more context and reduce adherence.」（確かめた日：2026-10-23）
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)の節「What loads at startup」：「A non-fork subagent's initial context contains:」に続く一覧に、フックの出力が無いこと（確かめた日：2026-11-14）
