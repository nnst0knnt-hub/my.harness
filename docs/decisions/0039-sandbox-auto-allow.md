# サンドボックスの中のコマンドを確認なしで動かす

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「サンドボックス」](../../.harness/docs/features/protection.md#サンドボックス) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- PCの設定に`sandbox.enabled`だけを書くと、サンドボックスの中のコマンドも、ふつうの権限の確認を通る。作業フォルダーの外へのリダイレクト（例：Claude Codeがセッションごとに用意する一時のフォルダーのscratchpadへの下書き）と、前に変数を置いたコマンドに確認が出る。
- 下書きをscratchpadに書くこと（`rules/git.md`）は、確認を求めない作業である。
- 中のコマンドを確認なしで動かす設定でも、`cd`、変数、`$(...)`を含むコマンドは、ふつうの権限の流れを通る。

## 判断

PCの設定に`autoAllowBashIfSandboxed: true`を足し、サンドボックスの中のコマンドを確認なしで動かす。設定でも確認が出る形（`cd`、変数、`$(...)`）を使わない書き方は、`SessionStart`のフックとレビュー役の定義（`agents/reviewer.md`）が渡す。レビュー役には、一時のフォルダーで動かす確かめで`git push`、`gh`、`glab`を動かさないことも渡す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 設定を足し、書き方も渡す | 採った | 中のコマンドは読み書きと通信の制限の内で動き、denyのルールと中身を指すaskのルール（例：`Bash(npm publish *)`）は当たり続ける。設定で消えない確認は、書き方で避ける。 |
| 設定だけを足す | 採らなかった | 前に変数を置いたコマンドは対象から外れ、確認が残る。 |
| 書き方だけを渡す | 採らなかった | エージェントが守らないと確認が出る。Writeで書く指示があっても、リダイレクトを使うことがあった。 |

## 結果と失うもの

手動のモードでは、作業フォルダーの中を消すコマンド（例：`rm -rf`、`git reset --hard`）にも確認が出ない。auto modeでは、サーバーの判定役が中のコマンドを見るセッションなら、判定役が止める。取り消せない操作の前の確認は、常に読むルールの節「人に確認を求める場面」のとおりにエージェントが守る。

外に出すコマンド（`git push`、`git fetch`、`glab`）はフックが書き換えるので、もとのコマンドを指すaskのルール（例：`Bash(git push *)`）は当たらない。環境を確かめるスクリプトが、そのルールを働かないと示す。

## 見直す条件

サンドボックスの中のコマンドで、消してはいけないものを消す事故が起きたとき、またはClaude Codeの自動で許す動きが変わったときに見直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Auto-allow mode」：「Claude Code approves a command automatically, with no prompt, when the command runs inside the sandbox.」、「Content-scoped ask rules like `Bash(git push *)` still force a prompt even for sandboxed commands」、「A command in a form that a `Bash` deny rule matches is still blocked」（確かめた日：2026-11-17）
- 同じページの同じ節：「Some sandboxed commands also go through the regular permission flow instead of being approved automatically. This happens with commands such as `FOO=bar npm test`, where a variable set in front of a command can change which program runs, and with `make CC=clang` or `eval "ls"`.」（確かめた日：2026-11-16）
- 同じページの同じ節：「Auto-allow mode works independently of your permission mode setting, with three exceptions: plan mode, an auto mode command that carries per-command allowed domains, and server-side classifier review of sandboxed commands in auto mode.」（確かめた日：2026-11-16）
- 同じページの節「`/sandbox` prints `Sandbox settings not changed`」：「This turns on regular permissions mode. For auto-allow mode, also set `sandbox.autoAllowBashIfSandboxed` to `true`.」（確かめた日：2026-11-16）
- [Configure permissions](https://code.claude.com/docs/en/permissions)の節「Redirections」：「for `> file`, `>> file`, or `2> file`, the check covers your `Edit` allow and deny rules, protected paths, and the working directories.」（確かめた日：2026-11-16）
- [Choose a permission mode](https://code.claude.com/docs/en/permission-modes)の節「How the classifier evaluates actions」：「In a session with server-side classifier review, read-only and sandboxed shell commands wait for that review and are blocked if it flags them」（確かめた日：2026-11-16）
