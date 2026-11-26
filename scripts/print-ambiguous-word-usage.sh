#!/bin/bash
# 渡したフォルダーの導入先で、導入先ごとの語の一覧に答えの無い確かめる語（data/ambiguous-word-list.txt）ごとに、追跡しているファイルで使われた場所を探し、「勧める種類<TAB>パターン<TAB>場所…」の1行を標準出力に出す。場所は「パス:行」で、語ごとに3か所まで出す。勧める種類は、使われていなければambiguous-banned、使われていればambiguous-allowedである。導入のときに、業務の言葉と重なる語だけを、場所を添えて人に示すためである。
# 終了コードは、0が出せた、1がgitのリポジトリの外か、導入先ごとの語の一覧の誤りか、語を探せない、2が使い方の誤りである。
# エージェントが、configure-repositoryの手順で、確かめる語を禁止にするかを人に聞く表を作るときに呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly AMBIGUOUS_WORD_LIST="${SCRIPT_DIRECTORY}/../data/ambiguous-word-list.txt"
readonly PROJECT_WORD_LIST='.harness/rules/word-list.txt'
# 場所を語ごとに3か所までにするのは、場所を見て人が決められれば足り、熟語の多い語で出力が長くならないためである。
readonly LOCATION_LIMIT=3
# 除く形の無い語に渡す、文書に現れない制御文字である。scripts/find-banned-word.shと同じにする。
readonly NO_EXCLUSION=$'\x02'

# 1つのファイルから1つの語を探し、使われた行の番号を出す。除く形は、語に当たらない制御文字に置き換えてから当てる。scripts/find-banned-word.shと同じ当て方にするためである。
# $'\x01'を呼ぶ側のプロセス置換に直接書かずにこの関数に置くのは、CONTRIBUTING.mdの節「setと変数とbash 3.2」のとおり、bash 3.2で語を見つけられなくなるためである。
# 引数：ファイルのパス、語のERE、除く形のERE
# 出力：行の番号を1行に1つ
# 戻り値：0か、sed、grep、cutの終了コード（呼ぶ側は出力で決める）
print_word_line_number() {
  LC_ALL=C sed -E $'s\x01'"$3"$'\x01\x02\x01g' "$1" | LC_ALL=C grep -anE -e "$2" | LC_ALL=C cut -d : -f 1
}

# 1つの語を、導入先の追跡しているファイルから探し、使われた場所を出す。
# 引数：メインの作業フォルダー、語のERE、除く形のERE
# 出力：「パス:行」を1行に1つ、3か所まで
# 戻り値：探せたら0、git grepが失敗したら1
print_word_location() {
  local file files line count=0 status
  # .harness/を除くのは、ハーネスのファイルにある語が、導入先の業務の言葉ではないためである。git grepの-Iはバイナリーを飛ばし、作業フォルダーのシンボリックリンクの先は読まない。
  # --no-colorは、人のgitの色の設定（例：color.ui=always）で、ファイル名に色のエスケープが付かないようにするためである。
  files="$(LC_ALL=C git -C "$1" grep --no-color -I -l -z -E -e "$2" -- . ':!.harness' | LC_ALL=C tr '\0' '\n')"
  # pipefailのもとでは、git grepの終了コードが残る。1は、語の無いことである。
  status=$?
  if [ "${status}" -gt 1 ]; then
    return 1
  fi
  while IFS= read -r file; do
    if [ -z "${file}" ] || [ "${count}" -ge "${LOCATION_LIMIT}" ]; then
      continue
    fi
    while IFS= read -r line; do
      if [ "${count}" -lt "${LOCATION_LIMIT}" ]; then
        printf '%s:%s\n' "${file}" "${line}"
        count=$((count + 1))
      fi
    done < <(print_word_line_number "$1/${file}" "$2" "$3")
  done <<< "${files}"
}

main() {
  local main_path project_row unanswered_row pattern exclusion location line row
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-ambiguous-word-usage.sh: フォルダーを1つだけ渡してください。確かめる語の使われ方を探す導入先のフォルダーを、引数に渡してください。' >&2
    exit 2
  fi
  if ! main_path="$("${BASH}" "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "$1")"; then
    exit 1
  fi
  project_row="$("${BASH}" "${SCRIPT_DIRECTORY}/print-project-word-list.sh" "${main_path}/${PROJECT_WORD_LIST}")" || exit 1
  if [ ! -r "${AMBIGUOUS_WORD_LIST}" ]; then
    printf 'print-ambiguous-word-usage.sh: 確かめる語の一覧「%s」が読めません。ハーネスのリポジトリの場所と権限を確かめてください。\n' "${AMBIGUOUS_WORD_LIST}" >&2
    exit 1
  fi
  # 答えは、導入先の行のどの種類でも、パターンの文字列が同じなら答えたものとする。確かめる語と同じパターンのbannedの行は、禁止にする答えに数えるためである。
  unanswered_row="$(PROJECT_ROW="${project_row}" LC_ALL=C awk -F '\t' '
    BEGIN { count = split(ENVIRON["PROJECT_ROW"], rows, "\n"); for (i = 1; i <= count; i++) { split(rows[i], column, "\t"); answered[column[2]] = 1 } }
    !/^#/ && $0 != "" && !($1 in answered) { print $1 "\t" $3 }' "${AMBIGUOUS_WORD_LIST}")"
  while IFS=$'\t' read -r pattern exclusion; do
    if [ -z "${pattern}" ]; then
      continue
    fi
    if ! location="$(print_word_location "${main_path}" "${pattern}" "${exclusion:-${NO_EXCLUSION}}")"; then
      printf 'print-ambiguous-word-usage.sh: 確かめる語「%s」を、%sのgit grepで探せませんでした。パターンを、grep -Eで読める形に直してください。\n' "${pattern}" "${main_path}" >&2
      exit 1
    fi
    if [ -z "${location}" ]; then
      printf 'ambiguous-banned\t%s\n' "${pattern}"
      continue
    fi
    row="ambiguous-allowed"$'\t'"${pattern}"
    while IFS= read -r line; do row="${row}"$'\t'"${line}"; done <<< "${location}"
    printf '%s\n' "${row}"
  done <<< "${unanswered_row}"
  exit 0
}

main "$@"
