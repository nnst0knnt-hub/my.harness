#!/bin/bash
# tests/run-test-suite.shのコピーを一時のフォルダーに置き、別のgitのリポジトリ、gitの外、コピーのtests/の中から動かして、どのリポジトリを確かめたかと終了コードを確かめる。失敗した確認を集めることと、ShellCheckを飛ばしたときの最後の行も確かめる。動かした作業フォルダーに関わらずスクリプトのあるリポジトリを確かめることと、失敗した確認と飛ばした確認を最後の行だけを読む人が見落とさないことを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もrun-test-suite.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
# shellcheck source=tests/create-suite-copy.sh
source "${TEST_DIRECTORY}/create-suite-copy.sh"

main() {
  local work_directory copy
  # ケースは、動かす場所とコピーの置き場所が1件ずつ違い、CONTRIBUTING.mdの節「テスト」がデータのファイルに分けると決めた判定の一覧ではないので、ここに書く。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  copy="${work_directory}/copy"
  create_suite_copy "${work_directory}" "${copy}" git
  run_test_git "${work_directory}" init -q "${work_directory}/other"
  mkdir -p "${work_directory}/outside"
  expect '別のgitのリポジトリから絶対パスで動かすと、スクリプトのあるリポジトリを確かめて、0で終わる。' '0 1' \
    "$(print_suite_result "${work_directory}" "${work_directory}/other" "${copy}/tests/run-test-suite.sh" "${copy}")"
  expect 'gitの外から絶対パスで動かすと、スクリプトのあるリポジトリを確かめて、0で終わる。' '0 1' \
    "$(print_suite_result "${work_directory}" "${work_directory}/outside" "${copy}/tests/run-test-suite.sh" "${copy}")"
  expect 'スクリプトのあるtests/の中から相対パスで動かすと、そのリポジトリを確かめて、0で終わる。' '0 1' \
    "$(print_suite_result "${work_directory}" "${copy}/tests" run-test-suite.sh "${copy}")"
  create_suite_copy "${work_directory}" "${work_directory}/outside/copy" none
  expect 'gitの外に置いたスクリプトは、使い方の誤りの2で終わる。' '2 0' \
    "$(print_suite_result "${work_directory}" "${work_directory}/outside/copy" tests/run-test-suite.sh \
      "${work_directory}/outside/copy")"
  create_suite_copy "${work_directory}" "${work_directory}/other/sub" none
  expect 'gitのリポジトリの一番上でないフォルダーに置いたスクリプトは、使い方の誤りの2で終わる。' '2 0' \
    "$(print_suite_result "${work_directory}" "${work_directory}/other/sub" tests/run-test-suite.sh \
      "${work_directory}/other/sub")"
  # PCのshellcheckが動くかに左右されないように、0か127で終わる偽のshellcheckと、--versionでだけ0で終わる偽のshellcheckをPATHの先頭に置く。
  mkdir -p "${work_directory}/working/bin" "${work_directory}/broken/bin" "${work_directory}/finding/bin"
  printf '#!/bin/sh\nexit 0\n' > "${work_directory}/working/bin/shellcheck"
  printf '#!/bin/sh\nexit 127\n' > "${work_directory}/broken/bin/shellcheck"
  # 書いたスクリプトの中の$1は、偽のshellcheckが動くときに読む引数なので、ここでは展開しない。
  # shellcheck disable=SC2016
  printf '#!/bin/sh\n[ "$1" = --version ]\n' > "${work_directory}/finding/bin/shellcheck"
  chmod +x "${work_directory}/working/bin/shellcheck" "${work_directory}/broken/bin/shellcheck" \
    "${work_directory}/finding/bin/shellcheck"
  expect 'ShellCheckが動けば、すべての確認が通ったことを最後の行に出し、0で終わる。' '0|すべての確認が通りました。|-' \
    "$(print_suite_summary "${work_directory}" "${copy}" "${work_directory}/working/bin")"
  expect 'ShellCheckを動かせなければ、飛ばしたことを最後の行に出し、0で終わる。' \
    '0|ShellCheckを飛ばしたほかは、すべての確認が通りました。|-' \
    "$(print_suite_summary "${work_directory}" "${copy}" "${work_directory}/broken/bin")"
  expect 'ShellCheckが動いて1で終われば、ShellCheckを失敗に挙げ、1で終わる。' '1|== ShellCheck|ShellCheck' \
    "$(print_suite_summary "${work_directory}" "${copy}" "${work_directory}/finding/bin")"
  create_suite_copy "${work_directory}" "${work_directory}/failing" git
  printf '#!/bin/bash\nexit 1\n' > "${work_directory}/failing/tests/test-fail.sh"
  expect '1で終わるテストがあれば、その名前を失敗に挙げ、1で終わる。' '1|== ShellCheck|tests/test-fail.sh' \
    "$(print_suite_summary "${work_directory}" "${work_directory}/failing" "${work_directory}/working/bin")"
  create_suite_copy "${work_directory}" "${work_directory}/no-match" git
  printf '対象の無い確認\tlinters/none.sh\tno-such-file.zzz\n' >> "${work_directory}/no-match/tests/linter-list.tsv"
  expect 'どのファイルにも合わないパターンの確認があれば、その名前を失敗に挙げ、1で終わる。' '1|== ShellCheck|対象の無い確認' \
    "$(print_suite_summary "${work_directory}" "${work_directory}/no-match" "${work_directory}/working/bin")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
