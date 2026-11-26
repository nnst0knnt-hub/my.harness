# CI

| 項目 | 内容 |
|---|---|
| 確かめたコミット | `b7d78e4` |
| 関わる変更の記録 | なし |

ハーネスのリポジトリのCIは、pushのたびに、テスト、文章の確認、ShellCheckを、エージェントとは別のサーバーで動かす。結果は、PRのチェックにも出る。導入先のCIは、ハーネスが作らず、決まった3つの場面で読むだけである。この文書には、CIで何をどこで動かすかと、導入先のCIの使い方を書く。

## 背景

エージェントは、手元の確認を飛ばしたまま、完了と言うことがある。同じ確認を別のサーバーでもう一度動かせば、飛ばしたことに気づける。

## 要求

CIは、`architecture.md`の名前付きの要件「ハーネス自身の確かめ」（[節「確かめの要件」](../architecture.md#確かめの要件)）を満たす。導入先のCIは作らない（[`architecture.md`の節「範囲の外」](../architecture.md#範囲の外)）。

## 業務のルール

### ハーネスのリポジトリのCI

| ルール | 理由 |
|---|---|
| 手元では、`tests/run-test-suite.sh`の1つのコマンドで、CIと同じ確認を動かす。 | エージェントがpushの前に、同じ確認で落ちるかを見られる。 |
| bash 3.2のテストはGitHubのmacOSのランナーの`/bin/bash`で、新しいbashのテストとShellCheckはUbuntuのランナーで動かす。 | 導入先で動くスクリプトは、macOSの標準のbash 3.2でも、新しいbashでも動く必要がある（[`architecture.md`の節「制約」](../architecture.md#制約)）。 |

確かめるものの一覧は、[`CONTRIBUTING.md`の節「機械で確かめるもの」](../../../CONTRIBUTING.md#機械で確かめるもの)に書く。

### 導入先での文章の確認

| ルール | 理由 |
|---|---|
| 文章の語と表記を確かめる`scripts/`のスクリプトは、導入先でも、エージェントが書いたあとに動かす。表記は、導入先に表記のルールが無いときだけ確かめる。 | 導入先に表記のルールがあれば、そちらが先である（[`rules/always-read.md`の節「導入先で書き方を決める順」](../../../rules/always-read.md#導入先で書き方を決める順)）。 |
| 導入先では、文章の確認を、Claude Codeのフックとgitのフックで強制しない。 | 導入先のチームの進め方を変えない（[`architecture.md`の節「範囲の外」](../architecture.md#範囲の外)）。 |
| ハーネスのリポジトリだけは、コミットメッセージの止める語を、gitの`commit-msg`のフックで止める。 | 比べた案は、[判断の記録](../../../docs/decisions/0037-commit-message-banned-word.md)に書く。 |

### 導入先のCI

ハーネスが導入先のCIを使うのは、次の3つの場面だけである。

| 場面 | すること |
|---|---|
| 導入のとき | `configure-repository`が、CIの定義のファイルを読み、テストとlintのコマンドを提案する。 |
| 自分のPRを作ったあと | エージェントが、CIの結果を読み、落ちていれば直す。結果の読み取りは確認を求めないが、GitLabのジョブのログを読むときと、作業フォルダーの中を指すgitの設定がある導入先（例：huskyの`core.hooksPath`）で`glab`を動かすときは、確認が出る（[`protection.md`の節「`glab`の判定」](protection.md#glabの判定)）。 |
| ほかの人のPRのレビューと、セキュリティの確認のとき | `review-pr`と`audit-security`が、対象のPRのCIの結果を読み、機械の確認の出力としてレビュー役に渡す。 |

## 関わるコードの名前

役割は、[`architecture.md`の節「コードの配置」](../architecture.md#コードの配置)に書く。

- `.github/workflows/test-and-lint.yml`
- `tests/run-test-suite.sh`
- `tests/linter-list.tsv`

## 判断

| 判断 | 誰が決めたか | 理由 |
|---|---|---|
| bash 3.2のテストは、macOSのランナー（`macos-15`）の`/bin/bash`で動かす。 | [判断の記録](../../../docs/decisions/0019-old-bash-ci-runner.md) | macOSのPCと同じbashとコマンドで確かめられる。 |
| 導入先のCIは作らず、導入のとき、自分のPRを作ったあと、ほかの人のPRのレビューと、セキュリティの確認のときの3つの場面で読む。 | エージェントの案 | 導入先のチームの進め方（例：CI）を変えない（[`architecture.md`の節「範囲の外」](../architecture.md#範囲の外)）。 |
| 1台のPCの具体と推測の形は、ハーネスのリポジトリだけのlinterで、変更の記録のほかのすべてのMarkdownに当てて止める。 | [判断の記録](../../../docs/decisions/0064-unverified-and-pc-specific-word.md) | 公開するルールとスキルに入った語と形も止まり、導入先の業務の言葉は止めない。 |
| 文のあとに語句を続けたセルと項目は、`scripts/`のスクリプトで止め、導入先でも表記のルールが無いときに当てる。 | [判断の記録](../../../docs/decisions/0065-phrase-after-sentence.md) | どの導入先でも、同じ基準で見つけられる。 |
