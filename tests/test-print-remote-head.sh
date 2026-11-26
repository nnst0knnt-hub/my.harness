#!/bin/bash
# tests/print-remote-head-case-list.tsvを読み、scripts/print-remote-head.shの出力、終了コード、かかった時間を確かめ、結果を出す。問い合わせの先と、問い合わせられないときと時間を超えたときに比べる元を出さないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-remote-head.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/create-remote-case-repository.sh
source "${TEST_DIRECTORY}/create-remote-case-repository.sh"
readonly SCRIPT="${TEST_DIRECTORY}/../scripts/print-remote-head.sh"
# originのfeat/xに次のcommitを送り、mainへ戻る設定のコマンドである。
readonly NEXT_COMMIT='git checkout -q feat/x && git commit -q --allow-empty -m next && git push -q origin feat/x:feat/x && git checkout -q main'

# リモートへ問い合わせるls-remoteのときだけ、答えずに5秒待って終わる遅いgitを、<フォルダー>/bin/に作る。ほかのとき（URLを求めるls-remote --get-urlを含む）は本物のgitを動かす。
# 待つのを同じプロセスのsleepにするのは、本物のgitと同じく、止めたプロセスのほかに出力をつないだままのプロセスを残さないためである。
# 引数：フォルダー
# 出力：なし
# 戻り値：0
create_slow_git() {
  mkdir -p "$1/bin"
  # 書いたスクリプトの中の$@と$wordは、偽のgitが動くときに読むので、ここでは展開しない。
  # shellcheck disable=SC2016
  printf '#!/bin/sh\nfor word in "$@"; do [ "$word" = --get-url ] && exec "%s" "$@"; done\nfor word in "$@"; do [ "$word" = ls-remote ] && exec sleep 5; done\nexec "%s" "$@"\n' \
    "$(command -v git)" "$(command -v git)" > "$1/bin/git"
  chmod +x "$1/bin/git"
}

main() {
  local work_directory project home description shape git_kind remote limit branch_text expected
  local branches=() output status path started main_id next_id
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  project="${work_directory}/project" && home="${work_directory}/home"
  create_test_home "${home}" && create_slow_git "${work_directory}"
  while IFS=$'\t' read -r description shape git_kind remote limit branch_text expected; do
    case "${description}" in
      '#'* | '') continue ;;
    esac
    create_test_repository "${project}" "${home}" "${NEXT_COMMIT}"
    main_id="$(git -C "${project}" rev-parse main)" && next_id="$(git -C "${project}" rev-parse feat/x)"
    case "${shape}" in
      pushurl)
        run_test_git "${home}" clone -q --bare "${project}-remote.git" "${work_directory}/push.git"
        run_test_git "${home}" -C "${work_directory}/push.git" update-ref refs/heads/main "${next_id}"
        run_test_git "${home}" -C "${project}" config remote.origin.pushurl "${work_directory}/push.git"
        ;;
      missing) run_test_git "${home}" -C "${project}" remote set-url origin "${work_directory}/missing.git" ;;
      # URLのコマンドが動くと、作業のフォルダーにmarkerができる。
      ext) run_test_git "${home}" -C "${project}" config protocol.ext.allow always \
        && run_test_git "${home}" -C "${project}" remote set-url origin "ext::sh -c touch% ${work_directory}/marker" ;;
      insteadof-ext)
        run_test_git "${home}" -C "${project}" config protocol.ext.allow always
        run_test_git "${home}" -C "${project}" config "url.ext::sh -c touch% ${work_directory}/marker.insteadOf" "${project}-remote.git"
        run_test_git "${home}" -C "${project}" config "url.${project}-remote.git.pushInsteadOf" "${project}-remote.git"
        ;;
      http) run_test_git "${home}" -C "${project}" remote set-url origin 'http://example.invalid/a/b.git' ;;
      tail-ref)
        run_test_git "${home}" -C "${project}-remote.git" update-ref refs/tags/HEAD "${next_id}"
        run_test_git "${home}" -C "${project}-remote.git" update-ref refs/tags/feat/new "${next_id}"
        ;;
    esac
    branches=()
    [ "${branch_text}" = '-' ] || IFS=',' read -r -a branches <<< "${branch_text}"
    path="${PATH}"
    [ "${git_kind}" = 'ふつう' ] || path="${work_directory}/bin:${PATH}"
    started="$(date +%s)"
    output="$(HOME="${home}" GIT_CONFIG_NOSYSTEM=1 PATH="${path}" "${BASH}" "${SCRIPT}" "${project}" "${remote}" "${limit}" \
      ${branches[@]+"${branches[@]}"} 2> /dev/null)"
    status=$?
    # 上限を超えたときに、遅いgitが終わるまで待たないことも確かめる。
    if [ "$(($(date +%s) - started))" -ge 4 ]; then
      status='待った'
    fi
    output="${output//${main_id}/@main@}" && output="${output//${next_id}/@next@}"
    [ ! -e "${work_directory}/marker" ] || status="${status} marker=yes"
    expect "${description}" "${expected}" "$(printf '%s\n' "${output:-なし}" | paste -s -d ';' -) ${status}"
    rm -rf "${work_directory}/push.git" "${work_directory}/marker"
  done < "${TEST_DIRECTORY}/print-remote-head-case-list.tsv"
  expect 'リモートと上限の秒数を渡さないと、使い方の誤りで止める。' '2' \
    "$("${BASH}" "${SCRIPT}" "${project}" origin 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
