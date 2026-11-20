---
name: backend-impl
description: 備品管理システムのサーバー（EquipmentManagementSystem_Server。Spring Boot）で、Jiraのタスク1つ分のAPI・業務のルール・SQLを作る、または直すときの手順。設計書を読み、詳細設計を書いてから実装し、組み立て（コンパイル）が通るところまで行う。テストは backend-test で書く。
when_to_use: 「ZPOP-33 を実装して」「種別管理のAPIを作って」「サーバーのこの不具合を直して」のように、Server のコードを作る・直す依頼のとき。テストを書く・動かす依頼は backend-test。
argument-hint: "[タスク名かJiraの課題キー（例：種別管理、ZPOP-33）]"
---

# バックエンド実装（Server）

対象のタスク：$ARGUMENTS

（空なら、人に Jira の課題キーとタスク名を聞く。タスク名は、証跡のフォルダとプルリクエストの名前に使う。決め方は deliver の skill。）

この skill には、作業の順番とチェック表だけを書く。決まりの正本は Document の `internaldesign/CLAUDE.md` と設計書。この skill と食い違ったら CLAUDE.md・設計書に従い、食い違っていることを人に知らせる。CLAUDE.md・設計書に書いていない所の書き方は、implementation-guidelines の skill（Document の `.claude/skills/implementation-guidelines/SKILL.md`）を参考にする。

1つのタスクは、人が `/backend-impl` → `/backend-test` → `/backend-review` → `/deliver` の順に呼んで進める（CLAUDE.md 4.4）。この skill はテストを書かず、終わったら次の skill を人に案内する。

## 0. 始める前に確かめる

- [ ] 共通の決まり（CLAUDE.md）が読み込めている。読み込めていなければ、作業を始めずに人に知らせる。
- [ ] Server の `.claude/rules/java.md` を読んだ（対象のファイルを触ると自動で読み込まれる。読み込まれていなければ先に読む。この skill が「CLAUDE.md 4.1・5章」などと呼ぶ決まりの本体）。
- [ ] Document のフォルダを読み書きできる（`--add-dir ../EquipmentManagementSystem_Document`）。
- [ ] 同じタスクで画面も作るなら、Client のフォルダも読み書きできる（`/add-dir ../EquipmentManagementSystem_Client`）。このタスクは、最後まで同じリポジトリで起動して進める（CLAUDE.md 7章）。
- [ ] 自分の担当の機能か（Document の `internaldesign/実装タスク一覧.md` の分担と Jira の担当者）。担当でなければ、止めて人に確かめる。
- [ ] 「先にやるタスク」（実装タスク一覧.md）が終わっている。終わっていなければ、人に知らせる。
- [ ] 作業用のブランチ（`feature/<課題キー>-<英語の機能名>`。release/main から。3つのリポジトリとも同じ名前）で作業している。マージ・release/main への push・強制 push はしない（CLAUDE.md 7章）。
- [ ] 作業の続きなら、ブランチの `git diff` と詳細設計を読んで続きから始める（あれば `output/<タスク名>/作業メモ.md` も）。作業メモは、会話を分けるときだけ作る。

## 1. 設計書を読む

タスクの「もとにする設計書」をすべて読む。少なくとも次を見る。

| 読むもの（Document の中） | 見る所 |
|---|---|
| internaldesign/API設計.md | そのAPIのURL・操作・必要な権限項目・送る値・返す値・エラー。2章（共通の決まり）、6章（設定値）、7章（ログ） |
| externaldesign/画面設計.md | その画面の入力チェックとメッセージ（サーバー側でも同じチェックをするため） |
| externaldesign/データ設計.md | 使うテーブルの列と制約。5.3（権限項目のコード） |
| externaldesign/機能一覧.md | 業務のルール |
| internaldesign/詳細設計/ | common.md（使える共通部品）、お手本（作り直した equipment/category/）、このまとまりのフォルダ（あれば） |
| internaldesign/パッケージ構成変更/API_パッケージとクラス名_決定版.md | 作る API のパッケージ名とクラス名の頭（`<頭>`） |

次に、今のコードを調べる：お手本のコード（`api.equipment.category`。業務チェック（Validator）は `api.equipment.management.entry.item`・`api.auth.login`）、使う common の部品（common.validation のチェック用アノテーションを含む）、使う dao の Mapper と Example、同じルールを書いているほかのまとまり（貸出：equipment.mine・equipment.management（取込を含む）、確認：equipment.mine・equipment.management）。

設計書があいまい、または設計書どうしが食い違うときは、**実装を止めて人に質問する**（CLAUDE.md 2章）。推測で進めない。質問には「どの設計書の何章と何章が、どう食い違うか」と「考えられる案」を書く。

外から見える判断（返す値・エラー・画面の文・移り方）や食い違いが出たときは、spec-check の skill の形（確定／推測／未確定）で整理して、実装の前にまとめて人に質問する（CLAUDE.md 2章）。

## 2. 詳細設計を書く

detailed-design の skill に従って、`internaldesign/詳細設計/<まとまりのフォルダ>/`（例：`equipment/category/`）に、まとまり全体（`<まとまりの名前>.md`）と、作る API ごとのファイル（`<APIのID>_<短い名前>.md`）を書く（あれば書き足す）。

「設計書にない判断」に、外から見た動き（返す値、エラー、メッセージなど）を変える項目が出たら、実装の前に人に確かめる（まとめて1回で質問し、推奨案を付ける。CLAUDE.md 2章）。それ以外は、そのまま実装に進む。

## 3. 作る

**置き場所**（CLAUDE.md 4.1。パッケージの頭の `jp.co.highjunk.equipment` は省く。`<頭>` は API_パッケージとクラス名_決定版.md のクラス名の頭）

| 作るもの | 置き場所 |
|---|---|
| API のクラス | その API のパッケージ（例：`api/equipment/category/update/item/`）の中を controller・service・validator・model に分けて置く（CLAUDE.md 4.1）。controller に `<頭>Controller`・`<頭>RestInDto`、service に interface の `<頭>Service`・中身の `<頭>ServiceImpl`（`@Service`）・`<頭>ServiceInDto`、model に `<頭>RestOutDto`、validator に `<頭>Validator`（`@Component`）・`<頭>ValidatorDto`。受け取る値・業務チェック・返す値がなければ、そのクラス（とパッケージ）は作らない |
| Mapper・テーブルの形・Example | 作らない。`dao.mapper`・`dao.entity` にある、MyBatis Generator が作ったものを使う。手で直さない。テーブルが変わったら作り直す（`.\gradlew.bat mybatisGenerator`。2人で相談してから。CLAUDE.md 9章） |
| 自動で作れない SQL（件数をまとめる SQL など） | `dao/mapper/custom/` に手で書く Mapper、XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/`。作る前に、Example では書けない理由を作業メモに書く |
| 自作のチェック用アノテーション | `common/validation/`（common の部品なので、新しく足すときは止めて人に相談する。CLAUDE.md 4.1・9章）。すでにあるものは使ってよい |
| Enum（決まった値だけを持つ型） | `common/constant/`。新しく足すだけなら作業の中で足してよい（作業メモの「確認してほしい点」に書く）。すでにある Enum を変えるときは、止めて人に相談する（CLAUDE.md 9章） |
| 2つ以上の API で使う処理、API でない処理 | common に置く（CLAUDE.md 4.1）。common の部品なので、止めて人に相談する |
| テーブルの変更（Flyway のファイル） | 作らない。必要になったら止めて人に相談する（CLAUDE.md 9章） |
| common の部品の変更 | しない。必要になったら止めて人に相談する（CLAUDE.md 9章） |
| ライブラリを足す | しない。必要になったら人に確かめる（CLAUDE.md 3章） |

**書きながら確かめること**（細かい決まりは Server の `.claude/rules/java.md`。機械で確かめているもの――API どうしの依存、Controller が ServiceImpl・Mapper を使わない、`@PreAuthorize`、Clock、record、`@Transactional` の置き場所、JOIN・サブクエリ・`${}`――は `ArchitectureTest`・`MapperXmlRulesTest` が確かめる。ここには、人の判断が要るものだけを書く）

- [ ] 業務のルールは ServiceImpl に書き、Controller は、受け取る・ServiceInDto を作る・Service（interface）を呼ぶ・返すだけ。
- [ ] 確かめることを3つに分けた：形式のチェック＝RestInDto（`@Valid`。メッセージは画面設計の文のまま）、DB と照らして分かるもの＝ServiceInDto（common.validation。読むだけ）、ServiceImpl が読んだ・計算した値が要るもの＝Validator（`@Transactional` の中で、書き換えの前に呼ぶ）。
- [ ] 返す値は `<頭>RestOutDto` を `ApiResponse` で包む（dao.entity をそのまま返さない。自分で JSON を組み立てない）。
- [ ] 必要な権限項目（データ設計 5.3）を `@PreAuthorize` に書いた。ID を受け取る API は、その人が操作してよい対象かを ServiceInDto のチェックで確かめた（IDOR）。
- [ ] 2つ以上の書き換えは ServiceImpl の `@Transactional`、Slack の送信はその外（書き込みが確定してから）。
- [ ] ループの中で Mapper を呼んでいない（N+1。`IN` でまとめて読む）。一覧・検索で削除済みの行を出さない。編集する API は version で 409。
- [ ] 変えられる値（時刻・期限・回数）は設定にした。ログにパスワード・合言葉・トークンを出さない。
- [ ] 貸出・確認のルールを変えたら、ほかのまとまり（equipment.mine・equipment.management）の同じルールも直した（テストは backend-test で直す）。
- [ ] タスクに関係のない所を、ついでに変えていない。気づいた不具合は、報告の「確認してほしい点」に書く。

足した・変えた・消したファイルは、`git status` で確かめる（変更ファイル一覧は作らない）。

## 4. 組み立てが通ることを確かめる

Server のフォルダで、本体とテストのコードが組み立てられること（コンパイルが通ること）を確かめる。テストはまだ動かさない（backend-test で動かす）。

```
./gradlew testClasses      （PowerShell なら .\gradlew.bat testClasses）
```

すでにあるテストが組み立てられなくなったら（クラスの名前や場所を変えたときなど）、テストの import などの最小限の直しだけをして、作業メモに書く。

## 5. 詳細設計とコードを突き合わせる

- [ ] まとまり全体の2章（クラス・ファイル構成）と、API詳細の2.5（ServiceInDto）・4章（処理フロー）・6章（バリデーション）・7章（DB操作）・8章（トランザクション）・9章（エラー）・10章（認証・認可）が、作ったコードと同じ（detailed-design の skill の5章）。
- [ ] 作りの途中で変えた所は、詳細設計も直した（版と変更履歴も）。

## 6. 作業記録を書いて、人に報告する

- [ ] `git status`・`git diff` で、変えたファイルが、このタスクの対象だけ。
- [ ] 「確認してほしい点」（設計書にない判断を、確定／推測／未確定に分けて）を、人への報告に書いた（会話を分けるときだけ、`output/<タスク名>/作業メモ.md` にも書く）。

人には短く書く：作ったもの、詳細設計の場所、確認してほしい点、次にすること（`/backend-test <タスク名>`）。
