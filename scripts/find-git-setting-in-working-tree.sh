#!/bin/bash
# フォルダーとハーネスの場所を受け取り、そこで動くgitが使う、サンドボックスの中から書ける設定とファイル（例：作業フォルダーの中のフック、通信の方式か相手を変える設定）を探す。見つけたものは標準エラーに出す。サンドボックスの外で動くgitに、サンドボックスの中から書いたものを動かさせないためである。
# 終了コードは、0が見つからない、1が見つけたか、リポジトリの形を確かめられない、2が使い方の誤りである。
# scripts/classify-remote-command.shが、判定で通すか確認を求めるgit push、git fetch、glabと、確認を求めるghの前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitの設定の確認」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# 外で動くgit push、git fetchが、値をパスかURLかコマンドとして使うキーである。
readonly SETTING_PATTERN='^(core\.(hookspath|sshcommand|gitproxy|askpass|fsmonitor)|include\.path|includeif\..*\.path|hook\..*\.command|credential\.(.*\.)?helper|remote\..*\.(url|pushurl|uploadpack|receivepack)|url\..*\.(insteadof|pushinsteadof)|gpg\.(.*\.)?program)$'

found_count=0 toplevel='' common_directory=''

# 見つけたものを、文の中の改行を⏎にして標準エラーの1行に出し、数える。呼び出し元が1行目だけを理由の文に入れるためである。
# 引数：見つけたものの説明の文
# 出力：標準エラーに1行
# 戻り値：0
report_finding() {
  printf 'find-git-setting-in-working-tree.sh: %s\n' "${1//$'\n'/⏎}" >&2
  found_count=$((found_count + 1))
}

# .gitの場所が、メインの作業フォルダーの.gitか、そこのworktrees/の中かを確かめ、ほかの場所なら見つけたものに足す。.git/commondirも、gitが読む.gitの場所を変えるので、ここで見つかる。
# 引数：動かすフォルダー
# 出力：見つけたものを標準エラーに
# 戻り値：確かめられたら0、gitに聞けなければ1
find_redirected_git_directory() {
  local git_directory output
  # 判定のスクリプトが外で動かすコマンドに渡す場所と同じ求め方にするため、同じスクリプトで求める。
  if ! output="$("${BASH}" "${SCRIPT_DIRECTORY}/print-git-directory.sh" "$1" 2> /dev/null)"; then
    return 1
  fi
  { IFS= read -r git_directory && IFS= read -r common_directory && IFS= read -r toplevel; } <<< "${output}"
  if ! { [ "${git_directory}" = "${toplevel}/.git" ] && [ -d "${toplevel}/.git" ] \
    && [ "${common_directory}" = "${git_directory}" ]; } \
    && ! { [ -f "${toplevel}/.git" ] && [ "${git_directory%/*}" = "${common_directory}/worktrees" ] \
      && [ "${common_directory##*/}" = '.git' ]; }; then
    report_finding ".gitが、メインの作業フォルダーの.gitか、そこのworktrees/の中を指していません（${git_directory}）。"
  fi
  # 正しいworktreeの共通のgitのフォルダーは、作業フォルダーの外にある。中にあれば、エージェントが作った偽のリポジトリで、設定もエージェントが書ける。
  case "${common_directory}/" in "${toplevel}/.git/") ;; "${toplevel}/"*) report_finding "共通のgitのフォルダー（${common_directory}）が、作業フォルダーの中にあります。" ;; esac
  if [ -e "${common_directory}/modules" ]; then
    report_finding "${common_directory}/modulesがあり、gitがサブモジュールの設定を読みます。"
  fi
}

main() {
  local origin key_value key value kind base hook path hook_kind
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'find-git-setting-in-working-tree.sh: 動かすフォルダーとハーネスの場所の2つを渡してください。' >&2
    exit 2
  fi
  if ! find_redirected_git_directory "$1"; then
    report_finding "$1で、gitのリポジトリの作業フォルダーと.gitの場所を求められませんでした。"
    exit 1
  fi
  # worktreeごとの設定のファイル（.git/config.worktree）は、.git/configと違って、サンドボックスの中から書ける。
  [ "$(git -C "${toplevel}" config --bool --get extensions.worktreeConfig 2> /dev/null)" = 'true' ] && report_finding 'extensions.worktreeConfigが有効で、サンドボックスの中から書けるconfig.worktreeを、gitが設定として読みます。'
  # pushとfetchで動くフックは、中身が作業フォルダーの中のファイルを動かすか（例：lefthook、npm test）を判定できないので、どこにあっても見つける。フックとフックのフォルダーのリンクとハードリンクは、判定のあとに別の名前から書き換えられるので、動かせなくても見つける。gitはcore.hooksPathの最後の/を残して返すので外してからリンクかを見て、親のフォルダーが無いときのcdのエラーは、見つけたものの文と混ざるので捨てる。
  for hook in hooks hooks/pre-push hooks/reference-transaction hooks/pre-auto-gc; do
    path="$(cd "${toplevel}" && path="$(git rev-parse --git-path "${hook}" 2> /dev/null | sed 's|//*$||')" \
      && cd "$(dirname "${path}")" 2> /dev/null && printf '%s/%s' "${PWD}" "${path##*/}")" || continue
    hook_kind="$({ [ -L "${path}" ] && printf 'リンク'; } || { [ -f "${path}" ] && [ -x "${path}" ] && printf '動かせるファイル'; } \
      || { [ -f "${path}" ] && [ -n "$(find "${path}" -prune -type f -links +1)" ] && printf 'ハードリンク'; })"
    [ -z "${hook_kind}" ] || report_finding "pushかfetchで動くフックの場所（${path}）が${hook_kind}で、サンドボックスの外で動くことがあります。"
  done
  # 一番上で読むのは、--show-originがリポジトリの設定を、gitを動かした場所からの相対パスで出すためである。
  while IFS= read -r -d '' origin && IFS= read -r -d '' key_value; do
    key="${key_value%%$'\n'*}"
    value="${key_value#*$'\n'}"
    origin="${origin#file:}"
    kind='command' && base="${toplevel}"
    case "${key}" in
      # コマンドが作業フォルダーの中のファイルを動かすかは文字列から判定できないので、ハーネスの場所のスクリプトのほかは見つける。
      hook.*.command)
        case "${value}" in
          "$2/"* | "\"$2/"* | "'$2/"*) ;;
          *) report_finding "${key}が、ハーネスの場所のほかのコマンド（${value}）を動かします。" ;;
        esac
        continue
        ;;
      core.hookspath) kind='path' ;;
      # gitは、この値をシェルで語に分けずに、1つのプログラムのパスとして動かす。
      core.askpass | core.gitproxy | gpg.program | gpg.*.program) kind='program' ;;
      include.path | includeif.*.path) kind='path' && base="$(cd "${toplevel}" && cd "$(dirname "${origin}")" 2> /dev/null && pwd -P)" || base="${toplevel}" ;;
      remote.*.url | remote.*.pushurl) kind='url' ;;
      # url.<書き換え先>.insteadOfは、値で始まるURLを、キーの中の書き換え先に変える。
      url.*.insteadof | url.*.pushinsteadof) kind='url' && value="${key#url.}" && value="${value%.*}" ;;
    esac
    if ! "${BASH}" "${SCRIPT_DIRECTORY}/find-writable-path-in-value.sh" \
      "${toplevel}" "${common_directory}" "${base}" "${kind}" "${value}"; then
      report_finding "${key}が、サンドボックスの中から書ける場所を指すか、指すかを判定できない形です（${value}）。"
    fi
  done < <(git -C "${toplevel}" config --show-origin -z --get-regexp "${SETTING_PATTERN}" 2> /dev/null)
  # 通信の方式か相手を変える設定（例：ext::のURL、リポジトリの設定のhttp.proxy）は、書ける場所を指すかでは決まらないので、別のスクリプトが探す。
  "${BASH}" "${SCRIPT_DIRECTORY}/find-git-transport-setting.sh" "${toplevel}" "${common_directory}" || found_count=$((found_count + 1))
  exit "$((found_count > 0))"
}

main "$@"
