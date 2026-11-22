#!/usr/bin/env bash
# check-merged.sh のテスト。一時フォルダに、本物の origin と同じ形のリポジトリを作って確かめる（GitHub には何もしない）。
# 使い方：bash test-check-merged.sh（どのフォルダからでもよい）
set -u

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/check-merged.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail=0
ok() { echo "  ok   $1"; }
ng() { echo "  FAIL $1"; fail=$((fail + 1)); }

# 期待する1行目と終了コードを確かめる
expect() { # 名前 期待する1行目 期待する終了コード コマンド...
  local name="$1" want="$2" code="$3"; shift 3
  local out rc
  out="$("$@")"; rc=$?
  local first="${out%%$'\n'*}"
  if [ "$first" = "$want" ] && [ "$rc" = "$code" ]; then ok "$name"; else ng "$name（期待：$want/$code、結果：$first/$rc）"; fi
}

git init -q --bare -b release/main "$work/origin.git"
git clone -q "$work/origin.git" "$work/dev" 2>/dev/null
cd "$work/dev" || exit 1
git config user.email t@example.com; git config user.name t
git checkout -q -b release/main
echo a > a.txt; git add a.txt; git commit -q -m "最初の commit"; git push -q -u origin release/main

echo "[check-merged.sh]"

# ブランチも履歴もない
expect "何もない → NOT_FOUND" NOT_FOUND 2 bash "$script" "$work/dev" ZPOP-169

# 設計ブランチを push（未マージ）
git checkout -q -b feature/ZPOP-169-b03-return-design
echo d > d.txt; git add d.txt; git commit -q -m "ZPOP-169 B-03：詳細設計を書いた"; git push -q origin feature/ZPOP-169-b03-return-design
expect "push しただけ → NOT_MERGED" NOT_MERGED 1 bash "$script" "$work/dev" ZPOP-169
expect "別のキー（ZPOP-16）は、ZPOP-169 のブランチに当たらない → NOT_FOUND" NOT_FOUND 2 bash "$script" "$work/dev" ZPOP-16

# マージ（GitHub の「Merge pull request」と同じ形）
git checkout -q release/main
git merge -q --no-ff feature/ZPOP-169-b03-return-design -m "Merge pull request #7 from owner/feature/ZPOP-169-b03-return-design"
git push -q origin release/main
expect "マージ後 → MERGED" MERGED 0 bash "$script" "$work/dev" ZPOP-169
expect "別のキー（ZPOP-16）は、マージ済みの ZPOP-169 に当たらない → NOT_FOUND" NOT_FOUND 2 bash "$script" "$work/dev" ZPOP-16
expect "別のキー（ZPOP-1699）→ NOT_FOUND" NOT_FOUND 2 bash "$script" "$work/dev" ZPOP-1699

# 同じキーの追加の作業ブランチ（修正）が未マージなら、NOT_MERGED
git checkout -q -b feature/ZPOP-169-b03-return-design-fix
echo e > e.txt; git add e.txt; git commit -q -m "ZPOP-169 B-03：レビューの指摘を直した"; git push -q origin feature/ZPOP-169-b03-return-design-fix
expect "同じキーの修正ブランチが未マージ → NOT_MERGED" NOT_MERGED 1 bash "$script" "$work/dev" ZPOP-169
git checkout -q release/main

# スカッシュ・マージ（ブランチは消える。commit の題だけが残る）
git checkout -q -b feature/ZPOP-170-b03-return-impl
echo i > i.txt; git add i.txt; git commit -q -m "途中の commit"; git push -q origin feature/ZPOP-170-b03-return-impl
git checkout -q release/main
git merge -q --squash feature/ZPOP-170-b03-return-impl; git commit -q -m "ZPOP-170 [実装] B-03 借りている備品を返す (#8)"
git push -q origin release/main
git push -q origin --delete feature/ZPOP-170-b03-return-impl
expect "スカッシュ・マージで、ブランチが消えた → MERGED（commit の題で分かる）" MERGED 0 bash "$script" "$work/dev" ZPOP-170

# 作っただけで、何も commit していないブランチ（release/main の祖先）は、証拠にならない
git checkout -q -b feature/ZPOP-171-b03-return-ut
git push -q origin feature/ZPOP-171-b03-return-ut
git checkout -q release/main
expect "空のブランチだけ → NOT_FOUND（マージの証拠がない）" NOT_FOUND 2 bash "$script" "$work/dev" ZPOP-171

# 入力の誤り・つながらない
expect "課題キーの形が違う → ERROR" ERROR 3 bash "$script" "$work/dev" zpop169
expect "フォルダがない → ERROR" ERROR 3 bash "$script" "$work/none" ZPOP-169
expect "引数がない → ERROR" ERROR 3 bash "$script"
rm -rf "$work/origin.git"
expect "origin につながらない → ERROR" ERROR 3 bash "$script" "$work/dev" ZPOP-169

echo
if [ "$fail" = 0 ]; then echo "すべて成功"; exit 0; else echo "$fail 件失敗"; exit 1; fi
