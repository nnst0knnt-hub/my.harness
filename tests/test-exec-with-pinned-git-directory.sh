#!/bin/bash
# tests/exec-with-pinned-git-directory-case-list.tsvとtests/exec-with-pinned-git-directory-flow-case-list.tsvを読み、hooks/exec-with-pinned-git-directory.shが、フックの記録の語だけを、gitのフォルダーを固定して動かすかを確かめ、結果を出す。判定のあとにgitのフォルダーを書き換えても、外のコマンドがエージェントの書いた設定とフックを使わないことを、フックの書き換えから本物のgitまでつないで確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もexec-with-pinned-git-directory.shかhooks/read-bash-command.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
readonly HARNESS_ROOT="${TEST_DIRECTORY}/.."
readonly SCRIPT="${HARNESS_ROOT}/hooks/exec-with-pinned-git-directory.sh"
# ケースごとにHOMEを分けるので、記録の名前は決まった英数字にする。
readonly RECORD_NAME='CaseRecord0'
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/create-fake-command.sh
source "${TEST_DIRECTORY}/create-fake-command.sh"
# shellcheck source=tests/print-hook-flow-result.sh
source "${TEST_DIRECTORY}/print-hook-flow-result.sh"

# 1つのケースの導入先を作り、場所を求めて記録と全文のファイルを書き、判定のあとのコマンドを動かしてからスクリプトを動かして、結果を出す。
# 引数：ケースのフォルダー、場所、判定のあとに動かすコマンド、記録、前に付ける環境変数（「-」は無し）、「|」で区切った記録の語、「|」で区切った渡す名前（「-」は無し）、標準エラーに含むはずの語（空は見ない）、偽のコマンドのフォルダー
# 出力：「終了コード 出力」の1行（ケースのフォルダーは@CASE@、改行は~）。語が無ければ「理由に「語」なし」を、記録か全文のファイルが残れば「残った：記録」か「残った：全文のファイル」を足す。作れなければ「作れなかった」
# 戻り値：0
print_case_result() {
  local run_directory location git_directory common_directory toplevel rest record output status error left=''
  local words=() names=() variables=()
  mkdir -p "$1"
  if ! run_directory="$(create_case_repository "$1" "$2")" \
    || ! location="$(HOME="$1" GIT_CEILING_DIRECTORIES="$1" "${BASH}" "${HARNESS_ROOT}/scripts/print-git-directory.sh" "${run_directory}")"; then
    printf '%s\n' '作れなかった' && return 0
  fi
  { IFS= read -r git_directory && IFS= read -r common_directory && IFS= read -r toplevel; } <<< "${location}"
  # 語は改行を含むことがあるので、readでなく「|」ごとに切って並べる。
  rest="$(printf '%b' "$6")"
  rest="${rest//@GIT@/${git_directory}}" && rest="${rest//@COMMON@/${common_directory}}" && rest="${rest//@TOP@/${toplevel}}|"
  while [ -n "${rest}" ]; do words+=("${rest%%|*}") && rest="${rest#*|}"; done
  [ "$7" = '-' ] || IFS='|' read -r -a names <<< "${7//@NAME@/${RECORD_NAME}}"
  [ "$5" = '-' ] || read -r -a variables <<< "$5"
  record="$(HOME="$1" "${BASH}" "${HARNESS_ROOT}/hooks/print-pinned-command-record-path.sh" "${RECORD_NAME}")"
  mkdir -p "${record%/*}"
  case "$4" in
    あり | 2回) printf '%s\0' "${words[@]}" > "${record}" && : > "${record}.txt" ;;
    古い) printf '%s\0' "${words[@]}" > "${record}" && : > "${record}.txt" && touch -t 202001010000 "${record}" ;;
  esac
  if [ "$3" != '-' ] && ! (cd "${run_directory}" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$3") > /dev/null 2>&1; then
    printf '%s\n' '作れなかった' && return 0
  fi
  if [ "$4" = '2回' ]; then
    (cd "${run_directory}" && env -u CLAUDE_CONFIG_DIR HOME="$1" PATH="$9/bin:${PATH}" "${BASH}" "${SCRIPT}" ${names[@]+"${names[@]}"}) > /dev/null 2>&1
  fi
  # Claude Codeのサンドボックスは、GIT_CONFIG_COUNTでsafe.directoryを渡すので、ケースで決めないときは0にする。
  output="$(cd "${run_directory}" && env -u CLAUDE_CONFIG_DIR HOME="$1" PATH="$9/bin:${PATH}" GIT_CONFIG_COUNT=0 ${variables[@]+"${variables[@]}"} \
    "${BASH}" "${SCRIPT}" ${names[@]+"${names[@]}"} 2> "$1/error.txt" | LC_ALL=C tr '\n' '~')"
  status=$?
  error="$(cat "$1/error.txt")"
  [ ! -e "${record}" ] || left="${left} 残った：記録"
  [ ! -e "${record}.txt" ] || left="${left} 残った：全文のファイル"
  output="${status}${output:+ }${output//$1/@CASE@}${left}"
  case "${error}" in
    *"$8"*) printf '%s\n' "${output}" ;;
    *) printf '%s 理由に「%s」なし\n' "${output}" "$8" ;;
  esac
}

main() {
  local work_directory description place mutation record variable word_list name_list expected word setup command check case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  create_fake_remote_command "${work_directory}/fake"
  while IFS=$'\t' read -r description place mutation record variable word_list name_list expected word; do
    case "${description}" in '#'* | '') continue ;; esac
    case_number=$((case_number + 1)) && [ "${word}" != '-' ] || word=''
    expect "${description}" "${expected}" "$(print_case_result "${work_directory}/case-${case_number}" \
      "${place}" "${mutation}" "${record}" "${variable}" "${word_list}" "${name_list}" "${word}" "${work_directory}/fake")"
  done < "${TEST_DIRECTORY}/exec-with-pinned-git-directory-case-list.tsv"
  # 長い語は、ケースの一覧に「[文字列*数]」で書き、コマンドと確かめるコマンドの両方で同じ語にする。
  # 改行は@LF@で書き、行ごとに読むprint_repeated_textのあとで置き換える。
  while IFS=$'\t' read -r description place setup command mutation check expected; do
    case "${description}" in '#'* | '') continue ;; esac
    case_number=$((case_number + 1)) && command="$(print_repeated_text "${command}")"
    expect "${description}" "${expected}" "$(print_hook_flow_result "${HARNESS_ROOT}" "${work_directory}/case-${case_number}" \
      "${place}" "${setup}" "${command//@LF@/$'\n'}" "${mutation}" "$(print_repeated_text "${check}")")"
  done < "${TEST_DIRECTORY}/exec-with-pinned-git-directory-flow-case-list.tsv"
  rm -rf "${work_directory}"
  print_expect_summary || exit 1
  exit 0
}

main "$@"
