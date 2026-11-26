# 判定のスクリプトは、pushに送り先のブランチを必ず書かせる

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「判定のスクリプト」](../../.harness/docs/features/protection.md#判定のスクリプト) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 送り先を書かないpush（例：`git push origin feat/x`）では、gitが、gitの設定（例：`remote.<名前>.push`）と参照（例：`main`を指すタグ、`ORIG_HEAD`）で送り先を決める。
- 参照は、サンドボックスの中のコマンドから書ける。判定のあとに、裏で動くコマンド（例：エージェントが先に動かしたバックグラウンドのコマンド）が参照を書き換えると、gitは書き換えた先へ送る。
- `pre-push`のフックは実際に送るブランチを見るが、gitが2.54より古い導入先と、フックを足す前のリポジトリには、そのフックが無い。

## 判断

pushは、`<送り元>:<送り先>`の形（例：`git push origin feat/x:feat/x`）だけを通し、送り先を書かない形は止めて、この形を理由の文で示す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 送り先を必ず書かせる | 採った | 送り先は、判定した文字列のまま変わらない。送り先を変える設定と参照を探す処理が要らない。 |
| 送り先を書かない形も、gitの設定と参照を確かめて通す | 採らなかった | 判定のあとの書き換えを止められない。送り先を変える設定と参照の形が見つかるたびに、確かめる処理を足し続ける。 |

## 結果と失うもの

pushの書き方が、送り先の分だけ長くなる。エージェントは、セッションの始めのフックと止めた理由の文で、この形を知る。消すpush（`--delete <ブランチ>`）は、ブランチの名前が送り先なので、この規則では止めない。判定のスクリプトが、作業用のブランチを消すpushには確認を求め、保護するブランチを消すpushは止める。

## 見直す条件

gitの`pre-push`を、すべての導入先で前提にできるようになったときに見直す。

## 出典

- [git-push](https://git-scm.com/docs/git-push)の`<refspec>`：「<src> without a :<dst> means to update the same ref as the <src>, unless the remote.<repository>.push configuration specifies a different <dst>.」（確かめた日：2026-11-16）
