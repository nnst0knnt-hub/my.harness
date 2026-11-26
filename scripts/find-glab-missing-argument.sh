#!/bin/bash
# glabのコマンドの名前の並び、data/glab-command-list.tsvの要る引数の列の値、コマンドの名前の後ろの引数を受け取り、要る引数が無ければ、止める理由の文を標準出力に出す。本文と対象をglabがエディター、標準入力、今のブランチから決め、判定のスクリプトが見られないか、判定のあとに変えられる形を止めるためである。
# 終了コードは、0が要る引数が無かった（理由の文を出した）、1があったか要る引数が無いコマンド、2が使い方の誤りである。
# scripts/classify-glab-command.shが、glabのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail

main() {
  local word
  if [ "$#" -lt 2 ]; then
    printf '%s\n' 'find-glab-missing-argument.sh: コマンドの名前の並び、要る引数の列の値、コマンドの名前の後ろの引数を渡してください。' >&2
    exit 2
  fi
  # 番号と送り元のブランチが無いと、glabは今のブランチから決め、ブランチは判定のあとにサンドボックスの中から変えられる。
  # 値を取るオプションを見分けず、ほかのオプションの値（例：-d --source-branch）と読み違えないよう、場所をコマンドの名前のすぐ後ろに決める。
  case "$2" in
    -) exit 1 ;;
    -m)
      for word in "${@:3}"; do
        case "${word}" in -m | --message | --message=*) exit 1 ;; esac
      done
      printf 'glab %sに-mがありません。glabがエディターか標準入力から本文を読み、判定できないので止めます。本文を-mの値に書いてください。\n' "$1"
      ;;
    number)
      case "${3:-}" in
        '' | *[!0-9]*) ;;
        *) exit 1 ;;
      esac
      printf 'glab %sは、対象のMRの番号を、コマンドの名前のすぐ後ろに書いてください（例：glab %s 12 -R g/p）。番号が無いと、glabは今のブランチから対象を決め、そのブランチは判定のあとに変えられるので止めます。\n' "$1" "$1"
      ;;
    --source-branch)
      case "${3:-}" in
        --source-branch=[!-]*) exit 1 ;;
        -s | --source-branch) case "${4:-}" in '' | -*) ;; *) exit 1 ;; esac ;;
      esac
      printf 'glab %sは、送り元のブランチを、コマンドの名前のすぐ後ろに--source-branchで書いてください（例：glab %s --source-branch feat/x --title …）。書かないと、glabは今のブランチを送り元にし、そのブランチは判定のあとに変えられるので止めます。\n' "$1" "$1"
      ;;
    *) printf 'data/glab-command-list.tsvの要る引数の列に、知らない値（%s）があるので止めます。ハーネスの一覧を確かめてください。\n' "$2" ;;
  esac
  exit 0
}

main "$@"
