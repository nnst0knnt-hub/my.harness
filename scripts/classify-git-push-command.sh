#!/bin/bash
# 作業フォルダー、メインの作業フォルダー、git pushのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。送り先を書いた作業用のブランチへの簡単な形だけを通し、保護するブランチへのpushと判定できない形を止めるためである。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-remote-command.shが、git pushのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

decision='allow'
reason=''

# 判定を、今より強いとき（allow < ask < deny）だけ変える。同じ強さなら、先の理由を残す。
# 引数：判定、理由の文
# 出力：なし（decisionとreasonを書く）
# 戻り値：0
raise_decision() {
  case "${decision} $1" in
    'allow ask' | 'allow deny' | 'ask deny') decision="$1" && reason="$2" ;;
  esac
}

main() {
  local word remote='' force=0 delete=0 spec output protected_patterns
  local specs=()
  if [ "$#" -lt 2 ]; then
    printf '%s\n' 'classify-git-push-command.sh: 作業フォルダー、メインの作業フォルダー、git pushのあとの引数を渡してください。' >&2
    exit 2
  fi
  if ! protected_patterns="$("${BASH}" "${SCRIPT_DIRECTORY}/print-protection-list.sh" "$2" branch 2> /dev/null)"; then
    printf 'ask\n%s\n' '保護するブランチの一覧を読めませんでした（.harness/configを確かめてください）。'
    exit 0
  fi
  for word in "${@:3}"; do
    case "${word}" in
      --no-verify) raise_decision deny 'gitのフックを飛ばす--no-verifyは止めます。--no-verifyを外して動かしてください。' ;;
      -u | --set-upstream | -q | --quiet | -v | --verbose | --progress) ;;
      -f | --force | --force-with-lease | --force-with-lease=* | --force-if-includes) force=1 ;;
      -d | --delete) delete=1 ;;
      -*) raise_decision deny "知らないオプション「${word}」を含みます。決まったオプション（例：-u）だけで書いてください。" ;;
      *) if [ -z "${remote}" ]; then remote="${word}"; else specs+=("${word}"); fi ;;
    esac
  done
  # 設定に無い名前は、gitがURLか手元のパスとして読み、そこにあるフックがサンドボックスの外で動くことがある。
  case "${remote}" in
    '' | *[!A-Za-z0-9._-]*) raise_decision deny 'リモートを、gitの設定にある名前（例：origin）で書いてください。' ;;
    *) git -C "$1" config --get "remote.${remote}.url" > /dev/null 2>&1 \
      || raise_decision deny "リモート「${remote}」が、gitの設定にありません。設定にあるリモートの名前（例：origin）で書いてください。" ;;
  esac
  # 理由の文のリモートは、コマンドに書いたものにする。設定に無いリモートは上で止まり、先の理由の文が残る。
  if [ "${#specs[@]}" -eq 0 ]; then
    raise_decision deny "送り先のブランチを書いていません。git push ${remote} <ブランチ>:<ブランチ>の形で書いてください。"
  fi
  # 空の配列をset -uのもとで展開しないように、「+」の形で渡す。
  for spec in ${specs[@]+"${specs[@]}"}; do
    output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-git-push-refspec.sh" "${protected_patterns}" "${spec}" "${force}" "${delete}")"
    case "$(printf '%s\n' "${output}" | sed -n 1p)" in
      allow) ;;
      ask | deny) raise_decision "$(printf '%s\n' "${output}" | sed -n 1p)" "$(printf '%s\n' "${output}" | sed -n 2p)" ;;
      *) raise_decision ask '送り先の判定のスクリプトが、決まった判定を返しませんでした。' ;;
    esac
    # 送り先を書かない送り元は、gitの設定（例：push.default）と参照（例：mainを指すシンボリックな参照）で送り先が決まり、判定のあとにも変えられる。消すpushの名前は、送り先である。
    case "${spec}" in
      *:*) ;;
      *) [ "${delete}" -eq 1 ] || raise_decision deny "送り先を書いていません（${spec}）。git push ${remote} ${spec}:${spec#+}の形で、送り先のブランチを書いてください。" ;;
    esac
  done
  printf '%s\n%s\n' "${decision}" "${reason}"
  exit 0
}

main "$@"
