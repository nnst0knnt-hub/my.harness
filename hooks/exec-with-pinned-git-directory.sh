#!/bin/bash
# フックの記録の名前を受け取り、記録から、gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、サブモジュールに入るか（recurseかno-recurse）、動かすコマンドの語を読んで、gitのフォルダーを環境変数で固定してコマンドを動かす。フックが判定した語だけを動かし、判定のあとにサンドボックスの中から.git/commondirのようなファイルを作っても、外で動くgit push、git fetch、glab、ghが、エージェントの書いた設定とフックを使わないためである。
# 終了コードは、動かしたコマンドの終了コードである。動かさなかったときは、1（記録が無いか古い、gitのフォルダーが書き換えられていた、書き換えられたかを確かめられなかった、GIT_CONFIG_COUNTが数でない）か、2（名前か記録の中身の形の誤り）である。
# hooks/read-bash-command.shが、git push、git fetch、glab、確認を求めるghを、このスクリプトの呼び出しに書き換える。直接は呼ばない。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

HOOK_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly HOOK_DIRECTORY
# 人が確認の画面を読む時間を見込んだ値で、根拠の資料は無い。
readonly RECORD_LIFETIME_MINUTES=10
readonly RECORD_ERROR_HINT='フックの記録を書くハーネスのhooks/write-pinned-command-record.shを確かめてください。'
words=()

# 理由の文を標準エラーに出し、コマンドを動かさずに終わる。
# 引数：終了コード、理由の文
# 出力：標準エラーに1行
# 戻り値：なし（exitする）
exit_without_running() {
  printf 'exec-with-pinned-git-directory.sh: %s\n' "$2" >&2
  exit "$1"
}

# フックが書いた記録を取り出して、NULで区切った語をwordsに読み、記録と全文のファイルを消す。先にmvで取り出すのは、同じ記録を2回使わないためである。
# 引数：記録のパス
# 出力：なし（wordsを書く）
# 戻り値：使える記録があれば0、無ければ1、古ければ2
take_record_word() {
  local taken="$1.taken.$$" fresh word
  mv "$1" "${taken}" 2> /dev/null || return 1
  fresh="$(find "${taken}" -mmin "-${RECORD_LIFETIME_MINUTES}" 2> /dev/null)"
  while IFS= read -r -d '' word; do
    words+=("${word}")
  done < "${taken}"
  rm -f "${taken}" "$1.txt"
  [ -n "${fresh}" ] || return 2
}

main() {
  local record path status reason count pair
  if [ "$#" -ne 1 ] || ! record="$("${BASH}" "${HOOK_DIRECTORY}/print-pinned-command-record-path.sh" "$1" 2> /dev/null)"; then
    exit_without_running 2 "フックの記録の名前（英数字）を1つだけ渡してください（$*）。このスクリプトは直接呼ばず、もとのコマンド（例：git push origin feat/x:feat/x）を動かしてください。"
  fi
  take_record_word "${record}"
  status=$?
  [ "${status}" -ne 2 ] || exit_without_running 1 "フックが書いた記録が${RECORD_LIFETIME_MINUTES}分より古いので、動かしません。もとのコマンドを、もう一度動かしてください。"
  [ "${status}" -eq 0 ] || exit_without_running 1 'フックが書いた記録が無いので、動かしません。このスクリプトは直接呼ばず、もとのコマンド（例：git push origin feat/x:feat/x）を動かしてください。'
  # 空の配列をset -uのもとで展開しないように、要素の数を先に見る。
  [ "${#words[@]}" -ge 5 ] || exit_without_running 2 "フックの記録に、gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、recurseかno-recurse、動かすコマンドがそろっていません。${RECORD_ERROR_HINT}"
  set -- "${words[@]}"
  case "$5 ${6:-}" in
    'git push' | 'git fetch' | glab\ * | gh\ *) ;;
    *) exit_without_running 2 "動かせるのは、git push、git fetch、glab、ghだけです（$5 ${6:-}）。${RECORD_ERROR_HINT}" ;;
  esac
  case "$4" in
    recurse | no-recurse) ;;
    *) exit_without_running 2 "フックの記録の4つ目が、recurseかno-recurseではありません（$4）。${RECORD_ERROR_HINT}" ;;
  esac
  for path in "$1" "$2" "$3"; do
    case "${path}" in /*) ;; *) exit_without_running 2 "フックの記録のgitのフォルダーか作業フォルダーが、絶対パスではありません（${path}）。${RECORD_ERROR_HINT}" ;; esac
  done
  # 環境変数で固定しても外のgitとglabが読み書きする場所が、判定のあとに書き換えられていれば動かさない。探せなかったときも動かさない。
  reason="$("${BASH}" "${HOOK_DIRECTORY}/../scripts/find-unpinned-git-path.sh" "$1" "$2" "$3" "$5" 2> /dev/null)"
  status=$?
  [ "${status}" -ne 0 ] || exit_without_running 1 "判定のあとに、gitのフォルダーが書き換えられたので動かしません（${reason}）。サンドボックスの中のコマンドが書き換えたことがあるので、人に知らせてください。"
  [ "${status}" -eq 1 ] || exit_without_running 1 'gitのフォルダーが書き換えられたかを確かめられなかったので、動かしません。ハーネスのscripts/find-unpinned-git-path.shを確かめてください。'
  export GIT_DIR="$1" GIT_COMMON_DIR="$2" GIT_WORK_TREE="$3" GIT_NO_LAZY_FETCH=1
  # サブモジュールの設定は環境変数で固定できないので、判定のときに.git/modulesが無ければ入らない。GIT_CONFIG_COUNTの値は、-cと同じく、リポジトリの設定より先に当たる。
  if [ "$4" = 'no-recurse' ]; then
    count="${GIT_CONFIG_COUNT:-0}"
    case "${count}" in '' | *[!0-9]*) exit_without_running 1 "GIT_CONFIG_COUNTが数ではないので、動かしません（${count}）。" ;; esac
    count=$((10#${count}))
    for pair in fetch.recurseSubmodules=false push.recurseSubmodules=no submodule.recurse=false; do
      export "GIT_CONFIG_KEY_${count}=${pair%%=*}" "GIT_CONFIG_VALUE_${count}=${pair#*=}"
      count=$((count + 1))
    done
    export GIT_CONFIG_COUNT="${count}"
  fi
  shift 4
  exec "$@"
}

main "$@"
