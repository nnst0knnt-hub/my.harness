# 秘密鍵だけを入れるファイルと、`glab`の設定のファイルのReadを止める

| 項目 | 内容 |
|---|---|
| 状態 | 採った |
| 決めた日 | 2026-11-19 |
| 関わる設計 | [`features/protection.md`の節「権限」](../../.harness/docs/features/protection.md#権限) |
| 語の意味 | [`.harness/docs/ubiquitous-language.md`](../../.harness/docs/ubiquitous-language.md) |

## 背景

- 作業フォルダーの秘密鍵のファイル（例：`*.pem`、`id_rsa`）は、Read、Edit、シェルで読め、読んだ中身はエージェントの文脈と、許した通信先へ出せる。
- 秘密鍵の中身のパターンは、commitとpushではgitのフックが止めるが、ファイルの読み取りは止めない。
- キーリングの無い環境（例：WSL2）では、`glab`がトークンを設定のファイルに平文で置く。

## 判断

勧める設定のReadとEditのdenyに、秘密鍵だけを入れるファイルの12の名前（例：`**/*.pem`、`**/id_ed25519`、`**/*.ppk`、`**/*.jks`）を足す。`glab`の設定の3つの場所（Linux、macOS、リポジトリの`.git/glab-cli/`）のReadも止める。

## 案

| 案 | 結果 | 理由 |
|---|---|---|
| 12の名前のReadとEditを止める | 採った | Readのdenyはサンドボックスの読み取りの禁止にも合わさり、シェルからも読めなくなる。よく使う6つに足した6つ（FIDO、PuTTY、Apple、Javaの鍵）は、秘密鍵だけを入れる名前で、ほかのファイルを読めなくすることがほぼ無い。 |
| よく使う6つの名前（`*.pem`、`*.key`、`id_rsa`、`id_dsa`、`id_ecdsa`、`id_ed25519`）だけを止める | 採らなかった | FIDOの鍵、PuTTYの鍵、Appleの鍵、Javaのキーストアを読める。Javaのキーストアは中身が文字でなく、中身のパターンでも探せない。 |
| 中身のパターンで、commitとpushだけを止める | 採らなかった | ファイルの読み取りは止まらない。 |

## 結果と失うもの

公開の証明書の`.pem`とKeynoteの`.key`も読めなくなるが、denyに除く形を書けないので受け入れる。人が名前を変えた鍵（例：`id_rsa_work`）は名前に当たらず、中身のパターンがcommitとpushで止めるだけになる。`GLAB_CONFIG_DIR`か`XDG_CONFIG_HOME`で場所を変えたPCでは、`glab`の設定のdenyが当たらない。

## 見直す条件

denyのルールに除く形を書けるようになったときと、名前を変えた鍵が読まれたとわかったときに見直す。

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の節「Permission rules」：「Paths and domains from both sandbox settings and permission rules are merged into the final sandbox configuration.」（確かめた日：2026-11-23）
- [Authenticate with GitLab](https://docs.gitlab.com/cli/authentication/)の節「Credential storage」：「If no keyring is available, if you pass `--insecure-storage`, or if you use `glab` in CI/CD environments where `GITLAB_CI` or `CI` is set to `true`, `glab` stores credentials as plaintext in the configuration file and prints a warning.」（確かめた日：2026-11-24）
