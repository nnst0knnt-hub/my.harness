#!/bin/bash
# tests/print-project-common-directory-case-list.tsvを読み、scripts/print-project-common-directory.shの終了コードと出力を確かめ、結果を出す。導入先のリポジトリとみなす形を変えても、Claude Codeのworktreeとメインの作業フォルダーを通し、.gitを偽のリポジトリに向けた形と、知らない形のworktreeを通さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-project-common-directory.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-project-common-directory.sh"

# 1つのケースの導入先を作り、設定のコマンドを動かしてからスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、場所、設定のコマンド（「-」は動かさない）、printfの%bの形で書いた、ケースのフォルダーからのCLAUDE_PROJECT_DIRのパス（「-」は動かす場所）、前に付ける環境変数（空白で区切り、@ROOT@はケースのフォルダー。「-」は無し）
# 出力：「終了コード 出力」の1行（ケースのフォルダーは@ROOT@）。何も出さなければ終了コードだけ。ケースを作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory project output status
  local variables=()
  mkdir -p "$1"
  if ! run_directory="$(create_case_repository "$1" "$2")" || { [ "$3" != '-' ] \
    && ! (cd "${run_directory}" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$3") > /dev/null 2>&1; }; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  project="${run_directory}"
  [ "$4" = '-' ] || project="$1/$(printf '%b' "$4")"
  [ "$5" = '-' ] || read -r -a variables <<< "${5//@ROOT@/$1}"
  output="$(env HOME="$1" GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" ${variables[@]+"${variables[@]}"} \
    "${BASH}" "${SCRIPT}" "${project}" 2> /dev/null)"
  status=$?
  printf '%s%s\n' "${status}" "${output:+ ${output//$1/@ROOT@}}"
}

main() {
  local work_directory description place setting project variable expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description place setting project variable expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${place}" "${setting}" "${project}" "${variable}")"
  done < "${TEST_DIRECTORY}/print-project-common-directory-case-list.tsv"
  expect 'Claude Codeの作業フォルダーを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" 2> /dev/null; printf '%s' "$?")"
  # 空の値でcdすると今のフォルダーに残るので、リポジトリの中で動かして、そのリポジトリを出さないことを確かめる。
  create_case_repository "${work_directory}/empty" git > /dev/null
  expect 'リポジトリの中で空の値を渡すと、何も出さずに1で終わる。' '1' \
    "$(cd "${work_directory}/empty/project" && "${BASH}" "${SCRIPT}" '' 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
