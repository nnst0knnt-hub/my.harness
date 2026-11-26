#!/bin/bash
# 渡したフォルダーで語の確認に使う語を、data/banned-word-list.txt、data/ambiguous-word-list.txt、導入先ごとの語の一覧から決め、語ごとに「種類<TAB>パターン<TAB>代わりの言い方<TAB>除く形」の1行を標準出力に出す。種類は、止めるbanned、示すだけのambiguous、この導入先で禁止にするかが決まっていないundecidedである。場所ごとの語の扱いを、1か所で決めるためである。
# 終了コードは、0が出せた、1が一覧が読めないか形の誤りがあるか、ハーネスのリポジトリの中かを決められない、2が使い方の誤りである。
# scripts/find-banned-word.shが、語を探す前に呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly WORD_LIST="${SCRIPT_DIRECTORY}/../data/banned-word-list.txt"
readonly AMBIGUOUS_WORD_LIST="${SCRIPT_DIRECTORY}/../data/ambiguous-word-list.txt"
readonly PROJECT_WORD_LIST='.harness/rules/word-list.txt'

# 1つの語の一覧を、最後の行に改行が無くてもその行を落とさずに読み、語ごとに1行を出す。
# 引数：一覧のパス、付ける種類
# 出力：「種類<TAB>パターン<TAB>代わりの言い方<TAB>除く形」の行。一覧の誤りは標準エラーに
# 戻り値：読めれば0、一覧が読めないか、代わりの言い方の無い行があれば1
print_word_list() {
  local pattern replacement exclusion
  if [ ! -r "$1" ]; then
    printf 'print-word-list.sh: 語の一覧「%s」が読めません。ハーネスのリポジトリの場所と権限を確かめてください。\n' "$1" >&2
    return 1
  fi
  while IFS=$'\t' read -r pattern replacement exclusion || [ -n "${pattern}" ]; do
    case "${pattern}" in
      '#'* | '') continue ;;
    esac
    if [ -z "${replacement}" ]; then
      printf 'print-word-list.sh: 語の一覧「%s」の「%s」の行に、代わりの言い方がありません。パターンのあとにタブと代わりの言い方を書いてください。\n' "$1" "${pattern}" >&2
      return 1
    fi
    printf '%s\t%s\t%s\t%s\n' "$2" "${pattern}" "${replacement}" "${exclusion}"
  done < "$1"
}

# 確かめる語に導入先の答えを当て、導入先だけの止める語を後ろに足して出す。答えはパターンの文字列どうしで比べる。正規表現で当てると、a|bへの答えがaにも当たるためである。
# 引数：導入先ごとの語の一覧のパス（知らせの文に出す）、scripts/print-project-word-list.shの出力
# 入力：種類を付けたハーネスの2つの一覧の行（標準入力。確かめる語はundecided）
# 出力：種類を決めた行。対応する確かめる語の無い答えの知らせは標準エラーに
# 戻り値：0
print_answered_word() {
  # 文字列をawkの-vでなく環境変数で渡すのは、-vが値の「\」をエスケープとして読むためである。
  PROJECT_PATH="$1" PROJECT_ROW="$2" LC_ALL=C awk -F '\t' -v OFS='\t' '
    BEGIN {
      count = split(ENVIRON["PROJECT_ROW"], rows, "\n")
      for (i = 1; i <= count; i++) {
        split(rows[i], column, "\t")
        answer[column[2]] = (column[1] == "ambiguous-allowed") ? "ambiguous" : "banned"
        if (column[1] != "banned") unmatched[column[2]] = 1
      }
    }
    $1 == "undecided" { delete unmatched[$2]; if ($2 in answer) $1 = answer[$2] }
    { seen[$2] = 1; print }
    END {
      for (i = 1; i <= count; i++)
        if (split(rows[i], column, "\t") && column[1] == "banned" && !(column[2] in seen)) { seen[column[2]] = 1; print rows[i] }
      for (pattern in unmatched)
        printf "print-word-list.sh: 導入先ごとの語の一覧「%s」の「%s」への答えに当たる確かめる語が、ハーネスの一覧にありません。その行を消すか、今の確かめる語のパターンで答え直してください。\n", ENVIRON["PROJECT_PATH"], pattern | "cat 1>&2"
    }'
}

main() {
  local status main_path project_path='' project_row='' ambiguous_kind=ambiguous output
  if [ "$#" -ne 1 ]; then
    printf '%s\n' 'print-word-list.sh: フォルダーを1つだけ渡してください。語の確認を動かすフォルダーを、引数に渡してください。' >&2
    exit 2
  fi
  "${BASH}" "${SCRIPT_DIRECTORY}/find-harness-repository.sh" "$1" > /dev/null
  status=$?
  if [ "${status}" -gt 1 ]; then
    printf 'print-word-list.sh: %sがハーネスのリポジトリの中かを決められないので、語の扱いを決められません。上の文を見て直してください。\n' "$1" >&2
    exit 1
  fi
  # ハーネスのリポジトリでは、確かめる語もすべて止め、導入先ごとの語の一覧を読まない。答えが要らず、読むと語の確認の時間が延びるためである。
  if [ "${status}" -eq 0 ]; then
    ambiguous_kind=banned
  # 導入したリポジトリは、.harness/rulesがフォルダーのものとする。導入していないリポジトリと、サンドボックスが見せる中身の無いファイルでは、答えを残す場所が無いためである。
  elif main_path="$("${BASH}" "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "$1" 2> /dev/null)" \
    && [ -d "${main_path}/.harness/rules" ]; then
    project_path="${main_path}/${PROJECT_WORD_LIST}"
    project_row="$("${BASH}" "${SCRIPT_DIRECTORY}/print-project-word-list.sh" "${project_path}")" || exit 1
    ambiguous_kind=undecided
  fi
  if ! output="$(print_word_list "${WORD_LIST}" banned && print_word_list "${AMBIGUOUS_WORD_LIST}" "${ambiguous_kind}")"; then
    exit 1
  fi
  if [ -z "${output}" ]; then
    printf 'print-word-list.sh: 語の一覧「%s」と「%s」に、語がありません。一覧のファイルを確かめてください。\n' "${WORD_LIST}" "${AMBIGUOUS_WORD_LIST}" >&2
    exit 1
  fi
  if [ -z "${project_path}" ]; then
    printf '%s\n' "${output}"
    exit 0
  fi
  printf '%s\n' "${output}" | print_answered_word "${project_path}" "${project_row}"
  exit 0
}

main "$@"
