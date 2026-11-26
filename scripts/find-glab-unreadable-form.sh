#!/bin/bash
# glabのあとの引数を受け取り、止める形があれば、止める理由の文を標準出力に出す。止める形は、コマンドの無い形、判定のスクリプトとglabで読み方が食い違う形、どのコマンドでも止めるオプション、エディターか標準入力から読む本文、行の頭が/の行を含む本文である。
# 終了コードは、0が止める形があった、1が無かった、である。
# scripts/classify-glab-command.shが、コマンドの一覧を引く前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 本文の値を確かめ、止めるなら理由の文を出す。
# 引数：本文の値
# 出力：止める理由の文（止めないときは何も出さない）
# 戻り値：止めるなら0、止めないなら1
print_body_reason() {
  case "$1" in
    - | '' | *[![:space:]]*) ;;
    *) set -- '' ;;
  esac
  if [ "$1" = '-' ] || [ -z "$1" ]; then
    printf '%s' '本文の値が「-」か空白だけなので、glabがエディターか標準入力から読み、判定できません。本文を値に書いてください。'
    return 0
  fi
  if "${BASH}" "${SCRIPT_DIRECTORY}/find-quick-action-line.sh" "$1"; then
    printf '%s' 'GitLabに送る本文に、行の頭が/の行（例：/merge）があります。GitLabがクイックアクションとして動かすので止めます。その行をバッククォートで囲むか、行の頭を変えてください。'
    return 0
  fi
  return 1
}

main() {
  local word is_body=0
  if [ "$#" -eq 0 ]; then
    printf '%s' 'glabのあとに、コマンドがありません。glabのコマンドを書いてください（例：glab mr view 12）。'
    exit 0
  fi
  case "$1" in
    -*)
      printf 'glabの直後に、オプション（%s）があります。glabはコマンドの前のオプションも読むので、コマンドを先に書いてください（例：glab mr list -R g/p）。' "$1"
      exit 0
      ;;
  esac
  for word in "$@"; do
    # glabは値を取る-dと-mの次の語を、-で始まっても値として読むので、次の語は本文としても形としても確かめる。
    if [ "${is_body}" -eq 1 ]; then
      is_body=0
      if print_body_reason "${word}"; then exit 0; fi
    fi
    case "${word}" in
      --)
        printf '%s' '「--」があります。判定のスクリプトとglabで、そのあとの語の読み方が食い違うので止めます。「--」を使わない形で書いてください。'
        exit 0
        ;;
      --push=false) ;;
      --with-variables | --with-variables=*)
        printf 'オプション（%s）は、CI/CDの変数の値を出すので止めます。' "${word}"
        exit 0
        ;;
      --fill | --fill=* | --fill-commit-body | --fill-commit-body=* | --push | --push=*)
        printf 'オプション（%s）は、glabの中でgitのpushを動かすか、判定が見られないcommitのメッセージを本文にするので止めます。git pushで送り、本文は-dの値に書いてください。' "${word}"
        exit 0
        ;;
      --template | --template=* | --recover | --recover=* | --description-file | --description-file=* \
        | --input | --input=* | --form | --form=* | --attach | --attach=*)
        printf 'オプション（%s）は、本文か送る中身をファイルか標準入力か設定のフォルダーから読み、判定のあとに書き換えられるので止めます。本文は-dか-mの値に書いてください。' "${word}"
        exit 0
        ;;
      --no-verify | --no-verify=*)
        printf 'オプション（%s）は、gitのフックを飛ばすので止めます。' "${word}"
        exit 0
        ;;
      -d | --description | -m | --message) is_body=1 ;;
      --description=* | --message=*) if print_body_reason "${word#*=}"; then exit 0; fi ;;
      # pflagは、1つの-のあとの文字を短い形の並びとして読み、値をつないだ形も読む。
      -[A-Za-z]?*)
        printf '束ねた短い形か、値をつないだ短い形（%s）があります。判定のスクリプトが読めないので、1つずつ分けて、値は空白で分けて書いてください（例：-y -f、-R g/p）。' "${word}"
        exit 0
        ;;
    esac
  done
  exit 1
}

main "$@"
