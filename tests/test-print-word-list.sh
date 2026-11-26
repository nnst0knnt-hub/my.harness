#!/bin/bash
# tests/print-word-list-case-list.tsvを読み、scripts/print-word-list.shを、一時のフォルダーに作ったハーネスのコピーと導入先で動かして、場所ごとに出す行と終了コードを確かめる。語を落とさずに渡し、場所と導入先の答えのとおりに種類を決めることを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-word-list.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT_DIRECTORY="${TEST_DIRECTORY}/../scripts"

# ハーネスのコピーと導入先を作ってスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、止める語の一覧の中身、確かめる語の一覧の中身、導入先ごとの語の一覧の中身（printfの%bの形、「-」は置かない）
# 出力：「終了コード 行 標準エラーの行の数」の1行（行は、タブを「/」に、改行を「;」にしたもの。無ければ「-」）
# 戻り値：0
print_case_result() {
  local harness="$1/harness" project="$1/project" run_directory="$1/project" error status output
  mkdir -p "${harness}/scripts" "${harness}/data"
  cp "${SCRIPT_DIRECTORY}/print-word-list.sh" "${SCRIPT_DIRECTORY}/print-project-word-list.sh" \
    "${SCRIPT_DIRECTORY}/find-harness-repository.sh" "${harness}/scripts/"
  if [ "$2" != 補助なし ]; then
    cp "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "${harness}/scripts/"
  fi
  if [ "$3" != - ]; then printf '%b' "$3" > "${harness}/data/banned-word-list.txt"; fi
  if [ "$4" != - ]; then printf '%b' "$4" > "${harness}/data/ambiguous-word-list.txt"; fi
  case "$2" in
    ハーネス) run_test_git "$1" init -q "${harness}" && project="${harness}" && run_directory="${harness}" ;;
    # worktreeの側には壊れた一覧を置き、worktreeの一覧を読むとケースが落ちるようにする。
    worktree) run_directory="$(create_case_repository "$1" worktree)" && printf 'broken\n' > "${run_directory}/.harness/rules/word-list.txt" ;;
    gitの外) create_case_repository "$1" 外 > /dev/null ;;
    *) create_case_repository "$1" git > /dev/null ;;
  esac
  case "$2" in
    導入なし) ;;
    rulesがリンク) mkdir -p "${project}/.harness" && ln -s /dev/null "${project}/.harness/rules" ;;
    *) mkdir -p "${project}/.harness/rules" ;;
  esac
  if [ "$5" != - ]; then printf '%b' "$5" > "${project}/.harness/rules/word-list.txt"; fi
  # 一時のフォルダーの上にあるリポジトリを、gitの外のケースで読まないように、上を探させない。
  error="$(GIT_CEILING_DIRECTORIES="$1" "${BASH}" "${harness}/scripts/print-word-list.sh" "${run_directory}" 2>&1 \
    > "$1/output.txt")"
  status=$?
  output="$(LC_ALL=C tr '\t\n' '/;' < "$1/output.txt")"
  output="${output%;}"
  printf '%s %s %s\n' "${status}" "${output:--}" "$(printf '%s' "${error}" | grep -c '')"
}

main() {
  local work_directory description place banned ambiguous project expected actual number=0
  work_directory="$(mktemp -d)"
  # 今の2つの一覧をハーネスのリポジトリで読むと、コメントと空行を除いた行の数だけ、止める語の行を出す。
  expected="$(cat "${TEST_DIRECTORY}/../data/banned-word-list.txt" "${TEST_DIRECTORY}/../data/ambiguous-word-list.txt" |
    grep -c -v -e '^#' -e '^$')"
  actual="$("${BASH}" "${SCRIPT_DIRECTORY}/print-word-list.sh" "${TEST_DIRECTORY}/.." | awk -F '\t' '$1 == "banned"' |
    wc -l | tr -d ' ')"
  expect '今の2つの一覧をハーネスのリポジトリで読むと、語の数だけ、bannedの行を出す。' "${expected}" "${actual}"
  while IFS=$'\t' read -r description place banned ambiguous project expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    number=$((number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/${number}" "${place}" "${banned}" "${ambiguous}" "${project}")"
  done < "${TEST_DIRECTORY}/print-word-list-case-list.tsv"
  expect 'フォルダーを渡さないと、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT_DIRECTORY}/print-word-list.sh" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
