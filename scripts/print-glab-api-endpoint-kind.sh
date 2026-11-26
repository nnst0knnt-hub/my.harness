#!/bin/bash
# glab apiのエンドポイントを1つ受け取り、data/glab-api-endpoint-list.tsvと比べて、allow（確認なしで読む形）、deny（秘密の値を返すことがある形）、unclear（%2Fのほかの%か、空の区切りか、先頭か最後の/があって比べられない形）、none（どれでもない）のどれかを出す。?より前を/の区切りごとに形と比べ、?の後ろを&で分けて許す引数と比べる。シェルのパターンの*は/と?にも当たり、ほかのエンドポイントの後ろに許す形をつなげて通せるためである。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-glab-api-command.shが、glab apiのエンドポイントを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly ENDPOINT_LIST="${SCRIPT_DIRECTORY}/../data/glab-api-endpoint-list.tsv"

# 一覧の形を、区切りを越えない正規表現にする。
# 引数：一覧の形（例：projects/<P>/merge_requests/<N>）
# 出力：先頭と最後を固定した正規表現
# 戻り値：0
print_pattern_regex() {
  local regex="$1" project='[A-Za-z0-9_.-]+(%2F[A-Za-z0-9_.-]+)+' number='[0-9]+' discussion='[0-9a-f]{40}' segment='[^/]+'
  regex="${regex//<P>/${project}}"
  regex="${regex//<N>/${number}}"
  regex="${regex//<D>/${discussion}}"
  regex="${regex//<G>/${segment}}"
  printf '^%s$' "${regex}"
}

# 問い合わせの引数が、すべて許す引数に合うかを返す。
# 引数：問い合わせの引数（?の後ろ）、許す引数（空白で区切った「名前=値のERE」、「-」は無い）
# 出力：なし
# 戻り値：すべて合えば0、合わないものがあれば1
has_allowed_query() {
  local part parameter regex matched
  local parts=() parameters=()
  [ -n "$1" ] || return 0
  [ "$2" != '-' ] || return 1
  IFS='&' read -r -a parts <<< "$1"
  IFS=' ' read -r -a parameters <<< "$2"
  for part in "${parts[@]}"; do
    matched=1
    for parameter in "${parameters[@]}"; do
      regex="^${parameter%%=*}=(${parameter#*=})\$"
      if [[ "${part}" =~ ${regex} ]]; then matched=0; fi
    done
    [ "${matched}" -eq 0 ] || return 1
  done
  return 0
}

main() {
  local path query='' kind pattern parameters regex
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-glab-api-endpoint-kind.sh: エンドポイントを1つだけ渡してください。' >&2
    exit 2
  fi
  path="${1%%\?*}"
  case "$1" in
    *'?'*) query="${1#*\?}" ;;
  esac
  # %2Fのほかの%、空の区切り、先頭か最後の/は、GitLabがどう読むかに依らず、止める形と比べずにunclearを返す。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
  case "${path}" in
    /* | */ | *//*) printf '%s\n' 'unclear' && exit 0 ;;
  esac
  case "${path//%2F/}" in
    *%*) printf '%s\n' 'unclear' && exit 0 ;;
  esac
  # 止める形を、許す形より先に見る。
  while IFS=$'\t' read -r kind pattern parameters; do
    regex="$(print_pattern_regex "${pattern}")"
    case "${kind}" in
      deny-segment) case "/${path}/" in *"/${pattern}/"*) printf '%s\n' 'deny' && exit 0 ;; esac ;;
      deny) if [[ "${path}" =~ ${regex} ]]; then printf '%s\n' 'deny' && exit 0; fi ;;
    esac
  done < <(grep '^deny' "${ENDPOINT_LIST}")
  # .と..の区切りは、GitLabがほかのエンドポイントとして読むことがあるので、許す形に当てない。
  case "/${path//%2F//}/" in
    */./* | */../*) printf '%s\n' 'none' && exit 0 ;;
  esac
  while IFS=$'\t' read -r kind pattern parameters; do
    regex="$(print_pattern_regex "${pattern}")"
    if [[ "${path}" =~ ${regex} ]] && has_allowed_query "${query}" "${parameters}"; then
      printf '%s\n' 'allow'
      exit 0
    fi
  done < <(grep '^allow' "${ENDPOINT_LIST}")
  printf '%s\n' 'none'
  exit 0
}

main "$@"
