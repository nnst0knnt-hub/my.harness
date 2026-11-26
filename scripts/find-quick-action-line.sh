#!/bin/bash
# 値を1つ受け取り、行の頭（前の空白を除く）が/の行があるかを返す。復帰の文字も行の区切りとして扱う。GitLabが本文の行の頭の/をクイックアクション（例：/merge）として動かすので、判定のスクリプトがその本文を止めるためである。
# 終了コードは、0があった、1が無かった、2が使い方の誤りである。
# scripts/classify-glab-command.shとscripts/classify-glab-api-command.shが、GitLabに送る本文を確かめるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

main() {
  local value line
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'find-quick-action-line.sh: 確かめる値を1つだけ渡してください。' >&2
    exit 2
  fi
  value="${1//$'\r'/$'\n'}"
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"
    case "${line}" in
      /*) exit 0 ;;
    esac
  done <<< "${value}"
  exit 1
}

main "$@"
