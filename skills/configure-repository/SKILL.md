---
name: configure-repository
description: ハーネスを導入先に入れるときに、導入先を読んで、エージェントが守る導入先ごとのルール（テスト、lint、ビルドのコマンド、コミットメッセージとブランチ名の形、PRを送るホストの種類とPRの向き先のブランチ）、`.harness/docs/`の今の説明と目次、本体の会話のモデルとeffort、ハーネスの確かめる語をこの導入先でも禁止にするか、保護の設定（足す保護するブランチとCIの設定のファイルの場所、gitのフック、サンドボックスの通信先と書き込みの禁止、ツールのキャッシュと手元のサーバーを使うテストの扱い）の案を示し、人が承認したものだけを書く。「このリポジトリにハーネスを導入して」「このリポジトリ用に、エージェントが守るルールとテストのコマンドを設定して」「このリポジトリに保護の設定を足して」のような、導入先ごとに1回行う依頼で使う。導入先の`CLAUDE.md`と`AGENTS.md`は書き換えない。導入のあとに指摘を1つずつ記録するのはadd-rule、プロダクトのコードや文書を変えるのはpropose-changeを使う。
---

# 導入先を読んで、承認された設定を書く

導入先（ハーネスを入れるリポジトリ）ごとに1回、導入先を読んで設定の案を示し、人が承認したものだけを書く手順である。

- 書くのは、メインの作業フォルダーの`.harness/`、`.git/info/exclude`、`.git/config`、`.claude/settings.local.json`だけにする。メインの作業フォルダーは、`SessionStart`のフックが渡す、worktreeでない元の作業フォルダーである。
- 導入の設定は、導入先のgitに入るファイル（例：`CLAUDE.md`、`AGENTS.md`、`.gitignore`）に書かない。ハーネスのリポジトリの`.harness/docs/architecture.md`の要件「導入先を変えない」を満たすためである。
- ハーネスの`scripts/`のスクリプトは、`bash <ハーネスの場所>/scripts/<名前>`の形で動かす。ハーネスの場所は、フックが渡す、ハーネスのリポジトリの手元のパスである。この形は、PCの設定（`~/.claude/settings.json`）の権限のうち、ハーネスの場所の読み取りと`scripts/`の実行を許す設定に当たり、確認が出ない。理由は、ハーネスのファイルの権限の判断の記録（`docs/decisions/0028-harness-file-permission.md`）に書く。

## 手順

1. 導入先の状態を、節「始める前に見ること」のとおりに見る。
2. 導入先を、`references/repository-convention.md`の表と、節「保護の設定の読み方」のとおりに読む。
3. 案を、節「案の示し方」の形で人に示し、問いに答えてもらう。
4. メインの作業フォルダーで`git status --porcelain`を動かし、出力を控える。節「書いたあとの確かめ」で、書く前の出力と比べるためである。
5. 承認されたものだけを、節「書き方」のとおりに書く。
6. 節「書いたあとの確かめ」のとおりに確かめ、書いたファイルと確かめた結果を報告する。書いたルールと目次は、次のセッション（または`/clear`のあと）からフックが渡すことも伝える。

承認の前には、何も書かない。書くものに`.harness/`のルールと保護の設定が入り、常に読むルールの節「人に確認を求める場面」の、ハーネスの設定の変更に当たるためである。

常に読むルールは、フックが毎回渡す、ハーネスの`rules/always-read.md`と導入先ごとのルールである。導入先ごとのルールは、その導入先だけで守るルールで、メインの作業フォルダーの`.harness/rules/always-read.md`に置く。

完了の条件は、常に読むルールの節「完了の条件」のとおりである。比べる差分が無いので、レビュー役（`reviewer`のサブエージェント）は使わない。書く前の人の承認と、書いたあとの確かめで確かめる。

## 始める前に見ること

| 見ること | 見方 | 当たったとき |
|---|---|---|
| gitのリポジトリか | `git rev-parse --show-toplevel`が成功するか | 失敗したら（例：gitの外、bareのリポジトリ）、書かずに止め、理由を人に伝える。`.harness/`をgitから外す`.git/info/exclude`が使えないためである。 |
| 書く場所 | フックが渡すメインの作業フォルダー | worktreeの中で動いていても、メインの作業フォルダーに書く。フックの出力が、メインの作業フォルダーを求められなかったと書いていれば、今の作業フォルダーに書くことを案で示す。 |
| `.harness/`がすでにあるか | メインの作業フォルダーの`.harness/`の中を読む | あるファイルは上書きせず、足りないものだけを案にする。今の中身と導入先が食い違う所（例：古いテストのコマンド）は、直す案として示す。 |
| `.harness/`がgitで追跡されているか | メインの作業フォルダーで`git ls-files .harness`の出力があるか | 出力があれば（例：ハーネスのリポジトリ、チームで`.harness/`をコミットした導入先）、`.harness/`を`.git/info/exclude`に足さない。足すと、あとで足すファイル（例：変更の記録）がgitに出ず、コミットから漏れるためである。 |
| ハーネスのリポジトリか | ハーネスの`scripts/find-harness-repository.sh <メインの作業フォルダー>`の終了コード | 0なら、ハーネスのリポジトリとして、節「確かめる語の表」の表を作らない。2なら、書かずに止め、標準エラーに出た文を人に示す。 |

`.harness/`を導入先の中に置き、`.git/info/exclude`でgitから外す理由は、ハーネスの`.harness/`の置き場所の判断の記録（`docs/decisions/0003-harness-folder-location.md`）に書く。

## 保護の設定の読み方

保護の設定は、次の表の項目ごとに読んで案にする。

- 依頼が一部の項目だけ（例：gitのフック）でも、すべての項目を読み、足りないものを案に示す。抜けた保護の一部（例：`.harness/`の書き込みの禁止）は、環境を確かめるスクリプト（`scripts/print-protection-status.sh`）も示さない。そのため、すべての項目を読まないと、気づかないまま残る。
- 足す保護するブランチは、ハーネスが既定で保護するブランチ（ハーネスの`data/default-protected-branch-list.txt`のパターン）のほかに、判定のスクリプトとgitの`pre-push`のフックが、直接のpushを止めるブランチである。
- 足すCIの設定のファイルの場所は、ハーネスが既定で見る場所（ハーネスの`data/ci-setting-path-list.txt`）のほかに、判定のスクリプトが、その場所を変えるpushで確認を求める場所である。
- 保護されたブランチとCIの設定のファイルの場所を読むコマンドは、PRを送るリモートのホストの種類（ハーネスの`rules/git.md`の節「ホストの種類」）で選ぶ。種類が決まらないとき（例：自前のGitLab）は、読む前に、節「案の示し方」のホストの種類の問いだけを先に聞く。
- `<グループ>/<プロジェクト>`は、リモートのURLのパス（例：`group/sub/project`）で、`<P>`は、その`/`を`%2F`にした形（例：`group%2Fsub%2Fproject`）である。
- 判定のスクリプトは、Claude Codeのフックが呼び、外に出るコマンド（例：`git push`、`gh`）を通すか、確認を求めるか、止めるかを決めるスクリプトである。
- 外で動くgitの設定は、サンドボックスの外で動く`git push`と`git fetch`が使う、サンドボックスの中から書ける設定とファイル（例：作業フォルダーの中のファイルを動かす設定、リポジトリの設定の`http.proxy`）である。
- 守れないことは、ハーネスの保護の仕組みが、その導入先で止められない操作である。
- 環境を確かめるスクリプト（`print-protection-status.sh`）は、保護ごとに`[働く]`、`[働かない]`、`[わからない]`を出す。保護を緩める設定と、サンドボックスの外で動く設定は、`[確かめる]`として出す。
- PCの勧める設定は、ハーネスの`data/recommended-claude-setting.json`の中身を、PCの設定（`~/.claude/settings.json`）に足したものである。
- 設計の理由は、ハーネスのリポジトリの`.harness/docs/features/protection.md`に書く。

| 項目 | 読み方 | 案にすること | 書く先 |
|---|---|---|---|
| 足す保護するブランチ | 既定のブランチ（`git symbolic-ref --short refs/remotes/origin/HEAD`）と、保護されたブランチ（GitHubは`gh api 'repos/{owner}/{repo}/branches?protected=true' --paginate --jq '.[].name'`、GitLabは`glab api --paginate projects/<P>/protected_branches`の`name`） | ハーネスの`data/default-protected-branch-list.txt`のパターンに当たらないブランチを、足す案にする。読めないとき（例：`gh`か`glab`にログインしていない、403、`refs/remotes/origin/HEAD`が無い）と、保護されたブランチが空のときは、ほかに直接pushさせないブランチがあるかを人に聞く。 | `.harness/config`の`protection.branch` |
| 足すCIの設定のファイルの場所 | GitLabの`ciConfigPathOrDefault`（`glab api graphql -f query='query($fullPath: ID!) { project(fullPath: $fullPath) { visibility ciConfigPathOrDefault } }' -f fullPath=<グループ>/<プロジェクト>`）とそのファイルの`include`、`.github/workflows/`のファイルの`uses:`、`git ls-files`に出るほかのCIのサービスの設定のファイル | ハーネスの`data/ci-setting-path-list.txt`に無い、リポジトリの中の場所を、足す案にする。ほかのプロジェクトかURLのファイルは、守れないこととして示す。 | `.harness/config`の`protection.ciSettingPath` |
| gitのフック | `scripts/find-missing-git-hook-setting.sh <メインの作業フォルダー> <ハーネスの場所>`の出力 | 出力に出たフックを、足す案にする。 | `.git/config`の`hook.<名前>.command`と`hook.<名前>.event` |
| 拒否する通信先 | `git remote -v`のURLのホスト | リモートのホストのうち、`github.com`、`gitlab.com`とそのサブドメインでないもの（例：自前のGitLab）を、拒否する案にする。`github.com`と`gitlab.com`は、PCの勧める設定（ハーネスの`data/recommended-claude-setting.json`）がすでに拒否する。 | `.claude/settings.local.json`の`sandbox.network.deniedDomains` |
| 許す通信先 | `references/repository-convention.md`の「テスト、lint、ビルドのコマンド」の行で読む所（例：パッケージの定義） | 依存を取る先のホスト（例：npmの登録所）を、そのツールの公式の文書で確かめて案にする。案にしない先には、初めての通信のときに確認が出る。 | `.claude/settings.local.json`の`sandbox.network.allowedDomains` |
| ツールのキャッシュ | 同じ行で読んだツールの、公式の文書にあるキャッシュの場所と場所を変える変数（例：Goの`GOCACHE`と`GOMODCACHE`）と、場所を出すコマンドをサンドボックスの中で動かした出力（例：`go env GOCACHE`） | 場所が、サンドボックスの中のコマンドが書ける場所（作業フォルダー、利用者ごとの一時のフォルダー、足したフォルダー）の外なら、節「ツールのキャッシュの案」の案を示す。 | `.claude/settings.local.json`の`env`と`sandbox.filesystem.allowWrite`、`.git/info/exclude` |
| 手元のサーバーを使うテスト | テストのコマンドと、テストが使うサーバーの設定（例：`docker-compose.yml`のサービス、テストの設定のDBのホスト）と、ポートで待ち受けるテストのコード | macOSで自分でポートを開くテストか、どのOSでも手元で動くほかのサーバー（例：DB）につなぐテストがあれば、節「手元のサーバーを使うテストの案」の案を示す。LinuxとWSL2で自分で立てたサーバーだけにつなぐテストは、サンドボックスの中で動くので案にしない。 | 導入先ごとのルール、`.claude/settings.local.json`の`sandbox.excludedCommands`か`sandbox.network.allowLocalBinding` |
| Unixのソケットの禁止 | LinuxとWSL2で、セッションの始めの表のサンドボックスが「有効」のときだけ、サンドボックスの中で動かした`LC_ALL=C socat -u OPEN:/dev/null UNIX-CONNECT:/nonexistent-harness-probe.sock`の標準エラー | 標準エラーに`No such file or directory`があれば、節「Unixのソケットの禁止の示し方」のとおりに、守れないこととして示す。 | 書かない |
| `.harness/`と`glab`の設定の書き込みの禁止 | なし（どの導入先にも足す） | `./.harness/rules`、`./.harness/config`、`./.git/glab-cli`を案にする。 | `.claude/settings.local.json`の`sandbox.filesystem.denyWrite` |
| 外で動くgitの設定 | `scripts/find-git-setting-in-working-tree.sh <メインの作業フォルダー> <ハーネスの場所>`の標準エラーの出力 | 見つけたもの（例：huskyの`core.hooksPath`）があれば、`git push`と`git fetch`のたびに確認が出ることと、その理由を示す。 | 書かない |
| 守れないこと | `scripts/print-protection-status.sh <メインの作業フォルダー>`の出力 | `[働かない]`と`[わからない]`の項目を、起きることと直し方とともに示す。`[確かめる]`の項目は、ファイル、キー、値を示し、足した覚えの無い値が無いかを人に確かめてもらう。 | 書かない |

- 拒否する通信先のホストがIPアドレスなら、拒否する通信先では止められないので、守れないこととして示す。
- 依存の中身をGitHubかGitLabから直接取るツール（例：Composer）を見つけたら、依存を取るコマンド（例：`composer install`）を人がClaude Codeの外で動かすことを、許す通信先の案より先に示し、導入先ごとのルールに1行（例：「`composer install`は、人がClaude Codeの外で動かす。」）書く案にする。PCの勧める設定の拒否する通信先は、`github.com`と`gitlab.com`とそのサブドメインへの通信をどのモードでも止め、許す通信先に足しても通らないためである。
- `gh api`の`protected=true`は、ブランチ保護とルールセットで保護されたブランチを返す（REST API endpoints for branchesの節「List branches」）。非公開・無料のプランのように保護を使えない導入先では、空になる。空は、直接pushさせないブランチが無いことを示さないので、表の「足す保護するブランチ」の行のとおりに人に聞く。
- GitLabの保護したブランチの名前は、ワイルドカードの`*`を含むことがある（例：`*-stable`）。その名前も、文字列のままハーネスの一覧のパターンと比べ、当たらなければそのまま`branch`のパターンとして案にする。ハーネスはブランチの名前をシェルのパターンと比べ、`*`は`/`を含むすべての文字に当たるので、GitLabが保護するブランチを狭めないためである。
- `./.git/glab-cli`を足すのは、サンドボックスの中のコマンドが`glab`の設定（`.git/glab-cli/config.yml`）を書けなくし、`glab`の判定で確認が出る場面を減らすためである。worktreeでは`./.git`がファイルで当たらないので、判定のスクリプトの確かめ（中身のある`glab-cli`があれば確認を求める）が残る。
- 足す保護するブランチと足すCIの設定のファイルの場所がどちらも無ければ、`.harness/config`を作らない。作らなくても、判定のスクリプトと`pre-push`が使う既定の一覧は変わらない。理由は、ハーネスのリポジトリの`.harness/docs/features/protection.md`の節「サンドボックス」に書く。

足すCIの設定のファイルの場所は、次のように読む。CIの設定を変えると、secrets（CIのジョブに渡す秘密の値）を外へ送るジョブを足せるので、pushで変わる場所を漏らさないためである。

- GitLabの`ciConfigPathOrDefault`は、プロジェクトの設定で決めたCIの設定のファイルのパスである。`.gitlab-ci.yml`でなければ足す案にし、`@`を含むもの（ほかのプロジェクトのファイル）とURLは、守れないこととして示す。値が無ければ、読めなかったことを示す。
- `include`は、`local`と、URLでない文字列だけで書いたパス（例：`include: '.gitlab-ci-production.yml'`）を案にし、含めたファイルの`include`もたどる。`include:local`は、同じブランチのファイルを読み、このリポジトリへのpushで変わるためである。`project`、`remote`、`component`は、ほかのプロジェクトかURLのファイルなので、守れないこととして示す。
- `include`のパスは、先頭の`/`を外して書く。ワイルドカード（`*`、`**`）を含むパスは、その前のフォルダーを`/`で終えて案にし（例：`/configs/*.yml`なら`configs/`）、前のフォルダーが無ければ人に聞く。`.harness/config`の場所は、ワイルドカードを読まず、`/`で終えるとフォルダーの中のすべてを指すためである。
- `.github/workflows/`のファイルでは、`uses:`の値が`./`で始まるもの（手元のアクション）のうち、`.github/actions/`の外のフォルダーを案にする。手元のアクションは、ワークフローと同じcommitのファイルを動かすためである。
- ほかのCIのサービスの設定のファイル（例：`.circleci/`、`Jenkinsfile`、`azure-pipelines.yml`）は、`git ls-files`に出れば案にする。そのサービスがpushで動くと、GitHubとGitLabのCIと同じく、設定の変更でsecretsを外へ送れるためである。

外で動くgitの設定を見つけたときは、次のように示す。

- 見つけた設定があると、判定のスクリプトが`git push`と`git fetch`のたびに確認を求める。`git push`と`git fetch`はサンドボックスの外で動くので、設定が動かす導入先のフック（例：huskyのフック）も、サンドボックスの外で動くためである。
- 導入先の設定（例：huskyの`core.hooksPath`）は変えない。
- ハーネスのリポジトリ（節「始める前に見ること」）では、gitのフックのスクリプトが作業フォルダーの中にあることも、守れないこととして示す。サンドボックスの中のコマンドがそのスクリプトを書き換えると、書き換えたスクリプトが、pushのときにサンドボックスの外で動くためである（ハーネスのリポジトリの`.harness/docs/features/protection.md`の節「gitの設定の確認」）。

環境を確かめるスクリプトの出力の「導入先のgitのフック」の行が`[働かない]`なら、案のフックを書けば働くことを添える。出力の中身は、ハーネスのリポジトリの`.harness/docs/features/protection.md`の節「環境を確かめるスクリプト」に書く。

### ツールのキャッシュの案

ツールのキャッシュが、サンドボックスの中のコマンドが書ける場所の外にあると、そのツールのビルドかテストは、サンドボックスの中で書き込みに失敗する。次の案を起きることとともに示し、人に選んでもらう。勧めは、専用のキャッシュである。

| 案 | 書くもの | 起きること |
|---|---|---|
| 専用のキャッシュ（勧め） | `.claude/settings.local.json`の`env`に、場所を変える変数をメインの作業フォルダーの`.harness/cache/<ツール>/`の絶対パスで書き（例：`"GOCACHE": "/home/a/app/.harness/cache/go-build"`）、`sandbox.filesystem.allowWrite`にも同じ絶対パスを足す | 最初のビルドで取り直し、そのぶんのディスクを使う。外で動くビルド（例：人の端末、IDE）が使う共有のキャッシュはサンドボックスの中から書き換わらず、フォルダーを消せば戻る。 |
| 共有のキャッシュへの`allowWrite` | `.claude/settings.local.json`の`sandbox.filesystem.allowWrite`に、今のキャッシュの場所を足す | 取り直しは無い。サンドボックスの中から書いたキャッシュを外のビルドが使うので、仕込まれたコードが、キャッシュを消すまで外で動きうる。 |
| 足さない | なし | そのツールはサンドボックスの中で失敗し、人がClaude Codeの外で動かす。 |

- 導入先のテスト、lint、ビルドのコマンドが、言語のバージョンの管理ツール（例：mise、asdf）を通して動くときは、そのツールのキャッシュのフォルダー（例：miseでは、場所を`MISE_CACHE_DIR`で変えるフォルダー）も、節「保護の設定の読み方」のツールのキャッシュの行と同じく読み、書ける場所の外ならこの節の案を示す。コマンドのたびにキャッシュに書くツールでは、ほかのツールのキャッシュと同じく、サンドボックスの中で書き込みに失敗するためである。miseのDirectoriesは場所を変える変数をシェル、エディター、CIで同じにするよう書くが、キャッシュは作り直せるデータなので、専用のキャッシュに分けても取り直しで済む。
- バージョンの管理ツールのデータのフォルダー（入れたバージョン、プラグイン、shimを置くフォルダー、例：miseでは、場所を`MISE_DATA_DIR`で変えるフォルダー）には、この節の案を当てない。足りないバージョンは人がClaude Codeの外で入れることを、導入先ごとのルールに1行（例：「足りないバージョンは、人がClaude Codeの外で`mise install`を動かして入れる。」）書く案にする。
- データのフォルダーに案を当てないのは、場所を変える変数で移すと、外で動くシェルとIDEが使うフォルダーと分かれて入れたバージョンが見つからず、`allowWrite`に足すと、外で動くshimと実行ファイルをサンドボックスの中から書き換えられるためである（miseのDirectories）。足りないバージョンかそのプラグインを取りに行く先が`github.com`のこともあり（例：asdfのプラグインのGitのURL）、PCの勧める設定がその通信を止めるので、許す通信先の案にしても、サンドボックスの中では入れられない。
- 専用のキャッシュと共有のキャッシュへの`allowWrite`の案では、環境を確かめるスクリプトが、足した`allowWrite`を`[確かめる]`で示すことも添える。
- 変数は、ツールごとの変数（例：Goの`GOCACHE`）にする。`XDG_CACHE_HOME`のような`XDG_*`の変数は、導入先の設定の`env`に書いても使われない（All settingsの節「Variables Claude Code ignores in `env`」）。
- 場所を変える変数の無いツールでは、専用のキャッシュを示さず、ほかの2つを示す。
- 値を絶対パスで書くのは、相対パスでは、ツールを動かすフォルダーで場所が変わるためである。`allowWrite`にも足すのは、worktreeのセッションでは、メインの作業フォルダーの`.harness/cache/`が作業フォルダーの外になるためである。
- 管理者の設定がサンドボックスを必須にした導入先では、導入先の`allowWrite`が使われない。worktreeのセッションでも書けるようにするには、人が`~/.claude/settings.json`の`allowWrite`に同じ絶対パスを足す（ハーネスの`docs/setup-guide.md`の節「環境を確かめる」）。
- 比べた案は、ハーネスのツールのキャッシュの判断の記録（`docs/decisions/0051-tool-cache.md`）に書く。

### 手元のサーバーを使うテストの案

macOSのサンドボックスの中のコマンドは、既定では、ポートで待ち受けられず、localhostで動くほかのサーバーにもつなげない。LinuxとWSL2では、コマンドのlocalhostはそのコマンドだけのもので、自分で立てたサーバーには届くが、手元で動くほかのサーバーには届かない。当たるテストがあれば、次の案を起きることとともに示し、人に選んでもらう。勧めは、人がClaude Codeの外で動かす形である。

| 案 | 書くもの | 起きること |
|---|---|---|
| 人がClaude Codeの外で動かす（勧め） | 導入先ごとのルールに1行（例：「`make test-integration`は、人がClaude Codeの外で動かす。」） | 保護は緩まない。そのテストの結果は、変更が当たるたびに人が渡す（ハーネスの`skills/implement-change/SKILL.md`の節「テストと文章の確認」）。 |
| テストのコマンドを外で動かす | `.claude/settings.local.json`の`sandbox.excludedCommands`に、テストのコマンド（例：`make test-integration`）を足す | エージェントが書いたテストのコードが、サンドボックスの外ですべての権限で動く。環境を確かめるスクリプトは、`[確かめる]`で示す。 |
| macOSで待ち受けとlocalhostへの接続を許す | `.claude/settings.local.json`の`sandbox.network.allowLocalBinding`を`true`にする | macOSだけで当たり、サンドボックスの中のコマンドがlocalhostのすべてのポートに届くので、認証の無いlocalhostのサービス（例：デバッガー）が、コマンドの代わりに外で動ける。環境を確かめるスクリプトは、`[確かめる]`で示す。 |

- 緩める2つの案には、管理者の設定がサンドボックスを必須にした導入先では、導入先の`excludedCommands`と`allowLocalBinding`の`true`が使われないことを添える。エージェントは、ファイルでない形（例：MDMのポリシー）で配られた管理者の設定を読めないためである（ハーネスの`docs/setup-guide.md`の節「環境を確かめる」）。
- `excludedCommands`に足すのは、テストを1つのコマンドで動かす形にする。`excludedCommands`は、区切ったすべてのコマンドが当たる呼び出しだけを外に出すためである。
- 比べた案は、ハーネスの手元のサーバーを使うテストの判断の記録（`docs/decisions/0052-local-server-test.md`）に書く。

### Unixのソケットの禁止の示し方

LinuxとWSL2のサンドボックスは、任意の依存のseccompのフィルターがあるときだけ、Unixのソケットへの接続を止める。環境を確かめるスクリプトはサンドボックスの外で動き、止める動きを見られないので、サンドボックスの中で`socat`（LinuxとWSL2のサンドボックスの依存）を1回動かし、標準エラーで見分ける。

| 標準エラー | すること |
|---|---|
| `Operation not permitted`がある（例：`socket(1, 1, 0): Operation not permitted`） | フィルターが止めているので、示さない。 |
| `No such file or directory`がある（例：`connect(...): No such file or directory`） | 守れないこととして、サンドボックスの中のコマンドが手元のUnixのソケット（例：dockerのソケット）を通して外のプログラムを動かせることを示す。入れ方（`npm install -g @anthropic-ai/sandbox-runtime`のあと、Claude Codeを起動し直し、`/sandbox`のDependenciesのタブが消えたかを見る）と、入れなければこのままであることを添える。 |

- `socat`が動かないときのように、どちらとも読めない出力は、そのまま人に示す。
- セッションの始めの表のサンドボックスが「有効」でなければ、動かさない。サンドボックスが働かずに外で動いた`socat`も`No such file or directory`を出し、フィルターが無いと読み違えるためである。
- macOSでは動かさない。macOSのサンドボックスは、`sandbox.network.allowUnixSockets`に書いたパスのほかのUnixのソケットへの接続を止める（All settingsの`sandbox.network.allowUnixSockets`）。
- 比べた案は、ハーネスのUnixのソケットの禁止の見つけ方の判断の記録（`docs/decisions/0053-unix-socket-block-detection.md`）に書く。

## 案の示し方

案は、項目ごとに「読んだ所、案、書く先」の表で示す。読んだ所には、ファイルの名前か、動かしたコマンドを書く。

- 導入先のチームのルール（例：`CLAUDE.md`、`CONTRIBUTING.md`）にある規則は、導入先ごとのルールに中身をコピーせず、場所を1行で書く（例：「テストは`AGENTS.md`の節「Testing」のとおりに動かす。」）。同じ中身を2か所に置くと、片方だけが古くなるためである。場所を書くのは、チームのルールのファイルが毎回読まれるかが、エージェントとその設定で変わるためである。
- チームのルールとハーネスのルールが食い違う所（例：コミットメッセージの形）は、食い違いとして示す。書き方はチームのものを先にする（常に読むルールの節「導入先で書き方を決める順」）。
- 読んでもわからないこと（例：テストの前に起動するサービス）は、推測で埋めず、問いにする。

次の問いは、勧める値と理由を添えて人に聞く。PRを送るホストの種類と、読めないか食い違うPRの向き先のブランチには、勧める値を付けない。

| 問い | 勧め | 書く先 |
|---|---|---|
| PRを送るホストの種類（リモートのホストが`github.com`でも`gitlab.com`でもなく、導入先ごとのルールに種類が無いとき） | 勧めを付けず、GitHubかGitLabかを聞く。URLのホストから種類を決められないので、推測で決めないためである（ハーネスの`rules/git.md`の節「ホストの種類」）。 | 導入先ごとのルールに1行書く（例：「PRを送るホストの種類は、GitLabである」）。 |
| PRの向き先のブランチ（読んだ向き先が`main`でないとき） | 既定のブランチ（`git symbolic-ref --short refs/remotes/origin/HEAD`の出力の`origin/`のあと）と、チームの文書（例：`CONTRIBUTING.md`、PRのテンプレート）に書いた向き先にする。既定のブランチが読めずチームの文書にも無いときと、2つが食い違うときは、勧めを付けずに聞く。 | 導入先ごとのルールに1行書く（例：「PRの向き先のブランチは`develop`である。」）。向き先が複数ある導入先では、チームの文書のとおりの選び方を書く（例：「PRの向き先のブランチは、`hotfix/`で始まるブランチでは`main`、ほかでは`develop`である。」）。 |
| コミットメッセージの本文の形（導入先のチームのルールで決まっていないとき） | 背景、要求、方法の中身を、導入先の言語で書く（例：英語の履歴なら、見出しを付けずに英語の段落で書く）。1行目は、導入先の形に従う。 | 導入先ごとのルールに書く。 |
| 本体の会話（サブエージェントを起動する側の会話）のモデルとeffort | ハーネスの本体の会話のモデルとeffortの値の判断の記録（`docs/decisions/0032-main-conversation-model-value.md`）の値にする。使用量を減らしたいときの案も、同じ判断の記録から示す。 | `.claude/settings.local.json`の`model`と`effortLevel`に書く。 |
| レビュー役の組み合わせ（レビュー役の数と、それぞれのモデルとeffort） | ハーネスのレビュー役のモデルとeffortの判断の記録（`docs/decisions/0024-review-model.md`）の「標準」にする。使用量に余裕があり、見逃しを減らすほうを先にしたいときは「使用量に余裕があるとき」を示す。 | 標準なら書かない。ほかは、導入先ごとのルールに1行書く（ハーネスの`rules/review.md`の節「レビュー役への頼み方」）。 |
| 確かめる語（ハーネスの`data/ambiguous-word-list.txt`の語）を、この導入先でも禁止にするか | 導入先で使われていない語は禁止にし、使われている語は禁止にしない。表の作り方は、節「確かめる語の表」に書く。 | `.harness/rules/word-list.txt`に書く。 |

- PRの向き先のブランチを書くのは、ハーネスのルールとスキルが、書いていない導入先では`main`を向き先として、作業用のブランチを切り、今の説明の確かめたコミットを選ぶためである。既定のブランチだけで決めないのは、既定のブランチとPRの向き先が違う導入先（例：既定のブランチが`main`で、PRを`develop`へ送る導入先）があるためである。比べた案は、ハーネスのPRの向き先のブランチの判断の記録（`docs/decisions/0050-pull-request-base-branch.md`）に書く。
- コミットメッセージの本文の形の理由は、ハーネスのコミットメッセージの本文の判断の記録（`docs/decisions/0031-commit-message-body.md`）に書く。
- 本体の会話のモデルとeffortに今の値があれば、上書きせず、今の値と勧める値を並べて人に決めてもらう。今の値は、メインの作業フォルダーの`.claude/settings.local.json`、チームの`.claude/settings.json`、PCの設定（`~/.claude/settings.json`）の`model`、`effortLevel`、`modelSettings`から読む。PCの設定も読むのは、導入先に書かなければその値で動き、`modelSettings`には`/effort`で選んだ値がモデルごとに残るためである。PCの設定は作業フォルダーの外にあり、読むときに確認が出ることがあるので、読む前に人に伝える。
- 管理者の設定のファイル（ハーネスの`scripts/print-sandbox-state.sh`が読む`managed-settings.json`と`managed-settings.d/`）も、PCの設定と同じく、読む前に人に伝えて読む。`model`か`effortLevel`があれば、導入先に書く値より先に当たり、書いても使われないことを示す（`modelSettings`なら、そこに書いたモデルでだけ使われない）。`--settings`で渡した値と、ファイルでない管理者の設定（例：MDMのポリシー）は読めないので、読めないことを添える。WSLでは、Windowsの側（HKLMのレジストリか`C:\Program Files\ClaudeCode\`の管理者の設定のファイル）で`wslInheritsWindowsSettings`を有効にしたPCで、Windowsの側の管理者の設定も当たるが、ハーネスはそれを読まないことも添える（Managed settings）。
- `printenv ANTHROPIC_MODEL CLAUDE_CODE_EFFORT_LEVEL`で値が出れば、その環境変数が、書く値より優先されることも示す。どの値が優先されるかの順は、ハーネスの本体の会話のモデルとeffortの置き場所の判断の記録（`docs/decisions/0029-main-conversation-model-location.md`）に書く。

### 確かめる語の表

確かめる語は、人が指摘した語のうち、正しい使い方もある語である。導入先で使われている語は、業務の言葉か導入先の表記の決めのおそれがあるので、使われた場所を添えて人に決めてもらう。

1. ハーネスの`scripts/print-ambiguous-word-usage.sh <メインの作業フォルダー>`を動かす。出力は、答えの無い確かめる語ごとの「勧める種類<TAB>パターン<TAB>場所…」の1行で、場所は「パス:行」の形で語ごとに3か所までである。
2. 出力の1行を、表の1行にする。列は、パターン、代わりの言い方、使われた場所、勧めである。
3. 代わりの言い方は、ハーネスの`data/ambiguous-word-list.txt`の、同じパターンの行の2列目から取る。
4. 勧めは、1列目が`ambiguous-banned`なら「禁止にする」、`ambiguous-allowed`なら「禁止にしない」にする。
5. 人に、表の勧めを直して答えてもらう。

表を作るときは、次のことを守る。

- 使われた場所が業務の言葉かは、推測で決めない。場所を示して、人が決める。
- 出力が空なら（すべての語に答えがある）、この問いを聞かない。`.harness/`がすでにある導入先では、答えの無い語だけが出る。
- スクリプトが1で終われば（例：導入先ごとの語の一覧の形の誤り、`git grep`の失敗）、表を作らずに、標準エラーに出た文を人に示す。
- 表には確かめる語がそのまま入るので、文章の確認でこの表の語が示されても、言い換えない。
- パターンの`|`は、Markdownの表では`\|`と書く。そのままでは、表の列の区切りと読まれるためである。導入先ごとの語の一覧には、`\`を付けずに書く。

## 書き方

| 書く先 | 書き方 |
|---|---|
| `.git/info/exclude` | `.harness/`が追跡されていなければ、`/.harness/`の1行を足す。`git check-ignore -q .claude/settings.local.json`が1を返せば（gitから外れていない）、`/.claude/settings.local.json`も足す。 |
| `.harness/rules/always-read.md` | 節「導入先ごとのルールの形」のとおりに書く。 |
| `.harness/rules/word-list.txt` | 人が答えた確かめる語ごとに、`ambiguous-banned`か`ambiguous-allowed`の行を足す。形は、ハーネスの`skills/add-rule/SKILL.md`の節「導入先ごとの語の一覧の書き方」のとおりにし、パターンは`print-ambiguous-word-usage.sh`の出力の2列目をそのまま使う。 |
| `.harness/docs/architecture.md`、`.harness/docs/ubiquitous-language.md` | `assets/architecture.md`と`assets/ubiquitous-language.md`をコピーし、読んだコードとチームの文書から書く。チームの文書か人の回答で確かめていない節は「未確認」とだけ書き、推測の中身は書かない。 |
| `.harness/docs/README.md` | `assets/document-index.md`をコピーし、書いた今の説明のファイルを並べる。 |
| `.harness/config` | `[protection]`の節に、人が決めたブランチごとに`branch = <パターン>`（例：`branch = hotfix/*`）、CIの設定のファイルの場所ごとに`ciSettingPath = <リポジトリの一番上からのパス>`（例：`ciSettingPath = ci/`、`/`で終えるとフォルダーの中のすべて）の1行を書く。保護の一覧を出すスクリプト（ハーネスの`scripts/print-protection-list.sh`）が、`git config -f`で読む形式である。 |
| `.git/config` | 足すフックごとに、`[hook "<名前>"]`の節に`command = <コマンド>`と`event = <イベント>`を書く。名前、イベント、コマンドは、`find-missing-git-hook-setting.sh`の出力（`<名前>: <イベント>で「<コマンド>」を動かす`）のとおりにする。 |
| `.claude/settings.local.json` | 人が決めた`model`、`effortLevel`、`sandbox`の3つの一覧（`network.deniedDomains`、`network.allowedDomains`、`filesystem.denyWrite`）の項目と、人が選んだ案の`env`の変数、`sandbox.filesystem.allowWrite`、`sandbox.excludedCommands`、`sandbox.network.allowLocalBinding`だけを足す。ほかのキー（例：`enabledPlugins`）と今ある項目は変えず、ファイルがgitで追跡されているかJSONとして読めなければ、書かずに人に示す。 |

書く先ごとに、次のことも守る。

- `.git/info/exclude`と`.git/config`の場所は、メインの作業フォルダーで`git rev-parse --git-path info/exclude`と`git rev-parse --git-path config`を動かして求める。`.git`を外に置いたリポジトリとサブモジュールでは`.git`がファイルで、`.git/info/exclude`のパスでは開けないためである。
- `.harness/`がgitで追跡されている導入先で、人が専用のキャッシュ（節「ツールのキャッシュの案」）を選んだときは、`.git/info/exclude`に`/.harness/cache/`を足す。キャッシュをコミットに入れないためである。
- `.git/config`に同じ名前のフックの節がすでにあれば、今の値と案を並べて人に決めてもらう。
- ハーネスの場所に空白があれば、`.git/config`のコマンドのスクリプトのパスを`\"`で囲む（例：`command = \"/path with space/scripts/find-secret-in-commit.sh\" pre-push`）。git configの形式では、値の中の`"`を`\"`と書くためである。
- 今の説明（導入先の`.harness/docs/`に置く、導入先の今の状態を書く文書）の関わるコードは、名前（識別子）で書き、ファイルのパスは書かない。コードの配置の表のフォルダーの名前、前提の理由の確かめた所、識別子の無いもの（例：シェルのスクリプト）の名前は、パスで書いてよい。理由は、ハーネスのリポジトリの`.harness/docs/features/harness-folder.md`の節「書き分け」に書く。
- `.harness/docs/architecture.md`の節「判断」の表の「誰が決めたか」には、チームの文書から読んだ判断ならその文書へのリンクを、人の回答で確かめた判断なら「人の回答（YYYY-MM-DD）」を書く。どちらでもなければ「未確認」と書く。

書く順と、書き込みの確認は、次のとおりにする。

- `.git/info/exclude`を最初に書く。`.git/info/exclude`への書き込みが断られたら（例：人が確認で拒んだ）、`.harness/`を書かずに止める。先に`.harness/`を書くと、gitから外れないまま残り、導入先のコミットに入るおそれがあるためである。
- `.harness/docs/changes/`は作らない。最初の変更の記録を書くときに、`propose-change`が作る。
- `.harness/`が追跡されている導入先では、書いたファイルをコミットするかを人に聞く。チームで共有しているファイルのためである。
- すべての書く先を、ファイルのツール（Claude CodeではEdit、Write）で書く。シェルのコマンド（例：`git config set`）では書かない。サンドボックスの中のコマンドは`.git/config`に書けず、PCの設定の`allowUnsandboxedCommands: false`が、サンドボックスの外での再実行も止めるためである。
- `.harness/rules/`、`.harness/config`、`.git/config`、`.claude/settings.local.json`への書き込みには、PCの設定のaskのルール（ハーネスの`data/recommended-claude-setting.json`）で、どの権限のモードでも確認が出る。承認を得るときに、書くときに確認がもう一度出ることを伝える。
- askのルールは`**/.git/config`のようなパスの形に合う場所にだけ当たるので、サブモジュールと`.git`を外に置いたリポジトリの`.git/config`では、確認が出ないことがある。`.git/info/exclude`は、権限のモードが確認を出すパス（ハーネスのリポジトリの`.harness/docs/features/protection.md`の節「権限」）の1つで、確認が出るかは権限のモードで変わる。auto modeでは、確認を出すかを、Claude Codeの判定役（auto modeで操作を通すかを決める分類器）が決める。
- 書き込みが断られたときは、書く中身を示し、人が書くか、許してから続けるかを聞く。別の方法で書こうとしない。

### 導入先ごとのルールの形

- 1行目は`# <導入先の名前>のルール`にし、次に、この導入先だけで守るルールであることを1文で書く。
- 1つの規則を、箇条書きの1文で書く。理由が要るときだけ「～ためである。」を足す（`add-rule`と同じ形）。
- 並びは、コマンド（テスト、lint、ビルドと、その前に要ること、人がClaude Codeの外で動かすコマンド）、git（コミットメッセージ、ブランチ名、PRのテンプレートの場所、PRを送るホストの種類、PRの向き先のブランチ）、レビュー役の組み合わせ、表記のルールにする。当てはまらないものは書かない。

導入先ごとのルールは、毎回のセッションでフックが渡すので、短く保つ（ハーネスのリポジトリの`.harness/docs/features/always-read-rule.md`）。

## 書いたあとの確かめ

| 確かめること | 見方 |
|---|---|
| 導入先のgitに入らない（`.harness/`が追跡されていない導入先） | `git status --porcelain`の出力を、手順4で控えた出力と比べ、消えた行が`.git/info/exclude`に足した行で外れたもの（例：`?? .claude/`）だけであること。`git check-ignore -v .harness/rules/always-read.md`が、`.git/info/exclude`の行を指すこと。 |
| 導入先のgitに入らない（`.harness/`が追跡されている導入先） | `git status --porcelain`に出るのが、書いた`.harness/`のファイルだけであること。 |
| 導入先ごとのルールの字数 | ハーネスの`scripts/find-long-rule.sh`を当てる。3,000字を超えたら、毎回守らなくてよい中身（例：手順、背景）を今の説明へ移す案を人に示す。 |
| 文章の表記 | 書いたMarkdownのファイルに、常に読むルールの節「書く前に読むファイル」の文章の確認（止める語と表記のスクリプト）を動かす。導入先ごとの語の一覧には当てない。 |
| 導入先ごとの語の一覧 | ハーネスの`scripts/print-project-word-list.sh <メインの作業フォルダー>/.harness/rules/word-list.txt`が0で終わること。`print-ambiguous-word-usage.sh`をもう一度動かし、人が答えた語が出ないこと。 |
| フックが本文を省かない | ハーネスの`hooks/print-session-context.sh`を、メインの作業フォルダーで1回動かし、出力に「本文を省きました」の文が無いことを見る。文があれば、導入先ごとのルールか目次から、毎回読まなくてよい中身（例：手順、背景）を今の説明へ移す案を人に示す。 |
| `.claude/settings.local.json` | ファイルを読み、決めた値が入り、ほかのキーと今あった項目が書く前と同じであること。 |
| 保護するブランチとCIの設定のファイルの場所 | `.harness/config`を書いたら、ハーネスの`scripts/print-protection-list.sh <メインの作業フォルダー> branch`と、同じスクリプトの`ciSettingPath`の出力に、足したパターンと場所があること。 |
| gitのフック | `find-missing-git-hook-setting.sh`をもう一度動かし、何も出さずに0で終わること。 |
| 守れないこと | `print-protection-status.sh`をもう一度動かし、導入先のgitのフックが`[働く]`になったことと、残った`[働かない]`の項目を報告する。 |

- フックは、出力の合計が8,000字を超えると本文を省いて収める。出力の字数を数えても超えたことはわからないので、「本文を省きました」の文で見る。
- `hooks/`のスクリプトの実行は、PCの設定の権限で許す範囲（ハーネスの`scripts/`）の外なので、フックを動かすときに確認が1回出る。
- 移す案は、承認を得てから移す。

## 出典

- [REST API endpoints for branches](https://docs.github.com/en/rest/branches/branches)の節「List branches」：「Setting to true returns only branches protected by branch protections or rulesets.」（確かめた日：2026-11-16）
- [Protected branches](https://docs.gitlab.com/user/project/repository/branches/protected/)の節「Use wildcard rules」：「Branch names and wildcards are case-sensitive.」（確かめた日：2026-11-20）
- [CI/CD YAML syntax reference](https://docs.gitlab.com/ci/yaml/)の節「`include:local`」：「The `.gitlab-ci.yml` file and the local file must be on the same branch.」、「You can use `*` and `**` wildcards in the file path」、「You can also use shorter syntax to define the path:」、節「`include`」：「You can have up to 150 includes per pipeline by default, including nested.」（確かめた日：2026-11-20）
- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Get started」：「By default, commands inside the sandbox can write to the working directory, a per-user temp directory, and any directories you've added with `--add-dir`, `/add-dir`, or `permissions.additionalDirectories`.」、節「Set up Linux and WSL2」：「The seccomp filter is optional and adds Unix domain socket blocking.」、「Install it with `npm install -g @anthropic-ai/sandbox-runtime` if it is missing.」（確かめた日：2026-11-23）
- 同じページの節「A command fails to reach a server on localhost」：「A localhost service that doesn't require authentication, such as a debugger, can then act for the command outside the sandbox」、「The command can listen on a port and reach servers it started itself.」（確かめた日：2026-11-23）
- 同じページの節「Repository settings under an admin-required sandbox」：「It ignores these settings in a repository's `.claude/settings.json` and `.claude/settings.local.json`」（確かめた日：2026-11-23）
- 同じページの節「Run commands outside the sandbox with `excludedCommands`」：「Every command in the call has to match」（確かめた日：2026-11-16）
- [All settings](https://code.claude.com/docs/en/settings-reference)の節「Variables Claude Code ignores in `env`」：「the operating-system directory variables such as `HOME`, `TMPDIR`, `TMP`, `TEMP`, and the `XDG_*` family.」、`sandbox.network.allowUnixSockets`：「List the Unix socket paths sandboxed commands can connect to on macOS.」（確かめた日：2026-11-23）
- [miseのDirectories](https://mise.jdx.dev/directories.html)の節「`~/.local/share/mise`」：「Holds tool installations, plugins, shims, and command wrappers.」、節「`~/.cache/mise`」：「Holds data mise can rebuild」、表のあとの段落：「keep them the same for shells, editors, and CI」（確かめた日：2026-11-24）
- [asdfのPlugins](https://asdf-vm.com/manage/plugins.html)の節「Add」：「Add plugins via their Git URL:」、「`asdf plugin add elm https://github.com/vic/asdf-elm`」（確かめた日：2026-11-24）
- [Composerのtroubleshooting](https://getcomposer.org/doc/articles/troubleshooting.md)の節「API rate limit and OAuth tokens」：「Because of GitHub's rate limits on their API it can happen that Composer prompts」（確かめた日：2026-11-23）
- [CI/CD pipeline settings](https://docs.gitlab.com/ci/pipelines/settings/)の節「Custom CI/CD configuration file examples」：「The path must be followed by an `@` symbol and the full group and project path.」、「If the CI/CD configuration file is on an external site, the URL must end with `.yml`:」（確かめた日：2026-11-20）
- [Managed settings](https://code.claude.com/docs/en/managed-settings)の節「Deploy a managed settings file」：「Windows: `C:\Program Files\ClaudeCode\managed-settings.json`」、節「How Claude Code combines managed sources」：「on WSL once the HKLM registry or the Windows managed settings file turns `wslInheritsWindowsSettings` on」（確かめた日：2026-11-25）
