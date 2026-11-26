#!/bin/bash
# 作業フォルダーとメインの作業フォルダーを受け取り、Markdownの節を標準出力に出す。節には、サンドボックスとjqの状態、gitが古いか見つからないときのgitの状態、git push、git fetch、gh、glabの動かし方、git pullの代わり、ファイルの読み書きとコマンドの書き方、終了コードの読み方を書く。エージェントが、働かない保護を人に伝え、確認を求めない作業で確認が出ないようにするためである。
# 終了コードは、いつも0である。hooks/print-session-context.shが、この出力を文脈に入れるためである。
# hooks/print-session-context.shがセッションの始めに呼び、並行の実装役（skills/implement-change/SKILL.mdの節「並行のとき」）が最初に動かす。理由は、.harness/docs/features/protection.mdの節「フック」に書く。
set -u -o pipefail

# ハーネスの場所は、このスクリプトの場所から求める（.harness/docs/architecture.mdの節「配置の理由」）。
HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly HARNESS_ROOT

# サンドボックスの状態の1語を、表に書く文にする。
# 引数：scripts/print-sandbox-state.shの出力
# 出力：表に書く文
# 戻り値：0
print_sandbox_text() {
  case "$1" in
    enabled) printf '%s\n' '有効' ;;
    disabled) printf '%s\n' "設定のファイルで有効になっていない（\`--settings\`で渡した値は読めない）" ;;
    missing-dependency) printf '%s\n' 'bubblewrapかsocatが動かない' ;;
    unsupported) printf '%s\n' 'このOSでは使えない（例：WSL1）' ;;
    *) printf '%s\n' "わからない（\`jq\`が無いか、設定のファイルを読めない）" ;;
  esac
}

# scripts/print-tool-status.shのgitの行の項目を、表に書く文にする。
# 引数：項目（例：gitのバージョン（2.53.0））
# 出力：表に書く文
# 戻り値：0
print_git_text() {
  local version="${1#*（}"
  version="${version%）}"
  if [ "${version}" = '見つかりません' ]; then
    printf '%s\n' '見つからない'
    return 0
  fi
  printf '古い（%s）\n' "${version}"
}

main() {
  local sandbox_state jq_text='ある' git_line git_state='' git_item='' git_fix=''
  if ! jq --version > /dev/null 2>&1; then
    jq_text='無い'
  fi
  sandbox_state="$("${BASH}" "${HARNESS_ROOT}/scripts/print-sandbox-state.sh" "$1" "$2" 2> /dev/null)"
  # バージョンの比べ方を1か所に置くため、環境を確かめるスクリプトが使うscripts/print-tool-status.shを呼ぶ（.harness/docs/features/protection.mdの節「フック」）。
  # 終わりを待ってから読むのは、1行目だけを読んで先に進むと、print-tool-status.shがほかのコマンドを動かしても裏で続き、テストで見つけられないためである。
  git_line="$("${BASH}" "${HARNESS_ROOT}/scripts/print-tool-status.sh" git 2> /dev/null)"
  IFS=$'\t' read -r git_state git_item _ git_fix <<< "${git_line}"
  printf '%s\n\n' '## 環境の状態'
  printf '%s\n%s\n' '| 項目 | 状態 |' '|---|---|'
  printf '| サンドボックス | %s |\n' "$(print_sandbox_text "${sandbox_state}")"
  printf "| \`jq\` | %s |\n" "${jq_text}"
  if [ "${git_state}" = '働かない' ]; then
    printf '| git | %s |\n' "$(print_git_text "${git_item}")"
  fi
  printf '\n%s\n' "\`git push\`、\`git fetch\`、\`gh\`、\`glab\`は、ほかのコマンドとつながず、\`cd\`とリダイレクト（\`2>&1\`を除く）を付けずに、1つで動かす。pushには、リモートと、送り元と送り先のブランチを書く（例：\`git push origin feat/add-x:feat/add-x\`）。\`git pull\`は使わず、\`git fetch origin <向き先のブランチ>\`のあとに\`git merge --ff-only origin/<向き先のブランチ>\`を動かす。向き先のブランチは、PRをマージする先のブランチで、導入先ごとのルールに無ければ\`main\`である。つなぐか、送り先を書かないか、\`git pull\`を動かすと、フックが止める。フックは、\`git push\`、\`git fetch\`、\`glab\`、確認を求める\`gh\`を、gitのフォルダーを固定して外で動かすスクリプト（\`hooks/exec-with-pinned-git-directory.sh\`）の呼び出しに書き換える。そのスクリプトは直接呼ばない（フックが止める）。auto modeとplan modeでは、書き換わる呼び出しを1つの返事に1つだけ置き、その後ろにほかの呼び出しを続けない。同じ返事の中で前の呼び出しが書き換わると、Claude Codeが、あとの呼び出しを判定せずに止めるためである。"
  printf '\n%s\n' "ファイルの読み書きは、シェルのコマンド（例：\`sed -i\`、\`cat > ファイル\`）ではなく、ReadとEditとWriteで行う。コマンドには、\`cd\`、シェルの変数、\`\$(...)\`（例：\`for f in\`の\`\$f\`、\`\$TMPDIR\`）を使わず、パスと値をそのまま書き、作業フォルダーの外のリポジトリには\`git -C <絶対パス>\`を使う。終了コードを見るために\`echo \$?\`をつながない。確認を求めない作業で、確認が出ないようにするためである。Bashのツールは、0以外で終わったコマンドの結果の先頭に\`Exit code\`の行を出すが、\`grep\`と\`git diff --quiet\`のように1で終わっても出さないコマンドがある。行が無いことを0と読まず、そうしたコマンドの結果は出力（例：\`grep -c\`の数、\`git diff --name-only\`の一覧）で読む。"
  if [ "${sandbox_state}" = 'enabled' ] && [ "${jq_text}" = 'ある' ] && [ "${git_state}" != '働かない' ]; then
    exit 0
  fi
  printf '\n%s\n' "働かない保護がある。セッションの最初の返事で、次の段落の働かない保護と、人がClaude Codeの外で\`bash ${HARNESS_ROOT}/scripts/print-protection-status.sh\`を動かすと原因と直し方がわかることを、人に1回伝える。"
  if [ "${sandbox_state}" != 'enabled' ]; then
    printf '\n%s\n' "サンドボックスが働かないので、\`git -C . push\`のようにフックの対象に当たらない書き方のpushが止まらず、シェルから秘密情報のファイル（例：\`.env\`）を読める。"
  fi
  if [ "${jq_text}" = '無い' ]; then
    printf '\n%s\n' "\`jq\`が無いので、フックが判定できず、\`git push\`、\`git fetch\`、\`git pull\`、\`gh\`、\`glab\`のたびに確認が出る。"
  fi
  if [ "${git_state}" = '働かない' ]; then
    printf '\n%s\n' "gitが古いか見つからないので、gitの設定で足したフック（\`pre-push\`、\`pre-commit\`、ハーネスのリポジトリでは\`commit-msg\`も）が動かず、保護するブランチへのpushと、秘密情報を含むcommitとpushと、ハーネスのリポジトリのコミットメッセージの止める語を、gitのフックで止めない。人がClaude Codeの外でするcommitとpushも止まらない。直し方は「${git_fix%。}」と伝える。"
  fi
  exit 0
}

main "$@"
