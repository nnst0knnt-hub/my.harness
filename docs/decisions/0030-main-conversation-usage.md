# 本体の会話の使用量を、作業の手順のまとまりごとにセッションを分けて減らす

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-15 |
| 関わる設計 | [`implement-change`](../../skills/implement-change/SKILL.md)の節「セッションの分け方」、[`investigate-code`](../../skills/investigate-code/SKILL.md)の節「調べ方」 |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

Claude Codeは、リクエストのたびに会話の全体を送る。文書の全体を1つのセッションで書き直したときは、本体の会話が使用量の76％を占め、リクエストの文脈は平均で約49万トークンだった。数は、セッションの記録（Claude Codeが残す会話のjsonl）の`usage`の合計である。

キャッシュの寿命の既定は、本体の会話が契約の使用量の中で1時間、API keyと追加の料金で5分、サブエージェントが5分で、人が設定で選べる。

## 判断

変更の記録の作業の手順を、まとまりごとに新しいセッションで進め、変更の記録で引き継ぐ。調査で広く探す所は、調べ役に任せる。キャッシュの寿命は既定のままにする。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 作業の手順のまとまりごとにセッションを分け、変更の記録で引き継ぐ | 採った | 分けて作った2つのPRでは、リクエストあたりの本体の会話の金額が、1つのセッションの0.24ドルから0.12ドルと0.10ドルに、平均の文脈が約28万と約25万トークンに減った。 |
| 全文を読む作業を調べ役に任せ、要点だけを受け取る | 採った | 調査で広く探す所だけに当てる。公式の文書は量の多い出力をサブエージェントに任せるよう勧めるが、読み落としが増えるかは測っていないので、結論の根拠にする行は本体の会話が読む。 |
| 本体の会話のキャッシュの寿命を、1時間から5分にする | 採らなかった | 人の答えやコマンドを待つ、5分を超えて1時間以内の間隔のあとは文脈を書き込み直すとして見積もると、使用量が1つのセッションでは約60％、分けた2つのPRでは約18％と約1％増える。 |
| `/usage`の内訳で測る | 採らなかった | 内訳は、PCの直近の24時間か7日の割合で、PRやセッションごとに分けられない。 |

## 結果と失うもの

- 新しいセッションは、ルールと変更の記録を読み直して始まり、10回目のリクエストまでに文脈が約10万～16万トークンになった。
- 変更の記録に書かなかった事実は、次のセッションに渡らない。
- まとまりの中が長いと、分けても文脈は大きくなる（例：平均で約39万トークンのセッション）。
- 比べたPRは中身が違い、差のすべてが分けたことによるとは言えない。金額は、公式の料金表の単価での見積もりである。

## 見直す条件

- 導入先で、変更の記録に書かなかった事実による手戻りが続いたとき
- API keyか追加の料金で使う導入先が出たとき（本体の会話の既定の寿命が5分になる）
- キャッシュの寿命の既定か、単価が変わったとき

## 出典

- [Manage costs effectively](https://code.claude.com/docs/en/costs)の節「Why usage climbs in a long session」：「Claude Code sends your full conversation with every request, and each time Claude uses tools it sends another request carrying that batch of tool results.」（確かめた日：2026-11-15）
- 同じページの節「Delegate verbose operations to subagents」：「the verbose output stays in the subagent's context while only a summary returns to your main conversation.」（確かめた日：2026-11-15）
- 同じページの節「Plan usage breakdown」：「Press `d` or `w` to switch between the last 24 hours and the last 7 days.」（確かめた日：2026-11-15）
- [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching)の節「Which TTL each request gets」：「Unless you choose a TTL yourself, Claude Code requests the one-hour TTL only on a Claude subscription within your plan's included usage.」、「Claude Code drops the main conversation to the five-minute TTL」（確かめた日：2026-11-15）
- 同じページの節「Choose the TTL yourself」：「the promptCacheTtl setting, or the CLAUDE_CODE_PROMPT_CACHE_TTL environment variable」（確かめた日：2026-11-15）
- 同じページの節「Subagents and the cache」：「so they get five minutes even on a subscription until you choose a longer one.」（確かめた日：2026-11-15）
- [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)の節「Model pricing」：表の「Claude Opus 5.5」の行の「$4 / MTok」「$5 / MTok」「$8 / MTok」「$0.20 / MTok」「$20 / MTok」（確かめた日：2026-11-15）
