#!/bin/bash
# tests/print-project-word-list-case-list.tsvを読み、scripts/print-project-word-list.shの終了コード、出す行、誤りを示す行番号を確かめ、結果を出す。壊れた導入先ごとの語の一覧で、語が黙って止まらなくならないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-project-word-list.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-project-word-list.sh"

# ケースのフォルダーに一覧を作ってスクリプトに渡し、結果を出す。
# 引数：ケースのフォルダー、一覧の中身（printfの%bの形。「-」は作らない、「!」は読めない、「@」はシンボリックリンク、「/」はフォルダー）
# 出力：「終了コード 行 誤りの行番号」の1行（行は、タブを「/」に、改行を「;」にしたもの。無ければ「-」）
# 戻り値：0
print_case_result() {
  local file="$1/word-list.txt" error status output
  mkdir -p "$1"
  case "$2" in
    -) ;;
    '!') : > "${file}" && chmod 000 "${file}" ;;
    # リンク先には正しい形の行を置き、リンクをたどると行が出てケースが落ちるようにする。
    @) printf 'banned\tleak\tr\n' > "$1/target.txt" && ln -s "$1/target.txt" "${file}" ;;
    /) mkdir -p "${file}" ;;
    *) printf '%b' "$2" > "${file}" ;;
  esac
  error="$("${BASH}" "${SCRIPT}" "${file}" 2>&1 > "$1/output.txt")"
  status=$?
  output="$(LC_ALL=C tr '\t\n' '/;' < "$1/output.txt")"
  output="${output%;}"
  printf '%s %s %s\n' "${status}" "${output:--}" "$(print_reported_line "${file}" "${error}")"
}

main() {
  local work_directory description content expected number=0
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description content expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    number=$((number + 1))
    expect "${description}" "${expected}" "$(print_case_result "${work_directory}/${number}" "${content}")"
  done < "${TEST_DIRECTORY}/print-project-word-list-case-list.tsv"
  expect 'ファイルを渡さないと、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
