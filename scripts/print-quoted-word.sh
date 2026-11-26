#!/bin/bash
# 語を受け取り、シェルが1つの語として読む形にして、空白でつないだ1行を標準出力に出す。英数字と決まった記号のほかを含む語は、'で囲む。書き換えたコマンドを、もとの語のまま動かすためと、動かす語を人に示すためである。
# 終了コードは、0が出した、2が使い方の誤りである。
# scripts/classify-git-push-commit.shとhooks/read-bash-command.shが書き換えたコマンドを組み立てるときに、hooks/write-pinned-command-record.shが全文のファイルを書くときに、hooks/print-pinned-command-reason.shが確認の画面の理由の文を作るときに呼ぶ。
set -u -o pipefail

main() {
  local word body separator='' newline=$'\n'
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'print-quoted-word.sh: 囲む語を1つ以上渡してください。' >&2
    exit 2
  fi
  for word in "$@"; do
    case "${word}" in
      '' | *[!A-Za-z0-9._/:+@=,-]*)
        # $(...)は最後の改行を消すので、最後の改行を外してから'を置き換え、外した改行を後ろに戻す。
        # 'は'\''でなく'"'"'にする。scripts/print-command-word.shは引用符の外の\を分けない形として止めるので、記録を書くときに語に分け直せないためである。
        body="${word%"${word##*[!"${newline}"]}"}"
        printf "%s'%s%s'" "${separator}" "$(printf '%s' "${body}" | sed "s/'/'\"'\"'/g")" "${word#"${body}"}"
        ;;
      *) printf '%s%s' "${separator}" "${word}" ;;
    esac
    separator=' '
  done
  printf '\n'
  exit 0
}

main "$@"
