# API のパッケージとクラス名（決定版）

2026-11-15。もとにした資料：API一覧_パッケージ整理用.md（人が編集した版）、API設計.md 3章。

## 1. 決まったこと

| 項目 | 決めたこと |
|---|---|
| 全体の形 | API は `jp.co.highjunk.equipment.api` の下に置く。`dao`（Mapper とテーブルの形）、`common`（共通部品）、`batch`（API ではない処理）は `api` の外 |
| パッケージ名 | 英小文字だけ。言葉はつなげて書く（例：`itemformanager`）。ハイフン・スラッシュは使わない |
| 取込 | `import` は Java の予約語で使えないので、`importer` にする |
| クラス名 | パッケージの `api` より後ろを全部つなげ、言葉の頭を大文字にする（例：`api.equipment.management.update.itemformanager` → `EquipmentManagementUpdateItemForManager`）。そのあとに役割を付ける |
| 役割 | `Controller`、`Service`（interface）、`ServiceImpl`、`RestInDto`（受け取る値の形式チェック）、`ServiceInDto`（DB との整合性と Enum のチェック） |
| A-01〜A-08 | パッケージは下の表のとおりにし、新しい書き方（RestInDto・ServiceInDto・Lombok）で作り直す |
| Mapper | `jp.co.highjunk.equipment.dao.mapper`（全 API で共通）。テーブルの形と Example（Criteria）は `dao.entity`。MyBatis Generator が作る |
| API ではない処理 | Slack 催促の定期実行は `jp.co.highjunk.equipment.batch.reminder` |

```
jp.co.highjunk.equipment
├─ api
│  ├─ auth        login、logout、me、passwordresetrequests、passwordtokens.verify/use、update.password
│  ├─ health
│  ├─ equipment
│  │  ├─ mine         自分の備品（社員向け）
│  │  ├─ management   備品・貸出履歴・確認の一括更新・取込（総務向け）
│  │  ├─ reminder     催促履歴
│  │  └─ category     種別
│  ├─ user
│  └─ role
├─ batch
│  └─ reminder    Slack 催促の定期実行
├─ dao
│  ├─ mapper      MyBatis Generator が作る Mapper（テーブルごと）
│  └─ entity      テーブルの1行の形と Example（Criteria）
└─ common         今のまま
```

## 2. API ごとのパッケージとクラス名

パッケージの頭の `jp.co.highjunk.equipment.` は省いた。クラス名の列は頭の部分だけ（例：`AuthLogin` → `AuthLoginController`、`AuthLoginService`、`AuthLoginServiceImpl`、`AuthLoginRestInDto`、`AuthLoginServiceInDto`）。

| No. | 操作 | URL | 内容 | 分類 | パッケージ | クラス名の頭 |
|---|---|---|---|---|---|---|
| A-01 | POST | /api/auth/login | ログインする | このままで | `api.auth.login` | `AuthLogin` |
| A-02 | POST | /api/auth/logout | ログアウトする | このままで | `api.auth.logout` | `AuthLogout` |
| A-03 | GET | /api/auth/me | ログインしている人の情報と権限項目を返す | このままで | `api.auth.me` | `AuthMe` |
| A-04 | POST | /api/auth/password-reset-requests | パスワード設定用のリンクを依頼する | このままで | `api.auth.passwordresetrequests` | `AuthPasswordResetRequests` |
| A-05 | POST | /api/auth/password-tokens/verify | リンクの合言葉が使えるか確かめる | このままで | `api.auth.passwordtokens.verify` | `AuthPasswordTokensVerify` |
| A-06 | POST | /api/auth/password-tokens/use | 合言葉を使って新しいパスワードを決める | このままで | `api.auth.passwordtokens.use` | `AuthPasswordTokensUse` |
| A-07 | PUT | /api/me/password | 自分のパスワードを変える | 更新 | `api.auth.update.password` | `AuthUpdatePassword` |
| A-08 | GET | /api/health | アプリとデータベースが動いているかを答える | このままで | `api.health` | `Health` |
| B-01 | GET | /api/me/loans | 自分が借りている備品の一覧と、今月の確認の案内を返す | 取得 | `api.equipment.mine.search.item` | `EquipmentMineSearchItem` |
| B-02 | POST | /api/me/loans | 備品を借りる | 登録 | `api.equipment.mine.entry.item` | `EquipmentMineEntryItem` |
| B-03 | POST | /api/me/loans/{貸出履歴のID}/return | 借りている備品を返す | 更新 | `api.equipment.mine.update.returnitem` | `EquipmentMineUpdateReturnItem` |
| B-04 | POST | /api/me/confirmations | 自分が借りている備品を「確認した」にする（1件でも、まとめてでも） | 更新 | `api.equipment.mine.update.item` | `EquipmentMineUpdateItem` |
| B-05 | GET | /api/me/available-equipment | 借りられる備品（管理中・保管中）を探す | 取得 | `api.equipment.mine.search.availableitem` | `EquipmentMineSearchAvailableItem` |
| C-01 | GET | /api/equipment | 備品を探す（絞り込み・並び替え・ページ分け） | 取得 | `api.equipment.management.search.item` | `EquipmentManagementSearchItem` |
| C-02 | GET | /api/equipment/{備品のID} | 備品1件と、その備品の貸出履歴（新しい順に5件）を返す | 取得 | `api.equipment.management.search.itemdetails` | `EquipmentManagementSearchItemDetails` |
| C-03 | POST | /api/equipment | 備品を登録する | 登録 | `api.equipment.management.entry.item` | `EquipmentManagementEntryItem` |
| C-04 | PUT | /api/equipment/{備品のID} | 備品を変える | 更新 | `api.equipment.management.update.item` | `EquipmentManagementUpdateItem` |
| C-05 | DELETE | /api/equipment/{備品のID} | 備品を削除する | 削除 | `api.equipment.management.delete.item` | `EquipmentManagementDeleteItem` |
| C-06 | POST | /api/equipment/{備品のID}/confirmation | 備品を「確認した」にする | 更新 | `api.equipment.management.update.confirmationitem` | `EquipmentManagementUpdateConfirmationItem` |
| C-07 | POST | /api/equipment/{備品のID}/loans | 総務が、ほかの人の貸出を登録する | 登録 | `api.equipment.management.entry.itemformanager` | `EquipmentManagementEntryItemForManager` |
| C-08 | POST | /api/equipment/{備品のID}/return | 総務が、返却を登録する | 更新 | `api.equipment.management.update.itemformanager` | `EquipmentManagementUpdateItemForManager` |
| D-01 | GET | /api/loans | 貸出履歴を探す | 取得 | `api.equipment.management.search.history` | `EquipmentManagementSearchHistory` |
| D-02 | PUT | /api/loans/{貸出履歴のID} | 貸出履歴を直す | 更新 | `api.equipment.management.update.history` | `EquipmentManagementUpdateHistory` |
| D-03 | DELETE | /api/loans/{貸出履歴のID} | 貸出履歴を取り消す | 削除 | `api.equipment.management.delete.history` | `EquipmentManagementDeleteHistory` |
| E-01 | GET | /api/confirmation-csv/template | テンプレートをダウンロードする | 作成 | `api.equipment.management.create.template` | `EquipmentManagementCreateTemplate` |
| E-02 | POST | /api/confirmation-csv | 確認日を入れたCSVを取り込む | 取込 | `api.equipment.management.importer.confirmation` | `EquipmentManagementImporterConfirmation` |
| E-03 | GET | /api/reminder-runs/latest | 直近の催促の結果（人数・成功・失敗）を返す | 取得 | `api.equipment.reminder.search.item` | `EquipmentReminderSearchItem` |
| E-04 | GET | /api/reminder-logs | 催促の宛先ごとの記録を探す | 取得 | `api.equipment.reminder.search.itemdetails` | `EquipmentReminderSearchItemDetails` |
| K-01 | GET | /api/categories | 種別の一覧（使っている備品の数つき） | 取得 | `api.equipment.category.search.item` | `EquipmentCategorySearchItem` |
| K-02 | POST | /api/categories | 種別を追加する | 登録 | `api.equipment.category.entry.item` | `EquipmentCategoryEntryItem` |
| K-03 | PUT | /api/categories/{種別のID} | 種別を変える | 更新 | `api.equipment.category.update.item` | `EquipmentCategoryUpdateItem` |
| K-04 | DELETE | /api/categories/{種別のID} | 種別を消す | 削除 | `api.equipment.category.delete.item` | `EquipmentCategoryDeleteItem` |
| G-01 | GET | /api/users | ユーザを探す | 取得 | `api.user.search.item` | `UserSearchItem` |
| G-02 | GET | /api/users/{ユーザのID} | ユーザ1人を返す | 取得 | `api.user.search.itemdetails` | `UserSearchItemDetails` |
| G-03 | POST | /api/users | ユーザを登録する。パスワード設定用のリンクをDMで送る | 登録 | `api.user.entry.item` | `UserEntryItem` |
| G-04 | PUT | /api/users/{ユーザのID} | ユーザを変える | 更新 | `api.user.update.item` | `UserUpdateItem` |
| G-05 | DELETE | /api/users/{ユーザのID} | ユーザを削除する | 削除 | `api.user.delete.item` | `UserDeleteItem` |
| G-06 | POST | /api/users/{ユーザのID}/password-link | パスワード設定用のリンクを送り直す | 更新 | `api.user.update.itempassword` | `UserUpdateItemPassword` |
| G-07 | GET | /api/users/options | 借用者を選ぶための候補を、氏名かメールアドレスで探す | 取得 | `api.user.search.itemlist` | `UserSearchItemList` |
| H-01 | GET | /api/roles | 権限の一覧（含む権限項目・人数つき） | 取得 | `api.role.search.item` | `RoleSearchItem` |
| H-02 | GET | /api/roles/{権限のID} | 権限1つを返す | 取得 | `api.role.search.itemdetails` | `RoleSearchItemDetails` |
| H-03 | POST | /api/roles | 権限を作る | 登録 | `api.role.entry.item` | `RoleEntryItem` |
| H-04 | PUT | /api/roles/{権限のID} | 権限を変える | 更新 | `api.role.update.item` | `RoleUpdateItem` |
| H-05 | DELETE | /api/roles/{権限のID} | 権限を消す | 削除 | `api.role.delete.item` | `RoleDeleteItem` |
| H-06 | GET | /api/permissions | 権限項目の一覧（18件） | 取得 | `api.role.search.itemlist` | `RoleSearchItemList` |
| I-01 | POST | /api/imports/users | ユーザのCSVを取り込む | 取込 | `api.user.importer.item` | `UserImporterItem` |
| I-02 | POST | /api/imports/equipment | 備品のCSVを取り込む | 取込 | `api.equipment.management.importer.item` | `EquipmentManagementImporterItem` |
| I-03 | POST | /api/imports/loans | 今貸出中の情報のCSVを取り込む | 取込 | `api.equipment.management.importer.itemonloan` | `EquipmentManagementImporterItemOnLoan` |

## 3. 作り直しの前に決めたこと（2026-11-15）

| No. | 項目 | 決めたこと |
|---|---|---|
| 1 | 返す値のクラス名 | `<頭>RestOutDto`（例：`EquipmentManagementSearchItemRestOutDto`）。あとで変わるかもしれない |
| 2 | MyBatis Generator で作れない SQL | 手で書く Mapper を `jp.co.highjunk.equipment.dao.mapper.custom` に置く（XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/`）。自動で作り直しても消えない |
| 3 | S-18（一括登録）の画面の置き場所 | **未定**。1つの画面のまま `features/importer/` に置く案と、画面を分ける案がある。画面を分けるなら、画面一覧・画面設計 21章の変更が要る |
| 4 | ServiceInDto のチェックを動かす場所 | ServiceImpl の `@Transactional` の中で、Bean Validation で確かめる |
