#!/bin/bash
# gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、recurseかno-recurse、外で動かすコマンドの文字列を受け取り、場所と語の並びをフックの記録に書き、動かす語を囲んだ1行を全文のファイル（<名前>.txt）に書いて、記録の名前を標準出力に出す。外で動かすスクリプトが、フックが判定した語だけを、Claude Codeが外に出せる短い呼び出しで動かすためである。
# 終了コードは、0が書いた、1が書けなかった、2が使い方の誤りである。
# hooks/read-bash-command.shが、コマンドを外で動かすスクリプトの呼び出しに書き換えるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

HOOK_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly HOOK_DIRECTORY
# 外で動かすスクリプトが使わない古さ（hooks/exec-with-pinned-git-directory.shのRECORD_LIFETIME_MINUTES）を過ぎた記録を消す。
readonly RECORD_LIFETIME_MINUTES=10

main() {
  local word directory command quoted record=''
  local arguments=()
  if [ "$#" -ne 5 ]; then
    printf '%s\n' 'write-pinned-command-record.sh: 3つの場所、recurseかno-recurse、外で動かすコマンドの文字列の5つを渡してください。' >&2
    exit 2
  fi
  arguments=("$1" "$2" "$3" "$4")
  # シェルが渡す引数と同じ並びにするため、判定のスクリプト（scripts/classify-remote-command.sh）と同じく末尾の2>&1を外し、同じスクリプトで語に分ける。
  command="$("${BASH}" "${HOOK_DIRECTORY}/../scripts/print-command-without-trailing-redirect.sh" "$5")"
  while IFS= read -r -d '' word; do
    arguments+=("${word}")
  done < <("${BASH}" "${HOOK_DIRECTORY}/../scripts/print-command-word.sh" "${command}" 2> /dev/null)
  if [ "${#arguments[@]}" -le 4 ] \
    || ! directory="$("${BASH}" "${HOOK_DIRECTORY}/print-pinned-command-record-path.sh")" \
    || ! mkdir -p "${directory}"; then
    printf '%s\n' 'write-pinned-command-record.sh: 記録の場所を作れないか、コマンドを語に分けられませんでした。Claude Codeの設定のフォルダーの権限を確かめてください。' >&2
    exit 1
  fi
  find "${directory}" -type f -mmin "+${RECORD_LIFETIME_MINUTES}" -exec rm -f {} + 2> /dev/null
  # 名前は、mktempで予想できない英数字にする。外で動かすスクリプトが名前を受け取るのは、フックが書き終えて名前を出したあとなので、途中まで書いた記録は読まれない。
  if ! record="$(mktemp "${directory}/XXXXXXXXXXXXXXXX")" \
    || ! printf '%s\0' "${arguments[@]}" > "${record}" \
    || ! quoted="$("${BASH}" "${HOOK_DIRECTORY}/../scripts/print-quoted-word.sh" "${arguments[@]:4}")" \
    || ! printf '%s\n' "${quoted}" > "${record}.txt"; then
    [ -z "${record}" ] || rm -f "${record}" "${record}.txt"
    printf 'write-pinned-command-record.sh: %sに記録を書けませんでした。Claude Codeの設定のフォルダーの権限を確かめてください。\n' "${directory}" >&2
    exit 1
  fi
  printf '%s\n' "${record##*/}"
  exit 0
}

main "$@"
