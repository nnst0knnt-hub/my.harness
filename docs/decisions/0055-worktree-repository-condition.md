# 導入先のリポジトリとみなすworktreeを、Claude Codeの既定の場所に限る

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-22 |
| 関わる設計 | [`features/protection.md`の節「判定のスクリプト」](../../.harness/docs/features/protection.md#判定のスクリプト) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 判定のスクリプトは、導入先のリポジトリでは、通す形のpushとfetchを確認なしで外に出す。
- worktreeの`.git`はファイルで、作業フォルダーの中にある。エージェントがこのファイルを、サンドボックスの中から書ける場所（例：一時のフォルダー）の偽のリポジトリに向けると、コマンドのリポジトリとClaude Codeの作業フォルダー（`CLAUDE_PROJECT_DIR`）のリポジトリが、同じ偽のリポジトリになる。
- 外のgitは、偽のリポジトリの設定のコマンド（例：`core.sshCommand`）を、人の確認なしにサンドボックスの外で動かす。

## 判断

導入先のリポジトリとみなすのは、`CLAUDE_PROJECT_DIR`が`.claude/worktrees/`の下にあるworktreeの形と、一番上の`.git`のフォルダーのリポジトリの形だけにする。ほかは別のリポジトリとして確認を求め、リモートに問い合わせない。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| `CLAUDE_PROJECT_DIR`の字から、比べる場所を求める | 採った | エージェントは`CLAUDE_PROJECT_DIR`を書けず、記録も設定の読み取りも要らない。知らない形のworktreeは、確認を求める側になる。 |
| サンドボックスが書ける場所を設定のファイルから読み、共通のgitのフォルダーがその中かを比べる | 採らなかった | 会話の中で足す場所と`--add-dir`の場所は設定のファイルに無く、一覧が欠けると偽のリポジトリを通す。 |
| セッションの始めに、共通のgitのフォルダーの番号（dev:inode）を書き込めない場所に記録して比べる | 採らなかった | 前のセッションが書き換えた`.git`を本物として記録し、記録の置き場所と消す時期も要る。 |
| `CLAUDE_PROJECT_DIR`がworktreeなら、いつも確認を求める | 採らなかった | Claude Codeが作るworktreeでも、通す形のpushとfetchに確認が出て、確認が形だけになる。 |

## 結果と失うもの

`.claude/worktrees/`の外のworktree（例：`git worktree add ../x`で作ったもの）で始めたセッションでは、通すか確認を求めるpushとfetchと`glab`が、いつも確認になる。そこで`.git`のファイルを偽の`.git`のフォルダーに置き換える形は、閉じられない。

## 見直す条件

Claude Codeが、フックの入力か環境変数で、worktreeのメインのリポジトリを渡すようになったときに見直す。

## 出典

- [Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)の節「Start Claude in a worktree」：「By default, the worktree is created under `.claude/worktrees/<name>/` at your repository root」、節「Replace worktree creation with a hook」：「including placing worktrees somewhere other than `.claude/worktrees/`.」（確かめた日：2026-11-23）
