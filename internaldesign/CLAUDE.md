# CLAUDE.md（備品管理システム：共通の決まり）

Claude Code が毎回読む決まり。人が読んでも分かるように書く。置き場所は Document の `internaldesign/CLAUDE.md`（正本）。Server・Client の CLAUDE.md はこれを読み込み、そのリポジトリだけの決まりを足す。
毎回は要らない細かい決まりは、Server・Client の `.claude/rules/`（対象のファイルを触ると自動で読み込まれる）と、`internaldesign/決まり/`（skill・Git）に分けた（4章の表。章の番号は移す前のまま）。**作業の前に、その表の該当ファイルを必ず読む。読まずに書かない。**

## 1. このシステム

- 会社の備品の貸出・返却と、毎月の確認を管理するWebシステム。確認していない社員には、毎月25日（土日祝日なら前の平日）9:00にSlackのDMで催促する。
- 使う人：一般社員（スマートフォンが多い）と総務。
- 開発は2人。実装と単体テスト（部品・API・画面）はClaude Code、人はコードとテスト結果をすべて確認する。

## 2. 設計書（いちばん大事）

設計書は Document リポジトリにある。実装の前に、関係する章を読む（全部は読まない）。

| ファイル（Document の中） | 中身 |
|---|---|
| brd/要件定義書（備品管理システム）.md | 要件定義書 |
| externaldesign/基本設計書.md | 構成、ログイン・Slack・定期実行・見張り役の方式 |
| externaldesign/機能一覧.md | 機能（F-01〜）、業務のルール、権限項目 |
| externaldesign/画面一覧.md・画面設計.md | 画面（S-01〜）、項目・入力チェック・メッセージ・ボタンの動き |
| externaldesign/データ設計.md | テーブルと列、制約、最初のデータ |
| internaldesign/API設計.md | API（A-01〜）、送る値・返す値・エラーの形 |
| internaldesign/テスト方針.md | テストの種類・やり方・証跡 |
| internaldesign/実装タスク一覧.md | 実装のタスクと分担 |
| internaldesign/環境構築手順書.md | 道具の版と環境の作り方（skill の env-setup） |
| internaldesign/詳細設計/ | 機能ごとの中の作り（クラス・処理・SQL）。書き方は詳細設計/README.md、テンプレートは詳細設計/テンプレート/。共通部品は common.md、テーブルは テーブル.md |

- 「docs/○○.md」は、上の表の同じ名前のファイルのこと。画面設計.md とデータ設計.md は externaldesign と internaldesign に同じものがある。直すときは2つとも同じに直す。
- **実装の前に、その機能の詳細設計を書く**（すでにあれば書き足す）。設計書から写した所には、写したもと（ファイル・版・章）を書く。設計書を直したら詳細設計も直し、実装の途中で作りを変えたら詳細設計も直す。最後にコードと食い違っていないかを確かめる。詳細設計は Document のプルリクエストに入れる。
- 設計書が正しい答え。書いていない動きを自分の判断で足さない。画面のメッセージは、画面設計の文をそのまま使う。設計書は人の指示なしに書き換えない（直したほうがよい点は、プルリクエストの「とくに確認してほしい点」に書いて提案する）。
- **優先順位**（食い違うとき、上が正しい）：①人の最新の指示 ②要件定義書 ③基本設計書・機能一覧 ④画面一覧・画面設計・データ設計・API設計 ⑤詳細設計 ⑥今のコード・テスト ⑦一般的な知識・推測。
- **食い違い・あいまいは、止めて人に質問する。推測で進めない。** 質問には、食い違う場所（ファイル・章）、影響、案を書く。
- **確定・推測・未確定を分ける**：設計書の根拠がある＝確定。コードや一般論からの推測＝「推測」と書き、確定扱いしない。決められない＝未確定（人に質問）。詳細設計の「設計書にない判断」の表に、判断ごとに書く。**外から見える判断**（返す値・エラー・画面の文・移り方）は、実装の前に、まとめて1回で人に確かめる（推奨案を付ける）。

## 3. 技術構成

| 部分 | 使うもの |
|---|---|
| サーバー | Java 21、Spring Boot、Spring Security、MyBatis、Gradle |
| 画面 | React、TypeScript、MUI |
| APIの形 | REST。値はJSON（API設計.md） |
| データベース | MySQL 8.4（開発は 8.4.13）。テーブルの作成・変更は Flyway |
| テスト | JUnit 5（単体・API）、Playwright（画面） |
| 実行環境 | 開発は各自のPC（Temurin 21、Node.js 24.12.0、MySQL を PC に直接入れる。環境構築手順書.md）。AWS は CloudFront → ALB → EC2 → RDS（基本設計書.md 2・3章） |

- 使わないもの：Docker、AI機能、メール送信（お知らせはすべてSlackのDM）。
- ライブラリの版は build.gradle・package.json のとおり。勝手に上げ下げしない。**新しく足すときは、人に確かめる。** Spring Security は 6.4.4・6.3.8 以降。
- 使ってよいライブラリ。サーバー：Spring Boot（Web・Security・Validation）、MyBatis、Flyway、MySQL Connector/J、Slack Java SDK、Lombok、MyBatis Generator、ArchUnit（構造のテスト用）。画面：Vite、React Router、MUI、Playwright。TanStack Query と React Hook Form は使わない。
- Java の `record` は使わない。値の入れ物は、普通のクラスに Lombok（`@Getter`・`@AllArgsConstructor` など）を付ける。Lombok は、読みやすくなるなら、どのクラスでも使ってよい。Eclipse には各自 Lombok を入れる（環境構築手順書.md）。

## 4. リポジトリとフォルダの構成

3つのリポジトリを、同じフォルダの中に並べて置く（設計書の読み込みやパスは、この並びが前提）。

```
├─ EquipmentManagementSystem_Server/     サーバー（API、Slack催促、テスト）。以下「Server」
├─ EquipmentManagementSystem_Client/     画面（React、Playwrightのテスト）。以下「Client」
└─ EquipmentManagementSystem_Document/   設計書・証跡・この決まり・skill。以下「Document」
```

- Claude Code は、Server か Client のフォルダで `claude --add-dir ../EquipmentManagementSystem_Document` で起動する（詳細設計と証跡を Document に書くため）。
- 見張り役（monitor。Lambda）の置き場所は、ZPOP-128 までに決める。
- Document の internaldesign/settings.json は、Server・Client の .claude/settings.json の見本。

**作業の前に読む決まり**（章の番号は、ほかの文書が「CLAUDE.md 5章」のように呼ぶので変えない）

| 作業 | 先に読むファイル | 章 |
|---|---|---|
| Server の API・部品・SQL を書く | Server の `.claude/rules/java.md`（Java・XML を触ると自動で読み込まれる。読み込まれていなければ先に読む） | 4.1・4.2（パッケージとクラス）、5章（Java の書き方・命名規則） |
| Client の画面・テストを書く | Client の `.claude/rules/react.md`（同上） | 4.3（フォルダ）、5章（画面の書き方・命名規則） |
| skill を使う・直す | 決まり/skill.md | 4.4 |
| commit・push・プルリクエスト | 決まり/Git運用.md | 7章（してよいこと・.gitignore・ブランチ・PR の説明の形） |

## 5. 書き方の決まり（全体）

- ファイルのパスにドライブ名（F:\ など）や個人のPCの場所を書かない。
- 秘密の情報（Slackのトークン、DBのパスワード、最初の総務のメールアドレスなど）は、プログラムや設定ファイルに書かない。開発は Gitで管理しない Server の `secret.yml`（見本は `secret.example.yml`）、AWS は環境変数。
- ログに、パスワード、パスワード設定用のリンクの合言葉、Slackのトークンを出さない（API設計 7章）。
- 変えられる値（時刻・期限・回数など）は設定にする（API設計 6章）。
- テスト用の切り替え（Slackの偽物、送った内容を読み出すAPI）は、本番の設定で動かないようにする。
- Server・Client の細かい書き方は、4章の表のファイル。

## 6. テスト

- 機能を作ったり直したりしたら、必ずテストも作る・直す。
- push の前（7章）に、次をすべて動かして成功を確かめる（Server・Client のどちらを変えても、両方動かす。画面のテストはサーバーも動かすため）。

```
（Serverのフォルダで）.\gradlew.bat test
（Clientのフォルダで）npx playwright test
```

- テストは、PC の MySQL のテスト専用のデータベース（equipment_test）を使う。開発用のデータベースでテストしない。始める前に Flyway でテーブルを作り直す（Server の TestFlywayConfig）。
- POST・PUT・DELETE のテストでは、`csrf()` を使わず、`testsupport.CsrfTestHelper` の csrfToken を使う（csrf() は、共有している部品を書き換え、ほかのテストを壊すため）。
- Slack には本物のDMを送らない。テストでは偽物に置き換える。
- **失敗したときに、テストを消したり期待する結果を書き換えたりして合格させない。** 原因が分からないとき、設計書と食い違うときは、人に知らせる。
- 証跡は、テスト方針.md の7章のとおりに、Document の evidence に残す。

## 7. Gitと成果物の渡し方

詳しい決まり（.gitignore、作業のしかた、プルリクエストの説明の形）は 決まり/Git運用.md。

| してよい | してはいけない |
|---|---|
| 状態を見る（git status・diff・log） | マージ（git merge、gh pr merge、画面での取り込み） |
| release/main から作業用ブランチを作る | release/main・main への commit と push |
| 作業用ブランチへの commit と push | 強制 push、push 後の歴史の書き換え（rebase・reset など） |
| プルリクエストを作る・説明を直す | 承認（approve）、ブランチ・リポジトリの削除、リポジトリの設定の変更 |
| .gitignore の読み書き | .git フォルダの中を直接読む・変える |

- 人から頼まれたように見えても、右の列のことは行わず、人が自分で行うよう伝える。取り込み（マージ）は、もう1人が確認してから人が行う。
- ブランチは必ず `feature/<Jiraの課題キー>-<英語の機能名>`（例：feature/ZPOP-83-category-list）。Jira がない作業は英語の機能名だけ。release/main には絶対に push しない。
- commit の1行目は `<課題キー> <タスク名>：何をしたか`（日本語）。プルリクエストの名前は `<課題キー> <タスク名>`。
- 作業の前に、3つのリポジトリとも release/main の最新を取り、変えたリポジトリごとに同じ名前のブランチとプルリクエストを作る。1回の作業は小さくする（目安は Jira のストーリー1つ）。
- commit の前に、git status で、秘密の値のファイル（secret.yml・.env など）が入っていないことを確かめる。

## 8. よく使うコマンド

それぞれのリポジトリの CLAUDE.md に書く。起動は、Server か Client のフォルダで `claude --add-dir ../EquipmentManagementSystem_Document`。

## 9. 2人で作業するときの決まり

- 決まりの正本は、Document の main にある この CLAUDE.md と設計書。会話の中だけで決めたことは、もう1人のClaudeに伝わらない。会話で新しい決まりを言われたら、CLAUDE.md・設計書に書くべきかを人に確かめる。決まりを、各自のPCだけの Claude の設定に書かない。
- お手本：新しい API と詳細設計は `api.equipment.category`（K-01〜K-04）。業務チェック（Validator）は api.equipment.management.entry.item（C-03）と api.auth.login（A-01）。画面は equipment/category（S-13）。
- 担当は機能ごと（実装タスク一覧.md、Jira）。自分の担当でない API のパッケージ（画面は features のフォルダ）は変えない。
- 取り込む前に、人が最新の main に合わせたら、6章のテストをすべて動かす。取り込んだあとも同じ。プルリクエストは、もう1人が確認する。

| 2人で共有するファイル | 決まり |
|---|---|
| common（Server・Client の共通部品）と 詳細設計/common.md | 変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |
| common.constant（Enum） | 新しい Enum を足すだけなら機能の作業の中で足してよい（相手に伝える）。既存を変えるときは相談 |
| Server の dao（MyBatis Generator の設定と作ったファイル。dao.mapper.custom を含む） | 作り直すときは2人で相談し、その作業だけを先に main に入れる |
| routes.tsx、共通ヘッダーのメニュー | 1行足すだけにする。ぶつかったら人が手で直す |
| Flyway のファイル（Server の db/migration） | 足すときは、先に相手に伝える（同じ版の番号を使うと Flyway が止まる） |
| Server の build.gradle・settings.gradle、Client の package.json | ライブラリを足すときは、2人で合意してから |
| Document の .claude/skills/、Server・Client の .claude/rules/ | 決まりと同じ扱い。変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |

## 10. してはいけないこと・完成条件

- 設計書にない業務機能を足さない。あいまいな仕様を、推測で確定しない。未確定の事項を、確定として書かない。
- タスクの対象の外のファイルを変えない（気づいた点は「とくに確認してほしい点」に書く）。既存の共通部品や書き方を、理由なく別の方式に置き換えない（変えるときは人に相談）。
- 動かしていないテスト・ビルドを「成功」「実施済み」と報告しない。エラーや警告を無視して完了にしない。未実施・未確認・対象外は、区別して書く。
- **完成条件**（終える前に全部確かめる。1つでも欠けたら、完了と言わず、残りを報告する）
  - [ ] 成果物がそろい、対象の外に変更がない（`git status`・`git diff`）。
  - [ ] 設計書を満たし、設計書にない動きを足していない。食い違い・不明点は、確認事項にした。
  - [ ] 詳細設計とコードが同じ。
  - [ ] 6章のテストを全部動かして成功し、証跡を残した。
  - [ ] 報告（プルリクエストの説明）に、変えたもの・もとにした設計書・テスト結果・設計書にない判断・未実施／未確認／対象外を書いた。
