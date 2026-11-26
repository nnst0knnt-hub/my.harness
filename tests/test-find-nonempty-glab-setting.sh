#!/bin/bash
# tests/find-nonempty-glab-setting-case-list.tsvを読み、一時のフォルダーにglab-cliを作って、scripts/find-nonempty-glab-setting.shの終了コードと出したパスを確かめ、結果を出す。サンドボックスが置く空のglab-cliを設定とみなさず、中身のあるものとリンクを必ず見つけることを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-nonempty-glab-setting.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-nonempty-glab-setting.sh"
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"

# 1つのケースのフォルダーでコマンドを動かし、スクリプトにパスを渡して、結果を出す。
# 引数：ケースのフォルダー、動かすコマンド（「-」は何もしない）、空白で区切ったパス（@CASE@はケースのフォルダー）
# 出力：「終了コード 出したパス」の1行（パスの中のケースのフォルダーは@CASE@）。コマンドが失敗すれば「作れなかった」
# 戻り値：0
print_case_result() {
  local output status
  local paths=()
  mkdir -p "$1"
  if [ "$2" != '-' ] && ! (cd "$1" && "${BASH}" -c "$2") > /dev/null 2>&1; then
    printf '%s\n' '作れなかった' && return 0
  fi
  read -r -a paths <<< "${3//@CASE@/$1}"
  output="$("${BASH}" "${SCRIPT}" "${paths[@]}" 2> /dev/null)"
  status=$?
  printf '%s\n' "${status}${output:+ }${output//$1/@CASE@}"
}

main() {
  local work_directory description command paths expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含むので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description command paths expected; do
    case "${description}" in '#'* | '') continue ;; esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${command}" "${paths}")"
  done < "${TEST_DIRECTORY}/find-nonempty-glab-setting-case-list.tsv"
  expect 'パスを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" 2> /dev/null; printf '%s' "$?")"
  # 中を読めないフォルダーのケースを消せるように、権限を戻してから消す。
  chmod -R u+rwx "${work_directory}"
  rm -rf "${work_directory}"
  print_expect_summary || exit 1
  exit 0
}

main "$@"
