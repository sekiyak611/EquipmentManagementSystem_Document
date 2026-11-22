# 役割別の settings.local.json の例

開発の流れ（`決まり/開発フロー.md` 9章）で、AI に「自分の役割」を伝える設定。環境変数 `DEV_ROLE` を使う。

| ファイル | `DEV_ROLE` | 意味 | 人のレビュー |
|---|---|---|---|
| settings.local.junior.json | junior | 経験が浅いメンバー | 要る（MR は Draft で作る） |
| settings.local.senior.json | senior | 経験者のメンバー | 要らない |
| settings.local.leader.json | leader | リーダー（MR のマージも行う） | 要らない |

**使い方**（各自のPCで1回だけ）

1. 自分の役割のファイルを、Server と Client のフォルダの `.claude/settings.local.json` に写す（名前を `settings.local.json` に変える）。
2. すでに `.claude/settings.local.json` があるときは、上書きせず、中の `"env"` に `"DEV_ROLE": "<役割>"` を足す。
3. Claude Code を起動し直す。AI は `echo "${DEV_ROLE:-}"` で確かめる。

`.claude/settings.local.json` は、Git で管理しない（各自のPCの設定。CLAUDE.md の .gitignore の決まり）。役割が変わったら、この値を書き換える。
