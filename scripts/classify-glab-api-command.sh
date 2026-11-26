#!/bin/bash
# glab apiのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。決まったエンドポイントの読み取りとGraphQLの決まった問い合わせだけを通し、秘密の値を返す形、URLの全体、ファイルから読む値、クイックアクションの行を止めるためである。
# 終了コードは、いつも0である。
# scripts/classify-glab-command.shが、glab apiのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# GraphQLの変数の$fullPathは、展開せずに、送る文字と一字一句比べる。
# shellcheck disable=SC2016
readonly FIXED_QUERY='query=query($fullPath: ID!) { project(fullPath: $fullPath) { visibility ciConfigPathOrDefault } }'
readonly FULL_PATH_PATTERN='^fullPath=[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)*$'

main() {
  local word endpoint='' count=0 asked='' skip='' query reason kind sent_count
  local fields=()
  for word in "$@"; do
    if [ -n "${skip}" ]; then
      if [ "${skip}" = 'field' ]; then fields+=("${word}"); fi
      skip='' && continue
    fi
    case "${word}" in
      -X | --method | -H | --header | --hostname | -R | --repo) asked="${word}" && skip='value' ;;
      --method=* | --header=* | --hostname=* | --repo=*) asked="${word%%=*}" ;;
      -f | -F | --field | --raw-field) skip='field' ;;
      --field=* | --raw-field=*) fields+=("${word#*=}") ;;
      --paginate | -i | --include | --silent | --output=*) ;;
      --output) skip='value' ;;
      -*)
        printf 'deny\nglab apiで、許すオプションに無いもの（%s）があります。決まったオプション（例：--paginate、-f）だけで書いてください。\n' "${word}"
        exit 0
        ;;
      *) endpoint="${word}" && count=$((count + 1)) ;;
    esac
  done
  if [ "${count}" -ne 1 ]; then
    printf 'deny\n%s\n' 'glab apiのエンドポイントが無いか、2つ以上あります。1つだけ書いてください。'
    exit 0
  fi
  kind="$("${BASH}" "${SCRIPT_DIRECTORY}/print-glab-api-endpoint-kind.sh" "${endpoint}")"
  case "${endpoint}:${kind}" in
    *://*:*)
      printf 'deny\nglab apiのエンドポイントがURLの全体（%s）です。glabは今のホストのトークンをそのURLへ送るので止めます。projects/<グループ>%%2F<プロジェクト>/…の形で書いてください。\n' "${endpoint}"
      exit 0
      ;;
    *:deny)
      printf 'deny\nglab apiのエンドポイント（%s）は、トークンか秘密の値（例：CI/CDの変数、runners_token）を返すことがあるので止めます。\n' "${endpoint}"
      exit 0
      ;;
    *:unclear)
      printf 'deny\nglab apiのエンドポイント（%s）は、%%2Fのほかの%%か、空の区切りか、先頭か最後の/があり、秘密の値を返す形と比べられないので止めます。%%2Fのほかは字のまま書き、区切りの/を1つずつにしてください（例：projects/<グループ>%%2F<プロジェクト>/merge_requests/1）。\n' "${endpoint}"
      exit 0
      ;;
  esac
  sent_count="${#fields[@]}"
  # 問い合わせの引数は、%XXを戻してから確かめる。\は先に%5Cにし、printfの%bにエスケープとして読ませない。
  case "${endpoint}" in
    *'?'*) query="${endpoint#*\?}" && query="${query//\\/%5C}" && fields+=("query=$(printf '%b' "${query//%/\\x}")") ;;
  esac
  if [ "${#fields[@]}" -gt 0 ] && reason="$("${BASH}" "${SCRIPT_DIRECTORY}/find-glab-api-unsafe-value.sh" "${fields[@]}")"; then
    printf 'deny\n%s\n' "${reason}"
    exit 0
  fi
  if [ -n "${asked}" ]; then
    printf 'ask\nglab apiで、メソッド、ヘッダー、ホストかリポジトリ（%s）を指定しています。リモートへの書き込みかほかのホストのことがあるので、確認を求めます。\n' "${asked}"
  elif [ "${endpoint}" = 'graphql' ]; then
    if [ "${#fields[@]}" -eq 2 ] && [ "${fields[0]}" = "${FIXED_QUERY}" ] && [[ "${fields[1]}" =~ ${FULL_PATH_PATTERN} ]]; then
      printf 'allow\n\n'
    else
      printf 'deny\n%s\n' 'glab apiのGraphQLは、決まった問い合わせ（visibilityとciConfigPathOrDefaultを読むもの）だけを通し、ほかを止めます。CI/CDの変数を読めるためです。'
    fi
  elif [ "${sent_count}" -gt 0 ]; then
    printf 'ask\n%s\n' 'glab apiで、値を送っています（POSTになります）。リモートへの書き込みなので、確認を求めます。'
  elif [ "${kind}" = 'allow' ]; then
    printf 'allow\n\n'
  else
    printf 'ask\nglab apiのエンドポイント（%s）は、確認なしで読む一覧に無いので、確認を求めます。\n' "${endpoint}"
  fi
  exit 0
}

main "$@"
