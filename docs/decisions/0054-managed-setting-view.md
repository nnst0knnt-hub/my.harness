# 管理者の設定は、人が`/status`で見る

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-23 |
| 関わる設計 | [`docs/setup-guide.md`の節「環境を確かめる」](../setup-guide.md#環境を確かめる)、[`features/protection.md`の節「前提」](../../.harness/docs/features/protection.md#前提) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 管理者の設定は、ハーネスの保護を外せる。`allowManagedHooksOnly`はハーネスのフックを、`allowManagedPermissionRulesOnly`は`~/.claude/settings.json`の権限のルールを使わなくする。
- 管理者の設定は、ファイルのほかに、MDMのようなファイルでない形でも配られる。
- 管理者の設定がサンドボックスを必須にすると、導入先の設定の値の一部（例：通信先、`excludedCommands`、`allowWrite`、`allowUnixSockets`、`allowLocalBinding`の`true`）は使われない。

## 判断

環境を確かめるスクリプトでは、管理者の設定のキーを示さない。導入の手引きに、`/status`の`Setting sources`の行で管理者の設定を見て、`allowManagedHooksOnly`か`allowManagedPermissionRulesOnly`が入っていないかを管理者に確かめる文を書く。必須のサンドボックスでは、要る値を`~/.claude/settings.json`に書く文も書く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 手引きの文で、人が`/status`を見る | 採った | Claude Codeが読み込んだ管理者の設定を、配り方に依らずに見られる。 |
| 環境を確かめるスクリプトで、管理者の設定のファイルのキーを示す | 採らなかった | ファイルでない管理者の設定を読めず、ファイルの場所と形が変わったときに黙って誤る。 |
| セッションの始めのフックで示す | 採らなかった | `allowManagedHooksOnly`はセッションの始めのフックも止めるので、示したい場面で動かない。 |

## 結果と失うもの

人が`/status`を見なければ、管理者の設定がハーネスの保護を外していても気づかない。管理者の設定の中身は人が管理者に確かめ、ハーネスは確かめた結果を記録しない。

## 見直す条件

管理者の設定のあるPCで、人が`/status`を見落とし、保護が外れたまま作業したことがわかったら、比べ直す。

## 出典

- [Settings files and precedence](https://code.claude.com/docs/en/settings)の節「Check what your organization enforces」：「To see which, run `/status`: the `Setting sources` line names the managed source that applies to you.」（確かめた日：2026-11-23）
- [All settings](https://code.claude.com/docs/en/settings-reference)の表の`allowManagedHooksOnly`の行：「Run only the hooks your organization deploys」、`allowManagedPermissionRulesOnly`の行：「Make managed settings the only settings source of permission rules」（確かめた日：2026-11-23）
- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Repository settings under an admin-required sandbox」：「It ignores these settings in a repository's `.claude/settings.json` and `.claude/settings.local.json`」（確かめた日：2026-11-23）
