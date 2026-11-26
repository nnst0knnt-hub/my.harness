#!/bin/bash
# gitが渡すリモートの名前とURLと、標準入力の送る参照の行（githooksの節「pre-push」の形）を受け取り、保護するブランチへ送る行があれば、そのブランチを標準エラーに出す。pushの書き方によらず、gitが実際に送るブランチで止めるためである。
# 終了コードは、0が保護するブランチへ送る行が無い、1が保護するブランチへ送る行があるか、保護するブランチの一覧を求められない、2が使い方の誤りである。
# gitが、導入先の.git/configのhook.<名前>.commandで、pre-pushのたびに呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitのフック」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

protected_patterns=''

# ブランチの名前が、保護するブランチのパターンのどれかに当たるかを返す。scripts/classify-git-push-refspec.shと同じ比べ方にする。
# 引数：ブランチの名前
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
  done <<< "${protected_patterns}"
  return 1
}

main() {
  local main_directory remote_ref name status=0
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'deny-protected-branch-push.sh: gitのpre-pushのフックとして、リモートの名前とURLを渡して呼んでください。' >&2
    exit 2
  fi
  # gitは、フックを作業フォルダーの一番上で動かす。.harness/configは、worktreeでもメインの作業フォルダーのものを読む。
  if ! main_directory="$("${BASH}" "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "${PWD}" 2> /dev/null)" \
    || ! protected_patterns="$("${BASH}" "${SCRIPT_DIRECTORY}/print-protection-list.sh" "${main_directory}" branch)"; then
    printf 'deny-protected-branch-push.sh: %sから、メインの作業フォルダーか保護するブランチの一覧を求められなかったので、pushを止めました。.harness/configの形と権限を確かめるか、人が確かめてから--no-verifyで送ってください。\n' "${PWD}" >&2
    exit 1
  fi
  # 送り先がブランチでない行（例：タグ）は、保護するブランチに当たらない。ブランチを消す行も、送り先で比べる。
  while read -r _ _ remote_ref _; do
    case "${remote_ref}" in
      refs/heads/*) name="${remote_ref#refs/heads/}" ;;
      *) continue ;;
    esac
    if is_protected_branch "${name}"; then
      printf 'deny-protected-branch-push.sh: 保護するブランチ「%s」へのpushを止めました。作業用のブランチへpushし、PRを作ってください。\n' "${name}" >&2
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
