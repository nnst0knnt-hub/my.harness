#!/bin/bash
# Claude Codeの作業フォルダー（CLAUDE_PROJECT_DIR）を受け取り、そのリポジトリを導入先のリポジトリとみなせる形のときだけ、共通のgitのフォルダーを、たどった先の絶対パスで標準出力に出す。worktreeの.gitを偽のリポジトリに向けても、判定のスクリプトがそのリポジトリを導入先のものとみなさないためである。
# 終了コードは、0が出した、1がみなせない（形が合わない、求められない、空か改行か復帰を含む値）、2が使い方の誤りである。
# scripts/classify-remote-command.shが、判定で求めた場所をexportする前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# Claude Codeがworktreeを作る既定の場所で、メインの作業フォルダーからの相対パスである。
readonly WORKTREE_PATH='/.claude/worktrees/'

# 場所が、導入先のリポジトリとみなす2つの形のどちらかかを返す。
# 引数：CLAUDE_PROJECT_DIRのたどった先のパス、gitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上
# 出力：なし
# 戻り値：形が合えば0、合わなければ1
is_project_repository() {
  local project="$1" git_directory="$2" common_directory="$3" toplevel="$4" main_directory
  # 場所はどれもprint-git-directory.shがたどった先（pwd -P）の字なので、リンクの.gitは、たどった先の字が<M>/.gitか一番上の.gitと合わずに外れる。
  case "${project}" in
    # Claude Codeのworktreeでは、メインの作業フォルダーをパスの字から求める。エージェントが書ける.gitのファイルとgit worktree listを使わないためである。
    *"${WORKTREE_PATH}"*)
      main_directory="${project%%"${WORKTREE_PATH}"*}"
      [ "${common_directory}" = "${main_directory}/.git" ] \
        && [ "${git_directory%/*}" = "${common_directory}/worktrees" ]
      ;;
    # ほかでは、一番上の.gitのフォルダーのリポジトリだけにする。偽のcore.worktreeは一番上を動かすので、CLAUDE_PROJECT_DIRがその中にあるかも見る。
    *)
      [ "${git_directory}" = "${toplevel}/.git" ] && [ "${common_directory}" = "${git_directory}" ] \
        && case "${project}/" in "${toplevel}/"*) true ;; *) false ;; esac
      ;;
  esac
}

main() {
  local project output git_directory common_directory toplevel
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-project-common-directory.sh: Claude Codeの作業フォルダーを1つだけ渡してください。' >&2
    exit 2
  fi
  # 空の値でcdすると今のフォルダーに残り、ほかのリポジトリを出すので、求めない。
  case "$1" in
    '' | *$'\n'* | *$'\r'*) exit 1 ;;
  esac
  if ! project="$(cd "$1" 2> /dev/null && pwd -P)"; then
    exit 1
  fi
  # フックの環境の変数と、判定のスクリプトがexportした場所に引かれず、CLAUDE_PROJECT_DIRのリポジトリを求める。
  if ! output="$(env -u GIT_DIR -u GIT_COMMON_DIR -u GIT_WORK_TREE "${BASH}" "${SCRIPT_DIRECTORY}/print-git-directory.sh" "${project}" 2> /dev/null)"; then
    exit 1
  fi
  { IFS= read -r git_directory && IFS= read -r common_directory && IFS= read -r toplevel; } <<< "${output}"
  if ! is_project_repository "${project}" "${git_directory}" "${common_directory}" "${toplevel}"; then
    exit 1
  fi
  printf '%s\n' "${common_directory}"
  exit 0
}

main "$@"
