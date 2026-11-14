---
name: reverse-engineer
description: 備品管理システムの今あるコード（Server・Client）を読み、詳細設計（機能全体・APIごと・画面ごと。internaldesign/詳細設計/テンプレート/ の形）を書き起こし、設計書（機能一覧・画面一覧・画面設計・API設計・データ設計）と CLAUDE.md の決まりとの食い違いを一覧にする。コードと設計書は直さない。
when_to_use: 詳細設計なしに作られたコードの中身を知りたいとき、相手が作った機能の作りを知りたいとき、「loan の作りを書き起こして」「このコードと設計書が合っているか調べて」と頼まれたとき。
argument-hint: "[まとまり（例：equipment.category）、API・画面の ID、またはファイル・フォルダのパス]"
---

# 実装から詳細設計を書き起こす（リバースエンジニアリング）

対象：$ARGUMENTS

（空なら、人にまとまり（または API・画面の ID）を聞く。）

**この skill でしないこと**
- コード（Server・Client）を直さない。おかしな所を見つけても、食い違い一覧に書くだけにする。
- 設計書（brd・externaldesign、internaldesign の API設計・テスト方針など）を直さない（CLAUDE.md 2章）。
- すでにある詳細設計を、人に確かめずに上書きしない（4章）。
- commit・push はしない（書き起こした詳細設計は、人が確かめてから取り込む）。マージもしない（CLAUDE.md 7章）。

**書き方の大事な点**：コードから確かに言えることと、推し量ったことを分ける。コードに書いていない「なぜそうしたか」を作らない。分からない所は「コードからは分からない」と書き、人に確かめる点として残す。

## 1. 読む範囲を決める

まとまり（CLAUDE.md 4.1 の表の1行）が渡されたら、次をすべて読む（パッケージの頭の `jp.co.highjunk.equipment` は省く）。API・画面の ID が渡されたら、その API・画面にかかわる所だけを読む。

コードは作り直しの途中（CLAUDE.md 4.1）なので、新しい形と古い形のどちらかで書かれている。どちらの形かを確かめて読む。

| リポジトリ | 読むもの |
|---|---|
| Server（新しい形） | そのまとまりの API のパッケージ（例：`api/equipment/category/` の下。Controller・Service・ServiceImpl・RestInDto・ServiceInDto・RestOutDto）、使っている `dao.mapper`・`dao.entity` と、`dao.mapper.custom` の手で書く Mapper と XML、使っている `common.validation` のチェック用アノテーション、`common.constant` の Enum と common の部品、`application*.yml` の使っている設定値、`src/test/java/` の同じパッケージのテスト |
| Server（古い形。作り直す前） | `<機能名>/`（controller・service・validator・model）、`mapper/<機能名>/` と XML、`dto/<機能名>/`、使っている Enum と common の部品、設定値、`src/test/java/jp/co/highjunk/equipment/<機能名>/` のテスト |
| Client | `src/features/` の、そのまとまりのフォルダ（新しい形は `features/equipment/category/` のような入れ子。移す前は `features/category/` のような機能ごと）の pages・components・api.ts・types.ts、`src/routes.tsx` のその行、使っている common の部品、`tests/` の同じ形のフォルダ |

ファイル・フォルダのパスが渡されたら、そのファイルと、そこから呼ばれている所まで読む。

読めないリポジトリがあれば（`--add-dir` していない）、人に `/add-dir ../EquipmentManagementSystem_Client` などを頼むか、読めた範囲だけで書いて、そのことを書く。

## 2. 詳細設計を書き起こす

`internaldesign/詳細設計/README.md` と、テンプレート（`internaldesign/詳細設計/テンプレート/` の機能.md・API.md・画面.md）の形で書く。お手本（作り直した `equipment/category/`）と同じ書き方にする。古い形のコードを書き起こすときも、テンプレートは新しい形を使い、古い形のクラス（validator・model・…Request など）は、そのクラス名のまま書く。

| ファイル | 1つずつ作る単位 | 書くもと |
|---|---|---|
| まとまり全体 `<まとまりの名前>.md` | まとまりに1つ | Controller の API の一覧、routes.tsx の画面、`@Scheduled`、読んだクラス・ファイル、使っている dao・Enum・common の部品、ほかのまとまりと同じテーブル・同じルールを使っている所 |
| API詳細 `<APIのID>_<短い名前>.md` | Controller のメソッド（API）ごと | URL・操作・`@PreAuthorize`、RestInDto の項目と印、ServiceInDto の作り方とチェック用アノテーション（古い形なら Validator で確かめていること）、ServiceImpl の順番、Mapper のメソッドと Criteria の条件（手で書く SQL）、`@Transactional`、エラーの返し方、Slack を送る所、IDOR の確かめの有無 |
| 画面詳細 `<画面のID>_<短い名前>.md` | pages の画面ごと | 部品の組み立て、項目と状態（useState）、入力チェック、ボタンの動き、読み込み中・0件・失敗の表示、api.ts の呼び出し、移り方、画面の文 |

- API・画面の ID は、URL・画面のアドレスを API設計 3章・画面一覧 2章と照らして決める。どれにも当たらない API・画面は、ID を「なし」にしてファイル名を `なし_<短い名前>.md` にし、食い違い一覧の「設計書にない」に書く。
- テンプレートの「写したもと」の所には、設計書から写さず、**コードから書いた中身**を書き、「書いたもと：コード（ファイル名）」とする。設計書との違いは3章で一覧にする。
- 画面の文・メッセージは、コードの文をそのまま書く。
- 表の頭：版は v0.1（書き起こし）。状態は「コードから書き起こした。人の確認前」。Jira は分かれば。
- 「設計書にない判断」の章には、設計書に書いていない作りと、理由がコード（コメント）にあればそれを、なければ「理由はコードからは分からない」と書く。
- 推し量ったことには「（推測）」と付ける。

## 3. 設計書・決まりと突き合わせる

書き起こした中身を、次と1つずつ比べる。

| 比べる相手 | 見る所 |
|---|---|
| internaldesign/API設計.md | URL・操作・権限項目・送る値・返す値・status・message |
| externaldesign/画面設計.md | 絵・項目・ボタン・移り方・入力チェック・メッセージの文（一字ずつ） |
| externaldesign/画面一覧.md | 画面のアドレス、移り方、スマートフォン優先か |
| externaldesign/データ設計.md | 使っているテーブル・列・制約。論理削除・version の使い方 |
| externaldesign/機能一覧.md | 業務のルールが抜けていないか、設計書にない動きがないか |
| internaldesign/CLAUDE.md | 4.1・4.3（置き場所）、5章（Service の interface と Impl、ServiceInDto は Controller で作る、チェックは RestInDto と ServiceInDto の2段、dao の Mapper と Criteria、JOIN・サブクエリ、N+1、Clock、`@PreAuthorize`、IDOR、`@Transactional`、Slack、`#{}`、論理削除、楽観ロック、ほかの API のパッケージを使わない、命名規則）、6章（テストの決まり）。古い形のコードは、作り直しの途中なので「決まりに合わない」には数えず、「古い形のまま」と書く |
| internaldesign/テスト方針.md | API ごとの ①〜⑤ のテスト、画面のテストの大きさ |
| すでにある詳細設計（あれば） | 書き起こした中身との違い |

## 4. 書き出す

書き出す場所は `output/<まとまりの名前>_リバース_<日付>/`（日付は今日。例：`output/management_リバース_20261210/`）。

```
output/management_リバース_20261210/
├─ 食い違い一覧.md
└─ equipment/
   └─ management/            書き起こした詳細設計（Document の詳細設計と同じ形）
      ├─ management.md
      ├─ D-01_貸出履歴を探す.md
      └─ S-10_貸出履歴.md
```

**詳細設計を Document に置くとき**
- `internaldesign/詳細設計/<まとまりのフォルダ>/` が**まだない**ときは、人に「Document に置いてよいか」を確かめてから写す。置くときは、設計書から写す所（「写したもと」）を、README 3章の決まりで設計書の中身に書き直す（コードの中身のままにしない）。
- **すでにある**ときは、上書きしない。違いを食い違い一覧の「すでにある詳細設計との違い」に書き、どちらに合わせるかを人に決めてもらう。

**食い違い一覧.md の形**

```
# 食い違い一覧（<まとまり>　YYYY-MM-DD）

読んだコード：（ファイルの数と一覧）
比べた設計書：（ファイル名・版・章）

## 設計書・決まりとの食い違い
| No. | 種類 | API・画面 | 設計書・決まりの場所 | コードの場所 | 内容 | どちらに合わせるかの材料 |
|---|---|---|---|---|---|---|
| 1 | 設計書と違う | K-02 | API設計 v1.1 の4.7 | src/main/java/…/XxxServiceImpl.java:42 | … | … |

種類：
- 設計書と違う：設計書と動きや文が違う
- 設計書にない：コードにあるが、設計書に書いていない動き・API・画面
- 実装がない：設計書にあるが、コードにない
- 決まりに合わない：CLAUDE.md の決まりに合わない
- テストがない：テスト方針で必要なテストがない

## すでにある詳細設計との違い
（あれば。なければ「なし」または「詳細設計なし」）

## コードからは分からないこと
（理由や意図が分からない所。人に確かめる点）
```

「どちらに合わせるかの材料」には、事実（設計書の版、コードのコメント、テストがあるか）だけを書き、どちらが正しいかは決めない（決めるのは人）。

## 5. 人に報告する

短く書く：読んだ範囲、書き出したファイルの場所、食い違いの件数（種類ごと）、とくに大きい食い違い（安全・データの整合に関わるもの）、人に決めてほしいこと。直すときは、backend-impl・frontend-impl・detailed-design の skill で、別の作業として行う。
