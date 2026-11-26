#!/bin/bash
# 判定の理由の文とフックの記録の名前を受け取り、確認の画面に出す理由の文（permissionDecisionReason）を標準出力に出す。書き換えたコマンドには記録の名前しか残らないので、人が理由の文で、外で動く語を見て認めるためである。
# 終了コードは、0が出した、1が記録を読めなかったか文を作れなかった、2が使い方の誤りである。
# hooks/read-bash-command.shが、hooks/write-pinned-command-record.shで記録を書いたあとに呼ぶ。理由は、.harness/docs/features/protection.mdの節「送り元とgitのフォルダーの固定」に書く。
set -u -o pipefail
# 語はバイトのまま読んで囲み、字の数はjqで数える。bashの${#x}は、ロケールでバイトの数か字の数かが変わるためである。
export LC_ALL=C

HOOK_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly HOOK_DIRECTORY
# 確認の画面は長い理由の文を切ることがあるので、語と全体を先に切って、全文のファイルのパスを付ける。値は、本文の初めとほかのオプションが読める長さの目安で、根拠の資料は無い。
readonly WORD_LIMIT=300
readonly REASON_LIMIT=1500

# 理由の文を標準エラーに出して終わる。
# 引数：終了コード、理由の文
# 出力：標準エラーに1行
# 戻り値：なし（exitする）
exit_with_error() {
  printf 'print-pinned-command-reason.sh: %s\n' "$2" >&2
  exit "$1"
}

# 数を3桁ごとにカンマで区切って出す。
# 引数：数
# 出力：区切った数（最後に改行を足さない）
# 戻り値：0
print_grouped_number() {
  local number="$1" grouped=''
  while [ "${#number}" -gt 3 ]; do
    grouped=",${number:${#number}-3}${grouped}"
    number="${number:0:${#number}-3}"
  done
  printf '%s%s' "${number}" "${grouped}"
}

main() {
  local record word length label text index=4 shortened=''
  local words=() shown=()
  if [ "$#" -ne 2 ] || ! record="$("${BASH}" "${HOOK_DIRECTORY}/print-pinned-command-record-path.sh" "$2" 2> /dev/null)"; then
    exit_with_error 2 '判定の理由の文と、英数字のフックの記録の名前の2つを渡してください。'
  fi
  [ -r "${record}" ] || exit_with_error 1 "フックの記録（${record}）を読めません。hooks/write-pinned-command-record.shが書いたかを確かめてください。"
  while IFS= read -r -d '' word; do
    words+=("${word}")
  done < "${record}"
  [ "${#words[@]}" -ge 5 ] || exit_with_error 1 "フックの記録（${record}）に、3つの場所、recurseかno-recurse、動かすコマンドがそろっていません。hooks/write-pinned-command-record.shを確かめてください。"
  # 記録の1～4つ目は場所とrecurseなので、5つ目からが動かす語である。
  while [ "${index}" -lt "${#words[@]}" ]; do
    word="${words[index]}"
    # バイトの数が上限以下なら、字の数も上限以下なので、jqを呼ばない。
    if [ "${#word}" -gt "${WORD_LIMIT}" ]; then
      length="$(jq -n -r --arg word "${word}" '$word | length')" || exit_with_error 1 'jqで語の字数を数えられませんでした。jqが動くかを確かめてください。'
      if [ "${length}" -gt "${WORD_LIMIT}" ]; then
        label="$((index - 3))番目の語"
        case "${words[index - 1]}" in -*) label="${words[index - 1]}の値" ;; esac
        shortened="${shortened}${shortened:+、}${label}：$(print_grouped_number "${length}")字"
        # $(...)が最後の改行を消さないよう、後ろに1字足してから外す。
        word="$(jq -n -j --arg word "${word}" --argjson limit "${WORD_LIMIT}" '$word[:$limit] + "."')" \
          || exit_with_error 1 'jqで語を切れませんでした。jqが動くかを確かめてください。'
        word="${word%.}"
      fi
    fi
    shown+=("${word}")
    index=$((index + 1))
  done
  text="$1"$'\n'"動かすコマンド：$("${BASH}" "${HOOK_DIRECTORY}/../scripts/print-quoted-word.sh" "${shown[@]}")" \
    || exit_with_error 1 'scripts/print-quoted-word.shで語を囲めませんでした。ハーネスのscripts/を確かめてください。'
  [ -z "${shortened}" ] || text="${text}"$'\n'"${WORD_LIMIT}字を超える語は、初めの${WORD_LIMIT}字だけを出しました（${shortened}）。全文：${record}.txt"
  # 切る位置をパスの長さで変えないよう、初めの上限の字数で切ってから、全文のファイルの行を足す。
  jq -n -r --arg text "${text}" --argjson limit "${REASON_LIMIT}" \
    --arg tail $'\n'"理由の文が$(print_grouped_number "${REASON_LIMIT}")字を超えたので、ここで切りました。全文：${record}.txt" \
    'if ($text | length) > $limit then $text[:$limit] + $tail else $text end' \
    || exit_with_error 1 'jqで理由の文を切れませんでした。jqが動くかを確かめてください。'
  exit 0
}

main "$@"
