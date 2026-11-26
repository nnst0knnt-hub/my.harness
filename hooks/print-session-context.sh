#!/bin/bash
# ハーネスの場所、メインの作業フォルダー、共通のルール、導入先ごとのルール、文書の目次を、Markdownで標準出力に出す。エージェントが、毎回のセッションでルールを読めるようにするためである。
# 終了コードは、いつも0である。読めないファイルがあっても、標準エラーと1ではなく、標準出力に書いて0を返す。文脈に入るのは0のときの標準出力だけで、1を返すと読めたルールまで渡らない。標準エラーは、エージェントが読めない。この点で、CONTRIBUTING.mdの節「エラーメッセージ」から外れる。
# Claude CodeのSessionStartのフック（hooks/hooks.json）が、セッションの始め、再開、/clear、会話の圧縮、forkのたびに呼ぶ。
set -u -o pipefail

# 出力の全体の字数の上限は、.harness/docs/features/always-read-rule.mdの表の「フックの出力の全体」の行の、8,000字である。
readonly CHARACTER_LIMIT=8000

# 文字列の字数を、改行を含めて数える。数え方は、scripts/find-long-rule.shと同じである。
# 引数：文字列
# 出力：字数
# 戻り値：0
count_character() {
  local byte_count
  # UTF-8の続きのバイト（0x80～0xBF）を消して、1文字を1バイトにする。ロケールとwcの実装に依らないためである。
  byte_count="$(printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c)"
  printf '%s\n' "$((byte_count))"
}

# 1つのファイルの節を出す。
# 引数：節の題、ファイルのパス、本文を省くときの案内の文（空なら本文を出す）
# 出力：節の題の行、場所の行、本文か案内の文
# 戻り値：0
print_file_section() {
  printf "\n## %s\n\n場所：\`%s\`\n\n" "$1" "$2"
  # リンクをたどらないのは、フックが権限の外で動き、リンク先の秘密情報（例：.env）を文脈に出すおそれがあるためである。
  if [ -L "$2" ]; then
    printf '%s\n' '読めませんでした。シンボリックリンクは、リンク先の秘密情報を出さないように読みません。実体のファイルを置くよう、人に伝えてください。'
  elif [ ! -e "$2" ]; then
    printf '%s\n' 'なし（ファイルがありません）'
  elif [ ! -f "$2" ] || [ ! -r "$2" ]; then
    printf '%s\n' '読めませんでした。ファイルの権限を確かめるよう、人に伝えてください。'
  elif [ -n "$3" ]; then
    printf '%s\n' "$3"
  else
    cat "$2"
  fi
}

# 渡す文脈の全体を出す。
# 引数：ハーネスの場所、メインの作業フォルダー、場所の表に添える文、導入先ごとのルールと目次を省くときの案内の文（空なら本文を出す）、環境の状態の節
# 出力：Markdownの文脈
# 戻り値：0
print_context() {
  printf '%s\n\n' '# my.harnessがセッションの始めに渡す文脈'
  printf '%s\n%s\n' '| 項目 | 場所 |' '|---|---|'
  printf "| ハーネスの場所 | \`%s\` |\n" "$1"
  printf "| メインの作業フォルダー | \`%s\`%s |\n\n" "$2" "$3"
  printf '%s\n' "ルールの中の「ハーネスの～」は、ハーネスの場所からのパスである。\`.harness/\`は、worktreeの中でも、メインの作業フォルダーのものを読む。"
  printf '\n%s\n' "$6"
  print_file_section '共通のルール' "$1/rules/always-read.md" ''
  print_file_section '導入先ごとのルール' "$2/.harness/rules/always-read.md" "$4"
  print_file_section '文書の目次' "$2/.harness/docs/README.md" "$5"
}

main() {
  local harness_root project_directory main_directory note='' output environment
  local omitted_message="合計が$((CHARACTER_LIMIT / 1000)),000字を超えるので、本文を省きました。作業の前に、このファイルを開いて読んでください。"
  # ハーネスの場所は、このスクリプトの場所から求める（.harness/docs/architecture.mdの節「配置の理由」）。
  harness_root="$(cd "$(dirname "$0")/.." && pwd)"
  project_directory="${CLAUDE_PROJECT_DIR:-${PWD}}"
  if ! main_directory="$("${BASH}" "${harness_root}/scripts/print-main-worktree-path.sh" \
    "${project_directory}" 2> /dev/null)"; then
    main_directory="${project_directory}"
    note='（gitの外か、メインの作業フォルダーを求められないので、今の作業フォルダー）'
  fi
  environment="$("${BASH}" "${harness_root}/hooks/print-environment-state.sh" \
    "${project_directory}" "${main_directory}" 2> /dev/null)"
  output="$(print_context "${harness_root}" "${main_directory}" "${note}" '' '' "${environment}")"
  # 超えたら、導入先ごとのルールだけ、目次だけ、両方の順に、本文を場所だけにする。共通のルールまで先頭だけに切られないためである。
  if [ "$(count_character "${output}")" -gt "${CHARACTER_LIMIT}" ]; then
    output="$(print_context "${harness_root}" "${main_directory}" "${note}" "${omitted_message}" '' "${environment}")"
  fi
  if [ "$(count_character "${output}")" -gt "${CHARACTER_LIMIT}" ]; then
    output="$(print_context "${harness_root}" "${main_directory}" "${note}" '' "${omitted_message}" "${environment}")"
  fi
  if [ "$(count_character "${output}")" -gt "${CHARACTER_LIMIT}" ]; then
    output="$(print_context "${harness_root}" "${main_directory}" "${note}" "${omitted_message}" \
      "${omitted_message}" "${environment}")"
  fi
  printf '%s\n' "${output}"
  exit 0
}

main "$@"
