#!/bin/bash
# tests/find-git-setting-in-working-tree-case-list.tsvを読み、scripts/find-git-setting-in-working-tree.shの終了コードを確かめ、結果を出す。探し方を変えても、次の3つが変わらないことを確かめるためである。サンドボックスの中から書ける設定とファイルを見逃さないこと、ふつうのリポジトリで確認を増やさないこと、見つけたものの文のほか（例：bashのエラー）を標準エラーに出さないことである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-git-setting-in-working-tree.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/find-git-setting-in-working-tree.sh"

# 1つのケースの導入先を作り、設定のコマンドを動かしてからスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、設定のコマンド（「-」は動かさない）
# 出力：終了コードの1行。頭の無い標準エラーの行があれば、終了コードの後ろに「頭の無い標準エラー」。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory harness_root="$1/harness" error_output status
  mkdir -p "$1" "${harness_root}/scripts"
  if ! run_directory="$(create_case_repository "$1" "$2")"; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  if [ "$3" != '-' ] && ! (cd "${run_directory}" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 \
    CASE_HARNESS_ROOT="${harness_root}" "${BASH}" -c "$3") > /dev/null 2>&1; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  error_output="$(HOME="$1" GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" \
    "${BASH}" "${SCRIPT}" "${run_directory}" "${harness_root}" 2>&1 > /dev/null)"
  status=$?
  # 呼び出し元は、頭で選んだ見つけたものの文を理由の文に入れるので、頭の無い行（例：bashのエラー）が出ないことも確かめる。
  if printf '%s\n' "${error_output}" \
    | LC_ALL=C grep -v -E '^(find-git-setting-in-working-tree|find-git-transport-setting)\.sh: |^$' | LC_ALL=C grep -q .; then
    printf '%s 頭の無い標準エラー\n' "${status}"
    return 0
  fi
  printf '%s\n' "${status}"
}

main() {
  local work_directory description place setting expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place setting expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${place}" "${setting}")"
  done < "${TEST_DIRECTORY}/find-git-setting-in-working-tree-case-list.tsv"
  expect 'ハーネスの場所を渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
