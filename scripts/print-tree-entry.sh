#!/bin/bash
# リポジトリのフォルダー、commitのSHA、パスを受け取り、そのcommitのパスのmodeとSHAを1行で出す（パスが無ければ何も出さない）。commitと、パスまでのtreeは、読んだ中身から計算し直したSHAと照らす。サンドボックスの中から偽れる手元のオブジェクト（例：refs/replace/、commit-graph、偽のオブジェクトのファイル）を、本物として読まないためである。
# 終了コードは、0が出せたかパスが無い、1が照らしたSHAが合わないか、読めないか、パスかSHAの形が誤っている、2が使い方の誤りである。
# scripts/classify-git-push-commit.shが、比べる元と送るcommitのCIの設定のファイルを比べるときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「CIの設定のファイルを変えるpush」に書く。
set -u -o pipefail

directory=''

# 置き換えの参照とcommit-graphを使わずに、gitを動かす。
# 引数：gitの引数
# 出力：gitの標準出力
# 戻り値：gitの戻り値
run_git() {
  git --no-replace-objects -c core.commitGraph=false -C "${directory}" "$@" 2> /dev/null
}

# 16進の数字を空白か改行で区切って並べた文字列を、そのバイトに戻して出す。
# 引数：16進の文字列（odの-tx1の出力）
# 出力：バイトの並び
# 戻り値：0
print_byte() {
  # 書式の文字列は、16進の数字から作った\xHHだけで、%を含まない。
  # shellcheck disable=SC2059
  printf "$(printf '%s' "$1" | LC_ALL=C tr -d ' \n' | LC_ALL=C sed 's/../\\x&/g')"
}

# オブジェクトを1回だけ読み、読んだ中身から計算し直したSHAが渡したSHAと合えば、中身を16進で出す。読むコマンドと照らすコマンドを分けると、その間にファイルを差し替えられるためである。
# 引数：オブジェクトの種類（commit、tree）、SHA
# 出力：中身の16進の文字列
# 戻り値：合えば0、合わないか読めなければ1
print_verified_object() {
  local hex
  hex="$(run_git cat-file "$1" "$2" | od -An -v -tx1)" || return 1
  # --literallyは、gitの形の確かめ（fsck）を外し、SHAが合うかだけを見る。形の古い本物のcommitで、確認を増やさないためである。
  [ "$(print_byte "${hex}" | run_git hash-object --literally -t "$1" --stdin)" = "$2" ] || return 1
  printf '%s\n' "${hex}"
}

# treeの中身の16進から、名前の合う項目を探し、modeとSHAを出す。
# 引数：treeの中身の16進の文字列、名前の16進の文字列（区切り無し）、SHAのバイト数
# 出力：「<mode> <SHA>」の1行（無ければ何も出さない）
# 戻り値：0
print_tree_item() {
  # 項目は、modeの数字、空白（20）、名前、NUL（00）、SHAのバイトの順に並ぶ（gitformat-object）。
  printf '%s\n' "$1" | LC_ALL=C awk -v target="$2" -v size="$3" '
    { for (i = 1; i <= NF; i++) byte[count++] = $i }
    END {
      position = 0
      while (position < count) {
        mode = ""; name = ""; id = ""
        while (position < count && byte[position] != "20") mode = mode substr(byte[position++], 2, 1)
        position++
        while (position < count && byte[position] != "00") name = name byte[position++]
        position++
        for (read_size = 0; read_size < size && position < count; read_size++) id = id byte[position++]
        if (name == target) { print mode " " id; exit }
      }
    }'
}

main() {
  local size hex id mode='40000' rest component item
  if [ "$#" -ne 3 ]; then
    printf '%s\n' 'print-tree-entry.sh: リポジトリのフォルダー、commitのSHA、パスの3つを渡してください。' >&2
    exit 2
  fi
  directory="$1" && id="$2" && rest="${3%/}"
  case "$(run_git rev-parse --show-object-format)" in
    sha1) size=20 ;;
    sha256) size=32 ;;
    *) exit 1 ;;
  esac
  case "${id}" in
    '' | *[!0-9a-f]*) exit 1 ;;
  esac
  [ "${#id}" -eq "$((size * 2))" ] || exit 1
  hex="$(print_verified_object commit "${id}")" || exit 1
  # commitの1行目は「tree <SHA>」で、照らした中身と同じ16進から読む。
  id="$(print_byte "${hex}" | LC_ALL=C sed -n '1s/^tree //p')"
  while [ -n "${rest}" ]; do
    component="${rest%%/*}"
    if [ "${component}" = "${rest}" ]; then rest=''; else rest="${rest#*/}"; fi
    case "${component}" in
      '' | . | ..) exit 1 ;;
    esac
    # 途中がtreeでない（例：ファイル、サブモジュール）なら、パスは無い。
    [ "${mode}" = '40000' ] || exit 0
    hex="$(print_verified_object tree "${id}")" || exit 1
    item="$(print_tree_item "${hex}" "$(printf '%s' "${component}" | od -An -v -tx1 | LC_ALL=C tr -d ' \n')" "${size}")"
    [ -n "${item}" ] || exit 0
    mode="${item%% *}" && id="${item#* }"
  done
  printf '%s %s\n' "${mode}" "${id}"
  exit 0
}

main "$@"
