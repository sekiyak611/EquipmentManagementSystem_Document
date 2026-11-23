# 詳細設計：自分の備品（api.equipment.mine）

| 項目 | 内容 |
|---|---|
| 版 | v1.1 2026-11-23 |
| Jira | ZPOP-63（B-01）、ZPOP-65（B-03）。B-02・B-04・B-05、S-05・S-06 は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.1 の1章・5章・7章（F-07・F-10・F-18・F-19）、API設計.md v1.4 の2.3〜2.5・3.2・4.5〜4.7、画面設計.md v1.5 の3章・4章、画面一覧.md v1.1 の2章、データ設計.md v1.0 の2章・5.6・5.7 |

## 1. 概要

写したもと：機能一覧.md v1.1 の4章（F-07・F-18・F-19）、画面設計.md v1.5 の3章

一般社員が、自分が借りている備品を見て（B-01）、借りる（B-02）・返す（B-03）・確認した（B-04）をする。借りられる備品を探す（B-05）。今月まだ確認していない備品の数と、今月の催促日時を案内する

### 1.1 API一覧

写したもと：API設計.md v1.4 の3.2

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | パッケージ（クラス名の頭） | 詳細設計 |
|---|---|---|---|---|---|---|---|
| B-01 | GET | /api/me/loans | 自分が借りている備品の一覧と、今月の確認の案内を返す | LOAN_SELF | S-05 | api.equipment.mine.search.item（EquipmentMineSearchItem） | [B-01_自分の備品の一覧.md](B-01_自分の備品の一覧.md) |
| B-02 | POST | /api/me/loans | 備品を借りる | LOAN_SELF | S-06 | api.equipment.mine.entry.item（EquipmentMineEntryItem） | まだ（ZPOP-64） |
| B-03 | POST | /api/me/loans/{貸出履歴のID}/return | 借りている備品を返す | LOAN_SELF | S-05 | api.equipment.mine.update.returnitem（EquipmentMineUpdateReturnItem） | [B-03_備品を返す.md](B-03_備品を返す.md) |
| B-04 | POST | /api/me/confirmations | 自分が借りている備品を「確認した」にする | CONFIRM_SELF | S-05 | api.equipment.mine.update.item（EquipmentMineUpdateItem） | まだ（ZPOP-66） |
| B-05 | GET | /api/me/available-equipment | 借りられる備品を探す | LOAN_SELF | S-06 | api.equipment.mine.search.availableitem（EquipmentMineSearchAvailableItem） | まだ（ZPOP-67） |

### 1.2 画面一覧

写したもと：画面一覧.md v1.1 の2章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-05 | 自分の備品 | （画面の詳細設計で決める） | 全員（権限項目「備品を借りる・返す（自分）」） | はい | まだ（ZPOP-107） |
| S-06 | 備品を借りる | （画面の詳細設計で決める） | 全員 | はい | まだ（ZPOP-108） |

### 1.3 業務のルール

写したもと：機能一覧.md v1.1 の5章、画面設計.md v1.5 の3章、API設計.md v1.4 の4.5

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

使う dao（作らない。MyBatis Generator が作ったもの）

| パッケージ | クラス・ファイル | 使い方 | 使う API |
|---|---|---|---|
| dao.mapper | LoanMapper | 今借りている貸出履歴を読む（読むだけ） | B-01 |
| dao.mapper | EquipmentMapper | 貸出中の備品を読む（読むだけ） | B-01 |
| dao.entity | Loan・LoanExample・Equipment・EquipmentExample | テーブルの1行の形と、取得の条件 | B-01 |
| dao.mapper | LoanMapper・EquipmentMapper | 返却日・メモ・最終確認日・version を更新する（B-03） | B-03 |
| dao.mapper.custom | LoanCustomMapper（新規。XML は dao/mapper/custom/） | selectByIdForUpdate（FOR UPDATE。Example では書けない）。common.md 3.20 | B-03 |

足した共通部品（common。B-04 も同じ形の一覧を返すので common に置く。common.md 3.19）

| パッケージ | クラス | 役割 | 使う API |
|---|---|---|---|
| common.equipment | MyLoanList・MyLoanItem | B-01 の data と items の1件の形 | B-01・B-04 |
| common.equipment | MyLoanListAssembler | ログインしている人の分の一覧を作る（今借りている貸出履歴・備品・種別を、テーブルごとに読んで突き合わせる） | B-01・B-04 |
| common.calendar | ReminderCalendar#isReminderPassed | 今月の催促の日時を過ぎたか（common.md 3.18） | B-01 |
| common.validation・common.error | LoanExists・LoanBorrowedBySelf・LoanNotReturned・LoanEquipmentManaged、ServiceErrorType.Forbidden・ForbiddenException | 貸出履歴のチェックと、403 の返し方（common.md 3.20。B-04 も使う） | B-03・B-04 |

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
| 5 | 同じルール | 返却のルール（自分の分だけ返せる、返却日は今日、最終確認日を更新する、行を押さえる順は貸出履歴 → 備品） | equipment.management の C-07・C-08、equipment.mine の B-02 | C-07・C-08・B-02 の詳細設計を書くとき、同じにする |

## 4. 設計書にない判断

まとまり全体にかかわる判断。B-01 の判断は B-01_自分の備品の一覧.md の12章。

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | S-05・S-06 の URL は、画面の詳細設計（ZPOP-107・108）で決める | 画面一覧 2章で確かめる | いいえ | ― |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-16 | 初版（ZPOP-63。B-01 の分） |
| v1.1 | 2026-11-23 | ZPOP-65：B-03 の分を足した（1.1 のリンク、2.1 のクラス・dao・共通部品、3章の No.4・5） |
