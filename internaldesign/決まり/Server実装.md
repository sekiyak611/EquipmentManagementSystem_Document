# 決まり：Server（Java）の実装

共通の決まり（internaldesign/CLAUDE.md）から移した。章の番号（4.1・5章・7章など）は、移す前の CLAUDE.md のまま。ほかの文書やコードのコメントが「CLAUDE.md 5章」のように呼ぶ番号と、食い違わないようにするため。 Server の API・部品を書く前に、必ず読む。

## 4.1 サーバー（Server）のパッケージ

パッケージ名の頭は `jp.co.highjunk.equipment`（2026-11-15 に、機能ごとの分け方から、1つの API に1つのパッケージの形に変えた）。

| パッケージ | 受け持つもの |
|---|---|
| api | API。1つの API に1つのパッケージ（一覧は Document の internaldesign/パッケージ構成変更/API_パッケージとクラス名_決定版.md。のちに API設計.md か詳細設計に移す） |
| api.auth | A-01〜A-07（ログイン・パスワード） |
| api.health | A-08 |
| api.equipment.mine | B-01〜B-05（自分の備品。社員向け） |
| api.equipment.management | C-01〜C-08、D-01〜D-03、E-01・E-02、I-02・I-03（備品・貸出履歴・確認の一括更新・取込。総務向け） |
| api.equipment.reminder | E-03・E-04（催促履歴） |
| api.equipment.category | K-01〜K-04 |
| api.user | G-01〜G-07、I-01 |
| api.role | H-01〜H-06 |
| batch.reminder | Slack 催促の定期実行（API ではない処理） |
| dao.mapper | MyBatis Generator が作る Mapper（テーブルごとに1つ）。全 API で共通 |
| dao.mapper.custom | 自動で作れない SQL を書く、手で書く Mapper（テーブルごとに1つ。例：EquipmentCustomMapper） |
| dao.entity.custom | 手で書く Mapper の結果の形のうち、テーブルの1行でないもの（例：種別ごとの備品の数 CategoryEquipmentCount。2026-11-15 に決めた） |
| dao.entity | MyBatis Generator が作る、テーブルの1行の形と Example（取得条件の Criteria＝「削除されていない」などの条件を1つずつ足していく部品） |
| common | 共通部品（下の表） |

| 共通部品 | 中身 |
|---|---|
| common.config | 設定値の読み込み、時計（java.time.Clock） |
| common.security | ログインと権限の確かめ方（Spring Securityの設定） |
| common.error | エラーの返し方（docs/API設計.md 2.4） |
| common.slack | Slack送信の部品と、テスト用の偽物・送った内容を読み出すAPI |
| common.csv | CSVの読み書き（UTF-8・Shift_JIS） |
| common.calendar | 祝日、催促日の計算（25日。土日祝日なら前の平日）、「今月確認済み」の判定 |
| common.passwordlink | パスワード設定用のリンク（合言葉）を作り、DMを送る（A-04、G-03、G-06で使う） |
| common.web | 組み立てた画面（Client の dist）を配る。画面のアドレスでは index.html を返す |
| common.equipment | 備品の一覧の1件の形を作る部品（EquipmentSummaryAssembler。C-01・C-06 で使う。2026-11-15 に決めた） |
| common.constant | Enum（列挙型＝決まった値だけを持つ型。例：備品の管理状態、権限項目のコード）。Enum はすべてここに置く |
| common.validation | 自作のチェック用アノテーション（ServiceInDto に付け、DB との整合性や Enum を確かめるもの。例：種別があるか）と、その中身（ConstraintValidator）。1つの API でしか使わないものも、ここに置く（2026-11-15 に決めた。API のパッケージどうしは使い合わないため）。ServiceInDto を確かめて例外に変える ServiceInDtoChecker と、確かめる順番（ServiceCheckOrder）・返し方の印（ServiceErrorType）もここ |
| common.text | 画面から受け取った文字の直し方（前後の空白を取る、大文字にするなど。TextInputs）。RestInDto が、形式のチェックの前に使う（2026-11-15 に決めた） |

- 2つ以上の API で使う処理と、API でない処理は、common に置く。API のパッケージどうしは使い合わないため（5章）。パッケージの名前は、その処理を作るときに決め、上の表に足す（2026-11-15 に決めた）。今あるもの：common.security の LoginUserInfoAssembler（ログインしている人の情報。A-01・A-03）と LoginUserRefresherImpl（権限項目の読み直し。API でない処理）、common.equipment の EquipmentSummaryAssembler（備品の一覧の1件の形。C-01・C-06）。
- パッケージ名は英小文字だけ。言葉はつなげて書く（例：`itemformanager`）。`import` は Java の予約語（Java が使うので名前にできない言葉）なので、取込は `importer` にする。
- 1つの API のパッケージの中を、controller・service・validator・model のパッケージに分け、次のクラスを置く（2026-11-15 に決め直した）。クラス名の頭（以下 `<頭>`）は、パッケージの `api` より後ろを全部つなげ、言葉の頭を大文字にしたもの（例：`api.equipment.management.search.item` → `EquipmentManagementSearchItem`）。

| クラス | 役割 |
|---|---|
| `controller.<頭>Controller` | API の入口。受け取る・Service を呼ぶ・返すだけ |
| `service.<頭>Service` | 業務の処理の interface（インターフェース＝メソッドの名前・受け取る値・返す値だけを決めた型） |
| `service.<頭>ServiceImpl` | 業務の処理の中身 |
| `controller.<頭>RestInDto` | 画面から受け取る値。形式のチェック（必須、文字数、形）をアノテーションで書く |
| `service.<頭>ServiceInDto` | Service に渡す値。Controller が、RestInDto・パスの値・ログインしている人の ID から作る。DB との整合性（重複、存在するか、使われているか）と Enum のチェックを、自作のチェック用アノテーション（common.validation）で書く |
| `model.<頭>RestOutDto` | 画面に返す値（この名前は、あとで変わるかもしれない。2026-11-15） |
| `validator.<頭>ValidatorDto` | Validatorに渡す値。ServiceImplの値をセットする |
| `validator.<頭>Validator` | 業務チェックをするためのクラス。 |

- 受け取る値・業務チェック・返す値がない API では、そのクラス（とパッケージ）は作らない（例：K-01 は受け取る値がないので RestInDto・ServiceInDto を作らない。K-04 は返す値がないので RestOutDto と model を作らない。種別の API は業務チェックがないので validator を作らない）。

```
jp.co.highjunk.equipment
├─ api
│  └─ equipment
│     └─ category
│        └─ update
│           └─ item          K-03（種別を変える）
│              ├─ controller/  EquipmentCategoryUpdateItemController、EquipmentCategoryUpdateItemRestInDto
│              ├─ service/     EquipmentCategoryUpdateItemService、EquipmentCategoryUpdateItemServiceImpl、
│              │               EquipmentCategoryUpdateItemServiceInDto
│              ├─ model/       EquipmentCategoryUpdateItemRestOutDto
│              └─ validator/   （業務チェックがある API だけ）<頭>Validator、<頭>ValidatorDto
├─ batch
│  └─ reminder/
├─ dao
│  ├─ mapper/          MyBatis Generator が作る Mapper
│  │  └─ custom/       手で書く Mapper
│  └─ entity/          テーブルの1行の形と Example
└─ common/
   └─ constant/        Enum（例：EquipmentStatus）
```

- MyBatis の XML は、`src/main/resources/jp/co/highjunk/equipment/dao/mapper/` に置く（MyBatis Generator が作る）。手で書く Mapper の XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/` に置く。
- Enum は、api・dao の中に作らない。1つの API でしか使わない Enum も common.constant に置く（同じ値の Enum が2つできるのを防ぐため）。
- テストは、本体と同じパッケージ名で `src/test/java` に置く（API のテストは、その API のパッケージ。controller などの下ではなく、その上。例：`jp.co.highjunk.equipment.api.equipment.category.search.item`）。

## 4.2 見張り役（monitor）のパッケージ

- パッケージ名は `jp.co.highjunk.equipment.monitor`。
- Server の部品は共有しない。Slackへ送る処理も monitor の中に書く。DMの文面と送り方は、Server の common.slack とそろえる。

## 5. 書き方の決まり：サーバー（Java）
- パッケージは 4.1 のとおり、1つの API に1つ。業務のルールは ServiceImpl に書き、Controller には書かない（2026-11-15 に決めた）。
- Controller には、その API の URL と操作を1つだけ書く。
- Controller は、RestInDto・パスの値・ログインしている人の ID から ServiceInDto を作り、Service に渡す（2026-11-15 に決めた）。Service は、受け取る値を ServiceInDto だけにする（RestInDto やパスの値をそのまま受け取らない）。受け取る値がない API（例：一覧で条件がないもの）は、ServiceInDto を作らない。
- Service は、interface の `<頭>Service` と、中身の `<頭>ServiceImpl`（`implements <頭>Service`）に分け、どちらも service のパッケージに置く。`@Service` は ServiceImpl に付ける。Controller は、自分の API の Service の interface を受け取って使い、ServiceImpl を直接使わない。
- API のパッケージは、ほかの API のパッケージのクラスを使わない（同じまとまりの API どうしも同じ）。使ってよいのは、`common` と `dao` だけ。`batch` も同じで、使ってよいのは `common` と `dao` だけ（api と batch は互いに使わない）。`common` と `dao` から `api`・`batch` を使わない。循環（AがBを使い、BもAを使う形）を作らない。
- 2つ以上の API で使う処理と、API でない処理は、common に置く（4.1）。API でない処理のクラスは、役目を表す名前にする（例：ログイン中の人の情報を読み直す LoginUserRefresher）。
- 確かめることは、次の3つに分ける。
  - RestInDto：画面設計のとおりの形式のチェック（受け取った値だけで分かるもの。必須、文字数、形式、数の範囲など）。`@NotBlank`・`@Size` などのアノテーションで書き、Controller の引数に `@Valid` を付けて確かめる（Bean Validation＝アノテーションで値を確かめる仕組み）。
  - ServiceInDto：DB との整合性と Enum のチェック（例：同じ名前の種別がもうある、使われている種別は消せない、すでに貸し出されている、その人が操作してよい対象か）。自作のチェック用アノテーション（`ConstraintValidator`＝自作のチェックの中身を書くための Bean Validation の仕組み。Mapper を読める）で書き、common.validation に置く（4.1）。新しく足すときは、common の変更として2人で相談する（9章）。ServiceImpl の `@Transactional` の中で、Bean Validation で確かめる（確かめてから書き換えるまでを1つのまとまりにするため）。受け取った値だけで、DB と照らせば確かめられるもの（ある・重なる・version・使われている・Enum など）はここに書く。
  - ServiceInDto のチェックは、読むだけにする（Mapper の取得・数える処理だけを使う）。書き換えは ServiceImpl で行う。
  - Validator：業務チェックのうち、ServiceImpl が読んだ・計算した値が要るもの（例：貸出の期間の重なり、その人が借りている備品か。2026-11-15 に決めた）。`validator.<頭>Validator`（`@Component`）に書き、ServiceImpl が `validator.<頭>ValidatorDto` に値を入れて、`@Transactional` の中で、書き換えの前に呼ぶ。守れなければ、その場で common.error の例外（NotFoundException・ConflictException・BusinessRuleException・FieldErrorException など）を投げる。読むだけ（Mapper の取得・数える処理だけ）で、書き換えない。Controller からは呼ばない。業務チェックがない API では作らない。
  - チェックのメッセージは、画面設計の文のまま。守れないときに返す状態コード（404・409・422 など）と文は、API設計とその API の詳細設計のとおり。ServiceInDto のチェックからの返し方は、次のとおり（2026-11-15 に決めた。お手本は api.equipment.category）。
    - ServiceImpl は、`@Transactional` のメソッドの中で、書き換えの前に `common.validation.ServiceInDtoChecker#check(ServiceInDto)` を呼ぶ。
    - 確かめる順番は、チェック用アノテーションの groups で決める：`ServiceCheckOrder.First`（対象があるか）→ `ServiceCheckOrder.Second`（対象の今の状態と合うか。version、使われているか など）→ groups なし（そのほか。重なり など）。ある段で守れないものがあれば、そこで止める。
    - 返し方は、チェック用アノテーションの payload で決める：`ServiceErrorType.NotFound`（404。NotFoundException）、`ServiceErrorType.Conflict`（409。ConflictException。文はアノテーションの message）、`ServiceErrorType.BusinessRule`（400。BusinessRuleException。errors なし）、payload なし（400。FieldErrorException。errors に入力欄ごとの文。並び順は ServiceInDto の項目の順）。
    - クラスに付けるチェック（2つ以上の項目を見るもの。例：version が同じか、自分を除いて名前が重ならないか）は、アノテーションの中の Target という interface を ServiceInDto が実装して、値を渡す。入力欄のエラーにするときは、誤りを入力欄（項目の名前）に付ける。
- DB の読み書きは、`dao.mapper` の Mapper で行う。取得の条件は、`dao.entity` の Example の Criteria で組み立てる（例：`example.createCriteria().andDeletedAtIsNull()`）。
- MyBatis Generator が作ったファイル（`dao.mapper`・`dao.entity` と、その XML）は手で直さない。テーブルが変わったら作り直す。自動で作れない SQL（件数をまとめる SQL など）は、手で書く Mapper を `dao.mapper.custom` に置く（XML は `src/main/resources/jp/co/highjunk/equipment/dao/mapper/custom/`）。手で書く Mapper は、自動で作り直しても消えない。
- Controller は、Web のセッションを扱う common.security.LoginSession（ログインの開始・終了）だけは、Service を通さずに呼んでよい。業務のルールとデータベースの読み書きは、これまでどおり Service に書く（2026-11-10 に決めた例外。Service に HttpServletRequest を渡さないため。詳細設計 common.md 3.10）。
- 2つ以上の API で使う業務のルール（4.1の common.calendar・common.passwordlink など）は、common に1つだけ置き、書き写さない。
- API をまたいで同じルールが書かれている所（貸出のルール：equipment.mine・equipment.management（取込を含む）、確認のルール：equipment.mine・equipment.management）は、1か所を直したらほかも同じように直し、テストも直す。
- SQLで JOIN とサブクエリ（SQLの中にもう1つSQLを入れる書き方）を使わない。複数のテーブルの情報は、テーブルごとにSQLを出し、Javaで突き合わせる。
- 1件ずつSQLを出さない（N+1問題＝一覧の件数だけSQLが出てしまう問題を防ぐ）。IDをまとめて集め、`IN`（Example の `andIdIn`、手で書く XML なら `<foreach>`）で1回で読む。
- 今の日時は、直接取らずに java.time.Clock から取る（テストで日時を止められるようにするため）。
- APIごとに、必要な権限項目をサーバー側で必ず確かめる（例：@PreAuthorize("hasAuthority('EQUIPMENT_UPDATE')")）。権限項目のコードは docs/データ設計.md の5.3。
- 画面設計に書かれたチェック（形式のチェックと DB との整合性のチェック）は、サーバー側でも必ず行う。画面側のチェックだけに頼らない。
- 編集するAPIは、楽観ロック（version 列）で、ほかの人が先に保存していたら 409 を返す。
- SQLは MyBatis の XML に書く（MyBatis Generator が作るものと、dao.mapper.custom に手で書くもの）。値は必ずパラメータ（#{}）で渡し、文字をつなげてSQLを作らない（SQLインジェクション＝外から入れた文字でデータベースを操られる攻撃を防ぐため）。
- 削除は論理削除（deleted_at）。一覧や検索では、削除済みの行を出さない。
- 2つ以上の書き換え（INSERT・UPDATE・DELETE）を1つの操作として行う処理は、ServiceImpl のメソッドに `@Transactional` を付け、途中で失敗したら全部を元に戻す。Controller・Mapper と、interface の `<頭>Service` には付けない。
- Slack の送信は、`@Transactional` の中で行わない。データベースへの書き込みが確定してから送る（送ったのにデータベースは元に戻った、を防ぐため）。送るのに失敗したときの扱いは、その機能の設計書・詳細設計に従う。
- 操作する対象（備品・貸出など）の ID を画面から受け取る API は、権限項目の確認に加えて、その人が操作してよい対象かを ServiceInDto のチェックか Validator で確かめる（受け取った値だけで確かめられるなら ServiceInDto、ServiceImpl が読んだ値が要るなら Validator）（例：B-03 の返す・B-04 の確認したは、ログインしている人が借りている備品だけを対象にする。B-04 は docs/API設計.md 4.7 のとおり、ほかの人の備品が含まれていたら 403）。ID を書き換えて他人のデータを読む・変えることを防ぐため（IDOR と呼ばれる穴）。

