#!/bin/bash
# 作業フォルダー、メインの作業フォルダー、リポジトリの種類（projectが導入先のリポジトリとみなせるリポジトリ、otherがみなせないリポジトリ）、コマンドごとの判定と理由の文、コマンドの語を受け取り、手元のgitの状態を見て強めた判定、理由の文、pushの送り元を手元のcommitのSHAにしたコマンドの3行を出す。サンドボックスの外で動くgitとglabが、サンドボックスの中から書いた設定と、判定のあとに書き換えたブランチを使わないためである。
# 終了コードは、0が判定を出した、2が使い方の誤りである。
# scripts/classify-remote-command.shが、コマンドごとの判定が通すか確認を求めるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitの設定の確認」と節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 2つの判定のうち、強いほう（allow < ask < deny）を出す。
# 引数：判定、判定
# 出力：判定
# 戻り値：0
print_stronger_decision() {
  case "$1 $2" in
    *deny*) printf '%s' 'deny' ;;
    *ask*) printf '%s' 'ask' ;;
    *) printf '%s' 'allow' ;;
  esac
}

main() {
  local decision reason finding commit_output pinned_command='' query='query'
  if [ "$#" -lt 6 ] || { [ "$3" != 'project' ] && [ "$3" != 'other' ]; }; then
    printf '%s\n' 'classify-local-git-state.sh: 作業フォルダー、メインの作業フォルダー、リポジトリの種類（projectかother）、判定、理由の文、コマンドの語を渡してください。' >&2
    exit 2
  fi
  decision="$4"
  reason="$5"
  # 外のglabは、gitのフォルダーのglab-cli/の設定（例：host）を読み、送り先とトークンを変えることがある。
  if [ "$6" = 'glab' ] && finding="$("${BASH}" "${SCRIPT_DIRECTORY}/find-glab-setting-in-git-directory.sh" "$1" 2> /dev/null)"; then
    decision='ask'
    reason="${reason}gitのフォルダーに、glabの設定のフォルダー（${finding}）があります。外のglabがその設定を読み、送り先とトークンが変わることがあるので、確認を求めます。"
  fi
  # ghは、確認を求めるもの（例：書き込み、gh pr checkout、-wか--webかほかのホストを指す読み取り）だけを、gitのフォルダーを固定して外で動かすので、そのときだけgitの設定を見る。
  if [ "$6" != 'gh' ] || [ "${decision}" = 'ask' ]; then
    # 通すか確認を求めるgitでも、サンドボックスの中から書ける設定かファイルを外のgitが使うなら、確認を求める。確認を求めるもの（例：force push）は、もとの理由の文に足し、人が知ってから認められるようにする。
    # このときと、導入先のリポジトリとみなせない（設定をサンドボックスの中から書けることがある）リポジトリでは、問い合わせのgitがその設定を人の確認の前に動かさないよう、問い合わせない。送り元は、手元のgitだけでSHAにする。
    if ! finding="$("${BASH}" "${SCRIPT_DIRECTORY}/find-git-setting-in-working-tree.sh" "$1" "${SCRIPT_DIRECTORY%/*}" 2>&1 > /dev/null)"; then
      # 見つけたものの文の頭で始まる最初の行だけを使い、ほかの標準エラー（例：gitやbashのエラー）を見つけたものとして人に見せない。
      finding="$(printf '%s\n' "${finding}" | LC_ALL=C awk '/^find-git-(setting-in-working-tree|transport-setting)\.sh: / { print; exit }')"
      [ -n "${finding}" ] || finding=': 何を見つけたかを読めませんでした'
      decision='ask'
      reason="${reason}サンドボックスの外で動くgitが、サンドボックスの中から書ける設定かファイルを使うことがあります（${finding#*: }）。認めると、その設定かファイルのとおりに、gitがサンドボックスの外で動くことがあります。"
      query='no-query'
    fi
    [ "$3" = 'project' ] || query='no-query'
    if [ "${7:-}" = 'push' ]; then
      commit_output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-git-push-commit.sh" "$1" "$2" "${query}" "${@:8}")"
      case "$(printf '%s\n' "${commit_output}" | sed -n 1p)" in
        allow | ask | deny) ;;
        *) commit_output="$(printf 'ask\n%s\n' '送るcommitの判定のスクリプトが、決まった判定を返しませんでした。')" ;;
      esac
      decision="$(print_stronger_decision "${decision}" "$(printf '%s\n' "${commit_output}" | sed -n 1p)")"
      reason="${reason}$(printf '%s\n' "${commit_output}" | sed -n 2p)"
      pinned_command="$(printf '%s\n' "${commit_output}" | sed -n 3p)"
    fi
  fi
  printf '%s\n%s\n%s\n' "${decision}" "${reason}" "${pinned_command}"
  exit 0
}

main "$@"
