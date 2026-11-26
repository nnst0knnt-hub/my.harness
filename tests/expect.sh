#!/bin/bash
# 期待と実際を比べてok・ngの行を出す関数と、ファイルを入力にするケースを動かす関数と、ケースの中身を作る関数を持つ。テストの結果を、どのテストでも同じ形で出すためである。
# 終了コードは持たない。print_expect_summaryが、失敗があれば1を返す。
# tests/のテストのファイルが、始めにsourceする。

case_count=0
failure_count=0

# 期待と実際を比べ、結果を出す。
# 引数：説明の文、期待する値、実際の値
# 出力：一致すればokの行、違えばngの行と、期待と実際の行
# 戻り値：一致すれば0、違えば1
expect() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  case_count=$((case_count + 1))
  if [ "${expected}" = "${actual}" ]; then
    printf 'ok: %s\n' "${description}"
    return 0
  fi
  failure_count=$((failure_count + 1))
  printf 'ng: %s\n  期待：%s\n  実際：%s\n' \
    "${description}" "${expected}" "${actual}"
  return 1
}

# ケースの数と失敗の数を出す。
# 引数：なし
# 出力：ケースの数と失敗の数の1行
# 戻り値：失敗が無ければ0、あれば1
print_expect_summary() {
  if [ "${failure_count}" -eq 0 ]; then
    printf '%s件のケースが、すべて通りました。\n' "${case_count}"
    return 0
  fi
  printf '%s件のケースのうち、%s件が失敗しました。\n' \
    "${case_count}" "${failure_count}"
  return 1
}

# スクリプトの出力から、渡したファイルの行番号だけを取り出す。
# 引数：ファイルのパス、スクリプトの出力（1行が「ファイル:行: 説明」の形）
# 出力：行番号を空白で区切った1行（行番号が無ければ「-」）
# 戻り値：0
print_reported_line() {
  printf '%s\n' "$2" | awk -v prefix="$1:" '
    index($0, prefix) == 1 {
      rest = substr($0, length(prefix) + 1)
      sub(/:.*/, "", rest)
      lines = lines separator rest
      separator = " "
    }
    END { if (lines == "") lines = "-"; print lines }'
}

# エスケープで書いた中身のファイルを作ってスクリプトに渡し、結果を出す。報告は、標準エラーに出たものだけを読む。
# 引数：スクリプトのパス、作るファイルのパス、printfの%bの形で書いた中身
# 中身の「-」は空のファイルに、「!」は読めないファイルにする。「-」を使うのは、タブ区切りのデータで空の列を書けないためである。
# rootは読めないファイルも読めるので、「!」のケースはroot以外で動かす。
# 出力：「終了コード 行番号…」の1行
# 戻り値：0
print_file_case_result() {
  local script="$1"
  local file="$2"
  local content="$3"
  local output
  local status
  rm -f "${file}"
  case "${content}" in
    '-') : > "${file}" ;;
    '!') : > "${file}" && chmod 000 "${file}" ;;
    *) printf '%b' "${content}" > "${file}" ;;
  esac
  output="$("${BASH}" "${script}" "${file}" 2>&1 > /dev/null)"
  status=$?
  printf '%s %s\n' "${status}" "$(print_reported_line "${file}" "${output}")"
}

# 中身の「[文字列*数]」を、文字列を数だけ並べたものに置き換えて出す。秘密情報のような本物の形の値と長い語を、ケースの一覧に書かずに作るためである。文字列には「[」「]」「*」を書かない。外側の括弧（例：「[[a*3]]」）を残すためである。
# 引数：中身
# 出力：置き換えた中身（最後に改行を足さない）
# 戻り値：0
print_repeated_text() {
  printf '%s' "$1" | LC_ALL=C awk '{
    while (match($0, /\[[^][*]+\*[0-9]+\]/)) {
      spec = substr($0, RSTART + 1, RLENGTH - 2)
      text = substr(spec, 1, index(spec, "*") - 1)
      repeated = ""
      for (i = 0; i < substr(spec, index(spec, "*") + 1) + 0; i++) repeated = repeated text
      printf "%s%s", substr($0, 1, RSTART - 1), repeated
      $0 = substr($0, RSTART + RLENGTH)
    }
    printf "%s", $0 }'
}
