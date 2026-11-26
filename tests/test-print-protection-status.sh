#!/bin/bash
# tests/print-protection-status-case-list.tsvを読み、scripts/print-protection-status.shが出す項目ごとの状態と終了コードを確かめ、結果を出す。コマンドのバージョン、依存、PCの設定、導入先のフックを変えても、働かない保護を見逃さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-protection-status.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-fake-command.sh
source "${TEST_DIRECTORY}/create-fake-command.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
HARNESS_ROOT="$(cd "${TEST_DIRECTORY}/.." && pwd)"
readonly HARNESS_ROOT

# 1つのケースのPCの設定と導入先を作る。
# 引数：ケースのフォルダー、PCの設定の種類、導入先の種類、導入先の.claude/settings.jsonの中身（「-」は作らない）
# 出力：導入先のパス。作れなければ何も出さない
# 戻り値：作れたら0、作れなければ1
create_case_setting() {
  local name event command
  mkdir -p "$1/home/.claude" "$1/project/.claude"
  case "$2" in
    full) sed "s|<ハーネスの場所>|${HARNESS_ROOT}|g" "${HARNESS_ROOT}/data/recommended-claude-setting.json" \
      > "$1/home/.claude/settings.json" ;;
    # 勧める設定に、その値があることを確かめるため、一覧から1つの値だけを抜く。
    without:*) sed "s|<ハーネスの場所>|${HARNESS_ROOT}|g" "${HARNESS_ROOT}/data/recommended-claude-setting.json" \
      | jq --arg value "${2#without:}" 'walk(if type == "array" then map(select(. != $value)) else . end)' \
      > "$1/home/.claude/settings.json" ;;
    partial) printf '%s\n' '{"sandbox": {"enabled": true}}' > "$1/home/.claude/settings.json" ;;
  esac
  if [ "$4" != '-' ]; then
    printf '%s\n' "$4" > "$1/project/.claude/settings.json"
  fi
  if [ "$3" = 'outside' ]; then
    printf '%s\n' "$1/project"
    return 0
  fi
  # bareのリポジトリは、メインの作業フォルダーを求められない導入先として作る。
  if [ "$3" = 'bare-repository' ]; then
    create_case_repository "$1" bare > /dev/null || return 1
    printf '%s\n' "$1/project"
    return 0
  fi
  create_case_repository "$1" git > /dev/null || return 1
  if [ "$3" = 'hooked' ]; then
    while IFS=$'\t' read -r name event command _; do
      case "${name}" in '#'* | '' | harness-commit-message) continue ;; esac
      run_test_git "$1" -C "$1/project" config "hook.${name}.command" "${HARNESS_ROOT}/${command}" || return 1
      run_test_git "$1" -C "$1/project" config "hook.${name}.event" "${event}" || return 1
    done < "${HARNESS_ROOT}/data/git-hook-setting-list.tsv"
  fi
  printf '%s\n' "$1/project"
}

# 1つのケースを作ってスクリプトを動かし、項目ごとの状態の最初の字と終了コードを出す。
# 引数：ケースのフォルダー、OS、動かないコマンド、gitのバージョン、Claude Codeのバージョン、PCの設定、導入先、導入先の設定
# 出力：状態の字を並べたものと終了コードを空白で区切った1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local project output status
  create_fake_command "$1" "$2" "$3"
  create_fake_version_command "$1" "$4" "$5"
  if ! project="$(create_case_setting "$1" "$6" "$7" "$8")"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  output="$(cd "${project}" && env -u CLAUDE_CONFIG_DIR HOME="$1/home" PATH="$1/bin:${PATH}" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" \
    "${BASH}" "${HARNESS_ROOT}/scripts/print-protection-status.sh" 2> /dev/null)"
  status=$?
  # わからないの行は、次の行（起きること）がjqを挙げるかで分け、項目に合わない理由の文を見逃さない。
  printf '%s %s\n' "$(printf '%s\n' "${output}" | awk '/^\[働く\]/ { letters = letters "o" } /^\[働かない\]/ { letters = letters "x" }
    /^\[確かめる\]/ { letters = letters "!" } /^\[見ない\]/ { letters = letters "-" }
    unknown { letters = letters (index($0, "jq") ? "j" : "?"); unknown = 0 } /^\[わからない\]/ { unknown = 1 } END { print letters }')" "${status}"
}

main() {
  local work_directory description os missing git_version claude_version setting project expected
  local project_setting case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description os missing git_version claude_version setting project project_setting \
    expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result "${work_directory}/case-${case_number}" \
      "${os}" "${missing}" "${git_version}" "${claude_version}" "${setting}" "${project}" "${project_setting}")"
  done < "${TEST_DIRECTORY}/print-protection-status-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
