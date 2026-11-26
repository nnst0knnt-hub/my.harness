#!/bin/bash
# tests/run-test-suite.shのコピーを一時のフォルダーに置く関数と、コピーを動かして結果を出す関数を持つ。コピーを作って動かす処理をケースと分け、テストのファイルを100行に収めるためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# tests/test-run-test-suite.shが、tests/create-case-repository.shのあとにsourceする。

SUITE_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/run-test-suite.sh"
readonly SUITE_SCRIPT

# 作業フォルダーを出すだけのテストと、コメントだけのlinterの一覧を置いた、run-test-suite.shのコピーを作る。本物のテストを置かないのは、tests/test-run-test-suite.shをコピーの中から繰り返し呼ばないためである。
# 引数：ケースのフォルダー、コピーを置くフォルダー、gitのリポジトリにするか（gitかnone）
# 出力：なし
# 戻り値：作れたら0、gitの操作が失敗したら1
create_suite_copy() {
  mkdir -p "$2/tests"
  if [ "$3" = git ]; then
    run_test_git "$1" init -q "$2" || return 1
  fi
  cp "${SUITE_SCRIPT}" "$2/tests/"
  printf '%s\n' '# 確かめるlinterは無い。' > "$2/tests/linter-list.tsv"
  printf '%s\n' '#!/bin/bash' \
    '# 作業フォルダーを出す。tests/run-test-suite.shが、どのリポジトリで動いたかを確かめるためである。' \
    '# 終了コードは、いつも0である。' \
    '# tests/test-run-test-suite.shが作るコピーの中で、コピーのrun-test-suite.shが呼ぶ。' 'pwd -P' \
    > "$2/tests/test-print-place.sh"
}

# 渡したフォルダーで、run-test-suite.shのコピーを渡したパスで動かし、結果を出す。
# 引数：ケースのフォルダー、動かすフォルダー、スクリプトのパス（動かすフォルダーからの相対パスか絶対パス）、確かめたはずのリポジトリ
# 出力：「終了コード そのリポジトリの場所の行の数」の1行
# 戻り値：0
print_suite_result() {
  local output status
  # 一時のフォルダーの上にあるリポジトリを、gitの外のケースで読まないように、上を探させない。
  output="$(cd "$2" && GIT_CEILING_DIRECTORIES="$1" "${BASH}" "$3" 2> /dev/null)"
  status=$?
  printf '%s %s\n' "${status}" "$(printf '%s\n' "${output}" | grep -c -x -F -e "$4")"
}

# 渡したフォルダーをPATHの先頭に足して、run-test-suite.shのコピーをコピーの一番上で動かし、結果を出す。
# 引数：ケースのフォルダー、コピーを置いたフォルダー、PATHの先頭に足すフォルダー
# 出力：「終了コード|標準出力の最後の行|標準エラーの「- 」の行の確認の名前（「,」でつなぐ、無ければ「-」）」の1行
# 戻り値：0
print_suite_summary() {
  local output status
  output="$(cd "$2" && PATH="$3:${PATH}" GIT_CEILING_DIRECTORIES="$1" "${BASH}" tests/run-test-suite.sh \
    2> "$1/suite-error.txt")"
  status=$?
  printf '%s|%s|%s\n' "${status}" "$(printf '%s\n' "${output}" | tail -n 1)" "$(awk '
    /^- / { names = names separator substr($0, 3); separator = "," }
    END { print (names == "" ? "-" : names) }' "$1/suite-error.txt")"
}
