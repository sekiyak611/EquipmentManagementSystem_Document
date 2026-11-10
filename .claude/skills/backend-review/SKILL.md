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
- [ ] その機能の詳細設計 `internaldesign/詳細設計/<機能名>/`（機能全体と、変わった API の API詳細）と、`common.md`
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

**パッケージと機能の分け方**（CLAUDE.md 4.1・5章）
- [ ] 機能の中は controller・service・validator・model。mapper は `mapper.<機能名>`、dto は `dto.<機能名>`、Enum は `common.constant`。
- [ ] service は interface の `<機能名>Service` と、中身の `<機能名>ServiceImpl`（`@Service`）に分かれ、同じ service パッケージにある。controller は interface を使い、ServiceImpl を直接使っていない。
- [ ] 業務チェック（データベースの中身や業務のルールと照らして確かめるもの）が `<機能名>/validator/` の `…Validator` にあり、ServiceImpl から書き換えの前に呼ばれている。controller から呼んでいない。Validator が書き換え（insert・update・markDeleted など）をしていない。業務チェックが ServiceImpl や controller に直接書かれていない。
- [ ] 名前が CLAUDE.md 5章の命名規則のとおり（`…Service`・`…ServiceImpl`・語尾が `Validator`）。
- [ ] Controller は1つの機能に1つだけ。業務のルールが controller に書かれていない。
- [ ] ほかの機能の service・validator・model・`mapper.<ほかの機能>`・`dto.<ほかの機能>` を import していない（import の行を見て確かめる）。common から機能のパッケージを使っていない。循環がない。
- [ ] common の部品、Flyway のファイル、build.gradle・settings.gradle、すでにある Enum を変えていたら、「2人で相談が必要な変更」として指摘する（CLAUDE.md 9章）。

**データベースと SQL**
- [ ] SQL は XML にあり、値は `#{}`。`${}` があれば、外から入る値でないかを確かめる（SQLインジェクション）。
- [ ] JOIN・サブクエリ（SQL の中の2つ目の SELECT）がない。
- [ ] ループの中で mapper を呼んでいない（N+1）。IN と `<foreach>` でまとめて読んでいる。
- [ ] 一覧・検索で削除済み（`deleted_at` が入った行）を出していない。削除は論理削除。
- [ ] 編集は `version` で楽観ロックし、先に保存されていたら 409。
- [ ] UPDATE・DELETE の条件（id、`deleted_at IS NULL`、`version`）が足りていて、条件の抜けで全件が変わらない。

**安全と決まり**
- [ ] すべての API に権限項目の確認（`@PreAuthorize`）がある。ログインなしで呼べる API は、API設計で決めたものだけ。
- [ ] ID を受け取る API で、その人が操作してよい対象かを Validator で確かめている。ID を書き換えて他人のデータを読む・変えることができない（IDOR。CLAUDE.md 5章）。
- [ ] 2つ以上の書き換えを1つの操作として行う ServiceImpl のメソッドに `@Transactional` があり、Validator の呼び出しもその中にある。interface・controller・validator・mapper に付いていない。同じクラスの中から呼んでいて効いていない、ということがない（CLAUDE.md 5章）。
- [ ] Slack の送信が `@Transactional` の中にない。書き込みが確定してから送っている（CLAUDE.md 5章）。
- [ ] 画面設計のチェックをサーバー側でも行っている（入力チェックは `@Valid` と dto の印、業務チェックは Validator）。
- [ ] 今の日時を Clock から取っている（`now()` を Clock なしで呼んでいない）。
- [ ] ログに、パスワード・合言葉・Slack のトークンを出していない。秘密の値がコードや設定ファイルに書かれていない。
- [ ] 変えられる値（時刻・期限・回数）が、プログラムに直接書かれていない。
- [ ] テスト用の切り替え（Slack の偽物など）が、本番の設定で動かない。
- [ ] 貸出・確認のルールを変えたなら、ほかの機能（mine・equipment・importer・confirmation）の同じルールとテストも直っている。

**テスト**（テスト方針 3・4章、CLAUDE.md 6章）
- [ ] API ごとに ①成功 ②400 ③401 ④403 ⑤400・409 がある。④がなければ必ず指摘する。
- [ ] POST・PUT・DELETE で `csrf()` を使わず、CsrfTestHelper を使っている。
- [ ] 計算・判断の部品に単体テストがあり、境界値と日付（時計を止める）を確かめている。
- [ ] Slack に本物を送っていない。
- [ ] 期待する結果が甘くなっていない（例：status だけで中身を見ていない、メッセージを確かめていない）。
- [ ] 他人の ID を使ったときのテスト（IDOR）がある（ID を受け取る API）。
- [ ] 最後に動かしたテストが全部成功している（作業メモ、結果のファイル）。

**心得（implementation-guidelines）**
- `catch (Exception e)` で何でも受け止めている、例外を握りつぶしている、null で落ちる所がある、`SELECT *` を使っている、部品をコンストラクタ以外で受け取っている、model をそのまま返している、など。根拠を「implementation-guidelines ○章」と書き、重さは「直したほうがよい」以下にする（決まりではないため）。

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
（common、Flyway、build.gradle、すでにある Enum などの変更。なければ「なし」）

## 確かめた観点
（3章の見出しごとに「問題なし」か「指摘 No.○」）

## 読んだもの
（レビューしたファイルの数と、読んだ設計書の章）
```

指摘がなければ、表に「なし」と書く。指摘を作るために、無理に探さない。
