# GitLabのMRの指摘に対応するコマンド

`resolve-review-comment`の手順のうち、GitLabのMR（GitHubのPRにあたる）で使うコマンドと送る形である。流れと、どちらのホストでも守る規則は、`SKILL.md`に書く。

プロジェクトは、PRを送るリモートのURLのパス（例：`group/sub/project`）で書く。`-R <グループ>/<プロジェクト>`はそのままの形、`glab api`の`<P>`は`/`を`%2F`にした形（例：`group%2Fsub%2Fproject`）である（ハーネスの`rules/git.md`の節「ホストの種類」）。

読み取りの`glab api`は、ハーネスの`data/glab-api-endpoint-list.tsv`の`allow`の形だけを使う。ほかの形は、読み取りでも、判定のスクリプトが確認を求めるか、止める（例：CI/CDの変数を読む形）。

応答が大きい（例：discussionsの約34KB）と、Claude Codeが出力をファイルに保存して場所を示す。そのファイルに`jq`を当てて、要る項目だけを読む。`glab api`には`gh api`の`--jq`にあたるオプションが無く、`jq`にパイプでつなぐとフックが止めるためである。

## PRを見つける

`glab mr list -R <グループ>/<プロジェクト> --source-branch <今のブランチ> --output json`で、今のブランチのMRの`iid`（番号）を読む。そのあと、`glab api projects/<P>/merge_requests/<番号>`で、`description`、`web_url`、`sha`を読む。先頭のSHAは`sha`である。

## 指摘を集める

| 読むもの | コマンド |
|---|---|
| 差分へのスレッドと普通のコメント | `glab api --paginate projects/<P>/merge_requests/<番号>/discussions` |
| 自分の下書きのコメント | `glab api --paginate projects/<P>/merge_requests/<番号>/draft_notes` |
| 公開か | `glab api graphql -f query='query($fullPath: ID!) { project(fullPath: $fullPath) { visibility ciConfigPathOrDefault } }' -f fullPath=<グループ>/<プロジェクト>`の`visibility` |

discussionsは、差分へのスレッドと普通のコメントの両方を、`notes`の並びを持つdiscussionとして返す。`individual_note`が`true`のものは、普通のコメントである。GitLabにはレビューの本文が無く、レビューのまとめのコメントも普通のコメントとして返る。

`SKILL.md`の節「指摘を集める」の規則は、次の項目で見る。

- `notes[].system`が`true`のnoteは、GitLabが書いた記録（例：コミットの追加）なので、指摘として読まず、「最後のコメント」を決めるときも数えない。systemのnoteだけのdiscussionは外す。
- 解決したスレッドは、`resolvable`が`true`のnoteがすべて`resolved`が`true`のものである。
- 最後のコメントは、systemでない最後のnoteである。

`visibility`が`public`か`internal`なら、公開のリポジトリとして扱う。`internal`は、そのGitLabにログインしたすべての人が読めるためである。

自分の下書きのコメントは、扱いの表と一緒に人に示す。出していない下書きは相手に届かず、出すか消すかは、書いた人が決めるためである。

## 返信の送り方

| 返信の先 | 送り方 |
|---|---|
| スレッドと普通のコメント | `glab api projects/<P>/merge_requests/<番号>/discussions/<discussionのid>/notes -f body='<本文>'` |
| PRの本文 | `glab mr update <番号> -R <グループ>/<プロジェクト> --description '<本文>' --yes` |

- 普通のコメントへの返信も、元のdiscussionの`notes`へ送る。GitLabは普通のコメントへの返信もスレッドにでき、元のコメントのURLを本文に書かずに済むためである。
- `glab mr update`の番号は、コマンドの名前のすぐ後ろに書く。判定のスクリプトが、ほかのオプションの値と読み違えないためである。
- 本文の行の頭に`/`を書かない。GitLabがクイックアクションとして動かすので、判定のスクリプトが止める（ハーネスの`rules/git.md`の節「下書きの置き場所と確かめ方」）。
- 本文の`'`は`'"'"'`と書く。
- リンクは`https://<ホスト>/<グループ>/<プロジェクト>/-/blob/<SHA>/<パス>#L10`（範囲は`#L10-12`）にし、Markdownのファイルの行は`<パス>?plain=1#L10`で指す。

## 出典

- [Discussions API](https://docs.gitlab.com/api/discussions/)の節「List all merge request discussion items」：`notes[].system`「If `true`, a system note.」、`notes[].resolved`「If `true`, the note is resolved (merge requests only).」、節「Add note to a merge request thread」：「Adds a new note to the thread.」（確かめた日：2026-11-20）
- [glab mr list](https://docs.gitlab.com/cli/mr/list/)の節「Options」：「Filter by source branch <name>.」（確かめた日：2026-11-20）
- [glab mr update](https://docs.gitlab.com/cli/mr/update/)の節「Options」：「Skip confirmation prompt.」（確かめた日：2026-11-20）
