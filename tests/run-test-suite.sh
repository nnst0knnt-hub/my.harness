#!/bin/bash
# テスト、linter、ShellCheckをすべて動かし、確認ごとの出力と、失敗した確認の名前を出す。CIと同じ確認を、手元でも1つのコマンドで動かすためである。
# 終了コードは、0がすべて通った（ShellCheckを動かせずに飛ばしたときも含む）、1が1つ以上失敗した、2がスクリプトをgitのリポジトリの一番上のtests/の外に置いた使い方の誤りか、tests/linter-list.tsvを読めないことである。確かめるのは、動かした作業フォルダーに関わらず、スクリプトのあるリポジトリである。
# 人とエージェントが手元の変更のあとに、CIのワークフローがpushのたびに呼ぶ。
set -u -o pipefail

failure_names=()
skipped_shellcheck_text=''

# 追跡しているファイルとまだ追加していないファイルのうち、パターンに合い、今あるものを出す。
# 引数：git ls-filesのパターン（1つ以上、「:!」で始まるものは除くパターン）
# 出力：ファイルのパスを1行に1つ
# 戻り値：0
print_target_file() {
  local file
  # -zなしでは、日本語や記号を含む名前が引用符とエスケープの形で出て、ファイルとして読めない。
  git ls-files -z --cached --others --exclude-standard -- "$@" |
    while IFS= read -r -d '' file; do
      if [ -f "${file}" ]; then
        printf '%s\n' "${file}"
      fi
    done
}

# 1つの確認を動かし、失敗したら確認の名前をfailure_namesに足す。
# 引数：確認の名前、動かすコマンドと引数
# 出力：確認の名前の行と、コマンドの出力
# 戻り値：0
run_and_collect_failure() {
  local name="$1"
  shift
  printf '== %s\n' "${name}"
  if ! "$@"; then
    failure_names+=("${name}")
  fi
}

# ShellCheckを動かし、失敗したら確認の名前をfailure_namesに足す。動かせなければ、飛ばしたことを標準エラーに出し、最後の行に付ける文をskipped_shellcheck_textに入れる。
# 引数：スクリプトのパス（1つ以上）
# 出力：確認の名前の行と、ShellCheckの出力か飛ばしたことの説明
# 戻り値：0
run_shellcheck() {
  printf '%s\n' '== ShellCheck'
  # バージョンの決まっていないmiseのshimのように、コマンドはあっても動かないことがある。
  if ! shellcheck --version > /dev/null 2>&1; then
    printf '%s\n' 'run-test-suite.sh: shellcheckを動かせないので、ShellCheckを飛ばしました。動くshellcheckを入れるか、CIのUbuntuのジョブの結果を見てください。' >&2
    # 最後の行だけを読む人が、飛ばしたことを見落とさないように、最後の行にも書く。
    skipped_shellcheck_text='ShellCheckを飛ばしたほかは、'
    return 0
  fi
  if ! shellcheck -x "$@"; then
    failure_names+=('ShellCheck')
  fi
}

main() {
  local file test_file root_directory name linter pattern_text
  local shell_files=() target_files=() patterns=()
  # 確かめるリポジトリは、作業フォルダーでなく、このスクリプトの場所で決める。作業フォルダーで決めると、別のクローンのスクリプトを絶対パスで動かしたときに、作業フォルダーのリポジトリを確かめるためである。
  # 1つ上のフォルダーがgitのリポジトリの一番上かを、git rev-parseの値と比べて確かめる。サブフォルダーに置いたコピーで、上のリポジトリを確かめないためである。
  if ! cd "$(dirname "$0")/.." || ! root_directory="$(git rev-parse --show-toplevel 2> /dev/null)" \
    || [ "${root_directory}" != "$(pwd -P)" ] || [ ! -r tests/linter-list.tsv ]; then
    printf '%s\n' 'run-test-suite.sh: スクリプトの1つ上のフォルダーがgitのリポジトリの一番上でないか、tests/linter-list.tsvが読めませんでした。ハーネスのリポジトリのtests/run-test-suite.shを動かし、tests/linter-list.tsvがあるかと権限を確かめてください。' >&2
    exit 2
  fi
  while IFS= read -r file; do shell_files+=("${file}"); done < <(print_target_file '*.sh')
  for test_file in tests/test-*.sh; do
    run_and_collect_failure "${test_file}" "${BASH}" "${test_file}"
  done
  # 一覧は3番で読む。linterが一覧を標準入力から読むと、残りの確認が黙って飛ぶためである。
  while IFS=$'\t' read -r name linter pattern_text <&3; do
    read -r -a patterns <<< "${pattern_text}"
    target_files=()
    # 空の配列をset -uのもとで展開すると、bash 4.4より前ではエラーになるので、要素の数を先に見る。
    if [ "${#patterns[@]}" -gt 0 ]; then
      while IFS= read -r file; do target_files+=("${file}"); done < <(print_target_file "${patterns[@]}")
    fi
    # 列の足りない行や、どのファイルにも合わないパターンで、確認が黙って飛ばないように、失敗に数える。
    if [ "${#target_files[@]}" -eq 0 ]; then
      printf '== %s\n' "${name}"
      printf 'run-test-suite.sh: 確認「%s」の対象のファイルがありません。tests/linter-list.tsvの行の列とパターンを確かめてください。\n' "${name}" >&2
      failure_names+=("${name}")
      continue
    fi
    run_and_collect_failure "${name}" "${BASH}" "${linter}" "${target_files[@]}"
  done 3< <(grep -v -e '^#' -e '^$' tests/linter-list.tsv)
  # 空の配列をset -uのもとで展開しないように、「+」の形で渡す。
  run_shellcheck ${shell_files[@]+"${shell_files[@]}"}
  if [ "${#failure_names[@]}" -gt 0 ]; then
    printf 'run-test-suite.sh: 次の%s個の確認が失敗しました。上の出力を見て、直してください。\n' "${#failure_names[@]}" >&2
    printf -- '- %s\n' "${failure_names[@]}" >&2
    exit 1
  fi
  printf '%s%s\n' "${skipped_shellcheck_text}" 'すべての確認が通りました。'
  exit 0
}

main "$@"
