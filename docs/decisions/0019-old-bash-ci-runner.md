# bash 3.2のテストを、macOSのランナーで動かす

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-10-30 |
| 関わる設計 | [`features/ci.md`](../../.harness/docs/features/ci.md) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

macOSのPCでは、`scripts/`が、標準の`/bin/bash`（bash 3.2）とmacOSのコマンド（例：`grep`、`awk`）で動く。このリポジトリは公開のもので、GitHubの標準のランナーは、macOSのランナー（`macos-15`）も含めて無料で動く。

## 判断

bash 3.2のテストは、macOSのランナー（`macos-15`）の`/bin/bash`で動かす。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| macOSのランナー | 採った | macOSのPCと同じbashとコマンドで確かめられる。 |
| Ubuntuのランナーの上の`bash:3.2`のイメージ | 採らなかった | コマンド（例：`grep`、`awk`）がBusyBoxのものになり、macOSだけの違いを見つけられない。 |

## 結果と失うもの

macOSのPCが無い手元では、bash 3.2とmacOSのコマンドでテストを動かせず、pushのあとのCIの結果で知る。

## 見直す条件

macOSのランナーの`/bin/bash`がbash 3.2でなくなったときと、このリポジトリでmacOSのランナーに費用がかかるようになったとき（例：非公開にしたとき）に見直す。

## 出典

- [GitHub-hosted runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)の節「Standard GitHub-hosted runners for public repositories」：「Use of the standard GitHub-hosted runners is free and unlimited on public repositories.」、表の`macos-15`のある行（確かめた日：2026-11-23）
- [macOS 15](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)の節「Language and Runtime」：「Bash 3.2.57(1)-release」（確かめた日：2026-11-23）
