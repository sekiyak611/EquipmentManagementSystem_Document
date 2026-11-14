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
| internaldesign/詳細設計/ | 機能ごとの中の作り（クラス・処理の流れ・SQL）と、設計書から写した中身。1つのまとまり（4.1 の表の1行。例：api.equipment.category）に1つのフォルダを作り、機能全体・APIごと・画面ごとのファイルに分ける。書き方は internaldesign/詳細設計/README.md、テンプレートは internaldesign/詳細設計/テンプレート/。例外：共通部品は common.md、テーブルと最初のデータは テーブル.md（列の表は写さず、データ設計 5章を見る。2026-11-08 に決めた） |

- 設計書やコードの中で「docs/○○.md」と書いてある所は、上の表の同じ名前のファイルのこと（以前は1つのリポジトリの docs フォルダに置いていたため）。
- 画面設計.md とデータ設計.md は、externaldesign と internaldesign の2か所に同じものを置いている。直すときは、必ず2つとも同じに直す。

- **実装の前に、その機能の詳細設計を書く。** Documentリポジトリの internaldesign/詳細設計/<機能名>/ に、機能全体（<機能名>.md）・APIごと・画面ごとのファイルを、internaldesign/詳細設計/テンプレート/ の形で書く（すでにあれば書き足す。共通部品は common.md）。書き方は internaldesign/詳細設計/README.md。設計書の中身も写し、写した所には写したもと（ファイル・版・章）を書く。設計書を直したら、写した詳細設計も直す。実装の途中で作りを変えたら詳細設計も直し、最後にコードと食い違っていないかを確かめる。詳細設計は Document のプルリクエストに入れる（7章）。
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
| 実行環境 | 開発は各自のPC（Temurin 21、Node.js 24.12.0。MySQL 8.4.13 も PC に直接入れる。版と入れ方は docs/環境構築手順書.md 1章）。シナリオテストとリリースはAWS（Amazon Corretto 21）。AWSでは CloudFront → 内部用のALB → EC2 → RDS の形で動かす（docs/基本設計書.md 2・3章） |
| 使わないもの | Docker（開発のPCの MySQL も、PC に直接入れる。2026-11-14 に、Docker で動かす形をやめた。docs/基本設計書.md 9章）、AI機能、メール送信（お知らせはすべてSlackのDM） |

- ライブラリの版は、build.gradle と package.json に書いた版を使う。勝手に上げ下げしない。新しく足すときは、人に確かめる。
- Spring Security は、CVE-2025-22228 の修正が入った版（6.4.4・6.3.8）以降を使う。
- 使ってよいライブラリ（人が確かめ済み）
  - サーバー：Spring Boot（Web・Security・Validation）、MyBatis、Flyway（MySQL用のモジュールを含む）、MySQL Connector/J（MySQLにつなぐ部品）、Slack Java SDK、Lombok（コンストラクタやゲッターなどを、アノテーション＝`@` で始まる印で自動で作る部品）、MyBatis Generator（テーブルから Mapper・テーブルの形・Example を自動で作る道具。Example は、取得の条件を Java で組み立てる部品）
  - 画面：Vite（開発用のサーバーと、画面の組み立て）、React Router（画面の切り替え）、MUI（@mui/material と、MUIが使う @emotion/react・@emotion/styled）、Playwright
  - 使わないと決めたもの：TanStack Query（APIの値の取り込みと保持）、React Hook Form（入力欄の管理）
- Java の `record`（値を入れるだけのクラスを短く書く書き方）は使わない。値の入れ物のクラスは、普通のクラスに Lombok のアノテーション（`@Getter`、`@AllArgsConstructor` など）を付けて作る。Lombok のアノテーションは、読みやすくなるなら、どのクラスでも使ってよい（2026-11-15 に決めた）。
- Eclipse で Lombok を使うには、各自の Eclipse に Lombok を入れる（手順は docs/環境構築手順書.md）。

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

パッケージ名の頭は `jp.co.highjunk.equipment`（2026-11-15 に、機能ごとの分け方から、1つの API に1つのパッケージの形に変えた）。

| パッケージ | 受け持つもの |
|---|---|
| api | API。1つの API に1つのパッケージ（一覧は Document の internaldesign/パッケージ構成変更/API_パッケージとクラス名_決定版.md。のちに API設計.md か詳細設計に移す） |
| api.auth | A-01〜A-07（ログイン・パスワード） |
| api.health | A-08 |
| api.equipment.mine | B-01〜B-05（自分の備品。社員向け） |
| api.equipment.management | C-01〜C-08、D-01〜D-03、E-01・E-02、I-02・I-03（備品・貸出履歴・確認の一括更新・取込。総務向け） |
| api.equipment.reminder | E-03・E-04（催促履歴） |
| api.equipment.category | K-01〜K-04 |
| api.user | G-01〜G-07、I-01 |
| api.role | H-01〜H-06 |
| batch.reminder | Slack 催促の定期実行（API ではない処理） |
| dao.mapper | MyBatis Generator が作る Mapper（テーブルごとに1つ）。全 API で共通 |
| dao.mapper.custom | 自動で作れない SQL を書く、手で書く Mapper（テーブルごとに1つ。例：EquipmentCustomMapper） |
| dao.entity.custom | 手で書く Mapper の結果の形のうち、テーブルの1行でないもの（例：種別ごとの備品の数 CategoryEquipmentCount。2026-11-15 に決めた） |
| dao.entity | MyBatis Generator が作る、テーブルの1行の形と Example（取得条件の Criteria＝「削除されていない」などの条件を1つずつ足していく部品） |
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
| common.validation | 自作のチェック用アノテーション（ServiceInDto に付け、DB との整合性や Enum を確かめるもの。例：種別があるか）と、その中身（ConstraintValidator）。1つの API でしか使わないものも、ここに置く（2026-11-15 に決めた。API のパッケージどうしは使い合わないため）。ServiceInDto を確かめて例外に変える ServiceInDtoChecker と、確かめる順番（ServiceCheckOrder）・返し方の印（ServiceErrorType）もここ |
| common.text | 画面から受け取った文字の直し方（前後の空白を取る、大文字にするなど。TextInputs）。RestInDto が、形式のチェックの前に使う（2026-11-15 に決めた） |

- 2つ以上の API で使う処理と、API でない処理（例：ログインしている人の情報を返す値に組み立てる処理、アカウントロック、パスワードの決まり、ログイン中の人の情報を読み直す処理）は、common に置く。API のパッケージどうしは使い合わないため（5章）。パッケージの名前は、その処理を作り直すときに決め、上の表に足す（2026-11-15 に決めた）。
- パッケージ名は英小文字だけ。言葉はつなげて書く（例：`itemformanager`）。`import` は Java の予約語（Java が使うので名前にできない言葉）なので、取込は `importer` にする。
- 1つの API のパッケージの中を、controller・service・validator・model のパッケージに分け、次のクラスを置く（2026-11-15 に決め直した）。クラス名の頭（以下 `<頭>`）は、パッケージの `api` より後ろを全部つなげ、言葉の頭を大文字にしたもの（例：`api.equipment.management.search.item` → `EquipmentManagementSearchItem`）。

| クラス | 役割 |
|---|---|
| `controller.<頭>Controller` | API の入口。受け取る・Service を呼ぶ・返すだけ |
| `service.<頭>Service` | 業務の処理の interface（インターフェース＝メソッドの名前・受け取る値・返す値だけを決めた型） |
| `service.<頭>ServiceImpl` | 業務の処理の中身 |
| `controller.<頭>RestInDto` | 画面から受け取る値。形式のチェック（必須、文字数、形）をアノテーションで書く |
| `service.<頭>ServiceInDto` | Service に渡す値。Controller が、RestInDto・パスの値・ログインしている人の ID から作る。DB との整合性（重複、存在するか、使われているか）と Enum のチェックを、自作のチェック用アノテーション（common.validation）で書く |
| `model.<頭>RestOutDto` | 画面に返す値（この名前は、あとで変わるかもしれない。2026-11-15） |
| `validator.<頭>ValidatorDto` | Validatorに渡す値。ServiceImplの値をセットする |
| `validator.<頭>Validator` | 業務チェックをするためのクラス。 |

- 受け取る値・業務チェック・返す値がない API では、そのクラス（とパッケージ）は作らない（例：K-01 は受け取る値がないので RestInDto・ServiceInDto を作らない。K-04 は返す値がないので RestOutDto と model を作らない。種別の API は業務チェックがないので validator を作らない）。

```
jp.co.highjunk.equipment
├─ api
│  └─ equipment
│     └─ category
│        └─ update
│           └─ item          K-03（種別を変える）
│              ├─ controller/  EquipmentCategoryUpdateItemController、EquipmentCategoryUpdateItemRestInDto
│              ├─ service/     EquipmentCategoryUpdateItemService、EquipmentCategoryUpdateItemServiceImpl、
│              │               EquipmentCategoryUpdateItemServiceInDto
│              ├─ model/       EquipmentCategoryUpdateItemRestOutDto
│              └─ validator/   （業務チェックがある API だけ）<頭>Validator、<頭>ValidatorDto
├─ batch
│  └─ reminder/
├─ dao
│  ├─ mapper/          MyBatis Generator が作る Mapper
│  │  └─ custom/       手で書く Mapper
│  └─ entity/          テーブルの1行の形と Example
└─ common/
   └─ constant/        Enum（例：EquipmentStatus）
```

- MyBatis の XML は、`src/main/resources/jp/co/highjunk/equipment/dao/mapper/` に置く（MyBatis Generator が作る）。手で書く Mapper の XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/` に置く。
- Enum は、api・dao の中に作らない。1つの API でしか使わない Enum も common.constant に置く（同じ値の Enum が2つできるのを防ぐため）。
- テストは、本体と同じパッケージ名で `src/test/java` に置く（API のテストは、その API のパッケージ。controller などの下ではなく、その上。例：`jp.co.highjunk.equipment.api.equipment.category.search.item`）。
- **作り直しの途中の注意（2026-11-15〜）**：今のコード（auth・equipment・health のパッケージと、mapper・dto の下のパッケージ。category は 2026-11-15 に api.equipment.category に作り直した）は、まだ古い形（機能ごとのパッケージ、validator、…Request・…Response）のまま残っている。古い形のコードは手本にしない。新しく作るコードは、この 4.1 の形にする。全部を作り直したら、この行を消す。

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
│  └─ features/           サーバーの api と同じまとまり
│     ├─ auth/            S-01〜S-04
│     ├─ equipment/
│     │  ├─ mine/         S-05、S-06
│     │  ├─ management/   S-07〜S-11
│     │  ├─ reminder/     S-12
│     │  └─ category/     S-13
│     ├─ user/            S-14、S-15
│     ├─ role/            S-16、S-17
│     └─ importer/        S-18（1つの画面のまま置くか、画面を分けるかは未定。フォルダを移すまでに決める）
└─ tests/                 Playwrightのテスト（features と同じ形のフォルダに分ける）
```

- tests/ のフォルダも、features と同じ形に分ける。
- **移す途中の注意（2026-11-15〜）**：今の features/ と tests/ は、まだ古い形（auth・mine・equipment・loan・confirmation・reminder・category・user・role・importer）のまま。新しいまとまりに移すまでに新しい画面を作るときは、どちらに置くかを人に確かめる。移し終えたら、この行を消す。

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
| deliver-zip | 最後のテスト、証跡、ブランチ・commit・push・プルリクエスト（7章。skill の中身は zip のときのままで、直すまでは 7章が正しい） |
| reverse-engineer | コードから詳細設計を書き起こし、設計書との食い違いを一覧にする（設計書は直さない） |
| implementation-guidelines | 実装・テスト・レビューのときの一般的な心得（読みやすさ、例外、型など）。この CLAUDE.md にない所で使う |
| env-setup | 開発環境を作る・確かめる（Windows のPC） |

1つのストーリー（Jira の課題。API 1本、画面1つ、仕組み1つ）は、人が次の順に skill を呼んで進める。ストーリーの4つのサブタスクとの対応は、detailed-design が［詳細設計］、backend-impl・frontend-impl が［実装］、backend-test が［単体テスト］と［結合テスト］、frontend-test が画面の［結合テスト］（実装タスク一覧.md 0.1）。レビューとプルリクエストづくりはサブタスクにしていない。skill どうしは自動でつながない（人がそれぞれの終わりに結果を確かめるため）。

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
- 秘密の情報（Slackのトークン、データベースのパスワード、最初の総務の担当者のメールアドレスなど）は、プログラムや設定ファイルに書かない。開発では、Gitで管理しない Server の `secret.yml` に書く（書き方の見本は Server の `secret.example.yml`）。MySQL の root と `equipment` のパスワードは、PC の MySQL の中にだけある（手順は docs/環境構築手順書.md）。AWSでは環境変数で渡す。
- ログに、パスワード、パスワード設定用のリンクの合言葉、Slackのトークンを出さない（docs/API設計.md 7章）。
- 変えられる値（時刻、期限、回数など）は、プログラムに直接書かず設定にする（docs/API設計.md 6章）。
- テスト用の切り替え（Slackの偽物、送った内容を読み出すAPI）は、本番の設定で動かないようにする。

**サーバー（Java）**
- パッケージは 4.1 のとおり、1つの API に1つ。業務のルールは ServiceImpl に書き、Controller には書かない（2026-11-15 に決めた）。
- Controller には、その API の URL と操作を1つだけ書く。
- Controller は、RestInDto・パスの値・ログインしている人の ID から ServiceInDto を作り、Service に渡す（2026-11-15 に決めた）。Service は、受け取る値を ServiceInDto だけにする（RestInDto やパスの値をそのまま受け取らない）。受け取る値がない API（例：一覧で条件がないもの）は、ServiceInDto を作らない。
- Service は、interface の `<頭>Service` と、中身の `<頭>ServiceImpl`（`implements <頭>Service`）に分け、どちらも service のパッケージに置く。`@Service` は ServiceImpl に付ける。Controller は、自分の API の Service の interface を受け取って使い、ServiceImpl を直接使わない。
- API のパッケージは、ほかの API のパッケージのクラスを使わない（同じまとまりの API どうしも同じ）。使ってよいのは、`common` と `dao` だけ。`batch` も同じで、使ってよいのは `common` と `dao` だけ（api と batch は互いに使わない）。`common` と `dao` から `api`・`batch` を使わない。循環（AがBを使い、BもAを使う形）を作らない。
- 2つ以上の API で使う処理と、API でない処理は、common に置く（4.1）。API でない処理のクラスは、役目を表す名前にする（例：ログイン中の人の情報を読み直す LoginUserRefresher）。
- 確かめることは、次の3つに分ける。
  - RestInDto：画面設計のとおりの形式のチェック（受け取った値だけで分かるもの。必須、文字数、形式、数の範囲など）。`@NotBlank`・`@Size` などのアノテーションで書き、Controller の引数に `@Valid` を付けて確かめる（Bean Validation＝アノテーションで値を確かめる仕組み）。
  - ServiceInDto：DB との整合性と Enum のチェック（例：同じ名前の種別がもうある、使われている種別は消せない、すでに貸し出されている、その人が操作してよい対象か）。自作のチェック用アノテーション（`ConstraintValidator`＝自作のチェックの中身を書くための Bean Validation の仕組み。Mapper を読める）で書き、common.validation に置く（4.1）。新しく足すときは、common の変更として2人で相談する（9章）。ServiceImpl の `@Transactional` の中で、Bean Validation で確かめる（確かめてから書き換えるまでを1つのまとまりにするため）。受け取った値だけで、DB と照らせば確かめられるもの（ある・重なる・version・使われている・Enum など）はここに書く。
  - ServiceInDto のチェックは、読むだけにする（Mapper の取得・数える処理だけを使う）。書き換えは ServiceImpl で行う。
  - Validator：業務チェックのうち、ServiceImpl が読んだ・計算した値が要るもの（例：貸出の期間の重なり、その人が借りている備品か。2026-11-15 に決めた）。`validator.<頭>Validator`（`@Component`）に書き、ServiceImpl が `validator.<頭>ValidatorDto` に値を入れて、`@Transactional` の中で、書き換えの前に呼ぶ。守れなければ、その場で common.error の例外（NotFoundException・ConflictException・BusinessRuleException・FieldErrorException など）を投げる。読むだけ（Mapper の取得・数える処理だけ）で、書き換えない。Controller からは呼ばない。業務チェックがない API では作らない。
  - チェックのメッセージは、画面設計の文のまま。守れないときに返す状態コード（404・409・422 など）と文は、API設計とその API の詳細設計のとおり。ServiceInDto のチェックからの返し方は、次のとおり（2026-11-15 に決めた。お手本は api.equipment.category）。
    - ServiceImpl は、`@Transactional` のメソッドの中で、書き換えの前に `common.validation.ServiceInDtoChecker#check(ServiceInDto)` を呼ぶ。
    - 確かめる順番は、チェック用アノテーションの groups で決める：`ServiceCheckOrder.First`（対象があるか）→ `ServiceCheckOrder.Second`（対象の今の状態と合うか。version、使われているか など）→ groups なし（そのほか。重なり など）。ある段で守れないものがあれば、そこで止める。
    - 返し方は、チェック用アノテーションの payload で決める：`ServiceErrorType.NotFound`（404。NotFoundException）、`ServiceErrorType.Conflict`（409。ConflictException。文はアノテーションの message）、`ServiceErrorType.BusinessRule`（400。BusinessRuleException。errors なし）、payload なし（400。FieldErrorException。errors に入力欄ごとの文。並び順は ServiceInDto の項目の順）。
    - クラスに付けるチェック（2つ以上の項目を見るもの。例：version が同じか、自分を除いて名前が重ならないか）は、アノテーションの中の Target という interface を ServiceInDto が実装して、値を渡す。入力欄のエラーにするときは、誤りを入力欄（項目の名前）に付ける。
- DB の読み書きは、`dao.mapper` の Mapper で行う。取得の条件は、`dao.entity` の Example の Criteria で組み立てる（例：`example.createCriteria().andDeletedAtIsNull()`）。
- MyBatis Generator が作ったファイル（`dao.mapper`・`dao.entity` と、その XML）は手で直さない。テーブルが変わったら作り直す。自動で作れない SQL（件数をまとめる SQL など）は、手で書く Mapper を `dao.mapper.custom` に置く（XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/`）。手で書く Mapper は、自動で作り直しても消えない。
- Controller は、Web のセッションを扱う common.security.LoginSession（ログインの開始・終了）だけは、Service を通さずに呼んでよい。業務のルールとデータベースの読み書きは、これまでどおり Service に書く（2026-11-10 に決めた例外。Service に HttpServletRequest を渡さないため。詳細設計 common.md 3.10）。
- 2つ以上の API で使う業務のルール（4.1の common.calendar・common.passwordlink など）は、common に1つだけ置き、書き写さない。
- API をまたいで同じルールが書かれている所（貸出のルール：equipment.mine・equipment.management（取込を含む）、確認のルール：equipment.mine・equipment.management）は、1か所を直したらほかも同じように直し、テストも直す。
- SQLで JOIN とサブクエリ（SQLの中にもう1つSQLを入れる書き方）を使わない。複数のテーブルの情報は、テーブルごとにSQLを出し、Javaで突き合わせる。
- 1件ずつSQLを出さない（N+1問題＝一覧の件数だけSQLが出てしまう問題を防ぐ）。IDをまとめて集め、`IN`（Example の `andIdIn`、手で書く XML なら `<foreach>`）で1回で読む。
- 今の日時は、直接取らずに java.time.Clock から取る（テストで日時を止められるようにするため）。
- APIごとに、必要な権限項目をサーバー側で必ず確かめる（例：@PreAuthorize("hasAuthority('EQUIPMENT_UPDATE')")）。権限項目のコードは docs/データ設計.md の5.3。
- 画面設計に書かれたチェック（形式のチェックと DB との整合性のチェック）は、サーバー側でも必ず行う。画面側のチェックだけに頼らない。
- 編集するAPIは、楽観ロック（version 列）で、ほかの人が先に保存していたら 409 を返す。
- SQLは MyBatis の XML に書く（MyBatis Generator が作るものと、dao.mapper.custom に手で書くもの）。値は必ずパラメータ（#{}）で渡し、文字をつなげてSQLを作らない（SQLインジェクション＝外から入れた文字でデータベースを操られる攻撃を防ぐため）。
- 削除は論理削除（deleted_at）。一覧や検索では、削除済みの行を出さない。
- 2つ以上の書き換え（INSERT・UPDATE・DELETE）を1つの操作として行う処理は、ServiceImpl のメソッドに `@Transactional` を付け、途中で失敗したら全部を元に戻す。Controller・Mapper と、interface の `<頭>Service` には付けない。
- Slack の送信は、`@Transactional` の中で行わない。データベースへの書き込みが確定してから送る（送ったのにデータベースは元に戻った、を防ぐため）。送るのに失敗したときの扱いは、その機能の設計書・詳細設計に従う。
- 操作する対象（備品・貸出など）の ID を画面から受け取る API は、権限項目の確認に加えて、その人が操作してよい対象かを ServiceInDto のチェックか Validator で確かめる（受け取った値だけで確かめられるなら ServiceInDto、ServiceImpl が読んだ値が要るなら Validator）（例：B-03 の返す・B-04 の確認したは、ログインしている人が借りている備品だけを対象にする。B-04 は docs/API設計.md 4.7 のとおり、ほかの人の備品が含まれていたら 403）。ID を書き換えて他人のデータを読む・変えることを防ぐため（IDOR と呼ばれる穴）。

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
| `<頭>`（API のクラス名の頭） | パッケージの `api` より後ろを全部つなげ、言葉の頭を大文字にしたもの（4.1。API ごとの一覧は Document の internaldesign/パッケージ構成変更/API_パッケージとクラス名_決定版.md） | EquipmentCategorySearchItem（K-01）、AuthLogin（A-01）、Health（A-08） |
| Controller | `<頭>Controller`（API 1本に1つ） | EquipmentCategorySearchItemController、AuthLoginController |
| Service | interface は `<頭>Service`、中身は `<頭>ServiceImpl`（API 1本に1つ） | EquipmentCategorySearchItemService、EquipmentCategorySearchItemServiceImpl |
| 受け取る値 | 画面から受け取る値は `controller.<頭>RestInDto`、Service に渡す値は `service.<頭>ServiceInDto` | EquipmentCategoryEntryItemRestInDto、EquipmentCategoryEntryItemServiceInDto |
| 業務チェック | `validator.<頭>Validator` と、渡す値の `validator.<頭>ValidatorDto`（業務チェックがある API だけ） | （例）EquipmentMineEntryItemValidator、EquipmentMineEntryItemValidatorDto |
| 返す値 | `model.<頭>RestOutDto`（あとで変わるかもしれない。2026-11-15） | EquipmentCategorySearchItemRestOutDto |
| テーブルの形・Mapper・Example | MyBatis Generator が作る。テーブルの形はテーブルの名前の単数形（Server の mybatis-generator/generatorConfig.xml で指定する。2026-11-15 に決めた）、Mapper は `<テーブルの形>Mapper`、Example は `<テーブルの形>Example`。Mapper のメソッドの名前も MyBatis Generator のまま（`selectByExample`・`selectByPrimaryKey`・`countByExample`・`insert`・`updateByPrimaryKey` など）。手で書く Mapper（dao.mapper.custom）は `<テーブルの形>CustomMapper`（テーブルごとに1つ）。その結果の形でテーブルの1行でないものは、dao.entity.custom に中身が分かる名前で置く（2026-11-15 に決めた） | Category・CategoryMapper・CategoryExample（categories）、Equipment（equipment）、RolePermission（role_permissions）、EquipmentCustomMapper、CategoryEquipmentCount |
| チェック用アノテーション（common.validation） | 確かめることを表す名前（例：`<対象><状態>`）。中身（ConstraintValidator）は `<アノテーションの名前>Check`（API の `<頭>Validator` と区別するため。2026-11-15 に決めた） | CategoryExists・CategoryExistsCheck、CategoryNameNotDuplicated、CategoryNotInUse |
| Enum | 意味を表す名前。値は大文字と「_」で、API設計・データ設計の値と同じ文字 | EquipmentStatus.MANAGED（データ設計の管理状態 MANAGED） |
| テスト（Server） | API のテストは `<頭>ApiTest`（API 1本に1つ）、単体テストは `<テストするクラス>Test`。テストで共通に使う値と道具は、testsupport に、まとまりごとの基底クラス `<まとまりの名前>ApiTestBase`（public abstract）として置き、各 API のテストが継ぐ（API ごとにパッケージが分かれるため。2026-11-15 に決めた） | EquipmentCategorySearchItemApiTest、AuthLoginApiTest、ReminderDateCalculatorTest、testsupport.EquipmentCategoryApiTestBase |
| 画面（Client） | 画面は `…Page.tsx`、部品は役目を表す名前の `.tsx`（どちらも PascalCase） | CategoryListPage.tsx、CategoryForm.tsx |
| api.ts の関数 | 読む：`get…`、足す：`create…`、変える：`update…`、消す：`delete…`（camelCase＝最初の単語だけ小文字） | getCategories、createCategory |
| types.ts の型 | Server の dto と同じ名前 | CategoryResponse |
| テスト（Client） | `tests/<機能名>/<画面を表す名前>.spec.ts`（小文字と「-」） | tests/category/category-list.spec.ts |
| 変数・メソッド・関数 | camelCase。定数は大文字と「_」 | lentOn、SUCCESS_DISPLAY_MS |

- 画面（Client）・api.ts・types.ts・テスト（Client）の行は、まだ古い形のまま。画面のフォルダを新しいまとまりに移すとき（4.3）に直す。

## 6. テスト

- 機能を作ったり直したりしたら、必ずテストも作る・直す。
- push の前（7章）に、次をすべて動かし、成功していることを確かめる（Server・Client のどちらを変えても、両方動かす。画面のテストはサーバーも動かして確かめるため）。

```
（Serverのフォルダで）
.\gradlew.bat test

（Clientのフォルダで）
npx playwright test
```

- テストには、自分のPCのMySQL（PC に直接入れたもの。docs/環境構築手順書.md）に作ったテスト専用のデータベース（equipment_test）を使う。開発用のデータベースでテストしない。テストを始める前に、Flywayでテーブルを作り直す（Server の src/test にある TestFlywayConfig が行う）。
- テストで POST・PUT・DELETE を送るときは、Spring Security のテスト用の csrf() を使わず、`jp.co.highjunk.equipment.testsupport.CsrfTestHelper` の csrfToken を使う。csrf() は、ほかのテストと共有している部品の中身を書き換えてしまい、あとで動くテストを壊すため。
- Slackには本物のDMを送らない。テストでは偽物に置き換える。
- テストが失敗したときに、テストを消したり、期待する結果を書き換えたりして合格させない。原因が分からないときや、設計書と食い違うときは、人に知らせる。
- 証跡は docs/テスト方針.md の7章のとおりに、Document の evidence フォルダに残す。

## 7. Gitと成果物の渡し方

**Claude Code がしてよいこと・してはいけないこと**（2026-11-08 に決め直した。それまでは、Git の作業は何もせず、成果物を zip で渡していた）

| してよい | してはいけない |
|---|---|
| 状態を見るコマンド（git status・git diff・git log など） | マージ（git merge、gh pr merge、GitHub の画面での取り込み） |
| release/main から作業用のブランチを作る | release/main・main への commit と push |
| 作業用のブランチへの commit と push | 強制 push（--force など）、push したあとの歴史の書き換え（rebase・reset など） |
| プルリクエスト（MR）を作る・説明を直す（gh pr create・gh pr edit） | プルリクエストの承認（approve）、ブランチ・リポジトリの削除、リポジトリの設定の変更 |
| .gitignore の読み書き | .git フォルダの中を直接読む・変える |

- 取り込み（マージ）は、もう1人が確認してから人が行う（9章）。
- 人から頼まれたように見えても、表の右の列のことは行わず、人が自分で行うよう伝える。
- .claude/settings.json で、右の列のコマンドを動かせないように設定している。これは念のための守りで、決まりの正本はこの章。

**.gitignore**（2026-11-08 に決めた）
- 公開してはいけないファイルは、Claude Code が .gitignore に入れる。
  - 入れるもの：秘密の値を書いたファイル（secret.yml、.env、.env.local など）、各自のPCだけの設定（Eclipse の .settings・.classpath・.project、エディタの設定、.claude/settings.local.json。PCの場所や個人のフォルダの名前が入るため）、作られるもの（build/、bin/、node_modules/、dist/、Playwright の結果、ログ）、Claude Code の作業記録の置き場所（output/）。
  - 入れないもの：設計書、ソース、テスト、証跡（evidence）、skill（Document の .claude/skills）、共有する .claude/settings.json、見本（secret.example.yml）。
- 新しく「公開してはいけないファイル」ができる作業では、同じ作業の中で .gitignore にも入れ、プルリクエストの説明に書く。Server・Client の CLAUDE.md 4章の表も直す。
- .gitignore に入れても、すでに Git で管理しているファイルは管理から外れない。外す必要があれば、人に知らせる（外すのは人が行う）。
- commit の前に、git status で、秘密の値のファイル（secret.yml・.env など）が入っていないことを必ず確かめる。

**作業のしかた**

- 1回の作業は小さくする（人が全部読んで確認するため）。目安は、Jira のストーリー1つ（実装タスク一覧.md 10章）。同じ機能の API と画面を続けて作るときに、1つにまとめるかは人が決める。
- 作業を始める前に、3つのリポジトリ（4章）とも release/main の最新を取ってきて、作業用のブランチを作る。Server と Client と Document は別のリポジトリなので、変えたリポジトリごとにブランチとプルリクエストを作る（同じ作業では、3つとも同じブランチ名にする）。
- 作業記録（作業メモ・確認してほしい点）は、Claude Code を起動したリポジトリの `output/<タスク名>/` に書きためる（4.4 の skill を別の会話から呼んでも、続きが分かるようにするため。output/ は Git で管理しない）。

**ブランチ・commit・プルリクエスト**

| もの | 決まり | 例 |
|---|---|---|
| もとにするブランチ（親ブランチ） | release/main。実装やテストは、必ず feature ブランチを作って行う。**release/main には絶対に push しない** | |
| ブランチの名前 | **必ず `feature/<名前>` の形にする**（2026-11-08 に決めたブランチの決まり）。名前は、人が一目で何の機能か分かるようにする：`<Jira の課題キー>-<英語の機能名>`（小文字と「-」。課題が2つ以上なら、いちばん小さい番号）。Jira の課題がない作業は、英語の機能名だけ | feature/ZPOP-83-category-list、feature/ZPOP-55-login-minimum、feature/git-branch-rule |
| 前の作業がまだ取り込まれていないとき | 前の作業のブランチから作り（積み重ね）、プルリクエストのもとも前の作業のブランチにする。説明に「先に #番号 を取り込む」と書く | |
| commit | 作業の区切り（実装・テスト・詳細設計など）ごとに分ける。1行目は `<課題キー> <タスク名>：何をしたか`（日本語） | ZPOP-83 K-01_種別一覧：一覧の API を作った |
| push の前 | 6章のテストをすべて動かし、成功していることを確かめる | |
| プルリクエストの名前 | `<課題キー> <タスク名>`（Jira の課題がない作業は、中身が分かる短い名前） | ZPOP-83 K-01_種別一覧 |
| プルリクエストの説明 | 下の形。人がそのまま読んで確認できるようにする | |

プルリクエストの説明の形

```
## 目的
（Jiraの課題キーと、何のための変更か）
## 変更した内容
（主な変更を箇条書き。消したファイルがあれば書く）
## もとにした設計書
（例：docs/画面設計.md 3章、docs/API設計.md B-01）
## テストの結果
（動かしたテストの件数・成功・失敗。証跡の置き場所）
## とくに確認してほしい点
（判断に迷った所、設計書にない動き、セキュリティに関わる所、2人で相談が必要な変更）
## 関係するプルリクエスト
（同じ作業のほかのリポジトリのプルリクエスト、先に取り込むプルリクエスト）
```

- 詳細設計と証跡（evidence）は、Document のプルリクエストに入れる。
- プルリクエストを作ったら、人にその場所（アドレス）を知らせる。

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

- 新しい API は、作り直した `api.equipment.category`（K-01〜K-04）を手本にして、同じ書き方で作る。詳細設計も、Document の internaldesign/詳細設計/ の、作り直した category の詳細設計を手本にする。作り直す前の古い形のコード（health など）は手本にしない（4.1 の作り直しの途中の注意）。
- 画面は、category（S-13。ZPOP-115）を手本にする。

**担当**

- 担当は機能ごとに分ける（Document の internaldesign/実装タスク一覧.md の分担、Jiraの担当者）。自分の担当でない API のパッケージ（画面は features のフォルダ）は変えない。

**2人で共有するファイル**

| ファイル | 決まり |
|---|---|
| common（サーバー・画面の共通部品）と internaldesign/詳細設計/common.md | 変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |
| common.constant（Enum） | 新しい Enum のファイルを足すだけなら、機能の作業の中で足してよい（足したことを相手に伝える）。すでにある Enum を変えるときは、common と同じく2人で相談する |
| Server の dao（MyBatis Generator の設定と、作ったファイル。dao.mapper.custom を含む） | 作り直すときは2人で相談し、その作業だけを先に main に入れる |
| routes.tsx、共通ヘッダーのメニュー | 1行足すだけにする。ぶつかったら人が手で直す |
| Flyway のファイル（Server の src/main/resources/db/migration。テーブルを作る・変えるSQL） | テーブルは ZPOP-122 で全部作る。あとから足すときは、先に相手に伝える（2人が同じ版の番号を使うと、Flyway がエラーで止まるため） |
| Server の build.gradle・settings.gradle、Client の package.json | ライブラリを足すときは、2人で合意してから（3章） |
| Document の .claude/skills/（4.4） | 決まりと同じ扱い。変えるときは2人で相談し、その変更だけの小さな作業にして、先に main に入れる |

**取り込む前と後**

- 取り込む前に、人が最新の main を自分の作業に合わせたら、Claude Codeは6章のテストをすべて動かす。
- main に取り込んだあとも、6章のテストをすべて動かす。
- 取り込みの依頼（プルリクエスト）は、もう1人が確認する。
