#!/bin/bash
# tests/print-main-worktree-path-case-list.tsvを読み、scripts/print-main-worktree-path.shの終了コードと、出したパスの種類を確かめ、結果を出す。求め方を変えても、worktreeや.gitの置き場所の違う導入先で、同じ場所を出すことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-main-worktree-path.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-main-worktree-path.sh"

# 1つのケースの導入先を作ってスクリプトを動かし、結果を出す。一時フォルダーの上にあるリポジトリを、gitの外のケースで読まないように、上を探させない。
# 引数：ケースのフォルダー、場所（tests/create-case-repository.shのcreate_case_repositoryの場所）
# 出力：「終了コード パスの種類（project、なし、違う場所）」の1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory output status kind='違う場所'
  mkdir -p "$1"
  if ! run_directory="$(create_case_repository "$1" "$2")"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  output="$(GIT_CEILING_DIRECTORIES="$1" "${BASH}" "${SCRIPT}" "${run_directory}" 2> /dev/null)"
  status=$?
  if [ -z "${output}" ]; then
    kind='なし'
  elif [ "${output}" = "$1/project" ]; then
    kind='project'
  fi
  printf '%s %s\n' "${status}" "${kind}"
}

main() {
  local work_directory description place expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result "${work_directory}/case-${case_number}" "${place}")"
  done < "${TEST_DIRECTORY}/print-main-worktree-path-case-list.tsv"
  expect 'フォルダーを渡さないと、使い方の誤りで止める。' '2' "$("${BASH}" "${SCRIPT}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
