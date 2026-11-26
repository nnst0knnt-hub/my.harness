#!/bin/bash
# 引数なしで、git、jq、Claude Codeのバージョンを調べ、引数gitでは、gitだけを調べる。そのコマンドが受け持つ保護が働くかを、「状態<TAB>項目<TAB>起きること<TAB>直し方」の1行ずつで標準出力に出す。人に、働かない保護と直し方を示すためである。
# 状態は、働く、働かない、わからないで、直し方の無い行は「-」にする。終了コードは、いつも0である。
# scripts/print-protection-status.shが引数なしで、hooks/print-environment-state.shが引数gitで呼ぶ。下限のバージョンの理由は、.harness/docs/features/protection.mdの節「gitのフック」と節「フック」に書く。
set -u -o pipefail

readonly MINIMUM_GIT_VERSION=2.54.0
readonly MINIMUM_CLAUDE_VERSION=2.1.314

# バージョンが下限以上かを、点で区切った3つの数で比べる。数でない字から後ろは読まない（例：2.39.5 (Apple Git-154)）。
# 引数：バージョン、下限のバージョン
# 出力：なし
# 戻り値：下限以上なら0、下限より小さいか、空なら1
is_version_at_least() {
  local actual_parts=() required_parts=() actual required i
  if [ -z "$1" ]; then
    return 1
  fi
  IFS=. read -r -a actual_parts <<< "${1%%[!0-9.]*}"
  IFS=. read -r -a required_parts <<< "$2"
  for i in 0 1 2; do
    actual="${actual_parts[i]:-0}"
    required="${required_parts[i]:-0}"
    if [ "$((10#${actual}))" -gt "$((10#${required}))" ]; then
      return 0
    fi
    if [ "$((10#${actual}))" -lt "$((10#${required}))" ]; then
      return 1
    fi
  done
  return 0
}

# gitのバージョンが下限以上かを、1行で出す。
# 引数：なし
# 出力：「状態<TAB>項目<TAB>起きること<TAB>直し方」の1行
# 戻り値：0
print_git_status() {
  local version
  version="$(git --version 2> /dev/null)"
  version="${version#git version }"
  if is_version_at_least "${version}" "${MINIMUM_GIT_VERSION}"; then
    printf '働く\tgitのバージョン（%s）\tgitの設定で足したフック（pre-push、pre-commit、ハーネスのリポジトリではcommit-msgも）が動きます。\t-\n' "${version}"
  else
    printf '働かない\tgitのバージョン（%s）\tgitの設定で足したフックが動かないので、保護するブランチへのpushと、秘密情報を含むcommitと、ハーネスのリポジトリのコミットメッセージの止める語を、gitのフックで止めません。\tgitを%s以上にしてください。\n' \
      "${version:-見つかりません}" "${MINIMUM_GIT_VERSION}"
  fi
}

main() {
  local version
  print_git_status
  if [ "${1:-}" = 'git' ]; then
    exit 0
  fi
  if version="$(jq --version 2> /dev/null)"; then
    printf '働く\tjq（%s）\tPreToolUseのフックが、git push、git fetch、git pull、gh、glabを判定します。\t-\n' "${version}"
  else
    printf '%s\n' '働かない	jq（動きません）	PreToolUseのフックが判定できず、git push、git fetch、git pull、gh、glabのたびに確認が出ます。	jqを入れてください（例：sudo apt-get install jq、brew install jq）。'
  fi
  if ! version="$(claude --version 2> /dev/null)" || [ -z "${version}" ]; then
    printf '%s\n' 'わからない	Claude Codeのバージョン（claudeが動きません）	バージョンを確かめられません。	claudeを動かせるシェルで、このスクリプトを動かしてください。'
  elif is_version_at_least "${version%% *}" "${MINIMUM_CLAUDE_VERSION}"; then
    printf '働く\tClaude Codeのバージョン（%s）\tフックが起動しないときと時間切れのときに、コマンドを止めます。Monitorのツールで動かしたコマンドにも、フックが動きます。\t-\n' "${version%% *}"
  else
    printf '働かない\tClaude Codeのバージョン（%s）\tフックが起動しないときと時間切れのときに、git push、git fetch、git pull、gh、glabが確認なしで進みます。Monitorのツールで動かしたコマンドに、フックが動きません。\tclaude updateで、%s以上にしてください。\n' \
      "${version%% *}" "${MINIMUM_CLAUDE_VERSION}"
  fi
  exit 0
}

main "$@"
