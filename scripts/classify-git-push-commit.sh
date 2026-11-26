#!/bin/bash
# 作業フォルダー、メインの作業フォルダー、リモートに問い合わせるか（queryかno-query）、git pushのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文、3行目に送り元を手元のcommitのSHAにしたpushのコマンドを出す。送るcommitがCIの設定のファイルを変えるpushで確認を求め、判定で確かめたcommitだけを送るためである。no-queryでは、問い合わせずに、CIの設定のファイルを確かめていないとして確認を求める。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-local-git-state.shが、通すか確認を求めるgit pushで呼ぶ。gitの設定の確認が何かを見つけたときと、導入先のリポジトリとみなせないリポジトリでは、no-queryで呼ぶ。理由は、.harness/docs/features/protection.mdの節「CIの設定のファイルを変えるpush」と節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# フックの時間切れ（30秒）より短くし、超えたら止めずに確認を求める。
readonly QUERY_TIME_LIMIT_SECONDS=10

pinned_command='git push'

# 判定、理由の文、書き換えたpushのコマンドの3行を出して終わる。
# 引数：判定、理由の文
# 出力：3行
# 戻り値：なし（exitする）
print_result_and_exit() {
  printf '%s\n%s\n%s\n' "$1" "$2" "${pinned_command}"
  exit 0
}

# 比べる元と送るcommitで、CIの設定のファイルのmodeとSHAが違う場所を、1行に1つ出す。
# 引数：作業フォルダー、比べる元のcommit、送るcommit、CIの設定のファイルの場所（1行に1つ）
# 出力：違う場所
# 戻り値：比べられたら0、照らして読めなければ1
print_changed_path() {
  local path base_entry sent_entry
  while IFS= read -r path; do
    base_entry="$("${BASH}" "${SCRIPT_DIRECTORY}/print-tree-entry.sh" "$1" "$2" "${path}" 2> /dev/null)" || return 1
    sent_entry="$("${BASH}" "${SCRIPT_DIRECTORY}/print-tree-entry.sh" "$1" "$3" "${path}" 2> /dev/null)" || return 1
    [ "${base_entry}" = "${sent_entry}" ] || printf '%s\n' "${path}"
  done <<< "$4"
}

main() {
  local word remote='' delete=0 spec source name sha paths heads base index changed=''
  local names=() shas=() specs=()
  if [ "$#" -lt 4 ] || { [ "$3" != 'query' ] && [ "$3" != 'no-query' ]; }; then
    printf '%s\n' 'classify-git-push-commit.sh: 作業フォルダー、メインの作業フォルダー、queryかno-query、git pushのあとの引数を渡してください。' >&2
    exit 2
  fi
  for word in "${@:4}"; do case "${word}" in -d | --delete) delete=1 ;; esac; done
  # 許すオプションは値を別の語に取らないので、オプションでない最初の語がリモートで、ほかが送り先である。
  for word in "${@:4}"; do
    spec="${word}" && source="${word#+}"
    case "${word}" in
      -*) ;;
      *)
        if [ -z "${remote}" ]; then
          remote="${word}"
        # 消す送り先（--deleteのあとの名前と、:<ブランチ>）は、送るcommitが無いので書き換えない。
        elif [ "${delete}" -eq 0 ] && [ "${source#:}" = "${source}" ]; then
          name="${source#*:}" && name="${name#refs/heads/}"
          if ! sha="$(git --no-replace-objects -C "$1" rev-parse --verify -q "${source%%:*}^{commit}" 2> /dev/null)"; then
            printf 'deny\n送り元「%s」が、手元のcommitになりません。手元にあるブランチかcommitを、送り元に書いてください。\n\n' "${source%%:*}"
            exit 0
          fi
          spec="${word%"${source}"}${sha}:refs/heads/${name}"
          names+=("${name}") && shas+=("${sha}")
        fi
        ;;
    esac
    specs+=("${spec}")
  done
  pinned_command="${pinned_command} $("${BASH}" "${SCRIPT_DIRECTORY}/print-quoted-word.sh" "${specs[@]}")"
  # 消すpushは、送るcommitが無いので比べない。
  [ "${#names[@]}" -gt 0 ] || print_result_and_exit allow ''
  # 送り元のSHAは手元のgitだけで求めるので、問い合わせないときも固定する。
  [ "$3" = 'query' ] || print_result_and_exit ask 'CIの設定のファイルは確かめていません。'
  if ! paths="$("${BASH}" "${SCRIPT_DIRECTORY}/print-protection-list.sh" "$2" ciSettingPath 2> /dev/null)"; then
    print_result_and_exit ask 'CIの設定のファイルの場所の一覧を読めなかったので、CIの設定のファイルを変えるかを確かめていません（.harness/configを確かめてください）。'
  fi
  # 失敗したときは、出力が無く、標準エラーの原因の文（例：時間切れ、許さない方式のURL）だけが出るので、理由の文に足す。
  if ! heads="$("${BASH}" "${SCRIPT_DIRECTORY}/print-remote-head.sh" "$1" "${remote}" "${QUERY_TIME_LIMIT_SECONDS}" "${names[@]}" 2>&1)"; then
    print_result_and_exit ask "リモート「${remote}」に問い合わせられなかったので、CIの設定のファイルを変えるかを確かめていません。${heads#print-remote-head.sh: }"
  fi
  for index in "${!names[@]}"; do
    # 送り先がリモートに無ければ、既定のブランチの今の先頭と比べる。分岐点は、親のcommitの情報を手元で偽れるので求めない。
    base="$(printf '%s\n' "${heads}" | awk -v ref="refs/heads/${names[index]}" '$2 == ref { print $1 }')"
    [ -n "${base}" ] || base="$(printf '%s\n' "${heads}" | awk '$2 == "HEAD" { print $1 }')"
    [ -n "${base}" ] || print_result_and_exit ask "リモート「${remote}」に、送り先のブランチもHEADも無いので、CIの設定のファイルを比べる元がありません。"
    if ! changed="${changed}$(print_changed_path "$1" "${base}" "${shas[index]}" "${paths}")"$'\n'; then
      print_result_and_exit ask "比べる元（リモートの今の先頭）か送るcommitを、手元で照らして読めませんでした（手元に無いか、中身とSHAが合いません）。手元に無いときは、git fetch ${remote} ${names[index]}のあとに、もう一度pushしてください。"
    fi
  done
  # pasteの-dは区切りを1バイトずつ読むので、「、」でつなぐのはawkで行う。
  changed="$(printf '%s' "${changed}" | grep -v '^$' | sort -u | awk 'NR > 1 { printf "、" } { printf "%s", $0 }')"
  [ -n "${changed}" ] || print_result_and_exit allow ''
  print_result_and_exit ask "CIの設定のファイル（${changed}）を変えるpushです。CIのジョブはリポジトリのsecretsを読めるので、差分を確かめてから認めてください。"
}

main "$@"
