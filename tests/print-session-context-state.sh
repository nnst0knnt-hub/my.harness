#!/bin/bash
# hooks/print-session-context.shの出力の字数を数える関数と、出力から節ごとの状態を取り出す関数を持つ。出力を読む処理をケースを作る処理と分け、テストのファイルを100行に収めるためである。
# 終了コードは持たない。関数ごとの戻り値は、関数のコメントに書く。
# tests/test-print-session-context.shが、始めにsourceする。

# 文字列の字数を、改行を含めて数える。フックがバイト数でなく字数で数えるかを確かめるため、UTF-8の続きのバイトを除いて数える。
# 引数：文字列
# 出力：字数
# 戻り値：0
count_character() {
  printf '%s' "$1" | LC_ALL=C tr -d '\200-\277' | wc -c | tr -d ' '
}

# フックの出力から、節ごとの状態と、メインの作業フォルダーの種類と、ルールの前に環境の状態の節があるかを取り出す。本文の字数がファイルと違えば「欠け」にする。
# 引数：フックの出力、メインの作業フォルダーのパス、共通のルール、導入先ごとのルール、目次の字数
# 出力：「共通のルール 導入先ごとのルール 文書の目次 メインの作業フォルダー 環境の状態」の状態を空白で区切った1行
# 戻り値：0
print_section_state() {
  # 本文の字数は、テストが作った「あ」の行の字数に、行ごとの改行の1字を足して数える。
  printf '%s\n' "$1" | LC_ALL=C awk -v main_path="$2" -v counts="$3 $4 $5" '
    !section && $0 == "## 環境の状態" { environment = "あり" }
    $0 == "## 共通のルール" { section = 1; state[1] = "本文"; next }
    $0 == "## 導入先ごとのルール" { section = 2; state[2] = "本文"; next }
    $0 == "## 文書の目次" { section = 3; state[3] = "本文"; next }
    /^\| メインの作業フォルダー \|/ { where = index($0, "今の作業フォルダー") ? "今" : (index($0, "`" main_path "`") ? "メイン" : "違う場所") }
    section && $0 == "なし（ファイルがありません）" { state[section] = "なし" }
    section && /^読めませんでした/ { state[section] = "読めない" }
    section && /^合計が.*本文を省きました/ { state[section] = "省略" }
    section && (found = gsub(/あ/, "")) { body[section] += found + 1 }
    END {
      split(counts, expected, " ")
      for (i = 1; i <= 3; i++) if (state[i] == "本文" && body[i] != expected[i]) state[i] = "欠け"
      print state[1] " " state[2] " " state[3] " " where " " (environment ? environment : "なし") }'
}
