# 文書を要求、要件、設計、ルールとスキルに分け、設計は全体の説明、構成要素ごとの設計、判断の記録に分ける

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-24 |
| 関わる設計 | [`.harness/docs/architecture.md`の節「判断」](../../.harness/docs/architecture.md#判断) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

業務の側の要求とハーネスの側の方針が1つの文書にあると、ハーネスが何を満たせばよいかを読み取りにくい。設計を1つのファイルにすると、最初に読む量が多い。

## 判断

- 文書を、要求、要件、設計、ルールとスキルの4つに分ける。要求が要件の、要件が設計の、設計がルールとスキルの理由になる。1つの事実は、それを決めた文書の1か所にだけ書く。ルールの本文はルールにだけ書き、要件と設計は理由を書いてルールを指す。
- 設計は、全体の説明、構成要素ごとの設計、論点ごとの判断の記録に分ける。置き場所は、[判断の記録](0043-harness-document-form.md)に書く。
- PR、Issue、コミットの本文でも、どうなればよいかを「要求」と呼ぶ。

## 案

### 分け方

| 案 | 結果 | 理由 |
|---|---|---|
| 要求、要件、設計、ルールとスキルの4つに分ける | 採った | 利害関係者の要求の定義の結果を、システムの要件の定義の入力にする（SEBoK）。AIの開発ツールも、要件、設計、実装の計画に分ける（Kiro）。 |
| 要求と要件を1つにする | 採らなかった | 業務の側とハーネスの側が混ざる。 |
| 検証を足して5つにする | 採らなかった | 確かめ方は、`architecture.md`の要件の表の列と、常に読むルールの完了の条件で書ける。 |

### 設計の分け方

| 案 | 結果 | 理由 |
|---|---|---|
| 全体の説明、構成要素ごとの設計、論点ごとの判断の記録に分ける | 採った | 全体の説明で構成要素どうしの関係を追え、構成要素ごとの設計は要るときに読める。判断の記録は1つの判断を1つの短い文書に書く形（NygardのADR）で、理由を読む人は1つのファイルで済む。 |
| 1つのファイルにする | 採らなかった | 最初に読む量が多い。 |

### 本文の言葉

| 案 | 結果 | 理由 |
|---|---|---|
| PR、Issue、コミットの本文でも「要求」と呼ぶ | 採った | 文書の要求の節、変更の記録の要求の節、PRの本文で、同じ中身を同じ語で呼べる。 |
| 本文では「目的」と呼ぶ | 採らなかった | 導入先（ハーネスを入れるリポジトリ）の人には通じやすいが、文書の要求の節と語が食い違う。 |

## 結果と失うもの

ファイルの数とリンクが増える。要求を直したら、その要求を指す要件と設計も見直す。

## 見直す条件

判断の記録が増えて探しにくくなったら、話題ごとのフォルダーに分ける。

## 出典

- [Stakeholder Needs and Requirements（SEBoK）](https://sebokwiki.org/wiki/Stakeholder_Needs_and_Requirements)：「The outcome of the Stakeholder Needs Definition process is used as the basis of System Validation, as well as input into the System Requirements Definition process.」（確かめた日：2026-10-24）
- [Specs（Kiro）](https://kiro.dev/docs/specs/)：「Feature Specs guide you through requirements gathering, technical design, and implementation planning」（確かめた日：2026-10-24）
- [Documenting Architecture Decisions](https://www.cognitect.com/blog/2011/11/15/documenting-architecture-decisions)（Michael Nygard）：「One ADR describes one significant decision for a specific project.」（確かめた日：2026-10-24）
