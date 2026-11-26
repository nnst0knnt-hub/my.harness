#!/bin/bash
# 作業フォルダーとコマンドの文字列を受け取り、1行目に判定（allowが通す、askが確認を求める、denyが止める）、2行目に理由の文を出す。サンドボックスの外で動くgit push、git fetch、gh、glabのうち、判定できる簡単な形だけを通し、判定できない形を止めるためである。
# 外で動かす形をgitのフォルダーを固定する形に書き換える判定（git push、git fetch、glabの通すか確認を求めるものと、確認を求めるgh）では、3～5行目に判定で求めたgitのフォルダー、共通のgitのフォルダー、作業フォルダーの一番上、6行目にサブモジュールに入るか（recurseかno-recurse）、7行目に、git pushの送り元を手元のcommitのSHAにしたコマンドを出す。
# 終了コードは、0が判定を出した、2が使い方の誤りである。hooks/read-bash-command.shが、Claude Codeがgit push、git fetch、git pull、gh、glabを動かす前に呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
# フックは、Claude Codeが区切れないコマンドでも動くので、ほかのコマンドの直し方も示す。
readonly SIMPLE_FORM='git push、git fetch、gh、glabは、前に何も付けず、ほかのコマンドとつながずに、1つで動かしてください（例：git push origin feat/x:feat/x）。ほかのコマンドでこの文が出たときは、Claude Codeがコマンドを区切れなかったので、区切りの記号、展開、繰り返し、引用符の中の\（例：&&、$、for）を使わない、1つずつのコマンドに分けて動かしてください。'
readonly UNPINNED_REASON='gitのフォルダーと作業フォルダーの一番上を求められないので止めます（例：gitの外、bareのリポジトリ、改行か復帰を含むパス）。git push、git fetch、glab、確認を求めるghは、判定で求めたgitのフォルダーに固定して外で動かすので、gitのリポジトリの作業フォルダーの中で動かしてください。'
# @COMMON@は、外のgitが設定とフックを読む共通のgitのフォルダーに置き換え、人が確認の文から場所を読めるようにする。
readonly OTHER_REPOSITORY_REASON='Claude Codeの作業フォルダー（CLAUDE_PROJECT_DIR）のリポジトリとみなせない場所（例：別のリポジトリ、.claude/worktrees/の外のworktree、.gitを書き換えたworktree）で動かします。外のgitは@COMMON@の設定とフックを使い、そこはサンドボックスの中から書けることがあるので、確認を求めます。'

main() {
  local command main_directory unsafe_reason word output='' decision reason location='' project_common='' recurse='' repository='other'
  local pinned_command='' is_checked=0 is_pinned=0
  local words=()
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'classify-remote-command.sh: 作業フォルダーとコマンドの文字列の2つを渡してください。' >&2
    exit 2
  fi
  # 末尾の2>&1は、出力をつなぐだけで、外に出す形からも外れないので許す。全体の最後で前の語と空白で分かれたものだけを外し、本文の途中の行末の2>&1は語の一部のまま残す。
  command="$("${BASH}" "${SCRIPT_DIRECTORY}/print-command-without-trailing-redirect.sh" "$2")"
  # 語はNULで終えて出るので、分けられるかを確かめてから、もう一度呼んで読む。
  if ! unsafe_reason="$("${BASH}" "${SCRIPT_DIRECTORY}/print-command-word.sh" "${command}" 2>&1 > /dev/null)"; then
    printf 'deny\n%s%s\n' "${unsafe_reason}" "${SIMPLE_FORM}"
    exit 0
  fi
  while IFS= read -r -d '' word; do
    words+=("${word}")
  done < <("${BASH}" "${SCRIPT_DIRECTORY}/print-command-word.sh" "${command}" 2> /dev/null)
  # 判定の中のgitと外で動かすコマンドが同じ場所を使うよう、場所を1回だけ求めてexportする。フックが渡すCLAUDE_PROJECT_DIRのリポジトリは、導入先のリポジトリとみなせる形のときだけ求め、exportの前に求める。
  if location="$("${BASH}" "${SCRIPT_DIRECTORY}/print-git-directory.sh" "$1" 2> /dev/null)"; then
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
      project_common="$("${BASH}" "${SCRIPT_DIRECTORY}/print-project-common-directory.sh" "${CLAUDE_PROJECT_DIR}" 2> /dev/null)"
    fi
    { IFS= read -r GIT_DIR && IFS= read -r GIT_COMMON_DIR && IFS= read -r GIT_WORK_TREE; } <<< "${location}"
    export GIT_DIR GIT_COMMON_DIR GIT_WORK_TREE GIT_NO_LAZY_FETCH=1
    if [ -n "${project_common}" ] && [ "${project_common}" = "${GIT_COMMON_DIR}" ]; then repository='project'; fi
  else
    location=''
  fi
  # .harness/configは、worktreeの中でも、メインの作業フォルダーのものを読む。
  if ! main_directory="$("${BASH}" "${SCRIPT_DIRECTORY}/print-main-worktree-path.sh" "$1" 2> /dev/null)"; then
    main_directory="$1"
  fi
  # 空の配列をset -uのもとで展開しないように、要素の数を先に見る。
  if [ "${#words[@]}" -ge 2 ] && [ "${words[0]}" = 'git' ]; then
    case "${words[1]}" in
      push) output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-git-push-command.sh" "$1" "${main_directory}" "${words[@]:2}")" ;;
      fetch) output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-git-fetch-command.sh" "$1" "${words[@]:2}")" ;;
      pull) output="$(printf 'deny\n%s\n' 'git pullは、サンドボックスの外で作業フォルダーを書き換えるので止めます。git fetch <リモート> <ブランチ>のあとに、git merge --ff-only <リモート>/<ブランチ>を動かしてください（例：git fetch origin main、git merge --ff-only origin/main）。')" ;;
    esac
  elif [ "${#words[@]}" -ge 1 ] && [ "${words[0]}" = 'gh' ]; then
    output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-gh-command.sh" "${words[@]:1}")"
  elif [ "${#words[@]}" -ge 1 ] && [ "${words[0]}" = 'glab' ]; then
    output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-glab-command.sh" "${words[@]:1}")"
  fi
  decision="$(printf '%s\n' "${output}" | sed -n 1p)"
  reason="$(printf '%s\n' "${output}" | sed -n 2p)"
  case "${decision}" in
    # 通すか確認を求めるコマンドは、外で動くgitとglabが使う手元のgitの状態も見て、判定を強める。
    allow | ask)
      output="$("${BASH}" "${SCRIPT_DIRECTORY}/classify-local-git-state.sh" "$1" "${main_directory}" "${repository}" "${decision}" "${reason}" "${words[@]}")"
      decision="$(printf '%s\n' "${output}" | sed -n 1p)" && reason="$(printf '%s\n' "${output}" | sed -n 2p)"
      pinned_command="$(printf '%s\n' "${output}" | sed -n 3p)" && is_checked=1
      ;;
    deny) ;;
    '') decision='deny' && reason="先頭がgit push、git fetch、gh、glabではないので、判定できません（例：前に付けた環境変数、timeout、git -C）。${SIMPLE_FORM}" ;;
    *) decision='ask' && reason='判定のスクリプトが、決まった判定を返しませんでした。' ;;
  esac
  # 外で動かす形は、gitのフォルダーを固定するスクリプトの呼び出しだけなので、場所を求められなければ止める。確認なしで通すghの読み取りは、固定しない。
  if [ "${is_checked}" -eq 1 ] && [ "${decision}" != 'deny' ] && { [ "${words[0]}" != 'gh' ] || [ "${decision}" = 'ask' ]; }; then
    if [ -z "${location}" ]; then
      decision='deny' && reason="${UNPINNED_REASON}"
    elif case "${pinned_command}" in *$'\n'* | *$'\r'*) true ;; *) false ;; esac; then
      decision='deny' && reason='送り元をSHAにしたpushのコマンドに、改行か復帰があります。改行と復帰の無い名前のリモートとブランチで書いてください。'
    else
      # 置換の${x/a/b}は、bash 5.2で置き換える値の&を見つけた字に変えるので、前と後ろを切って間に場所を入れる。
      [ "${repository}" = 'project' ] \
        || { decision='ask' && reason="${reason}${OTHER_REPOSITORY_REASON%%@COMMON@*}${GIT_COMMON_DIR}${OTHER_REPOSITORY_REASON#*@COMMON@}"; }
      recurse='no-recurse'
      [ ! -e "${GIT_COMMON_DIR}/modules" ] || recurse='recurse'
      is_pinned=1
    fi
  fi
  # 1行に1つで出すので、理由の文の改行と復帰は空白にする。
  reason="${reason//$'\n'/ }" && reason="${reason//$'\r'/ }"
  if [ "${is_pinned}" -eq 0 ]; then
    printf '%s\n%s\n' "${decision}" "${reason}"
    exit 0
  fi
  printf '%s\n' "${decision}" "${reason}" "${GIT_DIR}" "${GIT_COMMON_DIR}" "${GIT_WORK_TREE}" "${recurse}" "${pinned_command}"
  exit 0
}

main "$@"
