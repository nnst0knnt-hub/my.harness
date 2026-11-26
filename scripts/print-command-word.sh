#!/bin/bash
# コマンドの文字列を受け取り、シェルと同じく引用符を外した引数を、1つずつNULで終えて標準出力に出す。区切りか展開のある形は分けず、理由を標準エラーに出す。判定のスクリプトが、シェルが渡すのと同じ引数で判定するためである。
# 終了コードは、0が分けられた、1が分けられない形（引用符の外の区切りか展開の記号、二重引用符の中の展開か\、閉じていない引用符）だった、2が使い方の誤りである。
# scripts/classify-remote-command.shが、コマンドを判定する前に呼ぶ。hooks/read-bash-command.shが外で動かすスクリプトの直接の呼び出しを探すときと、hooks/write-pinned-command-record.shが動かす語を記録に書くときにも呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail
# 1バイトずつ比べる。区切りと展開の記号はどれもASCIIなので、分ける所は変わらない。
export LC_ALL=C

# 引用符の外で、文字の並びを止める字（空白、引用符、区切りと展開の記号、改行、復帰）のパターンである。
readonly UNQUOTED_STOP=$'[]\'"[:space:];&|<>()$`\\\\{}*?~#![]'
# 二重引用符の中で、文字の並びを止める字のパターンである。
readonly DOUBLE_QUOTED_STOP='["$`\\]'

words=()
unsafe_reason=''

# コマンドの文字列を、引用符を外した引数に分けて、wordsに入れる。引用符の中は次の引用符まで、引用符の外は止める字の前までを1回でまとめて取る。1字ずつ足すと、長い本文で長さの2乗の時間がかかるためである。
# 引数：コマンドの文字列
# 出力：なし（wordsと、分けられないときはunsafe_reasonを書く）
# 戻り値：分けられたら0、分けられない形なら1
split_command_word() {
  local rest="$1" chunk character word='' has_word=0
  while [ -n "${rest}" ]; do
    # 止める字の一覧は、パターンとして当てるので、引用符で囲まない。
    # shellcheck disable=SC2295
    chunk="${rest%%${UNQUOTED_STOP}*}"
    if [ -n "${chunk}" ]; then
      word="${word}${chunk}" && has_word=1 && rest="${rest:${#chunk}}"
      continue
    fi
    character="${rest:0:1}" && rest="${rest:1}"
    case "${character}" in
      ' ' | $'\t')
        if [ "${has_word}" -eq 1 ]; then words+=("${word}"); fi
        word='' && has_word=0
        ;;
      "'")
        chunk=${rest%%\'*}
        [ "${chunk}" != "${rest}" ] || { unsafe_reason='引用符が閉じていません。' && return 1; }
        word="${word}${chunk}" && has_word=1 && rest="${rest:$((${#chunk} + 1))}"
        ;;
      '"')
        # shellcheck disable=SC2295
        chunk="${rest%%${DOUBLE_QUOTED_STOP}*}"
        character="${rest:${#chunk}:1}"
        case "${character}" in
          '"') word="${word}${chunk}" && has_word=1 && rest="${rest:$((${#chunk} + 1))}" ;;
          '$' | '`') unsafe_reason='二重引用符の中に、展開される$かバッククォートがあります。' && return 1 ;;
          # シェルは、二重引用符の中の\を、次の文字によって外すか残し、改行の前では行をつなぐので、読み方が食い違いやすい。
          \\) unsafe_reason='二重引用符の中に、\があります。' && return 1 ;;
          *) unsafe_reason='引用符が閉じていません。' && return 1 ;;
        esac
        ;;
      ';' | '&' | '|' | '<' | '>' | '(' | ')' | '$' | '`' | \\ | '{' | '}' | '*' | '?' | '[' | ']' | '~' | '#' | '!' | $'\n' | $'\r')
        unsafe_reason="引用符の外に、区切りか展開の記号「${character}」があります。"
        return 1
        ;;
      # 止める字のうち、区切りでも記号でもない空白（例：垂直タブ）は、語の一部にする。
      *) word="${word}${character}" && has_word=1 ;;
    esac
  done
  if [ "${has_word}" -eq 1 ]; then words+=("${word}"); fi
  return 0
}

main() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-command-word.sh: コマンドの文字列を1つだけ渡してください。' >&2
    exit 2
  fi
  if ! split_command_word "$1"; then
    printf '%s\n' "${unsafe_reason}" >&2
    exit 1
  fi
  # 空の配列をset -uのもとで展開しないように、要素の数を先に見る。
  if [ "${#words[@]}" -gt 0 ]; then
    printf '%s\0' "${words[@]}"
  fi
  exit 0
}

main "$@"
