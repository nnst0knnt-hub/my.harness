#!/bin/bash
# 作業フォルダーの一番上と共通のgitのフォルダーを受け取り、そこで動くgitの通信の方式か相手を変える設定を探して、見つけたものを標準エラーに出す。サンドボックスの外で動くgitが、エージェントの書いた設定で、URLのコマンドを動かすか、ほかの相手を通して証明書を確かめずに通信しないためである。
# 終了コードは、0が見つからない、1が見つけた、2が使い方の誤りである。
# scripts/find-git-setting-in-working-tree.shが、gitの設定を探すときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitの設定の確認」に書く。
set -u -o pipefail
export LC_ALL=C

# URLの値のキーと、方式を許すキーと、通信の相手を変えるキーである。
readonly SETTING_PATTERN='^(remote\..*\.(url|pushurl|proxy)|url\..*\.(insteadof|pushinsteadof)|protocol\.(.*\.)?allow|http\.(.*\.)?proxy)$'
# 証明書を確かめるかのキーで、gitが真偽として読む値で決める。
readonly SSL_VERIFY_PATTERN='^http\.(.*\.)?sslverify$'
# gitは、<名前>::<アドレス>の形のURLを、git-remote-<名前>のプログラムで動かし、ext::では書いたコマンドを動かす。
readonly HELPER_URL_PATTERN='^[A-Za-z0-9][A-Za-z0-9+.-]*::'

found_count=0

# 見つけたものを、文の中の改行を⏎にして標準エラーの1行に出し、数える。呼び出し元が1行目だけを理由の文に入れるためである。
# 引数：見つけたものの説明の文
# 出力：標準エラーに1行
# 戻り値：0
report_finding() {
  printf 'find-git-transport-setting.sh: %s\n' "${1//$'\n'/⏎}" >&2
  found_count=$((found_count + 1))
}

# 設定のファイルが、リポジトリの設定（作業フォルダーの一番上か共通のgitのフォルダーの中）かを返す。
# 引数：作業フォルダーの一番上、共通のgitのフォルダー、--show-originの場所（file:を外したもの、ファイルでなければ空）
# 出力：なし
# 戻り値：リポジトリの設定か、場所を求められない（例：フォルダーの名前の最後が改行）なら0、ほか（例：PCの設定、コマンドの引数）なら1
is_repository_setting() {
  local directory
  [ -n "$3" ] || return 1
  # --show-originは、リポジトリの設定を、gitを動かした場所からの相対パスで出す。場所を求められないときは、見逃さないよう、リポジトリの設定とみなす。
  directory="$(cd "$1" && cd "$(dirname "$3")" 2> /dev/null && pwd -P)" || return 0
  case "${directory}/" in
    "$1/"* | "$2/"*) return 0 ;;
  esac
  return 1
}

# 書き換え（insteadOfとpushInsteadOf）を当てたあとのリモートのURLが、<名前>::の形かを確かめる。書き換え先とURLがつながって、初めてその形になることがあるためである。
# 引数：作業フォルダーの一番上
# 出力：見つけたものを標準エラーに
# 戻り値：0
find_rewritten_helper_url() {
  local name url
  while IFS= read -r name; do
    while IFS= read -r url; do
      [[ "${url}" =~ ${HELPER_URL_PATTERN} ]] && report_finding "リモート「${name}」の書き換えたあとのURLが、${url%%::*}::の形で、gitがURLのプログラムかコマンドを動かします。"
    done < <(git -C "$1" remote get-url --all "${name}" 2> /dev/null; git -C "$1" remote get-url --push --all "${name}" 2> /dev/null)
  done < <(git -C "$1" remote 2> /dev/null)
}

main() {
  local origin key_value key value status
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'find-git-transport-setting.sh: 作業フォルダーの一番上と共通のgitのフォルダーの2つを渡してください。' >&2
    exit 2
  fi
  while IFS= read -r -d '' origin && IFS= read -r -d '' key_value; do
    key="${key_value%%$'\n'*}" && value="${key_value#*$'\n'}"
    case "${origin}" in file:*) origin="${origin#file:}" ;; *) origin='' ;; esac
    # url.<書き換え先>.insteadOfは、値で始まるURLを、キーの中の書き換え先に変える。
    case "${key}" in url.*) value="${key#url.}" && value="${value%.*}" ;; esac
    case "${key}" in
      # URLは、どの設定のファイルにあっても見つける。
      remote.*.url | remote.*.pushurl | url.*)
        [[ "${value}" =~ ${HELPER_URL_PATTERN} ]] && report_finding "${key}が、${value%%::*}::の形のURLで、gitがURLのプログラムかコマンドを動かします。"
        continue
        ;;
    esac
    # 方式を許す設定と通信の相手を変える設定は、PCの設定（例：プロキシーの設定）にあれば、人が書いたものなので見つけない。
    is_repository_setting "$1" "$2" "${origin}" \
      && report_finding "${key}が、リポジトリの設定のファイル（${origin}）にあり、gitの通信の方式か相手を変えます。"
  done < <(git -C "$1" config --show-origin -z --get-regexp "${SETTING_PATTERN}" 2> /dev/null)
  find_rewritten_helper_url "$1"
  # 証明書の確かめは、gitが真偽として読んだ値で決める（例：空の文字列と0kはfalse）。gitが読めない値も、確かめないことがあるとみなす。
  git -C "$1" config --type=bool --get-regexp "${SSL_VERIFY_PATTERN}" > /dev/null 2>&1
  status=$?
  [ "${status}" -le 1 ] || report_finding 'http.sslVerifyに、gitが真偽として読めない値があります。'
  while IFS= read -r -d '' origin && IFS= read -r -d '' key_value; do
    case "${origin}" in file:*) origin="${origin#file:}" ;; *) origin='' ;; esac
    [ "${key_value#*$'\n'}" = 'false' ] && is_repository_setting "$1" "$2" "${origin}" \
      && report_finding "${key_value%%$'\n'*}が、リポジトリの設定のファイル（${origin}）でfalseで、gitが証明書を確かめずに通信します。"
  done < <([ "${status}" -eq 0 ] && git -C "$1" config --show-origin -z --type=bool --get-regexp "${SSL_VERIFY_PATTERN}" 2> /dev/null)
  exit "$((found_count > 0))"
}

main "$@"
