# pushの送り元を、判定で確かめたcommitのSHAに書き換える

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「送り元とgitのフォルダーの固定」](../../.harness/docs/features/protection.md#送り元とgitのフォルダーの固定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 判定のスクリプトは、送り元のブランチが指すcommitを確かめる（例：CIの設定のファイルを変えるか）。
- 判定のあと、外のgitがpushを動かす前に、裏で動くコマンド（例：`git update-ref`）が送り元のブランチを書き換えると、確かめていないcommitが送られる。
- この手口は、判定をすり抜けようとするエージェント、つまりこの確認が守る相手そのものが使える。

## 判断

`PreToolUse`のフックが、pushのコマンドの送り元を、判定で確かめたcommitのSHAに書き換えて動かす（例：`git push origin feat/x:feat/x`を`git push origin <SHA>:refs/heads/feat/x`にする）。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| フックが、送り元をSHAに書き換える | 採った | 送り元のブランチを書き換えられても、確かめたcommitだけが送られる。フックで確認を求める形の中で閉じる。 |
| 守れないこととして、設計の文書に書く | 採らなかった | 裏で動くコマンドで、確実にすり抜けられる。 |
| 判定したSHAを書き込めない場所に残し、`pre-push`のフックが送るSHAと比べる | 採らなかった | 残す場所がPCの設定に依り、gitが2.54より古いと`pre-push`が動かない。人が手で動かしたpushと見分けられない。 |

## 結果と失うもの

確認の画面とセッションの記録に出るpushのコマンドが、ブランチの名前でなくSHAの形になる。`-u`を付けてもpushは通るが、追跡の設定は付かない。

## 見直す条件

Claude Codeが、Bashのツールの呼び出しで、フックが書き換えた入力（`updatedInput`）を使わなくなったときに見直す。

## 出典

- [Hooks reference](https://code.claude.com/docs/en/hooks)の節「PreToolUse decision control」：`updatedInput`の行の「Modifies the tool's input parameters before execution.」（確かめた日：2026-11-23）
