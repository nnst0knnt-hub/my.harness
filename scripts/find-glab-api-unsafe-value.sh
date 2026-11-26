#!/bin/bash
# glab apiの-fか-Fの値（名前=値）を1つ以上受け取り、止める値があれば、止める理由の文を標準出力に出す。止める値は、ファイルから読む値（@）、行の頭が/の行を含む値、行の頭の/を隠せるJSONの値である。判定のあとにファイルを書き換えられ、GitLabが本文の行の頭の/をクイックアクションとして動かすためである。
# 終了コードは、0が止める値があった、1が無かった、である。
# scripts/classify-glab-api-command.shが、送る値と問い合わせの引数を確かめるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# JSONは、エスケープの書き方（例：\nのあとの/、\u002f）か、文字列の頭の/で、行の頭の/を隠せる。
readonly JSON_HIDDEN_LINE_PATTERN='\\|"[[:space:]]*/'

main() {
  local field value
  for field in "$@"; do
    value="${field#*=}"
    case "${value}" in
      @*)
        printf 'glab apiの値（%s）を、ファイルから読んでいます（@）。判定のあとに書き換えられるので止めます。値は-fか-Fに書いてください。' "${field}"
        exit 0
        ;;
    esac
    if "${BASH}" "${SCRIPT_DIRECTORY}/find-quick-action-line.sh" "${value}"; then
      printf '%s' 'GitLabに送る本文に、行の頭が/の行（例：/merge）があります。GitLabがクイックアクションとして動かすので止めます。その行をバッククォートで囲むか、行の頭を変えてください。'
      exit 0
    fi
    case "${value}" in
      '['* | '{'*)
        if [[ "${value}" =~ ${JSON_HIDDEN_LINE_PATTERN} ]]; then
          printf '%s' 'glab apiのJSONの値に、\か、"のあとの/があります。エスケープか文字列の頭で行の頭の/を隠せるので止めます。JSONを使わない形で書いてください。'
          exit 0
        fi
        ;;
    esac
  done
  exit 1
}

main "$@"
