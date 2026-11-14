---
name: backend-review
description: 備品管理システムのサーバー（EquipmentManagementSystem_Server）の実装を、CLAUDE.md の決まりと設計書に照らしてレビューし、指摘の一覧を返す。コードは直さない。作った会話とは別のエージェントで動くので、自分で作ったものを自分で採点する形にならない。
when_to_use: zip を人に渡す前の見直し、相手が作ったプルリクエストの確認、「ZPOP-33 のサーバー側をレビューして」と頼まれたとき。
argument-hint: "[タスク名かJiraの課題キー、zip のフォルダ、またはファイル・フォルダのパス]"
context: fork
agent: general-purpose
background: false
disallowed-tools:
  - Edit
  - Write
  - NotebookEdit
---

# バックエンドのレビュー（Server）

レビューする対象：$ARGUMENTS

あなたは、備品管理システムのサーバーのコードをレビューする。**ファイルを作る・直す・消すことはしない。** Git の作業も何もしない（状態を見るだけのコマンドも動かさない）。テストも動かさない（結果は、作業メモと、残っているテストの結果のファイルを読む）。結果は、最後に決まった形の文章で返す。

## 1. 何をレビューするかを決める

対象の指定によって、変わったファイルを次のように決める。

| 指定 | 変わったファイルの見つけ方 |
|---|---|
| タスク名か Jira の課題キー（例：種別管理、ZPOP-33） | Server か Client のいちばん上の、作業記録 `output/種別管理/`（課題キーが渡されたら、`output/` の中の各フォルダの作業メモ.md の頭の課題キーで探す）の `変更ファイル一覧.md` と `作業メモ.md` を読む（形は deliver-zip の skill の「作業記録の形」） |
| `output/` の中のフォルダ（作業記録、または zip の前のフォルダ） | そのフォルダの `変更ファイル一覧.md`（あれば `作業メモ.md` も）を読む |
| 相手から受け取った zip を広げたフォルダ | その中の `変更ファイル一覧.md` と `説明.md` を読み、`EquipmentManagementSystem_Server/` の中のファイルをレビューする |
| ファイル・フォルダのパス | そのファイル、またはそのフォルダの中の .java・.xml・.yml |
| 何もない | 人に対象を聞く（自分で決めつけない） |

変更ファイル一覧.md がなければ、そのことを結果に書き、指定されたパスだけをレビューする。Server のファイルが1つもなければ「Server の変更なし」と返して終わる。

Server のフォルダ（`EquipmentManagementSystem_Server`）と Document のフォルダが読めなければ、そのことを結果に書いて終わる（人が `/add-dir ../EquipmentManagementSystem_Server` で読めるようにしてから、もう一度呼ぶ）。

## 2. 照らし合わせるものを読む

同じフォルダに並んだ Document リポジトリ（`../EquipmentManagementSystem_Document`）の中を読む。

- [ ] `internaldesign/CLAUDE.md`（とくに 2章、4.1、5章、6章、9章）
- [ ] そのまとまりの詳細設計 `internaldesign/詳細設計/<まとまりのフォルダ>/`（まとまり全体と、変わった API の API詳細）と、`common.md`
- [ ] `internaldesign/パッケージ構成変更/API_パッケージとクラス名_決定版.md`（API のパッケージ名とクラス名の頭）
- [ ] 詳細設計の「もとにした設計書」に書かれた章（API設計・画面設計・データ設計・機能一覧）
- [ ] `internaldesign/テスト方針.md` 3・4・7章
- [ ] 作業メモのテストの結果と、Server の `build/test-results/test/`（あれば。zip の前のフォルダなら evidence のテスト結果.md）
- [ ] 心得：`.claude/skills/implementation-guidelines/SKILL.md`（4・5・7・8章）

## 3. 確かめること

1つずつ確かめ、合っていない所を指摘にする。推測で指摘しない。ファイル名と行番号、根拠（CLAUDE.md の章、設計書の章）を必ず示す。

**設計書のとおりか**
- [ ] API の URL・操作・必要な権限項目・送る値・返す値・status・message が、API設計と同じ。
- [ ] 入力チェックの決まりとメッセージが、画面設計と同じ（文字が一字でも違えば指摘）。
- [ ] 業務のルール（機能一覧）が抜けていない。設計書にない動きを足していない。
- [ ] 詳細設計とコードが食い違っていない（クラス・SQL・メッセージ・テスト）。

**パッケージと API の分け方**（CLAUDE.md 4.1・5章）
- [ ] API のクラスが、その API のパッケージ（API_パッケージとクラス名_決定版.md のとおり）の、役割どおりのパッケージにある：`controller`（`<頭>Controller`・`<頭>RestInDto`）、`service`（`<頭>Service`（interface）・`<頭>ServiceImpl`（`@Service`）・`<頭>ServiceInDto`）、`model`（`<頭>RestOutDto`）、`validator`（`<頭>Validator`・`<頭>ValidatorDto`）。要らないクラスを作っていない。Enum は `common.constant`、自作のチェック用アノテーションは `common.validation`。
- [ ] Controller に URL と操作が1つだけ。Controller は自分の API の interface を使い、ServiceImpl を直接使っていない。
- [ ] Controller が、RestInDto・パスの値・ログインしている人の ID から ServiceInDto を作り、Service に渡している。Service が RestInDto やパスの値をそのまま受け取っていない。
- [ ] 形式のチェックが RestInDto の印と Controller の `@Valid` にある。受け取った値だけで DB と照らして確かめられるものが、ServiceInDto の common.validation のチェック用アノテーションにあり、ServiceImpl の `@Transactional` の中で ServiceInDtoChecker で確かめている。ServiceImpl が読んだ・計算した値が要る業務チェックが、`validator.<頭>Validator` にあり、ServiceImpl が `<頭>ValidatorDto` を渡して、書き換えの前に呼んでいる（Controller から呼んでいない）。これらのチェックが ServiceImpl や Controller に直接書かれていない。
- [ ] チェック用アノテーションの中と Validator が読むだけ（Mapper の select・count だけ）で、書き換えをしていない。
- [ ] 業務のルールが Controller に書かれていない。（Controller から common.security.LoginSession を呼ぶのは、決まった例外なので指摘しない。CLAUDE.md 5章）
- [ ] ほかの API のパッケージ（同じまとまりの API も）のクラスを import していない（import の行を見て確かめる）。使っているのは自分の API のパッケージと common・dao だけ。common・dao から api・batch を使っていない。循環がない。
- [ ] Mapper・テーブルの形・Example の import が `dao.mapper`・`dao.entity` のもの。dao.entity をそのまま画面に返していない（RestOutDto に移している）。
- [ ] MyBatis Generator が作ったファイル（`dao.mapper`・`dao.entity` と、その XML）を手で直していない。
- [ ] `record` を使っていない（CLAUDE.md 3章）。
- [ ] common の部品（common.validation のチェック用アノテーションを足す・変えるのを含む）、Flyway のファイル、dao（MyBatis Generator の設定と作ったファイル）、build.gradle・settings.gradle、すでにある Enum を変えていたら、「2人で相談が必要な変更」として指摘する（CLAUDE.md 9章）。

**データベースと SQL**
- [ ] DB の読み書きが dao の Mapper と Example の Criteria で書かれている。手で書く SQL（dao.mapper.custom）は XML にあり、値は `#{}`。`${}` があれば、外から入る値でないかを確かめる（SQLインジェクション）。手で書く Mapper は、Example では書けないものだけ。
- [ ] JOIN・サブクエリ（SQL の中の2つ目の SELECT）がない。
- [ ] ループの中で Mapper を呼んでいない（N+1）。Criteria の `andIdIn`（手で書く XML なら `<foreach>`）でまとめて読んでいる。
- [ ] 一覧・検索で削除済み（`deleted_at` が入った行）を出していない。削除は論理削除。
- [ ] 編集は `version` で楽観ロックし、先に保存されていたら 409。
- [ ] UPDATE・DELETE の条件（id、`deleted_at IS NULL`、`version`）が足りていて、条件の抜けで全件が変わらない（`updateByExample` などで Criteria が空になっていない）。

**安全と決まり**
- [ ] すべての API に権限項目の確認（`@PreAuthorize`）がある。ログインなしで呼べる API は、API設計で決めたものだけ。
- [ ] ID を受け取る API で、その人が操作してよい対象かを ServiceInDto のチェックで確かめている（ログインしている人の ID は Controller が入れている）。ID を書き換えて他人のデータを読む・変えることができない（IDOR。CLAUDE.md 5章）。
- [ ] 2つ以上の書き換えを1つの操作として行う ServiceImpl のメソッドに `@Transactional` があり、ServiceInDto のチェックもその中にある。interface・Controller・Mapper に付いていない。同じクラスの中から呼んでいて効いていない、ということがない（CLAUDE.md 5章）。
- [ ] Slack の送信が `@Transactional` の中にない。書き込みが確定してから送っている（CLAUDE.md 5章）。
- [ ] 画面設計のチェックをサーバー側でも行っている（形式のチェックは `@Valid` と RestInDto の印、DB との整合性のチェックは ServiceInDto のチェック用アノテーション）。
- [ ] 今の日時を Clock から取っている（`now()` を Clock なしで呼んでいない）。
- [ ] ログに、パスワード・合言葉・Slack のトークンを出していない。秘密の値がコードや設定ファイルに書かれていない。
- [ ] 変えられる値（時刻・期限・回数）が、プログラムに直接書かれていない。
- [ ] テスト用の切り替え（Slack の偽物など）が、本番の設定で動かない。
- [ ] 貸出・確認のルールを変えたなら、ほかのまとまり（equipment.mine・equipment.management）の同じルールとテストも直っている。

**テスト**（テスト方針 3・4章、CLAUDE.md 6章）
- [ ] API ごとに ①成功 ②400 ③401 ④403 ⑤400・409 がある。④がなければ必ず指摘する。API のテストが、その API と同じパッケージの `<頭>ApiTest` にある。
- [ ] POST・PUT・DELETE で `csrf()` を使わず、CsrfTestHelper を使っている。
- [ ] 計算・判断の部品に単体テストがあり、境界値と日付（時計を止める）を確かめている。
- [ ] Slack に本物を送っていない。
- [ ] 期待する結果が甘くなっていない（例：status だけで中身を見ていない、メッセージを確かめていない）。
- [ ] 他人の ID を使ったときのテスト（IDOR）がある（ID を受け取る API）。
- [ ] 最後に動かしたテストが全部成功している（作業メモ、結果のファイル）。

**心得（implementation-guidelines）**
- `catch (Exception e)` で何でも受け止めている、例外を握りつぶしている、null で落ちる所がある、`SELECT *` を使っている、部品をコンストラクタ以外で受け取っている、dao.entity をそのまま返している、など。根拠を「implementation-guidelines ○章」と書き、重さは「直したほうがよい」以下にする（決まりではないため）。

**そのほか**
- 決まりにも心得にもないが、不具合になりそうな所（件数0件のときの扱い、日付の境目、など）。根拠を「一般的な不具合の恐れ」と書き、重さは「直したほうがよい」以下にする。

## 4. 返す形

次の形の Markdown で返す。

```
# バックエンドのレビュー結果（<対象>）

## 結論
（「このまま取り込んでよい」か「直してから取り込む」。理由を1〜2文）

## 指摘
| No. | 重さ | 場所 | 内容 | 根拠 | 直し方の案 |
|---|---|---|---|---|---|
| 1 | 必ず直す | src/main/java/…/XxxServiceImpl.java:42 | … | CLAUDE.md 5章「…」 | … |

重さ：
- 必ず直す：決まり・設計書に反する、不具合、安全の問題
- 直したほうがよい：読みにくい、テストが足りない、将来の不具合の恐れ
- 確認したい：設計書があいまいで、判断が要るもの

## 2人で相談が必要な変更
（common（common.validation を含む）、Flyway、dao、build.gradle、すでにある Enum などの変更。なければ「なし」）

## 確かめた観点
（3章の見出しごとに「問題なし」か「指摘 No.○」）

## 読んだもの
（レビューしたファイルの数と、読んだ設計書の章）
```

指摘がなければ、表に「なし」と書く。指摘を作るために、無理に探さない。
