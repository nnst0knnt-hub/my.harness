# GitHubのPRをレビューするコマンド

`review-pr`の手順のうち、GitHubのPRで使うコマンドと送る形である。流れと、どちらのホストでも守る規則は、`SKILL.md`に書く。

## PRを読む

| 読むもの | コマンド |
|---|---|
| 本文、作者、状態、向き先のブランチ、先頭のSHA、結び付いたチケット | `gh pr view <番号> --json number,title,body,author,state,baseRefName,headRefOid,url,closingIssuesReferences,files` |
| 変えたファイル | `gh pr diff <番号> --name-only` |
| CIの結果 | `gh pr checks <番号>` |
| 結び付いたチケット | `closingIssuesReferences`と本文の参照（例：`#12`、`owner/repo#12`、URL）ごとに、`gh issue view <番号> -R <OWNER>/<REPO>` |
| 差分へのコメント | `gh api --paginate repos/<OWNER>/<REPO>/pulls/<番号>/comments` |
| レビューの本文 | `gh api --paginate repos/<OWNER>/<REPO>/pulls/<番号>/reviews` |
| 普通のコメント | `gh api --paginate repos/<OWNER>/<REPO>/issues/<番号>/comments` |
| リポジトリの名前と公開か | `gh repo view --json nameWithOwner,visibility` |

- `<OWNER>/<REPO>`は、`nameWithOwner`の値である。`visibility`が`PUBLIC`なら、公開のリポジトリである。
- 結び付いたチケットの`<OWNER>/<REPO>`は、`closingIssuesReferences`では`repository.owner.login`と`repository.name`、本文の参照ではその参照のリポジトリ（`#12`ならPRのリポジトリ）である。URLを引数にすると、判定のスクリプトがほかのホストを指す形として確認を求めるので、番号とリポジトリの名前で読む。URLのホストが`github.com`でなければ（例：GitHub Enterprise Server）、`gh issue view <URL>`で読み、確認を経る。
- `--json files`は100件までしか返さないので、変えたファイルの一覧は`gh pr diff --name-only`の出力で見る。差分の中身は、`SKILL.md`の節「PRの先頭のコミットを取る」の形で、要る所だけを読む。
- GitHubの一覧のAPIは、既定で30件ずつ返す（Using pagination in the REST API）。

## 先頭のコミット

- リモートは、URLが`nameWithOwner`のリポジトリと合うものを選ぶ。
- 向き先のブランチは`baseRefName`、先頭のSHAは`headRefOid`である。
- 先頭の参照の名前は、`pull/<番号>/head`である。
- 分岐点のSHAは、`git merge-base <リモート>/<baseRefName> <PRの先頭のSHA>`で求める。

## コメントの形

- 行の種類は`side`で書く。足した行と変えていない行は`RIGHT`、消した行は`LEFT`である。行番号は`line`に書く。
- 複数の行にかかる指摘は、`start_line`と`start_side`を足す。
- ラベルはshields.ioのバッジにし、1つ目の段落にバッジだけを置く（ハーネスの`rules/review.md`の節「レビューのコメント」）。
- リンクは`https://github.com/<OWNER>/<REPO>/blob/<SHA>/<パス>#L10`（範囲は`#L10-L12`）にし、Markdownのファイルの行は`<パス>?plain=1#L10`で指す。
- レビューのイベント（`event`）は`COMMENT`だけにする。承認（`APPROVE`）と変更の要求（`REQUEST_CHANGES`）は、人が行う。

## 送り方

1回のレビューとして、次の形で送る。配列のほか（`commit_id`、`event`、`body`）を`-f`で、コメントの配列（`comments[]`）の値をすべて`-F`で書く（ハーネスの`rules/git.md`の節「下書きの置き場所と確かめ方」）。

```text
gh api repos/<OWNER>/<REPO>/pulls/<番号>/reviews --method POST -f commit_id=<PRの先頭のSHA> -f event=COMMENT -f body='<レビューの本文>' -F 'comments[][path]=<ファイルのパス>' -F 'comments[][line]=10' -F 'comments[][side]=RIGHT' -F 'comments[][body]=<コメント>'
```

- コメントごとに、`comments[][path]`から書き始め、1つのコメントの中で同じキーを2回書かない。ghは、配列の最後のオブジェクトに同じキーがあると、新しいオブジェクトを始めるためである。
- 複数の行にかかるコメントは、同じコメントの中に`-F 'comments[][start_line]=8'`と`-F 'comments[][start_side]=RIGHT'`を足す。
- コメントの本文を`@`で始めない（例：メンションは文の途中に書く）。`-F`の値が`@`で始まると、ghがファイルから読むので、判定のスクリプトが止める。
- 数か`true`、`false`、`null`だけのコメントにしない。`-F`の値のこれらの語は、ghが文字でない値に変える。
- `-F`の値に`:owner`、`:repo`、`:branch`、`{owner}`、`{repo}`、`{branch}`を書かない（例：`<repo>`と言い換える）。ghが今のリポジトリの値に置き換えるので、判定のスクリプトが止める。
- 本文の`'`は`'"'"'`と書く。
- 送る前に`gh pr view <番号> --json headRefOid`で先頭のSHAを読み直す。古いSHAに送ると、そのあとのコミットが変えた行のコメントが、古いものとして表示されるためである（Create a review for a pull requestの`commit_id`）。
- GitHubが422を返したら、どのコメントが外れたか（例：差分に出ない行）をエラーから読む。

## 出典

- [Using pagination in the REST API](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)の節「About pagination」：「will only return 30 issues from the `octocat/Spoon-Knife` repository」（確かめた日：2026-11-15）
- [Create a review for a pull request](https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28#create-a-review-for-a-pull-request)の`commit_id`：「Not using the latest commit SHA may render your review comment outdated if a subsequent commit modifies the line you specify as the position.」、`event`：「The review actions include: APPROVE, REQUEST_CHANGES, or COMMENT.」（確かめた日：2026-11-15）
- [Create a review comment for a pull request](https://docs.github.com/en/rest/pulls/comments?apiVersion=2022-11-28#create-a-review-comment-for-a-pull-request)の`line`：「The line of the blob in the pull request diff that the comment applies to.」、`side`：「Use LEFT for deletions that appear in red. Use RIGHT for additions that appear in green or unchanged lines that appear in white and are shown for context.」（確かめた日：2026-11-15）
- [gh api](https://cli.github.com/manual/gh_api)：「To pass nested values as arrays, declare multiple fields with the syntax `key[]=value1`, `key[]=value2`.」（確かめた日：2026-11-20）
