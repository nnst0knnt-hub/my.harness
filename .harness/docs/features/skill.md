# スキル

| 項目 | 内容 |
|---|---|
| 確かめたコミット | `b7d78e4` |
| 関わる変更の記録 | なし |

スキルは、作業ごとの手順を書いたMarkdownのファイル（`skills/<スキルの名前>/SKILL.md`）で、ハーネスには8つある。エージェントは、依頼に合うスキルを選んで読み、手順のとおりに進める。この文書には、スキルと作業の対応、スキルがハーネスのファイルを読む方法、セッションの分け方、向き先のブランチの書き方、`add-rule`のIssueの書き方、答えたコメントの見分け方、テンプレートの置き場所を書く。手順の中身は、それぞれのスキルに書く。

## 背景

エージェントは、作業の種類ごとに、確かめることと人に聞くことが違う（[`architecture.md`の節「作業の種類」](../architecture.md#作業の種類)）。手順を作業ごとに決めておかないと、エージェントが確かめることを飛ばし、人が見つけて直す。

## 要求

スキルは、`architecture.md`の名前付きの要件のうち、「作業ごとのスキル」「スキルの選択」（[節「作業の要件」](../architecture.md#作業の要件)）と、「スキルの形式」（[節「構成の要件」](../architecture.md#構成の要件)）を満たす。スキルの名前の規則は、[`CONTRIBUTING.md`の節「スキルとサブエージェントの名前」](../../../CONTRIBUTING.md#スキルとサブエージェントの名前)に書く。

## 業務のルール

スキルと作業は、次のように対応する。

| スキル | 役割 | 作業 |
|---|---|---|
| `investigate-code` | コードを変えずに調べ、根拠を付けて報告する。 | 調査 |
| `propose-change` | 実装の前に変更の記録を書き、人の承認を得る。 | 計画 |
| `implement-change` | 変更の記録の作業の手順を進め、最後に今の説明を直す。 | 機能の追加、不具合の修正、リファクタリング、性能の改善、依存や環境の更新、データの変更、インフラの変更 |
| `audit-security` | セキュリティを確かめる。 | セキュリティの確認 |
| `resolve-review-comment` | 指摘ごとに直すかを決め、直すか、直さない理由を返す。 | 指摘への対応 |
| `review-pr` | ほかの人のPRに、指摘の案を作る。 | ほかの人のPRのレビュー |
| `configure-repository` | 導入先を読み、人が承認した導入の設定を書く。 | 導入 |
| `add-rule` | 指摘と気づきを記録する。その導入先だけのことは導入先ごとのルールに、どの導入先でも守ることはハーネスのリポジトリのIssueかPRにし、人が指摘した語は導入先ごとの語の一覧に足す。 | ハーネスの改善 |

| ルール | 理由 |
|---|---|
| スキルは、`SessionStart`のフックが渡すハーネスの場所から、ハーネスの`rules/`を読む。本文には「ハーネスの`rules/quality.md`」のように書く。 | スキルのフォルダーの外にあるファイルを、導入先の作業フォルダーと取り違えずに読める。 |
| スキルの`references/`と`assets/`は、スキルのフォルダーからの相対パスで書く。 | Agent Skillsの仕様のとおりで、ほかのエージェントでも読める。 |
| ホストごとの手順は、`review-pr`と`resolve-review-comment`では`references/github.md`と`references/gitlab.md`に分け、ほかのスキル（`implement-change`、`audit-security`、`configure-repository`）では`SKILL.md`の中に並べる。エージェントは、PRを送るホストの種類（[`rules/git.md`の節「ホストの種類」](../../../rules/git.md#ホストの種類)）の参照のファイルだけを読む。 | 毎回の文脈に入るのは、使うホストの手順だけになる。2つのスキルは手順の半分ほどがホストごとで、ほかのスキルのホストごとのコマンドは表1つほどである。 |
| スキルとルールは、PRの向き先を「向き先のブランチ」と書き、コマンドでは`<向き先のブランチ>`と書く。向き先が`main`でない導入先では、`configure-repository`が導入先ごとのルールに書く（[`rules/git.md`の節「手元のマージ」](../../../rules/git.md#手元のマージ)）。 | 向き先が`main`の導入先では、導入先ごとのルールに何も書かずに、`main`として読める。 |
| `implement-change`は、作業の手順のまとまりを終え、次のまとまりを変更の記録だけで始められるときに、新しいセッションで続けるよう人に勧める。 | Claude Codeはリクエストのたびに会話の全体を送るので、セッションが長いほど、本体の会話の使用量が増える（この文書の節「前提」）。 |
| `add-rule`は、ハーネスのリポジトリのIssueの題、本文、コメントに、導入先の名前、業務の言葉とルール、コード、秘密情報を書かず、どの導入先でも起きる形で書く。 | Issueは導入先と別の人が読み、公開のリポジトリでは誰でも読めて、消しても読まれた中身は戻らない。 |
| どの導入先でも守ることは、Claude Codeの自動の記憶（Claude Codeが、PCごとに自分で書いて次のセッションで読むメモ）に書かない。 | 自動の記憶はPCとリポジトリごとに保存され、ほかのPCとほかの導入先では読まれない（How Claude remembers your project）。 |
| エージェントが答えたか、人の判断を待つコメントには、表示されないHTMLのコメント`<!-- my-harness -->`を付ける（[`rules/review.md`の節「レビューのコメント」](../../../rules/review.md#レビューのコメント)）。 | `resolve-review-comment`が、答えて相手の返事を待っているスレッドを見分けるためである。 |
| `resolve-review-comment`は、スレッドの最後のコメント（GitLabでは、discussionのsystemでない最後のnote）に`<!-- my-harness -->`があれば、そのスレッドを対応の一覧から外す。 | 最後に書いたのがエージェントなら、相手の返事を待っている。GitLabでは、普通のコメントもdiscussionとして返る。 |
| `review-pr`は、ほかの人のPRに送る指摘に`<!-- my-harness -->`を付けない。 | 付けると、PRの作者の`resolve-review-comment`が、作者の答えを待つ指摘を一覧から外す。 |
| テンプレートは、そのファイルを作るスキル1つの`assets/`に置く。変更の記録のテンプレートは`propose-change`が持ち、`implement-change`は変更の記録を作らない。 | 変更の記録が無ければ、`implement-change`は`propose-change`を使う。 |

## 関わるコードの名前

役割は、[`architecture.md`の節「コードの配置」](../architecture.md#コードの配置)に書く。

- `skills/`の8つのフォルダー（スキルの名前と同じ）
- `skills/propose-change/assets/change.md`
- `skills/implement-change/assets/feature.md`
- `skills/configure-repository/assets/`
- `skills/review-pr/references/`、`skills/resolve-review-comment/references/`

## 前提

| 前提 | 理由 |
|---|---|
| Claude Codeは、リクエストのたびに会話の全体を送る。 | 同じ作業でも、セッションが長いほど、1回のリクエストの使用量が増える。測った結果は、[判断の記録](../../../docs/decisions/0030-main-conversation-usage.md)に書く。 |

## 判断

| 判断 | 誰が決めたか | 理由 |
|---|---|---|
| スキルを8つにし、流れが同じ7つの作業を`implement-change`にまとめる。 | [判断の記録](../../../docs/decisions/0005-skill-count.md) | 同じ流れの手順を1か所に書ける。 |
| `SessionStart`のフックがハーネスの場所を渡し、スキルはその場所からハーネスの`rules/`を読む。 | [判断の記録](../../../docs/decisions/0026-skill-rule-path.md) | 常に読むルールと同じ書き方で読める。ほかのエージェントでも、セッションの始めに場所を渡せれば、同じ本文で動く。 |
| 変更の記録の作業の手順を、まとまりごとに新しいセッションで進め、変更の記録で引き継ぐ。 | [判断の記録](../../../docs/decisions/0030-main-conversation-usage.md) | 分けて作った2つのPRでは、本体の会話のリクエストあたりの金額が、1つのセッションの0.24ドルから0.12ドルと0.10ドルに減った。 |
| ホストごとの手順が多い`review-pr`と`resolve-review-comment`は、参照のファイルをホストごとに分け、ほかのスキルは`SKILL.md`の中にホストごとのコマンドを並べる。 | [判断の記録](../../../docs/decisions/0046-gitlab-support.md) | 毎回の文脈に入るのは、使うホストの手順だけになる。 |
| PRの向き先のブランチは、`configure-repository`が既定のブランチとチームの文書から読み、`main`でなければ導入先ごとのルールに1行書く。 | [判断の記録](../../../docs/decisions/0050-pull-request-base-branch.md)（人の回答、2026-11-23） | 判定のスクリプトを変えずに、毎回のセッションで値が文脈に入る。 |
| `add-rule`は、Issueを作る前に、`gh`のアカウントと書き込みの権限を示し、そのアカウントで作るか、題と本文とラベルだけを受け取るかを人が選ぶ。 | 人の回答（2026-11-23） | 書き込みの権限の無いアカウントでは、作るときに付けたラベルが黙って捨てられる（REST API endpoints for issues）。導入先のPCで使えるアカウントに依らずに、指摘を失わない。 |

### 答えたコメントの見分け方

| 案 | 結果 | 誰が決めたか | 理由 |
|---|---|---|---|
| スレッドの最後のコメントの`<!-- my-harness -->`で見分ける | 採った | エージェントの案 | 人とエージェントが同じアカウントで書いても、エージェントが書いたコメントだけを見分けられる。 |
| 書いた人の名前で見分ける | 採らなかった | エージェントの案 | 人とエージェントが同じアカウントで書く導入先で、人の答えも外してしまう。 |
| 最後のコメントに、コミットのSHAのリンクがあるかで見分ける | 採らなかった | エージェントの案 | 人の答えにリンクがあると、誤って外す。 |
| 付けるHTMLのコメントを、答えたものと判断を待つもので2種類にする | 採らなかった | エージェントの案 | 読む側の無いHTMLのコメントが増える。 |
| `<!-- my-harness -->`があり、書いた人が自分のときだけ外す | 採らなかった | エージェントの案 | 自分のPRに`review-pr`を使うと、同じアカウントなので、待つべき指摘が外れる。 |

### テンプレートの置き場所

| 案 | 結果 | 誰が決めたか | 理由 |
|---|---|---|---|
| そのファイルを作るスキル1つの`assets/`に置く | 採った | エージェントの案 | Agent Skillsの仕様の`assets/`の使い方（Specification）に合い、同じ中身が1か所だけになる。 |
| 使うスキルごとにコピーを置く | 採らなかった | エージェントの案 | 同じ中身が2か所以上になる。 |
| プラグインのルートに置く | 採らなかった | エージェントの案 | Agent Skillsの仕様の外になり、ほかのエージェントで読む方法が要る。 |

`propose-change`を通さずに変更の記録を作る場面が多ければ、使うスキルごとにコピーを置き、同じ中身かをCIで確かめる形に変える。変更の記録の見出しがそろわないことが多ければ、見出しを比べるスクリプトを足す。多いかは、導入先で使って人が決める。

## 出典

- [How Claude remembers your project](https://code.claude.com/docs/en/memory)の節「Storage location」：「Auto memory is machine-local.」、「The `<project>` path is derived from the git repository, so all worktrees and subdirectories within the same repo share one auto memory directory.」（確かめた日：2026-10-23）
- [Specification](https://agentskills.io/specification)（Agent Skills）の節「assets/」：「Templates (document templates, configuration templates)」（確かめた日：2026-10-23）
- [REST API endpoints for issues](https://docs.github.com/en/rest/issues/issues)の節「Create an issue」の`labels`：「Only users with push access can set labels for new issues.」、「Labels are silently dropped otherwise.」（確かめた日：2026-11-23）
