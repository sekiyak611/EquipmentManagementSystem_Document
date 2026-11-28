# 詳細設計：備品の管理（api.equipment.management）

| 項目 | 内容 |
|---|---|
| 版 | v2.1 2026-11-28 |
| Jira | ZPOP-68（C-01）、ZPOP-70（C-03）、ZPOP-73（C-06）、ZPOP-109（S-07）。C-02・C-04・C-05・C-07・C-08、S-08・S-09 は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.0 の1章・4章（F-05〜F-07・F-09）、API設計.md v1.2 の2.3〜2.5・3.3・4.8、画面設計.md v1.3 の10〜12章（S-07 は v1.10 の10章）、画面一覧.md v1.0 の2章・7章（S-07 は v1.3）、データ設計.md v1.0 の2章・5.1・5.3・5.5〜5.7・6章 |

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

写したもと：画面一覧.md v1.0 の2章・7章（S-07 の行は、画面一覧.md v1.3 の2章・7章）

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-07 | 備品一覧 | /equipment | 総務（備品一覧を見る） | いいえ（PCを前提。スマートフォンではカード） | [S-07_備品一覧.md](S-07_備品一覧.md) |
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
| R-8 | 備品を足す・種別を変えるときは、種別の行を FOR SHARE で読む（K-04 と同時に動いても、消した種別の備品ができない） | equipment/category/category.md 3章の No.2 |

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
| api.equipment.management.search.item.controller | EquipmentManagementSearchItemController・EquipmentManagementSearchItemRestInDto | C-01 の入口と、条件の形式のチェック（sort・page） | C-01 |
| api.equipment.management.search.item.service | EquipmentManagementSearchItemService（インターフェース）・…ServiceImpl・…ServiceInDto | C-01 の業務の処理（読むだけなので `@Transactional` は付けない） | C-01 |
| api.equipment.management.search.item.model | EquipmentManagementSearchItemRestOutDto（items の1件は中の Item） | C-01 の返す値（API設計 2.5 の形） | C-01 |
| api.equipment.management.entry.item.controller | EquipmentManagementEntryItemController・EquipmentManagementEntryItemRestInDto | C-03 の入口と、受け取る値（形式のチェック。文字の項目は common.text.TextInputs#stripToNull で直す） | C-03 |
| api.equipment.management.entry.item.service | EquipmentManagementEntryItemService（インターフェース）・…ServiceImpl・…ServiceInDto | C-03 の業務の処理（`@Transactional`）。ServiceInDto に管理番号の重なり（@EquipmentManagementNoNotDuplicated）と種別（@CategoryExists(forShare = true)） | C-03 |
| api.equipment.management.entry.item.validator | EquipmentManagementEntryItemValidator・…ValidatorDto | 購入日・保証期日の決まり（今日の日付が要るので Validator） | C-03 |
| api.equipment.management.entry.item.model | EquipmentManagementEntryItemRestOutDto | C-03 の返す値（C-01 の1件と同じ形） | C-03 |
| api.equipment.management.update.confirmationitem.controller | EquipmentManagementUpdateConfirmationItemController | C-06 の入口（本文を受け取らないので RestInDto は作らない） | C-06 |
| api.equipment.management.update.confirmationitem.service | EquipmentManagementUpdateConfirmationItemService（インターフェース）・…ServiceImpl・…ServiceInDto | C-06 の業務の処理（`@Transactional`）。ServiceInDto に、あるか（@EquipmentExists(forUpdate = true)）・管理中か（@EquipmentManaged） | C-06 |
| api.equipment.management.update.confirmationitem.model | EquipmentManagementUpdateConfirmationItemRestOutDto | C-06 の返す値（C-01 の1件と同じ形） | C-06 |
| common.equipment | EquipmentSummaryAssembler・EquipmentSummary | 備品の行から一覧の1件の形を作る（種別の名前・借用者の氏名を IN でまとめて読んで突き合わせる）。C-01・C-06 で使うので common（2026-11-15 に決めた） | C-01・C-06 |
| common.validation | EquipmentManagementNoNotDuplicated・EquipmentExists・EquipmentManaged（中身は …Check）、CategoryExists（forShare を足した） | C-03・C-06 の DB との整合性のチェック | C-03・C-06 |
| common.text | TextInputs#stripToNull | 文字の項目の直し方（前後の空白を取り除き、空なら null） | C-03 |
| dao.mapper・dao.entity | EquipmentMapper・LoanMapper・CategoryMapper・UserMapper と、テーブルの形・Example | MyBatis Generator が作ったもの。足す（insertSelective）、最終確認日を変える（updateByExampleSelective）、IN でまとめて読む（selectByExample） | C-01・C-03・C-06 |
| dao.mapper.custom | EquipmentCustomMapper（countBySearch・selectBySearch・selectByIdForUpdate）、UserCustomMapper（selectIdsByNameContaining）、CategoryCustomMapper（selectByIdForShare） | Example では書けない SQL（LOWER と LIKE の OR、管理中だけに効かせる条件、FOR UPDATE・FOR SHARE） | C-01・C-03・C-06 |
| dao.entity.custom | EquipmentSearchCondition | 備品を探す条件（EquipmentCustomMapper に渡す。テーブルの行ではない） | C-01 |
| （テスト）api.equipment.management.search.item | EquipmentManagementSearchItemApiTest | C-01 のテスト | C-01 |
| （テスト）api.equipment.management.entry.item | EquipmentManagementEntryItemApiTest・EquipmentManagementEntryItemLockTest | C-03 のテストと、同時に種別を消されたときの守り（FOR SHARE）のテスト | C-03 |
| （テスト）api.equipment.management.update.confirmationitem | EquipmentManagementUpdateConfirmationItemApiTest | C-06 のテスト | C-06 |

- XML は、自動で作ったものは src/main/resources/jp/co/highjunk/equipment/dao/mapper/、手で書くものは同じ場所の custom/ に置く。

### 2.2 Client

S-07 の分を書く（S-08・S-09 は、そのときに書く）。フォルダは src/features/equipment/management/、テストは tests/equipment/management/。

| ファイル | 役割 | 使う画面 |
|---|---|---|
| pages/EquipmentListPage.tsx | S-07 の画面全体 | S-07 |
| components/EquipmentSearchForm.tsx・EquipmentTable.tsx・EquipmentCard.tsx・searchConditions.ts | 探す条件、PC の表、スマートフォンのカード、探す条件の型と URL との変換 | S-07 |
| api.ts・types.ts | getEquipmentList（C-01）・getCategoryOptions（K-01）・confirmEquipment（C-06）と、その型 | S-07 |
| （共有）routes.tsx・common/components/menuItems.ts | `/equipment` の1行、メニュー「備品一覧」（EQUIPMENT_VIEW）の1行を足す | S-07 |
| （共有）common/components/TopPlaceholderPage.tsx | `/` を開いたとき、homePage に合わせて /equipment・/my-equipment に移す。別の小さな MR にして先に main に入れる（S-07 の10章 No.3） | S-07（S-05 と共通） |

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
| 5 | 共有ファイル・同じ API | S-07 が、routes.tsx（`/equipment`）・menuItems.ts（備品一覧）に1行ずつ足し、common/components の TopPlaceholderPage で `/` を /equipment・/my-equipment に移す。K-01（category）を、S-07 の中から呼ぶ | 共通部品・mine（S-05）・category | TopPlaceholderPage は、S-05 の分と一緒に、別の小さな MR にして先に main に入れる（S-07 の10章 No.3）。K-01 は読むだけで、対応なし |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | 探す条件の型 EquipmentSearchCondition を dao.entity に置く | mapper が使ってよいのは、同じ機能の model と common だけ（CLAUDE.md 5章）。category の CategoryEquipmentCount と同じ考え方 | いいえ | まだ |
| 2 | ページ分けの返す値の形（items・page・size・totalCount・totalPages）は api.equipment.management の model に作る | 共通の形（API設計 2.5）だが、common の変更は2人の相談が要るため、今は equipment の中に作る。2つ目のページ分けの API（D-01 など）を作るときに、common に移すかを相談する | いいえ | まだ |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-11 | 初版（ZPOP-68。C-01 の分） |
| v1.1 | 2026-11-11 | C-03（ZPOP-70）の分を足した（1.1・1.3・2章） |
| v1.2 | 2026-11-11 | C-06（ZPOP-73）の分を足した（1.1・1.3 の R-9・R-10・2章・3章）。C-01 の1件の形を作る処理を common.equipment.EquipmentSummaryAssembler にまとめた |
| v2.0 | 2026-11-15 | パッケージ構成の変更で、api.equipment.management に作り直した（2026-11-15）。クラス名・パッケージ・Mapper のメソッドを新しい形（controller・service・validator・model、dao の Mapper と Example、手で書く Mapper、common の部品）に書き換えた。外から見た動きは変わらない。置き場所を equipment/management/management.md にし、2.1 のクラスの表を書き直した |
| v2.1 | 2026-11-28 | S-07（ZPOP-109）の分を足した（版・Jira、1.2 の S-07、2.2）。外から見た動きは変えていない |

