#!/bin/bash
# 渡した導入先ごとの語の一覧（メインの作業フォルダーの.harness/rules/word-list.txt）を読み、形とパターンを確かめて、行ごとに「種類<TAB>パターン<TAB>代わりの言い方<TAB>除く形」を標準出力に出す。種類は、その導入先だけで止める語のbannedと、確かめる語への答えのambiguous-banned、ambiguous-allowedである。壊れた一覧で、語が黙って止まらなくならないようにするためである。
# 終了コードは、0が読めたか一覧が無い、1が一覧の形かパターンの誤り（空の文字列に当たる除く形を含む）か一覧が読めない、2が使い方の誤りである。
# scripts/print-word-list.shが導入したリポジトリの語を決めるときと、scripts/print-ambiguous-word-usage.shが答えの無い語を決めるときに呼ぶ。
set -u -o pipefail

# 一覧の行の形を確かめ、行番号を付けて出す。awkで読むのは、bashのreadが続いたタブを1つにまとめ、空の列のあとの列が前にずれるためである。
# 引数：一覧のパス
# 出力：「行番号<TAB>種類<TAB>パターン<TAB>代わりの言い方<TAB>除く形」の行。形の誤りは「ファイル:行: 説明」の形で標準エラーに
# 戻り値：形が正しければ0、誤りがあれば1
print_checked_row() {
  LC_ALL=C awk -F '\t' '
    function report(message) { print FILENAME ":" FNR ": " message | "cat 1>&2"; failed = 1 }
    /^#/ || $0 == "" { next }
    index($0, "\r") > 0 { report("行にCRがあります。改行をLFだけにしてください。"); next }
    $1 == "banned" && (NF < 3 || NF > 4 || $2 == "" || $3 == "") {
      report("bannedの行の列の数が3か4でないか、パターンか代わりの言い方が空です。banned、パターン、代わりの言い方、除く形（任意）を、タブで区切って書いてください。")
      next
    }
    ($1 == "ambiguous-banned" || $1 == "ambiguous-allowed") && (NF != 2 || $2 == "") {
      report($1 "の行の列の数が2でないか、パターンが空です。種類と確かめる語のパターンの2つを、タブで区切って書いてください。")
      next
    }
    $1 != "banned" && $1 != "ambiguous-banned" && $1 != "ambiguous-allowed" {
      report("種類「" $1 "」は使えません。banned、ambiguous-banned、ambiguous-allowedのどれかを、タブで区切って書いてください。")
      next
    }
    {
      # 確かめる語と同じパターンのbannedの行は、禁止にする答えとして数えるので、ambiguous-allowedと逆の答えになる。
      answer = ($1 == "ambiguous-allowed") ? "allowed" : "banned"
      if (($2 in answers) && answers[$2] != answer) {
        report("パターン「" $2 "」に、禁止にする答えと禁止にしない答えの両方があります。どちらかの行を消してください。")
        next
      }
      answers[$2] = answer
      print FNR "\t" $1 "\t" $2 "\t" $3 "\t" $4
    }
    END { exit failed }' "$1"
}

main() {
  local rows number kind pattern replacement exclusion value output='' status=0
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-project-word-list.sh: 一覧のパスを1つだけ渡してください。導入先ごとの語の一覧のパスを、引数に渡してください。' >&2
    exit 2
  fi
  # リンクをたどらないのは、リンク先の中身（例：秘密情報）を、誤りの文として出さないためである。
  if [ -L "$1" ]; then
    printf 'print-project-word-list.sh: 導入先ごとの語の一覧「%s」は、シンボリックリンクなので読みません。実体のファイルを置くよう、人に伝えてください。\n' "$1" >&2
    exit 1
  fi
  if [ ! -e "$1" ]; then
    exit 0
  fi
  if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    printf 'print-project-word-list.sh: 導入先ごとの語の一覧「%s」が、ふつうのファイルでないか、読めません。ファイルの種類と権限を確かめるよう、人に伝えてください。\n' "$1" >&2
    exit 1
  fi
  rows="$(print_checked_row "$1")" || exit 1
  while IFS=$'\t' read -r number kind pattern replacement exclusion; do
    if [ -z "${number}" ]; then
      continue
    fi
    # grepが読めないパターンを、語を探す前に、行を示して止める。探すときに見つけると、どの一覧のどの行かを示せないためである。
    for value in "${pattern}" "${exclusion}"; do
      if [ -z "${value}" ]; then
        continue
      fi
      LC_ALL=C grep -E -e "${value}" < /dev/null > /dev/null 2>&1
      if [ "$?" -eq 2 ]; then
        printf '%s:%s: パターン「%s」を、grepが読めません。grep -Eで読める形に直してください。\n' "$1" "${number}" "${value}" >&2
        status=1
      fi
    done
    # 空の文字列に当たる除く形は、語の確認の置き換えが文字の間すべてに入り、語が黙って見つからなくなるので、行を示して止める。
    if [ -n "${exclusion}" ] && LC_ALL=C grep -qE -e "${exclusion}" <<< '' 2> /dev/null; then
      printf '%s:%s: 除く形「%s」が、空の文字列に当たります。熟語だけに当たる形（例：末尾の縦線を消した形）に直してください。\n' "$1" "${number}" "${exclusion}" >&2
      status=1
    fi
    output="${output}${kind}"$'\t'"${pattern}"$'\t'"${replacement}"$'\t'"${exclusion}"$'\n'
  done <<< "${rows}"
  # 誤りがあれば、行を出さない。呼ぶ側が、誤りのある一覧の一部の語だけで動かないためである。
  if [ "${status}" -ne 0 ]; then
    exit 1
  fi
  printf '%s' "${output}"
  exit 0
}

main "$@"
