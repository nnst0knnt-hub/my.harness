# セキュリティの観点

`audit-security`の手順と、そこから頼まれたレビュー役が読む観点の一覧である。技術に依らない形で書く。導入先の言語やフレームワークでの当てはめ方は、導入先が使っているバージョンの公式の文書で確かめる。

## 使い方

- 対象に関わる観点だけを当てる（例：ファイルを扱わない変更では、「ファイルとパス」を飛ばす）。対象が依存の更新のときは、節「依存とサプライチェーン」のすべての観点を当てる。
- 報告には、当てた観点と、当てなかった観点とその理由を書く。見ていない所を、人が報告から知れるようにするためである。
- 見つけた秘密情報は、値を伏せて、場所（`path:line`）と種類だけを書く。報告とチケットに値を書くと、そこから広まるためである。
- 動かして確かめるのは、手元と一時のフォルダーだけにする。本番や共有の環境と、外のサービスには試さない。
- 出典の項目は、観点を詳しく調べるときに最初に読む所である。番号は、OWASP Top 10とCWE Top 25は2025年版、ASVSは5.0.0のものである。
- OWASP Top 10は、ウェブのアプリの重大なリスクの一覧である。CWE Top 25はソフトウェアの弱点の上位25の一覧で、ASVSはウェブのアプリのセキュリティを確かめる要件の一覧である。

## 外から入る値の扱い

| 観点 | 見ること | 出典の項目 |
|---|---|---|
| インジェクション | 外から入った値を、SQL、OSのコマンド、コード、HTMLの組み立てに、文字列のまま混ぜていないかを見る。値を分けて渡す仕組み（例：SQLのプレースホルダー、コマンドの引数の配列）か、出力先に合わせたエスケープを使っているかを見る。 | OWASP Top 10のA05、CWE-79、CWE-89、CWE-78、CWE-77、CWE-94、ASVSのV1 |
| 入力の検証と業務の順序 | 信頼の境界（信頼しない側から値が入る所、例：画面、API、ファイル、ほかのシステム）で、値の形、範囲、長さを確かめているかを見る。業務の順序（例：支払いの前に発送しない）を、利用者が飛ばせないかを見る。 | CWE-20、ASVSのV2 |
| ファイルとパス | 外から入った値でパスを組み立てて、決めたフォルダーの外を読み書きできないかを見る。アップロードされたファイルの種類と大きさを確かめているかを見る。 | CWE-22、CWE-434、ASVSのV5 |
| 外への要求 | 外から入ったURLやホストへ、サーバーが要求を送らないか（例：社内のアドレス、クラウドのメタデータの場所）を見る。 | CWE-918、ASVSのV1（1.3.6） |
| 信頼しないデータの復元 | 信頼しないデータを、型やオブジェクトを復元する形（デシリアライズ）で読んでいないかを見る。 | OWASP Top 10のA08、CWE-502 |
| 資源の消費 | 大きな入力、繰り返しの要求、時間のかかる処理に、上限があるかを見る。 | CWE-770、ASVSのV15 |
| メモリーの安全 | メモリーを直接扱う言語（例：C、C++）では、境界の外の読み書き、解放したあとの使用、NULLの参照が無いかを見る。 | CWE-787、CWE-125、CWE-416、CWE-476、CWE-120、CWE-121、CWE-122 |

## 利用者、秘密、設定の扱い

| 観点 | 見ること | 出典の項目 |
|---|---|---|
| 認証 | 重要な機能に認証があるかを見る。パスワードとトークンの保存、期限、総当たりへの備えを見る。 | OWASP Top 10のA07、CWE-306、ASVSのV6、V9、V10 |
| 認可 | 操作のたびに、その利用者がその対象を扱えるかを、サーバーの側で確かめているかを見る。利用者が変えられる値（例：URLの中のID）を変えるだけで、ほかの人のデータを読み書きできないかを見る。 | OWASP Top 10のA01、CWE-862、CWE-863、CWE-284、CWE-639、ASVSのV8 |
| セッションとほかのサイトからの要求 | セッションの発行、期限、ログアウトのときの無効化を見る。状態を変える要求で、ほかのサイトから送られた要求を見分けているか（CSRFへの備え）を見る。 | CWE-352、ASVSのV3、V7 |
| 秘密情報 | パスワード、APIのキー、鍵が、コード、設定のファイル、ビルドの成果物、ログ、エラーメッセージ、gitの履歴に入っていないかを見る。 | ASVSのV13（13.3.1）、V16（16.2.5）、CWE-200 |
| 暗号と通信 | 自前の暗号、古いアルゴリズム、コードに書いた鍵や初期値、暗号化しない通信、証明書の確認を外す設定が無いかを見る。 | OWASP Top 10のA04、ASVSのV11、V12 |
| 個人情報と機密のデータ | 個人情報と機密のデータを要る所だけで持ち、応答、ログ、キャッシュに余分に出していないかを見る。 | CWE-200、ASVSのV14 |
| 設定 | 本番に、デバッグの機能、テストのコード、既定のパスワード、広すぎる許可（例：CORS、ファイルの権限、クラウドの権限）が残っていないかを見る。 | OWASP Top 10のA02、ASVSのV13、V15 |
| 例外とログ | 失敗したときに、安全な側で止まるか（例：例外で認可の確認が飛ばされない）を見る。セキュリティに関わる出来事（例：ログインの失敗、権限の変更）をログに残し、ログに秘密情報を書かないかを見る。 | OWASP Top 10のA09、A10、ASVSのV16 |

## 依存とサプライチェーン

依存の追加と更新で当てる。対象が依存の更新のときは、人が直接頼んだときも、依存や環境の更新の作業から呼ばれたときも、この節のすべての観点を当てる。依存を足す差分では、差分に関わる観点を当てる。

| 観点 | 見ること | 出典の項目 |
|---|---|---|
| 公開元 | 名前の似た、より使われているパッケージが無いか（名前を似せた偽のパッケージ）を見る。公開者や持ち主が、今のバージョンから変わっていないかを見る。 | OpenSSFの「Name Verification」、OWASP Top 10のA03 |
| 変更の中身 | 今のバージョンと上げる先の差分を読み、リリースノートに無い動き（例：外への通信、符号化した値の実行、`~/.ssh`や環境変数の読み取り）が無いかを見る。 | OpenSSFの「Malicious Code Check」 |
| インストールのときに動くスクリプト | インストールのときに動くスクリプトが足されたか、変わったかを見て、中身を読む。 | OpenSSFの「Malicious Code Check」 |
| 既知の脆弱性 | 上げる先のバージョンに既知の重要な脆弱性が無いかを、導入先のパッケージの管理のツールの確認か、公開の脆弱性のデータベースで見る。 | OpenSSFの「Vulnerability Status」、ASVSのV15（15.2.1） |
| 間接の依存 | 新しく増える間接の依存と、本番に要らない依存が無いかを見る。 | OpenSSFの「Dependency Impact」 |
| 保守 | 直近12か月に、活動とリリースがあるかを見る。 | OpenSSFの「Activity Level」と「Release Recency」 |

ダウンロードしたパッケージは、空の一時のフォルダーに置いて読むだけにし、インストールのスクリプトとビルドを動かさない。インストールのスクリプトは、読む前に動かすと、中のコードがそのPCの権限で動くためである。

## 出典

- [OWASP Top 10:2025](https://owasp.org/Top10/2025/)：「It represents a broad consensus about the most critical security risks to web applications.」と、一覧の「A01:2025 - Broken Access Control」～「A10:2025 - Mishandling of Exceptional Conditions」（確かめた日：2026-11-15）
- [2025 CWE Top 25 Most Dangerous Software Weaknesses](https://cwe.mitre.org/top25/archive/2025/2025_cwe_top25.html)：一覧の「Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection')」ほか25の項目（確かめた日：2026-11-15）
- [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)の節「What is the ASVS?」：「The OWASP Application Security Verification Standard (ASVS) Project provides a basis for testing web application technical security controls and also provides developers with a list of requirements for secure development.」（確かめた日：2026-11-15）
- [ASVS 5.0.0の章のファイル](https://github.com/OWASP/ASVS/tree/v5.0.0/5.0/en)：「0x10-V1-Encoding-and-Sanitization.md」～「0x26-V17-WebRTC.md」の章の名前（確かめた日：2026-11-15）
- [ASVS 5.0.0のV1 Encoding and Sanitization](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x10-V1-Encoding-and-Sanitization.md)の1.3.6：「Verify that the application protects against Server-side Request Forgery (SSRF) attacks」（確かめた日：2026-11-15）
- [ASVS 5.0.0のV13 Configuration](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x22-V13-Configuration.md)の13.3.1：「Secrets must not be included in application source code or included in build artifacts.」（確かめた日：2026-11-15）
- [ASVS 5.0.0のV15 Secure Coding and Architecture](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x24-V15-Secure-Coding-and-Architecture.md)の15.2.1：「Verify that the application only contains components which have not breached the documented update and remediation time frames.」（確かめた日：2026-11-15）
- [ASVS 5.0.0のV16 Security Logging and Error Handling](https://github.com/OWASP/ASVS/blob/v5.0.0/5.0/en/0x25-V16-Security-Logging-and-Error-Handling.md)の16.2.5：「For example, it may not be allowed to log certain data, such as credentials or payment details.」（確かめた日：2026-11-15）
- [Concise Guide for Evaluating Open Source Software](https://best.openssf.org/Concise-Guide-for-Evaluating-Open-Source-Software)の「Name Verification」：「Check if a similar name is more popular - that could indicate a typosquatting attack.」、「Malicious Code Check」：「check the installation scripts/routines for maliciousness」、「Vulnerability Status」：「Confirm if the current version is free of known important vulnerabilities (especially long-known ones).」、「Dependency Impact」：「Does it add unexpected or unnecessary indirect dependencies in production?」、「Activity Level」：「Confirm significant recent activity (e.g., commits) has occurred within the previous 12 months.」、「Release Recency」：「Confirm that the last release was issued within the previous 12 months.」（確かめた日：2026-11-15）
