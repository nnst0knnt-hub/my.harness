#!/bin/bash
# 渡したファイルの字数を改行を含めて数え、3,000字を超えたファイルを標準エラーに出す。常に読むルールを短く保つためである。
# 終了コードは、0が超えたファイルなし、1が超えたファイルあり、2が使い方の誤りである。
# tests/run-test-suite.shが共通のルール（rules/always-read.md）を渡して呼び、エージェントがadd-ruleとconfigure-repositoryの手順で導入先ごとのルールを渡して呼ぶ。
set -u -o pipefail

# 目安は、.harness/docs/features/always-read-rule.mdの表の、共通のルールと導入先ごとのルールの字数である。
readonly CHARACTER_LIMIT=3000

# ファイルの字数を数える。
# 引数：ファイルのパス
# 出力：字数
# 戻り値：0
count_character() {
  local byte_count
  # UTF-8の続きのバイト（0x80～0xBF）を消して、1文字を1バイトにする。
  # ロケールとwcの実装に依らず、同じ数にするためである。
  byte_count="$(LC_ALL=C tr -d '\200-\277' < "$1" | wc -c)"
  printf '%s\n' "$((byte_count))"
}

# 100万より小さい数を、3桁ごとのカンマで区切る。
# 引数：数
# 出力：カンマで区切った数
# 戻り値：0
format_number() {
  if [ "$1" -lt 1000 ]; then
    printf '%d\n' "$1"
    return 0
  fi
  printf '%d,%03d\n' "$(($1 / 1000))" "$(($1 % 1000))"
}

main() {
  local file
  local count
  local status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-long-rule.sh: ファイルが渡されていません。字数を数えるファイルを、引数に渡してください。' >&2
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-long-rule.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    count="$(count_character "${file}")"
    if [ "${count}" -gt "${CHARACTER_LIMIT}" ]; then
      printf '%s: 字数が%s字で、目安の%s字を超えています。毎回守ること以外を、必要なときに読むファイル（例：書く前に読むルール、導入先の.harness/docs/）に移してください。\n' \
        "${file}" "$(format_number "${count}")" \
        "$(format_number "${CHARACTER_LIMIT}")" >&2
      status=1
    fi
  done
  exit "${status}"
}

main "$@"
