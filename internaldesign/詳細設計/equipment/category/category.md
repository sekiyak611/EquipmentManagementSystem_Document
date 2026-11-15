# 詳細設計：種別管理（api.equipment.category）

| 項目 | 内容 |
|---|---|
| 版 | v2.1 2026-11-15 |
| Jira | ZPOP-83（K-01）、ZPOP-84（K-02）、ZPOP-85（K-03）、ZPOP-86（K-04）、ZPOP-115（S-13） |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.0 の4章（F-21）、API設計.md v1.2 の2.4・2.5・2.7・3.6・7章、画面設計.md v1.3 の1.2・16章、画面一覧.md v1.0 の2章・4章・7章、データ設計.md v1.0 の2章・5.3・5.5・5.6 |

## 1. 概要

写したもと：機能一覧.md v1.0 の4章（F-21）

種別（名前と頭文字）を見る・追加する・変える・消す。名前は必須。頭文字は任意で、半角の英大文字1文字、ほかの種別と重複できない。備品で使われている種別は削除できない

### 1.1 API一覧

写したもと：API設計.md v1.2 の3.6

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | パッケージ（クラス名の頭） | 詳細設計 |
|---|---|---|---|---|---|---|---|
| K-01 | GET | /api/categories | 種別の一覧（使っている備品の数つき） | ログイン | S-06・S-07の絞り込み、S-09の選択、S-13 | api.equipment.category.search.item（EquipmentCategorySearchItem） | [K-01_種別一覧.md](K-01_種別一覧.md) |
| K-02 | POST | /api/categories | 種別を追加する | CATEGORY_MANAGE | S-13 | api.equipment.category.entry.item（EquipmentCategoryEntryItem） | [K-02_種別を追加する.md](K-02_種別を追加する.md) |
| K-03 | PUT | /api/categories/{種別のID} | 種別を変える | CATEGORY_MANAGE | S-13 | api.equipment.category.update.item（EquipmentCategoryUpdateItem） | [K-03_種別を変える.md](K-03_種別を変える.md) |
| K-04 | DELETE | /api/categories/{種別のID} | 種別を消す | CATEGORY_MANAGE | S-13 | api.equipment.category.delete.item（EquipmentCategoryDeleteItem） | [K-04_種別を消す.md](K-04_種別を消す.md) |

### 1.2 画面一覧

写したもと：画面一覧.md v1.0 の2章・7章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-13 | 種別管理 | /categories | 総務（権限項目「種別を管理する」） | いいえ（PCだけ） | [S-13_種別管理.md](S-13_種別管理.md) |

### 1.3 業務のルール

写したもと：機能一覧.md v1.0 の4章、画面設計.md v1.3 の16章、データ設計.md v1.0 の2章

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 名前は必須 | 機能一覧 4章（F-21） |
| R-2 | 頭文字は任意で、半角の英大文字1文字、ほかの種別と重複できない | 機能一覧 4章（F-21） |
| R-3 | 備品で使われている種別は削除できない | 機能一覧 4章（F-21） |
| R-4 | 頭文字の順に並べ、頭文字がないものは後ろに名前の順で並べる | 画面設計 16章 |
| R-5 | 使っている備品の数（削除されていない備品） | 画面設計 16章 |
| R-6 | 論理削除。deleted_at（削除した日時）に値が入っている行は「削除済み」とみなす | データ設計 2章 |

K-01 で使うのは R-4〜R-6。K-02・K-03 で使うのは R-1・R-2・R-6。K-04 で使うのは R-3・R-5・R-6。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則。K-01〜K-04（Server）と S-13（Client）の分を書く。

### 2.1 Server

API ごとのパッケージ（api.equipment.category の下。その中を controller・service・model に分ける。業務チェックがないので validator は作らない。CLAUDE.md 4.1）

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| api.equipment.category.search.item.controller | EquipmentCategorySearchItemController | K-01 の入口 | K-01 |
| api.equipment.category.search.item.service | EquipmentCategorySearchItemService（interface）・EquipmentCategorySearchItemServiceImpl | K-01 の業務の処理（`@Service`） | K-01 |
| api.equipment.category.search.item.model | EquipmentCategorySearchItemRestOutDto | K-01 で返す1件 | K-01 |
| api.equipment.category.entry.item.controller | EquipmentCategoryEntryItemController | K-02 の入口。ServiceInDto を作る | K-02 |
| api.equipment.category.entry.item.service | EquipmentCategoryEntryItemService（interface）・EquipmentCategoryEntryItemServiceImpl | K-02 の業務の処理（`@Service`、`@Transactional`） | K-02 |
| api.equipment.category.entry.item.controller | EquipmentCategoryEntryItemRestInDto | K-02 で受け取る値（name・initial）と形式のチェック。name・initial を直す | K-02 |
| api.equipment.category.entry.item.service | EquipmentCategoryEntryItemServiceInDto | K-02 で Service に渡す値と、名前・頭文字の重なりのチェック | K-02 |
| api.equipment.category.entry.item.model | EquipmentCategoryEntryItemRestOutDto | K-02 で返す、作った種別 | K-02 |
| api.equipment.category.update.item.controller | EquipmentCategoryUpdateItemController | K-03 の入口。ServiceInDto を作る | K-03 |
| api.equipment.category.update.item.service | EquipmentCategoryUpdateItemService（interface）・EquipmentCategoryUpdateItemServiceImpl | K-03 の業務の処理（`@Service`、`@Transactional`） | K-03 |
| api.equipment.category.update.item.controller | EquipmentCategoryUpdateItemRestInDto | K-03 で受け取る値（name・initial・version）と形式のチェック | K-03 |
| api.equipment.category.update.item.service | EquipmentCategoryUpdateItemServiceInDto | K-03 で Service に渡す値と、ある・version・重なりのチェック | K-03 |
| api.equipment.category.update.item.model | EquipmentCategoryUpdateItemRestOutDto | K-03 で返す、変えた種別 | K-03 |
| api.equipment.category.delete.item.controller | EquipmentCategoryDeleteItemController | K-04 の入口。ServiceInDto を作る | K-04 |
| api.equipment.category.delete.item.service | EquipmentCategoryDeleteItemService（interface）・EquipmentCategoryDeleteItemServiceImpl | K-04 の業務の処理（`@Service`、`@Transactional`） | K-04 |
| api.equipment.category.delete.item.service | EquipmentCategoryDeleteItemServiceInDto | K-04 で Service に渡す値と、ある・使われていないのチェック | K-04 |
| （テスト）api.equipment.category.search.item | EquipmentCategorySearchItemApiTest | K-01 のテスト | K-01 |
| （テスト）api.equipment.category.entry.item | EquipmentCategoryEntryItemApiTest | K-02 のテスト | K-02 |
| （テスト）api.equipment.category.update.item | EquipmentCategoryUpdateItemApiTest | K-03 のテスト | K-03 |
| （テスト）api.equipment.category.delete.item | EquipmentCategoryDeleteItemApiTest | K-04 のテスト | K-04 |
| （テスト）api.equipment.category.delete.item | EquipmentCategoryDeleteItemLockTest | K-04 の、同時に備品を足されたときの守り（FOR UPDATE・FOR SHARE）のテスト。2つのまとまりを本当に開いて確かめる | K-04 |
| （テスト）testsupport | EquipmentCategoryApiTestBase | K-02〜K-04 のテストで共通に使う値と道具（開発用のユーザでのログイン、最初のデータの種別の ID）。API ごとにパッケージが分かれるので testsupport に置く | K-02〜K-04 |

使う dao（作らない。MyBatis Generator が作ったもの。手で書く Mapper は今回足した）

| パッケージ | クラス・ファイル | 使い方 | 使う API |
|---|---|---|---|
| dao.mapper | CategoryMapper | categories を読む・足す・変える・論理削除する | K-01〜K-04 |
| dao.mapper | EquipmentMapper | 1つの種別の備品を数える（読むだけ） | K-03 |
| dao.entity | Category、CategoryExample、EquipmentExample | テーブルの1行の形と、取得の条件 | K-01〜K-04 |
| dao.mapper.custom | CategoryCustomMapper（XML は src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/） | selectByIdForUpdate（FOR UPDATE。Example では書けない） | K-04 |
| dao.mapper.custom | EquipmentCustomMapper（XML は同じ場所） | countGroupByCategoryId（GROUP BY）・countByCategoryIdForShare（FOR SHARE）。どちらも Example では書けない | K-01・K-04 |
| dao.entity.custom | CategoryEquipmentCount | countGroupByCategoryId の結果の1行（テーブルの行ではない） | K-01 |

足した共通部品（common。2026-11-15 に、お手本を作り直すときに決めた）

| パッケージ | クラス | 役割 | 使う API |
|---|---|---|---|
| common.validation | ServiceInDtoChecker | ServiceInDto を ServiceCheckOrder の順に確かめ、payload（ServiceErrorType）に合わせて common.error の例外に変える | K-02〜K-04 |
| common.validation | ServiceCheckOrder・ServiceErrorType | 確かめる順番（groups）と、返し方の印（payload） | K-02〜K-04 |
| common.validation | CategoryExists（中身は CategoryExistsCheck） | 削除されていない種別があるか（forUpdate で行を押さえる） | K-03・K-04 |
| common.validation | CategoryVersionMatches（中身は CategoryVersionMatchesCheck） | version が同じか | K-03 |
| common.validation | CategoryNameNotDuplicated・CategoryInitialNotDuplicated（中身は …Check） | 名前・頭文字が重ならないか | K-02・K-03 |
| common.validation | CategoryNotInUse（中身は CategoryNotInUseCheck） | 使っている備品がないか | K-04 |
| common.validation | CategoryChecks | 重複禁止に当たった例外を入力欄のエラーに変える。クラスに付けたチェックの誤りを入力欄に出す | K-02・K-03 |
| common.text | TextInputs | 受け取った文字の直し方（前後の空白を取る、大文字にする） | K-02・K-03 |

### 2.2 Client

src/features/equipment/category/ の下。名前の付け方は CLAUDE.md 5章の命名規則。

| ファイル | 役割 | 画面 |
|---|---|---|
| pages/CategoryListPage.tsx | S-13 の画面全体。権限の確かめ、一覧の読み込み（K-01）、ダイアログの開け閉め、削除（K-04） | S-13 |
| components/CategoryTable.tsx | 種別の一覧の表 | S-13 |
| components/CategoryFormDialog.tsx | 追加・変更のダイアログ。入力チェックと K-02・K-03 の呼び出し | S-13 |
| api.ts | getCategories（K-01）・createCategory（K-02）・updateCategory（K-03）・deleteCategory（K-04） | S-13 |
| types.ts | CategoryResponse・CategoryCreateRequest・CategoryUpdateRequest（形は Server と同じ。名前は中身が分かる名前。CLAUDE.md 5章） | S-13 |
| （テスト）tests/equipment/category/category-list.spec.ts | S-13 の画面のテスト（Playwright） | S-13 |
| （共有）src/routes.tsx | /categories の1行を足す（CLAUDE.md 9章） | S-13 |
| （共有）src/common/components/menuItems.ts | メニューに「種別管理」の1行を足す（CLAUDE.md 9章、common.md 11.4） | S-13 |

### 2.3 足す Enum（common.constant）

なし

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.error.ApiResponse | 成功の返す値を ok・created で包む（API設計 2.4 の形） |
| common.security（SecurityConfig・LoginRefreshFilter） | ログインしていなければ 401 を返す。Controller に `@PreAuthorize`（K-01 は `isAuthenticated()`、K-02〜K-04 は `hasAuthority('CATEGORY_MANAGE')`）を付ける |
| common.security.LoginUserId | K-02〜K-04 で、作った人・変えた人のユーザIDを Controller の引数（`@AuthenticationPrincipal`）で受け取り、ServiceInDto に入れる |
| common.validation（2.1 の表） | K-02〜K-04 の DB との整合性のチェックと、その返し方 |
| common.text.TextInputs | K-02・K-03 の RestInDto で、name・initial を直す |
| common.config（Clock） | K-02〜K-04 で、作った・変えた日時を時計から取る |
| common.error（NotFoundException・ConflictException・BusinessRuleException・FieldErrorException） | ServiceInDtoChecker が変える例外。K-03 で UPDATE が0件のときは ServiceImpl が ConflictException を投げる |

## 3. ほかのまとまりへの影響

| No. | 種類 | 内容 | 相手（まとまり・部品） | 対応 |
|---|---|---|---|---|
| 1 | 同じテーブルを読む | equipment（備品）を、種別ごとに数える（読むだけ） | equipment・mine・importer（これから作る） | 対応なし。備品の「削除済み」の決まり（deleted_at）が変わったら、ここの数え方も直す |
| 2 | 備品を足す機能 | K-04 で種別を消すのと同時に、その種別の備品を足されないように、備品を足す・種別を変える機能は、種別の行を FOR SHARE で読み、削除されていないことを確かめてから書き込む（K-04 の8章・12章の No.2） | equipment（C-03 備品を登録する、C-04 で種別を変えるとき）・importer（I-01〜I-03 一括登録） | それぞれの詳細設計に書き、同じように作る。C-03 は作った（equipment/management/C-03_備品を登録する.md の8章。EquipmentManagementEntryItemLockTest） |
| 3 | K-01 を使う画面 | S-06・S-07 の絞り込み、S-09 の選択、S-13 が、K-01 の返す値（K-01 の3章の形・並び順）を使う | mine・equipment・category の画面 | 返す値の形を変えるときは、使っている画面も直す。S-13 の types.ts（CategoryResponse）は category の中だけで使う（ほかの機能の画面は、自分の機能の types.ts に書く。CLAUDE.md 5章） |
| 4 | common・Flyway・Enum | K-02 のために common.error に FieldErrorException を足した。2026-11-15 の作り直しで、common.validation・common.text を足し、dao.mapper.custom・dao.entity.custom に手で書く Mapper と結果の形を足した。Flyway・Enum は変更なし | ― | 2人で相談済み（お手本の作り直しで決めた） |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | 数えた結果の型 CategoryEquipmentCount を dao.entity.custom に置く | 手で書く Mapper（dao.mapper.custom）の結果の形なので、MyBatis Generator が作る dao.entity と分けた。テーブルの名前の単数形に当てはまらないので、中身が分かる名前にした | いいえ | 済（2026-11-15。手で書く Mapper の名前を決めたとき） |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-10 | 初版（ZPOP-83。K-01 の分） |
| v1.1 | 2026-11-10 | K-02（ZPOP-84）の分を足した（1.1・1.3・2章・3章） |
| v1.2 | 2026-11-10 | K-03（ZPOP-85）の分を足した（1.1・1.3・2章）。画面設計の版を v1.2 にした |
| v1.3 | 2026-11-11 | K-04（ZPOP-86）の分を足した（1.1・1.3・2章・3章の No.2） |
| v1.4 | 2026-11-11 | S-13（ZPOP-115）の分を足した（1.2・2.2・3章の No.3）。画面設計の版を v1.3 にした |
| v1.5 | 2026-11-11 | 3章の No.2 の API の ID を直した（備品の登録は C-03、変更は C-04）。C-03 で作ったことを書いた |
| v2.0 | 2026-11-15 | パッケージ構成の変更で、api.equipment.category に作り直した（以後のお手本）。置き場所を equipment/category/ にし、1.1・2.1・2.4・3・4章を新しいクラスに合わせた。画面（S-13）と 2.2 の Client のファイルは、features を移すときに直す |
| v2.1 | 2026-11-15 | 2.2 の Client のファイルの場所を、features/equipment/category/・tests/equipment/category/ に直した |
