# 古いgitを、セッションの始めに1回知らせる

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-23 |
| 関わる設計 | [`features/protection.md`の節「フック」](../../.harness/docs/features/protection.md#フック)、[`features/protection.md`の節「gitのフック」](../../.harness/docs/features/protection.md#gitのフック) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- ハーネスは、保護するブランチへのpushと、秘密情報を含むcommitとpushを、gitの設定で足したフック（`pre-push`、`pre-commit`）でも止める。この足し方はgit 2.54からで、古いgitではフックが動かない。
- 古いgitでも、エージェントのpushは、判定のスクリプトが保護するブランチに届かない形にしている。秘密情報を含むcommitと、人がClaude Codeの外でするcommitとpushは止まらない。
- 環境を確かめるスクリプトは古いgitを示すが、人が動かすときにだけ動く。導入のあとに古いgitのPCで使い始めた人は、動かさないかぎり気づけない。

## 判断

gitが2.54より古いか見つからなければ、セッションの始めのフックが、環境の状態の表にgitの行を出し、働かない保護と直し方の段落を出す。エージェントは、セッションの最初の返事で、それを人に1回伝える。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| セッションの始めに1回知らせる | 採った | 人は、毎回のセッションで古いgitに気づける。確認の画面を増やさずに、人がClaude Codeの外でする操作が守られないことも伝えられる。 |
| エージェントのcommitとpushのたびに確認を求める | 採らなかった | 確認の画面からは秘密情報があるかが見えず、毎回出ると読まずに認めるようになる。人がClaude Codeの外で動かすcommitも守れない。 |
| 環境を確かめるスクリプトだけで示す | 採らなかった | 人がスクリプトを動かすまで、古いgitが見えない。 |

## 結果と失うもの

古いgitのPCでは、セッションの始めの文脈に、表の1行と段落が増える。gitを2.54以上にできないPCでは、セッションごとに同じことが人に伝わる。

セッションの始めのフックは、毎回`git --version`を1回動かす。

## 見直す条件

gitを2.54以上にできない導入先に入れるときに見直す。その導入先ではセッションごとに同じ知らせが出るので、`pre-commit`のようなフックを`.git/hooks/`に置く形と比べる。

## 出典

- [git-hook 2.54.0](https://git-scm.com/docs/git-hook/2.54.0)の節「DESCRIPTION」：「git config set hook.<some-name>.command <path-to-script>」（確かめた日：2026-11-23）
- [Hooks reference](https://code.claude.com/docs/en/hooks)の節「SessionStart」：「Claude's first response still waits for the hooks to finish, so their context reaches Claude.」（確かめた日：2026-11-23）
