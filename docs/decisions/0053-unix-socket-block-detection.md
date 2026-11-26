# Unixのソケットを止めるかは、サンドボックスの中で動かして見る

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-23 |
| 関わる設計 | [`skills/configure-repository/SKILL.md`の節「Unixのソケットの禁止の示し方」](../../skills/configure-repository/SKILL.md#unixのソケットの禁止の示し方)、[`docs/setup-guide.md`の節「環境を確かめる」](../setup-guide.md#環境を確かめる)、[`features/protection.md`の節「前提」](../../.harness/docs/features/protection.md#前提) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- LinuxとWSL2のサンドボックスは、任意の依存のseccompのフィルターがあるときだけ、Unixのソケットへの接続を止める。無いと`/sandbox`にDependenciesのタブが出るが、Claude Codeは起動する。
- 環境を確かめるスクリプトとセッションの始めのフックはサンドボックスの外で動き、フィルターが無くても「働く」と出す。
- 公式の文書には、フィルターの入れ方はあるが、サンドボックスが読む場所は無い。

## 判断

導入の手引きに、`/sandbox`のDependenciesのタブを見る文を足す。`configure-repository`が、LinuxとWSL2でサンドボックスが有効なときに中で`socat`を1回動かし、無いソケットへの接続の標準エラーに`No such file or directory`があれば、守れないこととして示す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 手引きの文と、`configure-repository`の`socat`の1回 | 採った | フィルターの有無でなく止める動きそのものを見るので、置き場所に依らない。導入先ごとに、人が入れるかを決められる。 |
| 手引きの文だけ足す | 採らなかった | 直しは軽いが、人が`/sandbox`を見なければ、「働く」の表示のまま気づかない。 |
| 環境を確かめるスクリプトか、セッションの始めのフックで見つける | 採らなかった | どちらもサンドボックスの外で動くので、止める動きを見られない。フィルターのファイルを探すと、置き場所が変わったときに黙って誤る。 |

## 結果と失うもの

- 見るのは導入のときの1回だけで、あとでフィルターが無くなったPCでは、人が`/sandbox`で見る。
- `socat`はLinuxとWSL2のサンドボックスの依存なので、足すコマンドは無い。macOSのサンドボックスは書いたパスのほかのソケットを止めるので、macOSでは動かさない。
- サンドボックスの外でも同じコマンドが`No such file or directory`を出すので、サンドボックスが有効なときだけ動かす。

## 見直す条件

フィルターの有無をサンドボックスの外から読めるようになったら、環境を確かめるスクリプトで見る形と比べ直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Set up Linux and WSL2」：「The seccomp filter is optional and adds Unix domain socket blocking.」、「Install it with `npm install -g @anthropic-ai/sandbox-runtime` if it is missing.」（確かめた日：2026-11-23）
- 同じページの節「Get started」：「plus a Dependencies tab on Linux when the optional seccomp filter is missing」（確かめた日：2026-11-23）
- [All settings](https://code.claude.com/docs/en/settings-reference)の`sandbox.network.allowAllUnixSockets`：「When the filter is missing, which `/sandbox` reports on its Dependencies tab, the sandbox doesn't block Unix-socket calls.」（確かめた日：2026-11-23）
