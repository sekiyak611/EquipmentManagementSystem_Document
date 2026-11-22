#!/usr/bin/env bash
# 前の工程のプルリクエスト（MR）が、release/main に入っているかを判定する。
# 決まりは Document の internaldesign/決まり/開発フロー.md（ゲート A・B・C）。
#
# 使い方：bash check-merged.sh <リポジトリのフォルダ> <サブタスクの Jira 課題キー>
#   例：bash ../EquipmentManagementSystem_Document/tools/check-merged.sh ../EquipmentManagementSystem_Document ZPOP-169
#
# 判定のしかた（読むだけ。git fetch でリモートの情報を更新するほかは、何も変えない）
#   1. 課題キーを含む作業ブランチ（origin/feature/<課題キー>-…）が、release/main に入っていなければ NOT_MERGED
#   2. 入っていれば、release/main の履歴に、課題キーで始まる commit か、そのブランチの「Merge pull request」があるかを見て、あれば MERGED
#   3. ブランチも履歴の証拠もなければ NOT_FOUND（まだ始めていない、または、マージされずに消された）
# 出力の1行目：MERGED／NOT_MERGED／NOT_FOUND／ERROR のどれか。2行目からは、根拠（ブランチ名・commit）。
# 終了コード：0=MERGED、1=NOT_MERGED、2=NOT_FOUND、3=ERROR

set -u

repo="${1:-}"
key="${2:-}"

if [ -z "$repo" ] || [ -z "$key" ]; then
  echo "ERROR"
  echo "使い方：check-merged.sh <リポジトリのフォルダ> <サブタスクの課題キー>"
  exit 3
fi
if ! printf '%s' "$key" | LC_ALL=C grep -Eq '^[A-Z][A-Z0-9]*-[0-9]+$'; then
  echo "ERROR"
  echo "課題キーの形が違う：$key（例：ZPOP-169）"
  exit 3
fi
if [ ! -d "$repo" ]; then
  echo "ERROR"
  echo "リポジトリのフォルダがない：$repo"
  exit 3
fi
if ! git -C "$repo" fetch origin --quiet 2>/dev/null; then
  echo "ERROR"
  echo "git fetch に失敗した（ネットワークか、GitHub のログインを確かめる）：$repo"
  exit 3
fi

base="origin/release/main"
if ! git -C "$repo" rev-parse --verify --quiet "$base" >/dev/null; then
  echo "ERROR"
  echo "$base がない：$repo"
  exit 3
fi

# 1. 課題キーを含む作業ブランチで、release/main に入っていないものがあるか（キーのあとに - が続く名前だけ。ZPOP-16 と ZPOP-169 を区別する）
unmerged=""
branches=$(git -C "$repo" for-each-ref --format='%(refname:short)' "refs/remotes/origin/feature/${key}-*")
for b in $branches; do
  if ! git -C "$repo" merge-base --is-ancestor "$b" "$base"; then
    unmerged="${unmerged}${b}"$'\n'
  fi
done
if [ -n "$unmerged" ]; then
  echo "NOT_MERGED"
  printf '未マージのブランチ：\n%s' "$unmerged"
  exit 1
fi

# 2. release/main の履歴に、このキーの commit か、このキーのブランチの Merge pull request があるか
pattern="^[0-9a-f]+[[:space:]](${key}([^0-9A-Za-z]|\$)|Merge pull request #[0-9]+ from [^[:space:]]*/feature/${key}([^0-9]|\$))"
hit=$(git -C "$repo" log "$base" --max-count=5000 --format='%h%x09%s' | LC_ALL=C grep -E "$pattern" | head -n 3)
if [ -n "$hit" ]; then
  echo "MERGED"
  printf '%s\n' "$hit"
  exit 0
fi

echo "NOT_FOUND"
echo "release/main にも、origin/feature/${key}-… のブランチにも、証拠がない（まだ始めていない、またはマージされずに消された）"
exit 2
