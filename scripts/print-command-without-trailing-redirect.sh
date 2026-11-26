#!/bin/bash
# コマンドの文字列を受け取り、文字列の全体の最後にある、前の語と空白で分かれた2>&1（前後の空白を含む）だけを外して、標準出力に出す。判定、フックの記録、書き換えたコマンドの3か所が、同じ語を外に出す形として扱い、本文の途中の行末の2>&1を語の一部のまま残すためである。
# 終了コードは、0が出した、2が使い方の誤りである。
# scripts/classify-remote-command.sh、hooks/write-pinned-command-record.sh、hooks/read-bash-command.shが呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

main() {
  local command trimmed
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-command-without-trailing-redirect.sh: コマンドの文字列を1つ渡してください。' >&2
    exit 2
  fi
  command="$1"
  # 行ごとに当たるsedの「$」は、引用符の中の本文の途中の行末にも当たるので、文字列の全体の最後だけを見る。
  trimmed="${command%"${command##*[![:space:]]}"}"
  case "${trimmed}" in
    *[[:space:]]'2>&1') ;;
    *) printf '%s' "${command}" && exit 0 ;;
  esac
  trimmed="${trimmed%'2>&1'}"
  printf '%s' "${trimmed%"${trimmed##*[![:space:]]}"}"
  exit 0
}

main "$@"
