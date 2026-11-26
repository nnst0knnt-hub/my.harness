# ツールのキャッシュは、導入先ごとの専用の場所を勧める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-23 |
| 関わる設計 | [`skills/configure-repository/SKILL.md`の節「ツールのキャッシュの案」](../../skills/configure-repository/SKILL.md#ツールのキャッシュの案)、[`features/protection.md`の節「サンドボックス」](../../.harness/docs/features/protection.md#サンドボックス) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- サンドボックスの中のコマンドが書けるのは、作業フォルダー、利用者ごとの一時のフォルダー、足したフォルダーである。ツールのキャッシュ（例：Goの`GOCACHE`）がその外にあると、最初のビルドかテストが書き込みに失敗する。
- 公式の文書は、ツールが外に書くときは、`excludedCommands`より`allowWrite`を勧めている。
- 共有のキャッシュは、サンドボックスの外で動くビルド（例：人の端末、IDE）も使う。

## 判断

`configure-repository`が、キャッシュが書ける場所の外にあるツールを見つけたら、3つの案を起きることとともに示し、人が導入先ごとに選ぶ。勧めは専用のキャッシュで、導入先の設定の`env`でツールの変数をメインの作業フォルダーの`.harness/cache/<ツール>/`の絶対パスにし、`sandbox.filesystem.allowWrite`にも同じパスを足す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 人が選び、勧めは専用のキャッシュ | 採った | 外で動くビルドが使う共有のキャッシュを、サンドボックスの中から書き換えられない。失うのは最初の取り直しとディスクで、フォルダーを消せば戻る。 |
| 人が選び、勧めは共有のキャッシュへの`allowWrite` | 採らなかった | 取り直しは無いが、中から書いたキャッシュを外のビルドが使い、仕込まれたコードが外で動きうる。気づきにくく、キャッシュを消すまで続く。 |
| 案にせず、手引きに直し方だけ書く | 採らなかった | ツールごとに、最初のビルドかテストが確認なしに止まってから、人が決めることになる。 |

## 結果と失うもの

- `.harness/`は導入先ごとにあり、導入先と一緒に消える。`.harness/`をgitで追跡する導入先では、`.git/info/exclude`に`/.harness/cache/`も足す。
- 管理者がサンドボックスを必須にした導入先では、導入先の`allowWrite`が使われないので、worktreeのセッションで書くには、人が`~/.claude/settings.json`に足す。
- 場所を変える変数の無いツールでは、専用のキャッシュを選べない（`XDG_*`の変数は、導入先の設定の`env`では使われない）。

## 見直す条件

取り直しの時間かディスクの量が作業を止める導入先が出たら、比べ直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Get started」：「By default, commands inside the sandbox can write to the working directory, a per-user temp directory, and any directories you've added with `--add-dir`, `/add-dir`, or `permissions.additionalDirectories`.」（確かめた日：2026-11-23）
- 同じページの節「Configure sandboxing」：「This is the recommended approach when a tool needs write access to a specific location, rather than excluding the tool from the sandbox entirely with `excludedCommands`.」（確かめた日：2026-11-23）
- 同じページの節「Repository settings under an admin-required sandbox」：「It ignores these settings in a repository's `.claude/settings.json` and `.claude/settings.local.json`」（確かめた日：2026-11-23）
- [All settings](https://code.claude.com/docs/en/settings-reference)の節「Variables Claude Code ignores in `env`」：「the operating-system directory variables such as `HOME`, `TMPDIR`, `TMP`, `TEMP`, and the `XDG_*` family.」（確かめた日：2026-11-23）
