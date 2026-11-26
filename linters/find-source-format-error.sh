#!/bin/bash
# 渡したMarkdownのファイルの節「出典」の箇条書きに「（確かめた日：YYYY-MM-DD）」があるかを確かめ、無い行を標準エラーに出す。確かめた日は、出典の古さを判断する材料であるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、Markdownのファイルを渡して呼ぶ。導入先の文書には当てない。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly BODY_READER="${SCRIPT_DIRECTORY}/../scripts/print-markdown-body.sh"
readonly CHECKED_DATE='（確かめた日：[0-9]{4}-[0-9]{2}-[0-9]{2}）'

# 節「出典」の箇条書きのうち、確かめた日の無い行を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_source_format_error() {
  "${BASH}" "${BODY_READER}" "$1" | LC_ALL=C awk -F '\t' '
    $2 ~ /^## / { in_source = ($2 ~ /^## 出典/) }
    in_source && $2 ~ /^ *[-*+] / { print }' |
    { LC_ALL=C grep -avE -e "${CHECKED_DATE}" || [ "$?" -eq 1 ]; } |
    LC_ALL=C awk -F '\t' -v file="$1" '{ print file ":" $1 ": 出典に「（確かめた日：YYYY-MM-DD）」がありません。原文を確かめた日を書いてください。" }'
}

main() {
  local file output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-source-format-error.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-source-format-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_source_format_error "${file}")"; then
      printf 'find-source-format-error.sh: ファイル「%s」を読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
      exit 2
    fi
    if [ -n "${output}" ]; then
      printf '%s\n' "${output}" >&2
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
