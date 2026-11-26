#!/bin/bash
# 導入先のフォルダーとハーネスの場所を受け取り、data/git-hook-setting-list.tsvのgitのフックのうち、導入先で読むgitの設定（導入先の.git/config、PCとシステムの設定）に無いか違うものを、1行に1つ標準出力に出す。足し忘れたgitのフックを、人に示すためである。
# 終了コードは、0が無いものが無い、1が無いものがあるか、メインの作業フォルダーを求められないか、一覧を読めない（この2つのときは標準出力に何も出さない）、2が使い方の誤りである。
# scripts/print-protection-status.shが呼ぶ。
set -u -o pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly SCRIPT_ROOT
readonly SETTING_LIST="${SCRIPT_ROOT}/data/git-hook-setting-list.tsv"

# 1つのフックが、決まったイベントとコマンドで足してあるかを返す。スクリプトのパスだけを二重引用符で囲んだ形も認める。
# 引数：導入先、名前、イベント、ハーネスの場所からのコマンド、ハーネスの場所
# 出力：なし
# 戻り値：足してあれば0、無いか違えば1
has_git_hook_setting() {
  local command script="${4%% *}" argument=''
  if [ "$4" != "${script}" ]; then
    argument=" ${4#* }"
  fi
  if ! git -C "$1" config --get-all "hook.$2.event" 2> /dev/null | grep -F -q -x -- "$3"; then
    return 1
  fi
  if ! command="$(git -C "$1" config --get "hook.$2.command" 2> /dev/null)"; then
    return 1
  fi
  case "${command}" in
    "$5/$4" | "\"$5/${script}\"${argument}") return 0 ;;
  esac
  return 1
}

main() {
  local main_directory harness_directory name event command target found_count=0
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'find-missing-git-hook-setting.sh: 導入先のフォルダーとハーネスの場所の2つを渡してください。' >&2
    exit 2
  fi
  # ハーネスのリポジトリかは、メインの作業フォルダーとハーネスの場所を、たどった先のパスで比べて決める。
  if ! main_directory="$("${BASH}" "${SCRIPT_ROOT}/scripts/print-main-worktree-path.sh" "$1" 2> /dev/null)" \
    || ! main_directory="$(cd "${main_directory}" && pwd -P)" \
    || ! harness_directory="$(cd "$2" && pwd -P)"; then
    printf 'find-missing-git-hook-setting.sh: %sで、gitのリポジトリのメインの作業フォルダーを求められませんでした。gitのリポジトリの中のフォルダーを渡してください。\n' "$1" >&2
    exit 1
  fi
  # 読めないまま読むと、ループが動かずに0で終わり、無いフックを示さないので、先に確かめる。
  if [ ! -f "${SETTING_LIST}" ] || [ ! -r "${SETTING_LIST}" ]; then
    printf 'find-missing-git-hook-setting.sh: gitのフックの一覧（%s）を読めません。ハーネスのファイルの権限を確かめてください。\n' "${SETTING_LIST}" >&2
    exit 1
  fi
  while IFS=$'\t' read -r name event command target; do
    case "${name}" in
      '#'* | '') continue ;;
    esac
    if [ "${target}" = 'harness' ] && [ "${main_directory}" != "${harness_directory}" ]; then
      continue
    fi
    if ! has_git_hook_setting "$1" "${name}" "${event}" "${command}" "$2"; then
      printf '%s: %sで「%s/%s」を動かす\n' "${name}" "${event}" "$2" "${command}"
      found_count=$((found_count + 1))
    fi
  done < "${SETTING_LIST}"
  if [ "${found_count}" -gt 0 ]; then
    exit 1
  fi
  exit 0
}

main "$@"
