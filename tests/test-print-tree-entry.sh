#!/bin/bash
# tests/print-tree-entry-case-list.tsvを読み、scripts/print-tree-entry.shの出力と終了コードを確かめ、結果を出す。手元のオブジェクトを偽っても、偽った中身を本物として出さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-tree-entry.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/create-remote-case-repository.sh
source "${TEST_DIRECTORY}/create-remote-case-repository.sh"
# shellcheck source=tests/create-forged-repository.sh
source "${TEST_DIRECTORY}/create-forged-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-tree-entry.sh"

main() {
  local work_directory directory description format forge revision path expected commit id tree output status
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  directory="${work_directory}/repository"
  while IFS=$'\t' read -r description format forge revision path expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    if ! create_tree_repository "${directory}" "${format}"; then
      expect "${description}" "${expected}" '作れなかった'
      continue
    fi
    case "${revision}" in
      missing) commit="$(printf '%040d' 0)" ;;
      bad) commit='not-a-sha' ;;
      *) commit="$(run_case_git "${directory}" rev-parse "${revision}")" ;;
    esac
    id="$(run_case_git "${directory}" rev-parse "${revision}:${path%/}")"
    tree="$(run_case_git "${directory}" rev-parse "${revision}^{tree}")"
    forge_repository "${directory}" "${forge}"
    # ふつうのgitが偽装を読まないと、偽装のケースが偽装なしで通るので、ふつうのgitが別のtreeを見ることを確かめる。
    case "${forge}" in
      replace | commit-graph)
        expect "${description}（ふつうのgitは偽装を読む）" 'ほかのtree' \
          "$([ "$(run_case_git "${directory}" log -1 --format=%T "${revision}")" != "${tree}" ] && printf '%s' 'ほかのtree')"
        ;;
    esac
    output="$(HOME="${work_directory}/home" GIT_CONFIG_NOSYSTEM=1 "${BASH}" "${SCRIPT}" "${directory}" "${commit}" "${path}")"
    status=$?
    case "${status}:${output}" in
      0:) output='なし' ;;
      0:*) [ -z "${id}" ] || output="${output/${id}/@ID@}" ;;
      *) output='失敗' ;;
    esac
    expect "${description}" "${expected}" "${output}"
  done < "${TEST_DIRECTORY}/print-tree-entry-case-list.tsv"
  expect 'commitとパスを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${directory}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
