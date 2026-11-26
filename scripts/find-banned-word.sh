#!/bin/bash
# 渡したファイルから、今の作業フォルダーで使う語（scripts/print-word-list.shが、止める語、確かめる語、導入先ごとの語の一覧から決める）を探し、見つけた場所と次にすることを標準エラーに出す。書いたあとに毎回同じ基準で見つけるためである。
# 終了コードは、0が止める語なし、1が止める語あり、2が使い方の誤りか、語の一覧が読めないか、ハーネスのリポジトリの中かを決められない、である。確かめる語は、ハーネスのリポジトリと、導入先で禁止にすると答えた語だけで止め、ほかでは示すか、禁止にするかが決まっていないと示す。
# エージェントと人が文章を書いたあとに呼ぶ。ハーネスのリポジトリのcommit-msgのフックがコミットメッセージに当て、tests/run-test-suite.shが語の確認から外すファイルを除いて呼ぶ。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# 除く形の無い語に渡す、文書に現れない制御文字である。
readonly NO_EXCLUSION=$'\x02'

word_patterns=()
word_exclusions=()
word_kinds=()
word_messages=()
grep_arguments=()

# 今の作業フォルダーで使う語をscripts/print-word-list.shで読み、パターン、除く形、種類、説明の文、grepに渡す引数を配列に入れる。
# 引数：なし
# 出力：一覧の誤りを標準エラーに（print-word-list.shが出す）
# 戻り値：読めれば0、読めなければ1
read_word_list() {
  local list kind pattern replacement exclusion
  # 今の作業フォルダーを渡すのは、エージェントとcommit-msgのフックが、書いているリポジトリの中で動かすためである。
  list="$("${BASH}" "${SCRIPT_DIRECTORY}/print-word-list.sh" "${PWD}")" || return 1
  while IFS=$'\t' read -r kind pattern replacement exclusion; do
    word_kinds+=("${kind}")
    word_patterns+=("${pattern}")
    word_exclusions+=("${exclusion:-${NO_EXCLUSION}}")
    # 説明の文は、語ごとに1回だけ作る。見つけるたびに作ると、プロセスが増えるためである。見つけた語を入れる所は%sにする。
    case "${kind}" in
      ambiguous) word_messages+=("確かめる語「%s」があります。業務の言葉か導入先の表記の決めでなければ、代わりの言い方（例：${replacement}）に変えてください。") ;;
      undecided) word_messages+=("確かめる語「%s」（一覧のパターン「${pattern}」）は、この導入先で禁止にするかが決まっていません。業務の言葉か導入先の表記の決めでなければ、代わりの言い方（例：${replacement}）に変えてください。PRを作る前の確認か完了の報告で、人に「この導入先でも禁止にしますか？」とまとめて聞き、答えをメインの作業フォルダーの.harness/rules/word-list.txtに書いてください。") ;;
      *) word_messages+=("止める語「%s」があります。代わりの言い方（例：${replacement}）に変えるか、削ってください。") ;;
    esac
    # 除く形もここで渡し、grepが読めない形をmainで見つける。
    grep_arguments+=(-e "${pattern}" -e "${exclusion:-${NO_EXCLUSION}}")
  done <<< "${list}"
}

# 1つのファイルから1つの語を探し、場所と説明を出す。除く形は、語に当たらない制御文字に置き換えてから当てる。行ごと外すと、同じ行の止める語を見逃すためである。
# 引数：ファイルのパス、語のERE、除く形のERE、説明の文（見つけた語を入れる所は%s）
# 出力：「ファイル:行: 説明」の行
# 戻り値：0か、grepかawkの終了コード（呼ぶ側は出力で決める）
print_banned_word() {
  # ファイルのパスと文をawkの-vでなく環境変数で渡すのは、-vが値の「\」をエスケープとして読むためである。
  LC_ALL=C sed -E $'s\x01'"$3"$'\x01\x02\x01g' "$1" | LC_ALL=C grep -anoE -e "$2" |
    PREFIX="$1" MESSAGE="$4" LC_ALL=C awk '{
      line = $0
      sub(/:.*/, "", line)
      word = substr($0, length(line) + 2)
      at = index(ENVIRON["MESSAGE"], "%s")
      print ENVIRON["PREFIX"] ":" line ": " substr(ENVIRON["MESSAGE"], 1, at - 1) word substr(ENVIRON["MESSAGE"], at + 2)
    }'
}

main() {
  local file i output status=0
  if [ "$#" -eq 0 ]; then
    printf '%s\n' 'find-banned-word.sh: ファイルが渡されていません。確かめるファイルを、引数に渡してください。' >&2
    exit 2
  fi
  if ! read_word_list; then
    exit 2
  fi
  for file in "$@"; do
    if [ ! -f "${file}" ] || [ ! -r "${file}" ]; then
      printf 'find-banned-word.sh: ファイル「%s」が見つからないか、読めません。パスと権限を確かめてください。\n' "${file}" >&2
      exit 2
    fi
    # 先にすべての語を1回で当て、当たったファイルだけを語ごとに見る。語とファイルの組ごとにgrepを動かすと、遅いためである。
    LC_ALL=C grep -aqE "${grep_arguments[@]}" "${file}"
    case "$?" in
      0) ;;
      1) continue ;;
      *)
        printf '%s\n' 'find-banned-word.sh: data/banned-word-list.txtかdata/ambiguous-word-list.txtのパターンを、grepが読めませんでした。パターンを、grep -Eで読める形に直してください。' >&2
        exit 2
        ;;
    esac
    for i in "${!word_patterns[@]}"; do
      # 当たらない語のプロセスを省く。除く形の置き換えは新しい当たりを作らないので、判定は変わらない。
      LC_ALL=C grep -aqE -e "${word_patterns[i]}" "${file}" || continue
      output="$(print_banned_word "${file}" "${word_patterns[i]}" "${word_exclusions[i]}" "${word_messages[i]}")"
      if [ -z "${output}" ]; then
        continue
      fi
      printf '%s\n' "${output}" >&2
      # 示すだけの語のほかは、知らない種類も止める語として数える。誤ったときに、語が黙って通らないためである。
      case "${word_kinds[i]}" in
        ambiguous | undecided) ;;
        *) status=1 ;;
      esac
    done
  done
  exit "${status}"
}

main "$@"
