#!/bin/bash
# 渡したファイルを整形の5つの規則（UTF-8、LFの改行、最後の改行1つ、行末の空白なし、インデントのタブなし）で確かめ、外れた場所を標準エラーに出す。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、追跡しているファイルと、まだ追加していないファイルを渡して呼ぶ。
set -u -o pipefail

# UTF-8として正しい並びだけからなる行に当たるEREを作る。NULと改行は行に入らないので、1バイトの文字から除く。
# 引数：なし
# 出力：ERE
# 戻り値：0
print_utf8_line_pattern() {
  local tail_byte=$'[\x80-\xbf]'
  local pattern=$'[\x01-\x7f]'
  pattern+=$'|[\xc2-\xdf]'"${tail_byte}"
  pattern+=$'|\xe0[\xa0-\xbf]'"${tail_byte}"
  pattern+=$'|[\xe1-\xec\xee\xef]'"${tail_byte}${tail_byte}"
  pattern+=$'|\xed[\x80-\x9f]'"${tail_byte}"
  pattern+=$'|\xf0[\x90-\xbf]'"${tail_byte}${tail_byte}"
  pattern+=$'|[\xf1-\xf3]'"${tail_byte}${tail_byte}${tail_byte}"
  pattern+=$'|\xf4[\x80-\x8f]'"${tail_byte}${tail_byte}"
  printf '^(%s)*$\n' "${pattern}"
}

# grepで選んだ行を、場所と説明の形で出す。
# 引数：ファイルのパス、grepのオプション、ERE、説明
# 出力：「ファイル:行: 説明」の行
# 戻り値：1行以上出せば0、無ければ1
print_matching_line() {
  LC_ALL=C grep -a "$2" -e "$3" "$1" |
    LC_ALL=C awk -F: -v prefix="$1" -v message="$4" '{ print prefix ":" $1 ": " message }'
}

# ファイルの最後の改行が1つでなければ、場所と説明を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の1行
# 戻り値：最後の改行が1つでなければ0、1つなら1
print_final_newline_error() {
  local line_count
  # macOSのwcは数の前に空白を付けるので、算術式で数に直す。
  line_count="$(($(wc -l < "$1")))"
  if [ -n "$(tail -c 1 "$1")" ]; then
    printf '%s:%s: ファイルの最後に改行がありません。最後に改行を1つ足してください。\n' \
      "$1" "$((line_count + 1))"
    return 0
  fi
  # macOSのtrは、UTF-8のロケールでは文字の途中のバイトで失敗するので、LC_ALL=Cで動かす。
  if [ "${line_count}" -ge 2 ] && [ -z "$(tail -c 2 "$1" | LC_ALL=C tr -d '\n')" ]; then
    printf '%s:%s: ファイルの最後に、改行が2つ以上あります。最後の空の行を消してください。\n' \
      "$1" "${line_count}"
    return 0
  fi
  return 1
}

# 1つのファイルを5つの規則で確かめ、外れた場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：外れた所があれば0、無ければ1
print_format_error() {
  local found=1
  if print_matching_line "$1" -nvE "$(print_utf8_line_pattern)" 'UTF-8でないバイトがあります。UTF-8で保存し直してください。'; then
    found=0
  fi
  if print_matching_line "$1" -nE $'\r' '改行にCRがあります。改行をLFだけにしてください。'; then
    found=0
  fi
  if print_matching_line "$1" -nE '[[:blank:]]$' '行末に空白があります。行末の空白を消してください。'; then
    found=0
  fi
  if print_matching_line "$1" -nE $'^ *\t' 'インデントにタブがあります。インデントを空白2つにしてください。'; then
    found=0
  fi
  if print_final_newline_error "$1"; then
    found=0
  fi
  return "${found}"
}

main() {
  local file
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-format-error.sh: ファイルが渡されていません。確かめるファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-format-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    # 空のファイルには行が無く、5つの規則のどれにも当たらない。
    if [ -s "${file}" ] && print_format_error "${file}" >&2; then
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
