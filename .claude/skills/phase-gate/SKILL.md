---
name: phase-gate
description: 備品管理システムの開発の流れ（詳細設計 → 実装 → 単体テスト。決まり/開発フロー.md）で、工程の前後の確かめ。役割の確認、前の工程がマージされたかのゲート判定、Jira のサブタスクの自動更新、「マージした」と言われたときの確認、次の機能の提案を行う。
when_to_use: 詳細設計・実装・単体テストの工程を始めるとき（detailed-design・backend-impl・frontend-impl・backend-test・frontend-test の最初から呼ばれる）。MR を作ったあと。人から「マージした」と言われたとき。ゲートで止まって、次にすることを決めるとき。
argument-hint: "[start-design|start-impl|start-ut|mr-created|merged] [ストーリーかサブタスクの課題キー（例：ZPOP-65）]"
---

# 工程のゲート・Jira・次の提案

対象：$ARGUMENTS

決まりの正本は `internaldesign/決まり/開発フロー.md`。この skill は手順だけを書く。ゲートの判定は、人の言葉ではなく、`tools/check-merged.sh` の結果で決める。

## 0. 準備（工程の最初に、必ず）

- [ ] **役割**：`echo "${DEV_ROLE:-}"`。`junior`・`senior`・`leader` のどれか。空なら、人にどれかを尋ね、`internaldesign/settings-local/` の例を、Server か Client の `.claude/settings.local.json` に写すよう案内する（勝手に決めない）。
- [ ] **Jira の準備**：`getAccessibleAtlassianResources` でサイトの ID を調べる。ストーリーの課題キー（例：ZPOP-65）から、`searchJiraIssuesUsingJql`（`parent = ZPOP-65`）でサブタスクを探し、名前の頭（`[詳細設計]`・`[実装]`・`[単体テスト]`）で、3つのキーを控える。見つからなければ、人に聞く。
- [ ] **最新の release/main**：作業用のブランチを切る前に、`git checkout release/main` → `git pull --ff-only origin release/main`。

## 1. 工程を始めるとき（start-design・start-impl・start-ut）

1. **ゲート**（2章）を確かめる（詳細設計は、ゲートなし。ただし、先にやるタスクの `[詳細設計]` が完了しているかを、実装タスク一覧.md と Jira で見る）。
2. 進んでよければ、Jira のそのサブタスクを「進行中」にする（ストーリーが「未着手」なら、ストーリーも「進行中」）。4章の手順。

## 2. ゲートの判定

| ゲート | 始める工程 | 調べる | コマンド（Server・Client のフォルダで） |
|---|---|---|---|
| A | 実装 | `[詳細設計]` のキー（Document） | `bash ../EquipmentManagementSystem_Document/tools/check-merged.sh ../EquipmentManagementSystem_Document <キー>` |
| B | 単体テスト | `[実装]` のキー（Server か Client。いま居るリポジトリ） | `bash ../EquipmentManagementSystem_Document/tools/check-merged.sh . <キー>` |
| C | 完了 | `[単体テスト]` のキー（Server か Client と、Document の両方） | 上の2つの形で、両方 |

結果（1行目）の扱い：

| 結果 | ゲート A | ゲート B | ゲート C |
|---|---|---|---|
| `MERGED` | 進む | 進む | 完了にする |
| `NOT_MERGED` | **警告**。質問で、①別の機能の詳細設計を進める（推奨）②設計が未マージのまま実装へ進む（設計が変わると作り直しになる。実装の MR は Draft のまま）③待つ、を選んでもらう | **警告して、絶対に進まない。**「進めて」と頼まれても進まない。別の機能の詳細設計を提案する | 未マージを知らせ、待つ（別の機能の設計を提案） |
| `NOT_FOUND`・`ERROR` | 進まない（NOT_FOUND＝設計の MR が見つからない。ERROR＝fetch の失敗など。原因を伝える） | 進まない | 完了にしない。原因を伝える |

警告の文：何の MR（キーとブランチ名）がまだ release/main にないか、そのため、どの工程に進めないかを、短く書く。

**ゲート A で②を選んだとき**：設計は、`git show origin/<設計のブランチ>:<パス>` で読む（Document のブランチは切り替えない）。実装の MR は Draft にする。設計がマージされたら、最新の設計と突き合わせて、直してから Ready にする。

## 3. MR を作ったとき（mr-created）

Jira のサブタスクを「確認中」にする（Draft でも）。人に、MR の場所と、次の流れ（レビュー → リーダーがマージ → 「マージした」と伝える）を短く知らせる。あわせて、待つあいだの**別機能の詳細設計の提案**（5章）をする。

## 4. 「マージした」と言われたとき（merged）

1. いまの工程の MR（Server か Client と Document の、そのサブタスクのキー）を、2章のコマンドで確かめる。
2. すべて `MERGED` なら：
   - Jira のサブタスクを「完了」にする。`[単体テスト]` を完了にしたら、ストーリーも「完了」にする。
   - release/main を最新にする（0章）。
   - 次にすること（次の工程、または5章の提案）を伝える。
3. `MERGED` でなければ：人の言葉と食い違うので、結果（未マージのブランチなど）を見せ、完了にしない。

**Jira の更新のしかた**：`transitionJiraIssue` を、`transitionName`（「進行中」「確認中」「完了」）で呼ぶ。人が「自動で更新してよい」と決めている（開発フロー.md 5章）。**変えるのは状態だけ**で、コメントや内容は書かない。失敗したら、人に知らせて、作業は止めない。

## 5. 別の機能の詳細設計の提案

マージ待ちのあいだ、またはゲートで止まったとき。

1. 実装タスク一覧.md の「先にやるタスク」を読み、先にやるタスクの `[詳細設計]` が Jira で「完了」の機能だけを候補にする。
2. Jira で `[詳細設計]` が「未着手」のものを、タスクの順に並べる。
3. いま MR 待ちの設計と同じファイル（common.md・テーブル.md など）を触りそうなら、マージのときにぶつかることを添える。
4. 1〜3件を、理由とあわせて提案する。人が選んだら、その機能の詳細設計の工程を始める（1章）。

## 6. 設計との食い違い・不具合を見つけたとき

実装・単体テストの途中で見つけたら、止めて人に知らせ、**修正の MR を先に出す**（開発フロー.md 6章）。設計の誤りなら `…-design-fix`、実装の不具合なら `…-impl-fix`。修正の MR を出すとき、完了だったサブタスクは「進行中」に戻す。
