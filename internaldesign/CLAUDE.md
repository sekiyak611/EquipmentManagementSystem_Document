# CLAUDE.md（備品管理システム：共通の決まり）

このファイルは、Claude Codeが備品管理システムの作業をするときに毎回読む決まりごと。人が読んでも分かるように書いている。

- 置き場所は、Documentリポジトリの `internaldesign/CLAUDE.md`。これが決まりの正本。
- Server・Client リポジトリの CLAUDE.md は、このファイルを読み込む（4章）。そちらには、そのリポジトリだけの決まりを書く。

## 1. このシステム

- 会社の備品の貸出・返却と、毎月の確認を管理するWebシステム。確認していない社員には、毎月25日（土日祝日なら前の平日）9:00にSlackのDMで自動的に催促する。
- 使う人：一般社員（スマートフォンからの利用が多い）と総務。
- 開発は2人。実装・単体テスト・結合テストはClaude Codeが行い、人はコードとテスト結果をすべて確認する。

## 2. 設計書（いちばん大事）

設計書は、Documentリポジトリ（EquipmentManagementSystem_Document）にある。実装の前に、関係する設計書を必ず読む。

| ファイル（Documentリポジトリの中の場所） | 中身 |
|---|---|
| brd/要件定義書（備品管理システム）.md | 要件定義書（総務との合意） |
| externaldesign/基本設計書.md | システムとAWSの構成、ログイン・Slack・定期実行・見張り役の方式 |
| externaldesign/機能一覧.md | 機能（F-01〜）、業務のルール、権限項目 |
| externaldesign/画面一覧.md | 画面（S-01〜）と画面の移り方 |
| externaldesign/画面設計.md | 画面ごとの項目・入力チェック・メッセージ・ボタンの動き |
| externaldesign/データ設計.md | テーブルと列、制約、最初に入れるデータ |
| internaldesign/API設計.md | API（A-01〜）、送る値・返す値・エラーの形 |
| internaldesign/テスト方針.md | テストの種類・やり方・証跡の残し方 |
| internaldesign/実装タスク一覧.md | 実装のタスクと分担 |
| internaldesign/環境構築手順書.md | 開発用のPCに入れる道具の版と、環境の作り方（skill の env-setup が使う） |
| internaldesign/詳細設計/ | 機能ごとの中の作り（クラス・処理の流れ・SQL）と、設計書から写した中身。1つの機能（4.1のパッケージ）に1つのフォルダを作り、機能全体・APIごと・画面ごとのファイルに分ける。書き方は internaldesign/詳細設計/README.md、テンプレートは internaldesign/詳細設計/テンプレート/ |

- 設計書やコードの中で「docs/○○.md」と書いてある所は、上の表の同じ名前のファイルのこと（以前は1つのリポジトリの docs フォルダに置いていたため）。
- 画面設計.md とデータ設計.md は、externaldesign と internaldesign の2か所に同じものを置いている。直すときは、必ず2つとも同じに直す。

- **実装の前に、その機能の詳細設計を書く。** Documentリポジトリの internaldesign/詳細設計/<機能名>/ に、機能全体（<機能名>.md）・APIごと・画面ごとのファイルを、internaldesign/詳細設計/テンプレート/ の形で書く（すでにあれば書き足す。共通部品は common.md）。書き方は internaldesign/詳細設計/README.md。設計書の中身も写し、写した所には写したもと（ファイル・版・章）を書く。設計書を直したら、写した詳細設計も直す。実装の途中で作りを変えたら詳細設計も直し、最後にコードと食い違っていないかを確かめる。詳細設計は成果物の zip に入れる（7章）。
- 設計書が正しい答え。設計書に書いていない動きを、自分の判断で足さない。詳細設計は、設計書（API設計など）の決まりを変えるものではない。
- 設計書があいまい、または設計書どうしが食い違うときは、実装を止めて人に質問する。推測で進めない。
- 設計書は人の指示なしに書き換えない。直したほうがよい点に気づいたら、説明.md（7章）の「とくに確認してほしい点」に書いて提案する。
- 画面のメッセージは、画面設計に書かれた文をそのまま使う。

## 3. 技術構成

| 部分 | 使うもの |
|---|---|
| サーバー | Java 21、Spring Boot、Spring Security、MyBatis、Gradle |
| 画面 | React、TypeScript（JavaScriptに型の決まりを足した書き方）、MUI（画面の部品集） |
| APIの形 | REST（URLで「もの」を、GET・POST・PUT・DELETEで「操作」を表す）。値はJSONでやり取りする（docs/API設計.md） |
| データベース | MySQL 8.4（開発は 8.4.13。AWS は RDS for MySQL の 8.4 系）。テーブルの作成・変更は Flyway |
| テスト | JUnit 5（単体・API）、Playwright（画面） |
| 実行環境 | 開発は各自のPC（Temurin 21、MySQL 8.4.13、Node.js 24.12.0。版と入れ方は docs/環境構築手順書.md 1章）。シナリオテストとリリースはAWS（Amazon Corretto 21）。AWSでは CloudFront → 内部用のALB → EC2 → RDS の形で動かす（docs/基本設計書.md 2・3章） |
| 使わないもの | Docker（2026-11-08 に、今は使わないと決めた。Docker への移行は保留中）、AI機能、メール送信（お知らせはすべてSlackのDM） |

- ライブラリの版は、build.gradle と package.json に書いた版を使う。勝手に上げ下げしない。新しく足すときは、人に確かめる。
- Spring Security は、CVE-2025-22228 の修正が入った版（6.4.4・6.3.8）以降を使う。
- 使ってよいライブラリ（人が確かめ済み）
  - サーバー：Spring Boot（Web・Security・Validation）、MyBatis、Flyway（MySQL用のモジュールを含む）、MySQL Connector/J（MySQLにつなぐ部品）、Slack Java SDK
  - 画面：Vite（開発用のサーバーと、画面の組み立て）、React Router（画面の切り替え）、MUI（@mui/material と、MUIが使う @emotion/react・@emotion/styled）、Playwright
  - 使わないと決めたもの：TanStack Query（APIの値の取り込みと保持）、React Hook Form（入力欄の管理）

## 4. リポジトリとフォルダの構成

リポジトリ（GitHubの保管場所）は3つに分ける。3つとも、同じフォルダの中に並べて置く（例：Eclipseのワークスペースの直下）。設計書の読み込みやパスは、この並び方を前提にしている。

```
（同じフォルダ）
├─ EquipmentManagementSystem_Server/     サーバー（Spring Boot。API、Slack催促、テスト）。以下「Server」
├─ EquipmentManagementSystem_Client/     画面（React。画面、Playwrightのテスト）。以下「Client」
└─ EquipmentManagementSystem_Document/   設計書・証跡・この共通の決まり。以下「Document」
```

| リポジトリ | 中身 |
|---|---|
| Server | CLAUDE.md（Serverだけの決まり）、.claude/settings.json、build.gradle などの組み立ての設定、src/、secret.example.yml |
| Client | CLAUDE.md（Clientだけの決まり）、.claude/settings.json、package.json などの組み立ての設定、src/、tests/ |
| Document | brd/（要件定義）、externaldesign/（基本設計）、internaldesign/（詳細設計とこの共通の決まり）、evidence/（テストの証跡。docs/テスト方針.md の7章）、.claude/skills/（Claude Code の skill。4.4） |

- Claude Codeは、Server か Client のフォルダで起動する。そのとき、Documentのフォルダも読み書きできるようにする（`claude --add-dir ../EquipmentManagementSystem_Document`、または起動したあとに `/add-dir ../EquipmentManagementSystem_Document`）。詳細設計と証跡は Document に書くため。
- 見張り役（monitor。AWS Lambda、Java 21。docs/API設計.md 3.10）の置き場所は、見張り役のタスク（ZPOP-128）までに決める。
- Documentの internaldesign/settings.json は、Server・Client の .claude/settings.json の見本。

### 4.1 サーバー（Server）のパッケージ

パッケージ名の頭は `jp.co.highjunk.equipment`。機能は、docs/API設計.md 3章の節のまとまりで分ける。

| パッケージ | 受け持つもの |
|---|---|
| auth | A-01〜A-07、アカウントロック、パスワードの決まり |
| health | A-08（動いているかを答える） |
| mine | B-01〜B-05（自分の備品。S-05、S-06） |
| equipment | C-01〜C-08 |
| loan | D-01〜D-03 |
| confirmation | E-01、E-02 |
| reminder | E-03、E-04、Slack催促の定期実行 |
| category | K-01〜K-04 |
| user | G-01〜G-07 |
| role | H-01〜H-06 |
| importer | I-01〜I-03 |
| common | 共通部品（下の表） |

| 共通部品 | 中身 |
|---|---|
| common.config | 設定値の読み込み、時計（java.time.Clock） |
| common.security | ログインと権限の確かめ方（Spring Securityの設定） |
| common.error | エラーの返し方（docs/API設計.md 2.4） |
| common.slack | Slack送信の部品と、テスト用の偽物・送った内容を読み出すAPI |
| common.csv | CSVの読み書き（UTF-8・Shift_JIS） |
| common.calendar | 祝日、催促日の計算（25日。土日祝日なら前の平日）、「今月確認済み」の判定 |
| common.passwordlink | パスワード設定用のリンク（合言葉）を作り、DMを送る（A-04、G-03、G-06で使う） |
| common.web | 組み立てた画面（Client の dist）を配る。画面のアドレスでは index.html を返す |
| common.constant | Enum（列挙型＝決まった値だけを持つ型。例：備品の管理状態、権限項目のコード）。Enum はすべてここに置く |

mapper と dto は、機能のパッケージの外にまとめて置く。その下に、機能と同じ名前のパッケージを作る。

| パッケージ | 中身 |
|---|---|
| 機能（例：loan） | controller（APIの入口）、service（業務のルール）、validator（業務チェック）、model（テーブルの1行の形）の4つに分ける。service には、interface（インターフェース＝メソッドの名前・受け取る値・返す値だけを決めた型）の `<機能名>Service` と、中身を書いた `<機能名>ServiceImpl` を並べて置く。業務チェックがない機能（例：health）は、validator を作らない |
| mapper.<機能名>（例：mapper.loan） | MyBatisでデータベースを読み書きする部品（インターフェース） |
| dto.<機能名>（例：dto.loan） | APIで受け取る値・返す値の形 |
| common.constant | Enum（上の表） |

```
jp.co.highjunk.equipment
├─ loan/
│  ├─ controller/   LoanController
│  ├─ service/      LoanService（interface）、LoanServiceImpl（中身）
│  ├─ validator/    LoanValidator（業務チェック）
│  └─ model/        Loan（テーブルの1行）
├─ mapper/
│  └─ loan/         LoanMapper
├─ dto/
│  └─ loan/         LoanRequest、LoanResponse など
└─ common/
   └─ constant/     Enum（例：EquipmentStatus）
```

- MyBatisのXMLは、`src/main/resources` の、mapperと同じパッケージの場所に置く（例：`src/main/resources/jp/co/highjunk/equipment/mapper/loan/LoanMapper.xml`）。
- Enum は、機能の中にも mapper・dto の中にも作らない。1つの機能でしか使わない Enum も common.constant に置く（同じ値の Enum が2つできるのを防ぐため）。
- テストは、本体と同じパッケージ名で `src/test/java` に置く（API のテストは、機能のパッケージ。例：`jp.co.highjunk.equipment.loan`）。

### 4.2 見張り役（monitor）のパッケージ

- パッケージ名は `jp.co.highjunk.equipment.monitor`。
- Server の部品は共有しない。Slackへ送る処理も monitor の中に書く。DMの文面と送り方は、Server の common.slack とそろえる。

### 4.3 画面（Client）のフォルダ

```
EquipmentManagementSystem_Client/
├─ src/
│  ├─ main.tsx            入口。MUIのテーマと画面の切り替えを組み立てる
│  ├─ routes.tsx          URLと画面（S-01〜S-19）の対応表
│  ├─ common/             共通部品
│  │  ├─ api/             APIの呼び出し（CSRFトークンを付ける、エラーの形、401・403のときの移り方）、値の取り込みと保持
│  │  ├─ auth/            ログイン中の人と権限項目（A-03）。権限によるボタンの出し分け
│  │  ├─ components/      共通ヘッダー、メッセージ表示、確認ダイアログ、押したら処理が終わるまで押せないボタン、エラー画面（S-19）、2つ以上の機能で使う部品（例：種別を選ぶ欄）
│  │  ├─ format/          日付・空の値の表示の形（画面設計 1.3）
│  │  └─ theme/           MUIのテーマ（色・文字の大きさ・スマートフォンとPCの境目の幅）
│  ├─ dev/                共通部品の見本の画面（開発とテストのときだけ開ける。組み立てた画面には入らない）
│  └─ features/           機能ごと（サーバーと同じ名前）
│     ├─ auth/            S-01〜S-04
│     ├─ mine/            S-05、S-06
│     ├─ equipment/       S-07〜S-09
│     ├─ loan/            S-10
│     ├─ confirmation/    S-11
│     ├─ reminder/        S-12
│     ├─ category/        S-13
│     ├─ user/            S-14、S-15
│     ├─ role/            S-16、S-17
│     └─ importer/        S-18
└─ tests/                 Playwrightのテスト（features と同じ名前のフォルダに分ける）
```

- 各機能の中は、pages/（画面）、components/（その機能だけで使う部品）、api.ts（その機能のAPIの呼び出し）、types.ts（APIで受け渡す値の型）に分ける。
- 画面からAPIを呼ぶときは、common/api の apiGet・apiPost・apiPut・apiDelete を使う。失敗すると ApiError（status・message・errors）が投げられる（詳細設計 common.md 11.3）。
- ファイル名に画面ID（S-05 など）は入れない。

### 4.4 skill（Claude Code の作業の手順書）

skill は、作業の順番とチェック表をまとめたファイル（SKILL.md）。Claude Code は、作業の内容に合うと判断したときに自動で読み込む。人が `/backend-impl K-01_種別一覧` のように名前を打って呼び出すこともできる（skill に渡すのは、実装タスク一覧.md の「タスク名」か、Jira の課題キー）。

- 置き場所は Document の `.claude/skills/<skillの名前>/SKILL.md`。Server・Client で `--add-dir ../EquipmentManagementSystem_Document` を付けて起動すると、2人とも同じ skill を使える。各自のPCだけに skill を置かない（9章）。
- skill には決まりを書き写さず、この CLAUDE.md と設計書の章を指す。skill と CLAUDE.md・設計書が食い違ったら、CLAUDE.md・設計書が正しい。

| skill | 使うとき |
|---|---|
| backend-impl | Server の実装（設計書を読む → 詳細設計 → 実装。テストは書かない） |
| backend-test | Server のテスト（単体・API）を書き、Server・Client のテストを全部動かす |
| frontend-impl | Client の実装（設計書を読む → 詳細設計 → 実装。テストは書かない） |
| frontend-test | Client のテスト（Playwright）を書き、Server・Client のテストを全部動かす |
| detailed-design | 詳細設計を書く・直す・コードと突き合わせる |
| backend-review | Server の実装のレビュー。コードは直さず、指摘の一覧を返す。作った会話とは別のエージェントで動く |
| frontend-review | Client の実装のレビュー（同じ） |
| deliver-zip | 最後のテスト、証跡、説明.md・変更ファイル一覧.md、zip（7章） |
| reverse-engineer | コードから詳細設計を書き起こし、設計書との食い違いを一覧にする（設計書は直さない） |
| implementation-guidelines | 実装・テスト・レビューのときの一般的な心得（読みやすさ、例外、型など）。この CLAUDE.md にない所で使う |
| env-setup | 開発環境を作る・確かめる（Windows のPC） |

1つのストーリー（Jira の課題。API 1本、画面1つ、仕組み1つ）は、人が次の順に skill を呼んで進める。ストーリーの4つのサブタスクとの対応は、detailed-design が［詳細設計］、backend-impl・frontend-impl が［実装］、backend-test が［単体テスト］と［結合テスト］、frontend-test が画面の［結合テスト］（実装タスク一覧.md 0.1）。レビューと zip づくりはサブタスクにしていない。skill どうしは自動でつながない（人がそれぞれの終わりに結果を確かめるため）。

```
（API・仕組みのストーリー。例：K-01_種別一覧）
/detailed-design K-01_種別一覧 → /backend-impl K-01_種別一覧 → /backend-test K-01_種別一覧 → /backend-review K-01_種別一覧 →（指摘を直す）→ /deliver-zip K-01_種別一覧

（画面のストーリー。例：S-13_種別管理）
/detailed-design S-13_種別管理 → /frontend-impl S-13_種別管理 → /frontend-test S-13_種別管理 → /frontend-review S-13_種別管理 →（指摘を直す）→ /deliver-zip S-13_種別管理
```

- backend-impl・frontend-impl は、詳細設計がすでにあれば、それを読んで書き足す。
- 画面のストーリーの単体テストは、テスト方針にないため、着手するときに中身を人と相談して決める（実装タスク一覧.md 0.1）。

## 5. 書き方の決まり

**全体**
- ファイルのパスにドライブ名（F:\ など）や、個人のPCの決まった場所を書かない。2人のPCで置き場所が違うため。
- 秘密の情報（Slackのトークン、データベースのパスワード、最初の総務の担当者のメールアドレスなど）は、プログラムや設定ファイルに書かない。開発では、Gitで管理しない Server の `secret.yml` に書く（書き方の見本は Server の `secret.example.yml`）。AWSでは環境変数で渡す。
- ログに、パスワード、パスワード設定用のリンクの合言葉、Slackのトークンを出さない（docs/API設計.md 7章）。
- 変えられる値（時刻、期限、回数など）は、プログラムに直接書かず設定にする（docs/API設計.md 6章）。
- テスト用の切り替え（Slackの偽物、送った内容を読み出すAPI）は、本番の設定で動かないようにする。

**サーバー（Java）**
- パッケージは 4.1 のとおり機能ごとに分ける。業務のルールは service（`<機能名>ServiceImpl`）に、業務チェックは validator に書き、controller には書かない。
- service は、interface の `<機能名>Service` と、中身の `<機能名>ServiceImpl`（`implements <機能名>Service`）に分け、同じ service パッケージに置く。`@Service` は ServiceImpl に付ける。controller は interface（`<機能名>Service`）を受け取って使い、ServiceImpl を直接使わない。
- 確かめることは、次の2つに分ける。
  - **入力チェック**：受け取った値だけで分かるもの（必須、文字数、形式、数の範囲など）。dto の印（`@NotBlank`・`@Size` など）と、controller の `@Valid` で確かめる。
  - **業務チェック**：データベースの中身や業務のルールと照らして確かめるもの（例：同じ名前の種別がもうある、使われている種別は消せない、すでに貸し出されている、その人が操作してよい対象か）。`<機能名>/validator/` の `<名前>Validator` に書く。
- Validator の決まり
  - `@Component` を付ける。ServiceImpl から、書き換えの前に呼ぶ（ServiceImpl の `@Transactional` の中で呼び、確かめてから書き換えるまでを1つのまとまりにする）。controller からは呼ばない。
  - 守れないときは、common.error の例外（BusinessRuleException・NotFoundException・ConflictException など。投げる例外と文は、その API の詳細設計 9章）を投げる。
  - 読むだけにする（mapper の `select…`・`count…` だけを使う）。書き換えは ServiceImpl で行う。確かめるために読んだ行（model）は、返して ServiceImpl で使ってよい（同じ行を2回読まないため）。
- Controller は1つの機能に1つだけ。URLの頭が違うAPI（例：auth の `/api/auth/...` と `/api/me/password`）も、同じControllerに書く。
- 機能は、その機能の中だけで完結させる。ほかの機能の service・validator・model と、mapper・dto の下のほかの機能のパッケージ（例：loan から mapper.equipment、dto.equipment）は使わない。使ってよいのは、自分の機能の mapper.<機能名>・dto.<機能名> と、common の部品だけ。
- mapper.<機能名> が使ってよいのは、同じ機能の model と common だけ。dto.<機能名> が使ってよいのは common だけ（common.constant の Enum など）。
- common から機能のパッケージ（mapper・dto の下も含む）を使わない。循環（AがBを使い、BもAを使う形）を作らない。
- 2つ以上の機能で使う業務のルール（4.1の common.calendar・common.passwordlink）は、common に1つだけ置き、書き写さない。
- 機能をまたいで同じルールが書かれている所（貸出のルール：mine・equipment・importer、確認のルール：mine・equipment・confirmation）は、1か所を直したらほかも同じように直し、テストも直す。
- 各機能の mapper は、必要なテーブルを直接読み書きしてよい（テーブルの持ち主は決めない）。例：mine は、貸出のときに equipment の最終確認日を書き換える。
- SQLで JOIN とサブクエリ（SQLの中にもう1つSQLを入れる書き方）を使わない。複数のテーブルの情報は、テーブルごとにSQLを出し、Javaで突き合わせる。
- 1件ずつSQLを出さない（N+1問題＝一覧の件数だけSQLが出てしまう問題を防ぐ）。IDをまとめて集め、`IN`（MyBatisの `<foreach>`）で1回で読む。
- 今の日時は、直接取らずに java.time.Clock から取る（テストで日時を止められるようにするため）。
- APIごとに、必要な権限項目をサーバー側で必ず確かめる（例：@PreAuthorize("hasAuthority('EQUIPMENT_UPDATE')")）。権限項目のコードは docs/データ設計.md の5.3。
- 画面設計に書かれたチェック（入力チェックと業務チェック）は、サーバー側でも必ず行う。画面側のチェックだけに頼らない。
- 編集するAPIは、楽観ロック（version 列）で、ほかの人が先に保存していたら 409 を返す。
- SQLは MyBatis の XML に書く。値は必ずパラメータ（#{}）で渡し、文字をつなげてSQLを作らない（SQLインジェクション＝外から入れた文字でデータベースを操られる攻撃を防ぐため）。
- 削除は論理削除（deleted_at）。一覧や検索では、削除済みの行を出さない。
- 2つ以上の書き換え（INSERT・UPDATE・DELETE）を1つの操作として行う処理は、ServiceImpl のメソッドに `@Transactional` を付け、途中で失敗したら全部を元に戻す。controller・validator・mapper と、interface の `<機能名>Service` には付けない。
- Slack の送信は、`@Transactional` の中で行わない。データベースへの書き込みが確定してから送る（送ったのにデータベースは元に戻った、を防ぐため）。送るのに失敗したときの扱いは、その機能の設計書・詳細設計に従う。
- 操作する対象（備品・貸出など）の ID を画面から受け取る API は、権限項目の確認に加えて、その人が操作してよい対象かを validator で確かめる（業務チェックの1つ。ServiceImpl から呼ぶ）（例：B-03 の返す・B-04 の確認したは、ログインしている人が借りている備品だけを対象にする。B-04 は docs/API設計.md 4.7 のとおり、ほかの人の備品が含まれていたら 403）。ID を書き換えて他人のデータを読む・変えることを防ぐため（IDOR と呼ばれる穴）。

**画面（React）**
- スマートフォン優先の画面（S-01〜S-06、S-19）は、スマートフォンの画面を先に作る。
- ボタンを押したら、処理が終わるまで押せなくする（二重登録を防ぐ）。
- フォルダは 4.3 のとおり機能ごとに分ける。ほかの機能のフォルダのものは使わない。使ってよいのは common だけ（サーバーと同じ決まり）。2つ以上の機能で使う部品は common/components に置く。
- APIは、common/api の部品で、ブラウザに最初からある fetch を使って呼ぶ。値の取り込みと保持も common/api の部品で行う。
- 入力欄は、MUIの部品と React の useState で作る。入力チェックのメッセージは、画面設計の文をそのまま使う。
- 画面設計に書いていない表示は、文のないものだけ足してよい（読み込み中の印、処理中にボタンを押せなくする、など）。新しい文（例：「データがありません」）は足さず、人に質問する。

**名前の付け方（命名規則）**

名前は英語。`<名前>` には、その機能やテーブルを表す英語を PascalCase（単語の頭を大文字にしてつなげる書き方。例：Category、LoanHistory）で入れる。

| もの | 付け方 | 例 |
|---|---|---|
| controller | `<機能名>Controller` | CategoryController |
| service | interface は `<機能名>Service`、中身は `<機能名>ServiceImpl` | CategoryService、CategoryServiceImpl |
| validator | 語尾を `Validator` にする。基本は `<機能名>Validator`。確かめることが多ければ、対象ごとに分けてよい | CategoryValidator、LoanValidator |
| mapper | `<テーブルの名前>Mapper`（機能の中でテーブルが2つ以上なら、テーブルごとに分けてよい） | CategoryMapper、LoanMapper |
| mapper のメソッド | 読む：`select…`（1件は `selectById`、まとめては `selectByIds`）、数える：`count…`、足す：`insert`、変える：`update…`、論理削除：`markDeleted` | selectById、countByName、markDeleted |
| model（テーブルの1行） | テーブルの名前の単数形 | Category（categories）、Loan（loans） |
| dto | 受け取る値は `…Request`、返す値は `…Response` | CategoryCreateRequest、CategoryResponse |
| Enum | 意味を表す名前。値は大文字と「_」で、API設計・データ設計の値と同じ文字 | EquipmentStatus.MANAGED（データ設計の管理状態 MANAGED） |
| テスト（Server） | API のテストは `<機能名>ApiTest`、単体テストは `<テストするクラス>Test` | CategoryApiTest、CategoryValidatorTest、ReminderDateCalculatorTest |
| 画面（Client） | 画面は `…Page.tsx`、部品は役目を表す名前の `.tsx`（どちらも PascalCase） | CategoryListPage.tsx、CategoryForm.tsx |
| api.ts の関数 | 読む：`get…`、足す：`create…`、変える：`update…`、消す：`delete…`（camelCase＝最初の単語だけ小文字） | getCategories、createCategory |
| types.ts の型 | Server の dto と同じ名前 | CategoryResponse |
| テスト（Client） | `tests/<機能名>/<画面を表す名前>.spec.ts`（小文字と「-」） | tests/category/category-list.spec.ts |
| 変数・メソッド・関数 | camelCase。定数は大文字と「_」 | lentOn、SUCCESS_DISPLAY_MS |

## 6. テスト

- 機能を作ったり直したりしたら、必ずテストも作る・直す。
- 成果物の zip（7章）を作る前に、次をすべて動かし、成功していることを確かめる（Server・Client のどちらを変えても、両方動かす。画面のテストはサーバーも動かして確かめるため）。

```
（Serverのフォルダで）
.\gradlew.bat test

（Clientのフォルダで）
npx playwright test
```

- テストには、自分のPCのMySQLに作ったテスト専用のデータベース（equipment_test）を使う。開発用のデータベースでテストしない。テストを始める前に、Flywayでテーブルを作り直す（Server の src/test にある TestFlywayConfig が行う）。
- テストで POST・PUT・DELETE を送るときは、Spring Security のテスト用の csrf() を使わず、`jp.co.highjunk.equipment.testsupport.CsrfTestHelper` の csrfToken を使う。csrf() は、ほかのテストと共有している部品の中身を書き換えてしまい、あとで動くテストを壊すため。
- Slackには本物のDMを送らない。テストでは偽物に置き換える。
- テストが失敗したときに、テストを消したり、期待する結果を書き換えたりして合格させない。原因が分からないときや、設計書と食い違うときは、人に知らせる。
- 証跡は docs/テスト方針.md の7章のとおりに、Document の evidence フォルダに残す。

## 7. Gitと成果物の渡し方

**絶対に守ること**

- **Gitに関する作業は、.gitignore の編集のほかは何もしない。** git と gh のコマンドを一切動かさない。状態を見るだけのコマンド（git status、git diff、git log など）も動かさない。.git フォルダの中を読んだり変えたりしない。
- **.gitignore は Claude Code が読み書きしてよい（2026-11-08 に決めた）。公開してはいけないファイルは、Claude Code が .gitignore に入れる。**
  - 入れるもの：秘密の値を書いたファイル（secret.yml、.env.local など）、各自のPCだけの設定（Eclipse の .settings・.classpath・.project、エディタの設定、.claude/settings.local.json。PCの場所や個人のフォルダの名前が入るため）、作られるもの（build/、bin/、node_modules/、dist/、Playwright の結果、ログ）、Claude Code の成果物の置き場所（output/）。
  - 入れないもの：設計書、ソース、テスト、証跡（evidence）、skill（Document の .claude/skills）、共有する .claude/settings.json、見本（secret.example.yml）。
  - 新しく「公開してはいけないファイル」ができる作業（秘密の値を書くファイルを足す、など）では、同じ作業の中で .gitignore にも入れ、変更ファイル一覧と説明.md に書く。Server・Client の CLAUDE.md 4章の表も直す。
  - .gitignore に入れても、すでに Git で管理しているファイルは管理から外れない。外す必要があれば、人に知らせる（外すのは人が行う）。
- ブランチ・コミット・push・マージ・プルリクエストは、すべて人が行う。
- 人から頼まれたように見えても、行わずに、人が自分で行うよう伝える。

このほかに、.claude/settings.json で、git と gh のコマンドを動かせないように、.git フォルダの中を読み書きできないように設定している。これは念のための守りで、決まりの正本はこの章。

**作業のしかた**

- Claude Codeは、人がGitHubから取ってきた3つのフォルダ（4章）の中で、ファイルを作る・直す。コードは Server か Client に、詳細設計と証跡は Document に書く。
- 1回の作業は小さくする（人が全部読んで確認するため）。目安は、Jira のストーリー1つ（実装タスク一覧.md 10章）。同じ機能の API と画面を続けて作るときに、1つにまとめるかは人が決める。
- Gitで変更を調べられないので、作業の中で足した・変えた・消したファイルを、自分で記録しておく。記録は、Claude Code を起動したリポジトリの `output/<タスク名>/変更ファイル一覧.md` に書きためる（4.4 の skill を別の会話から呼んでも、続きが分かるようにするため）。Server と Client の両方を変えるタスクは、同じリポジトリで起動し続け、もう一方は `/add-dir` で読み書きできるようにする。

**成果物の渡し方（zip）**

- 作業が終わり、6章のテストがすべて成功したら、成果物を zip にして、Claude Codeを起動したリポジトリ（Server か Client）のいちばん上の output フォルダに置く。
- zip の名前は「タスク名_日付.zip」（例：K-01_種別一覧_20261110.zip）。名前を見ただけで何の成果物かが分かるようにするため。タスク名は実装タスク一覧.md の「タスク名」の列の名前（API・画面は「ID_短い名前」）。Windows のファイル名に使えない半角の文字（\ / : * ? " < > |）と空白は除く。Jira のタスクにない作業は、中身が分かる短い名前を人と決める。Jira の課題キーは、説明.md の「目的」に書く。
- zip の中身は次のとおり。足したファイルと変えたファイルを、リポジトリの名前のフォルダの下に、リポジトリと同じフォルダの形のまま入れる。人は、それぞれのフォルダの中身を、同じ名前のリポジトリに反映する。

```
K-01_種別一覧_20261110.zip
├─ 説明.md                             下の形の説明の文
├─ 変更ファイル一覧.md                  足した・変えた・消したファイルの一覧（リポジトリごと。消したファイルは、ここにだけ書く）
├─ EquipmentManagementSystem_Server/ …   Serverで足したファイルと変えたファイル
├─ EquipmentManagementSystem_Client/ …   Clientで足したファイルと変えたファイル
└─ EquipmentManagementSystem_Document/ … 書いた・直した詳細設計（internaldesign/詳細設計/）と、今回の証跡（evidence/）。決まり・skill を直したときは、それも入れる
```

説明.md の形（人がプルリクエストを作るときに、そのまま使う）

```
## 目的
（Jiraの課題キーと、何のための変更か）
## 変更した内容
（主な変更を箇条書き）
## もとにした設計書
（例：docs/画面設計.md 3章、docs/API設計.md B-01）
## テストの結果
（動かしたテストの件数・成功・失敗。証跡の置き場所）
## とくに確認してほしい点
（判断に迷った所、設計書にない動き、セキュリティに関わる所）
```

## 8. よく使うコマンド

それぞれのリポジトリの CLAUDE.md に書く（Server・Client で違うため）。共通のものは次のとおり。

| やること | コマンド |
|---|---|
| Claude Codeを起動する | Server か Client のフォルダで `claude --add-dir ../EquipmentManagementSystem_Document` |

## 9. 2人で作業するときの決まり

**決まりの正本**

- 決まりの正本は、Documentリポジトリの main にある internaldesign/CLAUDE.md（このファイル）と設計書。人は、作業を始める前に、3つのリポジトリとも最新の main を取ってくる。
- 会話の中だけで決めたことは、もう1人のClaudeには伝わらない。決まりが変わったら、人が CLAUDE.md か設計書に書いて main に反映し、相手に伝える。Claude Codeは、会話で新しい決まりを言われたら、CLAUDE.md・設計書に書くべきかを人に確かめる。
- 決まりを、各自のPCだけにあるClaudeの設定に書かない（相手から見えないため）。

**お手本**

- 新しい機能は、category（種別管理。API は ZPOP-83〜86、画面は ZPOP-115）を手本にして、同じ書き方で作る。category ができるまでは、health（A-08）の controller・service（HealthService と HealthServiceImpl）と、mapper.health・dto.health の書き方に合わせる（health には業務チェックがないため、validator の書き方は 5章の決まりに従う）。詳細設計も、Document の internaldesign/詳細設計/ の category/（できるまでは health/）を手本にする。

**担当**

- 担当は機能ごとに分ける（Document の internaldesign/実装タスク一覧.md の分担、Jiraの担当者）。自分の担当でない機能のフォルダは変えない。

**2人で共有するファイル**

| ファイル | 決まり |
|---|---|
| common（サーバー・画面の共通部品）と internaldesign/詳細設計/common.md | 変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |
| common.constant（Enum） | 新しい Enum のファイルを足すだけなら、機能の作業の中で足してよい（足したことを相手に伝える）。すでにある Enum を変えるときは、common と同じく2人で相談する |
| routes.tsx、共通ヘッダーのメニュー | 1行足すだけにする。ぶつかったら人が手で直す |
| Flyway のファイル（Server の src/main/resources/db/migration。テーブルを作る・変えるSQL） | テーブルは ZPOP-122 で全部作る。あとから足すときは、先に相手に伝える（2人が同じ版の番号を使うと、Flyway がエラーで止まるため） |
| Server の build.gradle・settings.gradle、Client の package.json | ライブラリを足すときは、2人で合意してから（3章） |
| Document の .claude/skills/（4.4） | 決まりと同じ扱い。変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |

**取り込む前と後**

- 取り込む前に、人が最新の main を自分の作業に合わせたら、Claude Codeは6章のテストをすべて動かす。
- main に取り込んだあとも、6章のテストをすべて動かす。
- 取り込みの依頼（プルリクエスト）は、もう1人が確認する。
