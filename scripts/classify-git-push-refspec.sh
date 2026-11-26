#!/bin/bash
# 保護するブランチのパターン（1行に1つ）、git pushの1つの送り先（refspec）、forceの指定、ブランチを消す指定を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。送り先の書き方ごとに、保護するブランチへのpushと判定できない形を止め、取り消せないpushで確認を求めるためである。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-git-push-command.shが、送り先ごとに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

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

# ブランチの名前が、保護するブランチのパターンのどれかに当たるかを返す。
# 引数：ブランチの名前、保護するブランチのパターン（1行に1つ）
# 出力：なし
# 戻り値：当たれば0、当たらなければ1
is_protected_branch() {
  local pattern
  while IFS= read -r pattern; do
    # パターンを引用符で囲まないのは、release*のようなシェルのパターンとして比べるためである。
    # shellcheck disable=SC2254
    case "$1" in
      ${pattern}) return 0 ;;
    esac
  done <<< "$2"
  return 1
}

main() {
  local spec force delete destination name
  if [ "$#" -ne 4 ]; then
    printf '%s\n' 'classify-git-push-refspec.sh: 保護するブランチのパターン、送り先、forceの指定、ブランチを消す指定の4つを渡してください。' >&2
    exit 2
  fi
  spec="$2" && force="$3" && delete="$4"
  # gitは、*を含む送り先をパターンとして読み、いくつものブランチへ送るので、名前と比べられない。
  case "${spec}" in
    *'*'* | *'?'* | *'['*) raise_decision deny "送り先か送り元に、パターンの記号があります（${spec}）。送り先のブランチを、名前で1つずつ書いてください。" ;;
  esac
  case "${spec}" in +*) force=1 && spec="${spec#+}" ;; esac
  case "${spec}" in :*) delete=1 ;; esac
  destination="${spec#*:}"
  # gitは、heads/mainをrefs/heads/mainと読むので、どちらも外して比べる。
  name="${destination#refs/heads/}" && name="${name#heads/}"
  if is_protected_branch "${name}" "$1"; then
    raise_decision deny "保護するブランチ「${name}」へのpushは止めます。作業用のブランチへpushし、PRを作ってください。"
  elif [ -z "${name}" ] || [ "${name}" = 'HEAD' ] || [ "${name}" = '@' ]; then
    raise_decision deny "送り先のブランチを書いていません（${spec}）。git push <リモート> <ブランチ>:<ブランチ>の形で書いてください。"
  elif [ "${delete}" -eq 1 ]; then
    raise_decision ask "ブランチ「${name}」を消すpushです。取り消せないので、確認を求めます。"
  elif [ "${force}" -eq 1 ]; then
    raise_decision ask "ブランチ「${name}」へのforce pushです。リモートの履歴を上書きするので、確認を求めます。"
  fi
  # gitは、送り先をrefs/、refs/tags/、refs/heads/、refs/remotes/を付けた形でもリモートと比べるので、ブランチの名前のほかの形を通さない。
  case "${destination#refs/heads/}" in
    refs/* | heads/* | tags/* | remotes/* | *:*) raise_decision deny "送り先「${destination}」は、ブランチでないか、ブランチの名前のほかの形です。送り先は、ブランチの名前だけで書いてください。" ;;
  esac
  printf '%s\n%s\n' "${decision}" "${reason}"
  exit 0
}

main "$@"
