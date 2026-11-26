#!/bin/bash
# tests/classify-remote-command-case-list.tsvを読み、scripts/classify-remote-command.shの判定を確かめ、結果を出す。判定の規則か保護するブランチの一覧を変えても、次の3つが変わらないことを確かめるためである。確認を求めない作業で確認が出ないこと、リモートへの書き込みで確認が出ること、判定できない形が止まることである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人も判定のスクリプトか保護するブランチの既定の一覧を変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/create-remote-case-repository.sh
source "${TEST_DIRECTORY}/create-remote-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/classify-remote-command.sh"

# 判定のスクリプトを動かし、判定を出す。確認を求めるか止めるのに理由の文が無いときと、理由の文に含むはずの語が無いか、含まないはずの語があるときは、そのことも出す。
# 引数：導入先のフォルダー、printfの%bの形で書いたコマンド（「-」は空のコマンド）、HOMEにするフォルダー、理由の文に含むはずの語（空なら見ない、「!」で始まると含まないはずの語）
# 出力：判定の1行（例：allow、ask 理由なし、deny 理由に「git push fork」なし、ask 理由に「問い合わせ」あり）
# 戻り値：0
print_case_result() {
  local command='' output decision reason
  if [ "$2" != '-' ]; then
    command="$(printf '%b' "$2")"
  fi
  # フックと同じく、Claude Codeの作業フォルダーをCLAUDE_PROJECT_DIRで渡す。
  output="$(HOME="$3" GIT_CONFIG_NOSYSTEM=1 CLAUDE_PROJECT_DIR="$1" "${BASH}" "${SCRIPT}" "$1" "${command}" 2> /dev/null)"
  decision="$(printf '%s\n' "${output}" | sed -n 1p)"
  reason="$(printf '%s\n' "${output}" | sed -n 2p)"
  case "${decision}:${reason}" in
    ask: | deny:) decision="${decision} 理由なし" ;;
    *)
      case "$4" in
        '!'*) case "${reason}" in *"${4#!}"*) decision="${decision} 理由に「${4#!}」あり" ;; esac ;;
        *) case "${reason}" in *"$4"*) ;; *) decision="${decision} 理由に「$4」なし" ;; esac ;;
      esac
      ;;
  esac
  printf '%s\n' "${decision}"
}

main() {
  local work_directory description command branch_text expected setting reason_word directory
  # macOSの一時フォルダーはシンボリックリンクを含み、gitはたどった先のパスを出すので、たどった先で比べる。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  create_test_home "${work_directory}/home"
  create_test_repository "${work_directory}/project" "${work_directory}/home" -
  while IFS=$'\t' read -r description command branch_text expected setting reason_word; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    directory="${work_directory}/project"
    if [ -n "${setting}" ] && [ "${setting}" != '-' ]; then
      directory="${work_directory}/setting"
      if ! create_test_repository "${directory}" "${work_directory}/home" "${setting}"; then
        expect "${description}" "${expected}" '作れなかった'
        continue
      fi
    fi
    create_harness_config "${directory}" "${branch_text}"
    expect "${description}" "${expected}" \
      "$(print_case_result "${directory}" "${command}" "${work_directory}/home" "${reason_word}")"
  done < "${TEST_DIRECTORY}/classify-remote-command-case-list.tsv"
  expect 'コマンドを渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${work_directory}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
