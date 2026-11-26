#!/bin/bash
# 渡したMarkdownのファイルから、data/backquote-name-list.txtの名前をバッククォートで囲まずに書いた所を探し、場所を標準エラーに出す。同じ名前を囲む所と囲まない所が混ざると、読む人が別のものかと迷うためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、Markdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly NAME_LIST="${SCRIPT_DIRECTORY}/../data/backquote-name-list.txt"

# 1つのファイルの、囲まずに書いた名前の場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_missing_backquote() {
  "${BASH}" "${SCRIPT_DIRECTORY}/../scripts/print-markdown-body.sh" "$1" | LC_ALL=C awk -F '\t' -v file="$1" '
    # 1つ目の入力は名前の一覧である。名前の記号のうち、正規表現の記号は「.」だけなので、それだけを文字として読む形に変える。
    FNR == NR {
      if ($0 ~ /^#/ || $1 == "") next
      names[++count] = $1
      pattern = $1
      gsub(/\./, "[.]", pattern)
      # 前後が英数字か「_」「.」「/」「-」なら、長い名前かパスの一部なので数えない。
      patterns[count] = "(^|[^A-Za-z0-9_./-])" pattern "([^A-Za-z0-9_./-]|$)"
      exclusions[count] = $2
      next
    }
    {
      number = $1
      text = substr($0, length(number) + 2)
      # 節「出典」は、名前と同じ綴りの英語の語（例：main、reviewer）を、原文のまま引くので確かめない。
      if (text ~ /^## /) in_source = (text ~ /^## 出典/)
      if (in_source) next
      # インラインのコードは名前を囲んだ所で、リンク先はパスとURLなので、どちらも名前と読まない。
      gsub(/`[^`]*`/, "\001", text)
      gsub(/\]\([^)]*\)/, "]", text)
      for (i = 1; i <= count; i++) {
        line = text
        if (exclusions[i] != "") gsub(exclusions[i], "\001", line)
        if (match(line, patterns[i]))
          print file ":" number ": 名前「" names[i] "」を、バッククォートで囲まずに書いています。`" names[i] "`の形で書いてください。"
      }
    }' "${NAME_LIST}" -
}

main() {
  local file output status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-missing-backquote.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  # 一覧が空だと、awkが本文の1行目からを一覧として読むので、先に止める。
  if [ ! -s "${NAME_LIST}" ] || [ ! -r "${NAME_LIST}" ]; then
    printf 'find-missing-backquote.sh: 名前の一覧「%s」が無いか、空か、読めません。ハーネスのリポジトリの場所と権限を確かめてください。\n' "${NAME_LIST}" >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-missing-backquote.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_missing_backquote "${file}")"; then
      printf 'find-missing-backquote.sh: ファイル「%s」を、awkで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
