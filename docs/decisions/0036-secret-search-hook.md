# 秘密情報を、`pre-commit`と`pre-push`で探す

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「gitのフック」](../../.harness/docs/features/protection.md#gitのフック) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 秘密情報は、リモートに送られると取り消せない。手元のcommitに入っただけなら、送る前に直せる。
- `git commit`は通信が要らないので、サンドボックスの中で、どの書き方でも動く。権限のルールに当たらない書き方（例：`git commit -an`）では、`pre-commit`を飛ばせる。
- gitの設定でフックを足した導入先では、外に出るpushで、`pre-push`が動く。判定のスクリプトが、フックを飛ばす`--no-verify`を止めるためである。

## 判断

`pre-commit`では、置いた変更（ステージした変更）を探す。`pre-push`では、送るcommitを探す。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| `pre-commit`と`pre-push`の両方で探す | 採った | `pre-commit`を飛ばしたcommitも、送る前に`pre-push`で止まる。`pre-commit`で早く知らせると、直すcommitが少なくて済む。 |
| `pre-commit`だけで探す | 採らなかった | 飛ばしたcommitが、そのまま送られる。 |
| `pre-push`だけで探す | 採らなかった | 秘密情報を含むcommitが積み重なってから気づき、履歴の書き換えが要る。 |
| 導入先のCIで探す | 採らなかった | 送ったあとでは取り消せない。導入先のCIは作らない方針である。 |

## 結果と失うもの

pushのたびに送るcommitを読むので、送るcommitが多いと時間がかかる。誤検知のときは、人が自分で`--no-verify`を付けて動かす。設定で緩める道は作らない。gitが2.54より古い導入先では、どちらも動かない（[gitのフックの足し方の判断の記録](0012-git-hook-installation.md)）。

## 見直す条件

誤検知が続き、人が`--no-verify`を使うことが増えたとき、または、pushの時間が作業の妨げになったときに見直す。

## 出典

- [githooks](https://git-scm.com/docs/githooks)の節「pre-push」：「If this hook exits with a non-zero status, git push will abort without pushing anything.」（確かめた日：2026-11-16）
- 同じページの節「pre-commit」：「Exiting with a non-zero status from this script causes the git commit command to abort before creating a commit.」（確かめた日：2026-11-16）
