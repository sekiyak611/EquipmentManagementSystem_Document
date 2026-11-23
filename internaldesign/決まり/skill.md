# 決まり：skill（Claude Code の作業の手順書）

共通の決まり（internaldesign/CLAUDE.md）から移した。章の番号（4.1・5章・7章など）は、移す前の CLAUDE.md のまま。ほかの文書やコードのコメントが「CLAUDE.md 5章」のように呼ぶ番号と、食い違わないようにするため。 skill を使う・直す前に読む。

## 4.4 skill（Claude Code の作業の手順書）

skill は、作業の順番とチェック表をまとめたファイル（SKILL.md）。Claude Code は、作業の内容に合うと判断したときに自動で読み込む。人が `/backend-impl K-01_種別一覧` のように名前を打って呼び出すこともできる（skill に渡すのは、実装タスク一覧.md の「タスク名」か、Jira の課題キー）。

- 置き場所は Document の `.claude/skills/<skillの名前>/SKILL.md`。Server・Client で `--add-dir ../EquipmentManagementSystem_Document` を付けて起動すると、2人とも同じ skill を使える。各自のPCだけに skill を置かない（9章）。
- skill には決まりを書き写さず、この CLAUDE.md と設計書の章を指す。skill と CLAUDE.md・設計書が食い違ったら、CLAUDE.md・設計書が正しい。

| skill | 使うとき |
|---|---|
| backend-impl | Server の実装（工程②。詳細設計がマージ済みなのが前提。ゲート A。テストは書かない） |
| backend-test | Server のテスト（工程③。実装がマージ済みなのが前提。ゲート B） |
| frontend-impl | Client の実装（工程②。同じ） |
| frontend-test | Client のテスト（Playwright。工程③。同じ） |
| detailed-design | 詳細設計の工程（工程①）。書く・直す |
| phase-gate | 工程の前後の確かめ（役割・ゲート判定・Jira の自動更新・「マージした」の確認・次の機能の提案） |
| design-review | 詳細設計の独立した AI レビュー（直さない） |
| spec-check | 実装の前の、設計書の確認と確定・推測・未確定の整理、人への質問（ファイルは変えない。外から見える判断があるときだけ） |
| backend-review | Server の実装のレビュー。コードは直さず、指摘の一覧を返す。作った会話とは別のエージェントで動く |
| frontend-review | Client の実装のレビュー（同じ） |
| deliver | 各工程の MR の仕上げ（design・impl・ut。テスト・証跡・commit・push・MR。CLAUDE.md 7章・10章） |
| reverse-engineer | コードから詳細設計を書き起こし、設計書との食い違いを一覧にする（設計書は直さない） |
| implementation-guidelines | 実装・テスト・レビューのときの一般的な心得（読みやすさ、例外、型など）。この CLAUDE.md にない所で使う |
| env-setup | 開発環境を作る・確かめる（Windows のPC） |

1つのストーリー（Jira の課題。API 1本、画面1つ、仕組み1つ）は、3つの工程で進める。**工程ごとに MR を出し、マージしてから次へ進む**（CLAUDE.md 11章、`決まり/開発フロー.md`）。各工程の最初は phase-gate（役割・ゲート・Jira）。

```
① 詳細設計  /detailed-design <ストーリー> →（spec-check で質問）→ 詳細設計 → /design-review → 人のチェック → /deliver design → リーダーがマージ
   ↓ ゲート A（設計がマージ済みか。未マージなら警告し、別機能の設計を提案）
② 実装      /backend-impl または /frontend-impl → /backend-review または /frontend-review → 人のチェック → /deliver impl → リーダーがマージ
   ↓ ゲート B（実装がマージ済みか。未マージなら、絶対に進まない）
③ 単体テスト /backend-test または /frontend-test → /backend-review または /frontend-review → 人のチェック → /deliver ut → リーダーがマージ
   ↓ ゲート C（マージ済みを確かめて完了）→ 別の機能の詳細設計を提案
```

- 実装の工程は、詳細設計を書かない（マージ済みの設計を読む）。設計の誤りは、設計の修正の MR を先に出す。バグ・仕様との相違は、Jira に障害チケットを作り、設計書の修正から単体テストまでをやり直す（開発フロー.md 6章）。工程ごとに新しい会話にする必要はない。
- 画面のストーリーの単体テストは、frontend-test で Playwright のテストを書く（テスト方針 5章）。結合テストは行わず、機能をまたいだ結合はシナリオテストで確かめる（2026-11-15 に決めた。テスト方針 2章）。

