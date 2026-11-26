#!/bin/bash
# 渡したフォルダーから、メインの作業フォルダー（worktreeではなく、もとのクローンの作業フォルダー）を求め、そのパスを標準出力に出す。worktreeの中でも、導入先の.harness/をメインの作業フォルダーから読むためである。
# 終了コードは、0が求められた、1が求められない（gitの外、bareのリポジトリ、.gitを外に置いたリポジトリのworktree）、2が使い方の誤りである。
# hooks/print-session-context.shが、セッションの始めに呼ぶ。scripts/classify-remote-command.sh、scripts/deny-protected-branch-push.sh、scripts/find-harness-repository.sh、scripts/find-missing-git-hook-setting.sh、scripts/print-ambiguous-word-usage.sh、scripts/print-protection-status.sh、scripts/print-word-list.shも、メインの作業フォルダーが要るときに呼ぶ。
set -u -o pipefail

# フォルダーで動かしたgit rev-parseが出すパスを、絶対パスにして出す。
# 引数：フォルダーのパス、git rev-parseのオプション
# 出力：絶対パス
# 戻り値：求められたら0、gitの外なら0以外
print_absolute_git_path() {
  # git 2.31より古いgitでも絶対パスで比べられるよう、--path-format=absoluteを使わず、cdとpwd -Pで求める。
  (cd "$1" 2> /dev/null && directory="$(git rev-parse "$2" 2> /dev/null)" && cd "${directory}" && pwd -P)
}

main() {
  local git_directory common_directory main_path
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-main-worktree-path.sh: フォルダーを1つだけ渡してください。メインの作業フォルダーを求めるフォルダーを、引数に渡してください。' >&2
    exit 2
  fi
  if ! git_directory="$(print_absolute_git_path "$1" --git-dir)" \
    || ! common_directory="$(print_absolute_git_path "$1" --git-common-dir)"; then
    printf 'print-main-worktree-path.sh: %sは、gitのリポジトリの中ではありません。今の作業フォルダーを使ってください。\n' "$1" >&2
    exit 1
  fi
  # worktreeの外では、.gitの場所（--git-dir）と、worktreeで共有する場所（--git-common-dir）が同じになる。
  # 作業フォルダーの一番上を、.gitの場所からでなくgitに聞くのは、.gitを外に置いたリポジトリとサブモジュールで誤らないためである。
  if [ "${git_directory}" = "${common_directory}" ]; then
    if ! git -C "$1" rev-parse --show-toplevel 2> /dev/null; then
      printf 'print-main-worktree-path.sh: %sは、作業フォルダーの無いbareのリポジトリです。今の作業フォルダーを使ってください。\n' "$1" >&2
      exit 1
    fi
    exit 0
  fi
  # git worktree listは、メインの作業フォルダーを最初に出す。bareのリポジトリでは2行目にbareと出し、
  # .gitを外に置いたリポジトリでは.gitの場所を出すので、bareか、そこに.gitが無ければ求められないとする。
  # bareを2行目で見るのは、.gitという名前のbareのリポジトリでは、最初の行の場所に.git（bareのリポジトリ）があるためである。
  # 外に置いた.gitの名前が.gitのときと、.gitの名前が.gitのままcore.worktreeで作業フォルダーを外に置いたときは、.gitの親のフォルダーを出す。
  # 理由は、.harness/docs/features/harness-folder.mdの節「前提」と節「判断」に書く。
  main_path="$(git -C "$1" worktree list --porcelain 2> /dev/null | awk '
    NR == 1 && sub(/^worktree /, "") { path = $0 }
    NR == 2 && $0 == "bare" { path = "" }
    END { print path }')"
  if [ -z "${main_path}" ] || [ ! -e "${main_path}/.git" ]; then
    printf 'print-main-worktree-path.sh: %sのメインの作業フォルダーを求められませんでした。bareのリポジトリか、.gitを外に置いたリポジトリのworktreeです。今の作業フォルダーを使ってください。\n' "$1" >&2
    exit 1
  fi
  printf '%s\n' "${main_path}"
  exit 0
}

main "$@"
