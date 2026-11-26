#!/bin/bash
# gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、動かすコマンドの最初の語を受け取り、環境変数でgitのフォルダーを固定しても外のgitとglabが読み書きする場所のうち、書き換えられたものを探す。見つけたら、その説明を標準出力に出す。判定のあとにサンドボックスの中から書き換えた場所を、外のコマンドに使わせないためである。
# 終了コードは、0が見つけた、1が見つからない、2が使い方の誤りである。
# hooks/exec-with-pinned-git-directory.shが、外のコマンドを動かす直前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

main() {
  local directory link setting status
  if [ "$#" -ne 4 ]; then
    printf '%s\n' 'find-unpinned-git-path.sh: gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、コマンドの最初の語の4つを渡してください。' >&2
    exit 2
  fi
  # 参照は、GIT_COMMON_DIRがあっても、commondirのファイルの指す場所から読み書きする。ファイルでないもの（例：FIFO）は、読む前に外す。
  if [ "$1" = "$2" ]; then
    if [ -e "$1/commondir" ] || [ -L "$1/commondir" ]; then
      printf '%s/commondirがあります\n' "$1" && exit 0
    fi
  elif [ -L "$1/commondir" ] || [ ! -f "$1/commondir" ] \
    || [ "$(cd "$1" && cd "$(cat commondir)" && pwd -P)" != "$2" ]; then
    printf '%s/commondirが、%sを指していません\n' "$1" "$2" && exit 0
  fi
  # gitのフォルダーの中をリンクにすると、外のgitが、リンクの先（作業フォルダーの外）にファイルを書く（例：FETCH_HEAD、refs/、objects/pack）。
  # FETCH_HEADとlogs/は置き換えずに開いて書くので、ハードリンクも探す。objects/は、git clone --localがハードリンクを作り、gitが置き換えで書くので外す。
  # hooks/（サブモジュールのものも）は、gitが書かず、人がリンクのフックを置くことがあるので外す。判定のあとにリンクの先を書き換えてフックを動かす形は、判定のgitの設定の確認が、フックのリンクとハードリンクと、フックのフォルダーのリンクを見つけて確認を求める。
  for directory in "$1" "$2"; do
    link="$(find "${directory}" \( -path "${directory}/hooks" -o -path "${directory}/modules/*/hooks" \) -prune \
      -o -type l -print 2> /dev/null | head -n 1)"
    if [ -n "${link}" ]; then
      printf '%sがシンボリックリンクです\n' "${link}" && exit 0
    fi
    link="$(find "${directory}" \( -path "${directory}/objects" -o -path "${directory}/modules/*/objects" \
      -o -path "${directory}/hooks" -o -path "${directory}/modules/*/hooks" \) -prune \
      -o -type f -links +1 -print 2> /dev/null | head -n 1)"
    if [ -n "${link}" ]; then
      printf '%sが、ほかの名前とつながったファイル（ハードリンク）です\n' "${link}" && exit 0
    fi
  done
  # 外のglabは、gitのフォルダーと今のフォルダーの.gitにあるglab-cli/の設定を読む。サンドボックスが置く空のglab-cli/は、設定にならないので外す。
  [ "$4" = 'glab' ] || exit 1
  setting="$("${BASH}" "${SCRIPT_DIRECTORY}/find-nonempty-glab-setting.sh" \
    "$1/glab-cli" "$2/glab-cli" "$3/.git/glab-cli" "${PWD}/.git/glab-cli" 2> /dev/null)"
  status=$?
  [ "${status}" -ne 1 ] || exit 1
  # 探せなかったときも、見つけたとみなして、外で動かすスクリプトが動かさないようにする。
  [ "${status}" -eq 0 ] || setting='glabの設定のフォルダー（確かめられなかった）'
  printf '%sがあります\n' "${setting}" && exit 0
}

main "$@"
