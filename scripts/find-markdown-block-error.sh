#!/bin/bash
# 渡したMarkdownのファイルの見出しとコードブロックを、表記の規則（見出しの番号、深さ、#の数、コードブロックの言語）で確かめ、外れた場所を標準エラーに出す。閉じていないコードブロックとYAMLの前付けと、前付けの値の引用符の無い「 #」も出す。書いたあとに、表記を毎回同じ基準で見つけるためである。
# 終了コードは、0が外れた所なし、1が外れた所あり、2が使い方の誤りである。
# エージェントと人がMarkdownの文書を書いたあとに呼び、tests/run-test-suite.shがMarkdownのファイルを渡して呼ぶ。
set -u -o pipefail

# 1つのファイルの、見出しとコードブロックの規則から外れた場所を出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、awkが失敗すれば0以外
print_block_error() {
  LC_ALL=C awk -v file="$1" '
    function report(line, message) { print file ":" line ": " message }
    # #の見出しの無いテンプレートを、##から始められるようにする。
    BEGIN { previous_level = 1 }
    # 前付けとコードブロックは、print-markdown-body.shと同じ形で読む。片方だけを変えると、閉じたかの読み方が食い違うためである。
    FNR == 1 && /^---$/ { front_matter = 1; next }
    # 前付けの値を引用符で囲まずに「 #」を書くと、YAMLは「 #」から後ろをコメントと読み、値が切れる（例：スキルのdescriptionが途中で切れる）。
    # 「#」で始まる値は確かめない。次の行から対応表かリストを書くキーのコメントと分けられず、止めると正しいYAMLを止めるためである。
    front_matter && /^[A-Za-z0-9_-]+: *[^"'\''|> #].* #/ { report(FNR, "YAMLの前付けの値に、引用符の無い「 #」があります。「 #」から後ろはコメントと読まれて値が切れるので、値を\"で囲んでください。") }
    front_matter { if (/^---$/) front_matter = 0; next }
    # 囲みの記号は、バッククォート3つ以上か、~3つ以上（バッククォートの代わりに使える、CommonMarkのコードブロックの囲み）である。
    # バッククォートの開く行と閉じる行は、記号のあとにバッククォートが無い行である。行頭のインラインのコードを、コードブロックと読まないためである。~の行は、CommonMarkのとおり、言語の所にバッククォートを書いてもよい。
    # 閉じる行は、開いた行と同じ記号を同じ数以上だけ並べた行である。中に、記号の違うコードブロックか、記号の短いコードブロックを書けるようにするためである。
    /^ *(```+[^`]*|~~~+.*)$/ {
      match($0, /```+|~~~+/)
      if (!in_code) {
        in_code = 1
        fence_character = substr($0, RSTART, 1)
        fence_length = RLENGTH
        fence = substr($0, RSTART, RLENGTH)
        code_line = FNR
        if (/^ *(```+|~~~+) *$/) report(FNR, "コードブロックに言語がありません。開く行に言語を書き、当てはまる言語が無ければtextにしてください。")
      } else if (substr($0, RSTART, 1) == fence_character && RLENGTH >= fence_length && /^ *(```+|~~~+) *$/) in_code = 0
      next
    }
    in_code { next }
    /^#+( |$)/ {
      level = match($0, /[^#]/) ? RSTART - 1 : length($0)
      if (level == 1 && ++title_count > 1) report(FNR, "#の見出しが2つ以上あります。#の見出しを1つにしてください。")
      if (level > 3) report(FNR, "見出しが###より深くなっています。###までにしてください。")
      if (level > previous_level + 1) report(FNR, "見出しの深さが飛んでいます。1段ずつ深くしてください。")
      # 番号は、数字と「.」の並びのあとに「.」か空白が来る形（例：「1.」「2.1 」「2.1.」）とする。空白の無い「2.54以降」は通す。空白が続く数（例：「1.5 GB」「404 Not Found」）は、番号と分けられないので止める。
      if (substr($0, level + 2) ~ /^[0-9]+([.][0-9]+)*([.]([^0-9]|$)| )/) report(FNR, "見出しに番号があります。番号を消し、名前で指してください。")
      previous_level = level
    }
    # 閉じていないと、そこから最後までの行を確かめずに通すので、報告する。
    END {
      if (front_matter) report(1, "YAMLの前付けが閉じていません。前付けの最後に---の行を足してください。")
      if (in_code) report(code_line, "コードブロックが閉じていません。閉じる" fence "の行を足してください。")
    }' "$1"
}

main() {
  local file
  local output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-markdown-block-error.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-markdown-block-error.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    # 外れた所があるかは、出力で決める。awkの誤りで返る終了コードは、awkの種類で違うためである。
    if ! output="$(print_block_error "${file}")"; then
      printf 'find-markdown-block-error.sh: ファイル「%s」を、awkで読めませんでした。上のawkのエラーを見て、直してください。\n' "${file}" >&2
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
