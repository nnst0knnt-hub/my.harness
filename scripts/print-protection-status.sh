#!/bin/bash
# 導入先のフォルダー（省くと今のフォルダー）を受け取り、このPCと導入先で、ハーネスの保護のどれが働き、どれが働かないかと、直し方を標準出力に出す。人が、導入のときと、セッションの始めに働かない保護を伝えられたときに、原因を知るためである。
# 終了コードは、0がすべて働く、1が働かないか確かめられない保護がある、2が使い方の誤りである。[確かめる]の項目は、終了コードに入れない。
# 人が、Claude Codeの外のシェルで動かす。サンドボックスの依存が無いPCでは、Claude Codeが起動しないためである。手順は、docs/setup-guide.mdに書く。
set -u -o pipefail

HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly HARNESS_ROOT
readonly GUIDE_SECTION="${HARNESS_ROOT}/docs/setup-guide.mdの節「働かない保護を直す」"
problem_count=0
check_count=0

# 1つの項目を出し、働かない項目と確かめる項目を数える。
# 引数：状態（働く、働かない、確かめる、わからない、見ない）、項目、起きること、直し方（「-」は無し）
# 出力：状態と項目の行、起きることの行、直し方の行
# 戻り値：0
print_status_row() {
  printf '[%s] %s\n  %s\n' "$1" "$2" "$3"
  if [ "$4" != '-' ]; then
    printf '  直し方：%s\n' "$4"
  fi
  case "$1" in
    働かない | わからない) problem_count=$((problem_count + 1)) ;;
    確かめる) check_count=$((check_count + 1)) ;;
  esac
}

# サンドボックスの状態の1語を、項目の行にして出す。
# 引数：scripts/print-sandbox-state.shの出力
# 出力：項目の行
# 戻り値：0
print_sandbox_row() {
  local item='サンドボックス' leak='git -C . pushのようにフックの対象に当たらない書き方のpushと、シェルからの秘密情報のファイル（例：.env）の読み取りが止まりません。'
  case "$1" in
    enabled) print_status_row 働く "${item}" '設定のファイルで有効で、シェルのコマンドの読み書きと通信を制限します（--settingsで渡した値は読みません）。' - ;;
    disabled) print_status_row 働かない "${item}" "設定のファイルで有効になっていないので、${leak}" "${GUIDE_SECTION}のとおりに、PCの設定を足してください。導入先の設定がsandbox.enabledをfalseにしているときは、.claude/settings.local.jsonでtrueにしてください（導入先の値が先に当たります）。" ;;
    missing-dependency) print_status_row 働かない "${item}（bubblewrapかsocatが動きません）" "failIfUnavailableがtrueならClaude Codeが起動せず、falseならサンドボックスなしで動くので、${leak}" 'sudo apt-get install bubblewrap socat（Ubuntu、Debian）か、sudo dnf install bubblewrap socat（Fedora）で入れてください。' ;;
    unsupported) print_status_row 働かない "${item}（このOSでは使えません）" "WSL1とWindowsでは、サンドボックスが使えないので、${leak}" 'WSL2、Linux、macOSのどれかで動かしてください。' ;;
    *) print_status_row わからない "${item}" 'jqが動かないか、設定のファイルを読めないので、確かめられません。' 'jqを入れ、設定のファイルのJSONを直してください。' ;;
  esac
}

# 無いものを探すスクリプトの結果を、項目の行にして出す。
# 引数：項目、終了コード、無いものの行、働くときの文、無いときの直し方、確かめられないときの文、その直し方
# 出力：項目の行と、無いものの行
# 戻り値：0
print_missing_row() {
  if [ "$2" -eq 0 ]; then
    print_status_row 働く "$1" "$4" -
  elif [ -z "$3" ]; then
    print_status_row わからない "$1" "$6" "$7"
  else
    print_status_row 働かない "$1" "次のものが無いか、違います。"$'\n'"$(printf '%s\n' "$3" | sed 's/^/    /')" "$5"
  fi
}

main() {
  local project main_directory state item detail fix missing status
  local setting_file="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/settings.json"
  if [ "$#" -gt 1 ] || ! project="$(cd "${1:-${PWD}}" 2> /dev/null && pwd)"; then
    printf '%s\n' 'print-protection-status.sh: 導入先のフォルダーを1つ渡すか、何も渡さずに導入先の中で動かしてください。' >&2
    exit 2
  fi
  if ! main_directory="$("${BASH}" "${HARNESS_ROOT}/scripts/print-main-worktree-path.sh" "${project}" 2> /dev/null)"; then
    main_directory="${project}"
  fi
  printf 'my.harnessの保護の状態です。\nハーネスの場所：%s\n導入先：%s\n\n' "${HARNESS_ROOT}" "${project}"
  while IFS=$'\t' read -r state item detail fix; do
    print_status_row "${state}" "${item}" "${detail}" "${fix}"
  done < <("${BASH}" "${HARNESS_ROOT}/scripts/print-tool-status.sh")
  print_sandbox_row "$("${BASH}" "${HARNESS_ROOT}/scripts/print-sandbox-state.sh" "${project}" "${main_directory}")"
  missing="$("${BASH}" "${HARNESS_ROOT}/scripts/find-missing-claude-setting.sh" "${setting_file}" \
    "${HARNESS_ROOT}/data/recommended-claude-setting.json" "${HARNESS_ROOT}" 2> /dev/null)"
  status=$?
  print_missing_row "PCの設定（${setting_file}）" "${status}" "${missing}" \
    '勧める権限とサンドボックスの設定が、すべてあります。' "${GUIDE_SECTION}のとおりに足してください。" \
    'jqが動かないか、ファイルを読めないので、確かめられません。' 'jqを入れ、ファイルの権限とJSONの形を確かめてください。'
  while IFS=$'\t' read -r state item detail fix; do
    print_status_row "${state}" "${item}" "${detail}" "${fix}"
  done < <("${BASH}" "${HARNESS_ROOT}/scripts/print-claude-setting-status.sh" "${project}" "${main_directory}")
  if ! git -C "${project}" rev-parse --git-dir > /dev/null 2>&1; then
    print_status_row 見ない '導入先のgitのフック' '導入先のフォルダーがgitのリポジトリの中ではないので、見ません。' -
  else
    missing="$("${BASH}" "${HARNESS_ROOT}/scripts/find-missing-git-hook-setting.sh" "${project}" "${HARNESS_ROOT}" 2> /dev/null)"
    status=$?
    print_missing_row '導入先のgitのフック' "${status}" "${missing}" \
      'pre-pushとpre-commit（ハーネスのリポジトリではcommit-msgも）で、保護するブランチへのpushと、秘密情報を含むcommitとpush（ハーネスのリポジトリではコミットメッセージの止める語も）を止めます。' \
      '導入先でClaude Codeを開き、configure-repositoryで足してください。' \
      'メインの作業フォルダーを求められないか、ハーネスのgitのフックの一覧を読めないので、確かめられません。' 'bareのリポジトリでも、.gitを外に置いたリポジトリのworktreeでもないクローンの中で動かし、ハーネスのdata/git-hook-setting-list.tsvを読めるかを確かめてください。'
  fi
  if [ "${problem_count}" -eq 0 ]; then
    printf '\nすべての保護が働きます。[確かめる]の項目は%s個です。\n' "${check_count}"
    exit 0
  fi
  printf '\n働かないか、確かめられない保護が%s個あります。[確かめる]の項目は%s個です。直し方は、%sにも書いています。\n' \
    "${problem_count}" "${check_count}" "${GUIDE_SECTION}"
  exit 1
}

main "$@"
