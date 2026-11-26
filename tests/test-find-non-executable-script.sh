#!/bin/bash
# tests/find-non-executable-script-case-list.tsvを読み、linters/find-non-executable-script.shの終了コードと報告を確かめ、結果を出す。find-non-executable-script.shを変えても、判定が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-non-executable-script.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly LINTER="${TEST_DIRECTORY}/../linters/find-non-executable-script.sh"

# 権限を付けたスクリプトを作ってlinterに渡し、終了コードを出す。
# 引数：作るファイルのパス、権限
# 権限の「-」はファイルを渡さずに動かし、「?」は無いファイルを渡す。
# 出力：終了コード（止めたのに標準エラーの報告がファイルの名前で始まらなければ、「報告なし」を付ける）
# 戻り値：0
print_case_status() {
  local output
  local status
  rm -f "$1"
  if [ "$2" = '-' ]; then
    "${BASH}" "${LINTER}" > /dev/null 2>&1
    printf '%s\n' "$?"
    return 0
  fi
  if [ "$2" != '?' ]; then
    printf '%s\n' '#!/bin/bash' > "$1"
    chmod "$2" "$1"
  fi
  output="$("${BASH}" "${LINTER}" "$1" 2>&1 > /dev/null)"
  status=$?
  if [ "${status}" -eq 1 ]; then
    case "${output}" in
      "$1: "*) ;;
      *) status="${status} 報告なし" ;;
    esac
  fi
  printf '%s\n' "${status}"
}

main() {
  local work_directory
  local description
  local mode
  local expected_status
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description mode expected_status; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected_status}" \
      "$(print_case_status "${work_directory}/case.sh" "${mode}")"
  done < "${TEST_DIRECTORY}/find-non-executable-script-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
