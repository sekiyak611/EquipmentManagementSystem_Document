# 詳細設計：権限管理（api.role）

| 項目 | 内容 |
|---|---|
| 版 | v1.1 2026-11-28 |
| Jira | ZPOP-95（H-02）、ZPOP-99（H-06） |
| 状態 | 作成中（H-02・H-06 の分だけ。ほかの API・画面は、それぞれの詳細設計の工程で足す） |
| もとにした設計書 | 機能一覧.md v1.2 の4章（F-14・F-15）・8章、API設計.md v1.5 の3.8、データ設計.md v1.0 の2章・5.2〜5.4、権限の対応表.md v1.1 の6章 |

## 1. 概要

写したもと：機能一覧.md v1.2 の4章（F-14・F-15）

- F-14 権限一覧：権限と、それぞれに含まれる権限項目を見る（総務。権限項目「権限を見る」）
- F-15 権限登録/編集/削除：権限項目にチェックを付けて、権限を作る・変える・消す。ルールは8章（総務。権限項目「権限を管理する」）

### 1.1 API一覧

写したもと：API設計.md v1.5 の3.8。このファイルには、詳細設計を書いた API だけを載せる（H-01・H-03〜H-05 は、それぞれの詳細設計の工程で足す）。

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | パッケージ（クラス名の頭） | 詳細設計 |
|---|---|---|---|---|---|---|---|
| H-02 | GET | /api/roles/{権限のID} | 権限1つを返す | PERMISSION_VIEW、PERMISSION_MANAGE のどちらか | S-17（編集） | api.role.search.itemdetails（RoleSearchItemDetails） | [H-02_権限1つを返す.md](H-02_権限1つを返す.md) |
| H-06 | GET | /api/permissions | 権限項目の一覧（18件） | PERMISSION_VIEW、PERMISSION_MANAGE のどちらか | S-17 | api.role.search.itemlist（RoleSearchItemList） | [H-06_権限項目の一覧.md](H-06_権限項目の一覧.md) |

### 1.2 画面一覧

なし（H-02・H-06 は API だけ。S-16・S-17 は、画面の詳細設計の工程で足す）

### 1.3 業務のルール

写したもと：機能一覧.md v1.2 の8章、データ設計.md v1.0 の2章、API設計.md v1.5 の3.8（権限の対応表.md v1.1 の6章は、確認待ちの案なので、写したもとにしない）

| No. | ルール | 写したもと |
|---|---|---|
| R-1 | 権限項目の一覧はプログラムで決めておき、画面からは増やせない。プログラムが「この操作をしてよいか」を確かめるときに使う名前のため、項目を増やすにはプログラムの修正が要る。 | 機能一覧 8章の1 |
| R-2 | ユーザには権限を1つだけ割り当てる。 | 機能一覧 8章の2 |
| R-3 | ユーザに割り当てられている権限は削除できない。 | 機能一覧 8章の3 |
| R-4 | 「権限を管理する」を持つユーザが0人になる変更はできない（だれも権限を直せなくなるのを防ぐ）。 | 機能一覧 8章の4 |
| R-5 | ユーザの権限を選べる・変えられるのは、「権限を管理する」を持つ人だけ。「ユーザを編集する」だけの人が、自分の権限を上げられないようにするため。 | 機能一覧 8章の5 |
| R-6 | 「権限を管理する」を持たない人がユーザを登録すると、一般社員の権限が付く。そのため、一般社員の権限は削除できない。 | 機能一覧 8章の6 |
| R-7 | 権限の変更は、その権限を持つ人の次の操作から効く（ログインし直さなくてよい。60日間ログインしたままの人がいるため）。 | 機能一覧 8章の7 |
| R-8 | 論理削除。deleted_at（削除した日時）に値が入っている行は「削除済み」とみなす。 | データ設計 2章 |
| R-9 | 権限を1つ読む API（H-02）と、権限項目の一覧の API（H-06）は、PERMISSION_VIEW か PERMISSION_MANAGE のどちらかを持っていれば呼べる（S-17 を開ける人が、中の読み込みで 403 にならないように） | API設計 3.8 |

H-02 で使うのは R-1（返すコードは18個の権限項目のどれか）・R-7（権限のデータは、毎回読み直す。H-02 は覚えておかない）・R-8・R-9。H-06 で使うのは R-1（返すのは最初に入れた18件）・R-9。ほかは H-03〜H-05 で使う。

### 1.4 定期実行

なし

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。名前の付け方は CLAUDE.md 5章の命名規則。H-02・H-06（Server）の分を書く。

### 2.1 Server

API ごとのパッケージ（api.role の下。その中を controller・service・model に分ける。業務チェックがないので validator は作らない。受け取る本文がないので RestInDto は作らない。CLAUDE.md 4.1）

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| api.role.search.itemdetails.controller | RoleSearchItemDetailsController | H-02 の入口。パスの id から ServiceInDto を作る | H-02 |
| api.role.search.itemdetails.service | RoleSearchItemDetailsService（interface）・RoleSearchItemDetailsServiceImpl | H-02 の業務の処理（`@Service`。`@Transactional(readOnly = true)` を付ける） | H-02 |
| 〃 | RoleSearchItemDetailsServiceInDto | H-02 で Service に渡す値（id）と、権限があるかのチェック | H-02 |
| api.role.search.itemdetails.model | RoleSearchItemDetailsRestOutDto | H-02 で返す、権限1つ | H-02 |
| （テスト）api.role.search.itemdetails | RoleSearchItemDetailsApiTest | H-02 のテスト | H-02 |
| api.role.search.itemlist.controller | RoleSearchItemListController | H-06 の入口 | H-06 |
| api.role.search.itemlist.service | RoleSearchItemListService（interface）・RoleSearchItemListServiceImpl | H-06 の業務の処理（`@Service`。受け取る値がないので ServiceInDto は作らない。`@Transactional` は付けない） | H-06 |
| api.role.search.itemlist.model | RoleSearchItemListRestOutDto | H-06 で返す、権限項目1件（code・name・group） | H-06 |
| （テスト）api.role.search.itemlist | RoleSearchItemListApiTest | H-06 のテスト | H-06 |

使う dao（作らない。MyBatis Generator が作ったもの）

| パッケージ | クラス・ファイル | 使い方 | 使う API |
|---|---|---|---|
| dao.mapper | RoleMapper（XML は src/main/resources/jp/co/highjunk/equipment/dao/mapper/） | roles を読む | H-02 |
| dao.mapper | RolePermissionMapper | role_permissions を読む | H-02 |
| dao.mapper | PermissionMapper | permissions を読む（H-02 は並び順のため。H-06 は一覧そのもの） | H-02、H-06 |
| dao.entity | Role、RoleExample、RolePermission、RolePermissionExample、Permission、PermissionExample | テーブルの1行の形と、取得の条件 | H-02、H-06 |
| dao.mapper.custom | なし | | |

足す共通部品（common。足すことは 2026-11-28 に人が決めた。実装の前に、もう1人に伝えて、その部品だけの小さな MR を先に main に入れる。詳細設計 common.md 5章の「今あるチェック用アノテーション」の一覧にも1行足す。CLAUDE.md 9章）

| パッケージ | クラス | 役割 | 使う API |
|---|---|---|---|
| common.validation | RoleExists（中身は RoleExistsCheck） | 削除されていない権限があるか（H-02 は、行を押さえない） | H-02（H-03〜H-05・G-03・G-04 でも使う予定） |

### 2.2 Client

なし（H-02・H-06 は API だけ。S-17 の画面の詳細設計の工程で書く）

### 2.3 足す Enum（common.constant）

なし（PermissionCode は、すでにある。変えない）

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.error.ApiResponse | 成功の返す値を ok で包む（API設計 2.4 の形） |
| common.security（SecurityConfig・LoginRefreshFilter） | ログインしていなければ 401 を返す。Controller の `@PreAuthorize("hasAnyAuthority('PERMISSION_VIEW', 'PERMISSION_MANAGE')")` が、権限がなければ 403 を返す |
| common.validation（ServiceInDtoChecker・ServiceCheckOrder・ServiceErrorType） | ServiceInDto のチェックと、守れないときの 404 への変え方 |
| common.error.NotFoundException | ServiceInDtoChecker が、payload：NotFound の誤りから作る |

## 3. ほかのまとまりへの影響

| No. | 種類 | 内容 | 相手（まとまり・部品） | 対応 |
|---|---|---|---|---|
| 1 | common に足す | common.validation に `@RoleExists`（RoleExistsCheck）を足す | common（もう1人と共有） | 実装の前に、もう1人に伝え、その部品だけの小さな MR を先に main に入れる。詳細設計 common.md 5章の一覧にも1行足し、同じ MR に入れる（CLAUDE.md 9章）。H-03〜H-05・G-03・G-04 も同じ部品を使う |
| 2 | 同じテーブルを読む | role_permissions・roles・permissions を、ログイン中の人の権限項目を作る処理が読んでいる | common.security（LoginUserInfoAssembler。A-03） | 読むだけなので、対応なし。権限項目の持ち方（テーブルの形）を変えるときは、ここも直す |
| 3 | 同じ形にそろえる | 権限項目のコードの並び順（permissions.sort_order）を、H-01（含む権限項目）・H-06（権限項目の一覧）と同じにする | api.role（H-01・H-06） | H-06 は、同じ順にそろえた（H-06 の5章 No.1）。H-01 の詳細設計で、同じ順にそろえる |
| 4 | この API を使う画面 | S-17（編集）が、H-02 の返す値（H-02 の3章の形）と H-06 の返す値（H-06 の3章の形。code・name・group）をつないで、チェックを付ける。「説明」は name で足りる扱い（H-06 の12章の No.1） | role の画面（S-17。これから作る） | 返す値の形を変えるときは、使っている画面も直す |
| 5 | Flyway・Enum | 変更なし | ― | 対応なし |

## 4. 設計書にない判断

なし（H-02 の判断は、[H-02_権限1つを返す.md](H-02_権限1つを返す.md) の12章。H-06 の判断は、[H-06_権限項目の一覧.md](H-06_権限項目の一覧.md) の12章）

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-28 | 初版（ZPOP-95。H-02 の分） |
| v1.1 | 2026-11-28 | H-06 の分を足した（ZPOP-99。版・Jira・状態、1.1・1.2・1.3、2章の頭の文・2.1・2.2、3章、4章） |
