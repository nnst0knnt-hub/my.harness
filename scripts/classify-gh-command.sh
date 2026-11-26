#!/bin/bash
# ghのあとの引数を受け取り、1行目に判定（allow、ask、deny）、2行目に理由の文を出す。読み取りのコマンドだけを確認なしで通し、外でほかのプログラムを動かす形と外の設定を書く形を止め、リモートへの書き込みとほかのホストへの通信で確認を求めるためである。
# 終了コードは、いつも0である。引数が無いときも、確認を求める判定を出す。
# scripts/classify-remote-command.shが、ghのコマンドを判定するときに呼ぶ。理由は、.harness/docs/features/protection.mdの節「判定のスクリプト」に書く。
set -u -o pipefail

SCRIPT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIRECTORY
readonly CLONE_REASON='は、サンドボックスの外でgitのcloneを動かす形があるので止めます。外のghは今のリポジトリのgitのフォルダーを固定して動き、git cloneは作業フォルダーがあるとして止まります（working tree already exists）。cloneとforkは、人がClaude Codeの外で動かしてください。'

# 本文か送る中身をファイル、エディター、commitのメッセージから読む形（scripts/find-gh-unreadable-form.sh）があれば、止める判定を出す。
# 引数：ghのあとの引数
# 出力：止めるときは判定と理由の文の2行、確かめるスクリプトが失敗したときは確認を求める2行（無いときは何も出さない）
# 戻り値：判定を出したら0、止める形が無ければ1
print_unreadable_form_decision() {
  local reason status
  reason="$("${BASH}" "${SCRIPT_DIRECTORY}/find-gh-unreadable-form.sh" "$@")"
  status=$?
  [ "${status}" -ne 1 ] || return 1
  if [ "${status}" -eq 0 ]; then
    printf 'deny\n%s\n' "${reason}"
  else
    printf 'ask\n%s\n' '本文をファイルから読む形かを確かめるスクリプトが失敗したので、判定できません。確認を求めます。'
  fi
  return 0
}

# 本文をファイルから読む形が無ければ、読み取りでないか知らないコマンドとして、確認を求める判定を出す。
# 引数：ghのあとの引数
# 出力：判定と理由の文の2行
# 戻り値：0
print_write_decision() {
  print_unreadable_form_decision "$@" \
    || printf 'ask\n読み取りでないか、知らないghのコマンド（gh %s）です。リモートへの書き込み、サンドボックスの外での手元のファイルとgitの書き換え（例：gh release download、gh issue develop --checkout）、利用者の別名か拡張のプログラムの実行のことがあるので、確認を求めます。外のghは、サンドボックスが読めなくしたファイルも読め、書かせないパス（例：.git/hooks/）にも書けます。ファイルを渡すか書く先の引数（例：gh gist create、gh release upload、gh run download --dir）があれば、そのパスを確かめてください。\n' "${1:-} ${2:-}"
}

main() {
  case "${1:-} ${2:-}" in
    'pr view' | 'pr diff' | 'pr checks' | 'pr list' | 'pr status' | 'issue view' | 'issue list' | 'issue status' \
      | 'run view' | 'run list' | 'repo view' | 'release view' | 'release list' | 'label list' \
      | 'workflow view' | 'workflow list' | 'search '*)
      "${BASH}" "${SCRIPT_DIRECTORY}/classify-gh-read-command.sh" "$@"
      ;;
    'pr checkout') printf 'ask\n%s\n' 'gh pr checkoutは、サンドボックスの外でgitのfetchとcheckoutを動かします。導入先のgitのフック（例：post-checkout）と、gitの設定のコマンド（例：core.sshCommand、core.fsmonitor）も、外で動くことがあります。手元のブランチを書き換えるので、確認を求めます。' ;;
    'auth status')
      # --show-tokenのような引数は、トークンをエージェントの文脈に出すことがある。
      if [ "$#" -eq 2 ]; then
        printf 'allow\n%s\n' ''
      else
        printf 'deny\n%s\n' 'gh auth statusは、引数を付けずに動かしてください。引数（例：--show-token）で、トークンを出すことがあるためです。'
      fi
      ;;
    'auth token') printf 'deny\n%s\n' 'gh auth tokenは、トークンを標準出力に出してエージェントの文脈に入れるので止めます。ログインしたかは、引数を付けないgh auth statusで確かめてください。' ;;
    'config '*) printf 'deny\n%s\n' 'gh configには、トークンを標準出力に出してエージェントの文脈に入れる形（ホストを付けたgh config get oauth_token）と、ghが動かすプログラム（例：pager、editor、browser）を変える形があるので止めます。ghの設定は、人がClaude Codeの外で読み書きしてください。' ;;
    'auth '*) printf 'deny\n%s\n' 'gh authの、引数の無いstatusとtokenのほかの形は、ghの認証（login、logout、refresh、switch）か、gitの認証のヘルパーの設定（setup-git）を書くので止めます。ログインとアカウントの切り替えは、人がClaude Codeの外で動かしてください。' ;;
    'alias set' | 'alias import') printf 'deny\n%s\n' 'gh alias setとgh alias importは、判定が止めるコマンド（例：gh config get oauth_token）を動かす別名と、サンドボックスの外でシェルの式を動かす別名（--shellか、!で始まる展開）を書けるので止めます。別名は、人がClaude Codeの外で足してください。' ;;
    'extension '* | 'extensions '* | 'ext '*) printf 'deny\ngh %sには、GitHubが確かめていない拡張を入れる形と、拡張をサンドボックスの外で動かす形（例：install、exec）があるので止めます。拡張は、人がClaude Codeの外で入れて動かしてください。\n' "$1" ;;
    'copilot '*) printf 'deny\n%s\n' 'gh copilotは、Copilot CLIを（入っていなければダウンロードして）サンドボックスの外で動かすので止めます。Copilot CLIは、人がClaude Codeの外で動かしてください。' ;;
    'skill install' | 'skill add' | 'skill update' | 'skills install' | 'skills add' | 'skills update')
      printf 'deny\ngh %s %sは、サンドボックスの外から、エージェント（Claude Codeを含む）のスキルの場所に指示のファイルを書くので止めます。スキルは、人がClaude Codeの外で入れてください。\n' "$1" "$2"
      ;;
    'codespace ssh' | 'codespace cp' | 'cs ssh' | 'cs cp')
      printf 'deny\ngh %s %sは、サンドボックスの外でsshかscpを動かすので止めます。sshとscpに渡すオプション（例：-o ProxyCommand）で手元のコマンドも外で動かせ、cpは、サンドボックスが書かせない手元のファイルも書けます。codespaceへの接続は、人がClaude Codeの外で行ってください。\n' "$1" "$2"
      ;;
    'codespace code' | 'cs code')
      printf 'deny\ngh %s %sは、サンドボックスの外で、--webの無い形では手元のVS Codeで開くURL（vscode://）を、--webではブラウザーで動くVS Codeのページを開きます。ハーネスのスキルの手順では使わず、--webの無い形は手元のVS Codeを外で起こすので、--webも分けずに止めます。codespaceを開くのは、人がClaude Codeの外で行ってください。\n' "$1" "$2"
      ;;
    'codespace jupyter' | 'cs jupyter')
      printf 'deny\ngh %s %sは、codespaceの中でJupyterLabを起こし、サンドボックスの外の手元のポートで待ち受けて転送してから、ブラウザーで開くので止めます。codespaceを開くのは、人がClaude Codeの外で行ってください。\n' "$1" "$2"
      ;;
    'codespace ports' | 'cs ports')
      printf 'deny\ngh %s %sには、codespaceのポートを手元のポートへ転送し、サンドボックスの外で待ち受ける形（forward）があるので止めます。ポートの転送は、人がClaude Codeの外で行ってください。\n' "$1" "$2"
      ;;
    'repo clone' | 'repo fork' | 'gist clone') printf 'deny\ngh %s %s%s\n' "$1" "$2" "${CLONE_REASON}" ;;
    'repo create')
      case " $* " in
        *' --clone '* | *' --clone='* | *' -c '*) printf 'deny\ngh repo createの--clone%s\n' "${CLONE_REASON}" ;;
        *) print_write_decision "$@" ;;
      esac
      ;;
    'repo sync') printf 'deny\n%s\n' 'gh repo syncは、引数が無いと手元のリポジトリのブランチを外のgitで進めるか、--forceでhard resetし、git pullと同じく、サンドボックスが書かせないパス（例：.claude/settings.json）のファイルも書けるので止めます。手元のブランチは、git fetch <リモート> <ブランチ>のあとに、git merge --ff-only <リモート>/<ブランチ>で進めてください（例：git fetch origin main、git merge --ff-only origin/main）。' ;;
    'api '*) print_unreadable_form_decision "$@" || { shift && "${BASH}" "${SCRIPT_DIRECTORY}/classify-gh-api-command.sh" "$@"; } ;;
    *) print_write_decision "$@" ;;
  esac
  exit 0
}

main "$@"
