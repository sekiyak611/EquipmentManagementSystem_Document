# 詳細設計：ログイン（api.auth）

| 項目 | 内容 |
|---|---|
| 版 | v2.1 2026-11-15 |
| Jira | ZPOP-55（A-01）、ZPOP-56（A-02）、ZPOP-57（A-03）、ZPOP-103（S-01）、ZPOP-124（アカウントロック） |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.0 の4章（F-01・F-02）・8章、API設計.md v1.1 の2.2・3.1・4.1・4.2・7章、画面設計.md v1.1 の1・2章、データ設計.md v1.0 の5.1〜5.4、基本設計書.md v1.1 の5章 |

## 1. 概要

写したもと：機能一覧.md v1.0 の4章（F-01・F-02）

F-01：メールアドレスとパスワードでログインする。「ログインしたままにする」にチェックすると、60日間ログインしたままになる（ログアウト、パスワードの変更・再設定で解除）。5回続けてパスワードを間違えるとロックし、パスワード再設定でしか解除できない（6章の12）。ログイン後は、「備品一覧を見る」を持つ人には備品一覧（F-05）を、持たない人には「自分の備品」画面（5章）を表示する。

F-02：ログアウト。

**今回作る範囲（ログインの最小限）**：A-01・A-02・A-03・S-01 と、共通ヘッダーの氏名とログアウト。次のものは、それぞれのタスクで作る。

| 作らないもの | タスク | 今回の動き |
|---|---|---|
| ログインしたままにする（60日間） | ZPOP-125 | rememberMe は受け取るが使わない。画面のチェックも送るだけ |
| アカウントロック（失敗の回数を数える、ロックする、DM） | ZPOP-124 | **作成済み（ZPOP-124）**。A-01 が、パスワードを間違えた回数を数え、5回続けたらロックして DM（③）を送る（A-01 の 4.1）。ロックの解除（パスワードの再設定）は A-06 |
| パスワード設定・再設定・変更（A-04〜A-07、S-02〜S-04） | ZPOP-58〜61、104〜106 | 画面の「パスワードを忘れた方はこちら」は置くが、移る先（S-02）はまだない |

### 1.1 API一覧

写したもと：API設計.md v1.1 の3.1

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | 詳細設計 |
|---|---|---|---|---|---|---|
| A-01 | POST | /api/auth/login | ログインする | なし | S-01 | [A-01_ログイン.md](A-01_ログイン.md) |
| A-02 | POST | /api/auth/logout | ログアウトする | ログイン | 共通ヘッダー | [A-02_ログアウト.md](A-02_ログアウト.md) |
| A-03 | GET | /api/auth/me | ログインしている人の情報と権限項目を返す | ログイン | 全画面（メニューやボタンの出し分けに使う） | [A-03_ログイン中の人の情報.md](A-03_ログイン中の人の情報.md) |

### 1.2 画面一覧

写したもと：画面一覧.md v1.0 の2章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-01 | ログイン | /login | だれでも（ログイン前） | はい | [S-01_ログイン.md](S-01_ログイン.md) |

### 1.3 業務のルール

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | ログインできないときは、理由（メールアドレスかパスワードが違う、削除されたユーザ、ロック中）にかかわらず、同じ返し方・同じ文「メールアドレスまたはパスワードが違います」にする（他人が登録の有無を調べられないように） | API設計 4.1、画面設計 2章 |
| R-2 | ロック中のユーザは、正しいパスワードでもログインできない | 画面設計 2章・2.1 |
| R-3 | APIを呼ぶたびに、サーバーがログインしている人の権限項目を確かめる。権限の変更は次の操作から効く（ログインし直さなくてよい） | API設計 2.2、機能一覧 8章の7、画面設計 20章 |
| R-4 | APIを呼ぶたびに、ログインした日時が users.session_valid_after より前なら、ログアウトさせる | API設計 2.2、データ設計 5.1 |
| R-5 | ログイン後は、「備品一覧を見る」（EQUIPMENT_VIEW）を持つ人には備品一覧（S-07）を、持たない人には自分の備品（S-05）を出す（A-03 の homePage） | 機能一覧 F-01、API設計 4.2 |
| R-6 | メールアドレスは小文字にそろえて扱う（「Yamada@…」と「yamada@…」は同じ人） | データ設計 8章の決めたこと1 |
| R-7 | パスワードは bcrypt（元に戻せない形に変換する計算方法）で保存されたものと照らし合わせる | 基本設計書 5章 |
| R-8 | ログインの成功・失敗、ログアウトをログに残す。パスワードは残さない | API設計 7章 |

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。

### 2.1 Server

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| api.auth.login.controller | AuthLoginController・AuthLoginRestInDto | A-01 の入口と、受け取る値（形式のチェック） | A-01 |
| api.auth.login.service | AuthLoginService（インターフェース）・AuthLoginServiceImpl・AuthLoginServiceInDto | A-01 の業務の処理。メールアドレスでユーザを読み、Validator に渡す。返す値は common.security.LoginUserInfoAssembler で作る | A-01 |
| api.auth.login.service | AuthLoginFailureRecorder・AuthLoginLockNotifier | パスワードを間違えた回数を数える・ロックする・リンクを作る（`@Transactional`）／ロックしたときのDM（③）を作って送る（ZPOP-124。A-01 の 4.1） | A-01 |
| api.auth.login.validator | AuthLoginValidator・AuthLoginValidatorDto | パスワードの照らし合わせ・ロック（R-1・R-2・R-7）。読んだユーザが要るので Validator。守れなければ UnauthorizedException | A-01 |
| api.auth.login.model | AuthLoginRestOutDto | A-01 で返す値（API設計 4.2 の形） | A-01 |
| api.auth.logout.controller | AuthLogoutController | A-02 の入口。Service はなく、LoginSession を直接呼ぶ（CLAUDE.md 5章の例外）。受け取る値・返す値もない | A-02 |
| api.auth.me.controller | AuthMeController | A-03 の入口 | A-03 |
| api.auth.me.service | AuthMeService（インターフェース）・AuthMeServiceImpl・AuthMeServiceInDto | A-03 の業務の処理。返す値は common.security.LoginUserInfoAssembler で作る | A-03 |
| api.auth.me.model | AuthMeRestOutDto | A-03 で返す値（API設計 4.2 の形） | A-03 |
| common.security | LoginUserInfoAssembler・LoginUserInfo | ユーザの行から、ログインしている人の情報と権限項目を作る（A-01・A-03 で使うので common。2026-11-15 に決めた） | A-01・A-03 |
| common.security | LoginUserRefresherImpl | LoginUserRefresher の中身。APIを呼ぶたびの権限項目の読み直し（R-3・R-4）。API でない処理なので common（2026-11-15 に auth から移した） | 全API |
| dao.mapper.custom | UserCustomMapper#incrementFailedLoginCount | 失敗の回数を1増やす（`+ 1`。Example では書けない。ZPOP-124） | A-01 |
| dao.mapper・dao.entity | UserMapper・RoleMapper・RolePermissionMapper・PermissionMapper・PasswordTokenMapper と、テーブルの形・Example | users・roles・role_permissions・permissions を読む（MyBatis Generator が作ったもの） | A-01・A-03、全API |
| （テスト）api.auth.login・api.auth.logout・api.auth.me | AuthLoginApiTest・AuthLogoutApiTest・AuthMeApiTest | A-01・A-02・A-03 のテスト（API 1本に1つ） | A-01〜A-03 |
| （テスト）common.security | LoginUserRefresherApiTest | APIを呼ぶたびの読み直しのテスト | 全API |
| （テスト）testsupport | AuthApiTestBase | 上のテストで共通に使う値と道具（開発用のユーザ、ログインしてセッションを受け取る、など） | |

### 2.2 Client

| ファイル | 役割 | 使う画面 |
|---|---|---|
| src/features/auth/pages/LoginPage.tsx | ログイン画面 | S-01 |
| src/features/auth/components/PasswordField.tsx | 目のマークで文字を表示できるパスワードの入力欄（S-03・S-04 でも使う） | S-01 |
| src/features/auth/api.ts | A-01 の呼び出し（login） | S-01 |
| src/features/auth/types.ts | AuthLoginRestInDto | S-01 |
| src/common/auth/（common.md 11.9） | ログイン中の人（A-03）を持つ部品、ログインが要る画面の守り、A-02 の呼び出し | 全画面 |
| src/common/components/Header.tsx（変更） | ログイン中の人の氏名と、押すと出る「ログアウト」 | 全画面 |
| src/routes.tsx（変更） | /login と、ログインが要る画面のまとまり | |
| tests/auth/login.spec.ts | 画面のテスト | S-01 |

### 2.3 足す Enum（common.constant）

| Enum | 値 | 意味（設計書の言葉） | 使う所 |
|---|---|---|---|
| PermissionCode | EQUIPMENT_VIEW ほか18個（データ設計 5.3 のコード） | 権限項目のコード | homePage の判断。各機能の @PreAuthorize の文字と同じ |
| HomePage | EQUIPMENT_LIST、MY_EQUIPMENT | ログインしたあと最初に出す画面（S-07・S-05） | common.security.LoginUserInfo、AuthLoginRestOutDto・AuthMeRestOutDto |

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.security.LoginSession（今回足す。common.md 3.10） | ログインを始める（セッションを作り直し、ログイン状態を入れる）・終える |
| common.security.LoginUser（今回足す） | セッションに入れる「ログインしている人」（ユーザID・ログインした日時） |
| common.security.LoginUserRefresher（今回足す） | APIを呼ぶたびに権限項目を読み直すための約束（インターフェース）。中身は同じ common.security の LoginUserRefresherImpl |
| common.error.UnauthorizedException（今回足す） | 401 と文を返す |
| common.error.ApiResponse | 成功の返す値を ok で包む |
| common.passwordlink.PasswordLinkIssuer・IssuedPasswordLink（ZPOP-124。common.md 3.14） | ロックしたときの、パスワード設定用のリンク（用途 LOCK）を作る |
| common.slack.SlackSender（ZPOP-123。common.md 3.13） | ロックのDM（③）を送る |

## 3. ほかの機能への影響

| No. | 種類 | 内容 | 相手（機能・部品） | 対応 |
|---|---|---|---|---|
| 1 | common に足す | LoginUser・LoginUserRefresher・LoginRefreshFilter・LoginSession・UnauthorizedException、PasswordEncoder（bcrypt）の部品 | common（2人で共有） | common.md 3.10・6章に書く。今回の作業の中で入れる |
| 2 | ログインしている人の取り方 | ほかの機能の controller は `@AuthenticationPrincipal LoginUserId user` で、ログインしている人のユーザID（user.getUserId()）を取る | すべての機能 | common.md 3.10 |
| 3 | 権限項目の読み直し | APIを呼ぶたびに、users と role_permissions を読む SQL が2本出る | すべての API | 件数が少ない（社員数）ので、このままでよい |
| 4 | テスト用・開発用のユーザ | テストと開発のデータベースに、ユーザが2人増える（common.md 4章） | テスト全部 | DatabaseMigrationTest の「ユーザは1人」の確かめを直す |
| 5 | 画面のテスト | トップ（/）がログインの要る画面になる | tests/common の画面のテスト | ログインしてから確かめるように直す |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | 開発用（dev）と自動テスト（test）のときだけ、開発用のユーザ2人（総務・一般社員）を決まったパスワードで入れる（common.md 4章） | 最初の総務の担当者はパスワードが空で、パスワード再設定ができるまで画面からログインできないため | はい（開発のときだけ） | 済（2026-11-08） |
| 2 | ログアウト（A-02）とヘッダーのログアウトを、このタスクで一緒に作る | 別のユーザで試すときに、クッキーを消さずに済むように | はい | 済（2026-11-08） |
| 3 | mapper を、テーブルごとの `<テーブルの名前>Mapper`（UserMapper・RoleMapper・RolePermissionMapper・PermissionMapper）にした。v1.0 では AuthMapper の1つだった | 2026-11-10 に、命名規則を `<テーブルの名前>Mapper` のままにし、部品の名前をパッケージ込みにする（common.config.MyBatisConfig）と決めたため | いいえ | 済（2026-11-10） |
| 4 | 権限項目の読み直しで、削除されたユーザは、セッションを捨ててログアウトさせる | 削除されたユーザが、ログインしたまま使い続けられないように。API設計 2.2 は session_valid_after だけを書いているが、削除（画面設計 17章「削除すると、この人はログインできなくなります」）も同じ扱いにした | はい | 済（2026-11-10） |
| 5 | ロック中でも、すでにログインしている人は締め出さない | 画面設計 2.1 の6（ロックしても、ログインしている端末はそのまま使える） | いいえ | ― |
| 6 | ログインを始める・終える（common.security.LoginSession）は、controller から呼ぶ（A-02 は service を通さない） | セッションは Web の仕事で、service に HttpServletRequest を渡したくないため。CLAUDE.md 5章の「controller は service を呼ぶだけ」の例外として、2026-11-10 に CLAUDE.md 5章に書いた | いいえ | 済（2026-11-10） |
| 7 | 開発用のユーザは、データベースの名前が equipment_dev・equipment_test のときだけ入れる（common.md 4章） | 本番の起動で prod の設定を付け忘れても、公開しているパスワードの総務のユーザができないように（レビューの指摘） | いいえ | 済（2026-11-10） |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-08 | 初版（ZPOP-55・56・57・103） |
| v1.1 | 2026-11-10 | 4章の判断を人が確かめた（No.3・4・6・7 を済）。No.3 は、命名規則を `<テーブルの名前>Mapper` のままにすると決めたので、AuthMapper をテーブルごとの4つの mapper に分けた（2.1） |
| v1.2 | 2026-11-10 | controller と service を API 1本に1つずつに分けた（AuthController → AuthLoginController・AuthLogoutController・AuthMeController、AuthService → AuthLoginService・AuthMeService と LoginUserRefresherImpl）。テストも API ごとに分けた（2.1。CLAUDE.md 5章の決まりの変更） |
| v2.0 | 2026-11-15 | パッケージ構成の変更で、api.auth に作り直した（2026-11-15）。クラス名・パッケージ・Mapper のメソッドを新しい形（controller・service・validator・model、dao の Mapper と Example、手で書く Mapper、common の部品）に書き換えた。外から見た動きは変わらない。2.1 のクラスの表を書き直した |
| v2.1 | 2026-11-15 | ZPOP-124：アカウントロックを作った。A-01 が、パスワードを間違えた回数を数え、5回続けたらロックし、本人にSlackのDM（画面設計 9章の③。パスワード設定用のリンク入り）を送る。パスワード設定用のリンクを作る部品（common.passwordlink）も、このタスクで作った（common.md 3.14）。1章・2章を直した |
