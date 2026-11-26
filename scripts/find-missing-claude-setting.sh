#!/bin/bash
# Claude Codeの設定のファイル、勧める設定のファイル、ハーネスの場所を受け取り、勧める設定のうち設定のファイルに無いものを、1行に1つ標準出力に出す。PCの設定に足し忘れた保護を、人に示すためである。
# 終了コードは、0が無いものが無い、1が無いものがあるか、jqが無いか、設定のファイルを読めない（このときは標準出力に何も出さない）、2が使い方の誤りである。
# scripts/print-protection-status.shが、PCの設定とdata/recommended-claude-setting.jsonを渡して呼ぶ。
set -u -o pipefail

# 勧める設定の値ごとに、一覧の項目なら一覧にあるか、ほかの値なら同じかを比べる。<ハーネスの場所>は、渡したハーネスの場所に置き換える。
# paths(scalars)は、値がfalseの所を選ばないので、型で選ぶ。$で始まる語は、シェルではなくjqの変数である。
# shellcheck disable=SC2016
readonly PROGRAM='
  ($actual[0] // {}) as $setting
  | paths(type != "object" and type != "array") as $path
  | (getpath($path) | if type == "string" then split("<ハーネスの場所>") | join($root) else . end) as $value
  | ($path | map(select(type == "string")) | join(".")) as $key
  | if ($path[-1] | type) == "number" then
      select([try ($setting | getpath($path[:-1]) | .[]?) catch empty] | any(.[]; . == $value) | not)
    else
      select((try ($setting | getpath($path)) catch null) != $value)
    end
  | "\($key): \($value | tojson)"'

main() {
  local missing
  local actual_option=()
  if [ "$#" -ne 3 ]; then
    printf '%s\n' 'find-missing-claude-setting.sh: 設定のファイル、勧める設定のファイル、ハーネスの場所の3つを渡してください。' >&2
    exit 2
  fi
  if ! jq --version > /dev/null 2>&1; then
    printf '%s\n' 'find-missing-claude-setting.sh: jqが動かないので、設定のファイルを読めません。jqを入れてください。' >&2
    exit 1
  fi
  # 設定のファイルが無いのは、何も設定していないときなので、空の設定と比べる。
  actual_option=(--slurpfile actual "$1")
  if [ ! -e "$1" ]; then
    actual_option=(--argjson actual '[{}]')
  fi
  # 読めないときに何も出さずに0で終わると、無いものが無いと読み違えるので、jqの終了コードを見る。
  if ! missing="$(jq -r "${actual_option[@]}" --arg root "$3" "${PROGRAM}" "$2" 2> /dev/null)"; then
    printf 'find-missing-claude-setting.sh: %sか%sを、JSONとして読めませんでした。ファイルの権限とJSONの形を確かめてください。\n' "$1" "$2" >&2
    exit 1
  fi
  if [ -z "${missing}" ]; then
    exit 0
  fi
  printf '%s\n' "${missing}"
  exit 1
}

main "$@"
