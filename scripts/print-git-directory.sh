#!/bin/bash
# フォルダーを受け取り、そこで動くgitが使うgitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上を、たどった先の絶対パスで1行ずつ標準出力に出す。判定の中のgitと、サンドボックスの外で動かすコマンドに、同じ場所を渡すためである。
# 終了コードは、0が出した、1が求められない（gitの外、bareのリポジトリ、どれかのパスに改行か復帰がある）、2が使い方の誤りである。
# scripts/classify-remote-command.sh、scripts/find-git-setting-in-working-tree.sh、scripts/print-project-common-directory.shが呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail

# フォルダーでgit rev-parseが出す場所に移り、たどった先の絶対パスを出す。git 2.31より古いgitでも絶対パスで比べられるよう、--path-format=absoluteを使わない。
# 引数：フォルダー、git rev-parseのオプション
# 出力：たどった先の絶対パス
# 戻り値：求められたら0、gitが失敗したか空の場所を出したら1
print_resolved_path() {
  local path
  # cd "$(git …)"の形では、gitが失敗しても、空の場所へのcdが成功して今のフォルダーを出すので、gitの戻り値を先に見る。
  if ! path="$(cd "$1" && git rev-parse "$2" 2> /dev/null)" || [ -z "${path}" ]; then
    return 1
  fi
  (cd "$1" && cd "${path}" && pwd -P)
}

main() {
  local git_directory common_directory toplevel
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-git-directory.sh: フォルダーを1つだけ渡してください。' >&2
    exit 2
  fi
  if ! toplevel="$(print_resolved_path "$1" --show-toplevel)" \
    || ! git_directory="$(print_resolved_path "$1" --git-dir)" \
    || ! common_directory="$(print_resolved_path "$1" --git-common-dir)"; then
    printf 'print-git-directory.sh: %sで、gitのフォルダーと作業フォルダーの一番上を求められませんでした。gitのリポジトリの作業フォルダーの中で動かしてください。\n' "$1" >&2
    exit 1
  fi
  # 1行に1つで出すので、改行と復帰を含むパスは出さない。$(...)は最後の改行を消すので、渡したフォルダーも見る。
  case "$1${git_directory}${common_directory}${toplevel}" in
    *$'\n'* | *$'\r'*)
      printf '%s\n' 'print-git-directory.sh: パスに改行か復帰があるので、1行ずつ出せません。改行と復帰の無いパスのリポジトリで動かしてください。' >&2
      exit 1
      ;;
  esac
  printf '%s\n%s\n%s\n' "${git_directory}" "${common_directory}" "${toplevel}"
  exit 0
}

main "$@"
