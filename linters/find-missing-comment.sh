#!/bin/bash
# 渡したスクリプトに、先頭の3行のコメントと関数の上のコメントがあるかを確かめ、無い場所を標準エラーに出す。ファイルごとの説明の文書を置かない分を、コメントで説明するためである。
# 終了コードは、0が無い所なし、1が無い所あり、2が使い方の誤りである。
# tests/run-test-suite.shが、.shのファイルを、まだ追加していないものも含めて渡して呼ぶ。
set -u -o pipefail

# 1つのスクリプトの、コメントの無い場所を出す。
# 引数：スクリプトのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：無い所があれば0、無ければ1
print_missing_comment() {
  LC_ALL=C awk -v file="$1" '
    BEGIN {
      head_message = "先頭の3行のコメントがありません。2～4行目に、受け取るものと出すもの、終了コード、誰がいつ呼ぶかを書いてください。"
    }
    # 先頭の3行は、1行目のシェバンの次の2～4行目である（CONTRIBUTING.mdの節「コメント」）。
    FNR >= 2 && FNR <= 4 && !/^#/ {
      print file ":" FNR ": " head_message
      found = 1
    }
    # 関数は、行頭の「名前()」を定義として読む。関数をファイルの上にまとめるためである（CONTRIBUTING.mdの節「コードの作り」）。
    /^[A-Za-z_][A-Za-z0-9_]*[(][)]/ && previous !~ /^#/ {
      name = $0
      sub(/[(].*/, "", name)
      # mainは除く。先頭の3行のコメントが、mainの説明を兼ねるためである。
      if (name != "main") {
        print file ":" FNR ": 関数「" name "」の上にコメントがありません。関数のすぐ上の行に、説明のコメントを書いてください。"
        found = 1
      }
    }
    { previous = $0 }
    END {
      if (NR < 4) {
        print file ":" NR + 1 ": " head_message
        found = 1
      }
      exit !found
    }' "$1"
}

main() {
  local file
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-missing-comment.sh: ファイルが渡されていません。確かめるスクリプトを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-missing-comment.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if print_missing_comment "${file}" >&2; then
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
