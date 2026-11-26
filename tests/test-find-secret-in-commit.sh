#!/bin/bash
# tests/find-secret-in-commit-case-list.tsvを読み、一時のリポジトリでcommitとpushをして、終了コードを確かめ、結果を出す。リポジトリには、gitの設定で、scripts/find-secret-in-commit.shをpre-commitとpre-pushに足す。秘密情報を含むcommitとpushが止まり、秘密情報を消す変更と送ってある秘密情報では止まらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-secret-in-commit.shか秘密情報のパターンの一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-secret-in-commit.sh"

# 中身の「[文字列*数]」を、文字列を数だけ並べたものに置き換えてファイルに書き（「-」なら消し）、commitする。
# 引数：ケースのフォルダー、リポジトリ、ファイルのパス、printfの%bの形で書いた中身、commitのメッセージ
# 出力：なし
# 戻り値：gitの戻り値
commit_case_file() {
  rm -f "$2/$3"
  if [ "$4" != '-' ]; then
    mkdir -p "$(dirname "$2/$3")" && printf '%b' "$(print_repeated_text "$4")" > "$2/$3"
  fi
  run_test_git "$1" -C "$2" add -A && run_test_git "$1" -C "$2" commit -q -m "$5"
}

# 1つのケースの導入先を作ってcommitかpushをし、結果を出す。
# 引数：ケースのフォルダー、種類、ファイルのパス、先の中身、次の中身
# 出力：終了コードの1行。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local project="$1/project" event='pre-push' remote='origin'
  mkdir -p "$1"
  case "$2" in
    pre-commit) event='pre-commit' ;;
    pre-push-url) remote="$1/remote.git" ;;
  esac
  # 先の中身は、フックを足す前に置く。先に秘密情報があるケースで、置くcommitが止まらないようにするためである。
  { run_test_git "$1" init -q --bare -b unused "$1/remote.git" \
    && run_test_git "$1" init -q -b main "${project}" \
    && commit_case_file "$1" "${project}" first.txt 'first\n' first \
    && run_test_git "$1" -C "${project}" remote add origin "$1/remote.git" \
    && run_test_git "$1" -C "${project}" push -q origin main \
    && run_test_git "$1" -C "${project}" switch -q -c feature \
    && case "$2" in
      pre-commit | pre-push) [ "$4" = '-' ] || commit_case_file "$1" "${project}" "$3" "$4" before ;;
      pre-push-sent) commit_case_file "$1" "${project}" "$3" "$4" before \
        && run_test_git "$1" -C "${project}" push -q origin feature:sent ;;
      pre-push-url | pre-push-delete) commit_case_file "$1" "${project}" "$3" "$4" before \
        && run_test_git "$1" -C "${project}" push -q "${remote}" feature ;;
      pre-push-root) run_test_git "$1" -C "${project}" config log.showRoot false \
        && run_test_git "$1" -C "${project}" switch -q main && run_test_git "$1" -C "${project}" branch -q -D feature \
        && run_test_git "$1" -C "${project}" switch -q --orphan feature ;;
      pre-push-merge) run_test_git "$1" -C "${project}" switch -q -c side main \
        && commit_case_file "$1" "${project}" "$3" "$4" side \
        && run_test_git "$1" -C "${project}" switch -q feature \
        && commit_case_file "$1" "${project}" other.txt 'other\n' other \
        && run_test_git "$1" -C "${project}" merge -q --no-commit side ;;
      *) false ;;
    esac \
    && run_test_git "$1" -C "${project}" config hook.harness-secret.command "'${SCRIPT}' ${event}" \
    && run_test_git "$1" -C "${project}" config hook.harness-secret.event "${event}"; } \
    || { printf '%s\n' '作れなかった' && return 0; }
  case "$2" in
    pre-commit) commit_case_file "$1" "${project}" "$3" "$5" after ;;
    pre-push-delete) run_test_git "$1" -C "${project}" push -q origin :feature ;;
    *) commit_case_file "$1" "${project}" "$3" "$5" after || { printf '%s\n' '作れなかった' && return 0; }
      run_test_git "$1" -C "${project}" push -q "${remote}" feature ;;
  esac
  printf '%s\n' "$?"
}

main() {
  local work_directory description kind path before after expected case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description kind path before after expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${kind}" "${path}" "${before}" "${after}")"
  done < "${TEST_DIRECTORY}/find-secret-in-commit-case-list.tsv"
  mkdir -p "${work_directory}/unknown"
  run_test_git "${work_directory}/unknown" init -q "${work_directory}/unknown/project"
  expect '送るcommitを読めないと、止める。' '1' \
    "$(cd "${work_directory}/unknown/project" && printf 'HEAD %s refs/heads/x %s\n' "$(printf '1%.0s' {1..40})" "$(printf '0%.0s' {1..40})" |
      HOME="${work_directory}/unknown" GIT_CONFIG_NOSYSTEM=1 "${BASH}" "${SCRIPT}" pre-push origin url 2> /dev/null; printf '%s' "$?")"
  expect 'フックの名前を渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" < /dev/null 2> /dev/null; printf '%s' "$?")"
  expect 'pre-pushでリモートの名前とURLを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" pre-push < /dev/null 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
