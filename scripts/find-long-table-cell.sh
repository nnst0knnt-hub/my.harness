#!/bin/bash
# 渡したMarkdownのファイルの表から、文を3つ以上含むセルを探し、場所と列の名前を標準エラーに出す。表のセルを2文までにする規則を、書いたあとに毎回同じ基準で見つけるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# エージェントと人がMarkdownの文書を書いたあとに呼び、tests/run-test-suite.shがMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# 1つのセルに書いてよい文の数である（rules/writing.mdの節「機械で止める規則」）。
readonly SENTENCE_LIMIT=2

# 1つのファイルの、文の多すぎるセルの場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_long_table_cell() {
  "${BASH}" "${SCRIPT_DIRECTORY}/print-markdown-body.sh" "$1" | LC_ALL=C awk -F '\t' -v file="$1" -v limit="${SENTENCE_LIMIT}" '
    # かぎ括弧で囲んだ所を消す。バイトで読むので、「[^」]」の形では閉じ括弧を探せず、indexで探す。
    function remove_quote(text, start, rest, finish) {
      while ((start = index(text, "「")) > 0 && (finish = index(rest = substr(text, start + 3), "」")) > 0)
        text = substr(text, 1, start - 1) substr(rest, finish + 3)
      return text
    }
    {
      number = $1
      text = substr($0, length(number) + 2)
      # 表の外の行が来たら、次の表の1行目を見出しとして読み直す。
      if (text !~ /^\|/) { in_table = 0; next }
      # インラインのコードと、かぎ括弧の中は消す。中の「|」と「。」を、セルの区切りと文の終わりに読まないためである（例：「。」を付けない）。
      gsub(/`[^`]*`/, "``", text)
      text = remove_quote(text)
      # 区切りとして読まない「\|」を、文書に現れない制御文字に置き換える。
      gsub(/\\\|/, "\001", text)
      if (text ~ /^[|: -]+$/) next
      count = split(text, cells, "|")
      for (column = 2; column <= count; column++) {
        if (!in_table) { header[column] = cells[column]; gsub(/^ +| +$/, "", header[column]) }
        # 文は「。」か「？」で終わるので、その数を文の数とする。どちらも3バイトの並びで、ほかの文字の途中には現れない。
        sentence = gsub(/。|？/, "&", cells[column])
        if (sentence > limit)
          print file ":" number ": 表の「" header[column] "」の列のセルに、文が" sentence "つあります。" limit "文までにし、残りは表の下の段落か箇条書きに書いてください。"
      }
      in_table = 1
    }'
}

main() {
  local file output status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-long-table-cell.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-long-table-cell.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_long_table_cell "${file}")"; then
      printf 'find-long-table-cell.sh: ファイル「%s」を、awkで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
