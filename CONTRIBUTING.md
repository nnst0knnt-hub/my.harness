# ハーネスのリポジトリのルール

このリポジトリ（`my.harness`）の、答えと変更で見る範囲、ファイル、コード、GitHubの設定のルールである。エージェントは、ファイルを変える前にこのファイルを読み、質問に答える前に節「答えと変更で見る範囲」を読む。導入先には持ち込まない。文章、git、レビューの書き方は、[`rules/`](rules/)のルールに従う。

## 答えと変更で見る範囲

このリポジトリについての質問に答えるときと、変更を決めるとき（例：変更の記録の判断、レビューの指摘の勧め）は、このリポジトリで起きることに加えて、導入先のプロダクトと、そこで作業するPCで起きることも書く。ハーネスは導入先で動くので、このリポジトリの中だけで答えると、導入先で違うことが抜けるためである。

- 導入先のプロダクトでは、導入先のファイル、CI、チームのルールで変わることを書く（例：コミットメッセージの止める語を止める`commit-msg`のフックと`linters/`の確認は、導入先では動かない）。
- 作業するPCでは、OS、Claude Codeの入れ方（例：端末、IDEの拡張機能、デスクトップアプリ）、管理者の設定で変わることを書く。
- どちらでも変わらないときは、変わらないことと、そう言える根拠を書く。

## 文書の形

文書は、種類ごとに次の形で書く。表に無い1つだけの文書（例：`README.md`、`docs/setup-guide.md`）は、節の並びをそのファイルで決める。

| 種類 | ファイル | 形 |
|---|---|---|
| 今の説明 | `.harness/docs/`の`architecture.md`、`ubiquitous-language.md`、`features/`のファイル | 導入先と同じテンプレート（`skills/configure-repository/assets/`と、`skills/implement-change/assets/feature.md`）の冒頭の表と節の並び → 出典 |
| 判断の記録 | `docs/decisions/`の`<4桁の番号>-<名詞>.md` | 冒頭の表（状態、決めた日、関わる設計、語の意味） → 背景 → 判断 → 案 → 結果と失うもの → 見直す条件 → 出典 |
| ルール | `rules/`のファイルとこのファイル | 何のルールでいつ読むかの1文 → 規則の節 → 業界標準から外れる所 → 出典 |

- 今の説明をテンプレートの形で書くのは、テンプレートの誤りを、導入先より先にこのリポジトリで見つけるためである。導入先に無い節（例：要件、導入）は、テンプレートの節の間に足してよく、中身の多い節の下には`###`を足してよい。
- 構成要素ごとの設計は、`features/`に構成要素ごとに1つのファイルで書く。`implement-change`が、変えた構成要素のファイルだけを直せるためである。
- 種類の節の並びのうち、その文書に書くことが無い節は置かない。
- 文書には、今決まっていることと、その理由だけを書く。前の文書の状態、書き直しの経緯、確かめた作業の記録（例：使ったバージョン、確かめた手順）は書かず、確かめた作業はPRの本文の確かめ方に書く。
- 文書（ルールとスキルを含む）には、1台のPCの具体（例：誰のPCか、どこで受け取ったか、そのPCで見たバージョン）を書かず、どのPCにも当たる条件の形（例：管理者の権限が無いPC、IDEの拡張機能でClaude Codeを動かすPC）で書く。ハーネスはどのPCの導入先でも使うので、1台のPCの具体は、ほかのPCでは誤った前提になるためである。言い方の決まった語は、節「機械で確かめるもの」の1台のPCの具体と推測の形の確認が止める。
- 確かめていないことは、その文書の中の表（確かめていないこと、確かめられない理由、誰がいつ確かめるか、それまでの扱い）に書く。PRの前に確かめられないものだけを書く。
- ファイルを足すときは、[`.harness/docs/architecture.md`の節「コードの配置」](.harness/docs/architecture.md#コードの配置)の表にもとの要件を書き、書けないファイルは足さない。配置の表とファイルの一致は機械で確かめない。名前があることしか確かめられず、役割の確かめにならないためである。

### 判断の記録

- ほかの案と比べて選んだ判断だけを、1件1,500字（出典を除く）までで書く。比べた案が無い判断は、設計の文書に理由を1文で書く。
- 実現方式を別の方式へ置き換えたときに、判断の記録の本文を書き換える必要があるものは、判断の記録に書かず、比べた案と見直す条件ごと設計の文書かこのファイルに書く（ADRの書き方の記事）。
- 単体で読める形にし、本文にPRとIssueの番号と行番号を書かない。あとで読む人が追えなくなるためである。
- 中身をルールに書いた判断は、節「判断」を、何を決めたかの1～2文にし、中身は冒頭の表の「関わる設計」で指す。同じ中身を2か所に書くと、ルールを変えたときに片方だけが古くなるためである。
- 論点が2つ以上あるときは、論点ごとに`###`を置いて案の表を書く。表の形は、導入先の文書と同じにする（[`.harness/docs/features/harness-folder.md`の節「文書の形」](.harness/docs/features/harness-folder.md#文書の形)）。ただし、「誰が決めたか」の列は置かない。判断の記録はチームが決めた記録なので、値がすべて同じになり、読む人が得る情報が無いためである。
- 状態は、今は「採った」だけを使う。番号は足すときに最後の番号の次にし、2つ以上の記録を1つにまとめるときは小さい番号を残す。

### 図

- 描く前に、図で伝えることを1文で決め、図の前の文に書く。1文で書けない図は描かない。1文を先に決めると、その1文に要らない要素を図から外せるためである（Illustrating）。
- 1文と一緒に、読む人と、図の役割（全体の要素とつながり、作業の順、何がどこで止まるかの境界、状態の移り変わりのどれか）を決める。本文には図に描かない条件と理由を書き、図と本文で同じことを繰り返さない。
- 1つの図には、段落1つ分までの情報を入れる（Illustrating）。矢印には、何が渡るか、何をするかの語を付ける。
- 全体像と流れは、Mermaidの図で書く。PRの差分で読めて、文書と一緒に直せるためである。図のためのファイルと依存は増やさない。
- 図は人が読む文書だけに置く。ルールはエージェントが毎回読むので置かない。
- ラベルは`<br/>`で手で改行し、frontmatterに`wrappingWidth: 320`を付ける。語の途中で折り返さないためである。
- Mermaidは、矢印の向きで図の上下の並びを決めるので、人を上に置くには`<-->`にする。
- 図を直したら、作業用のブランチへpushして、GitHubの表示を確かめる。

## ファイルとフォルダーの名前

- 英小文字、数字、ハイフンだけを使う。ツールや仕様が決めた名前は、そのまま使う（例：`README.md`、`SKILL.md`、`.github/pull_request_template.md`）。
- シェルのスクリプトの拡張子は、`.sh`にする。スクリプトは「動詞-目的語」、データと文書は名詞にする。
- シェルのスクリプトには実行の権限を付け、gitに`100755`で記録する（`chmod +x`のあとに`git add --chmod=+x <ファイル>`で記録する）。ルールとスキルが直接動かすよう書いたスクリプトが、`Permission denied`で止まらないためである。`--chmod=+x`を付けるのは、`core.fileMode`が`false`のクローンでは、ふつうの`git add`が`100644`で記録するためである。
- 同じ種類のファイルを並べるフォルダーは、複数形にする（Claude Codeの`skills/`と同じ）。
- 文書とデータのファイル、スクリプトとスキルの名前の目的語は、単数形にする（例：`banned-word-list.txt`、`resolve-review-comment`）。
- `utils`、`helper`、`lib`、`misc`、`common`、`record`、`product`、`check`を、名前に使わない。名前だけで中身がわからないためである。`check`は、`rules/writing.md`の節「名前の具体性」では単独で使わない語で、このリポジトリでは、ほかの語と組み合わせても使わない。ツールが意味を決めた`common`（gitの`--git-common-dir`の共通のgitのフォルダー）と、[`.harness/docs/ubiquitous-language.md`](.harness/docs/ubiquitous-language.md)で意味を決めた`record`（フックの記録）は除き、その意味でだけ使う。
- `plan`、`glossary`、`login`、`logout`、`target`も、作者の好みで使わない。この5語を`rules/writing.md`に入れないのは、導入先では業務の言葉（ユビキタス言語）と食い違うおそれがあるためである。
- リポジトリの中で、ほかのファイルと同じファイル名にしない。`.harness/`の中は導入先と同じ形にするので除く。スキルごとの`references/`の、ホストの名前のファイル（`github.md`、`gitlab.md`）も除く。スキルの本文は、自分のファイルをスキルのフォルダーからの相対パス（例：`references/github.md`）で、ほかのスキルのファイルをスキルのフォルダーを付けて指し、全体の説明と`rules/review.md`がこの名前で書くためである。
- 目次のテンプレートは`document-index.md`にする。`README.md`は置かれたフォルダーの説明として読まれる名前で、`assets/README.md`だと`assets/`の説明に見えるためである。

## シェルの関数と変数

シェルのコードは、Google Shell Style Guideに合わせる。

- 関数と変数は英小文字とアンダースコアにし、定数と環境変数は英大文字にする。ほかのプログラムに渡す環境変数は、`HARNESS_`で始める。
- 関数は「動詞_目的語」にする。真偽を返す関数は、`is_`か`has_`で始める。関数の名前に、ファイルごとの接頭辞を付けない。
- 関数の中の変数は、`local`にする。1～2文字の名前を使わない（ループの`i`は使ってよい）。同じ名前を、別の意味で使わない。

## 設定の形式とキー

- 設定のファイルは、git configの形式にする（`git config -f <ファイル>`で読める）。`-f`で読むと`include.*`をたどらない。コメントは`#`か`;`で書く。`.harness/config`は、同じ形式の`.git/config`と同じく拡張子なしにする。
- キーはcamelCaseにする（git configのキーには`_`を使えない）。真偽値のキーは肯定の名前にし、単位はキーの最後に付ける。真偽値や数のキーを足すときに、`--type`での読み方を決める。
- 一覧は、単数形のキーを繰り返して書き、`git config -f <ファイル> --get-all <キー>`で読む。

## CIの名前

- ワークフローのファイル名、ジョブのid、ステップのidは、英小文字とハイフンにする（例：`test-and-lint.yml`、`run-shellcheck`）。
- ワークフロー、ジョブ、ステップの`name`は日本語にし、すべてのステップに付ける。
- ジョブの`name`は何を確かめるかの名詞（例：ShellCheckによるシェルの静的解析）にし、ステップの`name`は「～する」の形（例：ShellCheckを動かす）にする。

## スキルとサブエージェントの名前

- スキルは「動詞-対象」にする（例：`review-pr`、`add-rule`）。Agent Skillsの`name`の規則を守り、`claude`と`anthropic`を入れない。
- サブエージェントは、役割の名詞にする（例：`reviewer`）。
- 人は`/名前`で打つこともあるので、組み込みのコマンドとスキルと同じ名前と、紛らわしい名前を避ける。プラグインのスキルは`/my-harness:review-pr`の形で区別されるが、打つときに見分けにくいためである（Extend Claude with skills）。

避けた名前は、次のとおりである（Commandsの節「All commands」）。

| 名前 | 避けた名前 | 避けた理由 |
|---|---|---|
| `propose-change` | `plan`、`plan-change`、`design-change` | `/plan`は組み込みと同じで、`plan`は名前に使わない語である。`/design`は、画面の案を作る組み込みのスキルと紛らわしい。 |
| `audit-security` | `security-review`、`review-security` | 組み込みと同じ名前と、語順だけ違う名前である。 |
| `resolve-review-comment` | `address-feedback`、`address-review-comments` | `/feedback`は組み込みと紛らわしい。`address`は、何をするかがわからない動詞（`rules/writing.md`の「対応する」）に当たる。 |
| `review-pr` | `review`、`code-review` | 組み込みと同じ名前である。 |
| `configure-repository` | `init`、`configure-product` | `/init`は組み込みと同じで、`product`は抽象的な語である。 |
| `add-rule` | `record-rule` | `record`は抽象的な語である。 |

## コードの作り

[`rules/always-read.md`の節「導入先で書き方を決める順」](rules/always-read.md#導入先で書き方を決める順)の4番目の、言語に依らない原則（1つのことだけをする、先に返して入れ子を浅くする、名前に動作と対象を入れる）に加えて、次の4つを守る。

| 原則 | 中身 |
|---|---|
| 形を変えるのは呼ぶ側 | スクリプトは1つの仕事だけをし、入力の形を変えるのは呼ぶ側にする。 |
| 関数の置き場所 | 関数はファイルの上にまとめ、最後の行を`main "$@"`にする。 |
| 判定の関数の副作用なし | 判定の関数は、ファイルに書き込まず、`exit`しない。`exit`するのは`main`だけにする。 |
| わからないときは確認 | 環境の問題で判定できないとき（例：設定のファイルを読めない）は「確認を求める」を返し、判定できないコマンドの形は止める。呼ぶ側（例：`hooks/read-bash-command.sh`）は、結果が「通す」「確認を求める」「止める」のどれでもなければ、確認を求める。 |

「わからないときは確認」は、環境の問題を人に確認し、コマンドの形はエージェントが書き直す設計（[`.harness/docs/features/protection.md`の節「判定のスクリプト」](.harness/docs/features/protection.md#判定のスクリプト)）を、コードで守るための原則である。

## スクリプトの長さ

1ファイル100行を上限にし、`wc -l`で数える（空行とコメントも数える）。超えたら、確かめる規則か処理のまとまり（例：見出しとコードブロック、コマンドごとの判定）ごとにファイルを分け、言語は変えない。

## setと変数とbash 3.2

- スクリプトの始めに、`set -u -o pipefail`を書く。`set -e`は使わず、戻り値を`if`で確かめる。`set -e`は`if`の条件や`&&`の途中では無視され、どこで止まるかが読みにくくなるためである（Bash Reference Manualの「The Set Builtin」）。
- 変数は`"${x}"`の形で書く。1文字の特別な変数と位置パラメーター（例：`$1`、`$?`）には、括弧が要るとき（例：`${10}`）を除いて、括弧を付けない。
- bash 4以降の機能（例：`mapfile`、連想配列、`${x,,}`、`&>>`、`|&`、負の添字、nameref）を使わない（bashのNEWS）。
- 空の配列を、`set -u`のもとで展開しない。bash 4.4より前では、エラーになるためである（bashのCHANGES）。
- 置き換えの展開（例：`${x//a/b}`）のパターンに、`/`を含む展開（例：`${y##*/}`）を入れ子にせず、先に別の変数に入れる。bash 3.2は、入れ子の中の`/`で展開が終わったと読み、「bad substitution」で止まるためである（macOSのランナーの`/bin/bash`の3.2.57で見た）。
- 制御文字の`$'\x01'`を、コマンド置換とプロセス置換の中に直接書かず、関数の中に書いてその関数を呼ぶ。bash 3.2では、`$'\x01'`を区切りにした`sed`が、プロセス置換の中に書いたときだけ語を見つけなかったためである（macOSのランナーの`/bin/bash`の3.2.57で見た）。
- バイトを扱う`tr`、`grep`、`awk`は、`LC_ALL=C`で動かす。UTF-8のロケールでは、macOSの`tr`が文字の途中のバイトで失敗するためである。

## コメント

ファイルの先頭に、次の3行を書く（例：`scripts/find-banned-word.sh`）。ファイルごとの説明の文書を置かない分、先頭のコメントと関数のコメントで説明する（[判断の記録](docs/decisions/0014-code-explanation-location.md)）。

1. 何を受け取り、何を出力するか（何のためかを含む）
2. 終了コードの意味
3. 誰が、いつ呼ぶか

ほかのコメントは、次のように書く。

- 理由は、設計の文書の名前と、節の見出しで指す。
- `main`のほかの関数には、説明、引数、出力、戻り値を書く。`main`の上には書かない。先頭のコメントが`main`の説明を兼ねるためである。
- 行のコメントは、理由だけを、その行の上に書く。行末には書かない。
- `TODO`は書かず、Issueにする。ShellCheckの警告を外すときは、理由を書く。

## エラーメッセージ

- 標準エラーに出す。先頭は、`スクリプトの名前: `か`ファイル:行: `にする。時刻は付けない。
- 1文目に起きたことを、2文目に読む人（人かエージェント）が次にすることを書く。理由は判断に要るときだけ書き、3文までを目安にする。対象の値を含める。
- 終了コードは、0が成功、1が失敗、2が使い方の誤りにする。

## テスト

- テストフレームワークは使わず、比べる関数`expect`を持つ補助の関数を自分で書く。
- `tests/`の下に、確かめるスクリプト1つにテストのファイル1つを`test-<確かめるスクリプトの名前>.sh`で置く。
- 判定の一覧は、データのファイル（1行1件、タブ区切り、`#`はコメント）に分け、テストのスクリプトはデータを読んで比べるだけにする。100行の上限は、データのファイルには当てはめない。
- ケースの説明の文（テストが`ok:`のあとに出す文）は、「何を入れたら、どうなるか」を1文の常体で書く（例：保護するブランチへのpushを渡すと、止める。）。
- gitのフックのテストは、一時のリポジトリに、gitの設定でフックを足して動かすので、git 2.54以上が要る。古いgitではフックが動かず、止めるはずのケースが落ちる。
- テストは、root以外の利用者で動かす。読めないファイルのケースは`chmod 000`でファイルを作り、rootはそのファイルも読めるので落ちるためである。dockerのコンテナーでは、`--user`を付ける。誤り方は通るべきテストが落ちる側で、壊れたコードが黙って通る側ではないので、ケースは飛ばさない。

## 整形

- 文字コードはUTF-8、改行はLFにし、ファイルの最後に改行を1つ置く。行末に空白を置かず、インデントにタブを使わない。この5つは機械で確かめる。
- インデントは、空白2つにする。シェルの行の長さは、80文字を目安にする。Markdownの行の長さは決めない。段落の途中で改行しないためである。
- `.editorconfig`を置く。

## GitHubの設定と運用

| 対象 | ルール | 理由 |
|---|---|---|
| マージの方法 | マージコミットだけ（squashとrebaseのマージを切る） | 個々のコミットの時期と書いた人が残り、作業用のブランチの先頭のSHA（今の説明の確かめたコミット）も、マージのあとに`main`から辿れるため |
| マージのあとのブランチ | GitHubの「Automatically delete head branches」の有効化 | 使い終わったブランチが残らないため |
| `main`の保護 | 既定のブランチ（`~DEFAULT_BRANCH`）に当て、force pushと消すことを止めるruleset（例外にする利用者なし） | 公開のリポジトリをクローンした人の`git pull`が履歴の書き換えで進まなくなるのを防ぎ、手元の保護（判定のスクリプトとgitのフック）が止めないpush（例：Claude Codeの外で、gitのフックを足していないクローンから送るpushと、`--no-verify`を付けて送るpush）もGitHubが止めるため |
| 脆弱性の置き場所 | GitHubの非公開の脆弱性の報告（有効にし、IssueとPRには中身を書かない） | 公開のリポジトリのIssueとPRは誰でも読め、直す前に中身が広まるため |
| ブランチ名 | Issueの番号なし | Issueとの結び付きは、PRの本文の`Closes #12`で示すため |
| Issueの参照 | 本文の`Refs #12`と、閉じるときの`Closes #12` | `Closes #12`は、既定のブランチへのPRのマージでIssueを閉じ、`Refs #12`は閉じずに参照を残すため |
| PRのテンプレート | `.github/pull_request_template.md`の、[`rules/git.md`の節「PRの題と本文」](rules/git.md#prの題と本文)の5つの内容（背景、要求、方法、確かめ方、残っていること）の見出しと、確かめ方と残っていることの表の列の名前だけ | 5つの内容を、決めた形で書くため |
| Issueのテンプレート | Markdownのテンプレート2つ（不具合、要望と指摘）と、`config.yml`の`blank_issues_enabled: false` | ghは、手元で`.md`のテンプレートだけを読むため |
| PRの大きさ | 関係する作業とIssueを1つのPRにまとめてよく、`rules/git.md`の1,000行の目安を超えてよい | 作者1人のリポジトリで、PRごとのレビュー、CI、人の承認の繰り返しを減らすため（導入先には当てはめない） |

マージは、CIが通っていることを人が確かめてから、人が行う。

`main`の履歴を書き換えるときと、既定のブランチの名前を変えるときは、人が`protect-main`のrulesetを無効にしてから行い、終えたら有効に戻す。force pushは、`pre-push`のフックが止めるので、Claude Codeの外で`--no-verify`を付けて送る。

## ブランチの切り替え

このリポジトリは`.harness/rules/`をコミットし、導入の設定（`.claude/settings.local.json`の`sandbox.filesystem.denyWrite`）で、サンドボックスの中のコマンドから`.harness/rules/`に書けなくしている。そのため、`.harness/rules/`の中身が違うコミットへ移ると、サンドボックスの中では、そのファイルだけを書き換えられない（`Read-only file system`）。`git switch`と`git merge`は、そのファイルのパスを含む`unable to`の行を出す。終了コードと、HEADを移すかは、コマンドとファイルの変わり方（書き換わる、足される、消える）で違う。

移るときは、次のようにする。

- 移る前に、`git diff --name-only HEAD <移る先> -- .harness/rules`で、中身が同じかを見る。ファイルの名前が出れば（中身が違う）、Claude Codeの外のシェルで移るよう、人に頼む。終了コードで見分けないのは、Bashのツールが`git diff --quiet`の1を示さないためである。
- マージのあとの`main`へ移るときは、`git fetch origin main`のあと、移る先を手元の`main`ではなく`origin/main`にして比べる。中身が同じなら、`git update-ref refs/heads/main origin/main`で手元の`main`を進めてから、`git switch main`で移る。手元の`main`はマージの前のままなので、手元の`main`と比べると、要らない移動を人に頼むためである。
- `git switch`か`git merge`が、`.harness/rules/`のパスを含む`unable to`の行（例：`unable to unlink old`）を出したときは、終了コードに関わらず、`git status`と`git log -1 --oneline`の出力を人に示し、Claude Codeの外のシェルで直すよう頼む。
- EditとWriteで先に`.harness/rules/`を書き換えてから移る方法は、採らない。ファイルごとに確認が出て、移る先の中身と取り違えることがあるためである。

## ラベル

Issueには、次の3種類のラベルを付ける。

- 種類か対象：不具合、要望、セキュリティ
- 誰が見つけたか：人の指摘、エージェントの気づき
- 優先度（1つだけ）：優先度：高、優先度：中、優先度：低

誰が見つけたかを付けるのは、「人の指摘」の数を[`.harness/docs/architecture.md`の節「測り方」](.harness/docs/architecture.md#測り方)で使うためである。

- 優先度は、[`rules/review.md`の節「優先度の決め方」](rules/review.md#優先度の決め方)の基準で決める。PRの本文の「残っていること」と同じ基準にするのは、残したことをIssueにしたときに、優先度をそのまま移せるためである。
- 1つのIssueには、同じ優先度の項目だけを書く。最も高い項目に合わせると、低い項目も高い優先度で一覧に並ぶためである。
- 優先度を付けたときと変えたときは、理由をコメントに書く。今の環境が変わったとき（例：Codexで動かすと決めたとき）は、緊急度が変わるので、開いているIssueの優先度を見直す。
- 同じ指摘が出たら、`gh issue close --duplicate-of`で元のIssueに結び付けて数える。

## レビュー役の組み合わせ

このリポジトリの別の文脈のレビューでは、レビュー役のモデルとeffortの組み合わせを、[判断の記録](docs/decisions/0024-review-model.md)で決めた「使用量に余裕があるとき」にする。1回目のレビューでは、レビューの深さ（[`rules/review.md`の節「レビューの深さ」](rules/review.md#レビューの深さ)）で決めた数のOpusのレビュー役に加えて、全体を見るSonnetの`high`のレビュー役を1つ、互いの結果を見せずに動かす。

- この組み合わせにするのは、作者の契約に使用量の余裕があり、このリポジトリの構成要素を、このあとのすべての作業と導入先が使うためである。見逃しを減らすほうを、使用量より先にする。
- Sonnetのレビュー役の動かし方は、[`rules/review.md`の節「レビュー役への頼み方」](rules/review.md#レビュー役への頼み方)に書く。
- 変更の記録の冒頭の表のレビュー役の行には、Sonnetの1つを含めた数と、使用量の見込みを書く。変更の記録の承認が、常に読むルールの「サブエージェントを同時に2つ以上動かす」の確認を兼ねるためである。
- 2回目からの直しの差分のレビューは、標準の組み合わせと同じく、Opusの`xhigh`のレビュー役を1つ動かす。
- 契約が変わったら、同じ判断の記録の節「見直す条件」のとおりに見直す。

## 残した指摘の形

このリポジトリでは、残した`SUGGESTION`、`FYI`、答えが出ない`QUESTION`（ラベルの意味は[`rules/review.md`の節「レビューのコメント」](rules/review.md#レビューのコメント)）を、PRの本文へ入れる形（[`rules/review.md`の節「残した指摘の置き場所」](rules/review.md#残した指摘の置き場所)）の代わりに、次の形にする。比べた案は、[判断の記録](docs/decisions/0018-remaining-suggestion.md)に書く。

- 指摘を差分の該当箇所へのコメントにして、1回のレビューにまとめる。差分に無い所とPR全体への指摘は、普通のコメント1件にまとめる。
- PRの作成とコメントの送信は別の`gh`のコマンドなので、判定のスクリプトの確認は2回出る。人には、PRを作る前の確認で、本文の下書きとコメントを一度に示す。
- エージェントは、PRを作りコメントを送った時点で完了と報告する。人は、マージまでにPRの上で、直す、あとで行う、行わないを決める。
- あとで行うと決まったものだけをIssueにし、優先度はそのときに付ける。人がPRに書いた指摘は、「人の指摘」のIssueにする。

## タグと変更履歴

今は、タグも変更履歴（`CHANGELOG.md`）も作らない。手元のパスから読むプラグインは、`version`で固定されないためである（Plugin manifest reference）。変更の履歴は、マージコミットとPRの本文で見る。ハーネスを配る方法を決めるとき（例：ほかの人のPCで、手元のパス以外から入れる）に、タグと変更履歴の形を決めてここに書く。

## 機械で確かめるもの

`tests/run-test-suite.sh`は、テスト、`tests/linter-list.tsv`の確認、ShellCheckを1つのコマンドで動かす。CIは、bash 3.2のテストをmacOSのランナーで、新しいbashのテストとShellCheckをUbuntuのランナーで動かす。手元では、動かしたbashでだけ確かめられる（[`.harness/docs/architecture.md`の節「前提」](.harness/docs/architecture.md#前提)）。文章の確認は、[`rules/writing.md`の節「機械で止める規則」](rules/writing.md#機械で止める規則)に書く。

確かめ方は、次のとおりにする。

- 自分で書くbash（`grep`と`awk`）で確かめ、規則のまとまりごとにスクリプトを分ける。
- 今の文書と履歴に外れた例が無い規則は、機械では止めない（[判断の記録](docs/decisions/0020-writing-rule-split.md)）。
- 表記は、コードブロック、インラインのコード、YAMLの前付けの中を除く。そこの空白と記号は、文章の表記の規則に当たらないためである。
- 止める語の確認からは、`data/banned-word-list.txt`、`data/ambiguous-word-list.txt`、`tests/find-banned-word-case-list.tsv`を外す。止める語と確かめる語そのものを書いているためである。

止める語の一覧と確かめる語の一覧は、1行1語の`パターン<TAB>代わりの言い方<TAB>除く形（任意）`の形で置く。除く形は、行から消してから語を当てる。同じ行にある止める語を見逃さないためである。

名前のバッククォートは、`linters/find-missing-backquote.sh`が、`data/backquote-name-list.txt`の名前で確かめる。囲む名前の種類（例：スキル、gitのフック）は`rules/writing.md`の節「バッククォート」で決め、一覧にはこのリポジトリの文書に出る名前を書く。

次の3つの確認は、当てるファイルと外すファイルを、次のように決める。

- 文のあとの語句の確認（`scripts/find-phrase-after-sentence.sh`）は、すべてのMarkdownに当てる。置き場所の比べた案は、[判断の記録](docs/decisions/0065-phrase-after-sentence.md)に書く。
- 1台のPCの具体と推測の形の確認（`linters/find-unverified-or-pc-specific-word.sh`）は、変更の記録のほかのすべてのMarkdownの本文とYAMLの前付けに当て、語は`data/unverified-or-pc-specific-word-list.txt`に書く。変更の記録を外すのは、節「調べたこと」に推測を推測と書いて残すためである。節「出典」、インラインのコード、コードブロックは、原文とコマンドと出力の綴りなので見ず、前付けは、エージェントがスキルとサブエージェントを選ぶときに読む公開の文（例：`description`）なので見る。導入先には当てない。導入先の業務の言葉と、推測を推測と書く導入先の変更の記録まで止まるためである。比べた案は、[判断の記録](docs/decisions/0064-unverified-and-pc-specific-word.md)に書く。
- 実行の権限の確認（`linters/find-non-executable-script.sh`）は、まだ追加していないものも含めて、すべての`.sh`に当てる。

コミットメッセージの止める語は、gitの`commit-msg`のフックで止める（[判断の記録](docs/decisions/0037-commit-message-banned-word.md)）。このリポジトリのクローンごとに、エージェントが`configure-repository`の手順で、`pre-push`と`pre-commit`のフックと一緒に足す（`data/git-hook-setting-list.tsv`の4列目が`harness`の行）。手で足すときは、次の設定を、Claude Codeの外のシェルで1回動かす。サンドボックスの中のコマンドは、`.git/config`に書けないためである。`<ハーネスの場所>`は、このリポジトリの作業フォルダーの絶対パスで、gitは2.54以上が要る。

```bash
git config set hook.harness-commit-message.command "<ハーネスの場所>/scripts/find-banned-word.sh"
git config set hook.harness-commit-message.event commit-msg
```

止める語の一覧か確かめる語の一覧を直すcommitでは、メッセージに語を書かず、どの語かは差分で示す。メッセージに書くと、このフックで止まるためである。

確かめる語のパターンを変えるか消すPRでは、導入先の答えが外れる語があることを、PRの本文の方法に書く。語は書かず、差分で示す。答えが外れると、パターンを変えた語は導入先で決まっていない語になって聞き直され、外れた答えの行は導入先で消すまで語の確認のたびに知らされるためである（[`.harness/docs/features/harness-folder.md`の節「導入先ごとの語の一覧」](.harness/docs/features/harness-folder.md#導入先ごとの語の一覧)）。

コミットメッセージの形と、`rules/git.md`の差分100行の目安は、機械では確かめない。コミットメッセージは、導入先ごとに形が違うためである。

プラグインの設定（`.claude-plugin/`、`hooks/hooks.json`）を変えたら、手元で`claude plugin validate .`を動かし、出力をPRの本文の確かめ方に書く。CIには入れない。CIのランナーにClaude Codeを入れる手順とバージョンの管理が増え、前提にするコマンドを増やさない方針に合わないためである。

`--strict`は付けない。`--strict`では警告も失敗になり、節「タグと変更履歴」のとおり書かない`version`が、毎回警告に出るためである。

## 業界標準から外れる所

| 何を | 業界標準・公式の推奨 | 外れる理由 |
|---|---|---|
| シェルの長さ | 100行を超えたときの、構造化された言語への書き直し（Google Shell Style Guide） | 前提にするコマンドを増やさないため |
| ファイル名 | アンダースコア（Google Shell Style Guide） | スキルのフォルダー名がハイフンに決まっていて、1つにそろえるため |
| スキルの名前 | 動名詞（Skill authoring best practices） | 人が`/名前`で打つので短く命令として読め、動詞-対象も同じページで認められている形のため |
| `TODO`のコメント | `TODO`のコメント（Google Shell Style Guide） | 残っている作業を、コードの外のIssueで一覧にして数えるため |
| テストフレームワーク | bats-core | 判定の一覧を比べることが中心でbatsの機能をあまり使わず、外のコードを動かさないため |
| 行の長さ | 80文字の上限（Google Shell Style Guide） | 日本語は、1文字が2文字分の幅になるため |
| 日本語の文章の確認 | textlint | 前提にするコマンドを増やさないため |
| git configの一覧の読み方 | `git config get --all`（git-config） | `git config get`がgit 2.46.0からで、それより古いgitでも同じ読み方で動かし、`--get-all`は非推奨でもgit 3.0で互換性を壊す変更の一覧（BreakingChanges）に無いため |

## 出典

- [ADRの書き方の記事](https://zenn.dev/tokium_dev/articles/adr-authoring-guideline)：「本文を書き換える必要があるか」（確かめた日：2026-11-06）
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)の節「When to use Shell」：「you should rewrite it in a more structured language now.」、節「Source Filenames」：「Lowercase, with underscores to separate words if desired.」、節「TODO Comments」：「Use TODO comments for code that is temporary, a short-term solution, or good-enough but not perfect.」、節「Line Length and Long Strings」：「Maximum line length is 80 characters.」（確かめた日：2026-10-23）
- [git-config 2.54.0](https://git-scm.com/docs/git-config/2.54.0)の節「DEPRECATED MODES」：「Replaced by git config get [--value=<pattern>] --all <name>.」、[git-config 2.46.0](https://git-scm.com/docs/git-config/2.46.0)：「git config get」の書き方があること、[git-config 2.45.0](https://git-scm.com/docs/git-config/2.45.0)：その書き方が無いこと（確かめた日：2026-10-23）
- [BreakingChanges](https://git-scm.com/docs/BreakingChanges)：`--get-all`が無いこと（確かめた日：2026-10-23）
- [bashのNEWS](https://git.savannah.gnu.org/cgit/bash.git/plain/NEWS)のbash-4.0の項：「The shell provides associative array variables」（確かめた日：2026-10-23）
- [bashのCHANGES](https://git.savannah.gnu.org/cgit/bash.git/plain/CHANGES)のbash-4.4-rc2の3a：「no longer throws an unbound variable error.」（確かめた日：2026-10-23）
- [Bash Reference Manual「The Set Builtin」](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)の`-e`：「part of the test in an if statement」（確かめた日：2026-10-23）
- [cli/cli](https://github.com/cli/cli)のソース`pkg/githubtemplate/github_template.go`：「strings.HasSuffix(tf.Name(), ".md")」（確かめた日：2026-10-23）
- [REST API endpoints for rules](https://docs.github.com/en/rest/repos/rules)の節「Create a repository ruleset」：`conditions.ref_name.include`の「Also accepts ~DEFAULT_BRANCH to include the default branch or ~ALL to include all branches.」、`deletion`の「Only allow users with bypass permissions to delete matching refs.」、`non_fast_forward`の「Prevent users with push access from force pushing to refs.」（確かめた日：2026-11-25）
- [Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)の節「Block force pushes」：「will be unable to change or rename the default branch unless they are authorized to bypass the ruleset.」（確かめた日：2026-11-25）
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)の節「Naming conventions」：「Consider using gerund form (verb + -ing) for Skill names」、「Action-oriented: `process-pdfs`, `analyze-spreadsheets`」（確かめた日：2026-10-23）
- [Plugin manifest reference](https://code.claude.com/docs/en/plugins-reference)の`version`：「and a plugin loaded in place from a marketplace added from a local path aren't pinned by this field.」（確かめた日：2026-10-23）
- [Commands](https://code.claude.com/docs/en/commands)の節「All commands」：表の`/plan`、`/code-review`、`/review`、`/security-review`、`/init`、`/feedback`の行と、`/design [brief]`の行（確かめた日：2026-10-23）
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)の節「Resolve skills that share a name」：「Both load, because plugin skills are namespaced as /plugin-name:skill-name」（確かめた日：2026-10-23）
- [Illustrating（Google Technical Writing）](https://developers.google.com/tech-writing/two/illustrations)の節「Write the caption first」：「It is often helpful to write the caption before creating the illustration.」、節「Constrain the amount of information in a single drawing」：「As a rule of thumb, don't put more than one paragraph's worth of information in a single diagram.」（確かめた日：2026-11-17）
