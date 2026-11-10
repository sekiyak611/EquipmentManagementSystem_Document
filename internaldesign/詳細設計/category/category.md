# 詳細設計：種別管理（category）

| 項目 | 内容 |
|---|---|
| 版 | v1.1 2026-11-10 |
| Jira | ZPOP-83（K-01）、ZPOP-84（K-02）。K-03・K-04（ZPOP-85・86）と S-13（ZPOP-115）は、作るときに書き足す |
| 状態 | 作成中 |
| もとにした設計書 | 機能一覧.md v1.0 の4章（F-21）、API設計.md v1.2 の2.4・2.5・2.7・3.6・7章、画面設計.md v1.1 の1.2・16章、画面一覧.md v1.0 の2章・7章、データ設計.md v1.0 の2章・5.3・5.5・5.6 |

## 1. 概要

写したもと：機能一覧.md v1.0 の4章（F-21）

種別（名前と頭文字）を見る・追加する・変える・消す。名前は必須。頭文字は任意で、半角の英大文字1文字、ほかの種別と重複できない。備品で使われている種別は削除できない

### 1.1 API一覧

写したもと：API設計.md v1.2 の3.6

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | 詳細設計 |
|---|---|---|---|---|---|---|
| K-01 | GET | /api/categories | 種別の一覧（使っている備品の数つき） | ログイン | S-06・S-07の絞り込み、S-09の選択、S-13 | [K-01_種別一覧.md](K-01_種別一覧.md) |
| K-02 | POST | /api/categories | 種別を追加する | CATEGORY_MANAGE | S-13 | [K-02_種別を追加する.md](K-02_種別を追加する.md) |
| K-03 | PUT | /api/categories/{種別のID} | 種別を変える | CATEGORY_MANAGE | S-13 | まだ（ZPOP-85） |
| K-04 | DELETE | /api/categories/{種別のID} | 種別を消す | CATEGORY_MANAGE | S-13 | まだ（ZPOP-86） |

### 1.2 画面一覧

写したもと：画面一覧.md v1.0 の2章・7章

| ID | 名前 | URL | 使う人 | スマートフォン優先 | 詳細設計 |
|---|---|---|---|---|---|
| S-13 | 種別管理 | まだ決めていない（画面を作るときに決める） | 総務（権限項目「種別を管理する」） | いいえ（PCだけ） | まだ（ZPOP-115） |

### 1.3 業務のルール

写したもと：機能一覧.md v1.0 の4章、画面設計.md v1.1 の16章、データ設計.md v1.0 の2章

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 名前は必須 | 機能一覧 4章（F-21） |
| R-2 | 頭文字は任意で、半角の英大文字1文字、ほかの種別と重複できない | 機能一覧 4章（F-21） |
| R-3 | 備品で使われている種別は削除できない | 機能一覧 4章（F-21） |
| R-4 | 頭文字の順に並べ、頭文字がないものは後ろに名前の順で並べる | 画面設計 16章 |
| R-5 | 使っている備品の数（削除されていない備品） | 画面設計 16章 |
| R-6 | 論理削除。deleted_at（削除した日時）に値が入っている行は「削除済み」とみなす | データ設計 2章 |

K-01 で使うのは R-4〜R-6。K-02 で使うのは R-1・R-2・R-6。R-3 は K-04 で使う。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則（controller と service は API 1本に1つ、mapper はテーブルごと）。作った API（K-01・K-02）の分を書く。K-03・K-04 の分は、作るときに足す。

### 2.1 Server

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| category.controller | CategoryListController | K-01 の入口 | K-01 |
| category.service | CategoryListService（インターフェース） | K-01 の業務のルールのメソッドの形（controller はこれを使う） | K-01 |
| category.service | CategoryListServiceImpl | K-01 の業務のルールの中身（`@Service`） | K-01 |
| category.controller | CategoryCreateController | K-02 の入口 | K-02 |
| category.service | CategoryCreateService（インターフェース）・CategoryCreateServiceImpl | K-02 の業務のルール（`@Service`、`@Transactional`） | K-02 |
| category.validator | CategoryValidator | 名前・頭文字がほかの種別と重ならないか（K-02・K-03 で使うので、`<機能名>Validator` にまとめた。CLAUDE.md 5章） | K-02 |
| category.model | Category | テーブル categories の1行（使う列だけ。K-02 で記録用の列を足した） | K-01・K-02 |
| category.model | CategoryEquipmentCount | 種別ごとの備品の数（数えた結果の1行。テーブルの行ではない。4章の No.1） | K-01 |
| mapper.category | CategoryMapper（インターフェース）・CategoryMapper.xml | categories を読む・足す | K-01・K-02 |
| mapper.category | EquipmentMapper（インターフェース）・EquipmentMapper.xml | equipment を種別ごとに数える（読むだけ） | K-01 |
| dto.category | CategoryResponse | 返す値の1件の形（K-01 は data にこれの配列、K-02 は1件を入れる） | K-01・K-02 |
| dto.category | CategoryCreateRequest | K-02 で受け取る値（name・initial。入力チェックの前に空白と大文字を直す） | K-02 |
| （テスト）category | CategoryListApiTest | K-01 のテスト | K-01 |
| （テスト）category | CategoryCreateApiTest | K-02 のテスト | K-02 |

- XML は src/main/resources/jp/co/highjunk/equipment/mapper/category/ に置く。
- mapper.category.EquipmentMapper は、あとで作る equipment 機能の mapper.equipment.EquipmentMapper と同じ名前になるが、部品の名前はパッケージ込みなのでぶつからない（common.md 2.3）。import するときは mapper.category のものを選ぶ（CLAUDE.md 5章）。

### 2.2 Client

なし（K-01 では作らない。S-13 のときに書く）

### 2.3 足す Enum（common.constant）

なし

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.error.ApiResponse | 成功の返す値を ok で包む（API設計 2.4 の形） |
| common.security（SecurityConfig・LoginRefreshFilter） | ログインしていなければ 401 を返す。controller に `@PreAuthorize`（K-01 は `isAuthenticated()`、K-02 は `hasAuthority('CATEGORY_MANAGE')`）を付ける |
| common.security.LoginUserId | K-02 で、作った人のユーザIDを controller の引数（`@AuthenticationPrincipal`）で受け取る |
| common.error.FieldErrorException | K-02 で、名前・頭文字の重なりを入力欄のエラー（400）として返す（common.md 6章） |
| common.config（Clock） | K-02 で、作った日時を時計から取る |

## 3. ほかの機能への影響

| No. | 種類 | 内容 | 相手（機能・部品） | 対応 |
|---|---|---|---|---|
| 1 | 同じテーブルを読む | equipment（備品）を、種別ごとに数える（読むだけ） | equipment・mine・importer（これから作る） | 対応なし。備品の「削除済み」の決まり（deleted_at）が変わったら、ここの数え方も直す |
| 2 | K-01 を使う画面 | S-06・S-07 の絞り込み、S-09 の選択、S-13 が、K-01 の返す値（K-01 の3章の形・並び順）を使う | mine・equipment・category の画面 | 返す値の形を変えるときは、使っている画面も直す |
| 3 | common・Flyway・Enum | K-02 のために common.error に FieldErrorException を足した（別のプルリクエストで先に取り込む）。Flyway・Enum は変更なし | ― | ― |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | 数えた結果の型 CategoryEquipmentCount を category.model に置く | mapper が使ってよいのは、同じ機能の model と common だけ（CLAUDE.md 5章）。model の命名規則（テーブルの名前の単数形）に当てはまらないので、中身が分かる名前にした | いいえ | まだ |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-10 | 初版（ZPOP-83。K-01 の分） |
| v1.1 | 2026-11-10 | K-02（ZPOP-84）の分を足した（1.1・1.3・2章・3章） |
