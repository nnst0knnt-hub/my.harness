# GitHubとGitLabの導入先を、同じスキルと判定で扱う

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`rules/git.md`の節「ホストの種類」](../../rules/git.md#ホストの種類)、[`features/skill.md`](../../.harness/docs/features/skill.md)、[`features/protection.md`の節「`glab`の判定」](../../.harness/docs/features/protection.md#glabの判定) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 人が、ハーネスはGitHubとGitLabの2つを前提にすると決めた。スキルはPRの操作を`gh`で行い、GitLabでは動かない。
- `glab`は、MRの操作のほかに、トークンと秘密の値を出す形と、外でほかのプログラムを動かす形を持つ。
- GitLabの読み取りのAPIにも、秘密の値を返すもの（CI/CDの変数、`runners_token`）がある。

## 判断

ホストの種類はリモートのURLのホストで決め、決められないホストは人に聞いて導入先ごとのルールに書く。ホストごとの手順が多いスキルは参照のファイルをホストごとに分け、`glab`も判定のスクリプトを通して、許す形だけを確認なしで通す。

## 案

### ホストの種類の決め方

| 案 | 結果 | 理由 |
|---|---|---|
| URLのホストで決め、ほかのホストは導入先ごとのルールを読む | 採った | 多くの導入先で設定が要らない。 |
| すべての導入先で、導入のときに種類を書く | 採らなかった | URLでわかる導入先にも1行増え、導入の前は決まらない。 |
| `gh`と`glab`のどちらが認証されているかで決める | 採らなかった | 両方を認証したPCでは決まらない。 |

### ホストごとの手順の置き場所

| 案 | 結果 | 理由 |
|---|---|---|
| 手順の多い2つのスキルは参照のファイルに分け、ほかは`SKILL.md`に並べる | 採った | 毎回の文脈に入るのは、使うホストの手順だけになる。 |
| すべてを`SKILL.md`に並べる | 採らなかった | 使わないホストの手順も毎回読む。 |
| ホストごとのコマンドを、スキルの外の1つのファイルに集める | 採らなかった | 手順を読むたびに、2つのファイルを行き来する。 |

## 結果と失うもの

自前のホストの導入先では、導入先ごとのルールが1行増える。2つのスキルは参照のファイルが2つになり、流れを変えるときに両方を直す。スキルが新しいエンドポイントを使うたびに、判定の一覧とケースを直す。

## 見直す条件

3つ目のホストの種類を足すときと、判定がPCの`glab`のトークンの種類と権限を確かめられるようになったときに見直す。トークンの種類と、Fine-grained tokenで秘密の値を読めなくしても判定の止める形を残す理由は、[`glab`のトークンの判断の記録](0048-glab-token.md)に書く。

## 出典

- [Projects API](https://docs.gitlab.com/api/projects/)の`runners_token`：「Only visible if you have administrator access or the Owner role for the project.」（確かめた日：2026-11-19）
- [Pipeline trigger tokens API](https://docs.gitlab.com/api/pipeline_triggers/)：「The trigger token is displayed in full if the trigger token was created by the authenticated user.」（確かめた日：2026-11-19）
