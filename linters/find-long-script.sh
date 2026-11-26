#!/bin/bash
# 渡したスクリプトの行数を数え、100行を超えたファイルを標準エラーに出す。スクリプトを1つの仕事の大きさに保つためである。
# 終了コードは、0が超えたファイルなし、1が超えたファイルあり、2が使い方の誤りである。
# tests/run-test-suite.shが、.shのファイルを、まだ追加していないものも含めて渡して呼ぶ。
set -u -o pipefail

# 上限は、CONTRIBUTING.mdの節「スクリプトの長さ」の値である。
readonly LINE_LIMIT=100

main() {
  local file
  local count
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-long-script.sh: ファイルが渡されていません。行数を数えるスクリプトを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-long-script.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    # macOSのwcは数の前に空白を付けるので、算術式で数に直す。
    count="$(($(wc -l < "${file}")))"
    if [ "${count}" -gt "${LINE_LIMIT}" ]; then
      printf '%s: %s行で、上限の%s行を超えています。規則のまとまりごとに、ファイルを分けてください。\n' \
        "${file}" "${count}" "${LINE_LIMIT}" >&2
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
