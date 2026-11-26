#!/bin/bash
# フックの書き換えから本物のgitまでをつないで動かし、結果を出す関数を持つ。判定のあとにgitのフォルダーを書き換えても、外のコマンドがエージェントの書いた設定とフックを使わないことを、一時のリポジトリで確かめるためである。
# 終了コードは持たない。関数の戻り値は、関数のコメントに書く。
# tests/test-exec-with-pinned-git-directory.shが、tests/create-case-repository.shのあとにsourceする。

# 1つのケースの導入先を作ってフックを動かし、判定のあとのコマンドを動かしてから、フックが書き換えたコマンドを本物のgitで動かして、結果を出す。書き換えたコマンドは、PATHの先頭にケースのフォルダーのbin/（準備のコマンドが偽のコマンドを置く場所）を足して動かす。
# 引数：ハーネスの場所、ケースのフォルダー、場所、準備のコマンド、エージェントのコマンド、判定のあとに動かすコマンド（「-」は動かさない）、確かめるコマンド
# 出力：「判定 終了コード marker=yes|no 確かめるコマンドの出力」の1行。書き換えた入力が無ければ終了コードを「-」にし、作れなければ「作れなかった」
# 戻り値：0
print_hook_flow_result() {
  local run_directory output decision command status='-' marker='no'
  mkdir -p "$2"
  if ! run_directory="$(create_case_repository "$2" "$3")" \
    || ! (cd "${run_directory}" && HOME="$2" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$4") > /dev/null 2>&1; then
    printf '%s\n' '作れなかった' && return 0
  fi
  output="$(jq -n -c --arg command "$5" --arg cwd "${run_directory}" '{tool_name: "Bash", tool_input: {command: $command}, cwd: $cwd}' \
    | env -u CLAUDE_CONFIG_DIR HOME="$2" GIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES="$2" CLAUDE_PROJECT_DIR="${run_directory}" \
      "${BASH}" "$1/hooks/read-bash-command.sh" 2> /dev/null)"
  decision="$(printf '%s' "${output}" | jq -r '.hookSpecificOutput.permissionDecision' 2> /dev/null)"
  command="$(printf '%s' "${output}" | jq -r '.hookSpecificOutput.updatedInput.command // ""' 2> /dev/null)"
  [ "$6" = '-' ] || (cd "${run_directory}" && HOME="$2" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$6") > /dev/null 2>&1
  if [ -n "${command}" ]; then
    (cd "${run_directory}" && env -u CLAUDE_CONFIG_DIR HOME="$2" GIT_CONFIG_NOSYSTEM=1 PATH="$2/bin:${PATH}" "${BASH}" -c "${command}") > /dev/null 2>&1
    status=$?
  fi
  [ ! -e "$2/marker" ] || marker='yes'
  printf '%s %s marker=%s %s\n' "${decision}" "${status}" "${marker}" "$(cd "${run_directory}" && HOME="$2" "${BASH}" -c "$7" 2> /dev/null)"
}
