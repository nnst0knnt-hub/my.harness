#!/bin/bash
# tests/find-missing-git-hook-setting-case-list.tsvを読み、scripts/find-missing-git-hook-setting.shの出力と終了コードを確かめ、結果を出す。導入先の.git/configに足すgitのフックのうち、無いものと違うものを見逃さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-missing-git-hook-setting.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-missing-git-hook-setting.sh"
# 設定のコマンドの中で展開する文字列なので、ここでは展開しない。
# shellcheck disable=SC2016
readonly ADD_ALL='git config hook.harness-protected-branch.command "${CASE_HARNESS_ROOT}/scripts/deny-protected-branch-push.sh" && git config hook.harness-protected-branch.event pre-push && git config hook.harness-secret-pre-push.command "${CASE_HARNESS_ROOT}/scripts/find-secret-in-commit.sh pre-push" && git config hook.harness-secret-pre-push.event pre-push && git config hook.harness-secret-pre-commit.command "${CASE_HARNESS_ROOT}/scripts/find-secret-in-commit.sh pre-commit" && git config hook.harness-secret-pre-commit.event pre-commit'

# 設定のコマンドを、動かす場所で、HOMEをケースのフォルダーにして動かす。
# 引数：ケースのフォルダー、動かす場所、ハーネスの場所、設定のコマンド
# 出力：動かせなければ「作れなかった」
# 戻り値：動かせたら0、動かせなければ1
run_case_setting() {
  if ! (cd "$2" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 CASE_HARNESS_ROOT="$3" \
    "${BASH}" -c "$4") > /dev/null 2>&1; then
    printf '%s\n' '作れなかった'
    return 1
  fi
}

# 1つのケースの導入先を作り、設定のコマンドを動かしてからスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、ハーネスの場所の種類、設定のコマンド（「-」は動かさない）
# 出力：標準出力の行の名前を「,」でつないだもの（無ければ「なし」）と、終了コードの1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory harness_root="$1/harness" output status setting="$4" script="${SCRIPT}"
  mkdir -p "$1" "${harness_root}"
  if ! run_directory="$(create_case_repository "$1" "$2")"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  if [ "$3" = 'self' ]; then
    harness_root="$1/project"
  fi
  # スクリプトは自分の場所から一覧を読むので、一覧を読めなくするケースでは、コピーを動かす。
  if [ "$3" = 'unreadable' ]; then
    mkdir -p "${harness_root}/scripts"
    cp "${SCRIPT}" "${TEST_DIRECTORY}/../scripts/print-main-worktree-path.sh" "${harness_root}/scripts/"
    create_text_file "${harness_root}/data/git-hook-setting-list.tsv" '!'
    script="${harness_root}/scripts/find-missing-git-hook-setting.sh"
  fi
  # ADD_ALLは先に動かす。置き換えの「&」を、bash 5.2からは合った文字列に読み替えるためである。
  if [ "${setting#ADD_ALL}" != "${setting}" ]; then
    setting="${setting#ADD_ALL}" && setting="${setting# && }" && setting="${setting:--}"
    run_case_setting "$1" "${run_directory}" "${harness_root}" "${ADD_ALL}" || return 0
  fi
  if [ "${setting}" != '-' ]; then
    run_case_setting "$1" "${run_directory}" "${harness_root}" "${setting}" || return 0
  fi
  output="$(HOME="$1" GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" \
    "${BASH}" "${script}" "${run_directory}" "${harness_root}" 2> /dev/null)"
  status=$?
  output="$(printf '%s\n' "${output}" | sed -e 's/:.*$//' -e '/^$/d' | paste -s -d , -)"
  printf '%s %s\n' "${output:-なし}" "${status}"
}

main() {
  local work_directory description place harness_kind setting expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place harness_kind setting expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result \
      "${work_directory}/case-${case_number}" "${place}" "${harness_kind}" "${setting}")"
  done < "${TEST_DIRECTORY}/find-missing-git-hook-setting-case-list.tsv"
  expect '引数が足りなければ、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
