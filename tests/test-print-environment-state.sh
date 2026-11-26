#!/bin/bash
# tests/print-environment-state-case-list.tsvを読み、hooks/print-environment-state.shの出力の表と段落と、どのケースでもclaudeを動かさないことを確かめ、結果を出す。サンドボックス、jq、gitの状態ごとに、エージェントに渡す動かし方と、人に伝える働かない保護を誤らないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-environment-state.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-fake-command.sh
source "${TEST_DIRECTORY}/create-fake-command.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../hooks/print-environment-state.sh"
readonly STATUS_SCRIPT_PATH="${TEST_DIRECTORY%/tests}/scripts/print-protection-status.sh"

# フックの出力から、表の状態と段落の有無を取り出す。
# 引数：フックの出力
# 出力：「サンドボックス jq git 動かし方 伝える段落 スクリプトの場所」の状態を空白で区切った1行
# 戻り値：0
print_output_state() {
  printf '%s\n' "$1" | awk -v status_path="${STATUS_SCRIPT_PATH}" '
    function cell(line) { sub(/^\| [^|]* \| /, "", line); sub(/（.*$/, "", line); sub(/ \|$/, "", line); return line }
    /^\| サンドボックス \|/ { sandbox = cell($0) }
    /^\| `jq` \|/ { jq = cell($0) }
    /^\| git \|/ { git = $0; sub(/^\| git \| /, "", git); sub(/ \|$/, "", git) }
    /ほかのコマンドとつながず.*`git push origin feat\/add-x:feat\/add-x`.*`git pull`は使わず、`git fetch origin <向き先のブランチ>`のあとに`git merge --ff-only origin\/<向き先のブランチ>`を動かす。向き先のブランチは、PRをマージする先のブランチで、導入先ごとのルールに無ければ`main`である。/ { usage_remote = 1 }
    /auto modeとplan modeでは、書き換わる呼び出しを1つの返事に1つだけ置き、その後ろにほかの呼び出しを続けない。/ { usage_order = 1 }
    /ReadとEditとWriteで行う。/ { usage_file = 1 }
    /`cd`、シェルの変数、`\$\(\.\.\.\)`（例：`for f in`の`\$f`、`\$TMPDIR`）を使わず、パスと値をそのまま書き、作業フォルダーの外のリポジトリには`git -C <絶対パス>`を使う/ { usage_variable = 1 }
    /終了コードを見るために`echo \$\?`をつながない。.*`grep`と`git diff --quiet`のように1で終わっても出さないコマンドがある。行が無いことを0と読まず/ { usage_exit = 1 }
    /^サンドボックスが働かないので/ { notice_sandbox = 1 }
    /^`jq`が無いので/ { notice_jq = 1 }
    /^gitが古いか見つからないので/ && index($0, "直し方は「gitを2.54.0以上にしてください」と伝える。") { notice_git = 1 }
    index($0, status_path) { path = "あり" }
    END {
      notice = (notice_sandbox ? "+サンドボックス" : "") (notice_jq ? "+jq" : "") (notice_git ? "+git" : "")
      print sandbox " " jq " " (git ? git : "なし") " " (usage_remote && usage_order && usage_file && usage_variable && usage_exit ? "あり" : "なし") " " (notice ? substr(notice, 2) : "なし") " " (path ? path : "なし") }'
}

# 1つのケースのコマンドとPCの設定を作ってフックを動かし、結果を出す。
# 引数：ケースのフォルダー、OS、動かないコマンド、gitのバージョン、PCの設定のsandbox.enabled
# 出力：出力の状態と終了コードを空白で区切った1行
# 戻り値：0
print_case_result() {
  local output status
  # 偽のgitを先に作るのは、動かないコマンドにgitを書いたケースで、127で終わるgitに置き換えるためである。
  create_fake_version_command "$1" "$4" -
  # セッションの始めに足すコマンドはgit --versionだけなので、claudeが呼ばれたらclaude-calledのファイルを置き、mainで数える。
  printf '#!/bin/sh\n: > "%s/claude-called"\n' "$1" > "$1/bin/claude"
  create_fake_command "$1" "$2" "$3"
  mkdir -p "$1/home/.claude" "$1/project"
  if [ "$5" != '-' ]; then
    printf '{"sandbox": {"enabled": %s}}\n' "$5" > "$1/home/.claude/settings.json"
  fi
  output="$(env -u CLAUDE_CONFIG_DIR HOME="$1/home" PATH="$1/bin:${PATH}" \
    "${BASH}" "${SCRIPT}" "$1/project" "$1/project" 2> /dev/null)"
  status=$?
  printf '%s %s\n' "$(print_output_state "${output}")" "${status}"
}

main() {
  local work_directory description os missing_command git_version enabled expected case_number=0
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  while IFS=$'\t' read -r description os missing_command git_version enabled expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "${expected}" "$(print_case_result \
      "${work_directory}/case-${case_number}" "${os}" "${missing_command}" "${git_version}" "${enabled}")"
  done < "${TEST_DIRECTORY}/print-environment-state-case-list.tsv"
  expect 'どのケースでも、Claude Codeのバージョンを調べるclaudeを動かさない。' '0' \
    "$(find "${work_directory}" -name claude-called | wc -l | tr -d ' ')"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
