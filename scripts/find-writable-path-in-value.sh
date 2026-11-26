#!/bin/bash
# 引数を5つ受け取り、値がサンドボックスの中から書ける場所を指すかを、終了コードで返す。引数は、作業フォルダーの一番上、worktreeで共有する.gitの場所、相対パスを読む基のフォルダー、値の種類（path、url、command、program）、gitの設定の値である。サンドボックスの外で動くgitが、エージェントの書いたファイルを動かすか読む設定を見つけるためである。
# 終了コードは、0が指さない、1が指す、2が使い方の誤りである。
# scripts/find-git-setting-in-working-tree.shが、探すgitの設定の値ごとに呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitの設定の確認」に書く。
set -u -o pipefail

toplevel=''
common_directory=''
base_directory=''

# パスが、作業フォルダーか共有する.gitの中を指すかを返す。..を含むパスは、指すとみなす。
# 引数：パス
# 出力：なし
# 戻り値：指すなら0、指さなければ1
is_writable_path() {
  local path="$1"
  case "${path}" in
    \~/*) path="${HOME}/${path#\~/}" ;;
    /*) ;;
    *) path="${base_directory}/${path}" ;;
  esac
  case "${path}/" in
    */../* | "${toplevel}/"* | "${common_directory}/"*) return 0 ;;
  esac
  return 1
}

# URLの形の値が手元のパスなら、そのパスが書ける場所を指すかを返す。
# 引数：URLかパス
# 出力：なし
# 戻り値：指すなら0、指さなければ1
is_writable_url() {
  case "$1" in
    file://*) is_writable_path "${1#file://}" ;;
    *://*) return 1 ;;
    # gitは、最初の:より前に/が無い形を、SSHのホストとパスとして読む。
    [!/]*:*) case "${1%%:*}" in */*) is_writable_path "$1" ;; *) return 1 ;; esac ;;
    *) is_writable_path "$1" ;;
  esac
}

# プログラムのパスかコマンドの1つの語が、書ける場所を指すかを返す。/を含むか.か~で始まる語はパスとして読み、ほかの語は作業フォルダーの一番上にあるときだけ指すとみなす。
# 引数：語
# 出力：なし
# 戻り値：指すなら0、指さなければ1
is_writable_word() {
  case "$1" in
    '') return 1 ;;
    */* | .* | \~*) is_writable_path "$1" ;;
    *) [ -e "${toplevel}/$1" ] ;;
  esac
}

# シェルで動かすコマンドの形の値について、その語のどれかが書ける場所を指すかを返す。語は、引用符と\を読むxargsで分ける（例：/mnt/c/Program\ Files/xは1つの語）。分けられなければ（例：閉じていない引用符）、指すとみなす。
# 引数：コマンドの文字列
# 出力：なし
# 戻り値：指すなら0、指さなければ1
has_writable_word() {
  local word words argument=0
  words="$(printf '%s\n' "$1" | xargs printf '%s\n' 2> /dev/null)" || return 0
  while IFS= read -r word; do
    # 展開とシェルの記号は、シェルか、受け取ったプログラム（例：sh -c、sshのProxyCommand）が読む。中身を判定できないので、指すとみなす。1つ目の語の空白と括弧は、パスの一部として読む（例：Program Files (x86)）。
    case "${argument}${word}" in
      *[\$\`]* | 0*[\;\|\&\<\>\*\?\[\{\'\"\\]* | 1*[[:space:]\;\|\&\<\>\(\)\*\?\[\{\'\"\\]*) return 0 ;;
    esac
    # credential.helperの!を外す。オプションは=か2文字目のあとの値を見る（例：--file=./x、-F./x）。=を含むほかの語（例：BASH_ENV=./x）は、=のあとの値と語の全体の両方を見る。
    word="${word#!}" && argument=1
    case "${word}" in
      -?*=*) word="${word#*=}" ;;
      -[!-]?*) word="${word:2}" ;;
      -*) continue ;;
      *=*) is_writable_word "${word#*=}" && return 0 ;;
    esac
    is_writable_word "${word}" && return 0
  done <<< "${words}"
  return 1
}

main() {
  if [ "$#" -ne 5 ]; then
    printf '%s\n' 'find-writable-path-in-value.sh: 作業フォルダーの一番上、共有する.gitの場所、基のフォルダー、値の種類、値の5つを渡してください。' >&2
    exit 2
  fi
  toplevel="$1" && common_directory="$2" && base_directory="$3"
  case "$4" in
    path) is_writable_path "$5" ;;
    url) is_writable_url "$5" ;;
    command) has_writable_word "$5" ;;
    program) is_writable_word "$5" ;;
    *)
      printf 'find-writable-path-in-value.sh: 値の種類は、path、url、command、programのどれかにしてください（%s）。\n' "$4" >&2
      exit 2
      ;;
  esac
  # 判定の関数は指すときに0を返すので、指すなら1、指さなければ0で終える。
  exit "$(($? == 0))"
}

main "$@"
