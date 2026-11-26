# GitLabのMRをレビューするコマンド

`review-pr`の手順のうち、GitLabのMR（GitHubのPRにあたる）で使うコマンドと送る形である。流れと、どちらのホストでも守る規則は、`SKILL.md`に書く。

プロジェクトは、PRを送るリモートのURLのパス（例：`group/sub/project`）で書く。`-R <グループ>/<プロジェクト>`はそのままの形、`glab api`の`<P>`は`/`を`%2F`にした形（例：`group%2Fsub%2Fproject`）である（ハーネスの`rules/git.md`の節「ホストの種類」）。

読み取りの`glab api`は、ハーネスの`data/glab-api-endpoint-list.tsv`の`allow`の形だけを使う。ほかの形は、読み取りでも、判定のスクリプトが確認を求めるか、止める（例：CI/CDの変数を読む形）。

応答が大きい（例：discussionsの約34KB）と、Claude Codeが出力をファイルに保存して場所を示す。そのファイルに`jq`を当てて、要る項目だけを読む。`glab api`には`gh api`の`--jq`にあたるオプションが無く、`jq`にパイプでつなぐとフックが止めるためである。

## PRを読む

| 読むもの | コマンド |
|---|---|
| 本文、作者、状態、向き先のブランチ、先頭のSHA、差分のSHA | `glab api projects/<P>/merge_requests/<番号>`の`title`、`description`、`author`、`state`、`target_branch`、`sha`、`diff_refs`、`web_url` |
| 変えたファイル | 節「先頭のコミット」でコミットを取ったあとに、`git diff --name-only <分岐点のSHA>..<PRの先頭のSHA>` |
| CIの結果 | `glab api --paginate projects/<P>/merge_requests/<番号>/pipelines`で`id`の最も大きいパイプラインを選び、`glab api --paginate projects/<P>/pipelines/<パイプラインのid>/jobs`の`name`と`status` |
| 結び付いたチケット | 本文の参照（例：`Closes #12`、`group/project#12`）ごとに、`glab issue view <番号> -R <グループ>/<プロジェクト>` |
| すでにある指摘 | `glab api --paginate projects/<P>/merge_requests/<番号>/discussions` |
| 公開か | `glab api graphql -f query='query($fullPath: ID!) { project(fullPath: $fullPath) { visibility ciConfigPathOrDefault } }' -f fullPath=<グループ>/<プロジェクト>`の`visibility` |

- discussionsは、差分へのスレッドと普通のコメントの両方を返す。`notes[].system`が`true`のnoteは、GitLabが書いた記録（例：コミットの追加）なので、指摘として読まない。
- `visibility`が`public`か`internal`なら、公開のリポジトリとして扱う。`internal`は、そのGitLabにログインしたすべての人が読めるためである。
- 落ちたジョブのログ（`glab api projects/<P>/jobs/<ジョブのid>/trace`）は、判定のスクリプトが確認を求める。マスクしていないCI/CDの変数がログに出ることがあるためで、読むときは人にそのことを伝える。
- GraphQLの`query`の値は、判定のスクリプトが一字一句同じときだけ確認なしで通すので、空白も変えずに書く。

## 先頭のコミット

- リモートは、URLのパスがプロジェクトのパスと合うものを選ぶ。
- 向き先のブランチは`target_branch`、先頭のSHAは`diff_refs.head_sha`である。
- 先頭の参照の名前は、`merge-requests/<番号>/head`である。
- 分岐点のSHAは、`diff_refs.base_sha`にする。下書きのコメントの`position`の`base_sha`と同じ値で、消した行の行番号がGitLabの差分の表示と合うためである。

## コメントの形

- 行は、下書きのコメントの`position`の`new_line`と`old_line`で書く。足した行は`new_line`だけ、消した行は`old_line`だけ、変えていない行は両方を書く。
- 変えていない行の2つの行番号は、`git diff <分岐点のSHA>..<PRの先頭のSHA> -- <パス>`の塊の見出し（例：`@@ -10,7 +12,8 @@`）から数える。ファイルの前の部分が変わると、2つの行番号が違うためである。
- 複数の行にかかる指摘は、最後の行に付け、範囲（例：「12～15行目」）を本文に書く。GitLabの複数行のコメント（`line_range`）は、ファイル名のSHA1と前後の行番号を組んだ`line_code`が要り、組み方を誤るとGitLabが断るためである。
- ラベルはshields.ioのバッジにし、1つ目の段落にバッジだけを置く（ハーネスの`rules/review.md`の節「レビューのコメント」）。
- リンクは`https://<ホスト>/<グループ>/<プロジェクト>/-/blob/<SHA>/<パス>#L10`（範囲は`#L10-12`）にし、Markdownのファイルの行は`<パス>?plain=1#L10`で指す。
- 本文の行の頭に`/`を書かない。GitLabがクイックアクションとして動かすので、判定のスクリプトが止める（ハーネスの`rules/git.md`の節「下書きの置き場所と確かめ方」）。
- MRの承認（approve）とレビューの状態（`reviewer_state`）は送らない。人が行う。

## 送り方

指摘ごとに下書きのコメント（draft notes）を作り、最後にまとめて出す。GitHubの1回のレビューと同じく、出したときにまとめて届き、途中で失敗しても、出していない下書きは相手に届かないためである。書き込みのたびに判定のスクリプトが確認を求めるので、確認が指摘の数より1回多く出ることを、先に人に伝える。

1. 自分の下書きのコメントを`glab api --paginate projects/<P>/merge_requests/<番号>/draft_notes`で読む。あれば人に示し、出すか消すかを決めてもらう。まとめて出すと、人がGitLabの画面で書きかけた下書きも一緒に出るためである。
2. `glab api projects/<P>/merge_requests/<番号>`で`diff_refs`を読み直す。`head_sha`がPRを読んだときと違えば作らずに、増えたコミットを人に示し、レビューし直すかを聞く。
3. 指摘ごとに、下書きのコメントを作る。`position`の3つのSHAには、手順2で読んだ`diff_refs`の値をそのまま書く。
4. もう一度`diff_refs`を読み直し、`head_sha`が変わっていなければ、まとめて出す。レビューの本文は、まとめのコメント（`note`）にする。

手順3の形は、次のとおりである（足した行の例）。

```text
glab api projects/<P>/merge_requests/<番号>/draft_notes -f note='<コメント>' -F 'position={"base_sha":"<base_sha>","start_sha":"<start_sha>","head_sha":"<head_sha>","position_type":"text","old_path":"<前のパス>","new_path":"<パス>","new_line":10}'
```

手順4の形は、次のとおりである。

```text
glab api projects/<P>/merge_requests/<番号>/draft_notes/bulk_publish -f note='<レビューの本文>'
```

- `position`は、`-F`のJSONの値で書く。glabは、`position[base_sha]`のような括弧のある名前を、JSONの本文では誤りにするためである。
- `position`のJSONには、`\`と、`"`のあとの`/`を書かない。判定のスクリプトが、エスケープで行の頭の`/`を隠す形として止めるためである。
- レビューの本文が無いときは、`glab api -X POST projects/<P>/merge_requests/<番号>/draft_notes/bulk_publish`で出す。値が無いと、glabがGETで送るためである。
- 本文の`'`は`'"'"'`と書く。
- 途中で失敗したら、作った下書きのコメントを人に示し、`glab api -X DELETE projects/<P>/merge_requests/<番号>/draft_notes/<下書きのid>`で消してから作り直す。
- GitLabが400を返したら（例：差分に無い行の`position`）、どのコメントが外れたかをエラーから読む。

## 出典

- [Draft notes API](https://docs.gitlab.com/api/draft_notes/)の節「Publish all pending draft notes」：「Text of a summary note to add to the merge request.」（確かめた日：2026-11-20）
- [Discussions API](https://docs.gitlab.com/api/discussions/)の節「Create a new thread in the merge request diff」：「use `position[new_line]` and don’t include `position[old_line]`.」、「use `position[old_line]` and don’t include `position[new_line]`.」、「include both `position[new_line]` and `position[old_line]` for the line.」、節「Line code」：「A line code is of the form `<SHA>_<old>_<new>`」（確かめた日：2026-11-20）
- [glab api](https://docs.gitlab.com/cli/api/)の節「Synopsis」：「In a JSON request body a field name containing a bracket is an error.」、「The default HTTP request method is `GET` when no parameters are added, and `POST` otherwise.」（確かめた日：2026-11-20）
