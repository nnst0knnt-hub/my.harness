#!/bin/bash
# 渡したMarkdownのファイルの相対リンクを読み、先のファイルと見出しが無いものを標準エラーに出す。文書を書き直して見出しやファイルが変わっても、古いリンクが残らないようにするためである。
# 終了コードは、0が切れたリンクなし、1が切れたリンクあり、2が使い方の誤りである。
# tests/run-test-suite.shが、Markdownのファイルを渡して呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly BODY_READER="${SCRIPT_DIRECTORY}/../scripts/print-markdown-body.sh"
# GitHubが見出しのアンカーから消す記号を、バイトで書ける形にする。範囲は、「-」と「_」を除くASCIIの記号、U+2000～U+2BFF、CJKの記号（「々」「〆」「〇」を除く）、「・」、全角の記号（「＿」を除く）である。
readonly PUNCTUATION=$'([]!"#$%&\'()*+,./:;<=>?@[\\^`{|}~]|\xe2[\x80-\xaf][\x80-\xbf]|\xe3\x80[\x80-\x84\x88-\xbf]|\xe3\x83\xbb|\xef\xbc[\x81-\x8f\x9a-\xa0\xbb-\xbe]|\xef\xbd[\x80\x9b-\xa5])'

# 本文から、リポジトリの中を指すリンク先を取り出す。
# 引数：ファイルのパス
# 出力：「行<TAB>リンク先」の行
# 戻り値：0、読めなければ0以外
print_relative_link() {
  "${BASH}" "${BODY_READER}" "$1" | LC_ALL=C awk -F '\t' '{
    number = $1
    text = substr($0, length(number) + 2)
    # インラインのコードの中は、リンクではない。
    gsub(/`[^`]*`/, "", text)
    while (match(text, /\]\([^)]*\)/)) {
      link = substr(text, RSTART + 2, RLENGTH - 3)
      text = substr(text, RSTART + RLENGTH)
      # スキームのあるリンク（例：https:）は、外のページである。
      if (link != "" && link !~ /^[A-Za-z][A-Za-z0-9+.-]*:/) print number "\t" link
    }
  }'
}

# 1つのファイルの見出しから、GitHubと同じ形のアンカーを出す。
# 引数：ファイルのパス
# 出力：アンカーを1行に1つ
# 戻り値：0、本文を読むスクリプトか、つないだコマンドが失敗したら0以外（grepの1は、見出しが無いことなので0にする）
print_heading_anchor() {
  "${BASH}" "${BODY_READER}" "$1" | cut -f 2- | { LC_ALL=C grep -aE '^#{1,6} ' || [ "$?" -eq 1 ]; } |
    LC_ALL=C sed -E -e 's/^#+ +//' -e 's/ +#* *$//' -e 's/\[([^]]*)\]\([^)]*\)/\1/g' -e $'s\x01'"${PUNCTUATION}"$'\x01\x01g' |
    LC_ALL=C tr 'A-Z ' 'a-z-' |
    LC_ALL=C awk '{ if (seen[$0]++) print $0 "-" (seen[$0] - 1); else print }'
}

# 1つのファイルの切れたリンクを出す。
# 引数：ファイルのパス
# 出力：「ファイル:行: 説明」の行
# 戻り値：0、読めなければ1
print_broken_link() {
  local link_lines line link path anchor target
  if ! link_lines="$(print_relative_link "$1")"; then
    return 1
  fi
  while IFS=$'\t' read -r line link; do
    [ -n "${link}" ] || continue
    path="${link%%#*}"
    anchor=""
    case "${link}" in
      *'#'*) anchor="${link#*#}" ;;
    esac
    target="$1"
    if [ -n "${path}" ]; then
      target="$(dirname "$1")/${path}"
    fi
    if [ ! -e "${target}" ]; then
      printf '%s:%s: リンク先のファイル「%s」がありません。パスを直すか、リンクを消してください。\n' "$1" "${line}" "${path}"
    elif [ -n "${anchor}" ] && ! print_heading_anchor "${target}" | LC_ALL=C grep -xF -e "${anchor}" > /dev/null; then
      printf '%s:%s: リンク先「%s」の見出しがありません。見出しの名前に合わせてください。\n' "$1" "${line}" "${link}"
    fi
  done <<< "${link_lines}"
}

main() {
  local file output
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-broken-link.sh: ファイルが渡されていません。確かめるMarkdownのファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-broken-link.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    if ! output="$(print_broken_link "${file}")"; then
      printf 'find-broken-link.sh: ファイル「%s」を読めませんでした。上のエラーを見て、直してください。\n' "${file}" >&2
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
