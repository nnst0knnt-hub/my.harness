#!/bin/bash
# テストのケースごとに、導入先のリポジトリと、決まった字数のファイルを作る関数を持つ。worktreeや.gitの置き場所の違う導入先を、どのテストでも同じ形で作るためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# 一時のリポジトリを作るtests/のテスト（例：tests/test-print-session-context.sh）が、始めにsourceする。

# テストのためのgitを動かす。人のgitの設定（例：署名、フック）に左右されないよう、HOMEを空のフォルダーにする。
# 引数：HOMEにするフォルダー、gitの引数
# 出力：なし
# 戻り値：gitの戻り値
run_test_git() {
  local home="$1"
  shift
  HOME="${home}" GIT_CONFIG_NOSYSTEM=1 git -c user.name=test -c user.email=test@example.com \
    -c commit.gpgsign=false -c protocol.file.allow=always "$@" > /dev/null 2>&1
}

# 文字を並べたファイルを作る。40字ごとに改行を入れ、最後の行も改行で終える。
# 引数：作るファイルのパス、改行を含む字数（「-」は作らない、「!」は読めないファイル、「@」はシンボリックリンク）
# 出力：なし
# 戻り値：0
create_text_file() {
  if [ "$2" = '-' ]; then
    return 0
  fi
  mkdir -p "$(dirname "$1")"
  if [ "$2" = '!' ]; then
    : > "$1" && chmod 000 "$1"
    return 0
  fi
  if [ "$2" = '@' ]; then
    printf '%s\n' 'SECRET=linked' > "$1.target" && ln -s "$1.target" "$1"
    return 0
  fi
  # 本文を複数の行にするのは、フックが本文の一部の行だけを出したときに、テストで気づくためである。最後の行は空にしない。
  awk -v count="$2" 'BEGIN {
    for (i = 1; i < count; i++) printf "%s", (i % 41 == 0 && i < count - 1) ? "\n" : "あ"
    print "" }' > "$1"
}

# ケースの導入先のリポジトリを作り、フックを動かすフォルダーを出す。導入先は、どの場所でもケースのフォルダーのprojectにする。
# 引数：ケースのフォルダー、場所（git、subfolder、worktree、claude-worktree、separate、separate-worktree、submodule、bare、bare-dot-git-worktree、外、無い）。worktreeはprojectの隣、claude-worktreeはClaude Codeの既定の場所（project/.claude/worktrees/x）に作る
# 出力：フックを動かすフォルダーのパス
# 戻り値：作れたら0、gitの操作が1つでも失敗したか、動かすフォルダーが無ければ1（「無い」の場所を除く）。作れなかったケースが、求められないことを期待するケースとして通らないようにするためである。
create_case_repository() {
  local project="$1/project" run_directory="$1/project"
  # commitは、リポジトリを作った場所でだけ動かす。gitの外で動かすと、上のフォルダーのリポジトリに入るためである。
  case "$2" in
    git | subfolder | worktree | claude-worktree)
      run_test_git "$1" init -q "${project}" || return 1
      run_test_git "$1" -C "${project}" commit -q --allow-empty -m init || return 1
      ;;
    separate | separate-worktree)
      run_test_git "$1" init -q --separate-git-dir="$1/store" "${project}" || return 1
      run_test_git "$1" -C "${project}" commit -q --allow-empty -m init || return 1
      ;;
    submodule)
      run_test_git "$1" init -q "$1/origin" || return 1
      run_test_git "$1" -C "$1/origin" commit -q --allow-empty -m init || return 1
      run_test_git "$1" init -q "$1" || return 1
      run_test_git "$1" -C "$1" submodule add -q "$1/origin" project || return 1
      ;;
    bare-dot-git-worktree)
      run_test_git "$1" init -q "$1/origin" || return 1
      run_test_git "$1" -C "$1/origin" commit -q --allow-empty -m init || return 1
      run_test_git "$1" clone -q --bare "$1/origin" "${project}/.git" || return 1
      run_test_git "$1" -C "${project}/.git" worktree add -q "$1/worktree" || return 1
      ;;
    bare) run_test_git "$1" init -q --bare "${project}" || return 1 ;;
    外) mkdir -p "${project}" ;;
  esac
  case "$2" in
    subfolder) run_directory="${project}/src" && mkdir -p "${run_directory}" ;;
    worktree | separate-worktree)
      run_test_git "$1" -C "${project}" worktree add -q "$1/worktree" || return 1
      run_directory="$1/worktree"
      ;;
    claude-worktree)
      run_test_git "$1" -C "${project}" worktree add -q "${project}/.claude/worktrees/x" || return 1
      run_directory="${project}/.claude/worktrees/x"
      ;;
    bare-dot-git-worktree) run_directory="$1/worktree" ;;
    無い) printf '%s\n' "$1/missing" && return 0 ;;
  esac
  # 作る場所がずれたときも1を返す。worktreeの.harness/を作る前に確かめるのは、mkdir -pがworktreeのフォルダーも作るためである。
  if [ ! -d "${run_directory}" ]; then
    return 1
  fi
  case "$2" in
    worktree | separate-worktree)
      # worktreeにも別の字数の.harness/を置き、フックがメインの作業フォルダーのものを読むかを確かめる。
      create_text_file "${run_directory}/.harness/rules/always-read.md" 50
      create_text_file "${run_directory}/.harness/docs/README.md" 50
      ;;
  esac
  printf '%s\n' "${run_directory}"
}
