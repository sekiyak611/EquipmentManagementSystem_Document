# 詳細設計：備品の管理（equipment）

| 項目 | 内容 |
|---|---|
| 版 | v1.2 2026-11-11 |
| Jira | ZPOP-68（C-01）、ZPOP-70（C-03）、ZPOP-73（C-06）。C-02・C-04・C-05・C-07・C-08、S-07〜S-09 は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.0 の1章・4章（F-05〜F-07・F-09）、API設計.md v1.2 の2.3〜2.5・3.3・4.8、画面設計.md v1.3 の10〜12章、画面一覧.md v1.0 の2章・7章、データ設計.md v1.0 の2章・5.1・5.3・5.5〜5.7・6章 |

## 1. 概要

写したもと：機能一覧.md v1.0 の4章（F-05）

検索・絞り込み。管理状態・貸出状態・借用者・最終確認日を表示し、それぞれで絞り込める。今のExcelの棚卸対象（管理中で今月確認済みでないもの、不明のもの）もすぐに出せるようにする。色分けは今のExcelと同じにする（廃棄＝灰色、不明＝青色、最終確認日が未記入か先月以前＝黄色）

### 1.1 API一覧

写したもと：API設計.md v1.2 の3.3

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | 詳細設計 |
|---|---|---|---|---|---|---|
| C-01 | GET | /api/equipment | 備品を探す（絞り込み・並び替え・ページ分け） | EQUIPMENT_VIEW | S-07 | [C-01_備品を探す.md](C-01_備品を探す.md) |
| C-02 | GET | /api/equipment/{備品のID} | 備品1件と、その備品の貸出履歴（新しい順に5件）を返す | EQUIPMENT_VIEW | S-08、S-09（編集） | まだ（ZPOP-69） |
| C-03 | POST | /api/equipment | 備品を登録する | EQUIPMENT_CREATE | S-09 | [C-03_備品を登録する.md](C-03_備品を登録する.md) |
| C-04 | PUT | /api/equipment/{備品のID} | 備品を変える | EQUIPMENT_UPDATE | S-09 | まだ（ZPOP-71） |
| C-05 | DELETE | /api/equipment/{備品のID} | 備品を削除する | EQUIPMENT_DELETE | S-08 | まだ（ZPOP-72） |
| C-06 | POST | /api/equipment/{備品のID}/confirmation | 備品を「確認した」にする | CONFIRM_ALL | S-07、S-08 | [C-06_確認した.md](C-06_確認した.md) |
| C-07 | POST | /api/equipment/{備品のID}/loans | 総務が、ほかの人の貸出を登録する | LOAN_MANAGE | S-08 | まだ（ZPOP-74） |
| C-08 | POST | /api/equipment/{備品のID}/return | 総務が、返却を登録する | LOAN_MANAGE | S-08 | まだ（ZPOP-75） |

### 1.2 画面一覧

写したもと：画面一覧.md v1.0 の2章・7章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-07 | 備品一覧 | まだ決めていない | 総務（備品一覧を見る） | いいえ（PCを前提。スマートフォンではカード） | まだ（ZPOP-109） |
| S-08 | 備品詳細 | まだ決めていない | 総務 | いいえ | まだ（ZPOP-110） |
| S-09 | 備品登録・編集 | まだ決めていない | 総務 | いいえ（PCだけ） | まだ（ZPOP-111） |

### 1.3 業務のルール

写したもと：機能一覧.md v1.0 の1章、画面設計.md v1.3 の10章、データ設計.md v1.0 の2章・5.7

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 論理削除。deleted_at に値が入っている備品は出さない | データ設計 2章 |
| R-2 | 貸出中＝返却日が空で、取り消されていない貸出履歴がある | データ設計 5.7 |
| R-3 | 今月確認済み＝最終確認日の月が今月（common.calendar.MonthlyConfirmationRule。common.md 3.11） | 機能一覧 1章 |
| R-4 | 画面での検索は、大文字・小文字を区別しない | データ設計 2章 |
| R-5 | 棚卸対象＝管理中で今月確認済みでないもの＋不明のもの | 画面設計 10章 |

| R-6 | 管理番号はほかの備品と重ならない。削除済みの備品の番号は使い直せる | 画面設計 12章 |
| R-7 | 登録するときの管理状態は管理中、最終確認日は登録した日 | 機能一覧 F-06、画面設計 12章 |
| R-8 | 備品を足す・種別を変えるときは、種別の行を FOR SHARE で読む（K-04 と同時に動いても、消した種別の備品ができない） | category/category.md 3章の No.2 |

| R-9 | 「確認した」は最終確認日をその日の日付にする。確認できるのは管理中の備品だけ | 機能一覧 F-07、画面設計 10章 |
| R-10 | 保存のたびに version を1増やす（最終確認日だけを変えるときも。2026-11-11 に人が決めた） | データ設計 2章 |

C-01 で使うのは R-1〜R-5。C-03 で使うのは R-6〜R-8。C-06 で使うのは R-1〜R-3・R-9・R-10。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則。C-01・C-03・C-06 の分を書く。

### 2.1 Server

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| equipment.controller | EquipmentListController | C-01 の入口 | C-01 |
| equipment.service | EquipmentListService（インターフェース）・EquipmentListServiceImpl | C-01 の業務のルール（`@Service`。読むだけなので `@Transactional` は付けない） | C-01 |
| equipment.controller | EquipmentCreateController | C-03 の入口 | C-03 |
| equipment.service | EquipmentCreateService（インターフェース）・EquipmentCreateServiceImpl | C-03 の業務のルール（`@Service`、`@Transactional`） | C-03 |
| equipment.controller | EquipmentConfirmController | C-06 の入口 | C-06 |
| equipment.service | EquipmentConfirmService（インターフェース）・EquipmentConfirmServiceImpl | C-06 の業務のルール（`@Service`、`@Transactional`） | C-06 |
| equipment.service | EquipmentItemAssembler | 備品の行から C-01 の1件の形を作る（種別の名前・借用者の氏名を IN でまとめて読んで突き合わせる）。API の service ではないので、役目を表す名前（`@Component`） | C-01・C-06 |
| equipment.validator | EquipmentValidator | 備品の業務チェック。登録してよいか（validateCreatable。管理番号の重なり、種別、購入日・保証期日）、確認してよいか（validateConfirmable。あるか、管理中か）。2つ以上の API で使うので `<機能名>Validator` にまとめた | C-03・C-06 |
| equipment.model | Equipment | テーブル equipment の1行（C-03 ですべての列を足した） | C-01・C-03 |
| equipment.model | Loan | テーブル loans の1行（使う列だけ） | C-01 |
| equipment.model | Category | テーブル categories の1行（id・name だけ） | C-01・C-03 |
| equipment.model | User | テーブル users の1行（id・name だけ） | C-01 |
| equipment.model | EquipmentSearchCondition | 備品を探す条件（mapper に渡す。テーブルの行ではない。4章の No.1） | C-01 |
| mapper.equipment | EquipmentMapper（インターフェース）・EquipmentMapper.xml | equipment を探す・数える（C-01）、管理番号の重なりを数える・足す（C-03）、FOR UPDATE で読む・最終確認日を変える（C-06） | C-01・C-03・C-06 |
| mapper.equipment | LoanMapper・LoanMapper.xml | 貸出中の貸出履歴を読む（すべて：C-01、1つの備品：C-06） | C-01・C-06 |
| mapper.equipment | CategoryMapper・CategoryMapper.xml | 種別の名前を IN でまとめて読む（C-01）、種別を FOR SHARE で読む（C-03） | C-01・C-03 |
| mapper.equipment | UserMapper・UserMapper.xml | 氏名でユーザを探す、氏名を IN でまとめて読む | C-01 |
| dto.equipment | EquipmentListRequest | C-01 の条件（受け取った値を確かめて、探す条件にする） | C-01 |
| dto.equipment | EquipmentListResponse・EquipmentListItem | C-01 の返す値（API設計 2.5 の形と、1件の形）。EquipmentListItem は C-03・C-06 の返す値にも使う | C-01・C-03・C-06 |
| dto.equipment | EquipmentCreateRequest | C-03 で受け取る値 | C-03 |
| dto.equipment | EquipmentInputs | 文字の項目の直し方（前後の空白を取り除き、空なら null） | C-03 |
| （テスト）equipment | EquipmentListApiTest | C-01 のテスト | C-01 |
| （テスト）equipment | EquipmentCreateApiTest | C-03 のテスト | C-03 |
| （テスト）equipment | EquipmentConfirmApiTest | C-06 のテスト | C-06 |
| （テスト）equipment | EquipmentCreateLockTest | C-03 の、同時に種別を消されたときの守り（FOR SHARE）のテスト。2つのまとまりを本当に開いて確かめる | C-03 |

- XML は src/main/resources/jp/co/highjunk/equipment/mapper/equipment/ に置く。
- mapper.equipment の CategoryMapper・UserMapper・EquipmentMapper は、ほかの機能の同じ名前の mapper とは別のもの（common.md 2.3）。import するときは mapper.equipment のものを選ぶ（CLAUDE.md 5章）。

### 2.2 Client

なし（S-07〜S-09 のときに書く）

### 2.3 足す Enum（common.constant）

| Enum | 値 | 使う所 |
|---|---|---|
| EquipmentStatus | MANAGED（管理中）・DISPOSED（廃棄）・MISSING（不明） | 備品の管理状態（データ設計 5.6）。C-01 の条件と返す値。これから equipment・mine・importer で使う |
| LoanStatus | IN_STOCK（保管中）・LENT（貸出中） | 返す値の貸出状態 |
| LoanStatusFilter | ALL・IN_STOCK・LENT | C-01 の条件 loanStatus（API設計 4.8） |
| ConfirmFilter | ALL・CONFIRMED・UNCONFIRMED | C-01 の条件 confirm（API設計 4.8） |
| EquipmentSort | MANAGEMENT_NO・LAST_CONFIRMED_ON | C-01 の並び順の列（sort の managementNo・lastConfirmedOn） |

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.error.ApiResponse | 成功の返す値を ok で包む |
| common.error.BusinessRuleException・ApiMessages | sort・page が決まった値でないとき 400「入力内容に誤りがあります。」 |
| common.security | `@PreAuthorize("hasAuthority('EQUIPMENT_VIEW')")` |
| common.calendar.MonthlyConfirmationRule | 今月の1日（SQL の条件）、今月確認済みか（返す値。common.md 3.11） |
| common.error.FieldErrorException | C-03 の業務チェックの誤りを、入力欄のエラー（400）で返す |
| common.security.LoginUserId・common.config（Clock） | C-03 で、作った人のユーザIDと、作った日時・今日 |

## 3. ほかの機能への影響

| No. | 種類 | 内容 | 相手（機能・部品） | 対応 |
|---|---|---|---|---|
| 1 | 同じルール | 「確認した」で最終確認日を今日にし、version を1増やす（R-9・R-10） | mine（B-04）、貸出・返却（B-02・B-03・C-07・C-08） | 作るときに同じようにする（version を増やすことを、それぞれの詳細設計に書く） |
| 2 | 同じルール | 貸出中の決め方（R-2） | mine（B-01〜B-03）、importer、equipment の C-07・C-08 | 変えるときは、同じように直す（CLAUDE.md 5章） |
| 3 | 同じテーブルを読む | categories・users・loans を読むだけ | category・user・loan | 対応なし |
| 4 | common・Flyway・Enum | 今月確認済みの判定は common.calendar（取り込み済み。common.md 3.11）。Enum を5つ足した（2.3）。Flyway は変更なし | ― | 足した Enum を相手に伝える（CLAUDE.md 9章） |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | 探す条件の型 EquipmentSearchCondition を equipment.model に置く | mapper が使ってよいのは、同じ機能の model と common だけ（CLAUDE.md 5章）。category の CategoryEquipmentCount と同じ考え方 | いいえ | まだ |
| 2 | ページ分けの返す値の形（items・page・size・totalCount・totalPages）は dto.equipment に作る | 共通の形（API設計 2.5）だが、common の変更は2人の相談が要るため、今は equipment の中に作る。2つ目のページ分けの API（D-01 など）を作るときに、common に移すかを相談する | いいえ | まだ |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-11 | 初版（ZPOP-68。C-01 の分） |
| v1.1 | 2026-11-11 | C-03（ZPOP-70）の分を足した（1.1・1.3・2章） |
| v1.2 | 2026-11-11 | C-06（ZPOP-73）の分を足した（1.1・1.3 の R-9・R-10・2章・3章）。C-01 の1件の形を作る処理を EquipmentItemAssembler にまとめた |
