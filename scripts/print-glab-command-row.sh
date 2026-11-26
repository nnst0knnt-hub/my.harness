#!/bin/bash
# glabのあとの引数を受け取り、data/glab-command-list.tsvのうち、最初のオプションの前の4語までに最も長く当たる行を出す。行の後ろに、タブで区切って、コマンドの名前の並びを伸ばす後ろの語（無ければ「-」）と、並びの語の数を足す。cobraは、名前の間のオプションを飛ばして子のコマンドを探すので、判定のスクリプトがその形を止めるためである。
# 終了コードは、0が行を出した、1が当たる行が無かった、である。
# scripts/classify-glab-command.shが、glabのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly COMMAND_LIST="${SCRIPT_DIRECTORY}/../data/glab-command-list.tsv"

main() {
  local word names='' rest='' count=0 has_option=0 row
  for word in "$@"; do
    case "${word}" in
      -*) has_option=1 ;;
      *)
        if [ "${has_option}" -eq 0 ] && [ "${count}" -lt 4 ]; then
          names="${names}${names:+ }${word}" && count=$((count + 1))
        else
          rest="${rest}${word}"$'\n'
        fi
        ;;
    esac
  done
  # 後ろの語は、オプションの値かどうかを読み分けず、すべて確かめる。読み分けを誤って伸ばす語を見逃すより、誤って止めるほうが安全なためである。
  row="$(HARNESS_GLAB_NAME="${names}" HARNESS_GLAB_REST="${rest}" awk -F '\t' '
    !/^#/ && NF >= 5 {
      name = ENVIRON["HARNESS_GLAB_NAME"]
      if ((name == $1 || index(name, $1 " ") == 1) && length($1) > length(path)) { path = $1; row = $0 }
      keys[++n] = $1
    }
    END {
      if (row == "") exit
      extra = substr(ENVIRON["HARNESS_GLAB_NAME"], length(path) + 2) "\n" ENVIRON["HARNESS_GLAB_REST"]
      gsub(/ /, "\n", extra)
      m = split(extra, words, "\n")
      between = "-"
      for (i = 1; i <= m && between == "-"; i++) {
        if (words[i] == "") continue
        for (j = 1; j <= n; j++) {
          if (keys[j] == path " " words[i] || index(keys[j], path " " words[i] " ") == 1) { between = words[i]; break }
        }
      }
      printf "%s\t%s\t%d\n", row, between, split(path, parts, " ")
    }
  ' "${COMMAND_LIST}")"
  if [ -z "${row}" ]; then
    exit 1
  fi
  printf '%s\n' "${row}"
  exit 0
}

main "$@"
