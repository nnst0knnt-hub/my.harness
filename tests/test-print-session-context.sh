#!/bin/bash
# tests/print-session-context-case-list.tsvを読み、hooks/print-session-context.shの終了コード、節ごとに何を出したか、出力の字数を確かめ、結果を出す。フックを変えても、どのファイルを読み、どこを省くかが変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-session-context.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/print-session-context-state.sh
source "${TEST_DIRECTORY}/print-session-context-state.sh"
readonly HOOK="${TEST_DIRECTORY}/../hooks/print-session-context.sh"
readonly MAIN_WORKTREE_READER="${TEST_DIRECTORY}/../scripts/print-main-worktree-path.sh"
readonly ENVIRONMENT_HOOK="${TEST_DIRECTORY}/../hooks/print-environment-state.sh"
readonly SANDBOX_READER="${TEST_DIRECTORY}/../scripts/print-sandbox-state.sh"
readonly TOOL_STATUS_READER="${TEST_DIRECTORY}/../scripts/print-tool-status.sh"
# 共通のルールの字数は、実際のrules/always-read.mdに依らずに合計を決めるため、決まった数にする。
readonly COMMON_RULE_COUNT=1000
# 上限は、.harness/docs/features/always-read-rule.mdの表の、合計の字数である。
readonly CHARACTER_LIMIT=8000

# ケースに置いたフックを動かす。一時フォルダーの上にあるリポジトリを、gitの外のケースで読まないように、上を探させない。人のPCの設定を読まないように、HOMEをケースのフォルダーにする。
# 引数：ケースのフォルダー、フックを動かすフォルダー
# 出力：フックの標準出力
# 戻り値：フックの終了コード
run_hook() {
  env -u CLAUDE_CONFIG_DIR HOME="$1" GIT_CEILING_DIRECTORIES="$1" CLAUDE_PROJECT_DIR="$2" \
    "${BASH}" "$1/harness/hooks/print-session-context.sh" < /dev/null 2> /dev/null
}

# 1つのケースの導入先とハーネスを作ってフックを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、導入先ごとのルールの字数（「=」で始まれば、出力の合計をその字数にする）、目次の字数
# 出力：「終了コード 節ごとの状態 メインの作業フォルダー 環境の状態 上限の内か」の1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local project="$1/project" rule_count="$3" run_directory output status limit='以内'
  mkdir -p "$1/harness/hooks" "$1/harness/scripts" && cp "${HOOK}" "${ENVIRONMENT_HOOK}" "$1/harness/hooks/"
  cp "${MAIN_WORKTREE_READER}" "${SANDBOX_READER}" "${TOOL_STATUS_READER}" "$1/harness/scripts/"
  create_text_file "$1/harness/rules/always-read.md" "${COMMON_RULE_COUNT}"
  if ! run_directory="$(create_case_repository "$1" "$2")"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  create_text_file "${project}/.harness/docs/README.md" "$4"
  if [ "${rule_count#=}" != "${rule_count}" ]; then
    # 100字のルールで一度動かしてルールのほかの字数を求め、合計がちょうど指定の字数になるルールの字数を決める。
    create_text_file "${project}/.harness/rules/always-read.md" 100
    rule_count=$((${rule_count#=} - $(count_character "$(run_hook "$1" "${run_directory}")") + 100))
  fi
  create_text_file "${project}/.harness/rules/always-read.md" "${rule_count}"
  output="$(run_hook "$1" "${run_directory}")"
  status=$?
  if [ "$(count_character "${output}")" -gt "${CHARACTER_LIMIT}" ]; then
    limit='超え'
  fi
  printf '%s %s %s\n' "${status}" "$(print_section_state "${output}" "${project}" \
    "${COMMON_RULE_COUNT}" "${rule_count}" "$4")" "${limit}"
}

main() {
  local work_directory description place rule_count index_count expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place rule_count index_count expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result \
      "${work_directory}/case-${case_number}" "${place}" "${rule_count}" "${index_count}")"
  done < "${TEST_DIRECTORY}/print-session-context-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
