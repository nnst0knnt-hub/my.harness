#!/bin/bash
# tests/classify-local-git-state-case-list.tsvを読み、scripts/classify-local-git-state.shが、gitの設定の確認の標準エラーから理由の文に入れる行を確かめ、結果を出す。探す処理の標準エラーに頭の無い行（例：gitの警告）が混ざっても、見つけたものを人に見せるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もclassify-local-git-state.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"

# ハーネスのscripts/をコピーし、gitの設定の確認を、決まった標準エラーと終了コードを出す代わりのスクリプトにして、判定を動かす。
# 引数：ケースのフォルダー、代わりのスクリプトの終了コード、printfの%bの形で書いた標準エラー
# 出力：判定と、理由の文の括弧の中（無ければ「-」）の1行
# 戻り値：0
print_case_result() {
  local output decision finding
  mkdir -p "$1/harness"
  cp -R "${TEST_DIRECTORY}/../scripts" "$1/harness/"
  printf '%b\n' "$3" > "$1/stderr.txt"
  printf '#!/bin/bash\ncat %q >&2\nexit %s\n' "$1/stderr.txt" "$2" > "$1/harness/scripts/find-git-setting-in-working-tree.sh"
  output="$("${BASH}" "$1/harness/scripts/classify-local-git-state.sh" "$1" "$1" project allow '' git fetch origin 2> /dev/null)"
  decision="$(printf '%s\n' "${output}" | sed -n 1p)"
  finding="$(printf '%s\n' "${output}" | sed -n 2p | sed -n 's/.*あります（\(.*\)）。認めると.*/\1/p')"
  printf '%s %s\n' "${decision}" "${finding:--}"
}

main() {
  local work_directory description status error_text expected case_number=0
  work_directory="$(mktemp -d)"
  while IFS=$'\t' read -r description status error_text expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" \
      "$(print_case_result "${work_directory}/case-${case_number}" "${status}" "${error_text}")"
  done < "${TEST_DIRECTORY}/classify-local-git-state-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
