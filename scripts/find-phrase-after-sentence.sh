#!/bin/bash
# 渡したMarkdownのファイルの表のセルと箇条書きの項目から、文のあとに語句が続くもの（中に「。」があり、最後が「。」か「？」でないもの）を探し、場所を標準エラーに出す。1つのセルか項目の中で文のあとに語句を続けない規則を、書いたあとに毎回同じ基準で見つけるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# エージェントと人がMarkdownの文書を書いたあとに呼び、tests/run-test-suite.shがMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 1つのファイルの、文のあとに語句が続くセルと項目の場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ0以外
print_phrase_after_sentence() {
  "${BASH}" "${SCRIPT_DIRECTORY}/print-markdown-body.sh" "$1" | LC_ALL=C awk -F '\t' -v file="$1" '
    # かぎ括弧で囲んだ所を、内側の組から、文書に現れない1文字に置き換える。中の「。」を数えず、文のあとに続く語句（例：「説明です。「語句」」）としては残すためである。
    # 最初の閉じ括弧と、その前の最後の開き括弧を組にするので、入れ子（例：「「文。語句」の確認」）の中も残らない。
    # バイトで読むので、「[^」]」の形では括弧を探せず、indexで探す。どちらの括弧も3バイトである。
    function replace_quote(text, finish, start, offset, position) {
      while ((finish = index(text, "」")) > 0) {
        start = offset = 0
        while ((position = index(substr(text, offset + 1, finish - offset - 1), "「")) > 0) {
          start = offset + position
          offset = start + 2
        }
        # 組になる開き括弧の無い閉じ括弧は、それだけを消す。
        if (start == 0) { text = substr(text, 1, finish - 1) substr(text, finish + 3); continue }
        text = substr(text, 1, start - 1) "\002" substr(text, finish + 3)
      }
      return text
    }
    # 中に「。」があり、空白を除いた最後が「。」か「？」でないかを返す。どちらも3バイトなので、最後の3バイトで比べる。
    function is_phrase_after_sentence(text, tail) {
      gsub(/^[ \t]+|[ \t]+$/, "", text)
      if (index(text, "。") == 0) return 0
      tail = substr(text, length(text) - 2)
      return tail != "。" && tail != "？"
    }
    {
      number = $1
      text = substr($0, length(number) + 2)
      # インラインのコードの中は消し、かぎ括弧は1文字に置き換える。中の「|」と「。」を、セルの区切りと文の終わりに読まないためである（例：「。」を付けない）。
      gsub(/`[^`]*`/, "``", text)
      # 表の見出しは、置き換える前の行から取り、報告にかぎ括弧の中を残す。
      original = text
      text = replace_quote(text)
      if (text !~ /^\|/) {
        # 表の外の行が来たら、次の表の1行目を見出しとして読み直す。
        in_table = 0
        if (text ~ /^ *([-*+]|[0-9]+[.)]) /) {
          sub(/^ *([-*+]|[0-9]+[.)]) +/, "", text)
          if (is_phrase_after_sentence(text))
            print file ":" number ": 箇条書きの項目で、文のあとに語句が続いています。最後に「。」か「？」を付けた文にするか、「。」の無い1つの語句にしてください。"
        }
        next
      }
      # 区切りとして読まない「\|」を、文書に現れない制御文字に置き換える。
      gsub(/\\\|/, "\001", text)
      if (text ~ /^[|: -]+$/) next
      count = split(text, cells, "|")
      if (!in_table) { gsub(/\\\|/, "\001", original); split(original, heads, "|") }
      for (column = 2; column <= count; column++) {
        if (!in_table) { header[column] = heads[column]; gsub(/^ +| +$/, "", header[column]) }
        if (is_phrase_after_sentence(cells[column]))
          print file ":" number ": 表の「" header[column] "」の列のセルで、文のあとに語句が続いています。最後に「。」か「？」を付けた文にするか、「。」の無い1つの語句にしてください。"
      }
      in_table = 1
    }'
}

main() {
  local file output status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-phrase-after-sentence.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-phrase-after-sentence.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_phrase_after_sentence "${file}")"; then
      printf 'find-phrase-after-sentence.sh: ファイル「%s」を、awkで読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
