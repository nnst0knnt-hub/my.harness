#!/bin/bash
# 渡したMarkdownのファイルから、YAMLの前付けとコードブロックを除いた行を、「行<TAB>中身」の形で標準出力に出す。文章を確かめるスクリプトが、同じ読み方で本文を読むためである。
# 終了コードは、0が成功、2が使い方の誤りである。
# scripts/とlinters/の、Markdownの本文を確かめるスクリプトが呼ぶ。
set -u -o pipefail

main() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-markdown-body.sh: ファイルを1つだけ渡してください。読むMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    printf 'print-markdown-body.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "$1" >&2
    exit 2
  fi
  # 前付けとコードブロックは、find-markdown-block-error.shのprint_block_errorと同じ形で読む（理由はそちらのコメントに書く）。
  if ! LC_ALL=C awk '
    FNR == 1 && /^---$/ { front_matter = 1; next }
    front_matter { if (/^---$/) front_matter = 0; next }
    /^ *(```+[^`]*|~~~+.*)$/ {
      match($0, /```+|~~~+/)
      if (!in_code) { in_code = 1; fence_character = substr($0, RSTART, 1); fence_length = RLENGTH }
      else if (substr($0, RSTART, 1) == fence_character && RLENGTH >= fence_length && /^ *(```+|~~~+) *$/) in_code = 0
      next
    }
    in_code { next }
    { print FNR "\t" $0 }' "$1"; then
    printf 'print-markdown-body.sh: ファイル「%s」を、awkで読めませんでした。上のawkのエラーを見て、直してください。\n' "$1" >&2
    exit 2
  fi
}

main "$@"
