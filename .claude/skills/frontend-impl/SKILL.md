---
name: frontend-impl
description: 備品管理システムの画面（EquipmentManagementSystem_Client。React・TypeScript・MUI）で、Jiraのタスク1つ分の画面とAPIの呼び出しを作る、または直すときの手順。画面設計を読み、詳細設計を書いてから実装し、型の確かめが通るところまで行う。テストは frontend-test で書く。
when_to_use: 「ZPOP-33 の画面を作って」「種別管理の画面を作って」「この画面の表示がおかしいので直して」のように、Client のコードを作る・直す依頼のとき。テストを書く・動かす依頼は frontend-test。
argument-hint: "[タスク名かJiraの課題キー（例：種別管理、ZPOP-33）]"
---

# フロントエンド実装（Client）

対象のタスク：$ARGUMENTS

（空なら、人に Jira の課題キーとタスク名を聞く。タスク名は、証跡のフォルダとプルリクエストの名前に使う。決め方は deliver の skill。）

この skill には、作業の順番とチェック表だけを書く。決まりの正本は Document の `internaldesign/CLAUDE.md` と設計書。この skill と食い違ったら CLAUDE.md・設計書に従い、食い違っていることを人に知らせる。CLAUDE.md・設計書に書いていない所の書き方は、implementation-guidelines の skill（Document の `.claude/skills/implementation-guidelines/SKILL.md`）の6章を参考にする。

1つのタスクは、人が `/frontend-impl` → `/frontend-test` → `/frontend-review` → `/deliver` の順に呼んで進める（CLAUDE.md 4.4）。この skill はテストを書かず、終わったら次の skill を人に案内する。

## 0. 始める前に確かめる

- [ ] 共通の決まり（CLAUDE.md）が読み込めている。読み込めていなければ、作業を始めずに人に知らせる。
- [ ] Client の `.claude/rules/react.md` を読んだ（対象のファイルを触ると自動で読み込まれる。読み込まれていなければ先に読む。この skill が「CLAUDE.md 4.1・5章」などと呼ぶ決まりの本体）。
- [ ] Document のフォルダを読み書きできる（`--add-dir ../EquipmentManagementSystem_Document`）。
- [ ] 画面が使う API ができている（Server にある）。まだなら、人に順番を確かめる。同じタスクで Server も変えたなら、そのとき起動したリポジトリで続ける（CLAUDE.md 7章）。
- [ ] 自分の担当の機能か（Document の `internaldesign/実装タスク一覧.md` の分担と Jira の担当者）。担当でなければ、止めて人に確かめる。
- [ ] 作業用のブランチ（`feature/<課題キー>-<英語の機能名>`。release/main から。3つのリポジトリとも同じ名前）で作業している。マージ・release/main への push・強制 push はしない（CLAUDE.md 7章）。
- [ ] 作業の続きなら、ブランチの `git diff` と詳細設計を読んで続きから始める（あれば `output/<タスク名>/作業メモ.md` も）。作業メモは、会話を分けるときだけ作る。

## 1. 設計書を読む

| 読むもの（Document の中） | 見る所 |
|---|---|
| externaldesign/画面設計.md | 1章（全画面の共通の決まり）と、その画面の章：項目、入力チェック、メッセージ、ボタンの動き、操作できなかったときの表示 |
| externaldesign/画面一覧.md | 画面ID、移り方、スマートフォン優先かどうか（7章） |
| internaldesign/API設計.md | 画面が呼ぶ API の送る値・返す値・エラー |
| internaldesign/詳細設計/common.md | 11章（画面の共通部品の使い方） |
| internaldesign/詳細設計/ | お手本（作り直した equipment/category/）、このまとまりのフォルダ（あれば。API詳細も読む。フォルダの決め方は README 2章） |

次に、今のコードを調べる：お手本の画面（category の S-13）、使う common の部品（common/api、common/components、common/format、common/auth）。

設計書があいまい、または設計書どうしが食い違うときは、**実装を止めて人に質問する**（CLAUDE.md 2章）。画面設計にない動き（ボタン、メッセージ、移り方）を自分の判断で足さない。

外から見える判断（返す値・エラー・画面の文・移り方）や食い違いが出たときは、spec-check の skill の形（確定／推測／未確定）で整理して、実装の前にまとめて人に質問する（CLAUDE.md 2章）。

## 2. 詳細設計を書く

detailed-design の skill に従って、`internaldesign/詳細設計/<まとまりのフォルダ>/`（例：`equipment/category/`）に、作る画面ごとのファイル（`<画面のID>_<短い名前>.md`）を書く。まとまり全体（`<まとまりの名前>.md`）の 1.2（画面一覧）と 2.2（Client のファイル）も書き足す（なければ作る）。

「設計書にない判断」に、外から見た動き（画面の文、移り方など）を変える項目が出たら、実装の前に人に確かめる（まとめて1回で質問し、推奨案を付ける。CLAUDE.md 2章）。それ以外は、そのまま実装に進む。

## 3. 作る

**置き場所**（CLAUDE.md 4.3）

下の表の `<まとまりのフォルダ>` は、CLAUDE.md 4.3 の features の表のフォルダ（例：`equipment/category`）。

| 作るもの | 置き場所 |
|---|---|
| 画面 | `src/features/<まとまりのフォルダ>/pages/` |
| そのまとまりだけで使う部品 | `src/features/<まとまりのフォルダ>/components/` |
| API の呼び出し | `src/features/<まとまりのフォルダ>/api.ts`（common/api の `apiGet`・`apiPost`・`apiPut`・`apiDelete` を使う） |
| API で受け渡す値の型 | `src/features/<まとまりのフォルダ>/types.ts`（型の名前の付け方は、CLAUDE.md 5章の命名規則） |
| URL と画面の対応 | `src/routes.tsx` に1行足すだけ（CLAUDE.md 9章） |
| 共通ヘッダーのメニュー | 1行足すだけ（CLAUDE.md 9章） |
| 2つ以上の機能で使う部品、common の変更 | 作らない・変えない。必要になったら止めて人に相談する（CLAUDE.md 9章） |
| ライブラリを足す | しない（TanStack Query・React Hook Form は使わないと決めている。CLAUDE.md 3章） |

ファイル名に画面ID（S-05 など）を入れない。

**書きながら確かめること**（くわしくは CLAUDE.md 5章、common.md 11章）

- [ ] スマートフォン優先の画面（S-01〜S-06、S-19）は、スマートフォンの画面を先に作る。横にスクロールしないこと。境目の幅は 600px（MUI の `sm`）。
- [ ] 入力欄は MUI の部品と `useState` で作る。入力の誤りは、入力欄の `error`・`helperText` で、すぐ下に出す。
- [ ] 画面に出す文（メッセージ・ボタンの名前・見出し）は、画面設計の文をそのまま使う。言い換えない。
- [ ] 画面設計に書いていない表示は、文のないものだけ足した（読み込み中の印、処理中にボタンを押せなくする、など）。新しい文が要りそうなら、足さずに人に質問する（CLAUDE.md 5章）。
- [ ] 完了・操作できなかったことは、`useMessage()` の `success`・`error` で帯に出す（common.md 11.5）。
- [ ] 押すと処理が動くボタンは `SubmitButton` を使い、処理が終わるまで押せなくする。確認がいる操作は `ConfirmDialog` を使う（common.md 11.6）。
- [ ] 画面を開いたときに読む値は `useApi` で読む。API の失敗は `ApiError`（status・message・errors）で受け、画面設計のとおりに出し分ける（400・403・404・409 など）。
- [ ] `fetch` を直接呼ばない（common/api を通す。CSRF の合言葉と 401 の移り方をそこで行うため）。
- [ ] 日付・空の値は common/format の部品で表示する（画面設計 1.3）。
- [ ] 権限によってボタンを出し分ける画面は、common/auth の部品を使う（ログインのタスク ZPOP-25 で作る）。画面で隠しても、確認はサーバーで行う。
- [ ] 入力された文字を HTML として出していない（`dangerouslySetInnerHTML` を使わない）。
- [ ] ほかのまとまりのフォルダ（`src/features/` の下の、自分のまとまり以外のフォルダ。同じ `equipment/` の下のほかのフォルダも）のものを import していない。使うのは自分のまとまりと common だけ。
- [ ] タスクに関係のない所を、ついでに変えていない。気づいた不具合は、報告の「確認してほしい点」に書く。

足した・変えた・消したファイルは、`git status` で確かめる（変更ファイル一覧は作らない）。

## 4. 型の確かめが通ることを確かめる

Client のフォルダで、型の誤りがないことを確かめる。テストはまだ動かさない（frontend-test で動かす）。

```
npm run typecheck
```

## 5. 詳細設計とコードを突き合わせる

- [ ] まとまり全体の 2.2（Client のファイル）と、画面詳細の 2.2・3章（部品・項目）・4章（入力チェック）・5章（操作）・6章（状態）・7章（API）・9章（メッセージ）が、作ったコードと同じ（detailed-design の skill の5章）。
- [ ] 作りの途中で変えた所は、詳細設計も直した（版と変更履歴も）。

## 6. 作業記録を書いて、人に報告する

- [ ] `git status`・`git diff` で、変えたファイルが、このタスクの対象だけ。
- [ ] 「確認してほしい点」（設計書にない判断を、確定／推測／未確定に分けて）を、人への報告に書いた（会話を分けるときだけ、`output/<タスク名>/作業メモ.md` にも書く）。

人には短く書く：作ったもの、詳細設計の場所、確認してほしい点、画面を見て確かめる方法（`npm run dev` のあと開くアドレス）、次にすること（`/frontend-test <タスク名>`）。
