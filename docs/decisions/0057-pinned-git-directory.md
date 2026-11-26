# 外に出すコマンドを、gitのフォルダーを固定するスクリプトの呼び出しに書き換える

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-20 |
| 関わる設計 | [`features/protection.md`の節「送り元とgitのフォルダーの固定」](../../.harness/docs/features/protection.md#送り元とgitのフォルダーの固定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

判定のスクリプトがgitの設定を確かめたあと、外のコマンドが動く前に、サンドボックスの中のコマンドが`.git/commondir`かworktreeの`.git`のファイルを作ると、外のgitが作業フォルダーの中の設定とフックを使う。`GIT_DIR`、`GIT_COMMON_DIR`、`GIT_WORK_TREE`を付けたgitは、設定とフックを固定した場所から読むが、参照は`commondir`の指す場所から読み書きする。

## 判断

フックが、外に出すコマンドを、判定で求めたgitのフォルダーを環境変数で固定するスクリプトの呼び出しに書き換え、PCの設定の`excludedCommands`（サンドボックスの外で動かすコマンド）には、そのスクリプトの1行を足す。参照は固定できないので、そのスクリプトが動かす直前に`commondir`を確かめる。

## 案

### 外に出す形

| 案 | 結果 | 理由 |
|---|---|---|
| スクリプトの呼び出しに書き換える | 採った | 外に出るgitと`glab`がスクリプトの1行だけになり、判定を通らない形はサンドボックスの中で通信に失敗する。 |
| 先頭に3つの環境変数を付けた形か、`git --git-dir=<場所> push`に書き換える | 採らなかった | `excludedCommands`に当たらず、サンドボックスの中で失敗する。 |
| `.git/commondir`を、サンドボックスの書き込みの禁止に足す | 採らなかった | サンドボックスが無いパスに文字デバイスを置き、中のgitが読めずに止まる。 |
| 動かす直前に、フックがもう一度確かめる | 採らなかった | 確かめてから動かすまでの間が残る。 |

### 書き換えたコマンドの形

| 案 | 結果 | 理由 |
|---|---|---|
| スクリプトと記録の名前だけにし、理由の文に動かすコマンドを出す | 採った | 本文にバッククォート、`$(`、1万字を超える長さがあると、Claude Codeが`excludedCommands`に当てないが、この形は本文に依らずに当たる。 |
| 当たらない文字を、スクリプトが戻せる形に置き換える | 採らなかった | 当たらない形が文書に全部は載らず、バージョンで変わるので、置き換えの一覧が閉じない。 |

## 結果と失うもの

PCの設定に1行足すまで、外に出すコマンドは動かない。人は、動かすコマンドを確認の画面の理由の文で読む。

## 見直す条件

Claude Codeの`excludedCommands`が、環境変数を付けた形と、本文に記号のある形にも当たるようになったときに見直す。

## 出典

- [gitrepository-layout](https://git-scm.com/docs/gitrepository-layout)の`commondir`：「If this file exists, $GIT_COMMON_DIR (see git[1]) will be set to the path specified in this file if it is not explicitly set.」（確かめた日：2026-11-24）
