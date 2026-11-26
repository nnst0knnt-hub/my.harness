#!/bin/bash
# scripts/print-ambiguous-word-usage.shを、ASCIIの確かめる語の一覧を置いたハーネスのコピーと、一時の導入先で動かし、語ごとの勧める種類と場所を確かめる。導入のときに、業務の言葉と重なる語だけを、場所を添えて人に示せることを確かめるためである。
# 終了コードは、0がすべて通った、1が1件以上失敗した、である。
# tests/run-test-suite.shが動くたびに呼び、人もprint-ambiguous-word-usage.shを変えたあとに呼ぶ。
set -u -o pipefail

TEST_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly TEST_DIRECTORY
# shellcheck source=tests/expect.sh
source "${TEST_DIRECTORY}/expect.sh"
# shellcheck source=tests/create-case-repository.sh
source "${TEST_DIRECTORY}/create-case-repository.sh"
readonly SCRIPT_DIRECTORY="${TEST_DIRECTORY}/../scripts"
# 語は、どれもほかの語の一部にならないものにする。一部になると、ほかの語のファイルでも使われた語になるためである。
readonly AMBIGUOUS_WORD_LIST='alpha\tr\nbravo\tr\ncharlie\tr\ndelta\tr\necho\tr\techoes\nfoxtrot\tr\ngolf\tr\nhotel\tr\n'

# 語ごとに置き場所を変えたファイルを持つ導入先を作り、ファイルを追跡する。
# 引数：ケースのフォルダー
# 出力：なし
# 戻り値：作れたら0、gitの操作が失敗したら1
create_usage_project() {
  local project="$1/project"
  run_test_git "$1" init -q "${project}" || return 1
  mkdir -p "${project}/src" "${project}/docs" "${project}/.harness/docs"
  printf 'x\nalpha\n' > "${project}/src/a.txt"
  printf 'bravo\n' > "${project}/.harness/docs/b.md"
  printf 'charlie\0\n' > "${project}/bin.dat"
  # リンク先は追跡せず、リンクだけを追跡する。リンクをたどると、deltaが使われた語になる。
  printf 'delta\n' > "${project}/target.txt"
  ln -s target.txt "${project}/link.txt"
  printf 'echoes\n' > "${project}/docs/e.md"
  printf 'foxtrot\nfoxtrot\nfoxtrot\nfoxtrot\n' > "${project}/docs/f.md"
  printf 'golf\n' > "${project}/docs/g.md"
  run_test_git "$1" -C "${project}" add src docs .harness bin.dat link.txt
}

# 出力から、パターンが渡した語の行を出す。
# 引数：スクリプトの出力、語
# 出力：タブを「/」にした行。無ければ「-」
# 戻り値：0
print_word_row() {
  printf '%s\n' "$1" | LC_ALL=C awk -F '\t' -v word="$2" '
    $2 == word { gsub(/\t/, "/"); print; found = 1 }
    END { if (!found) print "-" }'
}

main() {
  local work_directory harness usage project output status
  # ケースは、1つの導入先で語ごとの扱いを比べるもので、CONTRIBUTING.mdの節「テスト」がデータのファイルに分けると決めた判定の一覧ではないので、ここに書く。
  work_directory="$(cd "$(mktemp -d)" && pwd -P)"
  harness="${work_directory}/harness"
  usage="${harness}/scripts/print-ambiguous-word-usage.sh"
  project="${work_directory}/project"
  mkdir -p "${harness}/scripts" "${harness}/data"
  cp "${SCRIPT_DIRECTORY}/print-ambiguous-word-usage.sh" "${SCRIPT_DIRECTORY}/print-project-word-list.sh" \
    "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "${harness}/scripts/"
  printf '%b' "${AMBIGUOUS_WORD_LIST}" > "${harness}/data/ambiguous-word-list.txt"
  create_usage_project "${work_directory}"
  output="$("${BASH}" "${usage}" "${project}" 2> /dev/null)"
  expect '導入先ごとの語の一覧を置く前は、あとで答える語にも、ambiguous-allowedと場所を付ける。' \
    'ambiguous-allowed/golf/docs/g.md:1' "$(print_word_row "${output}" golf)"
  mkdir -p "${project}/.harness/rules"
  printf '%b' 'ambiguous-allowed\tgolf\n' > "${project}/.harness/rules/word-list.txt"
  # 人のgitの色の設定でも、場所を出せることを確かめるため、色を付ける設定で動かす。
  output="$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=color.ui GIT_CONFIG_VALUE_0=always "${BASH}" "${usage}" "${project}" 2> /dev/null)"
  status=$?
  expect '導入先の語を探せたら、0で終わる。' '0' "${status}"
  expect '使われた語には、人のgitの色の設定があっても、ambiguous-allowedと、パスと行の場所を付ける。' \
    'ambiguous-allowed/alpha/src/a.txt:2' "$(print_word_row "${output}" alpha)"
  expect '.harness/の中だけで使われた語は、ambiguous-bannedにする。' 'ambiguous-banned/bravo' \
    "$(print_word_row "${output}" bravo)"
  expect 'バイナリーのファイルだけで使われた語は、ambiguous-bannedにする。' 'ambiguous-banned/charlie' \
    "$(print_word_row "${output}" charlie)"
  expect 'シンボリックリンクの先だけで使われた語は、ambiguous-bannedにする。' 'ambiguous-banned/delta' \
    "$(print_word_row "${output}" delta)"
  expect '除く形の熟語だけで使われた語は、ambiguous-bannedにする。' 'ambiguous-banned/echo' \
    "$(print_word_row "${output}" echo)"
  expect '4か所以上で使われた語は、3か所まで示す。' 'ambiguous-allowed/foxtrot/docs/f.md:1/docs/f.md:2/docs/f.md:3' \
    "$(print_word_row "${output}" foxtrot)"
  expect '導入先ごとの語の一覧で答えた語は、出さない。' '-' "$(print_word_row "${output}" golf)"
  expect 'どこにも無い語は、ambiguous-bannedにする。' 'ambiguous-banned/hotel' "$(print_word_row "${output}" hotel)"
  mkdir -p "${work_directory}/outside"
  expect 'gitの外のフォルダーを渡すと、1で終わる。' '1' "$(GIT_CEILING_DIRECTORIES="${work_directory}" "${BASH}" \
    "${usage}" "${work_directory}/outside" > /dev/null 2>&1; printf '%s' "$?")"
  expect 'フォルダーを渡さないと、使い方の誤りの2で終わる。' '2' "$("${BASH}" "${usage}" > /dev/null 2>&1; printf '%s' "$?")"
  printf '%b' 'alpha(\tr\n' > "${harness}/data/ambiguous-word-list.txt"
  expect '確かめる語をgit grepで探せなければ、1で終わる。' '1' \
    "$("${BASH}" "${usage}" "${project}" > /dev/null 2>&1; printf '%s' "$?")"
  printf '%b' "${AMBIGUOUS_WORD_LIST}" > "${harness}/data/ambiguous-word-list.txt"
  printf '%b' 'broken\tgolf\n' > "${project}/.harness/rules/word-list.txt"
  expect '導入先ごとの語の一覧に誤りがあれば、表を作らずに1で終わる。' '1' \
    "$("${BASH}" "${usage}" "${project}" 2> /dev/null; printf '%s' "$?")"
  rm -rf "${work_directory}"
  if ! print_expect_summary; then
    exit 1
  fi
  exit 0
}

main "$@"
