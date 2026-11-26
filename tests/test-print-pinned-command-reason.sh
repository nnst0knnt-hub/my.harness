#!/bin/bash
# tests/print-pinned-command-reason-case-list.tsvを読み、hooks/print-pinned-command-reason.shが出す理由の文と終了コードを確かめ、結果を出す。長い語を短くする所、字数の数え方、全文のファイルのパスを出す条件、全体の上限を変えても、確認の画面で動かす語が読めることを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-pinned-command-reason.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
readonly SCRIPT="${TEST_DIRECTORY}/../hooks/print-pinned-command-reason.sh"
# ケースごとにHOMEを分けるので、記録の名前は決まった英数字にする。
readonly RECORD_NAME='CaseRecord0'
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"

# 1つのケースの記録を書いてスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー（HOMEにする）、判定の理由の文、「|」で区切った記録の語（printfの%bの形、「-」は記録を書かない）、渡す名前（@NAME@は記録の名前）
# 出力：「終了コード 理由の文」の1行（記録のパスは@RECORD@、改行は~）
# 戻り値：0
print_case_result() {
  local record rest output status
  local words=()
  record="$(env -u CLAUDE_CONFIG_DIR HOME="$1" "${BASH}" "${TEST_DIRECTORY}/../hooks/print-pinned-command-record-path.sh" "${RECORD_NAME}")"
  mkdir -p "${record%/*}"
  if [ "$3" != '-' ]; then
    # 語は改行を含むことがあるので、readでなく「|」ごとに切って並べる。
    rest="$(printf '%b' "$3")|"
    while [ -n "${rest}" ]; do words+=("${rest%%|*}") && rest="${rest#*|}"; done
    printf '%s\0' "${words[@]}" > "${record}"
  fi
  output="$(env -u CLAUDE_CONFIG_DIR HOME="$1" "${BASH}" "${SCRIPT}" "$2" "${4//@NAME@/${RECORD_NAME}}" 2> /dev/null)"
  status=$?
  output="${output//${record}/@RECORD@}"
  printf '%s%s\n' "${status}" "$(printf '%s' "${output:+ }${output}" | LC_ALL=C tr '\n' '~')"
}

main() {
  local work_directory description reason word_list name expected case_number=0
  work_directory="$(mktemp -d)"
  # 長い語は、ケースの一覧に「[文字列*数]」で書き、記録の語と期待する結果の両方で同じ語にする。
  while IFS=$'\t' read -r description reason word_list name expected; do
    case "${description}" in '#'* | '') continue ;; esac
    case_number=$((case_number + 1))
    expect "${description}" "$(print_repeated_text "${expected}")" "$(print_case_result "${work_directory}/case-${case_number}" \
      "${reason}" "$(print_repeated_text "${word_list}")" "${name}")"
  done < "${TEST_DIRECTORY}/print-pinned-command-reason-case-list.tsv"
  rm -rf "${work_directory}"
  print_expect_summary || exit 1
  exit 0
}

main "$@"
