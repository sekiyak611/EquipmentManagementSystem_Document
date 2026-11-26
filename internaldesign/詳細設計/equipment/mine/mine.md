# 詳細設計：自分の備品（api.equipment.mine）

| 項目 | 内容 |
|---|---|
| 版 | v1.8 2026-11-26 |
| Jira | ZPOP-63（B-01）、ZPOP-65（B-03）、ZPOP-66（B-04）、ZPOP-107（S-05）、ZPOP-67（B-05）。B-02、S-06 は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.1 の1章・5章・7章（F-07・F-10・F-18・F-19）、API設計.md v1.4 の2.3〜2.5・3.2・4.5〜4.7、画面設計.md v1.8 の3章・4章・10章、画面一覧.md v1.1 の2章、データ設計.md v1.0 の2章・5.6・5.7。B-05 の分は、API設計.md v1.5 の2.5・3.2、画面設計.md v1.10 の4章（B-05 の詳細設計のもとにした設計書を見る） |

## 1. 概要

写したもと：機能一覧.md v1.1 の4章（F-07・F-18・F-19）、画面設計.md v1.8 の3章

一般社員が、自分が借りている備品を見て（B-01）、借りる（B-02）・返す（B-03）・確認した（B-04）をする。借りられる備品を探す（B-05）。今月まだ確認していない備品の数と、今月の催促日時を案内する

### 1.1 API一覧

写したもと：API設計.md v1.4 の3.2

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | パッケージ（クラス名の頭） | 詳細設計 |
|---|---|---|---|---|---|---|---|
| B-01 | GET | /api/me/loans | 自分が借りている備品の一覧と、今月の確認の案内を返す | LOAN_SELF | S-05 | api.equipment.mine.search.item（EquipmentMineSearchItem） | [B-01_自分の備品の一覧.md](B-01_自分の備品の一覧.md) |
| B-02 | POST | /api/me/loans | 備品を借りる | LOAN_SELF | S-06 | api.equipment.mine.entry.item（EquipmentMineEntryItem） | まだ（ZPOP-64） |
| B-03 | POST | /api/me/loans/{貸出履歴のID}/return | 借りている備品を返す | LOAN_SELF | S-05 | api.equipment.mine.update.returnitem（EquipmentMineUpdateReturnItem） | [B-03_備品を返す.md](B-03_備品を返す.md) |
| B-04 | POST | /api/me/confirmations | 自分が借りている備品を「確認した」にする | CONFIRM_SELF | S-05 | api.equipment.mine.update.item（EquipmentMineUpdateItem） | [B-04_確認した.md](B-04_確認した.md) |
| B-05 | GET | /api/me/available-equipment | 借りられる備品を探す | LOAN_SELF | S-06 | api.equipment.mine.search.availableitem（EquipmentMineSearchAvailableItem） | [B-05_借りられる備品を探す.md](B-05_借りられる備品を探す.md) |

### 1.2 画面一覧

写したもと：画面一覧.md v1.1 の2章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-05 | 自分の備品 | /my-equipment | 全員（権限項目「備品を借りる・返す（自分）」） | はい | [S-05_自分の備品.md](S-05_自分の備品.md) |
| S-06 | 備品を借りる | （画面の詳細設計で決める） | 全員 | はい | まだ（ZPOP-108） |

### 1.3 業務のルール

写したもと：機能一覧.md v1.1 の5章、画面設計.md v1.8 の3章、API設計.md v1.4 の4.5

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 一覧に出すのは、ログインしている人が今借りている（返却日が空で、取り消されていない）備品 | 機能一覧 F-07・F-19、API設計 4.5 |
| R-2 | 並び順は、未確認を上にし、その中は貸出日の古い順 | 画面設計 3章、API設計 4.5 |
| R-3 | 今月確認済み＝最終確認日の月が今月（common.md 3.11） | 機能一覧 1章 |
| R-4 | 返却予定日を過ぎていたら、期限超過（画面で返却予定日を赤字にする） | 画面設計 3章 |
| R-5 | 催促日は毎月25日（土日祝日なら前の平日）。催促の日時は、その日の催促の時刻（毎朝9:00）（common.md 3.18） | 機能一覧 7章、API設計 4.5 |
| R-6 | 一覧に出す備品の管理状態は「管理中」（催促の対象・確認できる備品と同じ。詳細設計 B-01 の12章の No.2） | 機能一覧 7章の3 |
| R-7 | 借りられるのは、管理中で、保管中（貸出中でない）の備品だけ。管理番号の順に、20件ずつ出す | 機能一覧 5章の1、画面設計 4章 |

B-01 で使うのは R-1〜R-6。B-05 で使うのは R-7（ほかに、B-01 と同じ「今借りている」の条件）。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則。B-01・B-03・B-04・B-05（Server）の分を書く。

### 2.1 Server

API ごとのパッケージ（api.equipment.mine の下。その中を controller・service・model に分ける。B-01 のように、受け取る値がない API は RestInDto を作らない。業務チェックがない API は validator を作らない。CLAUDE.md 4.1）

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| api.equipment.mine.search.item.controller | EquipmentMineSearchItemController | B-01 の入口。ServiceInDto を作る | B-01 |
| api.equipment.mine.search.item.service | EquipmentMineSearchItemService（interface）・EquipmentMineSearchItemServiceImpl | B-01 の業務の処理（`@Service`。読むだけなので `@Transactional` は付けない） | B-01 |
| api.equipment.mine.search.item.service | EquipmentMineSearchItemServiceInDto | B-01 で Service に渡す値（ログインしている人のユーザIDだけ） | B-01 |
| api.equipment.mine.search.item.model | EquipmentMineSearchItemRestOutDto（中に Item） | B-01 で返す値。common.equipment の MyLoanList・MyLoanItem を写す | B-01 |
| （テスト）api.equipment.mine.search.item | EquipmentMineSearchItemApiTest | B-01 のテスト | B-01 |
| api.equipment.mine.update.returnitem.controller | EquipmentMineUpdateReturnItemController・EquipmentMineUpdateReturnItemRestInDto | B-03 の入口。RestInDto（memo）と形式のチェック（200文字）。ServiceInDto を作る | B-03 |
| api.equipment.mine.update.returnitem.service | EquipmentMineUpdateReturnItemService（interface）・EquipmentMineUpdateReturnItemServiceImpl・EquipmentMineUpdateReturnItemServiceInDto | B-03 の業務の処理（`@Service`、`@Transactional`）。ServiceInDto に、貸出履歴のチェック（common.validation） | B-03 |
| api.equipment.mine.update.returnitem.model | EquipmentMineUpdateReturnItemRestOutDto | B-03 で返す、返したあとの最新の一覧（B-01 と同じ形） | B-03 |
| （テスト）api.equipment.mine.update.returnitem | EquipmentMineUpdateReturnItemApiTest | B-03 のテスト | B-03 |
| api.equipment.mine.update.item.controller | EquipmentMineUpdateItemController・EquipmentMineUpdateItemRestInDto | B-04 の入口。RestInDto（equipmentIds）と形式のチェック（1つ以上）。ServiceInDto を作る | B-04 |
| api.equipment.mine.update.item.service | EquipmentMineUpdateItemService（interface）・EquipmentMineUpdateItemServiceImpl・EquipmentMineUpdateItemServiceInDto | B-04 の業務の処理（`@Service`、`@Transactional`）。備品を FOR UPDATE で押さえて読み、今借りている貸出履歴を押さえずに読み、Validator で確かめ、まとめて更新する | B-04 |
| api.equipment.mine.update.item.validator | EquipmentMineUpdateItemValidator・EquipmentMineUpdateItemValidatorDto | 業務チェック（備品がある・自分が借りている・管理中）。ServiceImpl が読んだ行を渡して確かめる（読むだけ） | B-04 |
| api.equipment.mine.update.item.model | EquipmentMineUpdateItemRestOutDto | B-04 で返す、確認したあとの最新の一覧（B-01 と同じ形） | B-04 |
| （テスト）api.equipment.mine.update.item | EquipmentMineUpdateItemApiTest | B-04 のテスト | B-04 |
| api.equipment.mine.search.availableitem.controller | EquipmentMineSearchAvailableItemController・EquipmentMineSearchAvailableItemRestInDto | B-05 の入口と、条件の形式のチェック（page。keyword の LIKE の形）。ServiceInDto を作る | B-05 |
| api.equipment.mine.search.availableitem.service | EquipmentMineSearchAvailableItemService（interface）・EquipmentMineSearchAvailableItemServiceImpl・EquipmentMineSearchAvailableItemServiceInDto | B-05 の業務の処理（`@Service`。読むだけなので `@Transactional` は付けない）。業務チェックがないので validator は作らない | B-05 |
| api.equipment.mine.search.availableitem.model | EquipmentMineSearchAvailableItemRestOutDto（items の1件は中の Item） | B-05 の返す値（API設計 2.5 の形） | B-05 |
| （テスト）api.equipment.mine.search.availableitem | EquipmentMineSearchAvailableItemApiTest | B-05 のテスト | B-05 |

使う dao（作らない。MyBatis Generator が作ったもの）

| パッケージ | クラス・ファイル | 使い方 | 使う API |
|---|---|---|---|
| dao.mapper | LoanMapper | 今借りている貸出履歴を読む（読むだけ） | B-01 |
| dao.mapper | EquipmentMapper | 貸出中の備品を読む（読むだけ） | B-01 |
| dao.entity | Loan・LoanExample・Equipment・EquipmentExample | テーブルの1行の形と、取得の条件 | B-01 |
| dao.mapper | LoanMapper・EquipmentMapper | 返却日・メモ・最終確認日・version を更新する（B-03） | B-03 |
| dao.mapper | LoanMapper | 今借りている貸出履歴を、押さえずに、Example（equipment_id IN・返却日が空・取り消されていない）で読む（B-04） | B-04 |
| dao.mapper.custom | LoanCustomMapper（新規。XML は dao/mapper/custom/） | selectByIdForUpdate（FOR UPDATE。Example では書けない）。common.md 3.20 | B-03 |
| dao.mapper.custom | LoanCustomMapper | selectCurrentByEquipmentIdsForUpdate（初版の B-04 で足したが、使わなくなる。障害 ZPOP-434 の実装の修正で削除する） | （なし） |
| dao.mapper | LoanMapper | 今借りている貸出履歴を読む（読むだけ。equipment_id だけ使う）（B-05） | B-05 |
| dao.mapper | CategoryMapper | ページの種別の名前を IN でまとめて読む（B-05） | B-05 |
| dao.mapper.custom | EquipmentCustomMapper | countAvailableBySearch・selectAvailableBySearch（新規。管理中・保管中の備品を、種別・キーワードで絞って数える・20件読む。NOT IN とキーワードの OR は Example では書けない。B-05 の詳細設計の7章） | B-05 |
| dao.entity.custom | AvailableEquipmentSearchCondition（新規） | B-05 の探す条件（EquipmentCustomMapper に渡す。テーブルの行ではない） | B-05 |
| dao.mapper.custom | EquipmentCustomMapper | selectByIdsForUpdate（新規。ID の一覧の備品を FOR UPDATE で読む。IN）、updateLastConfirmedOnByIds（新規。最終確認日・version+1・更新日時・更新者を、1つの SQL でまとめて更新） | B-04 |

足した共通部品（common。B-04 も同じ形の一覧を返すので common に置く。common.md 3.19）

| パッケージ | クラス | 役割 | 使う API |
|---|---|---|---|
| common.equipment | MyLoanList・MyLoanItem | B-01 の data と items の1件の形 | B-01・B-04 |
| common.equipment | MyLoanListAssembler | ログインしている人の分の一覧を作る（今借りている貸出履歴・備品・種別を、テーブルごとに読んで突き合わせる） | B-01・B-04 |
| common.calendar | ReminderCalendar#isReminderPassed | 今月の催促の日時を過ぎたか（common.md 3.18） | B-01 |
| common.validation・common.error | LoanExists・LoanBorrowedBySelf・LoanNotReturned・LoanEquipmentManaged、ServiceErrorType.Forbidden・ForbiddenException | 貸出履歴のチェックと、403 の返し方（common.md 3.20）。B-04 が使うのは、ForbiddenException だけ（B-04 の確かめは、Validator） | B-03（ForbiddenException は B-04 も） |

### 2.2 Client

S-05（ZPOP-107）の分。フォルダは features/equipment/mine/（CLAUDE.md 4.3）。詳しくは [S-05_自分の備品.md](S-05_自分の備品.md) の2.2・7章。

| 場所 | ファイル | 役割 | 使う API |
|---|---|---|---|
| src/features/equipment/mine/pages | MyEquipmentPage.tsx | S-05 の画面全体 | B-01・B-03・B-04 |
| src/features/equipment/mine/components | MyEquipmentNotice.tsx・MyEquipmentCard.tsx・ReturnDialog.tsx・reminderText.ts | 上部の案内・備品1件・「返す」のダイアログ・催促の日時の形 | ― |
| src/features/equipment/mine | api.ts（getMyLoans・confirmEquipment・returnLoan）・types.ts | API の呼び出しと型 | B-01・B-03・B-04 |
| （テスト）tests/equipment/mine | my-equipment.spec.ts | S-05 のテスト（Playwright。スマートフォンと PC） | ― |

### 2.3 足す Enum（common.constant）

| Enum | 値 | 意味（設計書の言葉） | 使う所 |
|---|---|---|---|
| なし（既存の EquipmentStatus.MANAGED を使う） | | | |

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.security.LoginUserId | controller で `@AuthenticationPrincipal` から、ログインしている人のユーザIDを受け取る |
| common.equipment.EquipmentSummaryAssembler（3.12） | 種別の名前と今月確認済みかを求める（C-01 と同じ部品） |
| common.calendar.ReminderCalendar（3.18） | 今月の催促の日時・過ぎたか |
| common.calendar.MonthlyConfirmationRule（3.11） | EquipmentSummaryAssembler の中で使う |
| common.error.ApiResponse | 返す値の形 |

## 3. ほかのまとまりへの影響

| No. | 種類 | 内容 | 相手（まとまり・部品） | 対応 |
|---|---|---|---|---|
| 1 | 同じルール | 「今借りている」（返却日が空・取り消されていない）の条件と、「今月確認済みでない」の数え方。B-01 が一覧を作る | equipment.mine の B-04（同じ形の一覧を返す）、equipment.management の C-01（貸出状態）・C-06 | B-04 は MyLoanListAssembler を使う（書き写さない）。ほかは、直したら同じように直し、テストも直す |
| 2 | common に足した部品 | common.equipment に MyLoanList・MyLoanItem・MyLoanListAssembler、common.calendar の ReminderCalendar に isReminderPassed | 2人で共有するファイル（CLAUDE.md 9章） | 相手に伝える（プルリクエストの説明に書く） |
| 3 | Flyway | 変えない | ― | ― |
| 4 | common に足す部品 | ForbiddenException・ServiceErrorType.Forbidden（403 の返し方）、貸出履歴のチェック用アノテーション4つ、LoanCustomMapper（common.md 3.20） | 2人で共有するファイル（CLAUDE.md 9章） | 実装の工程の前に、相手に伝える。common の変更として、その変更だけの小さな MR にして、先に main に入れる（B-03 の実装 MR は、それがマージされてから） |
| 5 | 同じルール | 返却のルール（自分の分だけ返せる、返却日は今日、最終確認日を更新する）と、行を押さえる順（貸出履歴 → 備品。複数なら、備品の ID の小さい順） | equipment.management の C-07・C-08・C-05（備品の削除）・D-02・D-03（貸出履歴の直し・取り消し）・I-03（今貸出中の取り込み）、equipment.mine の B-02 | それぞれの詳細設計を書くとき、同じ順にする。B-02 は、貸出履歴を足す・変える処理は、確定する前に、その備品の行を FOR UPDATE で押さえる（B-04 は、この約束に頼っている。B-04 の8章）。B-04 は、備品の行だけを押さえ、貸出履歴は押さえない（障害 ZPOP-434）。貸出履歴を FOR UPDATE で押さえるときの索引（主キーか、備品の ID の索引か）は、B-03（主キーで押さえてから、備品の ID の索引を書き換える）と行き違うと、同じ障害（デッドロック）になる。**未確定（人の確認がまだ。4章 No.3）**。B-02 は、B-04・C-06 との同時実行を、実機で確かめて、押さえる順を、B-02 の詳細設計で決める（外部キーのために、貸出履歴の追加は、備品の行を共有ロックで押さえる）。I-03・E-02 のように、複数の備品を書き換えるものは、備品の ID の昇順で書き換える |
| 6 | dao に足す部品 | EquipmentCustomMapper#selectByIdsForUpdate・#updateLastConfirmedOnByIds（B-04 の詳細設計の7章。`version = version + 1` の式で、1つの SQL でまとめて更新する）。初版で足した LoanCustomMapper#selectCurrentByEquipmentIdsForUpdate は、使わなくなるので、削除する（ほかの機能は使っていない）。**実装の修正（ZPOP-436）の MR のあとで、dao の変更だけの小さな MR にして、先に main に入れる**（2人で相談。dao のテスト（LoanCustomMapperTest の該当、CustomMapperBulkLockTest の貸出履歴の分）も一緒に直す） | 2人で共有するファイル（CLAUDE.md 9章。dao） | 実装の工程の前に、相手に伝える。dao の変更として、その変更だけの小さな MR にして、先に main に入れる（B-04 の実装 MR は、それがマージされてから） |
| 7 | 同じルール | 確認のルール（最終確認日は今日、保存のたびに version +1、今月すでに確認済みでも誤りにしない、管理中の備品だけ、複数の行を押さえるときは備品の ID の小さい順） | equipment.management の C-06・E-02 | C-06 は作成済み。E-02（CSV で確認日を更新）の詳細設計を書くとき、同じにする（日付は CSV の値）。B-04 を直したら、C-06 も同じに直す。別件：C-06・B-03 は、読んだ version に 1 を足した値を Example で書き、B-04 は式（`version + 1`）。結果は同じだが、そろえるかは、実装の工程で、人に相談する |
| 8 | 共有ファイルへの足し（Client） | src/routes.tsx に S-05 の1行（/my-equipment）、src/common/components/menuItems.ts にメニュー「自分の備品」の1行（LOAN_SELF） | 2人で共有するファイル（CLAUDE.md 9章：routes.tsx・共通ヘッダーのメニューは「1行足すだけにする」） | 実装の MR の説明に書いて、相手に伝える |
| 9 | 共有ファイル（common）の変更 | src/common/components/TopPlaceholderPage.tsx に、homePage が MY_EQUIPMENT のとき /my-equipment に移す処理（S-05 の詳細設計の6章・10章 No.14）。影響する既存のテスト：tests/auth/login.spec.ts・tests/common/error-page.spec.ts・tests/common/shell.spec.ts（`top-placeholder` を見ている） | common の変更（CLAUDE.md 9章：2人で相談し、その変更だけの小さな作業にして、先に main に入れる） | 実装の MR とは別の小さな MR にする（人の確認は、まだ）。「S-05・S-07 ができたら置き換える」と決まっていた分の一部（S-07 の分は、S-07 のとき） |
| 10 | dao に足す部品 | EquipmentCustomMapper#countAvailableBySearch・#selectAvailableBySearch と、dao.entity.custom.AvailableEquipmentSearchCondition（B-05 の詳細設計の7章。管理中・保管中の備品を探す SQL。C-01 の countBySearch・selectBySearch は変えない） | 2人で共有するファイル（CLAUDE.md 9章。dao） | 実装の工程の前に、相手に伝える。dao の変更として、その変更だけの小さな MR にして、先に main に入れる（B-05 の実装 MR は、それがマージされてから）。**2人の相談は、まだ** |
| 11 | 同じ弱点 | page が非常に大きいとき、飛ばす件数 `(page - 1) × 件数` を int で計算すると溢れ、500 になるおそれがある（独立レビューで見つけた）。B-05 の設計は、long で計算し、count 以上なら読まない形にした。C-01 の実装（EquipmentManagementSearchItemServiceImpl）にも同じ計算がある | equipment.management の C-01（実装済み）。ほかに、ページ分けのある API（D-01・E-04・G-01 など）を書くとき | C-01 は、直すかを人に相談する（別の小さな作業）。ほかは、詳細設計を書くとき、同じ形にする |

## 4. 設計書にない判断

まとまり全体にかかわる判断。B-01 の判断は B-01_自分の備品の一覧.md の12章。

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | S-05 の URL は /my-equipment（2026-11-25 に決めた。S-05 の10章 No.1）。S-06 の URL は、S-06 の詳細設計（ZPOP-108）で決める（S-05 の「借りる」ボタンの移る先は、/borrow の案） | 画面一覧 2章で確かめる | いいえ | 済（S-05。2026-11-25） |
| 2 | B-04 の 404（送った備品がない・削除済み）のとき、S-05 が S-19（見つからない）に移るか、一覧を最新にするかは、S-05 の詳細設計（10章 No.3）で決めた：赤の帯「対象が見つかりません。」を出し、一覧を最新にする（S-19 には移らない。common.md 11.10） | 画面設計 3章に、404 のときの動きがない | はい | 決めた（人の確認はまだ。2026-11-25） |
| 3 | 貸出履歴を FOR UPDATE で押さえるときの決まり：案A「貸出履歴の ID（主キー）で押さえる。備品の ID から探すときは、先に普通の SELECT で貸出履歴の ID を知り、主キーで押さえ直して確かめる」、案B「全部を、備品 → 貸出履歴の順にそろえる（B-03 も直す）」。障害 ZPOP-434 と同じデッドロックを、C-08・C-05・C-07・I-03・D-02・D-03 に残さないため | 障害 ZPOP-434 のレビュー（2026-11-23）。決まれば、common.md 3.20 に書く（2人で共有するファイル） | はい（同時に操作されたときの結果） | まだ（未確定。B-04 には、影響しない） |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-16 | 初版（ZPOP-63。B-01 の分） |
| v1.1 | 2026-11-23 | ZPOP-65：B-03 の分を足した（1.1 のリンク、2.1 のクラス・dao・共通部品、3章の No.4・5） |
| v1.2 | 2026-11-23 | ZPOP-66：B-04 の分を足した（1.1 のリンク、2.1 のクラス・dao、3章の No.6・7、4章の No.2）。3章の No.5 に、C-05・D-02・D-03・I-03 と、B-02 の順を足した |
| v1.3 | 2026-11-23 | 障害 ZPOP-434：B-04 は備品の行だけを押さえる形に直した（2.1 の dao、3章の No.5・6、4章の No.3）。LoanCustomMapper#selectCurrentByEquipmentIdsForUpdate は削除する。貸出履歴の押さえ方の一般の決まりは、未確定として残した |
| v1.4 | 2026-11-24 | 2.1 の B-04 の service の説明を、備品だけを押さえる形（障害 ZPOP-434）に直した（直し漏れ） |
| v1.5 | 2026-11-25 | ZPOP-107：S-05 の分を足した（1.2 のリンクと URL、2.2 の Client、3章の No.8、4章の No.1・2）。S-05 の URL を /my-equipment に決めた |
| v1.6 | 2026-11-25 | 3章：TopPlaceholderPage の変更を、No.8 から No.9 に分けた（common の変更。小さな別の MR にする） |
| v1.7 | 2026-11-26 | ZPOP-67：B-05 の分を足した（1.1 のリンク、1.3 の R-7、2.1 のクラス・dao、3章の No.10）。B-05 のもとにした設計書を、画面設計 v1.10・API設計 v1.5 にした |
| v1.8 | 2026-11-26 | ZPOP-177：B-05 の独立レビューの指摘を直した（2章・2.1 の説明文を B-01 だけの言い方から一般の言い方に直した、3章に No.11） |
