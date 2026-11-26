#!/bin/bash
# 作業フォルダー、リモートの名前、問い合わせの上限の秒数、送り先のブランチ（0個以上）を受け取り、リモートの今のHEADと送り先のブランチのSHAを、「<SHA> <参照の名前>」の形で1行に1つ出す。CIの設定のファイルの比べる元を、サンドボックスの中から書き換えられないリモートの今の状態から読むためである。
# 終了コードは、0が出せた、1が問い合わせに失敗したか、上限の秒数を超えたか、URLがhttps、ssh、手元のパスのほかの方式だった（何も出さない）、2が使い方の誤りである。
# scripts/classify-git-push-commit.shが、pushを判定するたびに呼ぶ。理由は、.harness/docs/features/protection.mdの節「CIの設定のファイルを変えるpush」に書く。
set -u -o pipefail

# コマンドを裏で動かし、上限の秒数を超えたら止める。macOSにはtimeoutのコマンドが無く、フックの時間切れでは確認でなく止まるためである。
# 引数：上限の秒数、コマンドと引数
# 出力：コマンドの標準出力
# 戻り値：コマンドの戻り値（止めたときは0以外）
run_with_time_limit() {
  local seconds="$1" command_id watcher_id status
  shift
  "$@" &
  command_id=$!
  # 待つ側の出力を外すのは、残ったsleepが出力をつないだままにして、呼んだ側が待ち続けないためである。
  (sleep "${seconds}" && kill "${command_id}") > /dev/null 2>&1 &
  watcher_id=$!
  wait "${command_id}"
  status=$?
  kill "${watcher_id}" > /dev/null 2>&1
  return "${status}"
}

# URLが、問い合わせてよい方式（https、ssh、手元のパス）かを返す。gitは、最初の:より前に/が無い形をSSHのホストとパス（scpの形）として読み、ほかの形を手元のパスとして読む。
# 引数：URL
# 出力：なし
# 戻り値：問い合わせてよければ0、ほかの方式（例：ext::、http://）なら1
is_allowed_url() {
  case "$1" in
    https://* | ssh://* | file://*) return 0 ;;
    *::* | *://*) return 1 ;;
  esac
  return 0
}

main() {
  local url final_url output branch
  local patterns=(HEAD)
  if [ "$#" -lt 3 ] || [ -z "$3" ] || [ -n "${3//[0-9]/}" ]; then
    printf '%s\n' 'print-remote-head.sh: 作業フォルダー、リモートの名前、上限の秒数（数）と、送り先のブランチを渡してください。' >&2
    exit 2
  fi
  # pushと同じ場所に問い合わせるため、pushurlとpushInsteadOfを当てたURLを使う。
  if ! url="$(git -C "$1" remote get-url --push "$2" 2> /dev/null)" || [ -z "${url}" ] || [ "${url#-}" != "${url}" ]; then
    printf 'print-remote-head.sh: リモート「%s」のpushの場所を、gitの設定から求められませんでした。git remote -vでリモートを確かめてください。\n' "$2" >&2
    exit 1
  fi
  # ls-remoteは渡したURLにもurl.*.insteadOfを当てるので、当てたあとの方式で決める。URLは秘密の値を含むことがあるので、方式だけを出す。
  final_url="$(git -C "$1" ls-remote --get-url "${url}" 2> /dev/null)"
  if [ -z "${final_url}" ] || ! is_allowed_url "${final_url}"; then
    printf 'print-remote-head.sh: リモート「%s」のURLの方式（%s）は、https、ssh、手元のパスのほかなので、問い合わせません。リモートのURLとurl.*.insteadOfを確かめてください。\n' "$2" "${final_url%%:*}" >&2
    exit 1
  fi
  for branch in "${@:4}"; do
    patterns+=("refs/heads/${branch}")
  done
  # 認証の入力を待たないようにし、待つ画面が出ないときも上限の秒数で止める。
  # protocol.<名前>.allowはprotocol.allowより先に当たり、リポジトリの設定の値は-cで上書きできるので、使う3つの方式だけを-cで許す。
  export GIT_TERMINAL_PROMPT=0 GIT_PROTOCOL_FROM_USER=0
  if ! output="$(run_with_time_limit "$3" git -C "$1" -c protocol.allow=never -c protocol.https.allow=always \
    -c protocol.ssh.allow=always -c protocol.file.allow=always ls-remote "${url}" "${patterns[@]}" 2> /dev/null)"; then
    printf 'print-remote-head.sh: リモート「%s」に、%s秒のうちに問い合わせられませんでした。通信と認証を確かめてください。\n' "$2" "$3" >&2
    exit 1
  fi
  # ls-remoteのパターンは名前の後ろで合うものも出すので、渡した名前と同じ参照だけを出す。
  printf '%s\n' "${output}" | LC_ALL=C awk -F '\t' -v names="${patterns[*]}" '
    BEGIN { split(names, list, " "); for (i in list) wanted[list[i]] = 1 }
    ($2 in wanted) { print $1 " " $2 }'
  exit 0
}

main "$@"
