#!/bin/bash
# 作業フォルダーと、git fetchのあとの引数を受け取り、1行目に判定（allowかdeny）、2行目に理由の文を出す。リモートの名前とブランチだけの簡単な形を通し、任意のコマンドを動かせるオプションと設定に無いリモートを通さない。git fetchがサンドボックスの外で動くためである。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-remote-command.shが、git fetchのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

main() {
  local word remote=''
  if [ "$#" -lt 1 ]; then
    printf '%s\n' 'classify-git-fetch-command.sh: 作業フォルダーと、git fetchのあとの引数を渡してください。' >&2
    exit 2
  fi
  for word in "${@:2}"; do
    case "${word}" in
      -p | --prune | --tags | --no-tags | -q | --quiet | -v | --verbose | --progress) continue ;;
      -*)
        printf 'deny\n知らないオプション「%s」を含みます。git fetchは外で動くので、決まったオプション（例：--prune）だけで書いてください。\n' "${word}"
        exit 0
        ;;
    esac
    if [ -z "${remote}" ]; then
      remote="${word}"
      # 設定に無い名前は、gitがURLか手元のパスとして読み、そこにあるものがサンドボックスの外で動くことがある。
      case "${remote}" in
        *[!A-Za-z0-9._-]*)
          printf 'deny\nリモートを、gitの設定にある名前（例：origin）で書いてください（%s）。\n' "${remote}"
          exit 0
          ;;
      esac
      if ! git -C "$1" config --get "remote.${remote}.url" > /dev/null 2>&1; then
        printf 'deny\nリモート「%s」が、gitの設定にありません。設定にあるリモートの名前（例：origin）で書いてください。\n' "${remote}"
        exit 0
      fi
      continue
    fi
    # 取るブランチは、手元のブランチへ書く形（例：main:main、+main:main）も許す。手元にだけ書くためである。
    case "${word#+}" in
      '' | *[!A-Za-z0-9._/:-]* | *:*:*)
        printf 'deny\n取るブランチを、名前のほかの形で書いています（%s）。git fetch %s <ブランチ>の形で書いてください。\n' "${word}" "${remote}"
        exit 0
        ;;
    esac
  done
  # リモートを書かないと、gitは、設定に無いリモートを、サンドボックスの中から書ける.git/remotes/と.git/branches/のファイルから読むことがある。
  if [ -z "${remote}" ]; then
    printf 'deny\n%s\n' 'リモートを書いていません。gitの設定にあるリモートの名前を書いてください（例：git fetch origin main）。'
    exit 0
  fi
  printf 'allow\n%s\n' ''
  exit 0
}

main "$@"
