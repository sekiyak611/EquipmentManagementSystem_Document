---
name: backend-impl
description: 備品管理システムのサーバー（EquipmentManagementSystem_Server。Spring Boot）で、Jiraのタスク1つ分のAPI・業務のルール・SQLを作る、または直すときの手順。設計書を読み、詳細設計を書いてから実装し、組み立て（コンパイル）が通るところまで行う。テストは backend-test で書く。
when_to_use: 「ZPOP-33 を実装して」「種別管理のAPIを作って」「サーバーのこの不具合を直して」のように、Server のコードを作る・直す依頼のとき。テストを書く・動かす依頼は backend-test。
argument-hint: "[タスク名かJiraの課題キー（例：種別管理、ZPOP-33）]"
---

# バックエンド実装（Server）

対象のタスク：$ARGUMENTS

（空なら、人に Jira の課題キーとタスク名を聞く。タスク名は、作業記録と成果物の zip の名前に使う。決め方は deliver-zip の skill の「作業記録の形」。）

この skill には、作業の順番とチェック表だけを書く。決まりの正本は Document の `internaldesign/CLAUDE.md` と設計書。この skill と食い違ったら CLAUDE.md・設計書に従い、食い違っていることを人に知らせる。CLAUDE.md・設計書に書いていない所の書き方は、implementation-guidelines の skill（Document の `.claude/skills/implementation-guidelines/SKILL.md`）を参考にする。

1つのタスクは、人が `/backend-impl` → `/backend-test` → `/backend-review` → `/deliver-zip` の順に呼んで進める（CLAUDE.md 4.4）。この skill はテストを書かず、終わったら次の skill を人に案内する。

## 0. 始める前に確かめる

- [ ] 共通の決まり（CLAUDE.md）が読み込めている。読み込めていなければ、作業を始めずに人に知らせる。
- [ ] Document のフォルダを読み書きできる（`--add-dir ../EquipmentManagementSystem_Document`）。
- [ ] 同じタスクで画面も作るなら、Client のフォルダも読み書きできる（`/add-dir ../EquipmentManagementSystem_Client`）。このタスクは、最後まで同じリポジトリで起動して進める（CLAUDE.md 7章）。
- [ ] 自分の担当の機能か（Document の `internaldesign/実装タスク一覧.md` の分担と Jira の担当者）。担当でなければ、止めて人に確かめる。
- [ ] 「先にやるタスク」（実装タスク一覧.md）が終わっている。終わっていなければ、人に知らせる。
- [ ] 作業用のブランチ（`feature/<課題キー>`。release/main から）で作業している。マージ・release/main への push・強制 push はしない（CLAUDE.md 7章）。
- [ ] 作業記録 `output/<タスク名>/` があれば、`作業メモ.md` と `変更ファイル一覧.md` を読んで続きから始める。なければ作る（形は deliver-zip の skill の「作業記録の形」）。

## 1. 設計書を読む

タスクの「もとにする設計書」をすべて読む。少なくとも次を見る。

| 読むもの（Document の中） | 見る所 |
|---|---|
| internaldesign/API設計.md | そのAPIのURL・操作・必要な権限項目・送る値・返す値・エラー。2章（共通の決まり）、6章（設定値）、7章（ログ） |
| externaldesign/画面設計.md | その画面の入力チェックとメッセージ（サーバー側でも同じチェックをするため） |
| externaldesign/データ設計.md | 使うテーブルの列と制約。5.3（権限項目のコード） |
| externaldesign/機能一覧.md | 業務のルール |
| internaldesign/詳細設計/ | common.md（使える共通部品）、お手本（category/。まだなければ health/）、この機能のフォルダ（あれば） |

次に、今のコードを調べる：お手本のコード、使う common の部品、同じルールを書いているほかの機能（貸出：mine・equipment・importer、確認：mine・equipment・confirmation）。

設計書があいまい、または設計書どうしが食い違うときは、**実装を止めて人に質問する**（CLAUDE.md 2章）。推測で進めない。質問には「どの設計書の何章と何章が、どう食い違うか」と「考えられる案」を書く。

## 2. 詳細設計を書く

detailed-design の skill に従って、`internaldesign/詳細設計/<機能名>/` に、機能全体（`<機能名>.md`）と、作る API ごとのファイル（`<APIのID>_<短い名前>.md`）を書く（あれば書き足す）。

「設計書にない判断」に、外から見た動き（返す値、エラー、メッセージなど）を変える項目が出たら、実装の前に人に確かめる。それ以外は、そのまま実装に進む。

## 3. 作る

**置き場所**（CLAUDE.md 4.1。パッケージの頭の `jp.co.highjunk.equipment` は省く）

| 作るもの | 置き場所 |
|---|---|
| controller（APIの入口） | `<機能名>/controller/` の `<APIの名前>Controller`。API 1本に1つ（URL と操作を1つだけ書く） |
| service（業務のルール） | `<機能名>/service/` に、interface の `<APIの名前>Service` と、中身の `<APIの名前>ServiceImpl`（`@Service`）を並べて置く。API 1本に1つ |
| validator（業務チェック） | `<機能名>/validator/` の `<名前>Validator`（`@Component`）。業務チェックがない機能は作らない |
| model（テーブルの1行の形） | `<機能名>/model/` |
| mapper（データベースを読み書きする部品） | `mapper/<機能名>/` に、テーブルごとの `<テーブルの名前>Mapper`（ほかの機能に同じ名前があってよい）。SQLの XML は `src/main/resources/jp/co/highjunk/equipment/mapper/<機能名>/` |
| dto（APIで受け取る値・返す値の形） | `dto/<機能名>/` |
| Enum（決まった値だけを持つ型） | `common/constant/`。新しく足すだけなら作業の中で足してよい（作業メモの「確認してほしい点」に書く）。すでにある Enum を変えるときは、止めて人に相談する（CLAUDE.md 9章） |
| テーブルの変更（Flyway のファイル） | 作らない。必要になったら止めて人に相談する（CLAUDE.md 9章） |
| common の部品の変更 | しない。必要になったら止めて人に相談する（CLAUDE.md 9章） |
| ライブラリを足す | しない。必要になったら人に確かめる（CLAUDE.md 3章） |

**書きながら確かめること**（くわしくは CLAUDE.md 5章）

- [ ] 業務のルールは ServiceImpl に書き、controller は受け取る・service を呼ぶ・返すだけ。controller は自分の API の interface（`<APIの名前>Service`）を使い、ServiceImpl を直接使わない。（例外：ログインの開始・終了の LoginSession だけは controller から呼んでよい。CLAUDE.md 5章）
- [ ] 業務チェック（データベースの中身や業務のルールと照らして確かめるもの。例：重なり、使われているか、貸出中か、本人か）は Validator に書き、ServiceImpl から書き換えの前に呼んでいる。controller からは呼ばない。Validator は読むだけ（`select…`・`count…`）で、書き換えない。
- [ ] 返す値は `ApiResponse`（ok・created・accepted）で包む。エラーは common.error の例外（BusinessRuleException、NotFoundException、ConflictException、CsvErrorException など）を投げ、自分で JSON を組み立てない。
- [ ] すべての API に、必要な権限項目の確認（`@PreAuthorize("hasAuthority('…')")`）がある。コードはデータ設計 5.3 のもの。
- [ ] ID を受け取る API は、その人が操作してよい対象かを Validator で確かめている（IDOR を防ぐ）。
- [ ] 入力チェックを、画面設計のとおりにサーバー側でも行う（dto に `@NotBlank`・`@Size` などの印、controller の引数に `@Valid`）。メッセージは画面設計の文のまま。
- [ ] 2つ以上の書き換えを1つの操作として行う ServiceImpl のメソッドに `@Transactional` を付けた（Validator の呼び出しもこの中）。interface・controller・validator・mapper には付けない。Slack の送信はその外で、書き込みが確定してから行う。
- [ ] 今の日時は `java.time.Clock` から取る（`LocalDate.now(clock)`）。`LocalDate.now()` のように直接取らない。
- [ ] SQL は XML に書き、値は `#{}` で渡す（`${}` で文字をつなげない）。
- [ ] SQL に JOIN とサブクエリ（SQLの中にもう1つ SELECT を入れる書き方）がない。複数のテーブルはテーブルごとに読み、Java で突き合わせる。
- [ ] ループの中で mapper を呼んでいない（N+1 を防ぐ）。ID を集めて `IN`（`<foreach>`）で1回で読む。
- [ ] 一覧・検索で、削除済みの行（`deleted_at` が入っている行）を出さない。削除は論理削除。
- [ ] 編集する API は楽観ロック（`version` 列）で、ほかの人が先に保存していたら 409。
- [ ] ほかの機能の service・validator・model と、`mapper.<ほかの機能>`・`dto.<ほかの機能>` を import していない。使うのは自分の機能と common だけ。
- [ ] mapper の import が、自分の機能の `mapper.<機能名>` のものになっている（同じ名前の mapper がほかの機能にもあるため。CLAUDE.md 5章）。
- [ ] 変えられる値（時刻・期限・回数）をプログラムに直接書かず、設定にしている（API設計 6章）。
- [ ] ログに、パスワード・パスワード設定用のリンクの合言葉・Slack のトークンを出さない。
- [ ] 貸出のルール、確認のルールを変えたら、ほかの機能の同じルールも同じように直した（テストは backend-test で直す。作業メモに書いておく）。
- [ ] タスクに関係のない所を、ついでに変えていない。気づいた不具合は作業メモの「確認してほしい点」に書く。

足した・変えた・消したファイルは、そのつど `output/<タスク名>/変更ファイル一覧.md` に書く。

## 4. 組み立てが通ることを確かめる

Server のフォルダで、本体とテストのコードが組み立てられること（コンパイルが通ること）を確かめる。テストはまだ動かさない（backend-test で動かす）。

```
./gradlew testClasses      （PowerShell なら .\gradlew.bat testClasses）
```

すでにあるテストが組み立てられなくなったら（クラスの名前や場所を変えたときなど）、テストの import などの最小限の直しだけをして、作業メモに書く。

## 5. 詳細設計とコードを突き合わせる

- [ ] 機能全体の2章（クラス・ファイル構成）と、API詳細の4章（処理フロー）・6章（バリデーション）・7章（DB操作）・8章（トランザクション）・9章（エラー）・10章（認証・認可）が、作ったコードと同じ（detailed-design の skill の5章）。
- [ ] 作りの途中で変えた所は、詳細設計も直した（版と変更履歴も）。

## 6. 作業記録を書いて、人に報告する

- [ ] `output/<タスク名>/変更ファイル一覧.md` に、変えたファイルがすべてある。
- [ ] `output/<タスク名>/作業メモ.md` の進み具合で「backend-impl」に印を付け、「確認してほしい点」を書いた。

人には短く書く：作ったもの、詳細設計の場所、確認してほしい点、次にすること（`/backend-test <タスク名>`）。
