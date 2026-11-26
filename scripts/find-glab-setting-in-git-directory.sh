#!/bin/bash
# 作業フォルダーを受け取り、gitのフォルダー（git rev-parseの--git-dirと--git-common-dir）と、作業フォルダーの一番上の.git/に、中身のあるglabの設定のフォルダー（glab-cli/）があるかを返す。あれば、その場所を標準出力に出す。.git/glab-cli/config.ymlは、サンドボックスのReadのdenyが無いと中から書け、外で動くglabが設定として読むためである。
# 終了コードは、0があったかgitのフォルダーを決められなかった、1が無かった、2が使い方の誤りである。
# scripts/classify-remote-command.shが、通すか確認を求めるglabのコマンドで呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

main() {
  local output directory found status
  local settings=()
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'find-glab-setting-in-git-directory.sh: 作業フォルダーを1つだけ渡してください。' >&2
    exit 2
  fi
  # gitのフォルダーを決められないときは、あるとみなして、判定のスクリプトが確認を求めるようにする。
  if ! output="$(git -C "$1" rev-parse --git-dir --git-common-dir 2> /dev/null)"; then
    printf '%s\n' 'gitのフォルダーを決められませんでした'
    exit 0
  fi
  while IFS= read -r directory; do
    case "${directory}" in
      /*) ;;
      *) directory="$1/${directory}" ;;
    esac
    settings+=("${directory}/glab-cli")
  done <<< "${output}"
  settings+=("$1/.git/glab-cli")
  found="$("${BASH}" "${SCRIPT_DIRECTORY}/find-nonempty-glab-setting.sh" "${settings[@]}" 2> /dev/null)"
  status=$?
  [ "${status}" -ne 1 ] || exit 1
  # 探せなかったときも、あるとみなして、判定のスクリプトが確認を求めるようにする。
  [ "${status}" -eq 0 ] || found='glabの設定のフォルダーを確かめられませんでした'
  printf '%s\n' "${found}"
  exit 0
}

main "$@"
