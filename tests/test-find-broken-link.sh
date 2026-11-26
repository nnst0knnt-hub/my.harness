#!/bin/bash
# 一時のフォルダーにリンク先の文書を作り、tests/find-broken-link-case-list.tsvを読んで、linters/find-broken-link.shの終了コードと報告の行を確かめ、結果を出す。find-broken-link.shを変えても、判定が変わらないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もfind-broken-link.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
readonly LINTER="${TEST_DIRECTORY}/../linters/find-broken-link.sh"

# ケースのリンク先になる文書を作る。
# 引数：作業のフォルダーのパス
# 出力：なし
# 戻り値：0
create_link_target() {
  mkdir -p "$1/sub"
  : > "$1/sub/other.md"
  cat > "$1/target.md" << 'EOF'
# 題

## PRの題と本文

## `.harness/docs/`

## 「括弧」と、読点（例）

## Same

## Same

```text
## コードの中
```
EOF
}

main() {
  local work_directory
  local description
  local content
  local expected_status
  local expected_line
  work_directory="$(mktemp -d)"
  create_link_target "${work_directory}"
  while IFS=$'\t' read -r description content expected_status expected_line; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    expect "${description}" "${expected_status} ${expected_line}" \
      "$(print_file_case_result "${LINTER}" "${work_directory}/case.md" "${content}")"
  done < "${TEST_DIRECTORY}/find-broken-link-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
