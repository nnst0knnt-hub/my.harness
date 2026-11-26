#!/bin/bash
# 渡したシェルのスクリプトのうち、実行の権限が無いものを探し、パスを標準エラーに出す。ルールとスキルが直接動かすよう書いたスクリプトが、Permission deniedで止まらないようにするためである。
# 終了コードは、0が権限の無いファイルなし、1が権限の無いファイルあり、2が使い方の誤りである。
# tests/run-test-suite.shが、.shのファイルを、まだ追加していないものも含めて渡して呼ぶ。
set -u -o pipefail

main() {
  local file status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-non-executable-script.sh: ファイルが渡されていません。確かめるシェルのスクリプトを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ]; then
      printf 'find-non-executable-script.sh: ファイル「%s」が見つかりません。パスを確かめてください。\n' "${file}" >&2
      exit 2
    fi
    # 作業フォルダーのファイルの権限を見る。CIは、gitが100755で記録したファイルにだけ権限を付けて取り出すので、git add --chmod=+xで記録していないものはCIで止まる。
    if [ ! -x "${file}" ]; then
      printf '%s: 実行の権限がありません。chmod +xで付けてから、git add --chmod=+xでgitに100755で記録してください。\n' "${file}" >&2
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
