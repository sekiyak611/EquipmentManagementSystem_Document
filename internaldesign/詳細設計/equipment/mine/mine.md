# 詳細設計：自分の備品（api.equipment.mine）

| 項目 | 内容 |
|---|---|
| 版 | v1.3 2026-11-23 |
| Jira | ZPOP-63（B-01）、ZPOP-65（B-03）、ZPOP-66（B-04）。B-02・B-05、S-05・S-06 は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.1 の1章・5章・7章（F-07・F-10・F-18・F-19）、API設計.md v1.4 の2.3〜2.5・3.2・4.5〜4.7、画面設計.md v1.7 の3章・4章・10章、画面一覧.md v1.1 の2章、データ設計.md v1.0 の2章・5.6・5.7 |

## 1. 概要

写したもと：機能一覧.md v1.1 の4章（F-07・F-18・F-19）、画面設計.md v1.7 の3章

一般社員が、自分が借りている備品を見て（B-01）、借りる（B-02）・返す（B-03）・確認した（B-04）をする。借りられる備品を探す（B-05）。今月まだ確認していない備品の数と、今月の催促日時を案内する

### 1.1 API一覧

写したもと：API設計.md v1.4 の3.2

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | パッケージ（クラス名の頭） | 詳細設計 |
|---|---|---|---|---|---|---|---|
| B-01 | GET | /api/me/loans | 自分が借りている備品の一覧と、今月の確認の案内を返す | LOAN_SELF | S-05 | api.equipment.mine.search.item（EquipmentMineSearchItem） | [B-01_自分の備品の一覧.md](B-01_自分の備品の一覧.md) |
| B-02 | POST | /api/me/loans | 備品を借りる | LOAN_SELF | S-06 | api.equipment.mine.entry.item（EquipmentMineEntryItem） | まだ（ZPOP-64） |
| B-03 | POST | /api/me/loans/{貸出履歴のID}/return | 借りている備品を返す | LOAN_SELF | S-05 | api.equipment.mine.update.returnitem（EquipmentMineUpdateReturnItem） | [B-03_備品を返す.md](B-03_備品を返す.md) |
| B-04 | POST | /api/me/confirmations | 自分が借りている備品を「確認した」にする | CONFIRM_SELF | S-05 | api.equipment.mine.update.item（EquipmentMineUpdateItem） | [B-04_確認した.md](B-04_確認した.md) |
| B-05 | GET | /api/me/available-equipment | 借りられる備品を探す | LOAN_SELF | S-06 | api.equipment.mine.search.availableitem（EquipmentMineSearchAvailableItem） | まだ（ZPOP-67） |

### 1.2 画面一覧

写したもと：画面一覧.md v1.1 の2章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-05 | 自分の備品 | （画面の詳細設計で決める） | 全員（権限項目「備品を借りる・返す（自分）」） | はい | まだ（ZPOP-107） |
| S-06 | 備品を借りる | （画面の詳細設計で決める） | 全員 | はい | まだ（ZPOP-108） |

### 1.3 業務のルール

写したもと：機能一覧.md v1.1 の5章、画面設計.md v1.7 の3章、API設計.md v1.4 の4.5

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 一覧に出すのは、ログインしている人が今借りている（返却日が空で、取り消されていない）備品 | 機能一覧 F-07・F-19、API設計 4.5 |
| R-2 | 並び順は、未確認を上にし、その中は貸出日の古い順 | 画面設計 3章、API設計 4.5 |
| R-3 | 今月確認済み＝最終確認日の月が今月（common.md 3.11） | 機能一覧 1章 |
| R-4 | 返却予定日を過ぎていたら、期限超過（画面で返却予定日を赤字にする） | 画面設計 3章 |
| R-5 | 催促日は毎月25日（土日祝日なら前の平日）。催促の日時は、その日の催促の時刻（毎朝9:00）（common.md 3.18） | 機能一覧 7章、API設計 4.5 |
| R-6 | 一覧に出す備品の管理状態は「管理中」（催促の対象・確認できる備品と同じ。詳細設計 B-01 の12章の No.2） | 機能一覧 7章の3 |

B-01 で使うのは R-1〜R-6。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則。B-01（Server）の分を書く。

### 2.1 Server

API ごとのパッケージ（api.equipment.mine の下。その中を controller・service・model に分ける。受け取る値がないので RestInDto を作らない。業務チェックがないので validator を作らない。CLAUDE.md 4.1）

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
| api.equipment.mine.update.item.service | EquipmentMineUpdateItemService（interface）・EquipmentMineUpdateItemServiceImpl・EquipmentMineUpdateItemServiceInDto | B-04 の業務の処理（`@Service`、`@Transactional`）。貸出履歴・備品を FOR UPDATE で読み、Validator で確かめ、まとめて更新する | B-04 |
| api.equipment.mine.update.item.validator | EquipmentMineUpdateItemValidator・EquipmentMineUpdateItemValidatorDto | 業務チェック（備品がある・自分が借りている・管理中）。ServiceImpl が読んだ行を渡して確かめる（読むだけ） | B-04 |
| api.equipment.mine.update.item.model | EquipmentMineUpdateItemRestOutDto | B-04 で返す、確認したあとの最新の一覧（B-01 と同じ形） | B-04 |
| （テスト）api.equipment.mine.update.item | EquipmentMineUpdateItemApiTest | B-04 のテスト | B-04 |

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
| dao.mapper.custom | EquipmentCustomMapper | selectByIdsForUpdate（新規。ID の一覧の備品を FOR UPDATE で読む。IN）、updateLastConfirmedOnByIds（新規。最終確認日・version+1・更新日時・更新者を、1つの SQL でまとめて更新） | B-04 |

足した共通部品（common。B-04 も同じ形の一覧を返すので common に置く。common.md 3.19）

| パッケージ | クラス | 役割 | 使う API |
|---|---|---|---|
| common.equipment | MyLoanList・MyLoanItem | B-01 の data と items の1件の形 | B-01・B-04 |
| common.equipment | MyLoanListAssembler | ログインしている人の分の一覧を作る（今借りている貸出履歴・備品・種別を、テーブルごとに読んで突き合わせる） | B-01・B-04 |
| common.calendar | ReminderCalendar#isReminderPassed | 今月の催促の日時を過ぎたか（common.md 3.18） | B-01 |
| common.validation・common.error | LoanExists・LoanBorrowedBySelf・LoanNotReturned・LoanEquipmentManaged、ServiceErrorType.Forbidden・ForbiddenException | 貸出履歴のチェックと、403 の返し方（common.md 3.20）。B-04 が使うのは、ForbiddenException だけ（B-04 の確かめは、Validator） | B-03（ForbiddenException は B-04 も） |

### 2.2 Client

B-01 では作らない（S-05 は ZPOP-107）。

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

## 4. 設計書にない判断

まとまり全体にかかわる判断。B-01 の判断は B-01_自分の備品の一覧.md の12章。

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | S-05・S-06 の URL は、画面の詳細設計（ZPOP-107・108）で決める | 画面一覧 2章で確かめる | いいえ | ― |
| 2 | B-04 の 404（送った備品がない・削除済み）のとき、S-05 が S-19（見つからない）に移るか、一覧を最新にするかは、画面の詳細設計（ZPOP-107）で決める（API設計 2.3 は、404 のとき S-19 を出すと書く） | 画面設計 3章に、404 のときの動きがない | はい | まだ（未確定） |
| 3 | 貸出履歴を FOR UPDATE で押さえるときの決まり：案A「貸出履歴の ID（主キー）で押さえる。備品の ID から探すときは、先に普通の SELECT で貸出履歴の ID を知り、主キーで押さえ直して確かめる」、案B「全部を、備品 → 貸出履歴の順にそろえる（B-03 も直す）」。障害 ZPOP-434 と同じデッドロックを、C-08・C-05・C-07・I-03・D-02・D-03 に残さないため | 障害 ZPOP-434 のレビュー（2026-11-23）。決まれば、common.md 3.20 に書く（2人で共有するファイル） | はい（同時に操作されたときの結果） | まだ（未確定。B-04 には、影響しない） |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-16 | 初版（ZPOP-63。B-01 の分） |
| v1.1 | 2026-11-23 | ZPOP-65：B-03 の分を足した（1.1 のリンク、2.1 のクラス・dao・共通部品、3章の No.4・5） |
| v1.2 | 2026-11-23 | ZPOP-66：B-04 の分を足した（1.1 のリンク、2.1 のクラス・dao、3章の No.6・7、4章の No.2）。3章の No.5 に、C-05・D-02・D-03・I-03 と、B-02 の順を足した |
| v1.3 | 2026-11-23 | 障害 ZPOP-434：B-04 は備品の行だけを押さえる形に直した（2.1 の dao、3章の No.5・6、4章の No.3）。LoanCustomMapper#selectCurrentByEquipmentIdsForUpdate は削除する。貸出履歴の押さえ方の一般の決まりは、未確定として残した |
