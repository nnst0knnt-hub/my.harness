#!/bin/bash
# テストのPATHの先頭に置く偽のコマンドを作る関数を持つ。OSと依存の有無を変えたケースを、どのテストでも同じ形で作るためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# tests/test-print-sandbox-state.sh、tests/test-print-environment-state.sh、tests/test-print-protection-status.sh、tests/test-exec-with-pinned-git-directory.sh、tests/test-print-claude-setting-status.shが、始めにsourceする。

# テストのPATHの先頭に置く偽のコマンドを、<フォルダー>/bin/に作る。unameはケースのOSを返し、bubblewrapとsocatは動き、動かないコマンドは127で終わる。
# 引数：フォルダー、OS（linux、wsl1、wsl2、darwin、other）、動かないコマンド（「,」で区切る、「-」は無し）
# 出力：なし
# 戻り値：0
create_fake_command() {
  local kernel_name=Linux kernel_release=6.6.0-generic name
  case "$2" in
    wsl1) kernel_release=4.4.0-19041-Microsoft ;;
    wsl2) kernel_release=6.6.114.1-microsoft-standard-WSL2 ;;
    darwin) kernel_name=Darwin && kernel_release=24.0.0 ;;
    other) kernel_name=MINGW64_NT-10.0 && kernel_release=3.4.10 ;;
  esac
  mkdir -p "$1/bin"
  # 書いたスクリプトの中の$1は、偽のunameが動くときに読む引数なので、ここでは展開しない。
  # shellcheck disable=SC2016
  printf '#!/bin/sh\ncase "$1" in -r) echo %s ;; *) echo %s ;; esac\n' \
    "${kernel_release}" "${kernel_name}" > "$1/bin/uname"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/bwrap"
  printf '#!/bin/sh\nexit 0\n' > "$1/bin/socat"
  for name in ${3//,/ }; do
    if [ "${name}" != '-' ]; then
      printf '#!/bin/sh\nexit 127\n' > "$1/bin/${name}"
    fi
  done
  chmod +x "$1/bin/"*
}

# gitとclaudeの偽のコマンドを、<フォルダー>/bin/に作る。gitは--versionだけに決まったバージョンを返し、ほかは本物のgitを動かす。
# 引数：フォルダー、gitのバージョン、Claude Codeのバージョン（「-」は127で終わる）
# 出力：なし
# 戻り値：0
create_fake_version_command() {
  local real_git
  real_git="$(command -v git)"
  mkdir -p "$1/bin"
  # 書いたスクリプトの中の$1と$@は、偽のgitが動くときに読む引数なので、ここでは展開しない。
  # shellcheck disable=SC2016
  printf '#!/bin/sh\nif [ "$1" = --version ]; then echo "git version %s"; exit 0; fi\nexec "%s" "$@"\n' \
    "$2" "${real_git}" > "$1/bin/git"
  if [ "$3" = '-' ]; then
    printf '#!/bin/sh\nexit 127\n' > "$1/bin/claude"
  else
    printf '#!/bin/sh\necho "%s (Claude Code)"\n' "$3" > "$1/bin/claude"
  fi
  chmod +x "$1/bin/git" "$1/bin/claude"
}

# 固定したgitの3つの場所、GIT_NO_LAZY_FETCH、GIT_CONFIG_COUNTで足した設定、引数を1行で出す偽のgit、gh、glabを、<フォルダー>/bin/に作る。外で動かすスクリプトが渡す環境変数と引数を確かめるためである。
# 引数：フォルダー
# 出力：なし
# 戻り値：0
create_fake_remote_command() {
  local name
  mkdir -p "$1/bin"
  for name in git gh glab; do
    # 書いたスクリプトの中の変数は、偽のコマンドが動くときに読むので、ここでは展開しない。
    # shellcheck disable=SC2016
    printf '%s\n' '#!/bin/bash' 'config="" && i=0' \
      'while [ "${i}" -lt "${GIT_CONFIG_COUNT:-0}" ]; do key="GIT_CONFIG_KEY_${i}" && value="GIT_CONFIG_VALUE_${i}" && config="${config}${config:+,}${!key}=${!value}" && i=$((i + 1)); done' \
      'printf "dir=%s|%s|%s lazy=%s config=%s args=" "${GIT_DIR:-}" "${GIT_COMMON_DIR:-}" "${GIT_WORK_TREE:-}" "${GIT_NO_LAZY_FETCH:-}" "${config}"' \
      'printf "[%s]" "${0##*/}" "$@"' > "$1/bin/${name}"
    chmod +x "$1/bin/${name}"
  done
}
