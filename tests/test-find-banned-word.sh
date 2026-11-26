#!/bin/bash
# tests/find-banned-word-case-list.tsvとtests/find-banned-word-location-case-list.tsvを読み、scripts/find-banned-word.shの終了コードと報告の行を確かめ、結果を出す。find-banned-word.shか語の一覧を変えても、判定と場所ごとの止め方が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-banned-word.shか語の一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly LINTER="${TEST_DIRECTORY}/../scripts/find-banned-word.sh"

# gitの設定でcommit-msgにfind-banned-word.shを足した一時のリポジトリで、メッセージを渡してcommitし、結果を出す。このリポジトリのcommit-msgのフックの足し方（CONTRIBUTING.mdの節「機械で確かめるもの」）で止まることを確かめるためである。
# 引数：ケースのフォルダー、printfの%bの形で書いたコミットメッセージ
# 出力：「終了コード commitの数」の1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_commit_message_result() {
  local project="$1/project" status
  mkdir -p "$1"
  if ! run_test_git "$1" init -q "${project}" \
    || ! run_test_git "$1" -C "${project}" config hook.harness-commit-message.command "'${LINTER}'" \
    || ! run_test_git "$1" -C "${project}" config hook.harness-commit-message.event commit-msg; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  run_test_git "$1" -C "${project}" commit -q --allow-empty -m "$(printf '%b' "$2")"
  status=$?
  printf '%s %s\n' "${status}" "$(git -C "${project}" rev-list --count --all 2> /dev/null)"
}

# ASCIIの語の一覧を置いたハーネスのコピーと導入先を作り、場所のフォルダーでファイルを渡して動かし、結果を出す。場所ごとの止め方を、ハーネスの今の一覧に依らずに確かめるためである。
# 引数：ケースのフォルダー、場所、導入先ごとの語の一覧の中身（「-」は置かない）、ファイルの中身（どちらもprintfの%bの形）
# 出力：「終了コード 報告の種類…」の1行
# 戻り値：0
print_location_result() {
  local harness="$1/harness" project="$1/project" run_directory="$1/project" output status
  mkdir -p "${harness}/scripts" "${harness}/data" "${project}"
  cp "${LINTER}" "${TEST_DIRECTORY}/../scripts/print-word-list.sh" "${TEST_DIRECTORY}/../scripts/print-project-word-list.sh" \
    "${TEST_DIRECTORY}/../scripts/find-harness-repository.sh" "${harness}/scripts/"
  if [ "$2" != 補助なし ]; then cp "${TEST_DIRECTORY}/../scripts/print-main-worktree-path.sh" "${harness}/scripts/"; fi
  printf 'omega\tr\n' > "${harness}/data/banned-word-list.txt"
  if [ "$2" != 一覧なし ]; then printf 'alpha\tr\n' > "${harness}/data/ambiguous-word-list.txt"; fi
  case "$2" in
    ハーネス) run_test_git "$1" init -q "${harness}" && run_directory="${harness}" ;;
    gitの外) ;;
    *) run_test_git "$1" init -q "${project}" ;;
  esac
  if [ "$2" = 導入先 ]; then mkdir -p "${project}/.harness/rules"; fi
  if [ "$3" != - ]; then printf '%b' "$3" > "${project}/.harness/rules/word-list.txt"; fi
  printf '%b' "$4" > "${run_directory}/case.txt"
  # 一時のフォルダーの上にあるリポジトリを、gitの外のケースで読まないように、上を探させない。
  output="$(cd "${run_directory}" && GIT_CEILING_DIRECTORIES="$1" "${BASH}" "${harness}/scripts/find-banned-word.sh" case.txt 2>&1)"
  status=$?
  printf '%s %s\n' "${status}" "$(printf '%s\n' "${output}" | LC_ALL=C awk '
    /^case\.txt:/ { kind = index($0, "止める語「") ? "止める" : index($0, "決まっていません") ? "決まっていない" : "示す" }
    !/^case\.txt:/ { kind = $0; sub(/:.*/, "", kind); sub(/.*\//, "", kind) }
    $0 != "" { kinds = kinds separator kind; separator = " " }
    END { print (kinds == "" ? "-" : kinds) }')"
}

main() {
  local work_directory description content expected_status expected_line place word_list expected banned_message number=0
  # ケースの一覧は、ハーネスのリポジトリの中での動きを書くので、どこから呼ばれてもリポジトリの中で動かす。
  cd "${TEST_DIRECTORY}/.." || exit 1
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description content expected_status expected_line; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected_status} ${expected_line}" \
      "$(print_file_case_result "${LINTER}" "${work_directory}/case.txt" "${content}")"
  done < "${TEST_DIRECTORY}/find-banned-word-case-list.tsv"
  # このファイルは止める語の確認の対象なので、止める語の文はケースの一覧の止める1件目から取る。
  banned_message="$(awk -F '\t' '!/^#/ && $3 == 1 { print $2; exit }' "${TEST_DIRECTORY}/find-banned-word-case-list.tsv")"
  expect 'commit-msgのフックとして足すと、止める語のあるメッセージのcommitを止める。' '1 0' \
    "$(print_commit_message_result "${work_directory}/commit-banned" "docs: ${banned_message}")"
  expect 'commit-msgのフックとして足すと、止める語の無いメッセージのcommitは通す。' '0 1' \
    "$(print_commit_message_result "${work_directory}/commit-clean" 'docs: 文を足す')"
  while IFS=$'\t' read -r description place word_list content expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    number=$((number + 1))
    expect "${description}" "${expected}" \
      "$(print_location_result "${work_directory}/location-${number}" "${place}" "${word_list}" "${content}")"
  done < "${TEST_DIRECTORY}/find-banned-word-location-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
