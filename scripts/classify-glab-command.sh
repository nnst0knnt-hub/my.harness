#!/bin/bash
# glabのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。読み取りのコマンドだけを確認なしで通し、書き込みとほかのホストで確認を求め、トークンと秘密の値を出す形、外で動く形、判定のスクリプトとglabで読み方が食い違う形を止めるためである。
# 終了コードは、いつも0である。
# scripts/classify-remote-command.shが、glabのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「`glab`の判定」に書く。
set -u -o pipefail
export LC_ALL=C

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 止める行の理由の文を出す。
# 引数：コマンドの名前の並び、理由の種類
# 出力：理由の文
# 戻り値：0
print_deny_reason() {
  case "$2" in
    token) printf 'glab %sは、トークンか秘密の値を出すので止めます。' "$1" ;;
    push) printf 'glab %sは、gitのpushをglabの中で動かし、pushの判定を通らないので止めます。git pushで送ってください。' "$1" ;;
    upload) printf 'glab %sは、手元のファイルか記録を読んでGitLabへ送るので止めます。' "$1" ;;
    repo-view) printf '%s' 'glab repo viewは、-F jsonでプロジェクトのトークン（runners_token）を出すことがあるので止めます。公開かは、決まったGraphQLの問い合わせで読んでください。' ;;
    clone) printf 'glab %sは、サンドボックスの外で新しいリポジトリをcloneし、今のリポジトリのgitのフォルダーを固定して動かす形に合わないので止めます。cloneは、人がClaude Codeの外で動かしてください。' "$1" ;;
    *) printf 'glab %sは、ほかのプログラムをサンドボックスの外で動かすか、外の設定や指示のファイルを書くので止めます。' "$1" ;;
  esac
}

# 確認を求める行の理由の文を出す。ほかのホストを指す引数があれば、そのことも書く。
# 引数：コマンドの名前の並び、理由の種類、glabの引数
# 出力：理由の文
# 戻り値：0
print_ask_reason() {
  local path="$1" kind="$2" word is_repo=0 host=''
  shift 2
  case "${kind}" in
    send) printf 'glab %sは、手元のファイルを読んでGitLabへ送ることがあるので、確認を求めます。外のglabは、サンドボックスが読めなくしたファイルも読めます。' "${path}" ;;
    local) printf 'glab %sは、サンドボックスの外で、手元のファイルかgitを書き換えることがあるので、確認を求めます。外のglabは、サンドボックスが書かせないパス（例：.git/config）にも書けます。' "${path}" ;;
    screen) printf 'glab %sは、端末の画面かブラウザーを開くか、終わらないことがあるので、確認を求めます。' "${path}" ;;
    checkout) printf '%s' 'glab mr checkoutは、サンドボックスの外でgitのfetchとcheckoutを動かします。導入先のgitのフックと、gitの設定のコマンド（例：core.sshCommand、core.fsmonitor）も、外で動くことがあります。手元のブランチを書き換えるので、確認を求めます。' ;;
    *) printf 'glab %sは、確認なしで通す読み取りの一覧に無く、リモートへの書き込みのことがあるので、確認を求めます。' "${path}" ;;
  esac
  for word in "$@"; do
    if [ "${is_repo}" -eq 1 ] && "${BASH}" "${SCRIPT_DIRECTORY}/find-other-host-word.sh" "${word}"; then
      host="${word}"
    fi
    is_repo=0
    # glabがURLとして読むのは、頭がスキームの語だけである。本文の途中のURL（例：-mの値）は、送り先を変えない。
    if [[ "${word}" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then host="${word}"; fi
    case "${word}" in
      -R | --repo) is_repo=1 ;;
      --repo=*) if "${BASH}" "${SCRIPT_DIRECTORY}/find-other-host-word.sh" "${word#*=}"; then host="${word}"; fi ;;
    esac
  done
  if [ -n "${host}" ]; then
    printf 'GitLabのほかのホストを指す引数（%s）もあります。' "${host}"
  fi
}

main() {
  local reason row path decision kind short required between length word
  if reason="$("${BASH}" "${SCRIPT_DIRECTORY}/find-glab-unreadable-form.sh" "$@")"; then
    printf 'deny\n%s\n' "${reason}"
    exit 0
  fi
  if ! row="$("${BASH}" "${SCRIPT_DIRECTORY}/print-glab-command-row.sh" "$@")"; then
    printf 'deny\nglabの「%s」は、知らないコマンドか別名なので止めます。glabの本来のコマンドの名前で書いてください（例：glab mr view）。\n' "${*%% -*}"
    exit 0
  fi
  IFS=$'\t' read -r path decision kind short required between length <<< "${row}"
  if [ "${between}" != '-' ]; then
    printf 'deny\nコマンドの名前の間に、オプションがあります（「%s」の前）。glabはオプションを飛ばしてコマンドの名前を探すので、名前をすべて先に書いてください（例：glab mr note create 12 -R g/p）。\n' "${between}"
    exit 0
  fi
  for word in "$@"; do
    if [ "${short}" != '-' ] && [ "${word}" = "${short}" ]; then
      printf 'deny\nglab %sの%sは--fillなので止めます（gitのpushを動かし、本文をcommitのメッセージから作る）。\n' "${path}" "${short}"
      exit 0
    fi
  done
  if reason="$("${BASH}" "${SCRIPT_DIRECTORY}/find-glab-missing-argument.sh" "${path}" "${required}" "${@:$((length + 1))}")"; then
    printf 'deny\n%s\n' "${reason}"
    exit 0
  fi
  case "${decision}:${kind}" in
    deny:*) printf 'deny\n%s\n' "$(print_deny_reason "${path}" "${kind}")" ;;
    api:*) "${BASH}" "${SCRIPT_DIRECTORY}/classify-glab-api-command.sh" "${@:2}" ;;
    allow:bare)
      if [ "$#" -gt "${length}" ]; then
        printf 'deny\nglab %sは、引数を付けずに動かしてください。引数（例：--show-token）で、トークンを出すことがあるためです。\n' "${path}"
      else
        printf 'allow\n\n'
      fi
      ;;
    allow:*) "${BASH}" "${SCRIPT_DIRECTORY}/classify-glab-read-command.sh" "${path}" "${@:$((length + 1))}" ;;
    *) printf 'ask\n%s\n' "$(print_ask_reason "${path}" "${kind}" "$@")" ;;
  esac
  exit 0
}

main "$@"
