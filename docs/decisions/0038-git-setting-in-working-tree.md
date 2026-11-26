# サンドボックスの外で動くgitが作業フォルダーの中のファイルを動かす導入先では、確認を求める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-16 |
| 関わる設計 | [`features/protection.md`の節「gitの設定の確認」](../../.harness/docs/features/protection.md#gitの設定の確認) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 外に出した`git push`、`git fetch`、`glab`は、サンドボックスの外で、すべての権限で動く（[通信の境界の判断の記録](0034-sandbox-network-boundary.md)）。
- 作業フォルダーの中のファイルは、サンドボックスの中のコマンドから書ける。gitがそのファイルを動かすか読むと、エージェントが書いたものが外で動き、`main`へのpushも動かせる。
- gitが動かすか読むファイルの例は、huskyの`core.hooksPath`が指すフック、`core.sshCommand`が指すスクリプト、`.git/commondir`が指す場所の設定、`extensions.worktreeConfig`で読む`config.worktree`、サブモジュールの設定である。

## 判断

判定のスクリプトは、サンドボックスの外に出す`git push`、`git fetch`、`glab`のうち、通すか確認を求めるもので、外のgitが使う、サンドボックスの中から書ける設定とファイルを探し、あれば人に確認を求める。ハーネスの場所のスクリプトは除く。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| そのような設定のある導入先では確認を求める | 採った | 人が知らないまま、エージェントが書いたものが外で動くことが無い。設定の無い導入先では、確認は増えない。 |
| 保護の文書に、守れないこととして書くだけにする | 採らなかった | huskyの導入先では、pushのたびに、導入先のフックがサンドボックスの外で動く。 |
| フックのフォルダーを外す指定（例：`git -c core.hooksPath=/dev/null push`）に書き換えて動かす | 採らなかった | 導入先のフックを黙って止め、導入先の動きを変える。 |

## 結果と失うもの

huskyの導入先と、pushかfetchで動くフックを`.git/hooks/`に置く導入先では、pushとfetchのたびに確認が出る。確認が出る導入先と探す設定の一覧は、関わる設計に書く。探すのは決めた設定とフックのファイルだけで、ほかの設定は探さない。設定の多くは`.git/config`にあってサンドボックスの中から書けないが、値が指すファイルは書けるので、指す先が作業フォルダーの中かで探す。

ハーネスのリポジトリでは、ハーネスの場所のスクリプトを除くので、サンドボックスの中で書き換えたgitのフックのスクリプトが、pushのときに外で動く。

## 見直す条件

Claude Codeのサンドボックスが、外に出したコマンドにも読み書きの制限を当てられるようになったら見直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Run commands outside the sandbox with `excludedCommands`」：「An excluded command runs with your full access.」、「Claude can write that file and then run it outside the sandbox.」（確かめた日：2026-11-16）
- 同じページの節「Filesystem isolation」：「Writes to `hooks/` and `config` inside that directory remain denied.」（確かめた日：2026-11-16）
- [githooks](https://git-scm.com/docs/githooks)の節「DESCRIPTION」：「By default the hooks directory is $GIT_DIR/hooks, but that can be changed via the core.hooksPath configuration variable」（確かめた日：2026-10-23）
