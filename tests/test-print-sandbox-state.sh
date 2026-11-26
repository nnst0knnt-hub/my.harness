#!/bin/bash
# tests/print-sandbox-state-case-list.tsvを読み、scripts/print-sandbox-state.shの出力を確かめ、結果を出す。OS、依存、設定のファイルの組み合わせを変えても、サンドボックスの状態を誤らず、設定のファイルを決まった順に読むことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-sandbox-state.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-fake-command.sh
source "${TEST_DIRECTORY}/create-fake-command.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-sandbox-state.sh"

# 1つの設定のファイルを、決まった中身で作る。
# 引数：ファイルのパス、中身の種類
# 出力：なし
# 戻り値：0
create_setting_file() {
  mkdir -p "$(dirname "$1")"
  case "$2" in
    true | false) printf '{"sandbox": {"enabled": %s}}\n' "$2" > "$1" ;;
    string) printf '%s\n' '{"sandbox": {"enabled": "true"}}' > "$1" ;;
    none) printf '%s\n' '{"model": "opus"}' > "$1" ;;
    broken) printf '%s\n' '{"sandbox": {"enabled": true,}}' > "$1" ;;
    unreadable) printf '%s\n' '{"sandbox": {"enabled": true}}' > "$1" && chmod 000 "$1" ;;
    folder) mkdir -p "$1" ;;
    # サンドボックスが無いファイルの場所に置く文字デバイスは作れないので、文字デバイスの/dev/nullを指すリンクで試す。
    device) ln -s /dev/null "$1" ;;
  esac
}

# 1つのケースの設定のファイルとコマンドを作ってスクリプトを動かし、結果を出す。
# 引数：ケースのフォルダー、OS、動かないコマンド、設定のファイル
# 出力：スクリプトの標準出力と終了コードを空白で区切った1行
# 戻り値：0
print_case_result() {
  local pair place path output status config_directory=''
  create_fake_command "$1" "$2" "$3"
  for pair in $4; do
    place="${pair%%=*}"
    case "${place}" in
      managed) path="$1/managed/managed-settings.json" ;;
      drop) path="$1/managed/managed-settings.d/10-sandbox.json" ;;
      local) path="$1/main/.claude/settings.local.json" ;;
      project) path="$1/project/.claude/settings.json" ;;
      user) path="$1/home/.claude/settings.json" ;;
      configdir) path="$1/config/settings.json" && config_directory="$1/config" ;;
      worktreelocal) path="$1/project/.claude/settings.local.json" ;;
      *) continue ;;
    esac
    create_setting_file "${path}" "${pair#*=}"
  done
  mkdir -p "$1/home" "$1/main" "$1/project" "$1/managed"
  if [ -n "${config_directory}" ]; then
    output="$(HOME="$1/home" PATH="$1/bin:${PATH}" CLAUDE_CONFIG_DIR="${config_directory}" \
      "${BASH}" "${SCRIPT}" "$1/project" "$1/main" "$1/managed" 2> /dev/null)"
  else
    output="$(env -u CLAUDE_CONFIG_DIR HOME="$1/home" PATH="$1/bin:${PATH}" \
      "${BASH}" "${SCRIPT}" "$1/project" "$1/main" "$1/managed" 2> /dev/null)"
  fi
  status=$?
  printf '%s %s\n' "${output}" "${status}"
}

main() {
  local work_directory description os missing_command setting_file expected case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description os missing_command setting_file expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected} 0" "$(print_case_result \
      "${work_directory}/case-${case_number}" "${os}" "${missing_command}" "${setting_file}")"
  done < "${TEST_DIRECTORY}/print-sandbox-state-case-list.tsv"
  expect '引数が足りなければ、使い方の誤りの2で終わる。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" > /dev/null 2>&1; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
