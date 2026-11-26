#!/bin/bash
# 作業フォルダーとメインの作業フォルダーを受け取り、Claude Codeの設定のファイルと.mcp.jsonから、data/loosening-claude-setting-list.tsvのキーを読む。ハーネスの保護を止める値と、保護を緩めるかサンドボックスの外で動く項目を、「状態<TAB>項目<TAB>起きること<TAB>直し方」の1行ずつで標準出力に出す。人が、導入先の設定と、ハーネスの外の処理が足した設定に気づけるようにするためである。
# 状態は、働く、働かない、確かめる、わからないで、直し方の無い行は「-」にする。終了コードは、0が行を出した、2が使い方の誤りである。
# scripts/print-protection-status.shが呼ぶ。読むキーと読み方の理由は、.harness/docs/features/protection.mdの節「環境を確かめるスクリプト」に書く。
set -u -o pipefail

HARNESS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
readonly HARNESS_ROOT
readonly UNKNOWN_DETAIL='保護を止めるか緩める設定を、確かめられません。'

# 一覧の行ごとに、働かないの行は実際に使う値を、確かめるの行はファイルごとの値を見る。$で始まる語は、シェルではなくjqの変数である。
# shellcheck disable=SC2016
readonly PROGRAM='
  def files($scope):
    [{path: $pc_path, kind: "pc", value: $pc[0]}, {path: $shared_path, kind: "project", value: $shared[0]},
      {path: $local_path, kind: "project", value: $local[0]}, {path: $mcp_path, kind: "mcp", value: $mcp[0]}]
    | map(select(if $scope == ".mcp.json" then .kind == "mcp" elif $scope == "導入先" then .kind == "project"
      elif $scope == "PC" then .kind == "pc" else .kind != "mcp" end));
  def read_value($path): try getpath($path) catch null;
  # 止める値が「*」でない確かめるの行は、その名前のキーを中に持つ項目だけを示す。「~」で始まる止める値は、文字列の項目を後ろの正規表現で選ぶ。
  def has_key($match): $match == "*" or (if ($match | startswith("~")) then (type == "string" and test($match[1:]))
    else ([.. | objects | has($match)] | any) end);
  # ハーネスのプラグインを有効にする値は、保護を緩めないので示さない。
  def entries($match):
    if type == "array" then map(select(has_key($match)) | tojson)
    elif type == "object" then to_entries
      | map(select(.value != false and .key != "my-harness@nnst0knnt" and (.value | has_key($match)))
        | "\(.key): \(.value | tojson)")
    elif . == null or . == false then []
    else [tojson] end;
  [inputs | select(length > 0 and (startswith("#") | not)) | split("\t")
    | . as [$state, $scope, $key, $match, $detail, $fix] | ($key | split(".")) as $path
    | if $state == "働かない" and ($match | startswith("~") | not) then
        # Claude Codeは、.claude/settings.local.json、.claude/settings.json、PCの設定の順で、最初に書いた値を使う。
        # 読むファイルがPCの行は、導入先の値が当たらないか、導入先の値を確かめるの行で示すキーで、PCの値はほかの導入先でも当たるので、PCの設定の値だけで決める。
        first(files(if $scope == "PC" then "PC" else "PCと導入先" end) | reverse[]
          | select((.value | read_value($path)) != null))
        | (.value | read_value($path)) as $value
        | select(($scope != "導入先" or .kind == "project") and ($match == "*" or ($value | tojson) == $match))
        | "\($state)\t\(.path)の\($key)（\($value | tojson)）\t\($detail)\t\($fix)"
      else
        files($scope)[] | (.value | read_value($path) | entries($match)) as $entries | select($entries | length > 0)
        | "\($state)\t\(.path)の\($key)（\($entries | join("、"))）\t\($detail)\t\($fix)"
      end]
  | if length == 0 then "働く\tClaude Codeの設定\t保護を止める値と、保護を緩めるかサンドボックスの外で動く項目はありません。\t-"
    else .[] end'

# 読む設定のファイルを、jqの変数の名前とパスの組で出す。.claude/settings.local.jsonは、worktreeでもメインの作業フォルダーのものが使われる。
# 引数：作業フォルダー、メインの作業フォルダー
# 出力：「名前<TAB>パス」を1行に1つ
# 戻り値：0
print_setting_file_list() {
  printf 'pc\t%s\n' "${CLAUDE_CONFIG_DIR:-${HOME}/.claude}/settings.json"
  printf 'shared\t%s\n' "$1/.claude/settings.json"
  printf 'local\t%s\n' "$2/.claude/settings.local.json"
  printf 'mcp\t%s\n' "$1/.mcp.json"
}

main() {
  local name file output
  local option=()
  if [ "$#" -ne 2 ]; then
    printf '%s\n' 'print-claude-setting-status.sh: 作業フォルダーとメインの作業フォルダーを渡してください。' >&2
    exit 2
  fi
  if ! jq --version > /dev/null 2>&1; then
    printf 'わからない\tClaude Codeの設定（jqが動きません）\t%s\tjqを入れてください（例：sudo apt-get install jq、brew install jq）。\n' \
      "${UNKNOWN_DETAIL}"
    exit 0
  fi
  while IFS=$'\t' read -r name file; do
    option+=(--arg "${name}_path" "${file}")
    # 無いファイル、フォルダー、サンドボックスの中で無いファイルの場所に置かれる文字デバイスは、無いファイルとして読む。
    if [ ! -f "${file}" ]; then
      option+=(--slurpfile "${name}" /dev/null)
      continue
    fi
    if ! jq empty "${file}" > /dev/null 2>&1; then
      printf 'わからない\tClaude Codeの設定（%sを読めません）\t%s\tファイルの権限とJSONの形を確かめてください。\n' \
        "${file}" "${UNKNOWN_DETAIL}"
      exit 0
    fi
    option+=(--slurpfile "${name}" "${file}")
  done < <(print_setting_file_list "$1" "$2")
  if ! output="$(jq -n -r -R "${option[@]}" "${PROGRAM}" "${HARNESS_ROOT}/data/loosening-claude-setting-list.tsv" \
    2> /dev/null)"; then
    printf 'わからない\tClaude Codeの設定（%sを読めません）\t%s\tハーネスのファイルを確かめてください。\n' \
      "${HARNESS_ROOT}/data/loosening-claude-setting-list.tsv" "${UNKNOWN_DETAIL}"
    exit 0
  fi
  printf '%s\n' "${output}"
  exit 0
}

main "$@"
