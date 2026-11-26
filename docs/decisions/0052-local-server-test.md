# 手元のサーバーを使うテストは、人がClaude Codeの外で動かす形を勧める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-23 |
| 関わる設計 | [`skills/configure-repository/SKILL.md`の節「手元のサーバーを使うテストの案」](../../skills/configure-repository/SKILL.md#手元のサーバーを使うテストの案)、[`features/protection.md`の節「環境を確かめるスクリプト」](../../.harness/docs/features/protection.md#環境を確かめるスクリプト) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- macOSのサンドボックスの中のコマンドは、既定ではポートで待ち受けられず、localhostで動くほかのサーバーにもつなげない。LinuxとWSL2では、コマンドのlocalhostはそのコマンドだけのもので、手元で動くほかのサーバー（例：コンテナーのDB）に届かない。
- 公式の文書の直し方は、macOSでは`allowLocalBinding`、LinuxとWSL2では`excludedCommands`である。
- 緩める設定の一覧の`allowLocalBinding`の行が1つだと、環境を確かめるスクリプトは、導入先に足した`true`も`[働かない]`で示し、毎回1で終わる。

## 判断

`configure-repository`が当たるテストを見つけたら、3つの案を起きることとともに示し、人が選ぶ。勧めは、導入先ごとのルールに1行書いて人が外で動かす形である。緩める設定の一覧の`allowLocalBinding`の行は、PCの設定の値を`[働かない]`、導入先の設定の値を`[確かめる]`に分ける。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 人が選び、勧めは人が外で動かす形にし、一覧の行を分ける | 採った | 保護は緩まず、テストの結果は変更が当たるたびに人が渡す。緩める形を人が選んだ導入先でも、環境を確かめるスクリプトが毎回1で終わらない。 |
| 勧めを、LinuxとWSL2では`excludedCommands`、macOSでは`allowLocalBinding`にする | 採らなかった | エージェントがテストを動かせるが、エージェントが書いたテストのコードがサンドボックスの外で動くか、認証の無いlocalhostのサービスを通して外に届く。 |
| `configure-repository`に足さず、手引きに1行足す | 採らなかった | テストが失敗してから、人が決めることになる。 |

## 結果と失うもの

- 人が外で動かす形では、そのテストのたびに、エージェントがコマンドを示して人の出力を待つ。
- 緩める形を選んだ導入先では、環境を確かめるスクリプトの`[確かめる]`が1つ増える。
- 管理者がサンドボックスを必須にした導入先では、導入先の設定に書いた緩める2つの形が使われない。

## 見直す条件

人が出力を渡す回数が多く、作業が止まる導入先が出たら、テストのコマンドを外に出す形と比べ直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「A command fails to reach a server on localhost」：「By default, a sandboxed command can't connect directly to a server that's running on your machine outside the sandbox」、「A localhost service that doesn't require authentication, such as a debugger, can then act for the command outside the sandbox」、「The command can listen on a port and reach servers it started itself.」（確かめた日：2026-11-23）
- 同じページの節「Repository settings under an admin-required sandbox」：「It ignores these settings in a repository's `.claude/settings.json` and `.claude/settings.local.json`」（確かめた日：2026-11-23）
