#!/bin/bash
# Claude CodeのPreToolUseのフックのJSONを標準入力で受け取り、判定のJSON（permissionDecision）を標準出力に出す。git push、git fetch、git pull、gh、glabのコマンドを、判定のスクリプトのとおりに、通すか、確認を求めるか、止めるためである。git push、git fetch、glab、確認を求めるghは、判定で求めたgitのフォルダーに固定して外で動かすスクリプト（hooks/exec-with-pinned-git-directory.sh）と、判定した語を書いたフックの記録の名前だけの呼び出しにした入力（updatedInput）で動かし、動かす語を理由の文に出す。
# 終了コードは、いつも0である。onFailure: "block"では、0と2以外の終了コードが失敗に数えられ、出したJSONも使われないためである（Hooks referenceの節「Block the action when a hook fails」）。
# Claude CodeのPreToolUseのフック（hooks/hooks.json）が、これらのコマンドと、外で動かすスクリプトの呼び出しを動かす前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「フック」に書く。
set -u -o pipefail

# ハーネスの場所は、このスクリプトの場所から求める（.harness/docs/architecture.mdの節「配置の理由」）。
HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly HARNESS_ROOT
readonly PINNED_SCRIPT="${HARNESS_ROOT}/hooks/exec-with-pinned-git-directory.sh"
# jqが無いときにも出せるように、確認を求めるJSONと、外で動かすスクリプトを直接呼ぶ形を止めるJSONを、決まった文字列で持つ。
readonly ASK_WITHOUT_JQ='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"my.harness: jqが無いか、判定のJSONを作れないので、判定できません。"}}'
readonly DENY_DIRECT_CALL='{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"my.harness: hooks/exec-with-pinned-git-directory.shは、フックが書き換えた呼び出しだけが使います。直接呼ばずに、もとのコマンド（例：git push origin feat/x:feat/x）を動かしてください。"}}'

# 判定のJSONを出す。書き換えた入力があれば、updatedInputに入れる。jqでJSONを作れなければ、確認を求めるJSONを出す。
# 引数：判定（allow、ask、deny）、理由の文、書き換えた入力のJSON（任意、無ければnull）
# 出力：判定のJSONの1行
# 戻り値：0
print_decision() {
  if ! jq -n -c --arg decision "$1" --arg reason "my.harness: $2" --argjson updated "${3:-null}" \
    '{hookSpecificOutput: ({hookEventName: "PreToolUse", permissionDecision: $decision, permissionDecisionReason: $reason}
      + (if $updated == null then {} else {updatedInput: $updated} end))}' \
    2> /dev/null; then
    printf '%s\n' "${ASK_WITHOUT_JQ}"
  fi
}

main() {
  local input command directory output decision reason git_directory common_directory work_tree recurse pinned_command
  local path name pinned_input redirect='' updated_input=''
  input="$(cat)"
  # jqが無ければ語に分けられないので、入力の全体にスクリプトの名前があれば、本文の中だけでも止める。
  if ! command -v jq > /dev/null 2>&1; then
    case "${input}" in *"${PINNED_SCRIPT##*/}"*) printf '%s\n' "${DENY_DIRECT_CALL}" && exit 0 ;; esac
    printf '%s\n' "${ASK_WITHOUT_JQ}"
    exit 0
  fi
  if ! command="$(printf '%s' "${input}" | jq -e -r '.tool_input.command | strings' 2> /dev/null)" \
    || ! directory="$(printf '%s' "${input}" | jq -e -r '.cwd | strings' 2> /dev/null)"; then
    print_decision ask 'フックの入力のJSONから、コマンドと作業フォルダーを読めませんでした。'
    exit 0
  fi
  # 直接の呼び出しは、スクリプトを指す語（名前か/名前で終わる、空白の無い語）で見る。本文の中の名前は、語に空白が入るので当たらない。語に分けられないコマンドは、判定のスクリプトが止める。
  while IFS= read -r -d '' path; do
    case "${path}" in
      *[[:space:]]*) ;;
      "${PINNED_SCRIPT##*/}" | */"${PINNED_SCRIPT##*/}") printf '%s\n' "${DENY_DIRECT_CALL}" && exit 0 ;;
    esac
  done < <("${BASH}" "${HARNESS_ROOT}/scripts/print-command-word.sh" "${command}" 2> /dev/null)
  output="$("${BASH}" "${HARNESS_ROOT}/scripts/classify-remote-command.sh" "${directory}" "${command}" 2> /dev/null)"
  { IFS= read -r decision; IFS= read -r reason; IFS= read -r git_directory; IFS= read -r common_directory
    IFS= read -r work_tree; IFS= read -r recurse; IFS= read -r pinned_command; } <<< "${output}"
  case "${decision}" in
    allow) reason='判定のスクリプトが、簡単な形として通しました。' ;;
    ask | deny) ;;
    *) decision='ask' && reason='判定のスクリプトが、決まった判定を返しませんでした。' && recurse='' ;;
  esac
  # 6行目がある判定は、判定のあとに.git/commondirのようなファイルを書き換えられても外のコマンドが使わないよう、gitのフォルダーを固定するスクリプトの呼び出しにする。
  if [ -n "${recurse}" ] && [ "${decision}" != 'deny' ]; then
    for path in "${git_directory}" "${common_directory}" "${work_tree}"; do
      case "${path}" in /*) ;; *) decision='deny' && reason='判定のスクリプトが、gitのフォルダーを絶対パスで返しませんでした。' ;; esac
    done
    # 判定のスクリプトと同じく末尾の2>&1だけを外に出す形として許し、書き換えたコマンドにも残す。
    [ "$("${BASH}" "${HARNESS_ROOT}/scripts/print-command-without-trailing-redirect.sh" "${command}")" = "${command}" ] || redirect=' 2>&1'
    # Bashのマッチャーのフックの書き換えは、Monitorのツールのコマンドに当たらない（Hooks referenceの節「Match Monitor commands」）。
    if [ "${decision}" = 'deny' ]; then
      :
    elif [ "$(printf '%s' "${input}" | jq -r '.tool_name // ""' 2> /dev/null)" != 'Bash' ]; then
      decision='deny' && reason='Bashのほかのツール（例：Monitor）で動かしたgit push、git fetch、glab、ghは、gitのフォルダーを固定するスクリプトの呼び出しに書き換えられないので止めます。Bashのツールで動かしてください。'
    # 書き換えたコマンドは、Claude Codeが区切れない語（例：バッククォート、$(）を含まないよう、スクリプトと記録の名前だけにし、動かす語は理由の文で人に示す。
    elif ! name="$("${BASH}" "${HARNESS_ROOT}/hooks/write-pinned-command-record.sh" "${git_directory}" "${common_directory}" "${work_tree}" "${recurse}" "${pinned_command:-${command}}" 2> /dev/null)" \
      || ! reason="$("${BASH}" "${HARNESS_ROOT}/hooks/print-pinned-command-reason.sh" "${reason}gitのフォルダーを判定で求めた場所に固定するスクリプトの呼び出しに書き換えました。${pinned_command:+送り元は、判定で確かめたcommitのSHAにしました。}" "${name}" 2> /dev/null)" \
      || ! pinned_input="bash $("${BASH}" "${HARNESS_ROOT}/scripts/print-quoted-word.sh" "${PINNED_SCRIPT}") ${name}${redirect}" \
      || ! updated_input="$(printf '%s' "${input}" | jq -c --arg command "${pinned_input}" '.tool_input + {command: $command}' 2> /dev/null)"; then
      decision='ask' && reason='gitのフォルダーを固定するスクリプトの呼び出しと、その記録を作れなかったので、固定せずに確認を求めます。' && updated_input=''
    fi
  fi
  print_decision "${decision}" "${reason}" "${updated_input}"
  exit 0
}

main "$@"
