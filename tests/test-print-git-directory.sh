#!/bin/bash
# tests/print-git-directory-case-list.tsvを読み、scripts/print-git-directory.shの終了コードと出力を確かめ、結果を出す。求め方を変えても、worktree、別の場所の.git、commondirで、gitが実際に使う場所を出すことと、求められない場所で何も出さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-git-directory.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-git-directory.sh"

# 1つのケースの導入先を作り、設定のコマンドを動かしてからスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、設定のコマンド（「-」は動かさない）、printfの%bの形で書いた動かすフォルダー（「-」は動かす場所）
# 出力：「終了コード 1行目|2行目|3行目」の1行（ケースのフォルダーは@CASE@）。何も出さなければ終了コードだけ。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory output status
  mkdir -p "$1"
  if ! run_directory="$(create_case_repository "$1" "$2")" || { [ "$3" != '-' ] \
    && ! (cd "${run_directory}" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$3") > /dev/null 2>&1; }; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  if [ "$4" != '-' ]; then
    run_directory="${run_directory}/$(printf '%b' "$4")"
  fi
  output="$(HOME="$1" GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" "${BASH}" "${SCRIPT}" "${run_directory}" 2> /dev/null)"
  status=$?
  if [ -z "${output}" ]; then
    printf '%s\n' "${status}"
    return 0
  fi
  output="$(printf '%s\n' "${output}" | paste -s -d '|' -)"
  printf '%s %s\n' "${status}" "${output//$1/@CASE@}"
}

main() {
  local work_directory description place setting folder expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place setting folder expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${place}" "${setting}" "${folder}")"
  done < "${TEST_DIRECTORY}/print-git-directory-case-list.tsv"
  expect 'フォルダーを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
