# PCごとの導入の手引き

my.harnessを使うPCで、人が1回だけ行う導入の手順です。導入先のリポジトリごとの導入は、この手順のあとに、[`README.md`の節「導入」](../README.md#導入)のとおりに行います。設計の理由は、[`.harness/docs/architecture.md`の節「導入」](../.harness/docs/architecture.md#導入)と[`.harness/docs/features/protection.md`](../.harness/docs/features/protection.md)に書いています。

## 要るもの

| もの | バージョン | 無いときに働かない保護 |
|---|---|---|
| git | 2.54以上 | gitの設定で足すフック（`pre-push`、`pre-commit`）が動かず、保護するブランチへのpushと秘密情報を含むcommitを、gitのフックで止めません。GUIのgitのクライアント（例：IDEのgitの画面）が2.54より古いgitを使うと、人がそのクライアントで操作するときも同じです。 |
| `jq` | 決まりなし | `PreToolUse`のフックが判定できず、`git push`、`git fetch`、`git pull`、`gh`、`glab`のたびに確認が出ます。認めても、`git push`、`git fetch`、`glab`はサンドボックスの中で動き、通信できずに失敗します。 |
| Claude Code | 2.1.314以上 | フックが起動しないときと時間切れのときに、コマンドが確認なしで進みます。Monitorのツールで動かしたコマンドにも、フックが動きません。 |
| サンドボックスの依存 | LinuxとWSL2ではbubblewrapとsocat、macOSでは要りません | 節「PCの設定を足す」で足す設定では、Claude Codeが起動しません。`sandbox.failIfUnavailable`を`false`にして起動させたときに働かない保護は、[節「働かない保護を直す」](#働かない保護を直す)の最後に書いています。 |
| seccompのフィルター | LinuxとWSL2で任意、macOSでは要りません | サンドボックスがUnixのソケットへの接続を止めず、中のコマンドが、手元のソケット（例：dockerのソケット）を通して、サンドボックスの外のプログラムを動かせます。WSL2では、Windowsのプログラム（例：`cmd.exe`、`/mnt/c/`の下のプログラム）も起動できます。 |

- Claude Codeは、ネイティブのインストールで入れると、自動で新しいバージョンになります。Homebrew、WinGet、Linuxのパッケージの管理ツールで入れたときは、そのツールで上げてください（例：`brew upgrade claude-code`）。
- macOSのサンドボックスは、OSに標準で入っている仕組み（Seatbelt）で動くので、足すものはありません。
- WSL1と、WSLを使わないWindowsでは、サンドボックスが使えません。WSL2で動かしてください。
- LinuxとWSL2では、`sudo apt-get install bubblewrap socat`（Ubuntu、Debian）か、`sudo dnf install bubblewrap socat`（Fedora）で入れます。
- LinuxとWSL2のseccompのフィルターは、`npm install -g @anthropic-ai/sandbox-runtime`で入れます。無くてもClaude Codeは起動するので、有無は[節「環境を確かめる」](#環境を確かめる)のとおりに`/sandbox`で見ます。
- `gh`（GitHubのCLI）はPRを送るホストがGitHubの導入先だけで、`glab`（GitLabのCLI）はGitLabの導入先だけで要ります。ハーネスは、2つのバージョンを比べません。`glab`は、[節「`glab`を入れる」](#glabを入れる)のとおりに入れます。

## マーケットプレイスに登録する

ハーネスのリポジトリを手元にクローンし、その場所をClaude Codeのマーケットプレイス（プラグインの一覧）として登録します。`<ハーネスの場所>`は、クローンしたフォルダーの絶対パスです。

```bash
claude plugin marketplace add <ハーネスの場所>
```

手元のパスから登録したプラグインは、元の場所から読まれます。そのため、ハーネスのリポジトリを`git pull`すると、次のセッションから新しい中身が使われます。

## PCの設定を足す

`~/.claude/settings.json`に、[`data/recommended-claude-setting.json`](../data/recommended-claude-setting.json)の中身を足します。ハーネスのフォルダーでClaude Codeを開き、手動のモード（確認の要る操作のたびに確認を出す既定のモード）で、次のように頼んでください。Claude Codeが差分を示し、確認を求めるので、中身を見て認めます。

```text
<ハーネスの場所>/data/recommended-claude-setting.json の中身を、<ハーネスの場所>をこのフォルダーの絶対パスに置き換えて、~/.claude/settings.jsonに足してください。今ある設定は消さず、一覧の項目は今の一覧に足してください。
```

足す設定は、次のとおりです。

| 設定 | すること |
|---|---|
| `permissions.deny` | 秘密情報のファイル（`.env`、`.env.`で始まるファイル、`.p12`、`.pfx`）と、秘密鍵だけを入れるファイル（例：`*.pem`、`*.key`、`id_ed25519`、`*.jks`）を、Claude CodeのRead、Editで読み書きさせません。ホームのフォルダーの秘密情報（`~/.ssh`、`~/.aws`、`~/.config/gh`、`~/.git-credentials`、`~/.netrc`、`~/.docker/config.json`、`~/.kube/config`）と`glab`の設定（`~/.config/glab-cli/`、`~/Library/Application Support/glab-cli/`、リポジトリの`.git/glab-cli/`）はファイルのツールでもシェルでも読ませず、gitのフックを飛ばす`git commit`の`--no-verify`と`-n`は止めます（`git push`の`--no-verify`は、判定のスクリプトが止めます）。 |
| `permissions.ask` | `.harness/`のルールと設定、`.git/config`と`.git/hooks/`、Claude Codeの設定のファイル、gitのPCの設定、シェルの起動のファイル（例：`~/.bashrc`、`~/.zshrc`）への書き込みで、毎回確認を求めます。 |
| `permissions.allow` | `.harness/docs/`への書き込み、ハーネスの場所の読み取り、ハーネスの`scripts/`の実行を、確認なしで許します。 |
| `sandbox` | サンドボックスを有効にして中のコマンドを確認なしで動かし、使えないときはClaude Codeを起動させず、サンドボックスで失敗したコマンドの外での再実行を止めます。外で動かすのは、フックが`git push`、`git fetch`、`glab`を書き換えた、ハーネスの外で動かすスクリプトの呼び出しと`gh`だけにし、GitHubとGitLabへの通信をサンドボックスの中で拒否します。 |

`~/.claude/settings.json`の`sandbox.excludedCommands`に`git push *`、`git fetch *`、`glab *`があるか、`permissions.deny`に`Bash(git push *--no-verify*)`か、外で動かすスクリプトの後ろに語を書いた形（例：`Bash(bash <ハーネスの場所>/hooks/exec-with-pinned-git-directory.sh * git push *--no-verify*)`）があれば、消してから足します。

- `excludedCommands`に残ると、フックが書き換えなかったとき（例：`jq`が無い）に、そのコマンドが、判定を通らず、gitのフォルダーを固定せずにサンドボックスの外で動きます。
- この2つの形のdenyは、フックが書き換えたコマンド（外で動かすスクリプトとフックの記録の名前だけ）に当たらず、止めません。`--no-verify`のpushは、判定のスクリプトが止めます。
- 環境を確かめるスクリプト（[節「環境を確かめる」](#環境を確かめる)）は、この2つを`[働かない]`で表示します。

この設定は、このPCのすべてのプロジェクトに当たります。ほかのプロジェクトでは、次のことが起きます。

| 起きること | 直し方 |
|---|---|
| シェルのコマンドがサンドボックスの中で動き、初めての通信先への通信で確認が出ます。 | そのプロジェクトの`.claude/settings.local.json`の`sandbox.network.allowedDomains`に、通信先を足します。 |
| 手動のモードでは、サンドボックスの中で作業フォルダーの中を消すコマンド（例：`rm -rf`、`git reset --hard`）にも、確認が出ません。 | 消すコマンドのたびに確認を出したいプロジェクトでは、そのプロジェクトの`.claude/settings.local.json`で`sandbox.autoAllowBashIfSandboxed`を`false`にします。中のコマンドに、ふつうの権限の確認が出るようになります。 |
| サンドボックスに合わないツール（例：docker）が失敗し、外で動かし直されません。 | そのプロジェクトの`.claude/settings.local.json`の`sandbox.excludedCommands`に足します。外で動くコマンドには、サンドボックスの制限がかからず、フックの判定も当たりません。 |
| ビルドかテストのツールが、作業フォルダーの外のキャッシュ（例：LinuxのGoの`~/.cache/go-build`）に書けずに失敗します。 | ハーネスを入れた導入先では、`configure-repository`が案を示します。ほかのプロジェクトでは、`.claude/settings.local.json`の`env`でキャッシュをそのプロジェクトの中に移します（共有のキャッシュを`sandbox.filesystem.allowWrite`に足すと、中から書いたキャッシュを外のビルドが使います）。 |
| 手元のサーバーを使うテストが失敗します。macOSではポートで待ち受けられず、どのOSでも、手元で動くほかのサーバー（例：DB）に届きません。 | 人がClaude Codeの外で動かします。ハーネスを入れた導入先では、`configure-repository`が、人が外で動かす形と、緩める形（`excludedCommands`、macOSの`allowLocalBinding`）を、起きることとともに示します。 |
| commitに署名するPC（例：`commit.gpgsign`が`true`）では、サンドボックスがUnixのソケットを止める環境（macOSと、seccompのフィルターがあるLinuxとWSL2）で、中の`git commit`が署名のエージェント（例：ssh-agent、gpg-agent）のソケットに届かずに失敗します。鍵を`~/.ssh`のファイルから読む署名（例：`gpg.format`が`ssh`で、`user.signingkey`が鍵のファイル）は、PCの勧める設定がサンドボックスに`~/.ssh`を読ませないので、どの環境でも失敗します。 | 人がClaude Codeの外でcommitします。エージェントのソケットに届かないだけなら、macOSでは、そのプロジェクトの`.claude/settings.local.json`の`sandbox.network.allowUnixSockets`にエージェントのソケットのパスを足す形もあり、足したパスは`[確かめる]`に表示されます。 |
| サンドボックスの中の`git clone`と、GitHubとGitLabからの依存の取得（例：`npm install github:...`、GitHubから中身を取るComposerの`composer install`）が失敗します。 | 人がClaude Codeの外で動かします。拒否する通信先はどのモードでも止まるので、通信先を足しても通りません。 |
| ハーネスのプラグインを有効にしていないプロジェクトでは、エージェントの`git push`、`git fetch`、`glab`がサンドボックスの中で動き、通信できずに失敗します。 | 人がClaude Codeの外で動かすか、そのプロジェクトでもハーネスのプラグインを有効にします。そのプロジェクトの`sandbox.excludedCommands`に`git push *`を足す形は、判定もgitのフォルダーの固定も当たらないので勧めません。 |
| `git pull`が止まります。 | エージェントは、`git fetch`のあとに`git merge --ff-only`を動かします（例：PRの向き先が`main`なら、`git fetch origin main`のあとに`git merge --ff-only origin/main`）。 |
| 秘密情報のファイルを、ファイルのツールでもシェルでも読めません。見本のファイル（例：`.env.example`）も読めません。 | 読ませたいときは、人が中身を貼ります。そのファイルを開くテスト（例：`.env`を読むフレームワークのテスト、見本の鍵の`*.pem`を読むテスト）は、人がClaude Codeの外で動かします。 |
| サンドボックスの中で、ホームのフォルダーの秘密情報で認証するツール（例：別のホストへの`ssh`、AWSのCLI、`kubectl`、`curl -n`）が失敗します。 | 人がClaude Codeの外で動かすか、そのプロジェクトの`sandbox.excludedCommands`に足します（外で動くコマンドには、サンドボックスの制限がかかりません）。 |
| `.git/config`、`.claude/`の設定、`~/.gitconfig`、シェルの起動のファイルへの書き込みで、毎回確認が出ます。 | 人が中身を見て認めます。 |
| LinuxとWSL2では、サンドボックスの中のコマンドから、作業フォルダーに無い、サンドボックスが書かせないパス（例：`.bashrc`、`.mcp.json`、`.claude/settings.json`）が、中身の無いファイルとして見えます。中の`git status`に追跡されていないファイルとして出て、`git add -A`と`git add .`が失敗します。 | エージェントは、ファイルの名前を指定して`git add`します。サンドボックスがコマンドの間だけ置いて消すファイルなので、Claude Codeの外の`git status`には出ません。 |

サンドボックスが有効になると、エージェントは`git push`、`git fetch`、`gh`、`glab`を、ほかのコマンドとつながずに1つで動かします。pushは、送り先のブランチを書いた形（例：`git push origin feat/x:feat/x`）で動かします。つないだ形はフックが止め、フックの判定を通らない形はサンドボックスの中に残ってGitHubとGitLabに通信できないためです。

フックは、`git push`、`git fetch`、`glab`と確認を求める`gh`を、gitのフォルダーを固定して外で動かすスクリプトの呼び出しに書き換えます。書き換えた呼び出しは、スクリプトと、判定した語を書いたフックの記録の名前だけなので、動かすコマンドは確認の画面の理由の文に出ます。300字を超える語は初めの300字だけが出るので、全文は理由の文に出たパスのファイルで読みます。セッションの始めのフックが、エージェントにこの動かし方を渡します。

## `glab`を入れる

GitLabの導入先で使うPCだけで行います。節「PCの設定を足す」を終えてから行ってください。`glab`のトークンを、エージェントに読ませないためです。

1. `glab`を入れ（例：`brew install glab`）、`glab --version`で確かめます。
2. GitLabで、個人のアクセストークンのうちFine-grained token（使えるプロジェクトと操作を絞れるトークン）を作ります。Group and project accessではプロジェクトを選ぶ形（画面の名前は「Only specific groups or projects I have access to」）を選んで導入先のプロジェクトだけを選び、権限は下の表の7つを選びます。有効期限は、短いほど漏れたときの害が小さくなります。
3. Claude Codeの外のターミナルで`glab auth login`を動かし、ホストを選んで、トークンを貼ります。gitの方式は、SSHを選びます。
4. `glab auth status`で、ログインしたことを確かめます。`--show-token`（`-t`）は、トークンを表示するので付けないでください。

| 画面のタブ | 分類 | リソース | 操作 | 使う所 |
|---|---|---|---|---|
| User | System Access | User | Read | ログインの確かめ（`glab auth status`） |
| Group and project | Projects | Project | Read | プロジェクトの読み取り |
| Group and project | Repository | Merge Request | Read、Create、Update | MRの読み取り、作成、本文の直し、スレッドへの返信、下書きのコメント（作成、消すこと、`bulk_publish`）、MRのパイプライン |
| Group and project | Repository | Protected Branch | Read | 保護したブランチの読み取り |
| Group and project | Project Planning | Work Item | Read、Create | チケットの読み取り（`glab issue view`）と作成（`glab issue create`）、MRへの普通のコメント（残した指摘をMRへのコメントにする導入先） |
| Group and project | CI/CD | Pipeline | Read | パイプラインのジョブの読み取り |
| Group and project | CI/CD | Job | Read | ジョブのログ（trace）の読み取り |

Fine-grained tokenを勧めるのは、前からのLegacy token（範囲（scope）で権限を決めるトークン）の`api`の範囲が、APIの読み書きをすべて許すためです。Fine-grained tokenは、選んだプロジェクトの選んだ操作のほかを許さないので、判定が確認なしで通した呼び出しも、人が確認で認めた呼び出しも、その外には届きません。CI/CDの変数（Variable）のような、表に無いリソースも読めません。

公開かの読み取り（GraphQLの`visibility`）にどの権限が要るかは、GitLabの文書に書かれていません。gitlab.comでは、この7つの権限で読めます。

表は、gitをSSHで送る形の権限です。pushとfetchはSSHの鍵で送るので、gitの権限（Code）は選びません。gitをHTTPSで送り、このトークンをgitのパスワードに使うときは、CodeのDownloadとPushの権限も要ります。

Fine-grained tokenを作れないGitLabでは、Legacy tokenを作り、範囲に`api`と`write_repository`を選びます。`glab`の文書が、この2つを最小の範囲として示しているためです。

キーリングの無い環境（例：WSL2）では、`glab`がトークンを設定のファイル（Linuxでは`~/.config/glab-cli/config.yml`）に平文で置きます。勧める設定のdenyが、このファイルをエージェントに読ませません。`GLAB_CONFIG_DIR`か`XDG_CONFIG_HOME`で設定の場所を変えたPCでは、denyが当たらないので、その場所を`~/.claude/settings.json`の`permissions.deny`に`Read(<場所>/**)`の形で足してください。

GitLabの文書は、Claude Codeのサンドボックスでは`glab`を`excludedCommands`に足す形を示していますが、足さないでください。ハーネスのフックが、`glab`を判定してから外で動かすスクリプトの呼び出しに書き換えます。`glab *`を足すと、フックが書き換えなかったとき（例：`jq`が無い）に、`glab`が判定を通らずに外で動きます。

## 環境を確かめる

PCの設定を足したら、Claude Codeの外のシェルで、導入先のフォルダー（無ければどこでも）に移って、次のスクリプトを動かします。

```bash
bash <ハーネスの場所>/scripts/print-protection-status.sh
```

スクリプトは、項目ごとに、次のどれかの状態と、起きることと直し方を表示します。

| 状態 | 意味 |
|---|---|
| `[働く]` | 保護が働きます。 |
| `[働かない]` | 保護が働かないか、設定が保護を止めています。 |
| `[確かめる]` | 設定が保護を緩めるか、サンドボックスの外で動くものを足しています。足した覚えの無いものが無いかを、人が見ます。 |
| `[わからない]` | `jq`か`claude`が動かないか、ファイルを読めないか、メインの作業フォルダーを求められず（例：bareのリポジトリ）、確かめられませんでした。 |
| `[見ない]` | その項目を確かめませんでした。 |

`[働かない]`と`[わからない]`が無ければ、「すべての保護が働きます。」と`[確かめる]`の項目の数を表示し、0で終わります。`[確かめる]`の項目は、終了コードに入れません。人が認めて足した項目（例：`configure-repository`が足した許す通信先）でも、毎回1で終わると、表示が読まれなくなるためです。サンドボックスの依存が無いPCでは、PCの設定の`failIfUnavailable`のためにClaude Codeが起動しないので、Claude Codeの外で動かします。Claude Codeの中のサンドボックスで動かしても、同じ結果を表示します。

| 項目 | 確かめること |
|---|---|
| gitのバージョン | 2.54以上か |
| `jq` | 動くか |
| Claude Codeのバージョン | 2.1.314以上か |
| サンドボックス | OSで使えるか、依存が動くか、設定のファイルで有効か |
| PCの設定 | `~/.claude/settings.json`に、勧める設定がすべてあるか |
| Claude Codeの設定 | 導入先の設定のファイル、`.mcp.json`、`~/.claude/settings.json`に、保護を止める値（`[働かない]`）と、保護を緩めるかサンドボックスの外で動く項目（`[確かめる]`）があるか（`~/.claude/settings.json`の`[確かめる]`は、サンドボックスの外で動く項目だけ） |
| 導入先のgitのフック | 導入先で読むgitの設定（導入先の`.git/config`、PCとシステムの設定）に、`configure-repository`が足すフックがあるか（gitのリポジトリの外では見ない） |

サンドボックスが有効かは、設定のファイル（管理者の設定のファイル、導入先の`.claude/settings.local.json`と`.claude/settings.json`、`~/.claude/settings.json`）から読みます。`claude --settings`で渡した値と、ファイルでない管理者の設定は読めません。セッションの始めのフックも同じ読み方をし、働かない保護があれば、エージェントが最初の返事で伝えます。

スクリプトは、次のものを見ません。Claude Codeの中で、人が見てください。

| 見ないもの | 見方 |
|---|---|
| LinuxとWSL2のseccompのフィルター | `/sandbox`を開きます。Dependenciesのタブが出れば、フィルターが無く、サンドボックスはUnixのソケットへの接続を止めません。 |
| 管理者の設定 | `/status`を開き、`Setting sources`の行に管理者の設定があれば、`allowManagedHooksOnly`か`allowManagedPermissionRulesOnly`が入っていないかを管理者に確かめます。前者はハーネスのフックを、後者は`~/.claude/settings.json`の権限のルールを使わなくします。 |
| デスクトップアプリとVS Codeの拡張機能のClaude Codeのバージョン | デスクトップアプリのCodeのタブとVS Codeの拡張機能は、端末の`claude`とは別のClaude Codeを動かすので、バージョンが違うことがあります。そのセッションの`/status`（VS Codeの拡張機能では2.1.280以上）か、VS Codeの拡張機能の一覧の画面で、Claude Codeのバージョンを見ます。 |

管理者の設定がサンドボックスを必須にすると（例：管理者の設定の`allowUnsandboxedCommands`が`false`）、導入先の`.claude/settings.json`と`.claude/settings.local.json`の値の一部（例：許す通信先、`excludedCommands`、`allowWrite`、`allowUnixSockets`、`allowLocalBinding`の`true`）は使われません。`configure-repository`が導入先に書くこれらの値のうち要るものは、人が`~/.claude/settings.json`に絶対パスで書きます。`~/.claude/settings.json`では、`./`で始まるパスが`~/.claude`からの場所になるためです。

WindowsのデスクトップアプリのWSLのセッションでは、プラグインが使えず、ハーネスのフック、スキル、レビュー役が動きません。WSLの端末で`claude`を動かして使ってください。

導入先の`.claude/settings.json`と`.claude/settings.local.json`は、PCの権限とサンドボックスの設定を緩められます（例：`sandbox.excludedCommands`に足す、`sandbox.enabled`を`false`にする）。スクリプトは、緩める値と項目を、ファイルとキーごとに表示します。読むキーは、[`data/loosening-claude-setting-list.tsv`](../data/loosening-claude-setting-list.tsv)にあります。

- 導入先の`.claude/settings.json`と`.claude/settings.local.json`からは、導入先の設定で当たるキーを読みます。`.mcp.json`からは、`mcpServers`だけを読みます。
- `~/.claude/settings.json`からは、保護を止める値と、サンドボックスの外で動く項目（例：フック、プラグイン、`processWrapper`）だけを読みます。
- `~/.claude/settings.json`の権限とサンドボックスの一覧（例：`permissions.allow`、`sandbox.excludedCommands`）に足した項目は、表示しません。人が自分で足した項目が多く、すべて並べると表示が読まれなくなるためです。
- 設定の`env`は、導入先と`~/.claude/settings.json`のどちらからも読みません。`~/.claude/settings.json`の`env`に足した変数（例：`GIT_SSH_COMMAND`）が、サンドボックスの外で動く`git push`の動きを変えても、表示しません。Claude Codeの外でツール（例：npmのパッケージ）を入れたあとは、`~/.claude/settings.json`の一覧と`env`に、足した覚えの無いものが無いかを見てください。

勧める設定でも、次のことは止まりません。理由は、[`.harness/docs/features/protection.md`の節「前提」](../.harness/docs/features/protection.md#前提)に書いています。

- 勧める設定に無い認証のファイル（例：`~/.npmrc`）と環境変数の秘密情報（例：`NPM_TOKEN`）を、サンドボックスの中のコマンドが読むこと。止めたいときは、`~/.claude/settings.json`の`sandbox.credentials`に足します。
- ローカルのMCPのサーバーが、サンドボックスの外で動くこと。MCPのサーバーを足すときは、中身を見て決めてください。導入先の`.mcp.json`のサーバーは、`[確かめる]`に表示されます。
- Claude Codeの勧告で直ったバージョンが、ハーネスの求める2.1.314より新しくなること。ハーネスは勧告を見張らないので、Claude Codeを新しいバージョンに保ってください。
- 組み込みの保護のmodが読み込まれない環境で、プラグインのmod（Claude Codeの中で動くプラグインのコード）が、ハーネスの判定が確認を求めた呼び出しを、確認なしで許すこと。プラグインを入れる前に、[節「プラグインを入れる前にmodを確かめる」](#プラグインを入れる前にmodを確かめる)のとおりに確かめてください。
- CIの既存のジョブが動かすコード（例：`npm test`のテスト）を変えたpushで、そのジョブのsecrets（CIのジョブに渡す秘密の値）が外へ送られること。確認が出るのは、CIの設定のファイル（例：`.github/workflows/`、`.gitlab-ci.yml`）を変えたpushだけです。

pushのたびに、ハーネスの判定がリモートに1回問い合わせます。SSHの鍵の承認（例：FIDOの鍵のタッチ、1Passwordの承認）か、Git Credential Managerの画面が毎回出る環境では、pushのたびに承認が2回になります。

## プラグインを入れる前にmodを確かめる

modは、プラグインとして入ります。組み込みの保護のmod（`cc-plugin-sec-default`）が読み込まれない環境では、modが、権限のdenyとaskのルールと、ハーネスのフックの判定を越えて、ツールの呼び出しを許せます。組み込みの保護のmodが読み込まれるのは、管理者の設定、`managed-mcp.json`、TeamかEnterpriseの`/login`のどれかがあるときです。

ハーネスを使うPCでプラグインを入れるときは、次のように確かめます。

1. 入れる前に、プラグインのファイルを手元に置き（例：リポジトリのクローン）、Claude Codeの外のシェルで`claude plugin validate <プラグインのフォルダー>`を動かします。出力の`hooks:`の行はmodが受け取るイベントを、`calls:`の行はmodがClaude Codeに頼む操作（例：ファイルの読み取り、通信）を示します。
2. 入れたあとに、Claude Codeで`/plugin`を開きます。タブの下の`1 mod active · first-mod`のような行が、読み込んだmodの数と名前です。
3. 同じ`/plugin`のInstalledのタブに`cc-plugin-sec-default`があれば、組み込みの保護のmodが読み込まれています。

`~/.claude/settings.json`の`disableAllHooks: true`は、人が入れたmodを止めますが、ハーネスのフックも止めるので、ハーネスを使うPCでは使いません。1つのmodを止めるときは、`/plugin`のInstalledのタブで、そのプラグインを無効にします。

## 働かない保護を直す

| 表示 | 直し方 |
|---|---|
| gitのバージョンが働かない | gitを2.54以上にします（例：macOSのHomebrewでは`brew install git`、Ubuntuでは`sudo add-apt-repository ppa:git-core/ppa`のあと`sudo apt update`と`sudo apt install git`）。Ubuntuの標準のgitが2.54より古いときは、gitの公式のページが示すこのPPAで上げます。 |
| `jq`が働かない | `jq`を入れます（例：`sudo apt-get install jq`、`brew install jq`）。 |
| Claude Codeのバージョンが働かない | `claude update`で上げます。 |
| サンドボックス（bubblewrapかsocatが動きません） | 節「要るもの」のコマンドで入れ、Claude Codeを起動し直します。 |
| サンドボックス（このOSでは使えません） | WSL2、Linux、macOSのどれかで動かします。 |
| サンドボックスが設定のファイルで有効になっていない | 節「PCの設定を足す」のとおりに足します。導入先の`.claude/settings.json`が`sandbox.enabled`を`false`にしていれば、チームが追跡するそのファイルは変えずに、導入先の`.claude/settings.local.json`に`"sandbox": {"enabled": true}`を書きます（`.claude/settings.local.json`の値が優先されるため）。 |
| PCの設定が働かない | 表示された設定を、節「PCの設定を足す」のとおりに足します。 |
| Claude Codeの設定が働かない | 表示された直し方のとおりに、書いたファイルから消すか、導入先の`.claude/settings.local.json`で勧める値にします。チームが追跡する`.claude/settings.json`は変えません。 |
| Claude Codeの設定を確かめる | 足した覚えの無い値は、足した人に確かめてから消します。自分かチームが認めて足したもの（例：`configure-repository`が足した許す通信先）は、そのままにします。 |
| 導入先のgitのフックが働かない | 導入先でClaude Codeを開き、`configure-repository`に頼みます。 |

依存を入れられないPCでは、人が`~/.claude/settings.json`の`sandbox.failIfUnavailable`を`false`にすると、Claude Codeがサンドボックスなしで起動します。このときは、次のことが止まりません。

- フックが見るコマンドの形に合わない書き方のpush（例：`git -C . push`）
- シェルからの秘密情報の読み取り
- シェルからの、`.harness/`のルールと設定への書き込み

## 出典

- [Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing)の冒頭：「On native Windows, Claude Code runs commands unsandboxed.」（確かめた日：2026-11-23）
- 同じページの節「Get started」：「sandboxing uses the built-in Seatbelt framework」、「the sandbox relies on `bubblewrap` and `socat`」（確かめた日：2026-11-16）
- 同じページの節「Set up Linux and WSL2」：「Upgrade it to WSL2 or run Claude Code without sandboxing.」、「The seccomp filter is optional and adds Unix domain socket blocking.」、「Install it with `npm install -g @anthropic-ai/sandbox-runtime` if it is missing.」、「When a dependency is missing, the Dependencies tab in `/sandbox` lists which of `ripgrep`, `bubblewrap`, `socat`, and the seccomp filter your platform lacks.」、「the optional seccomp filter has to be installed to block the socket in the first place.」（確かめた日：2026-11-23）
- 同じページの節「Repository settings under an admin-required sandbox」：「`allowUnsandboxedCommands` set to `false` in managed settings」、「It ignores these settings in a repository's `.claude/settings.json` and `.claude/settings.local.json`」（確かめた日：2026-11-23）
- 同じページの節「A command fails to reach a server on localhost」：「By default, a sandboxed command can't connect directly to a server that's running on your machine outside the sandbox」（確かめた日：2026-11-23）
- [All settings](https://code.claude.com/docs/en/settings-reference)の表の`allowManagedHooksOnly`の行：「Run only the hooks your organization deploys」、`allowManagedPermissionRulesOnly`の行：「Make managed settings the only settings source of permission rules」、節「Sandbox path prefixes」：「Relative to the project root for project settings, or to `~/.claude` for user settings」、`sandbox.network.allowUnixSockets`：「List the Unix socket paths sandboxed commands can connect to on macOS.」（確かめた日：2026-11-23）
- [Settings files and precedence](https://code.claude.com/docs/en/settings)の節「Check what your organization enforces」：「To see which, run `/status`: the `Setting sources` line names the managed source that applies to you.」（確かめた日：2026-11-23）
- [Desktop application](https://code.claude.com/docs/en/desktop)の節「Claude Code version in the Code tab」：「so it can differ from the `claude` command in your terminal, and updating one doesn't update the other.」（確かめた日：2026-11-23）
- [Use Claude Code in VS Code](https://code.claude.com/docs/en/vs-code)の節「Prerequisites」：「The extension bundles its own copy of the CLI (command-line interface) for the chat panel.」、節「Install the extension」：「The extension's version number is the Claude Code version it bundles.」、「which the Extensions view shows」、節「Use the prompt box」の項目「Command menu」：「or type `/status`, to check the session's Claude Code version」、「Requires Claude Code v2.1.280 or later.」（確かめた日：2026-11-24）
- [Claude Code Desktop in WSL](https://code.claude.com/docs/en/desktop-wsl)の節「What works in a WSL session」のPluginsの行：「not available in WSL sessions」（確かめた日：2026-11-23）
- [Troubleshooting - Composer](https://getcomposer.org/doc/articles/troubleshooting.md)の節「API rate limit and OAuth tokens」：「Because of GitHub's rate limits on their API it can happen that Composer prompts」（確かめた日：2026-11-23）
- [Git - Install for macOS](https://git-scm.com/install/mac)の節「Homebrew」：「brew install git」、[Git - Install for Linux](https://git-scm.com/install/linux)の節「Debian/Ubuntu」：「For Ubuntu, this PPA provides the latest stable upstream Git version」（確かめた日：2026-11-23）
- [Set up Claude Code](https://code.claude.com/docs/en/setup)の節「Update Claude Code」：「Native installations automatically update in the background.」、「Homebrew, WinGet, and Linux package manager installations require manual updates by default.」、「To upgrade Homebrew manually, run `brew upgrade claude-code`」（確かめた日：2026-11-17）
- [Plugin loading reference](https://code.claude.com/docs/en/plugins/loading)の節「In-place and copied plugins」：「Your edits to the source directory take effect at the next session start」（確かめた日：2026-11-16）
- [Mods overview](https://code.claude.com/docs/en/plugins/mods/overview)の節「List what a mod does before you install one」：「The `hooks:` and `calls:` lines in the output list the events the mod handles and what it asks Claude Code to do.」、節「See which mods a session loaded」：「A dim line under the tabs gives the count and the names, such as `1 mod active · first-mod`.」、節「What a mod can reach」：「In a local terminal session, `cc-plugin-sec-default` on the Installed tab of `/plugin` means the guard is loaded.」、節「Turn mods on or off」：「Every mod you installed, in every session: set `"disableAllHooks": true` in `~/.claude/settings.json`.」（確かめた日：2026-11-20）
- [Configure permissions](https://code.claude.com/docs/en/permissions)の節「Precedence among rules, hooks, and mods」：「With managed settings or a `managed-mcp.json` file, or a Team or Enterprise `/login` as the session's credential, the built-in guard loads by default.」（確かめた日：2026-11-20）
- [GitLab CLIのREADME](https://gitlab.com/gitlab-org/cli/-/blob/main/README.md)：「Install with: `brew install glab`」（確かめた日：2026-11-19）
- [Authenticate with GitLab](https://docs.gitlab.com/cli/authentication/)：「Get a GitLab personal access token with at least the `api` and `write_repository` scopes.」、節「Option 1: Run glab outside the sandbox」：「Be aware that a compromised or prompt-injected agent could write outside the working directory」（確かめた日：2026-11-19）
- 同じページの節「Credential storage」：「If no keyring is available, if you pass `--insecure-storage`, or if you use `glab` in CI/CD environments where `GITLAB_CI` or `CI` is set to `true`, `glab` stores credentials as plaintext in the configuration file and prints a warning.」（確かめた日：2026-11-24）
- [Configure the CLI](https://docs.gitlab.com/cli/configuration/)の節「Configuration levels」：「The local configuration file is available at `.git/glab-cli/config.yml` in the current working Git directory.」（確かめた日：2026-11-23）
- [Fine-grained personal access tokens](https://docs.gitlab.com/auth/tokens/fine_grained_access_tokens/)の節「Create a fine-grained personal access token」：「If you're adding group or project resources, under Group and project access, select an option.」、節「How fine-grained tokens authorize each request」：「The token has a permission for the operation, on the resource in the request path.」（確かめた日：2026-11-22）
- [Fine-grained personal access tokensのREST APIの権限](https://docs.gitlab.com/auth/tokens/fine_grained_access_tokens_rest/)の節「System Access resources」の「User」の表の`GET /user`の行（Read）、節「Projects resources」の「Project」の表の`GET /projects/:id`の行（Read）、節「Repository resources」の「Merge Request」：「Grants the ability to approve, create, delete, merge, read, subscribe, and update merge requests.」と、同じ表の`.../discussions/:discussion_id/notes`のPOSTの行（Create）、`.../draft_notes`のPOST、`.../draft_notes/:draft_note_id`のDELETE、`.../draft_notes/bulk_publish`のPOSTの行（Update）、`.../pipelines`のGETの行（Read）、節「Project Planning resources」の「Work Item」：「Grants the ability to create, delete, read, subscribe, and update work items such as epics and issues.」と、同じ表の`/projects/:id/issues`と`/projects/:id/merge_requests/:noteable_id/notes`のPOSTの行（Create）、節「CI/CD resources」の「Pipeline」の表の`/projects/:id/pipelines/:pipeline_id/jobs`の行と「Job」の表の`/projects/:id/jobs/:job_id/trace`の行（Read）、同じ節の「Variable」：「Grants the ability to create, delete, read, and update CI variables.」（確かめた日：2026-11-22）
- [Fine-grained personal access tokensのGitとほかの操作の権限](https://docs.gitlab.com/auth/tokens/fine_grained_access_tokens_other/)の節「Git operations」：「A fine-grained personal access token used as the password for Git over HTTPS must have the following permissions:」と、表の「Clone or pull a project repository」の行（CodeのDownload）と「Push to a project repository」の行（CodeのPush）（確かめた日：2026-11-22）
- [Access token scopes](https://docs.gitlab.com/security/tokens/access_token_scopes/)の`api`の行：「Grants complete read and write access to the API for the token’s scope.」（確かめた日：2026-11-22）
- [glab auth login](https://docs.gitlab.com/cli/auth/login/)の節「Options」：「Git protocol. Options: ssh, https, http.」（確かめた日：2026-11-22）
