# 決まり：skill（Claude Code の作業の手順書）

共通の決まり（internaldesign/CLAUDE.md）から移した。章の番号（4.1・5章・7章など）は、移す前の CLAUDE.md のまま。ほかの文書やコードのコメントが「CLAUDE.md 5章」のように呼ぶ番号と、食い違わないようにするため。 skill を使う・直す前に読む。

## 4.4 skill（Claude Code の作業の手順書）

skill は、作業の順番とチェック表をまとめたファイル（SKILL.md）。Claude Code は、作業の内容に合うと判断したときに自動で読み込む。人が `/backend-impl K-01_種別一覧` のように名前を打って呼び出すこともできる（skill に渡すのは、実装タスク一覧.md の「タスク名」か、Jira の課題キー）。

- 置き場所は Document の `.claude/skills/<skillの名前>/SKILL.md`。Server・Client で `--add-dir ../EquipmentManagementSystem_Document` を付けて起動すると、2人とも同じ skill を使える。各自のPCだけに skill を置かない（9章）。
- skill には決まりを書き写さず、この CLAUDE.md と設計書の章を指す。skill と CLAUDE.md・設計書が食い違ったら、CLAUDE.md・設計書が正しい。

| skill | 使うとき |
|---|---|
| backend-impl | Server の実装（設計書を読む → 詳細設計 → 実装。テストは書かない） |
| backend-test | Server のテスト（単体・API）を書き、Server・Client のテストを全部動かす |
| frontend-impl | Client の実装（設計書を読む → 詳細設計 → 実装。テストは書かない） |
| frontend-test | Client のテスト（Playwright）を書き、Server・Client のテストを全部動かす |
| detailed-design | 詳細設計を書く・直す・コードと突き合わせる |
| spec-check | 実装の前の、設計書の確認と確定・推測・未確定の整理、人への質問（ファイルは変えない。外から見える判断があるときだけ） |
| backend-review | Server の実装のレビュー。コードは直さず、指摘の一覧を返す。作った会話とは別のエージェントで動く |
| frontend-review | Client の実装のレビュー（同じ） |
| deliver | 最後のテスト、証跡、commit・push、プルリクエスト（CLAUDE.md 7章・10章。2026-11-19 に、zip を渡す形から直した） |
| reverse-engineer | コードから詳細設計を書き起こし、設計書との食い違いを一覧にする（設計書は直さない） |
| implementation-guidelines | 実装・テスト・レビューのときの一般的な心得（読みやすさ、例外、型など）。この CLAUDE.md にない所で使う |
| env-setup | 開発環境を作る・確かめる（Windows のPC） |

1つのストーリー（Jira の課題。API 1本、画面1つ、仕組み1つ）は、人が次の順に skill を呼んで進める。ストーリーの3つのサブタスクとの対応は、detailed-design が［詳細設計］、backend-impl・frontend-impl が［実装］、backend-test（部品と API の単体テスト）と frontend-test（画面の単体テスト。Playwright）が［単体テスト］（実装タスク一覧.md 0.1）。レビューとプルリクエストづくりはサブタスクにしていない。skill どうしは自動でつながない（人がそれぞれの終わりに結果を確かめるため）。

```
（API・仕組みのストーリー。例：K-01_種別一覧）
/detailed-design K-01_種別一覧 → /backend-impl K-01_種別一覧 → /backend-test K-01_種別一覧 → /backend-review K-01_種別一覧 →（指摘を直す）→ /deliver K-01_種別一覧

（画面のストーリー。例：S-13_種別管理）
/detailed-design S-13_種別管理 → /frontend-impl S-13_種別管理 → /frontend-test S-13_種別管理 → /frontend-review S-13_種別管理 →（指摘を直す）→ /deliver S-13_種別管理
```

- backend-impl・frontend-impl は、詳細設計がすでにあれば、それを読んで書き足す。
- 画面のストーリーの単体テストは、frontend-test で Playwright のテストを書く（テスト方針 5章）。結合テストは行わず、機能をまたいだ結合はシナリオテストで確かめる（2026-11-15 に決めた。テスト方針 2章）。

