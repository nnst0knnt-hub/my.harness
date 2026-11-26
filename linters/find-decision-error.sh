#!/bin/bash
# 渡した判断の記録のファイルについて、出典を除いた字数と、本文に書いたPRとIssueの番号と行番号を確かめ、外れた場所を標準エラーに出す。字数は目で数えられず、番号はあとで読む人が追えなくなるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、docs/decisions/のファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly BODY_READER="${SCRIPT_DIRECTORY}/../scripts/print-markdown-body.sh"
readonly CHARACTER_LIMIT=1500
# PRとIssueの番号（例：#12、PR 12）、「12行目」、ファイルと行（例：a.md:12）である。
readonly NUMBER_REFERENCE='#[0-9]+|PR ?#?[0-9]+|Issue ?#?[0-9]+|[0-9]+行目|\.[A-Za-z]+:[0-9]+'

# 出典の節より前の字数を数える。字数の数え方は、find-long-rule.shと同じにする。
# 引数：ファイルのパス
# 出力：字数
# 戻り値：0
count_character_before_source() {
  LC_ALL=C awk '/^## 出典/ { exit } { print }' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}

# 出典の節より前の本文から、リンク先を消して番号を探す。リンク先のアンカーの数字を、番号と読まないためである。
# 出典の節で読むのを止めず、最後まで読んで捨てる。先に止めると、本文を書く側がまだ書いている途中でSIGPIPEを受けて止まる。pipefailがそれを、読めなかったと扱うためである。まれにしか起きないので、テストが通っても、止める形に戻さない。
# 引数：ファイルのパス
# 出力：番号のある行の、行の番号
# 戻り値：0、読めなければ0以外
print_number_reference_line() {
  "${BASH}" "${BODY_READER}" "$1" | LC_ALL=C awk -F '\t' '
    /^[0-9]+\t## 出典/ { in_source = 1 }
    in_source { next }
    { line = $0; gsub(/\]\([^)]*\)/, "]()", line); print line }' |
    { LC_ALL=C grep -aE -e "${NUMBER_REFERENCE}" || [ "$?" -eq 1 ]; } | cut -f 1
}

# 1つのファイルの、外れた場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」か「ファイル: 説明」の行
# 戻り値：0、読めなければ1
print_decision_error() {
  local count reference_lines line
  count="$(count_character_before_source "$1")"
  if [ "${count}" -gt "${CHARACTER_LIMIT}" ]; then
    printf '%s: 出典を除いた字数が%s字で、上限の%s字を超えています。理由を絞るか、案と見直す条件ごと設計の文書へ移してください。\n' \
      "$1" "${count}" "${CHARACTER_LIMIT}"
  fi
  if ! reference_lines="$(print_number_reference_line "$1")"; then
    return 1
  fi
  for line in ${reference_lines}; do
    printf '%s:%s: PRかIssueの番号か、行番号があります。あとで読む人が追えるように、中身を文で書いてください。\n' "$1" "${line}"
  done
}

main() {
  local file output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-decision-error.sh: ファイルが渡されていません。確かめる判断の記録のファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-decision-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_decision_error "${file}")"; then
      printf 'find-decision-error.sh: ファイル「%s」を読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
