#!/bin/bash
# tests/read-bash-command-case-list.tsvを読み、hooks/read-bash-command.shの終了コードと、出したJSONの判定と、書いたフックの記録を確かめ、結果を出す。フックの入出力を変えても、判定のとおりのJSONと記録を出し、jqが無いときと入力や判定がおかしいときに確認を求めることを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もread-bash-command.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
readonly HARNESS_ROOT="${TEST_DIRECTORY}/.."
# フックが書き換えた入力の、ハーネスの場所を@HARNESS@に置き換えるため、フックと同じ求め方で求める。
HARNESS_PATH="$(cd "${HARNESS_ROOT}" && pwd)"
readonly HARNESS_PATH
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"

# jqの無いPATHのフォルダーと、決まった判定以外を返す判定のスクリプトを置いたハーネスの場所と、理由の文を作るスクリプトが1で終わるハーネスのコピーを作る。
# 引数：作るフォルダー
# 出力：なし
# 戻り値：0
create_variant() {
  local command
  mkdir -p "$1/bin" "$1/harness/hooks" "$1/harness/scripts"
  for command in cat dirname git sed grep awk; do
    ln -s "$(command -v "${command}")" "$1/bin/${command}"
  done
  cp "${HARNESS_ROOT}/hooks/read-bash-command.sh" "$1/harness/hooks/"
  printf '%s\n' '#!/bin/bash' "printf 'maybe\\n\\n'" > "$1/harness/scripts/classify-remote-command.sh"
  mkdir -p "$1/broken-reason"
  cp -R "${HARNESS_ROOT}/hooks" "${HARNESS_ROOT}/scripts" "${HARNESS_ROOT}/data" "$1/broken-reason/"
  printf '%s\n' '#!/bin/bash' 'exit 1' > "$1/broken-reason/hooks/print-pinned-command-reason.sh"
}

# 1つのケースの導入先を作ってフックを動かし、結果を出す。Claude Codeの作業フォルダー（CLAUDE_PROJECT_DIR）は、プロジェクトなしと「プロジェクト=」の動かし方のほかは、動かす場所にする。「プロジェクト=」は、作業フォルダーの下の別のリポジトリ、worktreeの中のworktreeや下のフォルダーで始めたセッション、CLAUDE_PROJECT_DIRがメインの作業フォルダーでworktreeのコマンドを動かすセッション（EnterWorktreeで移ったセッションとClaude Codeのデスクトップアプリのworktreeのセッション）を確かめる。サンドボックスが渡すGIT_SSH_COMMANDは、サンドボックスの外で動くフックには無いので外す。
# 引数：ケースのフォルダー、場所、設定のコマンド、動かし方、printfの%bの形で書いた入力のJSON、作ったフォルダー
# 出力：「終了コード 判定」の1行。書き換えた入力があれば、そのJSONと、フックの記録の語（「記録=[語]…」）と全文のファイルの中身（「全文=」）を、理由も出す動かし方では理由の文（「理由=」）を、ケースのフォルダーにmarkerができたら「marker=yes」を後ろに足す。記録の名前は@NAME@、記録のパスは@RECORD@、ハーネスの場所は@HARNESS@、ケースのフォルダーは@ROOT@、導入先のHEADのSHAは@SHA@、改行は~にする。JSONの形が違えば判定を「形の誤り」に、ケースを作れなければ「作れなかった」にする
# 戻り値：0
print_case_result() {
  local run_directory input output status hook="${HARNESS_ROOT}/hooks/read-bash-command.sh" path="${PATH}" head_id record record_name word variables assignment
  mkdir -p "$1"
  if ! run_directory="$(create_case_repository "$1" "$2")" || { [ "$3" != '-' ] \
    && ! (cd "${run_directory}" && HOME="$1" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$3") > /dev/null 2>&1; }; then
    printf '%s\n' '作れなかった'
    return 0
  fi
  variables=("CLAUDE_PROJECT_DIR=${run_directory}")
  case "$4" in
    jqなし) path="$6/bin" ;;
    判定が想定外) hook="$6/harness/hooks/read-bash-command.sh" ;;
    理由を作れない) hook="$6/broken-reason/hooks/read-bash-command.sh" ;;
    プロジェクトなし) variables=() ;;
    プロジェクト=*) variables=("CLAUDE_PROJECT_DIR=$1/${4#プロジェクト=}") ;;
    環境=*) assignment="${4#環境=}" && variables+=("${assignment//@ROOT@/$1}") ;;
  esac
  input="$(printf '%b' "$5")"
  output="$(printf '%s' "${input//@CASE@/${run_directory}}" | env -u CLAUDE_CONFIG_DIR -u CLAUDE_PROJECT_DIR -u GIT_SSH_COMMAND HOME="$1" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$1" PATH="${path}" ${variables[@]+"${variables[@]}"} "${BASH}" "${hook}" 2> /dev/null)"
  status=$?
  output="$(printf '%s' "${output}" | jq -r --arg variant "$4" 'if .hookSpecificOutput.hookEventName == "PreToolUse"
    and (.hookSpecificOutput.permissionDecisionReason | length > 0)
    then .hookSpecificOutput.permissionDecision
      + (if .hookSpecificOutput.updatedInput then " " + (.hookSpecificOutput.updatedInput | tojson) else "" end)
      + (if $variant == "理由も出す" then " 理由=" + (.hookSpecificOutput.permissionDecisionReason | split("\n") | join("~")) else "" end)
    else "形の誤り" end' 2> /dev/null || printf '%s' '形の誤り')"
  record="$(find "$1/.claude/plugins/data/my-harness-pinned-command" -type f ! -name '*.txt' 2> /dev/null)"
  if [ -n "${record}" ]; then
    output="${output} 記録=$(while IFS= read -r -d '' word; do printf '[%s]' "${word}"; done < "${record}")"
    output="${output} 全文=$(cat "${record}.txt" 2> /dev/null)"
    record_name="${record##*/}" && output="${output//${record}/@RECORD@}" && output="${output//${record_name}/@NAME@}"
  fi
  # 判定の中のgitが、設定かURLのコマンドを人の確認の前に動かすと、ケースのフォルダーにmarkerができる。
  [ ! -e "$1/marker" ] || output="${output} marker=yes"
  head_id="$(git -C "${run_directory}" rev-parse HEAD 2> /dev/null)"
  output="${output//${HARNESS_PATH}/@HARNESS@}" && output="${output//$1/@ROOT@}"
  printf '%s %s\n' "${status}" "$(printf '%s' "${output//${head_id:-@SHA@}/@SHA@}" | LC_ALL=C tr '\n' '~')"
}

main() {
  local work_directory description place setting variant input expected case_number=0
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  create_variant "${work_directory}/variant"
  # 長い語は、ケースの一覧に「[文字列*数]」で書き、入力と期待する結果の両方で同じ語にする。
  while IFS=$'\t' read -r description place setting variant input expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    case_number=$((case_number + 1))
    expect "${description}" "$(print_repeated_text "${expected}")" "$(print_case_result "${work_directory}/case-${case_number}" \
      "${place}" "${setting}" "${variant}" "$(print_repeated_text "${input}")" "${work_directory}/variant")"
  done < "${TEST_DIRECTORY}/read-bash-command-case-list.tsv"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
