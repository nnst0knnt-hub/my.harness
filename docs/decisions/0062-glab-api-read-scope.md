# `glab api`は、スキルが使う形と決まった問い合わせだけを確認なしで通す

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「`glab`の判定」](../../.harness/docs/features/protection.md#glabの判定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

GitLabの読み取りのAPIにも、秘密の値を返すものがある（例：CI/CDの変数の値、自分が作ったトリガーのトークン、Ownerへのプロジェクトの`runners_token`）。GraphQLでも、CI/CDの変数を読める。判定のスクリプトは、`gh api`では、書き込みのオプションの無い形と`mutation`の無いGraphQLを確認なしで通す。

## 判断

`glab api`は、スキルが使うエンドポイントの形と、ログインした人を読む`user`と、判定のスクリプトに書いたGraphQLの決まった問い合わせだけを確認なしで通す。ほかのGraphQLと秘密の値を返すエンドポイントの形は止め、ほかのエンドポイントは確認を求める。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| スキルが使う形と、決まった問い合わせだけを通す | 採った | 秘密の値を返す読み取りを、確認なしにエージェントの文脈に入れない。 |
| `gh api`と同じく、書き込みのオプションの無い形と`mutation`の無いGraphQLをすべて通す | 採らなかった | CI/CDの変数の値、トリガーのトークン、`runners_token`を、確認なしで読める。 |
| すべての`glab api`で確認を求める | 採らなかった | `resolve-review-comment`と`review-pr`の読み取りのたびに確認が出る。 |

## 結果と失うもの

スキルが新しいエンドポイントを使うたびに、判定のスクリプトとケースの一覧を直す。公開のリポジトリかは、Ownerに`runners_token`を返すプロジェクトのAPIでなく、GraphQLの決まった問い合わせで読む。

## 見直す条件

すべての導入先で、CI/CDの変数とトークンを読めないトークン（例：変数の権限を外したFine-grained token）を使うと決めたときに見直す。

## 出典

- [Projects API](https://docs.gitlab.com/api/projects/)の節「Retrieve a project」の`runners_token`：「Only visible if you have administrator access or the Owner role for the project.」（確かめた日：2026-11-23）
- [Pipeline trigger tokens API](https://docs.gitlab.com/api/pipeline_triggers/)の節「List project trigger tokens」：「The trigger token is displayed in full if the trigger token was created by the authenticated user.」（確かめた日：2026-11-23）
