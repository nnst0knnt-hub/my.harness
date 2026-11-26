# 人が読む文の読みやすさを、読み手の行動で定義する

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-17 |
| 関わる設計 | [`rules/writing.md`の節「読みやすさ」](../../rules/writing.md#読みやすさ) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

人が読む文書の多くを、ハーネスのリポジトリの持ち主は「なぜか読む気にならない」と感じていた。原因は、段落の先頭で何の話かがわからないこと、理由と退けた案に何をするかが埋もれること、意味の広い和語と作業の中で作った語を読み手が補うことだった。書き方の規則は語と表記を止めていたが、読みやすさが何かは決めていなかった。

## 判断

読みやすさを、想定した読み手が初めて読んで読み返さずに、何の話か、何をするか、なぜかを読み取り、次に何をするかを決められることと定義する。語の基準（例：作った語を使わない、同じものを同じ名前で呼ぶ）は誰が読む文書にも当て、構造と量（例：段落の先頭の要点、字数の上限）だけを、誰が読み誰が直すかで分ける。基準の表は、冒頭の表の「関わる設計」に書く。

## 案

### 定義のしかた

| 案 | 結果 | 理由 |
|---|---|---|
| 読み手の行動で定義し、基準を表にする | 採った | どの文が満たさないかを、読み手の側で確かめられる。基準は、公用文と開発者向けの手引きに合わせた（例：50～60字で読みにくくないかを見る、段落の最初の文に大事なことを書く）。 |
| 止める語を増やすだけにする | 採らなかった | 語を置き換えても、文の組み立ては変わらない。見つけた形を消すことを、直すことと取り違えるおそれもある。 |
| 全体の字数の目標を置く | 採らなかった | 短くすると意味が抜けることがあり、短くする前に説明を作るほうを先にする。人も、少ないから良いとは見ないと言った。 |

### 誰が読む文書かで分けるか

| 案 | 結果 | 理由 |
|---|---|---|
| 語の基準は人が読む文書とエージェントが読む文書の両方に当て、構造と量を分ける | 採った | プロンプトの書き方は出力の書き方に移るので、ルールに作った語が残ると、エージェントの返事と導入先の成果物にも出る。 |
| 人が読む文書だけに当てる | 採らなかった | ルールとスキルの文体が、そのままエージェントの返事に出続ける。 |

## 結果と失うもの

基準の多くは書く人が確かめ、機械では止めない。守られたかは、文書を書き直すエージェントが、別の文脈に読み手が補った所を挙げさせ、書き直す前と後の数で比べる。

## 見直す条件

書き直したあとも、別の文脈が挙げる補った所が減らないとき、定義か基準を見直す。

## 出典

- [公用文作成の考え方（建議）](https://www.bunka.go.jp/seisaku/bunkashingikai/kokugo/hokoku/pdf/93731901_01.pdf)の節「Ⅲ 伝わる公用文のために」の「３ 文の書き方」：「適当な長さは一概に決められないが、50～60字ほどになってきたら読みにくくなっていないか意識するとよい」、「一つの文で扱う論点は、できるだけ一つとする」、同じ節の「４ 文書の構成」：「文書の結論は、できれば最初の段落で示しておく」（確かめた日：2026-11-17）
- [Write accessible documentation](https://developers.google.com/style/accessibility)の節「Ease of reading」：「Place distinguishing and important information of a paragraph in the first sentence to aid in scannability.」（確かめた日：2026-11-17）
- [Anthropomorphism](https://developers.google.com/style/anthropomorphism)：「Don't attribute human qualities to software or hardware.」（確かめた日：2026-11-17）
- [Short and simple](https://digital.gov/guides/plain-language/principles/short-simple)の節「Consistency counts」：「You can confuse your audience if you use different terms for the same concept or object.」（確かめた日：2026-11-17）
- [読みやすくするスキルyomiyasuの記事](https://zenn.dev/algoartis/articles/0b1c731881b25c)の節「「ブラックリスト方式」は効果が薄い」：「しかし、表層の単語だけを個別に置き換えても、文章の骨格や統語構造（文の組み立て）は変わりません」、本文：「LLMは指示文の内容だけでなく、プロンプトの文体そのものを手本として模倣します」（確かめた日：2026-11-17）
- [AIの謎な説明文を直すスキル](https://zenn.dev/microsoft/articles/explain-before-shorten)の節「SKILL.md」：「「短く書く」より先に、「相手に口頭でどう説明するか」を考える」、「短くしたことで意味が失われたら、必要な言葉を戻す」（確かめた日：2026-11-17）
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)の節「Match your prompt style to the output you want」：「The formatting style used in your prompt might influence Claude’s response style.」（確かめた日：2026-11-17）
- [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)の冒頭：「Please do not merely treat these signs as the problems to be fixed; that could just make detection harder.」（確かめた日：2026-11-17）
