# GitHubのPRの指摘に対応するコマンド

`resolve-review-comment`の手順のうち、GitHubのPRで使うコマンドと送る形である。流れと、どちらのホストでも守る規則は、`SKILL.md`に書く。

## PRを見つける

`gh pr view --json number,url,headRefName,headRefOid,body`で、今のブランチのPRを読む。先頭のSHAは`headRefOid`である。

## 指摘を集める

`<OWNER>/<REPO>`は、`gh repo view --json nameWithOwner,visibility`の`nameWithOwner`で求める。`visibility`が`PUBLIC`なら、公開のリポジトリである。

| 種類 | 読み方 |
|---|---|
| 差分へのコメントのスレッド | GraphQLの`reviewThreads`を、下のコマンドで読む |
| レビューの本文 | `gh api --paginate repos/<OWNER>/<REPO>/pulls/<番号>/reviews`で読み、本文が空のものを外す |
| 普通のコメント | `gh api --paginate repos/<OWNER>/<REPO>/issues/<番号>/comments` |

GitHubの一覧のAPIは、既定で30件ずつ返す（Using pagination in the REST API）。

```text
gh api graphql --paginate -f owner=<OWNER> -f name=<REPO> -F number=<番号> -f query='query($owner:String!,$name:String!,$number:Int!,$endCursor:String){repository(owner:$owner,name:$name){pullRequest(number:$number){reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor} nodes{id isResolved isOutdated path line firstComment:comments(first:1){nodes{fullDatabaseId}} lastComments:comments(last:100){totalCount nodes{fullDatabaseId author{login} body url}}}}}}}'
```

`--paginate`が次のページを読むのは、外側の`reviewThreads`だけである。そのため、スレッドの中のコメントは、GraphQLの別名で、最初の1件（`firstComment`）と最後の100件（`lastComments`）を読む。別名は、同じ項目を、条件を変えて2回読む書き方である。

- `firstComment`の`fullDatabaseId`は、返信の宛先に使う（節「返信の送り方」）。
- `lastComments`の最後のコメントで、答えたかを見分ける。
- `lastComments`の`totalCount`が101を超えるスレッドでは、2件目から「`totalCount`－100」件目までを読まない。そのスレッドのURLと読まなかった件数を、人に示す扱いの表に書き、人に読んでもらう。

`SKILL.md`の節「指摘を集める」の規則のうち、解決したスレッドは`isResolved`が`true`のもの、外さない古い表示のスレッドは`isOutdated`が`true`のものである。

送っていないレビュー（`state`が`PENDING`）は、次のように扱う。

- 本文が空のものを外す前のレビューの一覧で探す。送っていないレビューは、本文が空のことがあるためである。
- 書いた人（`user.login`）が`gh api user --jq .login`のアカウントなら、扱いの表と一緒に人に示し、GitHubで送るか消すかを決めてもらう。
- 返信の前に決めてもらうのは、送っていないレビューが返信するアカウントに残っていると、スレッドへの返信が断られるためである。GitHubは、HTTP 422の「user_id can only have one pending review per pull request」を返す。

## 返信の送り方

| 返信の先 | 送り方 |
|---|---|
| スレッド | `gh api repos/<OWNER>/<REPO>/pulls/<番号>/comments/<firstCommentのfullDatabaseId>/replies --method POST -f body='<本文>'`で送る。返信の先にできるのは、スレッドの最初のコメントだけである。 |
| レビューの本文と普通のコメント | `gh pr comment <番号> --body '<本文>'`で、PRへの普通のコメントとして送る。答えた元のコメントのURLを本文に書く。 |
| PRの本文 | `gh pr edit <番号> --body '<本文>'`で直す。 |

本文の`'`は`'"'"'`と書く。リンクは`https://github.com/<OWNER>/<REPO>/blob/<SHA>/<パス>#L10`（範囲は`#L10-L12`）にし、Markdownのファイルの行は`<パス>?plain=1#L10`で指す。

## 出典

- [Using pagination in the REST API](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)の節「About pagination」：「will only return 30 issues from the `octocat/Spoon-Knife` repository」（確かめた日：2026-11-15）
- [Create a reply for a review comment](https://docs.github.com/en/rest/pulls/comments?apiVersion=2022-11-28#create-a-reply-for-a-review-comment)：「This must be the ID of a top-level review comment, not a reply to that comment.」（確かめた日：2026-11-15）
