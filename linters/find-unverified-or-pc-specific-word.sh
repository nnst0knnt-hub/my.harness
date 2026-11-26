#!/bin/bash
# 渡したMarkdownのファイルの本文と前付けから、data/unverified-or-pc-specific-word-list.txtの語（1台のPCの具体を表す語と、推測と未確認の形）を探し、場所を標準エラーに出す。公開する文書に、1台のPCの具体と、確かめていないことを事実の形で書いた文が入らないようにするためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、変更の記録のほかのMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly WORD_LIST="${SCRIPT_DIRECTORY}/../data/unverified-or-pc-specific-word-list.txt"

# 1つのファイルのYAMLの前付けの行を、scripts/print-markdown-body.shと同じ「行<TAB>中身」の形で出す。前付けの値（例：スキルのdescription）は、エージェントがスキルを選ぶときに読む公開の文なので、本文と同じく確かめるためである。閉じていない前付けは、本文を取り出すスクリプトが何も出さないので、すべての行を出す。
# 引数：ファイルのパス
# 出力：「行<TAB>中身」の行
# 戻り値：0、読めなければ0以外
print_front_matter() {
  LC_ALL=C awk 'FNR == 1 { if ($0 != "---") exit; next } /^---$/ { exit } { print FNR "\t" $0 }' "$1"
}

# 1つのファイルの、一覧の語の場所を出す。コードブロックは、インラインのコードと同じくコマンドと出力の綴りなので見ない。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_unverified_or_pc_specific_word() {
  { print_front_matter "$1" && "${BASH}" "${SCRIPT_DIRECTORY}/../scripts/print-markdown-body.sh" "$1"; } | LC_ALL=C awk -F '\t' -v file="$1" '
    # 1つ目の入力は語の一覧である。
    FNR == NR {
      if ($0 ~ /^#/ || $1 == "") next
      patterns[++count] = $1
      replacements[count] = $2
      exclusions[count] = $3
      next
    }
    {
      number = $1
      text = substr($0, length(number) + 2)
      # 節「出典」は、原文のまま引くので確かめない。
      if (text ~ /^## /) in_source = (text ~ /^## 出典/)
      if (in_source) next
      # インラインのコードは、コマンドと値の綴りなので、語と読まない。
      gsub(/`[^`]*`/, "\001", text)
      for (i = 1; i <= count; i++) {
        line = text
        if (exclusions[i] != "") gsub(exclusions[i], "\001", line)
        if (match(line, patterns[i]))
          print file ":" number ": 1台のPCの具体か、推測と未確認の形「" substr(line, RSTART, RLENGTH) "」があります。" replacements[i] "で書いてください。"
      }
    }' "${WORD_LIST}" -
}

main() {
  local file output status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-unverified-or-pc-specific-word.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  # 一覧が空だと、awkが本文の1行目からを一覧として読むので、先に止める。
  if [ ! -s "${WORD_LIST}" ] || [ ! -r "${WORD_LIST}" ]; then
    printf 'find-unverified-or-pc-specific-word.sh: 語の一覧「%s」が無いか、空か、読めません。ハーネスのリポジトリの場所と権限を確かめてください。\n' "${WORD_LIST}" >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-unverified-or-pc-specific-word.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_unverified_or_pc_specific_word "${file}")"; then
      printf 'find-unverified-or-pc-specific-word.sh: ファイル「%s」を、awkで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
