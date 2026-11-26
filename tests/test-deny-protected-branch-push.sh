#!/bin/bash
# tests/deny-protected-branch-push-case-list.tsvを読み、一時のリポジトリからpushして、終了コードとリモートの変化を確かめ、結果を出す。リポジトリには、gitの設定で、scripts/deny-protected-branch-push.shをpre-pushに足す。pushの書き方とworktreeによらず、保護するブランチへのpushがリモートに届かないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もdeny-protected-branch-push.shか保護するブランチの一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/deny-protected-branch-push.sh"

# リモートにmainとfeatureを置き、手元にもう1つcommitを足した導入先を作る。フックは、置いたあとに足す。
# 引数：ケースのフォルダー、pushを動かす場所（mainかworktree）、printfの%bの形で書いた.harness/configの中身（「-」は置かない）
# 出力：pushを動かすフォルダーのパス
# 戻り値：作れたら0、gitの操作が1つでも失敗したら1
create_push_repository() {
  local project="$1/project"
  # リモートのHEADを別の名前にするのは、gitがリモートのHEADのブランチを消すpushを、フックより前に断らないようにするためである。
  run_test_git "$1" init -q --bare -b unused "$1/remote.git" || return 1
  run_test_git "$1" init -q -b main "${project}" || return 1
  run_test_git "$1" -C "${project}" commit -q --allow-empty -m first || return 1
  run_test_git "$1" -C "${project}" remote add origin "$1/remote.git" || return 1
  run_test_git "$1" -C "${project}" push -q origin main main:feature || return 1
  run_test_git "$1" -C "${project}" commit -q --allow-empty -m second || return 1
  run_test_git "$1" -C "${project}" config hook.harness-protected-branch.command "'${SCRIPT}'" || return 1
  run_test_git "$1" -C "${project}" config hook.harness-protected-branch.event pre-push || return 1
  if [ "$3" != '-' ]; then
    mkdir -p "${project}/.harness" && printf '%b' "$3" > "${project}/.harness/config"
  fi
  if [ "$2" = 'worktree' ]; then
    run_test_git "$1" -C "${project}" worktree add -q -b work "$1/worktree" || return 1
    printf '%s\n' "$1/worktree"
    return 0
  fi
  printf '%s\n' "${project}"
}

# 1つのケースの導入先を作ってpushし、結果を出す。
# 引数：ケースのフォルダー、場所、.harness/configの中身、git pushのリモートのあとの引数（空白で区切る）
# 出力：「終了コード リモートの変化」の1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory before after status change='変わった'
  local push_arguments=()
  mkdir -p "$1"
  if ! run_directory="$(create_push_repository "$1" "$2" "$3")" \
    || ! before="$(git -C "$1/remote.git" show-ref)"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  read -r -a push_arguments <<< "$4"
  run_test_git "$1" -C "${run_directory}" push -q origin "${push_arguments[@]}"
  status=$?
  after="$(git -C "$1/remote.git" show-ref)"
  if [ "${before}" = "${after}" ]; then
    change='変わらない'
  fi
  printf '%s %s\n' "${status}" "${change}"
}

main() {
  local work_directory description place config arguments expected case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place config arguments expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${place}" "${config}" "${arguments}")"
  done < "${TEST_DIRECTORY}/deny-protected-branch-push-case-list.tsv"
  expect 'リモートの名前とURLを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" < /dev/null 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
