#!/bin/bash
# glabの-Rの値か位置の引数を1つ受け取り、GitLabのほかのホストを指すか、ホストとして読まれる語かを返す。glabは、-Rの最初の部分が.か:を含む設定済みのホストのときにホストとして読み、スキームの無いURL（//ホスト/…）もそのホストへの要求にするためである。
# 終了コードは、0が指す、1が指さない、2が使い方の誤りである。
# scripts/classify-glab-command.shとscripts/classify-glab-read-command.shが、glabの引数を確かめるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

main() {
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'find-other-host-word.sh: 確かめる語を1つだけ渡してください。' >&2
    exit 2
  fi
  # :と@は、許す文字に無いので、この行で当たる。
  case "$1" in
    *[!A-Za-z0-9._/-]* | /* | *//*) exit 0 ;;
  esac
  # /を含む語の最初の部分だけをホストとして読む。/の無い語（例：タグのv1.0.0）は、ホストにならない。
  case "$1" in
    */*)
      case "${1%%/*}" in
        *.*) exit 0 ;;
      esac
      ;;
  esac
  exit 1
}

main "$@"
