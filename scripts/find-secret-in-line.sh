#!/bin/bash
# 種類（contentかfile-name）を受け取り、標準入力の行を、data/secret-pattern-list.txtのその種類のパターンと比べ、当たった場所と種類の名前を標準エラーに出す。行は、contentでは「場所<TAB>中身」、file-nameではファイルのパスである。見つけた値は出さない。
# 終了コードは、0が見つからない、1が見つけた、2が使い方の誤りか、一覧を読めなかったである。
# scripts/find-secret-in-commit.shが、gitのpre-commitとpre-pushのたびに、足した行と、足すか変えたファイルの名前を渡して呼ぶ。
set -u -o pipefail
# 中身をバイトで比べる。grepとbashの=~で、UTF-8として読めないバイトの扱いをそろえ、grepが当てた行を=~で見逃さないためである。
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly PATTERN_LIST="${SCRIPT_DIRECTORY}/../data/secret-pattern-list.txt"

names=()
patterns=()
exclusions=()
grep_arguments=()

# 一覧から、渡した種類の行を読み、配列に入れる。
# 引数：種類
# 出力：なし
# 戻り値：読めてその種類の行があれば0、読めないか、知らない種類の行か、grepが読めないパターンがあれば1
read_pattern_list() {
  local kind name pattern exclusion
  [ -r "${PATTERN_LIST}" ] || return 1
  # 最後の行に改行が無くても、その行を落とさずに読む。
  while IFS=$'\t' read -r kind name pattern exclusion || [ -n "${kind}" ]; do
    case "${kind}" in
      '#'* | '') continue ;;
      content | file-name) [ "${kind}" = "$1" ] || continue ;;
      *) return 1 ;;
    esac
    names+=("${name}")
    patterns+=("${pattern}")
    # 除く形の無い行には、1行の文字列に当たらない改行を入れる。
    exclusions+=("${exclusion:-$'\n'}")
    grep_arguments+=(-e "${pattern}")
  done < "${PATTERN_LIST}"
  [ "${#patterns[@]}" -gt 0 ] || return 1
  # grepは、読めないパターンで2を返す。当てるときの2は見えないので、ここで確かめる。
  grep -qE "${grep_arguments[@]}" < /dev/null
  [ "$?" -eq 1 ]
}

# 比べる行を出す。中身は、先にすべてのパターンを1回で当て、当たった行だけにする。行ごとにすべてのパターンと比べると、遅いためである。ファイルの名前は、パスの全体でなく名前に当てるので、そのまま出す。
# 引数：種類
# 出力：比べる行
# 戻り値：0
print_candidate_line() {
  if [ "$1" = 'content' ]; then
    grep -aE "${grep_arguments[@]}"
    return 0
  fi
  cat
}

main() {
  local line place target i found_count=0
  if [ "$#" -ne 1 ] || { [ "$1" != 'content' ] && [ "$1" != 'file-name' ]; }; then
    printf '%s\n' 'find-secret-in-line.sh: 種類（contentかfile-name）を1つ渡してください。' >&2
    exit 2
  fi
  if ! read_pattern_list "$1"; then
    printf 'find-secret-in-line.sh: 一覧%sを読めませんでした。ハーネスのファイルがそろっているかと、列の形を確かめてください。\n' "${PATTERN_LIST}" >&2
    exit 2
  fi
  while IFS= read -r line; do
    place="${line}" && target="${line##*/}"
    if [ "$1" = 'content' ]; then
      place="${line%%$'\t'*}" && target="${line#*$'\t'}"
    fi
    for i in "${!patterns[@]}"; do
      if [[ "${target}" =~ ${patterns[i]} ]] && ! [[ "${target}" =~ ${exclusions[i]} ]]; then
        printf 'find-secret-in-line.sh: %s: 秘密情報（%s）があります。\n' "${place}" "${names[i]}" >&2
        found_count=$((found_count + 1))
      fi
    done
  done < <(print_candidate_line "$1")
  if [ "${found_count}" -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
