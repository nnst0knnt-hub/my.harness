#!/bin/bash
# ghの読み取りのコマンドのあとの引数を受け取り、1行目に判定（allowかask）、2行目に理由の文を出す。ブラウザーを開く--webとその短い形の-w、GitHubのほかのホストを指す引数に確認を求め、ほかの読み取りを確認なしで通すためである。gh run listの-wは--workflowの短い形だが、コマンドごとに分けずに確認を求める。
# 終了コードは、いつも0である。
# scripts/classify-gh-command.shが、読み取りのコマンドに当たったときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

# 引数に、-wか--webがあるかを返す。ghは、短いオプションを1語に束ねた形（例：-cw）も読むので、-で始まりwを含む短い形の語をすべて当てる。
# 引数：ghの引数
# 出力：なし
# 戻り値：あれば0、無ければ1
has_web_option() {
  local word
  for word in "$@"; do
    case "${word}" in
      --web | --web=*) return 0 ;;
      --*) ;;
      -*w*) return 0 ;;
    esac
  done
  return 1
}

# 引数に、GitHubのほかのホストを指すものがあるかを返す。ghはサンドボックスの外で動き、通信先の制限を受けないためである。
# 引数：ghの引数
# 出力：なし
# 戻り値：あれば0、無ければ1
has_other_host() {
  local word
  for word in "$@"; do
    # ghは、URLと、-RのリポジトリのHOST/OWNER/REPOの形で、ほかのホストを指せる。
    case "${word}" in
      *://* | --hostname | --hostname=* | */*/*) return 0 ;;
    esac
  done
  return 1
}

main() {
  local reason=''
  # 両方あるときは、2つの理由をつなぐ。ほかのホストの形はファイルのパス（例：.github/workflows/ci.yml）にも当たるので、片方だけでは誤った理由だけになることがある。
  if has_other_host "$@"; then
    reason='GitHubのほかのホストを指す引数（例：URL、-R HOST/OWNER/REPO）があります。ghはサンドボックスの外で動くので、確認を求めます。'
  fi
  if has_web_option "$@"; then
    reason="${reason}gh ${1:-} ${2:-}の引数に、-w、--web、wを含む短い形の語（例：-cw）があるので、確認を求めます。-wを持つ読み取りのコマンドでは、-wはサンドボックスの外でブラウザーを開く--webの短い形で、gh run listだけは--workflowの短い形です。"
  fi
  if [ -n "${reason}" ]; then
    printf 'ask\n%s\n' "${reason}"
  else
    printf 'allow\n%s\n' ''
  fi
  exit 0
}

main "$@"
