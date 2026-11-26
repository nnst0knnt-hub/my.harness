# 変更の記録と今の説明を分ける

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-23 |
| 関わる設計 | [`features/harness-folder.md`の節「`.harness/docs/`の形」](../../.harness/docs/features/harness-folder.md#harnessdocsの形) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

コードには、なぜその実装になったかが残らず、文書に残していない背景は、次のセッションのAIに伝わらない（[`.harness/docs/architecture.md`の節「背景」](../../.harness/docs/architecture.md#背景)）。

## 判断

`.harness/docs/`を、マージされて「完了」になったあとは書き換えない変更の記録（`changes/`）と、作業の終わりに今の状態へ直す今の説明に分ける。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 変更の記録と今の説明に分ける | 採った | 決着した提案は、その時点の文書として扱い、今の仕様としては扱わない（PEP 1）。今の状態は、今の説明だけを読めばわかる。 |
| 1つの文書を、変更のたびに書き換える | 採らなかった | 当時の背景と判断が、書き換えるたびに消える。 |

## 結果と失うもの

今の説明がコードと食い違えば、今の動きはコードを正とする。

今の説明では、関わるコードを、リンクではなく名前で書く。リンクは古くなるためである。

## 出典

- [PEP 1](https://peps.python.org/pep-0001/)の節「PEP Maintenance」：「Once resolution is reached, a PEP is considered a historical document rather than a living specification.」（確かめた日：2026-10-23）
- [Using Copilot CLI as your AI SME](https://docs.github.com/en/copilot/tutorials/use-an-ai-sme)の節「2. Ground answers in the code, not the docs」：「If a documentation file conflicts with the code, treat the code as the source of truth.」（確かめた日：2026-10-23）
- [ARCHITECTURE.md](https://matklad.github.io/2021/02/06/ARCHITECTURE.md.html)：「Do not directly link them (links go stale).」（確かめた日：2026-10-23）
