# 詳細設計：動いているかを答える（health）

| 項目 | 内容 |
|---|---|
| 版 | v2.0 2026-11-08 |
| Jira | ZPOP-21（雛形：サーバー） |
| 状態 | 人の確認済み（2026-11-04。v2.0 は書き方だけを新しいテンプレートに合わせた） |
| もとにした設計書 | API設計.md v1.1 の3.1（A-08）・3.10（見張り役）、基本設計書.md 8章 |

## 1. 概要

写したもと：API設計.md v1.1 の3.1・3.10

アプリとデータベースが動いているかを答える。見張り役（アプリとは別のプログラム。AWS の Lambda、Java 21。ZPOP-46）が5分ごとに A-08 を呼ぶ。10秒以内に 200 が返らなければ失敗とし、2回続けて失敗したら開発者2人に DM を送る（見張り役の作りは、見張り役のタスクで書く）。

この機能は、controller → service → mapper の形を持つ最初の機能でもある。category（ZPOP-33）ができるまでは、ほかの機能はこの書き方に合わせる（CLAUDE.md 9章）。

### 1.1 API一覧

写したもと：API設計.md v1.1 の3.1

| ID | 操作 | URL | 内容 | 権限項目 | 画面 | 詳細設計 |
|---|---|---|---|---|---|---|
| A-08 | GET | /api/health | アプリとデータベースが動いているかを答える。動いていれば 200 で data は `{ "state": "UP" }`、データベースにつながらなければ 503（data は null）。版や設定などの詳しい情報は出さない | なし | 画面なし（見張り役のLambdaが5分ごとに呼ぶ。基本設計書8章） | [A-08_動いているかを答える.md](A-08_動いているかを答える.md) |

### 1.2 画面一覧

なし

### 1.3 業務のルール

なし（機能一覧に、この機能の行はない。A-08 は見張り役のために API設計 v0.4 で足した）

### 1.4 定期実行

なし（5分ごとに呼ぶのは、アプリの外の見張り役）

## 2. クラス・ファイル構成

パッケージの頭の `jp.co.highjunk.equipment` は省いて書く。

### 2.1 Server

| パッケージ | クラス・ファイル | 役割 | 使う API |
|---|---|---|---|
| health.controller | HealthController | A-08 の入口。HealthService を呼び、結果を ApiResponse.ok で包んで返す | A-08 |
| health.service | HealthService | データベースにつながるかを確かめる。つながらなければ ServiceUnavailableException を投げる | A-08 |
| health.model | なし | テーブルの1行を表すものがないため、作らない | |
| mapper.health | HealthMapper（インターフェース） | データベースを読み書きする部品。`@Mapper` を付けると、MyBatis が中身を自動で作る | A-08 |
| mapper.health | HealthMapper.xml（src/main/resources/jp/co/highjunk/equipment/mapper/health/） | SQL | A-08 |
| dto.health | HealthResponse | 返す data の形（state だけ）。state の型は HealthState | A-08 |
| （テスト）health | HealthApiTest | A-08 のテスト | A-08 |

### 2.2 Client

なし（画面はない）

### 2.3 足す Enum（common.constant）

| Enum | 値 | 意味（設計書の言葉） | 使う所 |
|---|---|---|---|
| HealthState | UP | 動いている（API設計 3.1 の `"state": "UP"`） | dto.health.HealthResponse |

### 2.4 使う共通部品

| 部品 | 使い方 |
|---|---|
| common.error.ApiResponse | 成功の返す値を ok で包む |
| common.error.ServiceUnavailableException | つながらないときに投げる。GlobalExceptionHandler が 503 に変える |
| common.security.SecurityConfig | /api/health を、ログインしていなくても呼べるようにしている（common.md 3.2） |

## 3. ほかの機能への影響

| No. | 種類 | 内容 | 相手（機能・部品） | 対応 |
|---|---|---|---|---|
| 1 | 設定値 | データベースにつながるまで待つ時間（5秒）は、全部の機能で共通の設定 | common（common.md 4章） | この機能のために変えない |
| 2 | 見張り役 | 見張り役は A-08 の 200 と時間だけを見る | 見張り役（ZPOP-46） | A-08 の答え方を変えるときは、見張り役も確かめる |

## 4. 設計書にない判断

| No. | 判断 | 理由 | 外から見えるか | 人の確認 |
|---|---|---|---|---|
| 1 | データベースにつながるまで待つ時間を5秒にした | 見張り役は10秒で失敗とみなすので、その前に 503 を返せるようにするため（common.md 10章の4） | いいえ | 済（2026-11-03） |

## 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.0 | 2026-11-03 | 初版（ZPOP-21 で作ったもの） |
| v1.1 | 2026-11-03 | リポジトリを3つに分けた形に合わせて、場所の書き方を直した |
| v1.2 | 2026-11-04 | パッケージ構成の変更：HealthMapper を mapper.health に、HealthResponse を dto.health に移した。state を Enum（common.constant.HealthState）にした |
| v2.0 | 2026-11-08 | 新しいテンプレートに合わせて、health.md を health/health.md（機能全体）と health/A-08_動いているかを答える.md（API詳細）に分けた。設計書の中身を写した。テストの章を外した（テストは証跡 evidence/20261103_単体結合API_基盤/ と evidence/20261104_単体結合API_パッケージ構成の変更/ を見る）。中身（作り）は変えていない |
