#!/bin/bash
# フックの記録の名前を受け取り、その記録のファイルのパスを標準出力に出す。名前を渡さなければ、記録を置くフォルダーを出す。フックが書く記録と、外で動かすスクリプトが探す記録を、同じ場所にするためである。
# 終了コードは、0が出した、2が使い方の誤り（名前が英数字だけでないか、引数が2つ以上）である。
# hooks/write-pinned-command-record.shが記録を書く前に、hooks/exec-with-pinned-git-directory.shとhooks/print-pinned-command-reason.shが記録を読む前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail
# 名前の文字の範囲を、ロケールに依らずASCIIの英数字にするためである。
export LC_ALL=C

main() {
  local directory
  # 場所は、サンドボックスの中から書けないClaude Codeの設定のフォルダーの下にする。プラグインのデータのフォルダーの名前は入れ方で変わるので、CLAUDE_PLUGIN_DATAを使わない。
  directory="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/plugins/data/my-harness-pinned-command"
  if [ "$#" -eq 0 ]; then
    printf '%s\n' "${directory}"
    exit 0
  fi
  # 名前は、書き換えたコマンドにそのまま書くので、Claude Codeが区切れない記号とパスの区切りを含まない英数字だけにする。
  if [ "$#" -ne 1 ] || case "$1" in '' | *[!A-Za-z0-9]*) true ;; *) false ;; esac; then
    printf 'print-pinned-command-record-path.sh: フックの記録の名前（%s）が、英数字だけの1つの名前ではありません。フックが書き換えたコマンドのまま動かしてください。\n' "$*" >&2
    exit 2
  fi
  printf '%s/%s\n' "${directory}" "$1"
  exit 0
}

main "$@"
