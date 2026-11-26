#!/bin/bash
# gh apiのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。値を送らない読み取りと、問い合わせだけのGraphQLを確認なしで通し、書き込みとほかのホストへの通信で確認を求めるためである。
# 終了コードは、いつも0である。
# scripts/classify-gh-command.shが、本文をファイルから読む形（scripts/find-gh-unreadable-form.sh）が無いgh apiを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

# 引数に、GitHubのほかのホスト（--hostnameかURL）を指すものがあるかを返す。ghはサンドボックスの外で動き、通信先の制限を受けないためである。
# 引数：gh apiのあとの引数
# 出力：なし
# 戻り値：あれば0、無ければ1
has_other_host() {
  local word
  for word in "$@"; do
    case "${word}" in
      *://* | --hostname | --hostname=*) return 0 ;;
    esac
  done
  return 1
}

main() {
  local word endpoint='' has_field=0 skip_value=0 values=''
  for word in "$@"; do
    if [ "${skip_value}" -eq 1 ]; then
      skip_value=0 && values="${values} ${word}"
      continue
    fi
    case "${word}" in
      -X* | --method | --method=*)
        printf 'ask\n%s\n' 'gh apiで、メソッドを指定しています。リモートへの書き込みなので、確認を求めます。'
        exit 0
        ;;
      -f | -F | --field | --raw-field) has_field=1 && skip_value=1 ;;
      -f?* | -F?* | --field=* | --raw-field=*) has_field=1 && values="${values} ${word}" ;;
      --jq | -q | --template | -t | -H | --header | --hostname | --cache | -p | --preview) skip_value=1 ;;
      --paginate | --slurp | -i | --include | --silent | --verbose | --jq=* | --template=* | --header=* | --hostname=* | --cache=*) ;;
      -*)
        printf 'deny\n知らないオプション「%s」を含みます。決まったオプション（例：--jq、--paginate）だけで書いてください。\n' "${word}"
        exit 0
        ;;
      *) if [ -z "${endpoint}" ]; then endpoint="${word}"; fi ;;
    esac
  done
  if has_other_host "$@"; then
    printf 'ask\n%s\n' 'gh apiで、GitHubのほかのホスト（--hostnameかURL）を指しています。ghはサンドボックスの外で動くので、確認を求めます。'
  elif [ "${has_field}" -eq 0 ]; then
    printf 'allow\n%s\n' ''
  elif [ "${endpoint}" != 'graphql' ]; then
    printf 'ask\n%s\n' 'gh apiで、値を送っています（POSTになります）。リモートへの書き込みなので、確認を求めます。'
  else
    case "${values}" in
      *mutation*) printf 'ask\n%s\n' 'GraphQLのmutationを含みます。リモートへの書き込みなので、確認を求めます。' ;;
      *) printf 'allow\n%s\n' '' ;;
    esac
  fi
  exit 0
}

main "$@"
