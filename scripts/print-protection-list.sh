#!/bin/bash
# メインの作業フォルダーと保護の一覧のキー（branchが保護するブランチ、ciSettingPathがCIの設定のファイルの場所）を受け取り、既定の一覧、.harness/configで足したものの順に、1行に1つ出す。判定のスクリプトとgitのpre-pushが、同じ一覧で比べるためである。
# 終了コードは、0が出せた、1が既定の一覧か.harness/configを読めなかった（何も出さない）、2が使い方の誤りである。
# scripts/classify-git-push-command.shとscripts/classify-git-push-commit.shがpushを判定するたびに呼び、gitのpre-pushのスクリプトも呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

main() {
  local config default_list default_values added_values status
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'print-protection-list.sh: メインの作業フォルダーと、一覧のキー（branchかciSettingPath）の2つを渡してください。' >&2
    exit 2
  fi
  case "$2" in
    branch) default_list="${SCRIPT_DIRECTORY}/../data/default-protected-branch-list.txt" ;;
    ciSettingPath) default_list="${SCRIPT_DIRECTORY}/../data/ci-setting-path-list.txt" ;;
    *)
      printf 'print-protection-list.sh: 一覧のキー「%s」を知りません。branchかciSettingPathを渡してください。\n' "$2" >&2
      exit 2
      ;;
  esac
  config="$1/.harness/config"
  if ! default_values="$(grep -v -e '^#' -e '^$' "${default_list}")"; then
    printf 'print-protection-list.sh: 既定の一覧%sを読めませんでした。ハーネスのファイルがそろっているかを確かめてください。\n' "${default_list}" >&2
    exit 1
  fi
  added_values=''
  if [ -e "${config}" ] || [ -L "${config}" ]; then
    # git configは、読めないファイルを、キーが無いときと同じ終了コード1で返すので、先に確かめる。
    # 文字デバイスは、サンドボックスが無いファイルへの書き込みを止めるために置くことがある（.harness/docs/features/protection.mdの節「前提」）。
    if [ -c "${config}" ]; then
      printf 'print-protection-list.sh: %sが文字デバイスなので、読めませんでした。サンドボックスの中で動かしたときは、無い.harness/configの場所にサンドボックスが置いたもので、サンドボックスの外で動く判定のスクリプトとpre-pushは、既定の一覧を読みます。一覧を見るときは、Claude Codeの外のシェルで動かしてください（エージェントは人に頼んでください）。\n' "${config}" >&2
      exit 1
    fi
    if [ ! -f "${config}" ] || [ ! -r "${config}" ]; then
      printf 'print-protection-list.sh: %sが、ふつうのファイルでないか読む権限が無いので、読めませんでした。ファイルの種類と権限を確かめてください。\n' "${config}" >&2
      exit 1
    fi
    # -fで読むのは、include.*をたどらず、このファイルだけを読むためである（CONTRIBUTING.mdの節「設定の形式とキー」）。
    added_values="$(git config -f "${config}" --get-all "protection.$2" 2> /dev/null)"
    status=$?
    # 1はキーが無いときで、足すものが無いだけである。ほかは、ファイルが読めないか形が壊れている。
    if [ "${status}" -ne 0 ] && [ "${status}" -ne 1 ]; then
      printf 'print-protection-list.sh: %sを読めませんでした（git configの終了コード%s）。権限とgit configの形式を確かめてください。\n' "${config}" "${status}" >&2
      exit 1
    fi
  fi
  printf '%s\n' "${default_values}"
  if [ -n "${added_values}" ]; then
    printf '%s\n' "${added_values}"
  fi
  exit 0
}

main "$@"
