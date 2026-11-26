#!/bin/bash
# 判定のスクリプトのテストのために、手元のbareのリモートとcommitのある導入先のリポジトリと、.harness/configを作る関数を持つ。リモートへの問い合わせを含む判定を、外と通信せずに確かめるためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# tests/test-classify-remote-command.sh、tests/test-print-tree-entry.sh、tests/test-print-remote-head.shが、tests/create-case-repository.shのあとにsourceする。

# テストのHOMEに、commitに要るgitの設定を書く。設定のコマンドに、利用者の名前を毎回書かずに済むようにするためである。
# 引数：HOMEにするフォルダー
# 出力：なし
# 戻り値：0
create_test_home() {
  mkdir -p "$1"
  printf '[user]\n\tname = test\n\temail = test@example.com\n[commit]\n\tgpgsign = false\n[init]\n\tdefaultBranch = main\n' \
    > "$1/.gitconfig"
}

# 導入先のフォルダーに、保護の設定を足す.harness/configを作る。
# 引数：導入先のフォルダー、足す値（「,」区切り、「ci=」で始まる値はCIの設定のファイルの場所、ほかは保護するブランチ。「-」は作らない、「!」は読めないファイル、「?」は形の壊れたファイル）
# 出力：なし
# 戻り値：0
create_harness_config() {
  local config="$1/.harness/config" value
  local values=()
  rm -rf "$1/.harness"
  [ "$2" != '-' ] || return 0
  mkdir -p "$1/.harness"
  case "$2" in
    '!') : > "${config}" && chmod 000 "${config}" ;;
    '?') printf '%s\n' '[protection' > "${config}" ;;
    *)
      printf '%s\n' '[protection]' > "${config}"
      # readで分けるのは、forで分けると、hotfix/*のようなパターンがファイルの名前に展開されるためである。
      IFS=',' read -r -a values <<< "$2"
      for value in "${values[@]}"; do
        case "${value}" in
          ci=*) printf '\tciSettingPath = %s\n' "${value#ci=}" >> "${config}" ;;
          *) printf '\tbranch = %s\n' "${value}" >> "${config}" ;;
        esac
      done
      ;;
  esac
}

# 導入先のリポジトリと、その隣に手元のbareのリモートを作り、originに足す。最初のcommitにCIの設定のファイルを置いてリモートのmainへ送り、今のケースが送り元に使う作業用のブランチを手元に作る。設定のコマンドがあれば、最後にそこで動かす。
# 引数：作るフォルダー、HOMEにするフォルダー（create_test_homeで作ったもの）、設定のコマンド（「-」は動かさない）
# 出力：なし
# 戻り値：作れたら0、作れなければ1
create_test_repository() {
  local remote="$1-remote.git" branch
  rm -rf "$1" "${remote}"
  run_test_git "$2" init -q "$1" || return 1
  mkdir -p "$1/.github/workflows"
  printf '%s\n' 'on: push' > "$1/.github/workflows/ci.yml"
  printf '%s\n' 'test:' '  script: "true"' > "$1/.gitlab-ci.yml"
  run_test_git "$2" -C "$1" add -A || return 1
  run_test_git "$2" -C "$1" commit -q -m init || return 1
  for branch in feat/x feat/add-protection main-fix; do
    run_test_git "$2" -C "$1" branch "${branch}" || return 1
  done
  run_test_git "$2" init -q --bare "${remote}" || return 1
  run_test_git "$2" -C "$1" remote add origin "${remote}" || return 1
  run_test_git "$2" -C "$1" push -q origin main:main || return 1
  if [ "$3" != '-' ]; then
    (cd "$1" && HOME="$2" GIT_CONFIG_NOSYSTEM=1 "${BASH}" -c "$3") > /dev/null 2>&1
  fi
}
