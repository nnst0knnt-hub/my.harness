#!/bin/bash
# フックの名前（pre-commitかpre-push）と、pre-pushではgitが渡すリモートの名前とURLと標準入力の送る参照の行を受け取る。置いた変更（git addで次のcommitに入れる変更）か送るcommitの、足した行と、足すか変えたファイルの名前から秘密情報を探し、場所と種類を標準エラーに出す。見つけた値は出さない。秘密情報がリモートに届く前に止めるためである。
# 終了コードは、0が見つからない、1が見つけたか、差分か一覧を読めなかった、2が使い方の誤りである。
# gitが、導入先の.git/configのhook.<名前>.commandで、pre-commitとpre-pushのたびに呼ぶ。理由は、.harness/docs/features/protection.mdの節「gitのフック」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY

# 利用者のgitの設定（例：diff.noprefix、diff.external）で、差分の形が変わらないようにする。--textは、.gitattributesの-diffとbinaryで行を隠さないためである。
diff_options=(-U0 --no-color --no-ext-diff --no-textconv --text --src-prefix=a/ --dst-prefix=b/)

# 送る参照の行を標準入力で読み、送るcommitを選ぶgit logの引数を出す。リモートにあるcommitは、すでに送ってあるので除く。
# 引数：なし
# 出力：引数を1行に1つ。送るcommitが無ければ何も出さない
# 戻り値：0、最後の行のリモートのcommitが手元に無ければ0以外（呼ぶ側は値を使わない）
print_push_revision() {
  local local_object remote_object
  while read -r _ local_object _ remote_object; do
    # すべて0の名前は、ブランチを消す行と、リモートに無いブランチである。
    case "${local_object}" in *[!0]*) ;; *) continue ;; esac
    printf '%s\n' "${local_object}"
    case "${remote_object}" in
      *[!0]*) git cat-file -e "${remote_object}^{commit}" 2> /dev/null && printf '^%s\n' "${remote_object}" ;;
    esac
  done
}

# 置いた変更か送るcommitの、足した行を「場所<TAB>中身」の形で出す。
# 引数：pre-commitかpre-push、pre-pushではgit logの引数
# 出力：足した行を1行に1つ
# 戻り値：差分を読めたら0、gitが失敗したら0以外
print_added_line() {
  if [ "$1" = 'pre-commit' ]; then
    git -c core.quotePath=false diff --cached "${diff_options[@]}"
  else
    shift
    # --rootは、log.showRoot=falseの設定でも、最初のcommitの差分を出すためである。
    git -c core.quotePath=false log -p --cc --root --format=%h "${diff_options[@]}" "$@"
  fi | "${BASH}" "${SCRIPT_DIRECTORY}/print-added-line.sh"
}

# 置いた変更か送るcommitで、足すか変えたファイルのパスを出す。マージのcommitでは、どの親とも違うファイルだけを出す。
# 引数：pre-commitかpre-push、pre-pushではgit logの引数
# 出力：パスを1行に1つ
# 戻り値：読めたら0、gitが失敗したら0以外
print_changed_file() {
  if [ "$1" = 'pre-commit' ]; then
    git diff --cached --name-only -z --diff-filter=ACMR
  else
    shift
    git log --format= --name-only -z --cc --root --diff-filter=ACMR "$@"
  fi | tr '\0' '\n'
}

main() {
  local revision kind found=0
  local revisions=() statuses=()
  if ! { [ "$#" -eq 1 ] && [ "$1" = 'pre-commit' ]; } && ! { [ "$#" -eq 3 ] && [ "$1" = 'pre-push' ]; }; then
    printf '%s\n' 'find-secret-in-commit.sh: gitのフックとして、pre-commitか、pre-pushとリモートの名前とURLを渡して呼んでください。' >&2
    exit 2
  fi
  if [ "$1" = 'pre-push' ]; then
    while IFS= read -r revision; do revisions+=("${revision}"); done < <(print_push_revision)
    if [ "${#revisions[@]}" -eq 0 ]; then
      exit 0
    fi
    revisions+=(--not "--remotes=$2" --)
  fi
  for kind in content file-name; do
    # 空の配列をset -uのもとで展開しないように、「+」の形で渡す。
    if [ "${kind}" = 'content' ]; then
      print_added_line "$1" ${revisions[@]+"${revisions[@]}"} | "${BASH}" "${SCRIPT_DIRECTORY}/find-secret-in-line.sh" "${kind}"
    else
      print_changed_file "$1" ${revisions[@]+"${revisions[@]}"} | "${BASH}" "${SCRIPT_DIRECTORY}/find-secret-in-line.sh" "${kind}"
    fi
    statuses=("${PIPESTATUS[@]}")
    # 差分を読めないまま通すと、秘密情報を見逃すので止める。一覧を読めないときは、find-secret-in-line.shが理由を出す。
    if [ "${statuses[0]}" -ne 0 ]; then
      printf 'find-secret-in-commit.sh: %sで、置いた変更か送るcommitの差分を読めなかったので、止めました。gitの出力を確かめてください。\n' "${PWD}" >&2
      exit 1
    fi
    case "${statuses[1]}" in
      0) ;;
      1) found=1 ;;
      *) exit 1 ;;
    esac
  done
  if [ "${found}" -eq 1 ]; then
    printf 'find-secret-in-commit.sh: 秘密情報を見つけたので、%sを止めました。秘密情報を消して（例：環境変数から読む）、commitを作り直してください。誤検知なら、人が確かめてから--no-verifyで動かしてください。\n' "${1#pre-}" >&2
    exit 1
  fi
  exit 0
}

main "$@"
