#!/bin/bash
# glabの設定のフォルダー（glab-cli）のパスを1つ以上受け取り、中身のあるものを探して、見つけた最初のパスを標準出力に出す。サンドボックスはReadのdenyのために空のglab-cli/を置くので、空のものを設定とみなすと、すべてのglabで確認が出て、外で動かすスクリプトもglabを動かさないためである。
# 終了コードは、0が見つけた、1が見つからない、2が使い方の誤りである。
# scripts/find-glab-setting-in-git-directory.shとscripts/find-unpinned-git-path.shが呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail

# 1つのパスが、中身のあるglabの設定かを返す。中身のあるものは、シンボリックリンク、項目があるか中を読めないフォルダー、空でないファイル、ほかの種類（例：FIFO）である。空のフォルダー、空のファイル、文字デバイス（サンドボックスの中から見た/dev/null）は、glabが.git/glab-cli/config.ymlとして読めないので、外す。
# 引数：パス
# 出力：なし
# 戻り値：中身があれば0、無いか空なら1
is_nonempty_glab_setting() {
  local entries
  [ -L "$1" ] && return 0
  [ -e "$1" ] || return 1
  if [ -d "$1" ]; then
    entries="$(ls -A "$1" 2> /dev/null)" || return 0
    [ -n "${entries}" ]
    return
  fi
  [ -c "$1" ] && return 1
  [ -f "$1" ] && [ ! -s "$1" ] && return 1
  return 0
}

main() {
  local setting
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-nonempty-glab-setting.sh: glab-cliのパスを1つ以上渡してください。' >&2
    exit 2
  fi
  for setting in "$@"; do
    if is_nonempty_glab_setting "${setting}"; then
      printf '%s\n' "${setting}"
      exit 0
    fi
  done
  exit 1
}

main "$@"
