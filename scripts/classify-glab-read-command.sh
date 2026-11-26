#!/bin/bash
# glabの通すコマンドの名前の並びと、そのあとの引数を受け取り、1行目に判定（allowかask）、2行目に理由の文を出す。許すオプションの一覧に無いオプション、ブラウザーを開く-w、ほかのホストを指す引数に確認を求め、今後のglabが足すオプションを確かめるまで通さないためである。
# 終了コードは、いつも0である。
# scripts/classify-glab-command.shが、data/glab-command-list.tsvの通す行に当たったときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly OPTION_LIST="${SCRIPT_DIRECTORY}/../data/glab-read-command-option-list.tsv"

main() {
  local path="$1" options word skip='' host=''
  shift
  options=" $(awk -F '\t' -v path="${path}" '!/^#/ && $1 == path { printf "%s=%s ", $2, $3 }' "${OPTION_LIST}")"
  for word in "$@"; do
    # 値を取るオプションの次の語は値として読み、-Rと--repoの値だけをホストとして確かめる。
    if [ -n "${skip}" ]; then
      if [ "${skip}" = 'repo' ] && "${BASH}" "${SCRIPT_DIRECTORY}/find-other-host-word.sh" "${word}"; then
        host="${word}"
      fi
      skip=''
      case "${word}" in
        *://*) host="${word}" ;;
      esac
      continue
    fi
    case "${word}" in
      -w | --web | --web=*)
        printf 'ask\nglab %sの-wは、サンドボックスの外でブラウザーを開くので、確認を求めます。\n' "${path}"
        exit 0
        ;;
      -*)
        case "${options}" in
          *" ${word%%=*}=value "* | *" ${word}=flag "*) ;;
          *)
            printf 'ask\nglab %sで、許すオプションの一覧に無いオプション（%s）があります。確認を求めます。\n' "${path}" "${word}"
            exit 0
            ;;
        esac
        case "${word}" in
          -R | --repo) skip='repo' ;;
          --repo=*) if "${BASH}" "${SCRIPT_DIRECTORY}/find-other-host-word.sh" "${word#*=}"; then host="${word}"; fi ;;
          *=*) ;;
          *) case "${options}" in *" ${word}=value "*) skip='value' ;; esac ;;
        esac
        ;;
      *) if "${BASH}" "${SCRIPT_DIRECTORY}/find-other-host-word.sh" "${word}"; then host="${word}"; fi ;;
    esac
    case "${word}" in
      *://*) host="${word}" ;;
    esac
  done
  if [ -n "${host}" ]; then
    printf 'ask\nGitLabのほかのホストを指すか、ホストとして読まれる引数（%s）があります。glabはサンドボックスの外で動くので、確認を求めます。\n' "${host}"
    exit 0
  fi
  printf 'allow\n\n'
  exit 0
}

main "$@"
