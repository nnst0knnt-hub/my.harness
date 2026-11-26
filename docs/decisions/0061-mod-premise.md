# modの前提は条件を付けて書き、環境を確かめるスクリプトでは見分けない

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「前提」](../../.harness/docs/features/protection.md#前提) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

mod（Claude Codeの中で動くプラグインのコード）は、組み込みの保護のmodが読み込まれない環境では、`PreToolUse`のフックが止めた呼び出しと、denyのルールが断る一部の呼び出しを許せる。modはプラグインとして入り、読み込んだmodの名前は、Claude Codeが`/plugin`の表示で示す。

## 判断

`protection.md`の節「前提」に、組み込みの保護のmodが読み込まれない環境では、modが許した呼び出しがdenyとaskのルールとフックを越えることを、条件を付けて書く。導入の手引きに確かめ方を書き、環境を確かめるスクリプトは、`enabledPlugins`の行の文にmodのことを足すだけにする。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 条件を付けて書き、スクリプトは`enabledPlugins`の`[確かめる]`で示す | 採った | 入れたプラグインは、今の`[確かめる]`の表示で示せる。 |
| 環境を確かめるスクリプトが、プラグインのファイルを読んでmodを見分ける | 採らなかった | Claude Codeのプラグインの保存の形に依り、形が変わると黙って誤る。`--plugin-dir`で読み込んだmodは、設定のファイルにも保存の場所にも無い。 |

## 結果と失うもの

modを見分けるのは人で、人が`/plugin`を見なければ、modが保護を越えていても気づかない。サンドボックスの制限は、modが許したシェルのコマンドにも当たる。

## 見直す条件

Claude Codeが、読み込んだmodの一覧を、スクリプトから読める形で公式の文書に示したときに見直す。

## 出典

- [Configure permissions](https://code.claude.com/docs/en/permissions)の節「Precedence among rules, hooks, and mods」：「In that setup, the mod can approve a call that a `PreToolUse` hook blocked, and some calls that a deny rule refuses.」（確かめた日：2026-11-23）
- [Mods overview](https://code.claude.com/docs/en/plugins/mods/overview)の節「What a mod can reach」：「the sandbox isolates the Bash commands Claude runs, and a process that a mod starts runs outside it.」（確かめた日：2026-11-23）
