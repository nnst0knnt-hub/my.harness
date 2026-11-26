#!/bin/bash
# 渡したMarkdownのファイルの箇条書きと表を、語句と文の混在と、最上位の箇条書きの項目の数で確かめ、外れた場所を標準エラーに出す。レビューで繰り返し指摘された形を、書いたあとに毎回同じ基準で見つけるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# エージェントと人がMarkdownの文書を書いたあとに呼び、tests/run-test-suite.shがMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 1つのファイルの、箇条書きと表の規則から外れた場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_list_and_table_error() {
  "${BASH}" "${SCRIPT_DIRECTORY}/print-markdown-body.sh" "$1" | LC_ALL=C awk -F '\t' -v file="$1" '
    function report(line, message) { print file ":" line ": " message }
    # 文は、「。」か「？」で終わるものである。どちらも3バイトなので、最後の3バイトで比べる。
    function is_sentence(cell, tail) { tail = substr(cell, length(cell) - 2); return tail == "。" || tail == "？" }
    # 一覧は、最上位（level 0）と入れ子（level 1）に分けて数える。入れ子は2段までとする規則に合わせる。
    function close_list(level) {
      if (!list_count[level]) return
      if (list_sentence[level] && list_sentence[level] < list_count[level])
        report(list_line[level], "箇条書きに、語句と文が混ざっています。語句には「。」を付けず、文には付けて、どちらかにそろえてください。")
      # 出典の一覧だけは、1件や2件でも箇条書きにする。
      if (level == 0 && list_count[0] < 3 && !in_source)
        report(list_line[0], "箇条書きの項目が" list_count[0] "個です。3つ以上にするか、文で書いてください。")
      list_count[level] = list_sentence[level] = 0
    }
    function close_all_list() { close_list(1); close_list(0) }
    function close_table(column) {
      for (column = 2; column <= column_count; column++) {
        if (table_sentence[column] && table_sentence[column] < table_filled[column])
          report(table_line, "表の「" table_header[column] "」の列に、語句と文が混ざっています。語句には「。」を付けず、文には付けて、どちらかにそろえてください。")
        table_sentence[column] = table_filled[column] = 0
      }
      in_table = column_count = 0
    }
    function read_table_row(row, count, column) {
      # 区切りとして読まない「\|」を、文書に現れない制御文字に置き換える。
      gsub(/\\\|/, "\001", row)
      if (row ~ /^[|: -]+$/) return
      count = split(row, cells, "|")
      for (column = 2; column <= count; column++) {
        gsub(/^ +| +$/, "", cells[column])
        if (!in_table) table_header[column] = cells[column]
        else if (cells[column] != "") { table_filled[column]++; table_sentence[column] += is_sentence(cells[column]) }
      }
      if (!in_table) { in_table = 1; table_line = number; column_count = count }
    }
    {
      number = $1
      text = substr($0, length(number) + 2)
      # インラインのコードは中身を消す。中の「|」と「。」を、表の区切りと文の終わりに読まないためである。
      gsub(/`[^`]*`/, "``", text)
      sub(/[ \t]+$/, "", text)
      if (text == "") { if (in_table) close_table(); next }
      if (text ~ /^\|/) { close_all_list(); read_table_row(text); next }
      if (in_table) close_table()
      if (text ~ /^ *([-*+]|[0-9]+[.)]) /) {
        level = (text ~ /^ /) ? 1 : 0
        if (level == 0) close_list(1)
        if (!list_count[level]) list_line[level] = number
        list_count[level]++
        if (is_sentence(text)) list_sentence[level]++
        next
      }
      # 字下げした行は、項目の続きである。
      if (text ~ /^ /) next
      close_all_list()
      if (text ~ /^## /) in_source = (text ~ /^## 出典/)
    }
    END { close_all_list(); if (in_table) close_table() }'
}

main() {
  local file output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-list-and-table-error.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-list-and-table-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_list_and_table_error "${file}")"; then
      printf 'find-list-and-table-error.sh: ファイル「%s」を、awkで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
