# 導入先の既存の書き方を読む所

`configure-repository`が、導入先（ハーネスを入れるリポジトリ）の既存の書き方をどこで読むかの表である。

- 読む所は例で、導入先の言語とツールに合わせて探す。
- 技術ごとの知識はハーネスに持たせず、見つけたファイルの中身と、そのツールの公式の文書で確かめる（ハーネスのリポジトリの`.harness/docs/architecture.md`の節「範囲の外」）。
- チームのルールは、導入先のチームが書いたルール（例：`CONTRIBUTING.md`、`CLAUDE.md`）である。ハーネスが書く導入先ごとのルール（`.harness/rules/always-read.md`）とは別のものである。

| 項目 | 読む所 | 案にすること |
|---|---|---|
| テスト、lint、ビルドのコマンド | CIの定義（例：`.github/workflows/`、`.gitlab-ci.yml`）、パッケージの定義（例：`package.json`の`scripts`、`composer.json`の`scripts`、`Makefile`、`pyproject.toml`）、`README.md`、`CONTRIBUTING.md` | CIが動かすコマンドを先にする。手元で動かす前に要ること（例：依存のインストール、データベースの起動）も書く。 |
| コミットメッセージの1行目 | チームのルール、コミットの形を確かめる設定（例：`commitlint.config.js`）、直近の履歴（`git log -n 30 --format=%s`） | チームのルールか設定で形が決まっていればその形を書き、無ければ直近の履歴に多い形（例：`feat: `のようなプレフィックスの有無、言語）を書く。 |
| コミットメッセージの本文 | チームのルールと、直近の履歴の本文（`git log -n 30 --format=%B`） | チームのルールで決まっていなければ、本文の形を人に聞く。履歴に本文が無いことを、書かないと決めた証拠にしない。 |
| ブランチ名 | チームのルールと、リモートのブランチ（`git branch -r --sort=-committerdate`） | 多い形（例：`feature/`のような区切り、チケットの番号の有無）を書く。 |
| PRのテンプレート | `.github/pull_request_template.md`、`.github/PULL_REQUEST_TEMPLATE/`、`docs/pull_request_template.md`、ルートの`pull_request_template.md`、GitLabの`.gitlab/merge_request_templates/` | 場所だけを書く。PRを作るときに、その見出しで書く（ハーネスの`rules/git.md`の節「PRの題と本文」）。 |
| 表記のルール | 文章のlintの設定（例：`.textlintrc`、`.markdownlint.json`） | あれば場所を書き、ハーネスの表記の確認を当てないことを書く（常に読むルールの節「書く前に読むファイル」）。 |
| `CLAUDE.md`と`AGENTS.md` | ルートとサブフォルダーの`CLAUDE.md`と`AGENTS.md`、`.claude/CLAUDE.md`、`.claude/rules/` | 中身をコピーせず、ほかの項目で使う規則の場所と、ハーネスのルールと食い違う所を示す。 |

- コミットメッセージの本文の形を聞く理由は、ハーネスのコミットメッセージの本文の判断の記録（`docs/decisions/0031-commit-message-body.md`）に書く。
- PRのテンプレートは、`.github/PULL_REQUEST_TEMPLATE.md`のような大文字の名前も探す。GitHubは、テンプレートのファイル名の大文字と小文字を区別しないためである。
- 常に読むルールは、フックが毎回渡す、ハーネスの`rules/always-read.md`と導入先ごとのルールである。

## 出典

- [About issue and pull request templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)の節「Pull request templates」：「Pull request template filenames are not case sensitive, and can have an extension such as .md or .txt.」（確かめた日：2026-11-15）
