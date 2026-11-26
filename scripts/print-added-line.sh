#!/bin/bash
# git diffかgit log -p --ccの差分を標準入力で受け取り、足した行を「場所<TAB>中身」の形で1行に1つ出す。場所は「ファイル:行」で、git log --format=%hの差分では、場所の前に、短いcommitの名前と「の」を付ける。秘密情報を、足した行だけから探すためである。
# 終了コードは、0が出し終えた、である。差分の形でない行は、出さずに飛ばす。
# scripts/find-secret-in-commit.shが、gitのpre-commitとpre-pushのたびに呼ぶ。
set -u -o pipefail

main() {
  # マージのcommitの差分（--cc）は、行の先頭に親の数だけ記号が付く。どの親にも無い行（記号がすべて+）だけを、足した行とみなす。
  # 行の番号は、hunkの見出しの「+」の数から、消した行（記号に-がある）のほかを数えて求める。
  LC_ALL=C awk '
    in_hunk && /^[-+ ]/ {
      prefix = substr($0, 1, width)
      if (index(prefix, "-") > 0) next
      if (prefix ~ /^\++$/) print commit file ":" line "\t" substr($0, width + 1)
      line++
      next
    }
    in_hunk && /^\\/ { next }
    { in_hunk = 0 }
    /^[0-9a-f]+$/ { commit = $0 "の"; next }
    /^\+\+\+ / { file = substr($0, 5); sub(/^b\//, "", file); next }
    /^@@/ {
      match($0, /^@+/)
      width = RLENGTH - 1
      for (i = 2; i <= NF; i++) if ($i ~ /^\+[0-9]/) { line = substr($i, 2) + 0; break }
      in_hunk = 1
    }'
}

main "$@"
