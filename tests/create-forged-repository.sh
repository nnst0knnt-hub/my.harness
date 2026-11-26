#!/bin/bash
# CIの設定のファイルの中身だけが違う2つのcommitを持つリポジトリを作り、手元のオブジェクトを偽る関数を持つ。判定のスクリプトが、サンドボックスの中から偽れるオブジェクトを本物として読まないことを確かめるためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# tests/test-print-tree-entry.shが、tests/create-case-repository.shとtests/create-remote-case-repository.shのあとにsourceする。

# リポジトリの隣のHOMEでgitを動かし、出力を出す。
# 引数：リポジトリのフォルダー、gitの引数
# 出力：gitの標準出力
# 戻り値：gitの戻り値
run_case_git() {
  local directory="$1"
  shift
  HOME="${directory%/*}/home" GIT_CONFIG_NOSYSTEM=1 git -C "${directory}" "$@" 2> /dev/null
}

# ブランチaとbのcommitがあるリポジトリを作る。2つのcommitは、.github/workflows/ci.ymlの中身だけが違う。HOMEは、リポジトリの隣のhomeにする。
# 引数：作るフォルダー、オブジェクトの形式（sha1、sha256）
# 出力：なし
# 戻り値：作れたら0、作れなければ1
create_tree_repository() {
  local home="${1%/*}/home"
  rm -rf "$1" && create_test_home "${home}"
  run_test_git "${home}" init -q --object-format="$2" "$1" || return 1
  mkdir -p "$1/.github/workflows" && printf '%s\n' 'on: push' > "$1/.github/workflows/ci.yml"
  printf '%s\n' 'test:' > "$1/.gitlab-ci.yml"
  run_test_git "${home}" -C "$1" add -A && run_test_git "${home}" -C "$1" commit -q -m a || return 1
  run_test_git "${home}" -C "$1" branch a || return 1
  printf '%s\n' 'on: pull_request' > "$1/.github/workflows/ci.yml"
  run_test_git "${home}" -C "$1" commit -q -am b && run_test_git "${home}" -C "$1" branch b
}

# オブジェクトのファイルを、ほかのオブジェクトのファイルで置き換える。
# 引数：リポジトリのフォルダー、置き換えるオブジェクトのSHA、中身にするオブジェクトのSHA
# 出力：なし
# 戻り値：cpの戻り値
copy_object_file() {
  local objects="$1/.git/objects"
  rm -f "${objects}/${2:0:2}/${2:2}" && cp "${objects}/${3:0:2}/${3:2}" "${objects}/${2:0:2}/${2:2}"
}

# aのcommitをbのように見せる偽装をする。
# 引数：リポジトリのフォルダー、偽装の形（tests/print-tree-entry-case-list.tsvの3列目）
# 出力：なし
# 戻り値：0
forge_repository() {
  local commit_a commit_b tree_a tree_b graph="$1/.git/objects/info/commit-graph" hex
  commit_a="$(run_case_git "$1" rev-parse a)" && commit_b="$(run_case_git "$1" rev-parse b)"
  tree_a="$(run_case_git "$1" rev-parse 'a^{tree}')" && tree_b="$(run_case_git "$1" rev-parse 'b^{tree}')"
  case "$2" in
    replace) run_case_git "$1" replace "${commit_a}" "${commit_b}" ;;
    graft) printf '%s %s\n' "${commit_a}" "${commit_b}" > "$1/.git/info/grafts" ;;
    commit-graph)
      run_case_git "$1" commit-graph write --reachable
      hex="$(od -An -v -tx1 "${graph}" | LC_ALL=C tr -d ' \n')"
      hex="${hex/${tree_a}/${tree_b}}"
      rm -f "${graph}"
      # 書式の文字列は、16進の数字から作った\xHHだけで、%を含まない。
      # shellcheck disable=SC2059
      printf "$(printf '%s' "${hex}" | LC_ALL=C sed 's/../\\x&/g')" > "${graph}"
      ;;
    loose-tree) copy_object_file "$1" "${tree_a}" "${tree_b}" ;;
    loose-commit) copy_object_file "$1" "${commit_a}" "${commit_b}" ;;
  esac
}
