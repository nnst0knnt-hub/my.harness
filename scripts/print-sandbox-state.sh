#!/bin/bash
# 作業フォルダーとメインの作業フォルダーを受け取り、OS、サンドボックスの依存、Claude Codeの設定のファイルから、サンドボックスの状態を1語で標準出力に出す。働かない保護を、エージェントと人に示すためである。
# 状態は、enabled（使える）、disabled（設定のファイルで有効になっていない）、missing-dependency（依存が動かない）、unsupported（使えないOS）、unknown（jqが無いか、ふつうの設定のファイルを読めない）である。終了コードは、0が状態を出した、2が使い方の誤りである。
# hooks/print-environment-state.shとscripts/print-protection-status.shが呼ぶ。3つ目の引数（管理者の設定のフォルダー）は、テストだけが渡す。
set -u -o pipefail

# 設定のファイルを、Claude Codeが値を使う順（先のものほど強い）に出す。--settingsで渡した値と、ファイルでない管理者の設定は読めない。
# 引数：作業フォルダー、メインの作業フォルダー、管理者の設定のフォルダー
# 出力：ファイルのパスを1行に1つ
# 戻り値：0
print_setting_file_list() {
  local file drop_files=()
  # 名前の順を、ロケールに依らずに決める。
  local LC_ALL=C
  # managed-settings.d/は名前の順にmanaged-settings.jsonのあとで合わさるので、名前の逆の順に先に出す。
  for file in "$3/managed-settings.d/"*.json; do
    if [ -e "${file}" ]; then
      drop_files=("${file}" ${drop_files[@]+"${drop_files[@]}"})
    fi
  done
  printf '%s\n' ${drop_files[@]+"${drop_files[@]}"} "$3/managed-settings.json" \
    "$2/.claude/settings.local.json" "$1/.claude/settings.json" \
    "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/settings.json"
}

# OSと依存から、サンドボックスを使えるかを出す。
# 引数：なし
# 出力：使えなければ状態の1語、使えれば何も出さない
# 戻り値：0
print_platform_state() {
  case "$(uname -s)" in
    Darwin) return 0 ;;
    Linux) ;;
    *) printf '%s\n' 'unsupported' && return 0 ;;
  esac
  # WSL1のカーネルの名前は「Microsoft」で、WSL2の「microsoft-standard-WSL2」と大文字小文字で分かれる。
  case "$(uname -r)" in
    *Microsoft*) printf '%s\n' 'unsupported' && return 0 ;;
  esac
  if ! bwrap --version > /dev/null 2>&1 || ! socat -V > /dev/null 2>&1; then
    printf '%s\n' 'missing-dependency'
  fi
}

main() {
  local platform_state file value managed_directory
  if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    printf '%s\n' 'print-sandbox-state.sh: 作業フォルダーとメインの作業フォルダーを渡してください。' >&2
    exit 2
  fi
  managed_directory="${3:-/etc/claude-code}"
  if [ "$#" -eq 2 ] && [ "$(uname -s)" = 'Darwin' ]; then
    managed_directory='/Library/Application Support/ClaudeCode'
  fi
  platform_state="$(print_platform_state)"
  if [ -n "${platform_state}" ]; then
    printf '%s\n' "${platform_state}"
    exit 0
  fi
  # jqが無いときは、設定のファイルがあれば読めずにunknownになり、1つも無ければdisabledになる。
  while IFS= read -r file; do
    # 無いファイル、フォルダー、サンドボックスの中で無いファイルの場所に置かれる文字デバイス（読むとPermission deniedになる）は、無いファイルとして読む（.harness/docs/features/protection.mdの節「フック」）。
    if [ ! -f "${file}" ]; then
      continue
    fi
    if ! value="$(jq -r 'try .sandbox.enabled catch null | if type == "boolean" then tostring else empty end' \
      "${file}" 2> /dev/null)"; then
      printf '%s\n' 'unknown'
      exit 0
    fi
    case "${value}" in
      true) printf '%s\n' 'enabled' && exit 0 ;;
      false) printf '%s\n' 'disabled' && exit 0 ;;
    esac
  done < <(print_setting_file_list "$1" "$2" "${managed_directory}")
  printf '%s\n' 'disabled'
  exit 0
}

main "$@"
