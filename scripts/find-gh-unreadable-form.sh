#!/bin/bash
# ghのあとの引数を受け取り、本文か送る中身を、ファイル、標準入力、エディター、判定のあとに変えられるcommitのメッセージから読む形と、ghが値の中の語を置き換える形があれば、止める理由の文を標準出力に出す。確認で人が見る本文と、外で動くghが送る本文が食い違うためである。
# 終了コードは、0が止める形があった、1が無かった、である。
# scripts/classify-gh-command.shが、gh apiと、読み取りのほかのghのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

readonly READ_OUTSIDE='外のghは、判定のあとに書き換えたファイルや、サンドボックスが読めなくしたファイルも読むためです。'

# 型を変えて送るオプション（gh apiとgh workflow runの-Fと--field）の値が、ファイルか標準入力から読む形か、ghが語を置き換える形かを確かめる。
# 引数：オプションの値（キー=値の形）
# 出力：止める理由の文（止めないときは何も出さない）
# 戻り値：止めるなら0、止めないなら1
print_field_reason() {
  case "${1#*=}" in
    @*)
      printf '値（%s）を、ファイルか標準入力から読んでいるので止めます。%s値をそのまま書いてください。' "$1" "${READ_OUTSIDE}"
      return 0
      ;;
    # ghは、-Fの値の中の:ownerと{owner}のような語を、今のリポジトリの値に置き換えて送る（gh apiのソースのplaceholderRE）。
    *:owner* | *:repo* | *:branch* | *'{owner}'* | *'{repo}'* | *'{branch}'*)
      printf '値（%s）に、ghが今のリポジトリの値に置き換える語（:owner、:repo、:branch、{owner}、{repo}、{branch}）があるので止めます。確認で見る値と送る値が変わるためです。-fで送るか、語を言い換えてください（例：<repo>）。' "$1"
      return 0
      ;;
  esac
  return 1
}

# 本文か送る中身をほかの場所から読むオプションの、止める理由の文を出す。
# 引数：オプション
# 出力：止める理由の文
# 戻り値：0
print_option_reason() {
  printf 'オプション（%s）は、本文か送る中身を、ファイル、標準入力、エディター、判定のあとに変えられるcommitのメッセージから読むので止めます。%s本文は値に書いてください（例：--body '"'"'<本文>'"'"'、gh apiの-f）。' "$1" "${READ_OUTSIDE}"
}

main() {
  local command="${1:-} ${2:-}" word is_api=0 is_field=0
  [ "${1:-}" != 'api' ] || is_api=1
  for word in "$@"; do
    # 値を取る-Fと--fieldの次の語は、-で始まっても値として読まれる。
    if [ "${is_field}" -eq 1 ]; then
      is_field=0
      if print_field_reason "${word}"; then exit 0; fi
      continue
    fi
    case "${is_api}:${word}" in
      *:--field | 1:-F) is_field=1 ;;
      *:--field=*) if print_field_reason "${word#--field=}"; then exit 0; fi ;;
      1:-F?*) if print_field_reason "${word#-F}"; then exit 0; fi ;;
      *:--input | *:--input=* | *:--body-file | *:--body-file=* | *:--notes-file | *:--notes-file=* \
        | *:--from-file | *:--from-file=* | *:--env-file | *:--env-file=* | *:--editor | *:--editor=* \
        | *:--recover | *:--recover=* | *:--fill | *:--fill=* | *:--fill-first | *:--fill-first=* \
        | *:--fill-verbose | *:--fill-verbose=*)
        print_option_reason "${word}"
        exit 0
        ;;
      # gh repo createの--templateは、もとにするリポジトリの名前で、ファイルを読まない。
      0:--template | 0:--template=*)
        if [ "${command}" != 'repo create' ]; then print_option_reason "${word}" && exit 0; fi
        ;;
      0:-F | 0:-e | 0:-T | 0:-f)
        printf '短い形（%s）は、コマンドによって、本文か中身をファイルかエディターかcommitのメッセージから読む意味になるので止めます。長い形（例：--force、--raw-field、--env）で書き、本文は--bodyの値に書いてください。' "${word}"
        exit 0
        ;;
      # pflagは、1つの-のあとの文字を短い形の並びとして読み、値をつないだ形も読む。
      0:-[A-Za-z]?*)
        printf '束ねた短い形か、値をつないだ短い形（%s）があります。判定のスクリプトが読めないので、1つずつ分けて、値は空白で分けて書いてください（例：-d --body x、-R a/b）。' "${word}"
        exit 0
        ;;
    esac
  done
  exit 1
}

main "$@"
