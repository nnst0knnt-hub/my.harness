#!/bin/bash
# 渡したMarkdownのファイルを、文の中の表記の3つの規則（全角と半角の間の空白、リンクになっていないURL、絵文字）で確かめ、外れた場所を標準エラーに出す。書いたあとに、表記を毎回同じ基準で見つけるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# エージェントと人がMarkdownの文書を書いたあとに呼び、tests/run-test-suite.shがMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 全角は、U+3000以上の文字にする。「→」のような記号を、全角に入れないためである。
# 空白の前の全角は、最後のバイトでは範囲がわからないので文字の全体で当て、空白の後ろは先頭のバイトで当てる。
readonly FULL_WIDTH_HEAD=$'[\xe3-\xf4]'
readonly FULL_WIDTH_CHAR=$'([\xe3-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})'
# 半角は、英字、数字、括弧、バッククォートにする。表、引用、見出しの記号のあとの空白を、違反にしないためである。
readonly HALF_WIDTH_CHAR='[]A-Za-z0-9`()[]'
# 絵文字は、主な範囲（U+1F000～U+1FAFF、U+2600～U+27BF）と、絵文字として表示する異体字セレクタ（U+FE0F）にする。
readonly EMOJI_CHAR=$'(\xf0\x9f[\x80-\xab]|\xe2[\x98-\x9e]|\xef\xb8\x8f)'

# 3つの規則を当てるために、本文の行からコード、リンク先、箇条書きの記号を消した行を出す。
# 引数：ファイルのパス
# 出力：「行<TAB>消した行」の行
# 戻り値：0、読めなければ0以外
print_prose_line() {
  "${BASH}" "${SCRIPT_DIRECTORY}/print-markdown-body.sh" "$1" | LC_ALL=C awk '{
    number = $0
    sub(/\t.*/, "", number)
    text = substr($0, length(number) + 2)
    # インラインのコードは中身だけを消し、前後の空白を確かめられるようにする。
    gsub(/`[^`]*`/, "``", text)
    gsub(/\]\([^)]*\)/, "]()", text)
    sub(/^ *([-*+]|[0-9]+[.)]) (\[[ xX]\] )?/, "", text)
    print number "\t" text
  }'
}

# 消した行のうち、EREに合う行を、場所と説明の形で出す。
# 引数：ファイルのパス、print_prose_lineの出力、ERE、説明
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、grepかawkが失敗すれば0以外
print_matching_prose_line() {
  # grepの1は合う行が無いことなので、成功として扱う。
  printf '%s\n' "$2" | { LC_ALL=C grep -aE -e $'^[0-9]+\t.*('"$3"')' || [ "$?" -eq 1 ]; } |
    LC_ALL=C awk -F '\t' -v prefix="$1" -v message="$4" '{ print prefix ":" $1 ": " message }'
}

# 1つのファイルを3つの規則で確かめ、外れた場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、awkかgrepが失敗すれば1
print_notation_error() {
  local prose_line
  if ! prose_line="$(print_prose_line "$1")"; then
    return 1
  fi
  print_matching_prose_line "$1" "${prose_line}" "${HALF_WIDTH_CHAR} +${FULL_WIDTH_HEAD}|${FULL_WIDTH_CHAR} +${HALF_WIDTH_CHAR}" \
    '全角と半角の間に空白があります。空白を消してください。' || return 1
  print_matching_prose_line "$1" "${prose_line}" 'https?://' \
    'リンクになっていないURLがあります。[ページの名前](URL)の形にしてください。' || return 1
  print_matching_prose_line "$1" "${prose_line}" "${EMOJI_CHAR}" '絵文字があります。絵文字を消してください。' \
    || return 1
  return 0
}

main() {
  local file output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-notation-error.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-notation-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_notation_error "${file}")"; then
      printf 'find-notation-error.sh: ファイル「%s」を、awkかgrepで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
