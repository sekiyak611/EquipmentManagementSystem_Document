---
name: env-setup
description: 備品管理システムの開発環境（Windows のPC）を、Document の internaldesign/環境構築手順書.md のとおりに作る・確かめるときの手順。Java 21、PC に直接入れる MySQL 8.4.13（データベース2つと利用者）、secret.yml、Node.js 24.12.0、Eclipse（と Eclipse の Lombok）、Playwright、Claude Code の設定を、1つずつ人に案内し、最後にテストと /api/health で動くことを確かめる。
when_to_use: 「開発環境を作りたい」「新しいPCで動かしたい」「Docker をやめてローカルの MySQL を使いたい」「テストが動かない・つながらないので環境を見て」と頼まれたとき。Server・Client がまだ動かなくても、Document のフォルダで claude を起動して /env-setup と打てば使える。
argument-hint: "[確かめたい所（例：MySQL、Client）。空ならはじめから]"
---

# 開発環境を作る（Windows）

対象：$ARGUMENTS（空なら、はじめから順に進める）

**正本は Document の `internaldesign/環境構築手順書.md`**（以下「手順書」）。はじめに手順書を読み、そのとおりに案内する。この skill は、手順書の手順を Claude Code がどう確かめるかをまとめたもの。この skill と手順書が食い違ったら手順書が正しい。食い違いに気づいたら、人に知らせる。

インストールや管理者の操作は**人が行う**。Claude Code は、手順を1つずつ案内し、人が終えたら確かめのコマンドを動かして結果を伝える。

**守ること**
- パスワード・Slack のトークンを、Claude Code に見せない。`secret.yml` の中身を読まない・表示しない（あるかないかだけを確かめる。以前の Docker の手順で作った `.env` が残っていても、同じ）。人には、パスワードを会話に書かないよう伝える。MySQL に root でつながない。
- リポジトリを取ってくる（クローン）のは人が行う。環境構築では、ほかの Git の作業もしない。
- 版を変えない。手順書の 1.1・1.2 の版（Java 21、Node.js 24.12.0、MySQL 8.4.13）と違うものが入っていたら、そのことを人に伝える。手順書と違う版を勧めない。
- ライブラリの版を変えない（build.gradle・package.json に書いた版を使う）。
- Docker は使わない（CLAUDE.md 3章。2026-11-14 にやめた）。MySQL もサーバー・画面も、Docker に入れるよう勧めない。以前の手順で Docker の MySQL が動いているときは、手順書 5章で片づけるよう案内する。データを消す操作（`docker volume rm`、`DROP DATABASE` など）は、人に確かめてから案内する。

## 進め方

1. 手順書を読む。
2. 下の表の順に確かめのコマンドを動かし、まだ終わっていない所を見つける。
3. 終わっていない所を1つだけ、手順書のその手順を示して人に案内する。人が「できた」と言ったら、確かめのコマンドを動かす。
4. うまくいかなければ、出たエラーの文を、手順書 6章「つまずきやすい点」と比べて、直し方を案内する。テストの失敗は、エラーの文（`build/test-results/test/*.xml` の中）も読んで原因を確かめる。2回試してだめなら、エラーの文をそのまま人に見せて相談する。

Claude Code のコマンドは Git Bash で動く。PowerShell のコマンドは `powershell -NoProfile -Command "…"` で動かす。Server・Client のフォルダは、Document のフォルダから見て `../EquipmentManagementSystem_Server`・`../EquipmentManagementSystem_Client`。

| No. | 手順書 | やること | 確かめ（Claude Code が動かす） | うまくいったとき |
|---|---|---|---|---|
| 1 | 手順1 | Git と Claude Code | `git --version`、`claude --version` | 版が出る（Claude Code が動いている時点で、ほぼ済んでいる） |
| 2 | 手順2 | 3つのリポジトリを並べる | `ls ..` | `EquipmentManagementSystem_Server`・`_Client`・`_Document` が並んでいる |
| 3 | 手順3 | Java 21 | `java -version` | `21.` で始まる版（細かい版は問わない） |
| 4 | 手順4・5章 | MySQL 8.4.13 を入れる。古い MySQL・Docker の MySQL を片づける | `mysql --version`、`powershell -NoProfile -Command "Get-Service *mysql*"`、`docker ps`（Docker が入っているときだけ） | `Ver 8.4.13` を含む行が出る。`Running` の MySQL のサービスが、8.4.13 の1つだけ。`docker ps` に `equipment-mysql` が出ない（あれば手順書 5章を案内する。止める・消すのは人が行う） |
| 5 | 手順5 | データベース2つとユーザ `equipment` を作る | 終わったかを人に聞く（Claude Code は、MySQL に root でつながない。`equipment` のパスワードも知らない） | 人が「手順5の SQL を流し、`SHOW DATABASES;` で `equipment_dev` と `equipment_test` が出た」と答える |
| 6 | 手順6 | secret.yml | `test -f ../EquipmentManagementSystem_Server/secret.yml && echo ある`（中身は読まない） | 「ある」と出る。パスワードが手順5の `equipment` のものと同じか、`app.initial-admin-email` にメールアドレスの形の値を書いたか（空だと最初の起動で止まる）は、人に聞く（中身は見ない） |
| 7 | 手順7 | サーバーのテストと起動 | Server のフォルダで `./gradlew test`。続けて `./gradlew bootRun` を裏で動かし、起動したら `curl -s http://localhost:8080/api/health` | `BUILD SUCCESSFUL`、`"state":"UP"` が出る。確かめたらサーバーを止める |
| 8 | 手順8 | Node.js 24.12.0 と、PowerShell の npm | `node -v` と `powershell -NoProfile -Command "npm -v"` | `v24.12.0`。npm の版が出る（「デジタル署名されていません」と出たら手順8の2） |
| 9 | 手順9 | 画面の部品 | Client のフォルダで `npm install`、続けて `npx playwright install chromium` | エラーなし |
| 10 | 手順10 | 画面のテスト | 開発用のサーバーが動いていないことを確かめてから、Client のフォルダで `npx playwright test` | すべて passed |
| 11 | 手順11 | Eclipse と、Eclipse の Lombok（手順11の4） | Server のフォルダで `./gradlew -q dependencyInsight --dependency lombok --configuration compileClasspath` を動かし、1行目の Lombok の版を人に伝える。そのうえで、人に、エラーの印がないかと、「ヘルプ」→「Eclipse IDE について」に出る Lombok の版を聞く | エラーの印がない。Eclipse の Lombok の版が、build.gradle の版（Spring Boot が決めたもの）と同じ |
| 12 | 手順12 | Claude Code の設定 | `test -f ../EquipmentManagementSystem_Server/.claude/settings.json && test -f ../EquipmentManagementSystem_Client/.claude/settings.json && echo ある` | 「ある」と出る |
| 13 | 手順13 | Git で管理しないもの | Server・Client・Document の .gitignore を読み、Server・Client の CLAUDE.md 4章の一覧と比べる。足りなければ足す（CLAUDE.md 7章。git のコマンドは動かさない） | 一覧のものが入っている。とくに secret.yml（.env が残っていれば .env も） |

**版が違ったとき**
- 8.0 など、8.4.13 でない MySQL（例：MYSQL80）が動いている → 手順書 5章「8.0 から 8.4 への入れ替え」を案内する。
- Docker の MySQL（`docker ps` に `equipment-mysql`）が動いている → 手順書 5章の2を案内する（`docker stop equipment-mysql` は、人が確かめてから）。
- `mysql --version` が `8.4.13` でない → 人に伝えて相談する（勝手に良しとしない）。
- `java -version` が 21 でない → 手順書 6章の Path の直し方を案内する。
- `node -v` が v24.12.0 でない → 人に伝え、24.12.0 を入れるよう案内する（22.22.0 以上なら動くが、2人でそろえるため）。

## 最後に

手順書 4章「完了チェックリスト」の形で、できた所・できていない所の表を人に返す。できていない所は、次に何をすればよいかを1行で書く。
