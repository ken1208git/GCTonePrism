# 変更履歴

このプロジェクト（TonePrism）の重要な変更点を全て記録します。

このファイルの形式は [Keep a Changelog](https://keepachangelog.com/ja/1.0.0/) に従い、
このプロジェクトは [Semantic Versioning](https://semver.org/lang/ja/) に準拠しています。

**注意**: このCHANGELOGはソフトウェア本体のバージョンを追跡します。仕様書の変更履歴については、[SPECIFICATION.md](SPECIFICATION.md)の「変更履歴」セクションを参照してください。

---

## Bundle（リリース全体 / `RELEASE_VERSION`）

リリース zip 全体に付与する独立バージョン。GitHub Releases の本文として `Release.ps1` がこのセクションを抜き出して使う。エンドユーザー（来場スタッフ / 顧問の先生 / 部員）向けの **summary** を書く。技術詳細は `## Launcher` / `## Manager` / `## Release Tooling` 等の別セクションを参照。詳細仕様は [SPECIFICATION.md §3.7.7](SPECIFICATION.md) を参照。

### [Bundle v0.11.0] - 2026-09-04

**来場者のプレイ記録とアンケートを集められるようになった**リリースです。ゲームを遊び終えるたびにプレイ記録が自動で保存され、遊び終わったときと席を離れるときに**★評価と感想のアンケート**が出ます。あわせて、来場者がその日 1 本目のゲームを始める直前に**やめかた（HOME キー / Guide ボタン）の案内**を表示するようにしました。

主な変更:
- **プレイ記録とアンケートの収集を開始（#297 / #34 / #35）**: 記録は共有フォルダの `responses/` に 1 件 1 ファイルで保存されます。**来場者の画面・操作は変わりません**（記録は裏側で走ります）。アンケートは★1〜5 と、書きたい人だけが開く感想欄です。答えたくない人は「答えない」で断れます。
- **アンケートの表示は管理ソフトから切り替えられます（#35）**: 「設定 → アンケート」で「ゲーム終了時」「退出時」を**個別にオン/オフ**でき、**切り替えた瞬間に全パソコンへ反映**されます（再起動不要）。混雑してきたら高頻度な「ゲーム終了時」だけ切る、という使い方ができます。**落ち着いたら戻すのを忘れずに。**
- **やめかたの案内を追加（#344）**: その日 1 本目のゲームを始める直前に、中断メニューの開き方を 1 回だけ案内します。
- **開場前の点検項目が増えました（#297）**: 点検メニューに「**6. 記録・アンケートの動作確認**」を追加。**当日の朝、ここが全部 ✓ になっていることを必ず確認してください。** 記録はその日にしか取れず、取り直しができません。**スタッフの試遊では確認できません**（試遊は集計を汚さないよう意図的に記録から除外しているため）。

**アップデート方法**: Manager の「アップデート」タブから適用。**今回は DB スキーマが変わります（v23 → v24）**。Manager を起動すると自動で更新され、既存のゲームには内部の管理番号が自動で振られます。**更新前に「バックアップ」タブで手動バックアップを取っておいてください。**

- Launcher: v0.11.8 → v0.15.0（プレイ記録 #34 ／ アンケート #35 ／ 点検項目 #297 ／ やめかた案内 #344）
- Manager: v0.32.0 → v0.34.0（DB v24 = `games.game_no` 追加 #297 ／ 設定にアンケートのトグル #35）
- LauncherAgent: v0.3.0（変更なし）／ Updater: v0.2.1（変更なし・自己更新の番人として .NET 4.8 据え置き）

**Notes**: 機能追加のため Bundle minor bump（v0.10.0 → v0.11.0）。**DB スキーマ変更（v23 → v24）を含むが major bump にはしない判断**をした — 規約（AGENTS.md / SPEC §3.7.7）は「DB schema 変更は major」と定めるが、今回の変更は `games` への列追加 + backfill のみで後方互換があり（旧 Launcher + 新 DB でも動作、新 Launcher + 旧 DB は記録を書かないだけ）、かつバンドル更新でコンポーネント間のスキーマ整合は自動保証される（SPEC §3.7.3）ため。**破壊的変更を伴う次のスキーマ変更では major を検討すること。** なお集計（ストアの「人気ランキング」「最近プレイ」を実データで動かす）は本リリースには含まれず、文化祭後に対応予定。

### [Bundle v0.10.0] - 2026-09-02

**管理ソフト（Manager）の画面を一新**したリリースです。ゲーム管理の画面を新しいデザイン（WPF）に刷新し、起動時に**ダッシュボード**（準備状況が一目でわかる画面）を表示、ゲーム編集まわりの使い勝手を改善しました。あわせて、**ゲームのサムネイル・背景画像を、パソコンのどこにある画像からでも設定できる**ようになりました（設定した画像は自動でゲームフォルダ内に取り込まれ、他の PC やファイルサーバから開いても正しく表示されます）。**基本的な使い方は同じ**ですが、見た目が新しくなっています。

主な変更:
- **管理ソフトの画面を新デザイン（WPF）に刷新（#245 / #368）**: 左サイドバーで画面を切り替えるモダンな見た目に。起動時にダッシュボード（要対応チェックリスト・概況・LAN ランチャーの状態）を表示。
- **ゲーム編集画面を刷新（#324 / #242 / #383）**: 入力まわりを整理。編集中に別画面へ移動しようとすると「未保存の変更があります」と確認するようになりました。
- **画像をどこからでも取り込めるように（#386）**: ゲーム**編集**画面で、デスクトップ等ゲームフォルダの外にある画像もサムネイル/背景に選べます。保存すると自動でゲームフォルダ内（各バージョンの `.toneprism` フォルダ）へコピーされ、別 PC／ファイルサーバでも画像が壊れません。元の画像は消えません。

**アップデート方法**: Manager の「アップデート」タブから適用。**DB スキーマの変更はありません**（v23 のまま・データはそのまま）。念のため、更新前に「バックアップ」タブで手動バックアップを取っておくことを推奨します。

- Manager: v0.27.9 → v0.32.0（WPF 画面刷新 #245 / #368 ／ ダッシュボード ／ ゲーム編集 WPF 化 #324 ／ 未保存ガード #383 ／ 画像 `.toneprism` 取り込み #386）
- Launcher: v0.11.8（変更なし）
- LauncherAgent: v0.3.0（変更なし）／ Updater: v0.2.1（変更なし・自己更新の番人として .NET 4.8 据え置き）

**Notes**: 大きな機能追加（管理ソフトの WPF 画面刷新）のため Bundle minor bump（v0.9.0 → v0.10.0）。DB スキーマ変更なし（v23 据え置き）。**ゲーム「追加」画面はまだ従来（WinForms）**で、次回以降で WPF 化予定（#324）＝当面、新規ゲームは**サムネ無しで追加 → 編集画面でサムネを設定**する運用を推奨（追加画面でのサムネ指定は従来どおりゲームフォルダ内の画像限定）。

### [Bundle v0.9.0] - 2026-06-12

**管理ソフトの内部基盤を最新化**したリリースです。管理ソフト（Manager）と Launcher 補助エージェント（LauncherAgent）を **.NET 10** に移行し、配布を **1 ファイルにまとめた形式**（必要なものを exe に内包・解凍してすぐ起動・追加インストール不要）に切り替えました。**画面の見た目・操作は変わりません**（来場スタッフ・部員の使い方はそのまま）。あわせてアプリの表示名を「ランチャー」「マネージャー」に統一しました。

主な変更:
- **管理ソフト(Manager)を .NET 10 + 単一ファイル配布に刷新**: これまで複数ファイルだった Manager フォルダが `TonePrism_Manager.exe` 1 個になりました（中に必要なものを全部内包）。動作・画面は従来どおり。
- **LauncherAgent も同様に .NET 10 + 単一ファイル化**: ゲーム中の中断メニュー（HOME メニュー）を支える常駐プログラムも同じ形式に統一。
- **アプリ表示名の統一**: 「ランチャー」「マネージャー」表記に揃えました（#351）。

**アップデート方法**: Manager の「アップデート」タブから適用。**DB スキーマの変更はありません**（v23 のまま・データはそのまま）。Manager / LauncherAgent はファイルをまとめた分サイズが大きくなっています（ダウンロードに少し時間がかかる場合があります）。

- Launcher: v0.11.7 → v0.11.8（表示名統一 #351）
- Manager: v0.27.4 → v0.27.9（.NET 10 + 単一ファイル配布 #258 ／ 表示名統一 #351）
- LauncherAgent: v0.2.1 → v0.3.0（.NET 10 + 単一ファイル配布 #258 PR4.x）
- Updater: v0.2.1（変更なし・自己更新の番人として .NET 4.8 据え置き）

**Notes**: 内部基盤の刷新（.NET 10 化・配布形態変更）という大きな土台変更のため Bundle minor bump（v0.8.3 → v0.9.0）。DB スキーマ変更なし（v23 据え置き）。配布は win-x64 専用＝**32bit Windows は非対応**になりました（本番 PC は全て 64bit のため影響なし）。

### [Bundle v0.8.3] - 2026-06-11

**ストア画面の仕上げ**をまとめたリリースです。v0.8.2（6/10）以降、本番カタログの準備中に見つかった表示・操作の引っかかりを解消しました（新機能はなく、見やすさ・操作感の改善が中心です）。

主な変更:
- **ストアのスライドショー／タイルにもセクション名（見出し）を表示**: 通常の列と同じく「おすすめ」「はじめての人に」などの見出しが付き、選んだ先のカルーセルが「何の集まりか」分かりやすくなりました。
- **トラックパッドでストアが超高速スクロールする問題を修正**: ノートPC のタッチパッドで快適にスクロールできます（マウスホイールは従来どおり）。
- **ストアの「ランダム」枠で最大表示数が正しく効くように**: 設定した件数だけ表示されます（以前は開くと全件出ていました）。
- **初回説明の「画像＋本文」レイアウトの片寄りを修正**: ロゴ等の画像と本文が中央に寄って見やすくなりました。

**アップデート方法**: Manager の「アップデート」タブから適用。**DB スキーマの変更はありません**（v0.8.0 以降と同じ v23 のまま・データはそのまま）。

- Launcher: v0.11.6 → v0.11.7（ストアのセクション見出し #345 ／ トラックパッドスクロール ／ ランダム枠の件数 ／ top_bar グラデ整理 ／ 初回説明の画像レイアウト）
- Manager: v0.27.4（変更なし）
- LauncherAgent: v0.2.1（変更なし）／ Updater: v0.2.1（変更なし）

**Notes**: 表示・操作の磨き込みのみのため Bundle patch bump（v0.8.2 → v0.8.3）。DB スキーマ変更なし（v23 据え置き）。

### [Bundle v0.8.2] - 2026-06-10

**展示画面の表示の磨き込みと、スタッフ向け試遊テストの強化**をまとめたリリースです。v0.8.1（6/8）以降の改善 9 件を一本化しました（機能はそのまま、表示・操作・点検まわりの改善が中心です）。

主な変更:
- **サムネイル無しゲームの表示を統一 (#316 / #293)**: ゲーム選択・プレイ中・中断メニューで「NO IMAGE」の見た目（明るいグレーの箱）と文字サイズを統一。説明文が未入力のゲームは案内文を半透明で表示します。
- **ストアが空でも操作不能にならないように (#315)**: ストアにセクションが 1 つも無いとき、空のストア画面ではなく直接ゲーム選択（カルーセル）画面へ進みます。
- **WOLF 製ゲーム等で中断メニューから戻れない問題を修正 (#314)**: 全画面表示で自動的に最小化するタイプのゲームでも、中断メニューの「続ける」で正しくゲームに復帰できるようになりました。
- **スタッフ向け試遊テストを強化 (#311)**: サービスモードの試遊テストで**本番と同じ中断メニュー**を確認できるようになりました。ゲームごとに「遊べたか」「中断メニューが動いたか」の 2 つを 〇× で記録。試遊中の中断メニューは「続ける／試遊を終了する」の 2 択。サービスモード内の確認ダイアログがキーボード・コントローラーで操作できるようになり、60 秒を超える試遊でゲームが強制終了される不具合も修正しました。
- **リリース年・期生を「不明」のまま登録可能に (#313)**: 年や期生が分からない古いゲーム・製作者を空欄（不明）のまま登録できます。
- **並び順・表示の修正 (#327 / #328 / #329)**: ジャンル未設定のゲームで「&lt;null&gt;」タグが表示されるのを修正。「すべてのゲーム」一覧とストアの一部セクションの並びを名前順に統一しました。
- **未実装の「人気ランキング」「最近プレイ」をストア設定の選択肢から一時除外 (#297 の一部)**: 本物のランキング機能（v0.9.0 予定）が入るまで、スタッフが誤って選べないようにしました。

**アップデート方法**: Manager の「アップデート」タブから適用。**DB スキーマの変更はありません**（v0.8.0 以降と同じ v23 のまま・データはそのまま）。

- Launcher: v0.11.1 → v0.11.6（NO IMAGE 統一 #316・#293 ／ 空ストア #315 ／ 並び順・タグ #327・#328・#329 ／ 試遊テスト強化 #311）
- Manager: v0.27.2 → v0.27.4（不明（空欄）登録 #313 ／ ランキングソース一時除外 #297）
- LauncherAgent: v0.2.0 → v0.2.1（全画面ゲームの最小化復帰修正 #314）／ Updater: v0.2.1（変更なし）

**Notes**: 不具合修正・表示/運用調整主体（新規エンドユーザー機能なし）のため Bundle patch bump（v0.8.1 → v0.8.2）。DB スキーマ変更なし（v23 据え置き）。

### [Bundle v0.8.1] - 2026-06-08

**文化祭本番に向けた、初回説明と入力まわりの小さな不具合修正**をまとめたリリースです。v0.8.0（6/7）直後に見つかった表示・操作の引っかかりを解消しました（機能追加はなし）。

主な変更:
- **初回説明・ゲーム説明文の改行が正しく表示されるように (#318)**: Manager で改行を入れた説明文が、ランチャー側で「2 行ぶん空く」表示になっていたのを修正。本文だけの初回説明スライドは横幅を広げて読みやすくしました。
- **入力途中の Enter で誤って保存される事故を防止 (#312)**: ゲームの追加／編集／バージョンアップ／初回説明スライドの各画面で、リリース年などを入力中に Enter を押すと保存が走ってしまう問題を修正。説明文・本文欄では Enter が**改行**になります（保存は保存ボタンで行います）。
- **初回説明画面で Alt+F4 の終了案内が一瞬で消える不具合を修正 (#320)**: 終了案内ダイアログがすぐ引っ込まず、きちんと表示されたままになります。
- **整合性チェックの案内文を最新の実態に訂正 (#317)**: 「バックアップ／復元の対象は DB（登録情報）だけ」という古い案内を、「ゲームファイル本体・初回説明の画像も対象」に直しました。

**アップデート方法**: Manager の「アップデート」タブから適用。**DB スキーマの変更はありません**（v0.8.0 と同じ v23 のまま・データはそのまま）。

- Launcher: v0.11.0 → v0.11.1（初回説明／ゲーム説明の改行正規化・本文幅 #318 ／ Alt+F4 終了案内ダイアログ #320）
- Manager: v0.27.1 → v0.27.2（フォームの Enter 誤保存防止・複数行欄の改行解禁 #312 ／ 整合性レポート文言訂正 #317）
- LauncherAgent: v0.2.0（変更なし）／ Updater: v0.2.1（変更なし）

**Notes**: バグ修正・表示調整のみのため Bundle patch bump（v0.8.0 → v0.8.1）。DB スキーマ変更なし（v23 据え置き）。

### [Bundle v0.8.0] - 2026-06-07

**展示の「初回説明」と、バックアップ／復元まわりを大きく強化**したリリースです。前回 v0.7.0（5/27）以降の約20件の改善を一本化しました。

主な変更:
- **「初回説明」機能を追加 (#253)**: スクリーンセーバー →（キー押下）→ ストアの間に、展示の楽しみ方・注意事項の案内スライドを表示。来場者は入れ替わるため毎回表示。Manager に「初回説明」タブが増え、スライド（本文＋画像）を登録・並び替えできます。
- **バックアップがゲームファイルごと・操作のたびに自動で残る (#250 / #295 / #299)**: 従来 `toneprism.db`（登録情報）だけだったのを、**ゲームファイル本体（games/）と初回説明画像（guide/）も重複排除プール方式で同時に控える**ように。タイミングも「起動時の時間間隔」→「**データ変更操作の直後**」へ。進捗は画面下部バー表示で操作は止めません。
- **復元が「その時点まるごと」に進化 (#250)**: 復元で登録情報（DB）だけでなく**ゲームファイル本体・初回説明画像もその時点に戻せる**ように（戻す前に自動退避＝やり直し可）。
- **ストア特集枠の強化 (#211 / #212 / #291)**: スライドショー／タイルグリッドで人気・最近プレイ・ランダムを使用可に、表示数制御も整理。「制作年で絞る」セクション追加。
- **Launcher を立てたまま Manager で編集OK (#278)**: 開場後でも安全に編集できるよう競合検出を改善（PC 間の時計ズレにも強く）。
- **プレイ記録・アンケート保存方式を刷新する土台 (#297 第1弾)**: SQLite 取り込みをやめ Launcher が JSON 直読み集計する方式へ転換する基盤を整備。**※実際の記録・人気ランキング・アンケート画面は次回以降**（今回は内部整理のみ）。
- **フォルダ選択でウィンドウが縮む不具合を修正 (#308)**: 高 DPI（拡大率 200% 等）環境でゲームフォルダ選択を開くたびに Manager が縮む問題を修正。
- そのほか復元失敗時の案内改善、ゲーム版の個別削除、各種データ損失・クラッシュ修正を含みます。

**アップデート方法**: Manager の「アップデート」タブから適用。**ゲームデータは自動保護**され、内部 DB スキーマも自動で v14 → v23 に移行します（すべて非破壊・互換、手動再インストール不要）。

- Launcher: v0.9.1 → v0.11.0（初回説明表示 #253 / ストア特集強化 #211・#212・#291 / 版数 SoT 一本化 #281 / DB 読み取り解放 #278 / DB v23 追従 #297）
- Manager: v0.16.4 → v0.27.1（初回説明タブ #253 / バックアップ・復元の DB+アセット拡張 #250・#295・#299 / ストア条件UI #211・#212 / 版削除 #209 / セッション競合・時計ズレ対策 / プレイ記録・アンケート JSON 直読み化 #297 / フォルダ選択 DPI 縮み修正 #308）
- LauncherAgent: v0.2.0（変更なし）／ Updater: v0.2.1（変更なし）

**Notes**: 機能追加主体のため Bundle minor bump（v0.7.0 → v0.8.0）。DB v14 → v23 は複数段だが**すべて非破壊・自動 migration**（空テーブル撤去・列追加・制約追加・FK 追加等）で、v0.7.0 の v13→v14 同様に自動アップデートで適用できます。

### [Bundle v0.7.0] - 2026-05-27

**運営スタッフ向けの当日機能と操作性を大きく強化**したリリースです。ランチャーにサービスモード（診断メニュー）とコントローラからのゲーム復帰を追加し、Manager のゲーム編集まわりのデータ損失も修正しました。

主な変更:
- **サービスモード（スタッフ専用の診断メニュー）を追加**: `Ctrl+Alt+F12` で開く全画面メニューから、入力チェック（接続中コントローラ／押下ボタン確認）・音声テスト・画面表示テスト・ゲーム動作テスト（存在/起動/試遊）・ネットワーク接続テスト（IP〜共有サーバー速度〜Monitor）・DB 整合性・ログ確認・システム情報・モニタ選択・再起動などを開場前チェックできます。キーボードとコントローラ両対応。
- **コントローラの Guide ボタン／キーボード HOME でゲームから復帰**: ゲーム中に Guide / HOME を押すと中断オーバーレイが出てランチャーへ戻れます。あわせてゲームの「起動中→プレイ中」遷移検知、ランチャーが誤って前面に出た時の自動復帰、マルチモニタでゲーム窓をランチャー側モニタへ寄せる処理を、新しい常駐ヘルパー **LauncherAgent** に集約しました。
- **ランチャーの終了を一本化（誤終了防止）**: `Alt+F4` と `×` ボタンを封印し、サービスモードの「ランチャー終了」だけが正規の終了手段になりました。
- **エラー画面に対処法を併記**: エラーコードごとに「どうすればよいか」を画面に表示（ゲームセンター筐体のエラー表示と同様）。
- **Manager: ゲーム編集のデータ損失を修正 (#224)**: 「起動オプションが保存されない」「説明文が空で上書き消去される」2 件を修正。バージョンごとに説明/引数を持てる仕組みは維持しています。
- バックアップ履歴表示の整理や、各種レビュー指摘の修正も含みます。

**アップデート方法**: Manager の「アップデート」タブから「今すぐアップデート」で適用できます。**ゲームデータ（DB / ゲーム / バックアップ / 回答 / ログ）は自動で保護**され、内部の DB スキーマも自動で v13 → v14 に移行します（最終的なスキーマは変わらず、互換）。

- Launcher: v0.6.2 → v0.9.1 (サービスモード #74 / 終了制御 #84 / エラー対処法併記 / フォント・配色統一 / DB v14 追従 / レビュー修正)
- Manager: v0.16.1 → v0.16.4 (バックアップ履歴整理 #200 / 個別バージョン self-rename 修正 #221 / ゲーム編集データ損失修正 #224 / レビュー修正)
- LauncherAgent: 新規 v0.2.0 (旧 WindowProbe を統合・置換。probe + HOME/Guide sensor + focus + ネットワーク速度計測)
- Updater: v0.2.1 (変更なし)

**Notes**: 大型機能追加を含むため Bundle minor bump (v0.6.0 → v0.7.0)。DB v13 → v14 は自動 migration で非破壊（v0.4.0 の v12→v13 と同様）、brand rename (v0.5.0) のような手動再インストールは不要で、自動アップデートで適用できます。

### [Bundle v0.6.0] - 2026-05-20

**Manager の使い勝手まわりをまとめて改善**したリリースです。brand rename (v0.5.0) 以降に溜まった Manager の UX / 安全性改善を 1 本に束ねました。

主な変更:
- **アップデートが「消えて再起動」から「予告 + 完了通知」に**: 「今すぐアップデート」を押すと、Manager が一旦終了して新バージョンで再起動する旨を事前に dialog で予告し、再起動後に「✓ アップデート完了」のお知らせが出るようになりました (= 旧版は無言で Manager が消えて不安だった)。アップデート作業中の黒いウィンドウ (Updater) も非表示に。
- **ログの保存先を 1 フォルダにまとめて指定可能に**: 設定タブの「ログ保存先」が Manager だけでなく **Launcher / Updater 含む全コンポーネントのログ**をまとめた親フォルダの指定になりました。Manager のログ閲覧ツールもアプリ別のタブ表示に整理。
- **設定タブが「適用 / 元に戻す」式に**: 設定を変更しても即保存ではなく、各セクションの「適用」ボタンで確定 / 「元に戻す」で取り消しできるようになりました。未保存のままタブを移動 / ウィンドウを閉じようとすると確認 dialog が出ます。
- **バックアップ履歴の表示を整理**: ほぼ常に「成功」しか出ず情報量のなかった「状態」列を削除して見やすく。

**アップデート方法**: Manager の「アップデート」タブから「今すぐアップデート」で適用できます (= Bundle v0.5.0 以降は自動アップデート対応に復帰、手動 re-install は不要)。**ゲームデータ (DB / ゲーム / バックアップ / 回答 / ログ) は自動で保護**されます。

- Launcher: v0.6.1 → v0.6.2 (ログ保存先の統一に伴う Launcher 側の対応)
- Manager: v0.12.1 → v0.16.1 (アップデート予告 dialog / Companions ログ管理 / ログ保存先統一 / 設定タブ editing model / バックアップ履歴整理)
- Updater: v0.2.1 (変更なし)

**Notes**: 本リリースは機能追加を含むため Bundle minor bump (v0.5.0 → v0.6.0)。brand rename のような破壊的変更は無く、自動アップデートで適用できます。

### [Bundle v0.5.0] - 2026-05-19

**プロジェクト名称を `ゲームセンターTONE Prism (GCTonePrism)` → `TonePrism` に統一** (#168)。他校・他団体への配布も視野に入れた汎用化 rename で、**exe filename / DB filename / namespace / UI 文字列 / repo URL まで全件 sync**:
- `GCTonePrism_Manager.exe` → `TonePrism_Manager.exe`
- `GCTonePrism_Launcher.exe` → `TonePrism_Launcher.exe`
- `GCTonePrism_Updater.exe` → `TonePrism_Updater.exe`
- DB ファイル: `prism.db` → `toneprism.db` + バックアップ prefix も `prism_*.db` → `toneprism_*.db`
- ウィンドウタイトル `ゲームセンターTONE Prism 管理ソフト` → `TonePrism 管理ソフト`

あわせて、**copyright 表記を全 component / 全 surface で統一** + Manager 設定タブ「バージョン情報」に copyright + ライセンス情報を表示する経路を追加 (#170)。配布バイナリ 3 か所 (Launcher / Manager / Updater) の exe properties に焼き込まれる Copyright が `Copyright © 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)` に統一、Manager の設定タブからも runtime で確認可能。

**⚠ 重要: 本リリースは自動アップデート非対応** (= brand rename + DB filename rename を伴う破壊的変更のため、auto-update 経路は意図的に閉鎖)。**手動で再 install が必要**:
1. [リリースページ](https://github.com/ken1208git/TonePrism/releases/tag/v0.5.0) から `TonePrism_v0.5.0.zip` を DL
2. **空の新しい親フォルダ** に解凍 (= 既存 install dir には流さない、新版 Manager の旧版検出 guard で起動 block されます)
3. `Install.bat` をダブルクリック → 親フォルダを GUI 選択 → インストール
4. ゲームデータ移行が必要な場合: 旧 install から `games/` / `backups/` / `responses/` / `logs/` を新 install dir に手動 copy、`prism.db` は新 install dir に `toneprism.db` という名前で copy

旧版 (Bundle v0.4.0 以前) の install dir に新 zip を上書き展開してしまった場合、新 Manager 起動時に「旧版検出 — 手動再 install が必要です」MessageBox が出て `Environment.Exit(1)` で停止します (= 物理的に旧版混在を防ぐ guard 動作)。空の新フォルダに展開し直してください。

- Launcher: v0.5.18 → v0.6.1 (brand rename + copyright sync、3 SoT [version.gd / project.godot / export_presets.cfg] 同期)
- Manager: v0.11.0 → v0.12.1 (brand rename + 旧版 detect guard + 設定タブ copyright 表示 + copyright sync)
- Updater: v0.1.0 → v0.2.1 (brand rename + copyright sync)
- Release Tooling: v0.1.18 → v0.1.19 (brand rename URL slug + zip filename + build script 内 exe filename literal sweep)

**Notes**: Bundle v0.5.0 は brand rename の transition release。v0.6.0 以降は通常の自動アップデート経路に復帰します (= 旧版検出 guard は brand rename 専用 fail-safe、新版 install 完了後は再発火しません)。1.0.0 への bump は「API 安定保証 + 配布実績」の milestone として後の release に温存、本リリースは brand 統一 + 他校配布可能化への準備として位置付け。

### [Bundle v0.4.0] - 2026-05-19

**LAN 上の同時起動を自動検出して警告する機構が完成** (#179)。学校 LAN の SMB 共有 `prism.db` で、これまで「同時起動するとデータが壊れる可能性あり、毎回 MessageBox で注意喚起」だった人間頼り運用から、**他 PC で Manager / Launcher が動いている時にだけ自動で警告 dialog を出す** 方式に upgrade。Manager 起動時 + ゲーム編集 / バックアップ / 設定変更等の前で「【危険】他 PC で Manager / Launcher が稼働中です: PC-A (Manager v0.11.0、最終確認: 5 秒前) / PC-B (Launcher v0.5.18、最終確認: 12 秒前)」のように **検出された PC を具体的に表示** し、user は OK (続行) / キャンセル (中止) を都度判断できるようになりました。

その他の改善:
- アップデート完了直後の起動時に「✓ アップデート完了 (Bundle vX.Y.Z)」通知 dialog が出るようになりました (= 旧仕様は完了通知ゼロで silent 再起動)
- 同 PC で Manager を 2 つ起動しようとすると即座に block (= 物理的に防止、誤起動による上書き競合を予防)
- アップデート関連の UI / 安全性改善多数 (詳細は `## Manager` 別セクション参照)

- Launcher: v0.5.17 → v0.5.18 (LAN-wide session 出力 module 追加)
- Manager: v0.9.1 → v0.11.0 (6 段 bump、機能追加 + UX 改善)
- Release Tooling: v0.1.17 → v0.1.18 (manifest 経由 path 解決の forward compat)

**[v0.3.1 以前をインストール済みの方へ]** Manager の「アップデート」タブから「今すぐアップデート」で適用してください (= Bundle v0.3.0 以降は自動アップデート対応)。**ゲームデータ (DB、ゲーム、バックアップ、回答、ログ) は自動で保護**、内部の DB スキーマも自動で v12 → v13 に migration されます。

### [Bundle v0.3.1] - 2026-05-18

**zip の中身をシンプルに整理 + 将来の自動アップデート対応を強化** (#175)。zip を解凍した時に並ぶファイルが `Install.bat` / `INSTALL_README.txt` / `bundle/` フォルダ の 3 つだけになり、「どれを押せばいいか」が一目瞭然になりました。あわせて Manager の「アップデート」タブが将来の配布内容の変更に自動で追従できるように改良 — **次のリリース以降は zip を手動 DL する手間なく自動でアップデートできるように**なります。

- Launcher: 変更なし (v0.5.17 同梱)
- Manager: v0.9.0 → v0.9.1
- Release Tooling: v0.1.16 → v0.1.17

**ご注意 (v0.3.0 をインストール済みの方へ)**: 今回 1 回だけ、Manager の「アップデート」タブからは適用できません (今回の zip 構造変更を v0.3.0 の Manager は理解できないため)。お手数ですが [リリースページ](https://github.com/ken1208git/TonePrism/releases/tag/v0.3.1) から zip を DL → `Install.bat` ダブルクリック → 既存と同じ親フォルダを選択 → 上書きインストールしてください。**ゲームデータ (DB、ゲーム、バックアップ、回答、ログ) は自動で保護されます**。次回以降は自動アップデートが永久に効くようになります。

### [Bundle v0.3.0] - 2026-05-18

**Phase 4 アップデート機能完成** (#108 Phase 4)。Manager の UI に「アップデート」タブが追加され、新バージョン検出 → リリースノート確認 → ボタン 1 つで適用、までの flow が完備された。今後は新版が出ると Manager 起動時に通知ダイアログが出て「はい」→ タブ自動切替 → 「今すぐアップデート」で適用できる (= zip 手動展開や Install.bat 再実行が不要に)。累積更新 (例: v0.3.0 を飛ばして v0.4.0 が出た場合に v0.3.0 / v0.4.0 両方のリリースノートを 1 画面で確認) にも対応。

- Launcher: 変更なし (v0.5.17 同梱)
- Manager: v0.8.11 → v0.9.0 (Phase 4 update flow + UI、詳細は `## Manager` セクション参照)
- Release Tooling: v0.1.15 → v0.1.16 (CHANGELOG.md zip 同梱 + `Install.bat` の `TEMP_MV_OUT` silent corruption fix、詳細は `## Release Tooling` セクション参照)

**Notes**: Phase 4 完成版 = 「アップデートが UI ボタン 1 つで完結する」最初の version。Phase 5 (Launcher 通知バナー) / Phase 6 (統合テスト) は今後の release で順次実装予定。

### [Bundle v0.2.0] - 2026-05-13

**Phase 2 配布フロー整備 + 初回インストーラ実装** (#108 Phase 2)。zip ダブルクリック展開 → `Install.bat` ダブルクリック → 親フォルダを GUI 選択 → インストール完了、までの 1 経路を提供。`<親>/Launcher.bat` / `<親>/Manager.bat` の親フォルダ直下ショートカットにより部員の日常起動も `<親>` を開けばダブルクリック 1 回で済む。再インストール時はゲームデータ (`prism.db` / `games/` / `backups/` / `responses/` / `logs/`) を自動保護。

- Launcher: 変更なし (v0.5.16 同梱)
- Manager: 変更なし (v0.8.9 同梱)
- Release Tooling: v0.1.8 → v0.1.9 (`templates/Install.bat` 等の同梱、Y/N upload prompt、tag 衝突 graceful exit、exit code 体系 0/1/2/3、non-interactive 検出 等。詳細は `## Release Tooling` セクションを参照)

**Notes**: Phase 2 完成版 (本番運用可)。Phase 3 (Updater.exe) / Phase 4 (Manager UI アップデートタブ) / Phase 5 (Launcher 通知バナー) は今後の release で順次実装予定。

### [Bundle v0.1.0] - 2026-05-11

初回 Bundle リリース。`Release.bat` 1 発でビルド + zip + GitHub Releases アップロードまで自動化する配布インフラを導入 (#108 Phase 1)。

- Launcher: 変更なし (v0.5.16 同梱)
- Manager: 変更なし (v0.8.9 同梱)
- Release Tooling: `Release.ps1` / `Release.bat` を新規追加 → 詳細は `## Release Tooling` セクションを参照

**Notes**: 本リリースは `Install.bat` 未同梱のため本番運用不可、Release.ps1 の動作確認用テストリリース扱い。Phase 2 以降で `Install.bat` / `Updater` / Manager UI アップデートタブ / Launcher 通知バナーを順次実装予定。

---

## Release Tooling（配布インフラ）

`Release.ps1` / `Release.bat` / `Install.bat` / `templates/*.bat` / `show_folder_dialog.ps1` / `INSTALL_README.txt` 等の **build / 配布スクリプト** の変更履歴。エンドユーザー向けではなく、開発者が「リリーススクリプトのこの挙動はいつから？」を辿るために残す。

**注意 (#160 で section 責務分離)**: `Updater` 等の **runtime exe 群** (= SPEC §2.4 Companions 配置) の changelog は本 section ではなく **`## Companions`** (旧 `## Updater (Companions/Updater)`、本 PR で section 名を一般化) に記載する。本 section は build / 配布スクリプトのみ対象。Bundle v0.4.0 以前 (= 本 PR merge 前) の Updater 変更履歴は `## Release Tooling` の過去 entry (= round 1〜8 review 詳細等) に retain、retroactive consolidation は scope creep のため見送り (= PR #159 round 4 「SPEC 1 PR 1 bump 規約」導入時と同 pattern)。

### [Release Tooling v0.1.28] - 2026-06-14

#### Removed (#245 / #377 後の掃除)

- **開発用 Manager 単体ソリューション `Manager/TonePrism_Manager.slnx` を削除しルート `TonePrism.slnx` に一本化**。旧 #168（GCTonePrism 時代）の名残で中身は `TonePrism_Manager.csproj` 1 個（テスト未収録）。SPEC §2.4（#245 PR5）が**ルート `TonePrism.slnx` を VS 開発の SoT**（「VS では必ず .slnx を開く」）と定めて以降は冗長で、ルート slnx を開いて Manager をスタートアップに設定すれば同じ起動体験 + `Manager.Tests` も Test Explorer で回せる。`Release.ps1` / CI は solution を使わず各 csproj を個別 build するため**参照ゼロ＝ build / 配布に影響なし**（純粋に VS-IDE の開発利便ファイル）。VS で旧 slnx を開いていた場合はルート slnx を開き直すこと。
- bump 判断: 開発インフラ（VS ソリューション）整理のみで build / 配布スクリプトの挙動は不変。patch (v0.1.27 → v0.1.28)。Bundle 反映は次回リリース時。

### [Release Tooling v0.1.27] - 2026-06-11

#### Changed (#258 PR4 — net10 self-contained publish 対応)

- **`Build-Manager` を `msbuild /restore` → `dotnet publish`（net10 self-contained single-file）化**（`-r win-x64 --self-contained true -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true`）。staging の Manager が exe 1 個に。dev build（`dotnet build`/`test`）は single-file にせず publish 引数で渡す。Manager のみ dotnet (net10)、Updater / LauncherAgent は msbuild (net48) のまま（移行期 mixed、前提: net10 SDK が PATH）。**配布対象は win-x64 専用＝64bit Windows のみ**（旧 net48 AnyCPU は x64/x86 両 interop 同梱で 32bit OS でも起動したが、self-contained `-r win-x64` で 32bit OS 非対応に。2026 の学校 PC は全て 64bit のため実害なし、将来の前提取り違え防止に明記）。
- **`$script:BundleManifestFiles` の Manager 行を exe 1 個に刷新**（`.exe.config` / `System.Data.SQLite.dll` / `x64,x86\SQLite.Interop.dll` は single-file exe 内包のため撤去）。Manager v0.27.9・`UpdateDownloader.ValidateStagingLegacy` と三経路同期。
- **dead な `Resolve-Nuget` 一式を撤去**（関数定義 / `-NugetExe` param / `$NugetPinnedVersion` 定数 / `$script:ResolvedNuget`）。PR1 で呼び出しは撤去済、Manager の dotnet 移行で nuget.exe が完全に不要化（PR4 で予定通り撤去）。なお `Godot / msbuild / nuget` を subprocess stdout の codepage 分類例として列挙する箇所や DL キャッシュ温存メッセージは、nuget=外部ツール一般の言及として**意図的に残置**（dotnet restore も global package cache を使うため事実として正しい）。
- **（レビュー Medium）`Resolve-Dotnet` preflight を追加**（`Resolve-Godot` / `Resolve-MsBuild` と同様 Main 冒頭で解決）。`dotnet` を PATH 解決 + `dotnet --list-sdks` で **net10 SDK 存在を検証**、未導入なら `Build-Launcher`（Godot export、数分）より**前に fail-fast**（旧来 hard build 依存なのに preflight に居なかった穴を是正）。`Build-Manager` は `$script:ResolvedDotnet` を使用。
- doc（`.SYNOPSIS` / `.PARAMETER`）の Manager ビルド記述を dotnet publish に、必要環境に「.NET 10 SDK」を追記。
- **PR3+PR4 を束ねてマージ**で main から net10 bundle release が可能になる（PR3 単独では net10 出力が expected-files と drift し `Assert-ExpectedFiles` で fail-fast＝リリース不能だった窓を、本 PR で閉じる）。
- **（レビュー round2 Low）残存 stale 記述の sweep**: `Build-Updater` ヘッダコメントが「Build-Manager の **nuget restore** / native DLL 抽出は不要」と dotnet publish 化で消滅した挙動を説明していた stale を修正。`Resolve-Dotnet` の net10 SDK 判定を「`10.x` 固定」→「**major ≥ 10**」に緩和（11+ SDK でも roll-forward で net10.0 publish 可。pin 運用でも将来 SDK 更新時の誤 fail を回避）+ fail メッセージに検出 SDK 一覧を併記（切り分け容易化）。あわせて Companions/Updater `FileReplacer` の dir-atomic 根拠コメントを single-file 後の実態（exe 1 個）に同期（Updater は net48 無改修・version 据え置き、本移行で陳腐化したコメントのみ）。
- **（レビュー round3）Manager exe 版数の公開前ゲート `Assert-PublishedManagerVersion` を追加**: net10 single-file 化で Manager exe の Win32 FileVersion が **dotnet publish の stamp 由来**になった（net48 はコンパイル済アセンブリで自明に SoT 一致だったため検証不要だった）。Launcher の `Assert-ExportedLauncherVersion` と**対称**に、`Build-Manager` 直後（zip/publish より前）で staged `TonePrism_Manager.exe` の FileVersion を SoT（`$script:ManagerVersion` = AssemblyInfo AssemblyVersion）と突き合わせ、不一致なら hard fail。reviewer 指摘「apphost FileVersion が `1.0.0.0` になる疑い」は **build / 実 single-file publish 両方で実測し `0.27.9.0` で正しいと確認**（＝現状 bug ではない）が、stamp 経路が将来壊れても誤版数 publish を防ぐ **defense-in-depth として機械強制に格上げ**（#283「silent に嘘版数」/ memory「リリース時バージョン検証は2段」と整合）。あわせて `Resolve-Dotnet` に「SDK 存在のみ検証＝ランタイムパックの restore 可否は Build-Manager で初判明」の limitation コメントを追記（過信防止）。さらに **SPEC §3.7.8 に本ゲートの条件ベースルールを明文化**（(a) 版数表示 ∧ (b) stamp パイプライン → `Assert-<Name>Version` 必須・net48 直接コンパイルは除外。LauncherAgent #310 / Monitor は net10 化＋表示で将来必須化）、相補の **CHANGELOG↔SoT 版数ゲート（全部品の bump 忘れ検出＝「1 PR 1 bump」機械化）は #359 で別管理**。
- **（レビュー round5）single-file 不変条件の機械強制 `Assert-ManagerSingleFile` 追加 + gate コメント精緻化**: (D-1) `Assert-ExpectedFiles`（manifest）は presence のみ検証で**余剰ファイルを見ない**（余剰検出を入れると旧 Manager が新 zip を reject する後方互換問題が再燃するため、manifest forward-compat の設計上そうなっている）。将来 SDK / `System.Data.SQLite.Core` の挙動変化で sidecar（loose native dll / `createdump.exe` / `*.json` 等）が publish 出力に混ざり manifest 非記載のまま zip 同梱される silent drift を防ぐべく、**Manager staging が `TonePrism_Manager.exe` 1 個であること**を `Build-Manager` 直後に assert（single-file 化の核心不変条件をこれまで手動 smoke 頼みだったのを機械強制に格上げ）。(B-1) `Assert-PublishedManagerVersion` のコメントを精緻化＝比較は厳密には「exe FileVersion（apphost が managed DLL からコピー＝**AssemblyFileVersion** 由来）」↔「`$script:ManagerVersion`（**AssemblyVersion** 属性＝SoT）」で、両属性を同値に保つ前提＝両者 drift も検出できる有用な不変条件（意図的に乖離させる運用にするなら比較対象を AssemblyFileVersion へ寄せる旨を注記）。
- bump 判断: 配布スクリプト改修。patch (v0.1.26 → v0.1.27)。Bundle 反映は次回リリース時。

### [Release Tooling v0.1.26] - 2026-06-11

#### Changed (#258 PR3 — CI を net10 対応)

- **CI `.github/workflows/manager-tests.yml` の `setup-dotnet` を `8.0.x` → `10.0.x` に** (Manager/Manager.Tests が net10.0-windows へ flip、`dotnet test` が net10 SDK を要求)。詳細は Manager v0.27.8 参照。
- **注**: bundle build (`Release.ps1`) の net10 配布対応 (self-contained publish / expected-files 刷新) は **PR4** で別途。本 PR の CI 変更はテスト経路 (`dotnet test`) のみ。
- bump 判断: CI スクリプト変更。patch (v0.1.25 → v0.1.26)。Bundle 反映は次回リリース時。

### [Release Tooling v0.1.25] - 2026-06-11

#### Changed (Manager SDK-style 化に伴う restore 近代化 / #245 #258 #309)

- **`Build-Manager` を SDK-style restore に対応**: `nuget restore -PackagesDirectory Manager\packages`（packages.config 前提）→ `msbuild /restore`（PackageReference）に一本化。Stub.System.Data.SQLite の native interop 手動抽出（nupkg unzip）も廃止（PackageReference の build targets が `bin\Release\x64|x86\SQLite.Interop.dll` を自動コピーするため不要、実機確認済）。bundle SoT `$script:BundleManifestFiles` から WindowsAPICodePack DLL 2 件を除去（#309、Manager v0.27.6・`UpdateDownloader.ValidateStagingLegacy` と三経路同期）。
  - 契約変更（レビュー Low）: `msbuild /restore` に `-Offline` ガードが無いため、`-Offline` + global package cache cold 時は旧 `Resolve-Nuget` の preflight Fail と違い build 途中で fail する（誤成果物は出ない）。`-Offline` は global package cache warm 前提。fail-fast 復元は A4 の Release.ps1 改修で検討。
- **メインフローの `Resolve-Nuget` 呼び出しを撤去**（レビュー Medium）: 唯一の消費者だった Build-Manager の nuget restore が無くなり nuget.exe が未使用化。残すと (a) 通常実行で不要な nuget.exe DL、(b) `-Offline` で未使用ツールのために `Fail`（"NuGet キャッシュが必要"）になる live な失敗経路を温存するため、呼び出しを削除。`Resolve-Nuget` 関数定義は dead だが A4 の net10 配布対応 Release.ps1 改修でまとめて撤去予定。
- **CI `.github/workflows/manager-tests.yml` を SDK-style 対応**: 削除済み `Manager\packages.config` を restore していた step（+ `Setup NuGet` step）を撤去。両プロジェクトとも PackageReference になり `dotnet test` の暗黙 restore で復元されるため（packages.config 削除と不可分の修正・レビュー Critical）。
- bump 判断: 配布 / CI スクリプトの変更。patch (v0.1.24 → v0.1.25)。Bundle 反映は次回リリース時。

### [Release Tooling v0.1.24] - 2026-06-01

#### Changed (#283 — project.godot 同梱廃止 + exe 版数の公開前検証ゲート)

- **release zip への `Launcher/project.godot` 同梱を廃止**（`$filesTemplates` と `$script:BundleManifestFiles` から `files\Launcher\project.godot` を除去）。Manager UI の VersionInventory が Launcher 版数を `<install>/Launcher/TonePrism_Launcher.exe` の FileVersionInfo から読むようになった（上記 Manager v0.19.5）ため、版数読み取り用の loose ファイルを別途同梱する必要がなくなった（exe は元々同梱）。manifest 駆動の `UpdateDownloader.ValidateStaging` は `$BundleManifestFiles` 更新で自動追従（`ValidateStagingLegacy` は v0.3.0 zip 構造凍結のため据置）。
- **`Assert-ExportedLauncherVersion` を追加**（`Build-Launcher` 直後・zip/upload より前に実行）。エクスポート済み exe の `FileVersion` を読み、SoT（`$script:LauncherVersion` = project.godot config/version）と 3-part 一致を検証、不一致 / parse 不可なら `Fail` で **公開前に release を中止**。#283 で版数読み取りが多段 stamp パイプライン（config/version → `Set-ExportPresetVersions` → export_presets.cfg → rcedit → exe）の派生値になったため、stamp 一手抜けで exe が古い/欠落版数を焼く failure mode を **公開前に自動で hard fail** させる安全網（手動目視は backstop に降格）。検証: stale `0.9.1.0` / 空（rcedit 不発相当）はいずれも Fail、SoT 一致 `0.10.2.0` は PASS、を実値で確認。`Assert-*` 命名規約（AGENTS「Release Tooling 命名規約」、検証目的で Fail 到達）に準拠。
- bump 判断: 配布スクリプトの変更のみ。patch (v0.1.23 → v0.1.24)。Bundle への反映は次回リリース実行時。

### [Release Tooling v0.1.23] - 2026-06-01

#### Changed (#281 — Launcher 版数 SoT 移行に伴う release 基盤の追従)

- **`Assert-LauncherVersion` を `version.gd` の `MAJOR/MINOR/PATCH` 読み → `project.godot` の `config/version="X.Y.Z"` 読みに変更**（Launcher 版数の SoT が project.godot config/version に移行、#281）。`config/version`（スラッシュ）を読み `config_version`（Godot ファイル形式版）には誤マッチしない。
- **Phase 2 の project.godot config/version 同期を撤去**。config/version は SoT 自身（`Assert-LauncherVersion` がそこから読む）なので同期不要。派生先である `export_presets.cfg` の `file_version`/`product_version` の stamp は維持。責務が export_presets.cfg のみに縮小したため関数を **`Set-ManifestVersions` → `Set-ExportPresetVersions` に rename**（レビュー指摘、名称の実態整合）。
- **install 先同梱ファイルを `Launcher/version.gd` → `Launcher/project.godot` に差し替え**（`$filesTemplates` と `$script:BundleManifestFiles` の両 SoT を更新）。エクスポート済み Launcher exe は project.godot を .pck 内に隠匿するため、Manager UI の `VersionInventory` が parse できるよう project.godot のコピーを明示同梱する（旧 version.gd 同梱と同じ理由）。manifest 駆動の `UpdateDownloader.ValidateStaging` は `$script:BundleManifestFiles` 更新で自動追従。`ValidateStagingLegacy`（v0.3.0 zip 構造に凍結された fallback）は実在の旧 zip に match させる必要があるため version.gd 参照のまま据え置き。
- ヘッダの「version.gd = Launcher version の SoT」コメントを「project.godot config/version = SoT」に更新。
- bump 判断: 配布スクリプトの変更のみ。patch (v0.1.22 → v0.1.23)。Bundle への反映は次回リリース実行時。

### [Release Tooling v0.1.22] - 2026-05-27

#### Fixed (累積コードレビュー指摘の対応)

- **`Clear-OldGodot` の version ソートを文字列辞書順 → `[version]` 数値比較に修正**: 旧 `Sort-Object Name -Descending` は文字列順のため Godot が `4.10.x` 系に達すると `4.9.x` を「より新しい」と誤判定し、最新版を古い版として削除する時限バグだった (現状 4.6.x のみで未発火)。`Where-Object { $_.Name -as [version] }` で非 version dir を削除対象から除外しつつ (cast 例外で cleanup phase が落ちるのも防ぐ)、`Sort-Object { [version]$_.Name }` で数値比較に変更。非 version 名 dir (pre-release suffix 付き等) が混ざっていた場合は無言で蓄積しないよう warn を 1 行出す。
- **起動バナーの `(Phase 1)` 表記を削除**: Phase 2 / 3 完成済 (`.DESCRIPTION` と整合) なのにバナーだけ旧 Phase 表記が残り、実行者の誤読源になっていた。

bump 判断: 配布スクリプトの bugfix のみ。patch (v0.1.21 → v0.1.22)。Bundle への反映は次回リリース実行時。

### [Release Tooling v0.1.21] - 2026-05-21

#### Added (#101 / #216 — WindowProbe の build / 配布統合)

- **`Build-WindowProbe` 関数を新設** (`Release.ps1`、`Build-Updater` をテンプレに): `Companions/WindowProbe/TonePrism_WindowProbe.csproj` を msbuild Release ビルド → bin/Release/ から `<staging>/files/Companions/WindowProbe/` へコピー。clean build（bin/Release 削除）+ 成果物 dir / `.exe` 1 件以上 / 特定 exe 名（`TonePrism_WindowProbe.exe`）の 3 段 fail-fast を `Build-Updater` と同型で実装。Main のビルド列に `Build-Updater` の直後で挿入。
- **`$script:BundleManifestFiles` に WindowProbe 2 entry を追加** (`files\Companions\WindowProbe\TonePrism_WindowProbe.exe` + `.exe.config`): `Assert-ExpectedFiles`（staging 検証）と `New-BundleManifest`（manifest 生成）の両方が本配列を参照するため、これだけで Manager 側 validate（manifest 経由）も自動同期される。`$script:BundleLayout` は変更不要（Manager apply の Companions 一括ループが `companions_dir` 経由で WindowProbe を自動列挙するため、Updater のような専用 key は不要）。
- 冒頭 docstring の `TODO #101` を実装済表記に更新。

bump 判断: 新規 Companion の build / 配布統合で、Release.ps1 への build step + manifest entry 追加。配布インフラへの機能追加として patch (v0.1.20 → v0.1.21)。WindowProbe コンポーネント本体の CLI 仕様 / 設計判断は `## Companions WindowProbe v0.1.0`、Launcher 統合は `## Launcher v0.7.0` に記載。Bundle への反映は次回リリース実行時。

### [Release Tooling v0.1.20] - 2026-05-21

#### Added (#106 — 部員向けマニュアル docs サイト基盤 + README 配布物方針の区分け)

- **部員向けマニュアルの docs サイト基盤を新設** (MkDocs Material → GitHub Pages)。執筆ソースは `docs/` 配下の Markdown（SoT）、公開は `mkdocs.yml` + 新規 CI `.github/workflows/docs.yml`。公開 URL: `https://ken1208git.github.io/TonePrism/`。配色は Launcher（Godot）に寄せたダーク + 緑アクセント（`docs/stylesheets/extra.css`）。
  - **刀根山パソコン部専用**として作成（公開リポのため個人情報は載せず役割ベース）。`docs/` を `usage/`（製品の使い方＝汎用）と `operations/`（刀根山固有の運用）に分離。将来の一般版は別リポ/別サイトで `usage/` を種にする方針（共有機構は作らない、SPEC §3.7.10）。
  - **本文は実装済み機能のみ記載**: `usage/`（インストール / 起動と終了 / Manager 操作 / **ゲームの追加・編集・更新** / **ストア設定** / トラブル対応）を SPEC・コード・`ERROR_CODES_MANUAL.txt`・`INSTALL_README.txt` 準拠で執筆（フォーム各項目・エラーコード・SemVer の決め方・ストアのセクション/ソース/最大表示数などを実 UI に合わせて詳説）。未実装の Launcher 運用機能（終了制御 #84 / スタッフ呼び出し #83 / 音量 #82 / フィルター #29 等）は「実装予定」と明示し、動作するものとしては書かない。`operations/`（当日運用）は刀根山の実情（生徒用 PC 40 台・サーバー一元運用・役割・開場前チェックリスト等）で記述。
  - 全ページから **フィードバックフォーム**（バグ報告・改善要望）への導線を設置（「はじめに」関連リンク + トラブル対応）。
  - 執筆中に洗い出した Manager/Launcher の改善点を issue 化（#206 ゲームID 検証文言 / #207 thumbnail.jpg 自動検出 / #208 製作者氏名どちらか必須 / #209 個別バージョン削除 / #210 タイルグリッド複数行 / #211 最大表示数のソース別グレーアウト / #212 自動ソースは通常カテゴリ行のみ）。
  - `docs.yml` は `mkdocs build --strict` で内部リンク切れ / 見出しアンカー切れ / ページ削除を Fail 扱いにし、構造ドリフトを CI で検知。各ページの「最終更新日」は `git-revision-date-localized` プラグインが git 履歴から自動表示（手動マーカーと違い陳腐化しない）。
  - **インストール手順の詳細は従来通り zip 同梱 `templates/INSTALL_README.txt`（版数固定・オフライン安全）が SoT**。`docs/usage/install.md` は概要 + 誘導に留め、二重管理しない。
- **README.md を「開発者向け / 部員向け」の入口で区分け** (#106)。冒頭に 2 種類の読み手の案内を追加し、部員導線を「運用マニュアル(Pages) + GitHub Releases の zip + INSTALL_README.txt」へ、開発者導線を「開発環境のセットアップ」へ振り分け。「現在の状態」を最新進捗（Companions/Updater 追加等）に更新、ディレクトリ構成を実体（`docs/` 実体化・`mkdocs.yml`・`.github/workflows/` 等）と整合。
  - 手動配布版 `README.txt`（旧 v0.5.7 / v0.7.6 同梱想定）の時代は終了し、部員向けインストール説明は `INSTALL_README.txt`（zip 同梱）に一本化済であることを明記（物理ファイルは既に不在）。
- **ドリフト防止ルールを AGENTS.md に追加**: `## Documentation (部員向けマニュアル)` 節 + 「作業完了時」チェックに「UI / 操作 / エラーコード / インストール手順 / 設定に影響する変更時は `docs/` 更新要否を提案」を追記。ドキュメント役割分担は SPEC §3.7 に追記。

bump 判断: docs 公開インフラ + 配布物方針ドキュメントの追加で、アプリ component（Launcher / Manager / Updater）のコード・挙動は無変更。配布インフラへの機能追加として patch (v0.1.19 → v0.1.20)。Bundle への反映は次回リリース実行時。

### [Release Tooling v0.1.19] - 2026-05-19

#### Changed (#168 — brand rename URL slug + exe filename literals sweep)

`Release.ps1` 内の brand 関連 literal を `GCTonePrism` → `TonePrism` に全件 sweep。本 section は build / 配布 script 専属で、runtime exe (Updater 等) の brand rename は `## Companions Updater v0.2.0` に記載済、本 entry は **build script 側の文字列同期** のみ対象。

- `$GitHubRepoSlug = 'ken1208git/GCTonePrism'` → `'ken1208git/TonePrism'` (`Release.ps1:290` の SoT 定数、`Assert-ChangelogLinkDefs` の URL 組立てに使用)
- zip filename: `"GCTonePrism_v$Version.zip"` → `"TonePrism_v$Version.zip"` (`$ZipPath` 組立て、本変更で配布 zip filename も brand 統一)
- exe filename literal: `Build-Launcher` / `Build-Manager` / `Build-Updater` 内の `GCTonePrism_*.exe` / `GCTonePrism_*.csproj` → `TonePrism_*.exe` / `TonePrism_*.csproj` 全件 sweep (= csproj rename + AssemblyName 変更に追従)
- docstring 内の `GCTonePrism のリリース zip` → `TonePrism のリリース zip` 表記更新

bump 判断: 文字列 sweep のみで behavior 無変更、SemVer 上 patch (v0.1.18 → v0.1.19)。Release.ps1 の関数 signature / Assert-* logic / build flow は全件無変更、参照する exe filename と GitHub URL slug が brand 統一されただけ。Bundle v0.5.0 リリース実行時に本 v0.1.19 が同梱される。

### [Release Tooling v0.1.18] - 2026-05-18

#### Changed (#177 — Bundle manifest に `layout` field 追加、apply 側 forward compat)

- **`$script:BundleLayout` SoT 変数を新規追加** (`Release.ps1`、`$script:BundleManifestFiles` 配列の隣): `bundle_manifest.json` の `layout` field の SoT。category 名 → zip 内 `bundle/` 起点の `/` separator 相対 path の mapping を `[ordered]` hashtable で 1 箇所に集約。key 命名は **snake_case** (JSON 慣例)、7 key (`launcher_dir` / `manager_dir` / `companions_dir` / `updater_dir` / `launcher_bat` / `manager_bat` / `changelog_md`)。Manager 側 `BundleLayout` POCO は PascalCase property (C# 慣例)、wire format との対応は `ReadBundleManifest` 内の `TryGetLayoutString(dict, "launcher_dir")` 等の **literal snake_case key 参照** で manual 解決 (= dict 経由 manual mapping、`JavaScriptSerializer` の POCO 自動 mapping 挙動には依存しない設計、`Dictionary<string, object>` default comparer は case-sensitive、snake_case ↔ PascalCase は case 差ではなく separator 差 `_` のため自動 mapping だけでは不可)。v0.3.1 Manager (v0.9.1) との互換は schema_version=1 維持 + **未知 field 黙殺** (= 旧 reader は `TryGetValue("files", ...)` で必要 field のみ取り出し、新 optional field `layout` は dict 内に残るが POCO 側で参照しなければ無視される標準 JSON forward compat) で成立。新規 component 追加時は本 hashtable に新 key 追加 + Manager 側 `BundleLayout` 同期 + SPEC §3.7.8 チェックリスト更新の 3 件並列同期 (= `$script:BundleManifestFiles` と独立した SoT、用途が異なる)。
- **`New-BundleManifest` 関数を拡張**: 生成 hashtable に `layout = $script:BundleLayout` を additive 追加。schema_version は 1 のまま据置 (additive optional field 追加のため bump 不要、Manager 側 `BundleManifest` docstring に「**Schema 進化方針**: 既存 field の semantics 変更のみ bump、新 optional field 追加は据置で forward compat」を明記)。Write-Ok 出力 message も「manifest 生成完了 (N files entries + M layout keys)」に同期更新で debug 容易化。
- **Schema 進化方針の明文化**: 本 PR で「全 field 追加で bump」(Phase 4.1 round 1 Medium-1 の conservative 規約) → 「additive optional field は bump 不要、breaking change のみ bump」に修正、`layout` 追加が初の additive change 事例として SPEC §3.7.7 / §3.7.8 / Manager `BundleManifest` POCO docstring の 3 箇所で SoT 同期。これにより将来の review で「なぜ layout 追加で bump しない?」と問われた時の根拠を 1 箇所に集約。

**スコープ**: Phase 4.1 (PR #175) で manifest 同梱機構を導入した後の片肺解消。Release.ps1 側は新 SoT 1 件追加 + manifest 生成に 1 行追加で完結、Manager 側との contract が拡張 (= apply 側 layout 経由 path 解決) だが Release Tooling 単体の挙動変化はゼロ (生成される zip 構造は v0.1.17 と同一、manifest JSON に layout key が増えるだけ)。詳細は `## Manager v0.9.3` セクション参照。

### [Release Tooling v0.1.17] - 2026-05-18

#### Changed (#175 Phase 4.1 — Bundle manifest 同梱 + zip 構造整理)

- **zip 構造を `bundle/` 配下に集約**: 旧構造 (v0.3.0) は zip 直下に `Install.bat` / `INSTALL_README.txt` / `Launcher.bat` / `Manager.bat` / `show_folder_dialog.ps1` / `files/` の 5 file + 1 folder が並んでいて、新規ユーザーが zip 展開した時に「どれをダブルクリックすればいい?」と迷う UX 課題があった。新構造 (v0.3.1+): zip 直下 = `Install.bat` + `INSTALL_README.txt` の 2 file のみ、それ以外 (Launcher.bat / Manager.bat / show_folder_dialog.ps1 / bundle_manifest.json / files/) は `bundle/` 配下に集約。zip 直下が「ダブルクリックする 2 file」だけになり「Install.bat を押すだけ」が一目瞭然に。`Release.ps1 Copy-Templates` で `$rootTemplates` (2 件) + `$bundleTemplates` (3 件) + `$filesTemplates` (2 件) の 3 段配置に再構成、Install.bat 側も `set "BUNDLE_DIR=%SCRIPT_DIR%bundle"` + `set "FILES_DIR=%BUNDLE_DIR%\files"` 経由で参照する形に同期更新。
- **`Release.ps1 New-BundleManifest` 関数を新設 (`bundle/bundle_manifest.json` 生成)**: Phase 7 (Assert-ExpectedFiles) の直前に新 Phase 6.5 として呼び出し、zip 化前に manifest を staging に書き出す。manifest schema (schema_version 1): `bundle_version` (String) + `generated_at` (ISO 8601 UTC) + `schema_version` (Int) + `files` (Array、bundle/ からの相対 path、`/` separator)。Manager 側 (`UpdateDownloader.ValidateStaging`) が manifest を読み込んで forward compat 検証する SoT (`## Manager v0.9.1` 参照)。
- **`Release.ps1 $script:BundleManifestFiles` で SoT 1 箇所統一**: 旧設計は `Assert-ExpectedFiles` 内 local 配列 `$expected` (17 entries) で fence していたが、`New-BundleManifest` 追加で同じ list を 2 関数で持つと drift する risk。`$script:` scope で配列を 1 箇所に集約、両関数が同 SoT を参照する形に refactor。zip 構造変更時は本配列 1 箇所の更新で `Assert-ExpectedFiles` (staging 検証) + `New-BundleManifest` (manifest 生成) の両方が同期する。**SPEC §3.7.8 チェックリスト** の新規コンポーネント追加項目も「`$script:BundleManifestFiles` 配列に追加」に変更。
- **`Release.ps1 Assert-ExpectedFiles` を 3 段検証に再構成**: zip 直下 (`Install.bat`, `INSTALL_README.txt`, `bundle\bundle_manifest.json`) + `bundle/` 直下 (`bundle\Launcher.bat`, `bundle\Manager.bat`, `bundle\show_folder_dialog.ps1`) + `bundle/files/` 配下 (12 件、`$script:BundleManifestFiles` から bundle/ prefix 付与で展開) の合計 17 件を staging で存在 check。`bundle_manifest.json` 自身も検証対象に含めることで「New-BundleManifest 生成失敗 → Assert で catch」の自己整合性 fence。
- **`$FilesDir` を `<staging>\bundle\files` に変更 + 新規 `$BundleDir` `$ManifestPath` global var 追加**: Build-Launcher / Build-Manager / Build-Updater が `$FilesDir` 経由で配置先を決めているため、本変数 1 箇所の変更で Launcher / Manager / Companions/Updater の出力先が自動的に新構造 (`bundle/files/Launcher/...` 等) になる。

**スコープ**: Phase 4 (#108 PR #161) Manager UI update flow の forward compat 機構が機能するための release 側 infrastructure。zip 構造変更による「面食らわない UX」改善 + manifest 同梱による「将来の dir 構造変更を Manager 側コード変更なしに吸収」forward compat 獲得の 2 件を 1 PR で。詳細は `## Manager v0.9.1` セクションと SPEC §3.7.7 / §3.7.8 参照。

### [Release Tooling v0.1.16] - 2026-05-14

#### Changed (#108 Phase 4 関連)

- **`Release.ps1` の `Copy-Templates` で `CHANGELOG.md` を `files/CHANGELOG.md` に zip 同梱**: Phase 4 (#108) で Manager UI が「現在の Bundle version」を抽出するための SoT として、repo root の CHANGELOG.md を install dir 直下に同梱する。配置: zip 内 `files/CHANGELOG.md` → Install.bat の `robocopy files/* <install>/` で `<install>/CHANGELOG.md` 直下 (= `Launcher/` `Manager/` 等と同階層)。配置選定根拠: (a) project 全体の SoT semantic に整合 (CHANGELOG は Launcher / Manager / Companions / Bundle / Release Tooling を横断、Manager 専属ではない)、(b) File Explorer から install dir を開いたユーザーから直接見える位置 (Manager dir の中に埋もれない)、(c) 累積更新時に staging CHANGELOG.md を信頼できる accurate source として再利用 (DL 後の「適用直前確認」UI で API 経由より staging を信頼)。検討した代替案 (`bundle_version.txt` 新設 / `<install>/Manager/CHANGELOG.md` 配置) と比較して、本案 (`<install>/` 直下) は semantic 的にクリーン + ユーザー可視性が高い + Manager UI Phase 4 の Phase 4 update flow に single-file copy 1 行追加で対応可能 (shortcut bat = `Launcher.bat` / `Manager.bat` 置換と同 pattern、Updater は `<install>/` 直下を touch しないため Manager UI 責務に置く)。
- **`Assert-ExpectedFiles` に `files\CHANGELOG.md` を追加**: 上記同梱の structural fence として、CHANGELOG.md が staging に正しくコピーされなかった場合 Release.ps1 を fail-fast で停止する。

#### Fixed (#108 Phase 4 デバッグで発見した pre-existing bug)

- **`templates/Install.bat` の `set "TEMP_MV_OUT=..."` が dead code 状態だった silent corruption fix**: PR #150 round 7 M1 で導入された TEMP_MV_OUT (migration の stdout/stderr capture 用 tmp file path) の `set` 行が `:do_overwrite` block 内の `goto :migrate_legacy_manager` より **後**、かつ `:migrate_legacy_manager` ラベルより **前** に配置されていた = `goto` が `set` 行を物理的に飛び越えて **never executes** する dead code 状態だった。結果として `:migrate_done` での `del "%TEMP_MV_OUT%" 2>nul` (TEMP_MV_OUT が空文字) が `del "" 2>nul` になり、cmd.exe が空 quoted argument を **current dir wildcard** (`del .\*` 相当) と解釈 → JP locale で 「`<SCRIPT_DIR>\*、よろしいですか (Y/N)?`」prompt 発生 → ユーザーが「上書きインストール途中のなんらかの確認」と誤解して Y → zip 展開 dir の top-level files (`Install.bat` 自身含む) が物理削除 → bat 実行が途絶 → cmd window 即閉じ、という silent corruption path。Phase 4 PR で Install.bat overwrite path を手動テストした際に再現、`@echo on` で `del "" 2>nul` を視認して原因特定。fix: `set "TEMP_MV_OUT=..."` を `:do_overwrite` block 内 (goto より前) に移動。本 bug は v0.2.0 → v0.3.0+ 移行 (= 旧構造から新構造への dir rename) を行う overwrite path で必ず発火するため、運用上の影響は大きい (= zip 再 DL + 再 install で復旧可能だがユーザー混乱大、データロストの可能性も残る)。Pre-existing bug を本 PR scope 内で fix する判断: Phase 4 PR でも `templates/Install.bat` を touch (Phase 4 案内文の更新) しているため commit history が同じ PR に閉じる、別 PR 分離は scope 整合性の細部にすぎず本 PR の重要性のほうが優先。

### [Release Tooling v0.1.15] - 2026-05-14

#### Changed (PR #159 シニアレビュー round 4)

- **[Claude M-1 + Codex P2] `Install-Hooks.ps1` の `Set-Location` を `Push-Location -LiteralPath` + try/finally Pop-Location に置き換え (cwd 副作用 + wildcard 解釈の 2 件同時対応)**: Claude M-1 = 旧実装の `Set-Location $repoRoot` は script 実行後も親 PowerShell session の current location を `$repoRoot` のまま残す副作用 (PS の location 状態は runspace 単位、scope 単位ではない、try/finally 対 `Pop-Location` 不在で revert 不能)。Codex P2 = 同じ行で `-Path` 引数が wildcard chars (`[`, `]`, `*`, `?`) を解釈するため、本 repo の `【ゲームセンターTONE】` (= 非 wildcard) は安全だが fork / clone 先の path に `[` / `]` が含まれると `PathNotFoundException` で abort、contributor が installer を実行できない path。両者を 1 fix で同時解消: `Push-Location -LiteralPath $repoRoot` で literal 扱い + 親 stack に保存、`try/finally { Pop-Location }` で `exit N` paths を含めて確実に restore。あわせて `Test-Path .githooks/pre-commit` も `-LiteralPath` 化、`Get-ChildItem .githooks` も `-LiteralPath .githooks` 化で wildcard interpretation 経路を全廃
- **[Claude M-2] AGENTS.md「Specification Management」に「SPEC 変更履歴も 1 PR 1 bump 原則」を明文化**: 旧 AGENTS.md の「1 PR 内の version bump は原則 1 回のみ」は文言上 CHANGELOG のみ対象とも読める範囲で、SPEC 変更履歴の 1 PR 多重 bump は規約違反ではなかった (本 PR #159 内で v1.10.17 / 1.10.18 / 1.10.19 / 1.10.20 の 4 連 bump が発生)。CHANGELOG / SPEC の運用一貫性を将来 implicit に分岐させないため、AGENTS.md「Specification Management」セクションに「**1 PR 内の SPEC 変更履歴 bump も原則 1 回のみ** (CHANGELOG 同様)」を 1 行追記。**本ルールは PR #159 round 4 以降に適用**、PR #159 内に既に存在する 1.10.17 / 1.10.18 / 1.10.19 / 1.10.20 の連続 bump は **移行前履歴として残置** (retroactive consolidation は scope creep のため見送り、round 4 では SPEC 版 bump を追加しない形で新規約を即時適用)
- **[Claude L-1] `Install-Hooks.ps1` 最終案内文の backtick escape 罠を修正**: 旧 `Write-Host "To verify: edit a .bat file to add a UTF-8 BOM, then \`git add\` + \`git commit\`."` は double-quoted string 内で `` `g `` / `` `c `` が PowerShell の escape character として消費され、console には `git add + git commit` (markdown style backtick が剥がれて) と表示される cosmetic bug。round 1 [Claude H-1] critical で fix した「backtick 由来の literal `\r\n` でファイル悪化」と同 family の path。single-quoted string に置換、backtick を literal で保持
- **[Claude L-2] CI workflow `paths` filter に `.githooks/pre-commit` 追加**: 旧 paths filter (`**/*.bat` / `**/*.cmd` / `.githooks/check-bat-encoding.ps1` / `.gitattributes` / workflow yaml 自身) は wrapper (`.githooks/pre-commit`) のみを変更する PR で workflow を発火させなかった。今後 wrapper だけを修正する小 PR (pwsh fallback 改修、log 改善等) でも safety net 側で「fence 全体が動くか」を CI 経由で再検証する自動契機を確保。push + pull_request 両 trigger に追加
- **[Claude L-3] `check-bat-encoding.ps1` 冒頭にも `[Console]::OutputEncoding = UTF8` を追加 (Install-Hooks との対称性確保)**: round 3 [Claude M-2] で `Install-Hooks.ps1` 側だけ `[Console]::OutputEncoding = UTF8` を明示したが、`check-bat-encoding.ps1` 側は未対応で violation message (`[FAIL] BOM detected: <Japanese path>`) が PS 5.1 + JP locale で stdout を CP932 decode → mojibake する path が残っていた (内部処理は round 2 [Claude H-2] の `Invoke-GitCapture` で UTF-8 path 取得済、最終 `Write-Host` 段階で encoding mismatch という dead-code 同型の不整合)。script 冒頭 (param block 直後、`$ErrorActionPreference = 'Stop'` の隣) に 1 行追加で symmetric に
- **[Claude L-4] `Test-WorkingTreeCrlf` docstring に true rationale 追記**: 既存 docstring は「working tree のみが LF-only state の signal source」を説明していたが、reader が「LF-only working tree が commit 内容に流入する」と誤解する path が残っていた。実際は `.gitattributes eol=crlf` が smudge で吸収するため最終 commit blob は CRLF-clean (= 検査の真の価値は contributor の editor-config 早期警告であって commit-content guard ではない)。docstring に「Even when this check FAILS in Mode Staged, the *committed* blob is still LF and `git checkout` smudges back to CRLF. Treat it as editor-config lint, not as a commit-content guard.」を 6 行 note として追加

#### 受容 (本 PR scope では対応せず、次 sweep 候補として明示)

- **[Claude L-5] `[void]$strictUtf8.GetString($payload)` の full string 化 O(N) memory**: `[System.Text.UTF8Encoding]::new($false, $true).GetCharCount($payload)` で char allocation なしで同等の `DecoderFallbackException` を得られるが、`.bat` file は通常数 KB で実害ゼロ。API 選択の整合性のみの細部、別 issue / 次 sweep 候補
- **[round 4 で SPEC bump なし]**: 本 round で導入する M-2 ルール「SPEC 1 PR 1 bump」を round 4 自身に即時適用するため、round 4 の changes (script docstring 補強 / workflow paths 追加 / AGENTS.md 追記) のいずれも SPEC 変更履歴に新 row を追加しない。SPEC §3.7.9.7 prose 本体への文言修正 (L-4 rationale clarification 等) も script docstring 側に閉じ、SPEC 側は v1.10.20 のまま固定。次の PR から SPEC 1 PR 1 bump 規約が full force で適用される
- **[Codex stale 系 finding]**: round 3 同様、Codex review が古い snapshot を見て既 fix 済 finding を re-flag する pattern は本 round 1 件 (`.gitattributes` を pull_request paths に追加) で再発、本 PR では code 修正なし

#### Changed (PR #159 シニアレビュー round 3)

- **[Claude M-1] SPEC §3.7.9.7 prose の claim-vs-impl 乖離解消 (CRLF 検査 source 明示)**: round 2 で hybrid 設計 (BOM/UTF-8 = blob、CRLF = working tree) を script docstring と CHANGELOG entry に書いたが、SPEC §3.7.9.7 本文は「バイト列は **git index の blob から** ... で取得」と前置きしてから 3 種検査 (BOM / LF / UTF-8) を箇条書きする構造で、reader は 3 種全部が blob 検査と自然解釈する path が残っていた (= round 2 [Claude H-1] と同型の整合化漏れ、CI 側は doc 同期したが Mode Staged 側の SPEC 本文に未着手)。SPEC §3.7.9.7 prose を 2 source 分岐記述に修正、`.gitattributes eol=crlf` で blob が常時 LF 化される事実が CRLF blob 検査を原理的に成り立たせない事も明記
- **[Claude M-2] Install-Hooks.ps1 の console encoding 明示 (JP locale + 日本語 path mojibake 防止)**: 本 repo worktree root が `C:\【ゲームセンターTONE】\GCTonePrism\` で Japanese を含み、PS 5.1 + JP locale で `& git rev-parse --show-toplevel` の stdout が CP932 として decode → mojibake → `Set-Location` が `PathNotFoundException` で abort する path があった。`check-bat-encoding.ps1` 側は round 2 [Claude H-2] で `Invoke-GitCapture` (`StandardOutputEncoding=UTF8`) で対応済だったが、`Install-Hooks.ps1` 側は同 PR scope 外として残存。冒頭に `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` + `$OutputEncoding = [System.Text.Encoding]::UTF8` を 2 行追加。`check-bat-encoding.ps1` のような Process ベース helper まで担ぐ必要は無く global override で十分 (helper は `&` 直呼び数行のみ)
- **[Codex P2 / pwsh fallback] `.githooks/pre-commit` shell wrapper を pwsh 優先 fallback 化**: `powershell.exe` hardcode は Windows 上では問題ないが、theoretical に macOS / Linux で hook が「not found」で all commit を hard block する path が残っていた (`core.hooksPath = .githooks` を別環境で適用した case 等)。`command -v pwsh` で先に PowerShell 7+ を探し、無ければ `powershell.exe`、両方不在なら friendly `[FAIL]` + bypass guide で exit 1。Windows-only project の方針は変えないが、defensive UX として hard block path を排除
- **[Claude L-4] `Test-WorkingTreeCrlf` violation message に first-occurrence hint 追加**: 旧 message「LF-only line ending detected: $Path (line $line, must be CRLF)」は最初の 1 件で `break` する設計だが、reader にはエディタ全体 LF 設定の case で「line $line だけ直して再 commit → 次の line で同 message」と勘違いする path があった。「(this is the first occurrence -- if your editor saved the whole file as LF, fix once and re-stage)」を追記、break 維持で出力 bounded のまま UX 改善
- **[Claude L-6] `Install-Hooks.ps1` の "Active hooks" filter を whitelist 化**: 旧実装 `Where-Object { $_.Name -notmatch '\.(ps1|md)$' }` は blacklist で、将来 `.githooks/` に `.psm1` / `.py` / `.txt` 等の補助 file を追加した時に誤って「Active hooks」として表示される。`Where-Object { $_.Extension -eq '' }` (= 拡張子なし = git hook 名の convention) に変更、whitelist 化で将来拡張耐性を獲得

#### 受容 (本 PR scope では対応せず、次 sweep 候補として明示)

- **[Claude L-3] `Invoke-GitCapture` の stdout/stderr 直列読みによる理論 deadlock**: 現 git subcommand (`diff --cached --name-only` / `ls-files` / `cat-file -p`) は stderr 出力がほぼゼロのため実害なし。将来 hook が他の git subcommand を増やすなら `BeginOutputReadLine` + `BeginErrorReadLine` の async pair に書き換え。理論既知 anti-pattern として記録のみ
- **[Claude L-5] SPEC version bump 3 連 (1.10.17 / 1.10.18 / 1.10.19) → 本 PR で 1.10.20 を更に重ねる結果に**: SPEC 側の「1 PR 1 bump」規定が AGENTS.md に無いため違反ではないが、review iteration の self-correction が SPEC table に永続化される pattern。CHANGELOG 側の「1 PR 1 bump」ルールと並行運用するなら merge 後の専用 PR で 1.10.17 を最新 state で書き直して 1.10.18-20 を rebase 集約する案も検討余地、本 PR scope 外
- **[Claude L-7] CR-only (classic Mac) line ending 未検出**: SPEC §3.7.9.1「UTF-8 (no BOM) + CRLF 厳守」を物理 fence するなら CR-only も reject すべきだが、2026 年現代の Windows editor が CR-only を吐く path は皆無、defensive 価値小。別 issue 候補
- **[Codex stale finding]** `.gitattributes` を pull_request paths に追加せよ: 本 finding は round 2 [Codex P2] と同一内容で、本 PR の `.github/workflows/check-bat-encoding.yml:45` で既に追加済。Codex review が古い snapshot を見ている stale report と判断、code 修正なし

#### Changed (PR #159 シニアレビュー round 2)

- **[Claude H-2 (Critical)] non-ASCII path 対応 (`core.quotepath=false` 全 invocation 適用)**: 本 repo root が `C:\【ゲームセンターTONE】\GCTonePrism` で Japanese path を含み、将来 `Companions/<日本語>/foo.bat` 等の追加で `core.quotepath` default true が C-style quoted (`"\343\203\206...bat"`) を返す → `Where-Object` regex は quoted 末尾 `"` も拡張子 match で拾う → `git cat-file -p ":\343..."` が解決不能 (exit 128) → round 1 [M-2] fail-closed で **primary fence 全体が dead-lock** する path があった。全 git invocation に `-c core.quotepath=false` を付与 + StandardOutputEncoding を UTF-8 に明示、non-ASCII path を raw UTF-8 で受け取る形に
- **[Claude H-1] CI の CRLF 検査が dead path であることを doc 側に明示 (claim-vs-impl 整合化)**: round 1 で `Test-WorkingTreeCrlf` を Mode All 経路にも組み込んだが、`actions/checkout@v4` 経由の fresh checkout では `.gitattributes eol=crlf` smudge が必ず先に発火 → working tree は常に CRLF → Mode All の CRLF 検査は **構造的に絶対 PASS する dead path**。PR description / SPEC / CHANGELOG は「CI が 3 種全部 catch」する建付けで claim-vs-impl 乖離していた。code は defence-in-depth として残置 (self-hosted runner や smudge 無効環境への保険)、SPEC §3.7.9.7 / CHANGELOG / PR description には「CI primary signal は **BOM + UTF-8 validity** の 2 種、CRLF は smudge 専管 + 環境変化への保険」を明記
- **[Claude M-1] PS 5.1 `2>&1` NativeCommandError trap を `Invoke-GitCapture` helper で物理解消**: round 1 では `& git ... 2>&1` で stderr を capture していたが、PS 5.1 (`.githooks/pre-commit` の `powershell.exe` 固定実行環境) では native exe の `2>&1` redirect が stderr 行を `NativeCommandError` ErrorRecord に wrap、`$ErrorActionPreference='Stop'` で terminating exception に転化 → script が friendly `[FAIL]` message に到達する前に kill される path があった。git 情報用 stderr (`warning: LF will be replaced by CRLF` 等) 1 行で発火する高頻度 path だった事に注意。`Invoke-GitCapture` helper (= `System.Diagnostics.Process` + 個別 `StandardError.ReadToEnd()` capture + try/finally Dispose、`StandardOutputEncoding` で UTF-8 明示) に全 git invocation を集約、`2>&1` を hook から完全排除。あわせて L-1 (Process / MemoryStream の Dispose 漏れ) も同 helper 内 try/finally で同時解消
- **[Claude M-2] SJIS recovery hint の 2 分岐表示 (`ReadAllText` UTF-8 default で SJIS content を U+FFFD に置換する逆効果 path 排除)**: round 1 の Codex P2 で UTF-8 validity 検査を加えて SJIS file を `[FAIL] Invalid UTF-8` で catch するようになったが、`[FAIL]` 直後に表示する復旧 PowerShell one-liner は `[System.IO.File]::ReadAllText('<path>')` (UTF-8 default) を使うため、ユーザーが指示通り走らせると **SJIS の Japanese bytes が U+FFFD replacement char に置換** され content 喪失 → Claude H-1 round 1 (literal `\r\n` でファイル悪化) と同型の「復旧 hint が逆効果」path が non-UTF-8 case で再発していた。violation 内に `Invalid UTF-8` が含まれる場合は CP932-aware path (`[System.Text.Encoding]::GetEncoding(932)` を `ReadAllText` の 2 番目引数に渡す) を表示する分岐に修正、source encoding 不明時は VS Code / Notepad++ 等の editor で「UTF-8 (without BOM)」に明示 re-save する案内も併記
- **[Codex P2 + Claude L-3] workflow trigger paths filter 整理**: (a) Codex P2: `.gitattributes` を pull_request paths に追加、`.bat eol=crlf` rule の削除 / 弱化 PR が workflow をスキップして merge 後 catch される silent regression path を防ぐ。(b) Claude L-3: `push: branches: [main]` trigger にも paths filter を追加 (`**/*.bat` / `**/*.cmd` / hook script / `.gitattributes`)、`.bat` 不変更の main push で windows-latest job 起動を抑止、CI minutes 節約
- **[Claude L-1] `Get-IndexBlobBytes` 内 Process / MemoryStream の Dispose 漏れ解消**: round 1 では `CopyTo` 等での例外時に handle leak、GC 任せだった。`Invoke-GitCapture` helper への集約に伴い try/finally で Dispose を明示
- **[Claude L-2 受容]** (`git cat-file -p :path` の `--` separator 追加要請): `:` で始まる rev:path notation は git argument parser が flag と誤解釈する path がなく、`cat-file -p` も `--` 受け付けない構文 (`<object>` は rev-spec、pathspec ではない) のため本 case には適用不可、コード内 comment で根拠を明示して受容
- **[Claude L-4] PR description Test plan に partial-staging case (Codex P1 verify) 追加**: round 1 fix commit message には 11 シナリオ verify が記載されていたが、PR body の Test plan checklist には partial-staging case (`(g) git add 後の working tree 修正で staged blob が BOM 含 → fence FAIL`) が未記載で commit log との整合 minor mismatch、PR body 側に追記

#### Changed (PR #159 シニアレビュー round 1)

- **[Codex P1 + Claude H-1 + M-1 + M-2] `.githooks/check-bat-encoding.ps1` の fence 設計上の silent bypass / 誤情報 path を一括解消**:
  - **Codex P1**: 旧実装は staged file の path から `[System.IO.File]::ReadAllBytes($Path)` で **working tree** を読んでいた。partial staging (`git add foo.bat` 後に foo.bat を再編集) で staged blob と working tree が乖離した場合、(a) staged blob は BOM 付きだが working tree は修正済 → hook PASS で bad blob commit (false negative)、(b) staged blob は clean だが working tree は LF 化された → 不要 block (false positive) という双方向 silent bypass path があった。Mode Staged で **`git cat-file -p :<path>`** を `System.Diagnostics.Process` + `MemoryStream` でバイナリ safe に capture する形に修正、index の blob を直接検査する設計に
  - **Claude H-1 (Critical)**: `[FAIL]` 出力時の復旧 PowerShell one-liner 内 replacement string が `"\r\n"` (= リテラル 4 文字 `\r\n`、PowerShell の escape 文字は backslash ではなく **backtick**) となっていた。実機で verify (PS 7.6 / win) すると `a\nb` → `61 5C 72 5C 6E 62` (= `a \ r \ n b` の 6 byte) を出力、ユーザーが指示通り実行すると BOM 除去は正しく動作する一方で LF が「\r\n」リテラル 4 文字に置換され **ファイルが今より悪化** する critical バグ。replacement string を ``` "`r`n" ``` (backtick escape) に修正、display message にも「backticks are PowerShell escape characters, NOT backslashes」と注記を追加。実機 re-verify で `a\nb` → `61 0D 0A 62` (= `a CRLF b`) の期待バイト列が得られることを confirm
  - **Claude M-1**: `--diff-filter=AM` が **Renamed (R) を取りこぼし**、rename + content 変更 (similarity ~99%) で `foo.bat` → `bar.bat` + 3 byte BOM 注入 という commit 1 つで fence を素通りする path があった (modern git の `diff.renames` default true 由来)。`--diff-filter=AMR` に拡張、rename target も検査対象に
  - **Claude M-2**: `git diff --cached` が exit code != 0 で失敗した場合 (corrupted index / `.git` permission 問題 / 未来の git I/F 変更等)、旧実装は `@()` を return → file count 0 → silent exit 0 で **primary fence が黙って commit を通す** path があった。`$LASTEXITCODE -ne 0` 時は `[FAIL] <command> failed (exit N): <stderr>` を出して exit 1 (fail-closed)
- **[Codex P2 + Claude M-3 + L-1 + L-2 + L-3 + L-4 + L-5 + L-6] 検査範囲拡張・UX・整合性 sweep**:
  - **Codex P2**: 旧実装は BOM + CRLF のみ検査、**Shift-JIS / ANSI / CP932 等の non-UTF-8 + no BOM + CRLF** は素通りしていた (script docstring の「UTF-8 (no BOM) + CRLF」claim と impl の gap)。strict UTF-8 validity 検査を追加 (`[System.Text.UTF8Encoding]::new($false, $true)` で `DecoderFallbackException` を catch)、SJIS の Japanese 文字等が混入した case を検出。BOM 付き file は BOM 部分を strip してから UTF-8 validity check することで double-report を避ける
  - **Claude M-3**: `Install-Hooks.ps1` が既存の `core.hooksPath` 値 (Husky / 企業内 lint hook 等) を **warning なしで上書き**していた。`git config --get core.hooksPath` で既存値を確認、`.githooks` 以外に設定済なら `[WARN]` + abort (`-Force` switch で override 可能)。`.githooks` に既に設定済の場合は idempotent に `[OK]` 表示のみで no-op
  - **Claude L-1**: PR description 内 `apps#157` を `#157` に訂正 (`apps` は別 repo の prefix で本 repo は `GCTonePrism`、display text のみのバグだが reader が confuse する。`Closes #157` で GH 自動 link が発火するので prefix 不要)
  - **Claude L-2**: `.github/workflows/check-bat-encoding.yml` に `permissions: contents: read` を追加。本 workflow は `actions/checkout` で read 操作のみ、write 不要のため least-privilege で supply-chain risk surface 縮小
  - **Claude L-3**: 行番号計算の `($bytes[0..$i] | Where-Object { $_ -eq 0x0A }).Count` が array slice + filter で O(N²)。worst case (= 違反が最後の LF) で 100 KB 級 file で体感遅延。scan ループの外で `$line = 1` counter を持ち、LF を見つけたら increment、violation 検出時に counter を report する single-pass O(N) 実装に書き換え
  - **Claude L-4**: `[OK] All .bat / .cmd files pass encoding check (N file(s))` を毎 commit (= `.bat` を含まない commit でも `.bat`/`.cmd` を含む場合) 表示する unix philosophy 違反 noise。Mode Staged の OK case は silent (= 何も出力せず exit 0)、Mode All (CI) のみ info 表示する形に
  - **Claude L-5**: SPEC §3.7.9.7 / PR description / 本 CHANGELOG entry の「A / M filter、D は対象外」記述を `--diff-filter=AMR` 対応に同期 (M-1 と同期、catalog vs call site の整合性確保)
  - **Claude L-6**: `Install-Hooks.ps1 -Uninstall` が `git config --unset` の exit code 5 (= key not set) を確認せずに `[OK] unset` を表示 → 元から設定されてない repo で「unset 成功」と誤報告する path があった。exit code 1/5 を「was not set (no change)」、0 を「unset success」、それ以外を `[FAIL]` に区別表示。さらに `core.hooksPath` が `.githooks` 以外に向いていた場合は「本 helper の管轄外」として unset を refuse (= Husky 等を意図せず clobber する path を排除)

#### Added (#157)

- **`.bat` / `.cmd` 用 encoding fence (pre-commit hook + CI 安全網)**: SPEC §3.7.9.1 の規約「UTF-8 (no BOM) + CRLF 厳守」を **物理 fence** として 2 段実装。PR #156 開発過程で Write ツールが Release.bat に UTF-8 BOM を付与し `@echo off` 自体が機能不全 → DryRun 実行時に `'t' is not recognized` 等の cmd.exe parse error 多発 → 手動 incident response が必要だった事故の再発防止が目的。`.gitattributes` の `*.bat eol=crlf` だけでは BOM 侵入を防げない (LF 半分対応のみ) ため、commit 前 + push 後の 2 段で encoding 違反を catch:
  - **1 段目 (pre-commit hook)**: `.githooks/pre-commit` (POSIX shell wrapper) + `.githooks/check-bat-encoding.ps1` (PowerShell 本体ロジック、`git cat-file -p :<path>` で git index の blob を `System.Diagnostics.Process` + `MemoryStream` でバイナリ safe に capture)。staged `.bat` / `.cmd` (`--diff-filter=AMR` = Added / Modified / Renamed、D / C / T は対象外) を逐次検証、(a) 先頭 3 byte `EF BB BF` で BOM 違反、(b) 任意 `\n` の直前が `\r` でなければ LF-only 違反、(c) strict UTF-8 validity 検査で `DecoderFallbackException` 時に non-UTF-8 違反、として exit 1。git invocation 失敗時は fail-closed で exit 1。失敗時は `[FAIL]` prefix message + 復旧 PowerShell one-liner を ASCII で表示。bypass: `git commit --no-verify` (推奨しない、AGENTS.md 「hooks を `--no-verify` で skip しない」原則と整合)
  - **2 段目 (GitHub Actions safety net)**: `.github/workflows/check-bat-encoding.yml` で `windows-latest` runner + `pwsh` で同 `check-bat-encoding.ps1` を `-Mode All` で再実行。`main` への push + `**/*.bat` / `**/*.cmd` / hook script 自身を含む PR を trigger、pre-commit hook を install していない contributor の push を catch する **安全網** (primary fence は hook 側、CI は二重チェック)
- **`Install-Hooks.ps1` (1 回 setup helper)**: 各 contributor が repo clone 後に 1 度実行する idempotent helper。`git config core.hooksPath .githooks` を設定するだけのシンプル実装。`-Uninstall` switch で `git config --unset core.hooksPath` の reversal も提供。`.git/hooks/` への copy 方式 (Husky 等) を採らない理由は (a) hook 自体が version control 下、(b) 更新は `git pull` で自動伝播、(c) `.git/hooks/` との drift 源を排除、の 3 点
- **対象拡張子**: `*.bat` + `*.cmd` のみ。`*.ps1` は PowerShell parser が BOM 寛容 + LF 許容のため fence 対象外
- **動作 verify** (本 PR 内で完了): (a) 既存 4 件の tracked `.bat` (Release.bat / Install.bat / Launcher.bat / Manager.bat) で `-Mode All` PASS、(b) BOM 付き `.bat` を一時 stage → `-Mode Staged` で `[FAIL] BOM detected: ...` 出力 + exit 1、(c) LF-only `.bat` を一時 stage → `[FAIL] LF-only line ending detected: ...` 出力 + exit 1、(d) `.githooks/pre-commit` shell wrapper の delegation も exit code 0 で通過
- 詳細仕様は **SPECIFICATION.md §3.7.9.7「encoding fence (pre-commit hook + CI 安全網)」** を参照

#### Notes (contributor 向け運用)

- **初回 clone 後** または **本 PR を merge した main を pull 後**: `.\Install-Hooks.ps1` を 1 度実行して `core.hooksPath` を有効化。以降の `git commit` で BOM / LF-only の `.bat` / `.cmd` は自動 reject
- **incident response**: `[FAIL]` 出力された場合、message 内の PowerShell one-liner で UTF-8 no BOM + CRLF に矯正してから再 commit
- **CI 失敗時** (hook 未 install で push してしまった等): 同じく PowerShell one-liner で修正 + force push

### [Release Tooling v0.1.14] - 2026-05-14

**TL;DR**: small cleanup 4 件 (#142 / #143 / #144 / #146) を 1 PR で消化。本来の deliverable は entry 末尾の **`#### Changed (refactor/release-tooling-cleanup、#142 / #143 / #144 / #146)`** セクション参照。以下に並ぶ round 1〜8 の `#### Changed (PR #156 シニアレビュー round N)` は review iteration 中の self-correction 履歴 (forward-looking text からの PR/round 番号 embed 自己違反 sweep、規約境界明確化、cross-reference 修正、CHANGELOG / PR body / SPEC / Release.bat の整合性同期、`Release.bat` の自己違反 ASCII 境界 sweep + AGENTS / SPEC の境界曖昧化 fence、SPEC SoT と code 状態の REM/echo 非対称扱い同期 等)。

#### Changed (PR #156 シニアレビュー round 8)

- **[Medium-2] SPEC 変更履歴 table v1.10.14 entry 内の line embed 2 箇所を literal anchor に置換 (round 7 [Low-1] sweep の table 内漏れ)**: round 7 [Low-1] で SPEC §3.7.9.1 本体の `Release.bat:46-48` line range embed を literal-content anchor に置換したが、**SPEC 変更履歴 table の v1.10.14 entry 内** に同型 embed が 2 箇所残存していた sweep 漏れ (`Release.bat:46-48` を 1 回、`line 21 / 26 / 29 / 48` を 1 回)。round 1 [High-3] / round 6 [High-3] / round 7 [High-2] で本 PR 内に何度も立てた「行番号 / line range 直 embed は rot 源泉」規約を SPEC table 内 row にも適用、`Release.bat` の `==== ASCII boundary (only when chcp 65001 succeeded above) ====` で始まる REM block / Usage REM block の `See SPECIFICATION.md` reference 行 / `setlocal enabledelayedexpansion` 直前 REM / chcp 切替 header REM / ASCII boundary marker 末尾 REM のような literal-content anchor に置換、Release.bat に REM を 1 行追加しても rot しない形に。round 7 [Low-1] の sweep 範囲を「SPEC §3.7.9.1 本体 + SPEC 変更履歴 table」に拡張
- **[Low-1] SPEC §3.7.9.2 に `%VAR: =%` leading space strip step の説明を追加 (doc-vs-impl gap 解消)**: `Release.bat` の `if defined ORIGINAL_CODEPAGE set ORIGINAL_CODEPAGE=%ORIGINAL_CODEPAGE: =%` は `for /f delims=:` 由来の leading space ( ` 932` のような形) を pure decimal に normalize する **validation 前提の必須 step** だが、本 PR の docstring SPEC 移管で Release.bat 本体の inline 説明 (旧 line 51 相当) が削除された一方で、SPEC §3.7.9.2 側は「`findstr /R "^[0-9][0-9]*$"` で純 decimal を確認」と書くのみで strip step に触れていなかった doc-vs-impl gap。「SPEC が whys、Release.bat が what + minimum context」原則に照らすと当該 step の why は SPEC 側にあるべきだった漏れ。SPEC §3.7.9.2 に「**leading space の strip (findstr 前段の必須 normalize)**」段落を新設、strip 省略時の silent rot path (findstr が leading space で fail → 数値 capture 成功 case でも skip path に落ちる) も明示
- **[Low-3] SPEC §3.7.9.1 「ASCII 境界」を REM / echo 非対称扱いに再記述 (round 7 [Medium-3] で code 側に立てた判定基準を SoT に反映)**: round 7 [Medium-3] で「**REM = ASCII pure、echo = WARN-zone 規約に従い Japanese OK**」の判定基準を Release.bat code 側で確立したが、**SoT 側 (SPEC §3.7.9.1) は「REM / echo 同列に ASCII で書き」の対称表現のまま**で code-vs-SoT 乖離が発生していた (= 次に Release.bat を触る人が SPEC §3.7.9.1 を読んで「post-WARN zone なら REM も Japanese OK」と判断する path 残存)。SPEC §3.7.9.1 を「REM (pre/post WARN-zone 問わず ASCII pure、tokenizer 安全側)」と「echo (`:runps` 冒頭の予告 WARN 以降なら Japanese OK、user value 維持)」を分岐記述する形に更新、SoT を code 状態に再同期。SPEC 変更履歴 v1.10.15 → v1.10.16

#### 受容 (本 PR scope では対応せず、次 sweep 候補として明示)

- **[Medium-1] CHANGELOG `[Release Tooling v0.1.14]` entry の self-correction 比率 ~86% (再掲、deferral 維持)**: round 7 [Low-2] で flag 済の scope 偏り、本 round で「**集約圧縮は再帰 paradox を起こさない (既存内容の物理移動、新規違反ではない)**」と review 指摘を反映して deferral 理由を訂正済 (旧 paradox framing は厳密には誤りだった)。merge 後に「`v0.1.14` entry round 1〜8 圧縮」だけの専用 issue + PR を立てて 1 段で消化、当該 PR では round 1〜8 全 entry → 「self-correction history (詳細は merged PR #156 コメント参照)」1 行に短縮する案を recommend。`## Bundle` セクションが GitHub Releases に流れる SoT で `## Release Tooling` は開発者向け詳細履歴という規約 (AGENTS.md `CHANGELOG Section Roles`) を考えるとエンドユーザー被害ゼロで開発者の読解コストのみが問題
- **[Low-2] AGENTS.md「Release Tooling 命名規約」が PSScriptAnalyzer `PSUseApprovedVerbs` warning との関係に未言及**: `Assert-*` は PS approved verb ではないため PSScriptAnalyzer 導入時に 8 件の warning が出る可能性があるが、現状 repo に PSScriptAnalyzer / `PSScriptAnalyzerSettings.psd1` は無く実害ゼロ (`Glob '*.psd1'` ヒットなし)、warning は発生しない。PSScriptAnalyzer 導入を判断する別 issue 起票時に「`PSUseApprovedVerbs` を `Assert-*` に対して suppress する `.psd1` 設定」要件も合わせて整理する方が穏便、本 PR scope では明文化 skip

#### Changed (PR #156 シニアレビュー round 7)

- **[High-1] PR body `[#146]` セクションの「ログ表示用」表現を CHANGELOG / Release.ps1 と同期**: round 6 [High-2] で CHANGELOG `[#146]` entry の「ログ表示用」を「phase identifier (Fail / Warn message に embed される user-facing diagnostic)」に同期したが、**PR body 同セクションは未同期で残った漏れ**。round 2 [High-1] が確立した「CHANGELOG ×2 + SPEC + PR body ×2 = 5 者同期」原則の自己違反 (merge 時の squash commit message も PR body 由来になり得るため、commit history への mismatch 流入も問題)。PR body line 8 を CHANGELOG deliverable section の最新 phrasing に同期、round 6 [High-2] の影響範囲を「CHANGELOG ×N + PR body」と明示
- **[High-2] CHANGELOG round 5 [Low-2] entry の `[Release.ps1 line 843 / 847 / 851]` 行番号 embed を anchor 表現に置換**: round 6 [High-3] で round 1 / round 2 内の `line 73` embed を sweep したが、**round 5 [Low-2] の line 843/847/851 embed は同型 violation なのに sweep 対象外として残存**。行番号自体は本日時点で正しいが、`Assert-WorkingTreeClean` の Fail / Warn を 1 行でも増減させると 3 箇所同時に rot する。round 1 [High-3] 規約 (行番号は rot 源泉、関数 / セクション anchor 化) を round 5 entry にも適用、「`Assert-WorkingTreeClean` 内の `Fail` message / `-Force` 経由 `Write-Warn` / uncommitted change 検出 `Write-Host (Yellow)` の 3 site」のような関数名 + 出力種別 anchor に置換。round 6 [High-3] の sweep 範囲を「PR 内全 round の `line N` embed」に拡張
- **[High-3] PR body `[#143]` セクションの `round 4 L-2` round 番号 embed を削除**: round 5 [High-1] で AGENTS.md / Release.ps1 catalog meta-rule / SPEC §3.7.9.4 の 3 箇所から PR/round 番号 embed を sweep したが、**PR body は対象外として残った漏れ**。round 1 [Low-1] / round 3 [Low-1] / round 4 [Low-1] が確立した「forward-looking text に process trivia / PR 識別子を入れない」原則の自己違反 (PR body は merge 後の squash commit message に流入する forward-looking text)。PR body line 25 を「Release.bat: 165 → 110 行 (約 33% 削減、ASCII boundary REM block を 3 行構成にした分 +2 行)」のような round 番号フリー表現に書き換え、round 5 の sweep 範囲を「forward-looking text 全箇所 (AGENTS / SPEC / Release.ps1 / PR body / CHANGELOG forward-looking 部分)」に拡張
- **[Medium-1] SPEC §3.7.9.4「system codepage」を「console codepage」に統一 (§3.7.9.1 との用語不整合解消)**: §3.7.9.1 は「`chcp 65001` 行より上は **console codepage** (JP locale = CP932) でパースされる」、§3.7.9.4 は「bat parser はファイルを **system codepage** (JP locale = cp932) で読む」と同一概念を別用語で記述していた。Windows 上で console codepage (OEMCP、`chcp` で操作可能) と system codepage (ANSI / ACP、system locale 由来で `chcp` 不変) は **別概念** で、cmd.exe bat parser が見るのは console (OEM) codepage の方。「system codepage」は技術的に誤読を招き、§3.7.9.1 の「`chcp 65001` 行より上は CP932 でパース」説明とも論理的に不整合。本 PR が確立した「§3.7.9.X = SPEC 側 SoT、Release.bat 本体は SPEC 参照」原則の SoT 自身が用語ブレを抱える状態だったので §3.7.9.4 を「console codepage (JP locale = CP932、§3.7.9.1 参照)」に統一 (大文字小文字も CP932 で統一)。SPEC 変更履歴 v1.10.14 → v1.10.15
- **[Medium-2] CHANGELOG round 6 [High-1] entry 内 `line 21 / 26 / 29 / 48` 行番号 embed 4 個を役割 anchor に置換**: round 6 [High-3] で round 1 / round 2 の `line 73` embed を sweep した直後の同 round 内で、別 entry (round 6 [High-1]) が 4 箇所 line embed していた連動 regression。round 6 自身が「同 PR 内で確立した規約を同 round の他 entry で違反する連動 regression」を flag した直後の同型違反 (= 同 round 内 self-violation)。「`See SPECIFICATION.md` reference 行 / `SPEC §3.7.9.3` reference 行 / 3-way branch header / ASCII boundary REM block 末尾行」のような役割 anchor 表現に置換、Release.bat に REM を 1 行追加しても rot しない形に
- **[Medium-3] Release.bat 残存 `§` + 日本語 REM を 2 zone で sweep (round 6 で確立した新 SPEC fence + rationale の対称適用)**: review が flag したのは exit code dispatch 直前 REM (`SPEC §3.7.9.4`) と codepage 復元直前 REM (`呼出元 cmd の codepage を復元 ..., SPEC §3.7.9.6`) の 2 行 (= post-WARN zone) だったが、verify 中に **parseargs section の 3 つの日本語 REM (`引数を解析...` / `引数にスペース...` / `初回 append 時...`) が pre-WARN zone (chcp 65001 直後 ~ `:runps` ラベル冒頭の予告 WARN 間) に残存** していたことを発見、両 zone を一括 sweep:
  - **pre-WARN zone 3 行** (`set SCRIPT_DIR=%~dp0` ~ `:runps` 間): round 6 [Medium-2] で新設した SPEC §3.7.9.1 fence (「skip path で実行されうる REM / echo (= chcp 65001 直後から `:runps` ラベル冒頭の予告 WARN まで) は ASCII で書き」) への hard 違反 (= fence 立てと同 PR 内での fence 違反、round 6 内 self-violation の連鎖)。Parse args 説明 / Quote args 説明 / Skip leading space 説明をすべて英訳して ASCII pure 化
  - **post-WARN zone 2 行** (exit code dispatch 直前 REM、codepage 復元直前 REM): SPEC §3.7.9.1 の WARN-zone 規約に照らせば技術的に許容範囲だが、round 6 [High-1] の rot rationale (REM tokenizer 安全側) は post-WARN 領域にも同程度に当てはまる (= 「pre-chcp-effective 領域だけ ASCII pure」境界が rationale と非対称で判定基準が読み手に伝わらない)。両 REM 行を ASCII 化 (`SPEC 3.7.9.4` / `SPEC 3.7.9.6` reference + Japanese を英訳)
  - **user-facing echo 行 5 件** (引数表示 / 正常終了 / publish skip ×2 / FAIL message): post-WARN zone の意図的 Japanese として維持 (= reader 向け実行結果、ASCII にすると user value 喪失)。これで「**REM = ASCII pure、echo = WARN-zone 規約に従い Japanese OK**」の判定基準を Release.bat 全体で確立、SPEC §3.7.9.1 fence と code 状態が完全整合
- **[Low-1] SPEC §3.7.9.1 末尾の `Release.bat:46-48` line range embed を literal-content anchor に置換**: round 1 [High-3] / round 6 [High-3] が CHANGELOG 文脈で立てた「行番号 / line range 直 embed は rot 源泉」規約を SPEC にも適用。`Release.bat:46-48` を「`Release.bat` の `==== ASCII boundary (only when chcp 65001 succeeded above) ====` REM block (`chcp 65001` 切替の直後、`set SCRIPT_DIR=%~dp0` 直前に配置)」のような literal content + 周辺 anchor 表現に置換、Release.bat に REM を追加しても rot しない形に

#### 受容 (本 PR scope では対応せず、次 sweep 候補として明示)

- **[Low-2] CHANGELOG `## Release Tooling v0.1.14` entry の round 1〜7 self-correction 部分を 1 bullet 集約に圧縮**: round 5 [Medium-3] で TL;DR 1 行を冒頭追加したが、round 6 / round 7 で更に self-correction round が増え、deliverable `#### Changed (#142 / #143 / #144 / #146)` 比率は ~17% のまま (本 round 後で計 28 sub-bullet 中 4 bullet = ~14% に更に悪化)。圧縮自体は round N+1 の self-correction として flag される性質のものではなく (既存内容の物理移動であって新規違反ではない) **専用 PR で 1 段消化する方が圧縮基準を独立 review できる**。`## Bundle` セクションが GitHub Releases に流れる SoT で `## Release Tooling` は開発者向け詳細履歴という規約 (AGENTS.md `CHANGELOG Section Roles`) を考えると、エンドユーザー被害ゼロで開発者の読解コストのみが問題、本 PR scope に押し込むより専用 issue 化が穏便

#### Changed (PR #156 シニアレビュー round 6)

- **[High-1] `Release.bat` 内 `§3.7.9.X` reference 4 箇所を ASCII 化 (本 PR 規約への自己違反 sweep)**: 本 PR が CHANGELOG / Release.bat docstring header 「Comments / echo above `chcp 65001` MUST stay ASCII」 / SPEC §3.7.9.1 で「`chcp 65001` 行より上は ASCII のみ」と明文化したにもかかわらず、`Release.bat` 自体が `See SPECIFICATION.md` reference 行 / `SPEC §3.7.9.3` reference 行 / 3-way branch header / ASCII boundary REM block 末尾行 の 4 箇所で `§` (Latin-1 0xA7、UTF-8 0xC2 0xA7) や日本語を embed していた自己違反。Skip path では codepage 不変 (CP932) のため `§` は `ﾂｧ` 等の mojibake になり、長期的には cmd.exe の REM 行 tokenizer に多バイト列が紛れ込んで silent rot を招く path。4 箇所すべてを ASCII reference (`section 3.7.9` / `SPEC 3.7.9.X`) に置換、§ 記号も日本語タイトルも削除。review が flag したのは 2 箇所 (`See SPECIFICATION.md` reference 行 と ASCII boundary REM block 末尾) だったが、同型 violation の `SPEC §3.7.9.3` reference 行 と 3-way branch header も同時 sweep して規約を完結 (Release.bat の pre-chcp-effective 領域全体が ASCII pure に戻った状態を確立)
- **[High-2] CHANGELOG `#### Changed (#142 / #143 / #144 / #146)` の `[#146]` entry 内「`$Context` は『ログ表示用』として責務分離」を round 5 [Low-2] と同期**: round 5 [Low-2] が code 上で `$Context` param description を「ログ表示用」→「phase identifier (Fail / Warn message にも含まれる、user-facing diagnostic)」に正確化済だったにもかかわらず、本 PR deliverable summary に旧表現「ログ表示用」が残存していた doc-vs-impl mismatch。本 PR 自身が解消したはずの「文字列マッチで silent fail」型 regression と同型 (= round 5 の correction が deliverable section に伝搬しないまま残り、reader が古い phrasing を信じる path)。entry を「`$Context` は phase identifier (Fail / Warn message に embed される user-facing diagnostic) として責務分離 (round 5 [Low-2] で『ログ表示用』表現を正確化済)」に同期、round 内 cross-reference も含めて固定化
- **[High-3] CHANGELOG round 1 [Medium-1] / round 2 [High-2] の `line 73` embed を anchor 表現に置換**: round 1 [High-3] で「行番号を CHANGELOG entry に embed する文化そのものが rot 源泉、関数名 / セクション名で anchor 化」と立てた規約に対し、同じ round 1 / round 2 entry 内で `line 73` を 2 箇所 embed していた自己違反 (= 規約立て当日に同 PR の他 entry で違反するという連動 regression)。さらに `line 73` の値自体が誤り (`Release.bat` line 73 は `:runps` ラベル直後の REM、実際の WARN echo は line 75)。両 entry とも `line 73` 表現を「`:runps` ラベル直後の `if not defined ORIGINAL_CODEPAGE` ブロック」または「`:runps` ラベル冒頭の WARN」のような関数 / セクション anchor 表現に置換、round 1 [High-3] 規約の物理 sweep を完結
- **[Medium-1] AGENTS.md「Release Tooling 命名規約」に `Get-*` vs `Assert-*` の判定軸を追加**: 旧規約は「`Get-*` (取得) は副次的に Fail し得るが対象外」と一行で示すのみで、`Assert-LauncherVersion` (値 return + hard fail) と `Get-BundleReleaseNotes -AllowMissing` (値 return + soft fail 経路あり) のように構造が酷似する 2 関数を**何で分けるか**の判定基準が言語化されていなかった。本 PR で「`Assert-*` 範疇は『Fail 到達しうる』を critical 軸」と明文化した直後の境界 ambiguity (= 次に Release.ps1 を触る人が `Get-BundleReleaseNotes` も `Assert-` 化すべきと過剰 sweep する path)。判定軸として **caller の fail tolerance** を追加: soft fail 経路 (`-AllowMissing` 等で空文字 / `$null` 返却) を持つ取得関数は `Get-*`、hard fail のみで return 値が必ず非空となる検証関数は `Assert-*`。switch 追加で fail tolerance が後発で導入される場合は rename を検討する運用も明示
- **[Medium-2] SPEC §3.7.9.1 「ASCII 境界」定義を skip path 経路を accounting する形に正確化**: 旧定義「`chcp 65001` 行より上は ASCII のみ、それより下は UTF-8 console で Japanese 安全」は §3.7.9.2 の `corrupted format` / `not captured` skip path を計算に入れておらず、skip path 時は `chcp 65001` 行より物理的に下も CP932 のまま (= 境界自体が条件付き) という事実と齟齬していた。本 PR で `Release.bat:46-48` の ASCII boundary marker を round 4 [Low-2] で 3 行に拡張した時に「`only when chcp 65001 succeeded above`」条件を marker 自体に embed したが、SPEC 本文側は条件を accounting する形に更新できていなかった漏れ。新定義では (a) chcp 65001 成功 path / (b) skip path の 2 経路を分岐明示、安全側設計として「skip path で実行されうる REM / echo は ASCII で書き、Japanese 出力は `:runps` ラベル冒頭の予告 WARN 以降に置く」運用規約を明文化。SPEC 変更履歴に v1.10.13 → v1.10.14 として追記

#### Changed (PR #156 シニアレビュー round 5)

- **[High-1 + Medium-1 + Medium-2] forward-looking text からの PR/round 番号 embed 自己違反 sweep**: round 3 [Low-1] / round 4 [Low-1] で「forward-looking な箇所に process trivia / PR 識別子を入れない」原則を確立し、round 4 [High-3] でも「行番号 embed 文化が rot 源泉」と立規範していたにもかかわらず、本 PR で新規追加した text 自体が同型違反を 3 箇所に embed していた:
  - AGENTS.md「Release Tooling 命名規約」: `PR #140 round 6 で ... round 9 で ...、PR #156 で ... sweep 完結` の括弧を embed
  - Release.ps1 catalog meta-rule: 末尾括弧に `#142 / PR #140 round 9 M1` embed
  - SPECIFICATION.md §3.7.9.4: 「Install.bat 統一 pattern、`PR #149 round 3 で本 file にも適用`」embed
  3 箇所すべてから PR/round 番号を削除、規約 / 経緯の本文のみ残す形に統一。AGENTS.md は具体的な関数名例 (`Assert-Preflight` / `Assert-ExpectedFiles` / `Assert-LauncherVersion` 等) で趣旨を保持、PR 番号は CHANGELOG / git blame で追える
- **[Medium-3] CHANGELOG v0.1.14 entry 冒頭に TL;DR 1 行追加**: round 3 受容 [Low-2] で「self-correction が ~80%、元 cleanup 4 件が末尾に埋もれる」scope 偏りを flag した状態だったが、本 round で「次回 sweep」を待たず冒頭 1 行 TL;DR で lookup 性を改善 (#### Added 直前位置)。本来の deliverable (#142 / #143 / #144 / #146) が entry 末尾にある旨と、間の round 1〜5 が review iteration self-correction 履歴である旨を 2 行で明示
- **[Low-1] `Assert-WorkingTreeClean` の `if ($PostSync)` 直上 4 行コメント削除**: round 3 受容 [Low-3] で flag した「param description + if 直上の 4 行で同事象 2 重記載」を本 round で sweep。param 行の 1 行 description のみ残し、4 行コメント (`# #146 / PR #140 round 10 M3: ...` の経緯詳述) は git blame と CHANGELOG #146 entry で追跡可能なので削除。同時に `#146 / PR #140 round 10 M3` の trivia 削除も達成 (H-1 系列の sweep にも該当)
- **[Low-2] `$Context` param description を「ログ表示用」→「phase identifier (Fail / Warn message にも含まれる、user-facing diagnostic)」に正確化**: 旧 description は user-facing 出力 (`Assert-WorkingTreeClean` 内の `Fail` message / `-Force` 経由 `Write-Warn` / uncommitted change 検出 `Write-Host (Yellow)` の 3 site) にも `$Context` が embed される事実と乖離していて、reader が「ログ表示用なら typo / 文言調整して大丈夫」と誤読する path があった。本 PR が解消した「文字列マッチで silent fail」型 regression (`-like '*sync 後*'` → `[switch]$PostSync`) の再発防止のため、`$Context` 変更が user-facing 出力にも波及する点を明示
- **[Low-3] CHANGELOG round 1 [High-1] sweep verify に「`^function` anchor は本 project 定義関数のみ対象」注記追加**: 旧記載 `Grep '^function Read-' Release.ps1` のみで「`Read-Host` 等の対話 cmdlet 除外」前提が暗黙だった。`^function` anchor は cmdlet 呼出しを除外する事実を明示、将来「`Read-Host` 等の cmdlet 呼出し以外で新規 `Read-*` 関数を定義する case では本規約と purpose 限定句を再評価」の note も追加

#### Changed (PR #156 シニアレビュー round 4)

- **[High-1 + Medium-3] AGENTS.md「Release Tooling 命名規約」に purpose 限定句を追加して sweep 誘発 risk を遮断**: 旧文言「`Fail` 到達しうる関数は `Assert-*`」は文字通り適用すると Release.ps1 内 ~10 関数 (`Resolve-Godot` / `Resolve-MsBuild` / `Resolve-Nuget` / `Resolve-TagConflict` / `Set-ManifestVersions` / `Build-Launcher` / `Build-Manager` / `Build-Updater` / `New-Zip` / `Invoke-GhRelease` / `Get-BundleReleaseNotes` 等) が対象になり、次に Release.ps1 を触る人が「`Resolve-Godot` も `Assert-` にすべき」と過剰 sweep を始める誘発要因になっていた (本 PR 自体が round 1 [High-1] で `Read-GodotMinorFromProject` の漏れ補完をした同型 regression が再発する path)。**「主目的が検証 (verification)」の purpose 限定句**を追加、`Resolve-*` (探索/解決) / `Build-*` (生成) / `Set-*` (副作用) / `New-*` (生成) / `Get-*` (取得) / `Invoke-*` (呼出し) は副次的に Fail し得るが対象外と明示。拡張解釈 (b) も「**主目的が検証で**、return 値あり + Fail 到達しうる関数」と purpose 限定句を二重に重ねて境界曖昧化を fence
- **[Medium-1] catalog 内 per-site 書き方 meta-rule を 9 行 → 2 行に圧縮**: 旧 meta-rule (catalog 既述の一般則は per-site から削除、固有理由のみ残す + 判定基準) を catalog 冒頭に 9 行で固定化していたが、Release.ps1 内の `# pattern:` per-site 適用先は `Assert-WorkingTreeClean` の 1 箇所のみで sample size 1。9 行は明らかにオーバーキル比率。圧縮: 「`# pattern: <NAME>` 1 行で catalog 参照、catalog 既述の一般則は per-site から削除して固有理由のみ残す形式」の 2 行に縮約、適用 site が増えるまで詳細は固定化を delay
- **[Medium-2] SPEC §3.7.9.5 の `[FAIL]` ASCII prefix 議論を §3.7.9.4 末尾に移動 (構造ミスマッチ解消)**: round 1 [Medium-1] / round 2 [High-2] / round 3 [High-1] の 3 round 連続で同段落の cross-reference 修正を繰り返した構造的根因は「§3.7.9.5 (exit code 体系) 配下に文字化け回避策の話が混在」していた配置ミス。§3.7.9.5 は exit code 表のみに専念、`[FAIL]` ASCII prefix + `:runps` 冒頭 WARN は §3.7.9.4 (top-level goto label) 末尾の「文字化け回避策の連動」段落として束ね直し (chcp skip path + top-level goto + ASCII prefix の 3 段防御を 1 つの文脈で表現)
- **[Low-2] Release.bat:46 ASCII boundary 1 行 ~115 char を 3 行 REM block に分割**: 旧コメント 1 行で `chcp 65001 succeeded -> UTF-8 console below; on skip path, codepage unchanged -- see SPEC §3.7.9.2` を全部入れていたが横スクロール必須レベル。3 行に分割 (「==== ASCII boundary ====」+ 「chcp 65001 succeeded → UTF-8 console below」+ 「skip path → codepage unchanged, SPEC §3.7.9.2 参照」)。Release.bat 行数は 108 → 110 行に微増、約 33% 削減扱い

#### Followup (本 PR scope 外、別途対応)

- **[Low-1] pre-commit hook fence 化 GitHub issue 作成**: round 2 [Low-2] で書いた「将来 pre-commit hook で fence 化予定」が文書のみで未 issue 化だった点を解消、別途 GitHub issue を立てて TODO を捕捉

#### Changed (PR #156 シニアレビュー round 3)

- **[High-1] SPEC §3.7.9.5 cross-reference を Release.bat コード anchor 直指しに**: round 2 [High-2] で `§3.7.9.2 → §3.7.9.4` に reference 先を移したが、§3.7.9.4 本文も `:runps` / WARN / chcp skip 通知に一切触れておらず dead reference 状態が継続していた self-fix 同型 regression。round 1 [High-3] 「行番号 embed より関数 / セクション anchor」原則の延長で、SPEC 内部 anchor を諦めて **Release.bat の `:runps` ラベル冒頭の `if not defined ORIGINAL_CODEPAGE` ブロック** をコード anchor として直指し + 「powershell.exe 呼び出し **前**、Japanese 出力の前に予告を入れる位置」と文脈明示。これで reader は §3.7.9.4 を引かず直接 Release.bat 本体に飛んで実装確認できる
- **[High-2] rename 根拠を「PS verb convention 違反」→「project 内部 convention」に事実訂正**: CHANGELOG 内 2 箇所 (round 1 [High-1] entry と #144 entry) で「PowerShell verb convention 上『Read-* は対話的入力』を意味する」と書いていたが、**事実誤認**。`Read` は PS approved verb (Communications category、Microsoft 公式) で `Read-Counter` / `Read-Acl` 等の非 interactive cmdlet も存在。`Read-Host` がたまたま interactive なだけ。さらに本 PR で導入した `Assert-*` 自体が PS approved verb ではない (`Get-Verb` に存在しない) ので、「PS convention 違反を直すための rename」が **より強い PS convention 違反 (非 approved verb) に置換** している自己 invalidating な根拠引用だった。正しい記述「**本 project の規約「Fail する関数は `Assert-*`」(PR #140 round 6 / round 9 で確立)**、PS approved verbs では `Read` は approved だが、本 project では『Fail 到達しうる』を critical 軸とする internal convention で `Assert-*` 統一」に書き換え。AGENTS.md にも「Release Tooling 命名規約」セクションを新設してこの拡張解釈 (return 値ありでも Fail 到達しうれば `Assert-*` 含む、PS approved verbs と本 project 規約の優先順位) を明文化
- **[Medium-1] AGENTS.md に `Assert-*` 規約の拡張解釈を明文化** (Medium 1): H-2 の対応として「Release Tooling 命名規約」セクションを新設。`Assert-LauncherVersion` / `Assert-ManagerVersion` / `Assert-GodotMinorFromProject` は値を return する getter なので `Assert-*` の語感と一致しない指摘に対し、**「(a) return 値なし or (b) return 値あり + Fail 到達しうる関数の両方を含む拡張解釈」を明示**、将来 sweep 時に同議論が再発する path を fence
- **[Medium-2] Release.bat ASCII boundary コメントを条件付き表現に**: 旧 `REM ==== ASCII boundary (chcp 65001 above, UTF-8 console below) ====` は「chcp 65001 が必ず効いている」前提で書かれていたが、実際は `if defined ORIGINAL_CODEPAGE (chcp ...) else (echo WARN)` の else 分岐 (skip path) を取った場合は console codepage が元のまま (cp932 等)。コメントを `chcp 65001 succeeded -> UTF-8 console below; on skip path, codepage unchanged -- see SPEC §3.7.9.2` の条件付き表現に修正、reader が字面通り信じる誤読を防ぐ
- **[Medium-3] CHANGELOG `(c)` 記号削除 (catalog `(a)/(b)` との命名衝突解消)**: round 1 [Medium-2] / round 2 [Medium-2] で 2 回手を入れていた dangling reference 問題の **構造的根因** は、同じ `(a)/(b)/(c)` 記号が catalog 側で「PASS_THROUGH 内部 sub-label」、CHANGELOG 側で「policy 候補番号」の 2 軸を表す命名衝突。CHANGELOG 側の `(c)` 記号 (= policy 候補番号) を削除して「**採用方針: catalog 一般則 + per-site 固有理由**」と文章記述に書き換え、catalog 側の `(a)/(b)` (PASS_THROUGH sub-label) との衝突を構造的に avoid

#### 受容 (本 PR scope では対応せず、次 sweep 候補として明示)

- **[Low-1] catalog 内「per-site コメントの書き方」が catalog list (1./2./3.) の前に inline 挿入で構造的に非 parallel**: catalog item と meta-rule の structure 衝突は cosmetic で実害なし、次 sweep 時に「per-site コメント規約」を独立 section header にする or SPEC 側に移すかを再検討
- **[Low-2] CHANGELOG `## Release Tooling v0.1.14` entry 構成 (round 1+2+3 self-correction が元 cleanup 4 件を埋もれさせる)**: 元 deliverable が物理的に entry 末尾、self-correction メタ entry が ~80% 占める scope 偏り。次回 sweep 時に「元 deliverable を冒頭 → round 1 → ...」の時系列 (古い順) 並び替え、または冒頭 1 行 TL;DR 追加を検討
- **[Low-3] `[switch]$PostSync` param description が param 行と if ブロック直上の 2 箇所で同事象説明**: param 行と if 直上の 2 重記載は cosmetic、次回 Release.ps1 触る時に param 行を圧縮 or 一方に集約

#### Changed (PR #156 シニアレビュー round 2)

- **[High-1] PR body 内の行数 claim 2 箇所を `108 行 / 約 35%` に同期 (5 者同期の漏れ補完)**: round 1 [High-2] は CHANGELOG ×2 + SPEC v1.10.13 の 3 者を同期したと書いたが、5 者同期チェック相当の対象である **PR body 内 2 箇所** (`#143` セクション + `## 検証` セクション) が未同期で残っていた author self-violation。merge 時の squash commit message も PR body 由来になりうるため、commit history への mismatch 流入も防ぐ目的で同期。round 1 [High-2] の修正範囲を「CHANGELOG ×2 + SPEC + PR body ×2 = 5 者同期」に拡張
- **[High-2] SPEC §3.7.9.5 の cross-reference を実体に揃え**: round 1 [Medium-1] で追加した「§3.7.9.2 で `[WARN] Codepage switch was skipped; ...` の予告」cross-reference が、§3.7.9.2 本文に当該 WARN 文字列の言及がない dead reference 状態だった。WARN の出力箇所は Release.bat の `:runps` ラベル直後の `if not defined ORIGINAL_CODEPAGE` ブロック (§3.7.9.4 で top-level goto pattern の一部として説明済) なので、§3.7.9.5 の cross-reference を「Release.bat の `:runps` 経路冒頭で WARN を ASCII で再 echo、§3.7.9.4 参照」に修正。SPEC reader が「§3.7.9.2 を読みに行って WARN を探しても見つからない」path を排除
- **[Medium-1] `Assert-WorkingTreeClean` per-site コメントを 1 行に短縮 (#142 新ガイドライン厳格適用)**: 旧 per-site は `# pattern: CAPTURE_STDOUT_PASS_STDERR` + `# redirect を外しただけだと git 失敗時に $gitStatus が空文字になり「working tree clean」と誤判定されるため、exit code チェックが必須` の 3 行で、後者 2 行は catalog 一般則「`exit code チェック必須 ($output が空でも非ゼロ exit を見落とさないため)`」を site-local 名前 (`$gitStatus` / 「working tree clean」) で言い換えただけだった。同 PR #142 で確立した判定基準「catalog の説明と等価なら per-site から削除」を厳格適用、per-site を `# pattern: CAPTURE_STDOUT_PASS_STDERR` の 1 行に短縮 (新規約の sweep 完結)
- **[Medium-2] CHANGELOG round 1 [Medium-2] entry の dangling reference 主張を正確化**: 旧 entry は「catalog 側に (a)/(b)/(c) の言及がなく dangling reference」と書いたが、実際は **`(a)` (PASS_THROUGH 内部の「直 & 演算子版」) / `(b)` (PASS_THROUGH 内部の「Invoke-ExternalProcess helper 経由」) は catalog 側に実在、`(c)` のみ無い** 状態。「catalog に (a)/(b)/(c) の言及なし」は半分しか正しくない事実誤認だった。正しい記述「`(a)/(b)` は PASS_THROUGH の sub-label として実在、`(c)` のみ catalog に無い dangling reference」に正確化
- **[Low-1] CHANGELOG round 1 [High-1] に sweep 完結 verify 証跡追加**: round 1 [High-1] は「`Read-*` sweep を完結」と再主張したが、verify 記録 (= 残存ゼロ確認の grep 結果) が CHANGELOG に残らず、次の sweep 漏れが起きた時に「これは sweep 完結なのか、また漏れか」を切り分けられない問題があった。[High-1] entry に「sweep 完結確認: `Grep '^function Read-' Release.ps1` で残存ゼロ verify 済」の 1 行を追加、code-level の証跡を残す
- **[Low-2] Notes 文言を contributor 全員への手順強制 → encoding 破壊検出時の incident response 手順 + 将来 pre-commit hook fence 化予告に rephrase**: 旧 Notes 「編集後は ... ReadAllBytes で確認 + 必要なら ReadAllText で再 encode の後処理を行うこと」は contributor 全員に重い手順を毎回課す表現で、PR 内で確立した「規約は fence で物理的に防ぐ」原則 (round 1 [High-2] / [Medium-2] 等) と不整合だった。修正: 「encoding 破壊検出時の incident response 手順」に位置付け直し、通常 commit 時は `.gitattributes` 等の規約に委ね、将来 pre-commit hook (BOM reject + CRLF enforce) で fence 化する別 issue を予告。round 4 [Low-1] / round 3 [Low-1] の「forward-looking + 規約の物理 fence 化」方針と整合

#### Changed (PR #156 シニアレビュー round 1)

- **[High-1 + Low-2] `Read-GodotMinorFromProject` を `Assert-GodotMinorFromProject` に rename (#144 sweep の漏れ補完)**: 同 PR の #144 entry が「`Read-*` sweep を完結」と明言したが、ファイル読み出し + Fail 到達という同条件の `Read-GodotMinorFromProject` が漏れていた doc-vs-impl mismatch。**本 project の規約「Fail する関数は `Assert-*`」(PR #140 round 6 / round 9 で確立)** に照らすと、同関数も同じく `Assert-*` 対象 (PS approved verbs では `Read` は実は approved だが、本 project では「ファイル読み出し + Fail 到達は `Assert-*`」の internal convention で sweep)。Assert-LauncherVersion / Assert-ManagerVersion と命名統一、唯一の call site も追従。**sweep 完結確認**: `Grep '^function Read-' Release.ps1` で残存ゼロ verify 済 (`^function Read-` anchor は **本 project で定義した `Read-*` 関数** のみを対象、PS 標準 `Read-Host` 等の対話 cmdlet 呼び出しは `^function` で始まらないので除外される。将来 `Read-Host` 等の cmdlet 呼出し以外で新規 `Read-*` 関数を定義する場合は本規約と purpose 限定句 (AGENTS.md「Release Tooling 命名規約」) を再評価)
- **[High-2] Release.bat 行数 claim を 99 → 108 / 約 40% → 約 35% に 3 箇所同期**: CHANGELOG ×2 + SPEC v1.10.13 で「165 → 99 行、約 40% 削減」と embed していたが、実物は **108 行 (約 35% 削減)**。`wc -l` 確認済の数値と doc が乖離していた 5 者同期チェック相当の mismatch を解消
- **[High-3] CHANGELOG 内 `Release.ps1:95-160` 行番号 embed を anchor 表現に置換**: v0.1.12 round 6 Medium-1 で「行番号を CHANGELOG entry に embed する文化そのものが rot 源泉、関数名 / セクション名で anchor 化」と立てた規約を、本 PR entry が同 pattern で違反していた regression。さらに数値自体も誤り (catalog 実体は `# 採用ガイドライン` セクションで line 135〜)。Release.ps1 の **`# Native command 呼び出しの方針` catalog セクション** という関数 / セクション anchor 表現に置換、round 6 Medium-1 の規約準拠
- **[Medium-1] SPEC §3.7.9.5 の `[FAIL]` ASCII 表記文言を本文 mojibake 明示に修正**: 旧 SPEC「英文 prefix `[FAIL]` は ASCII で出して codepage 切替 skip 時も読める形に」が「メッセージ全体が読める」と暗黙誤読される余地があった。実体は「prefix のみ ASCII、本文の日本語 (`が exit code` / `で終了しました`) は cp932 console で mojibake する可能性あり」。「失敗の発生自体は判別可能 (本文は mojibake する可能性あり、`:runps` ラベル冒頭の WARN で予告済み)」と明示
- **[Medium-2] CHANGELOG 「policy 候補番号としての (c)」記号を削除し文章記述に**: 旧 CHANGELOG entry は「**case (c)** catalog 一般則 + per-site 固有理由」と書いていたが、これは「policy 選択肢 (a) catalog 参照型 / (b) catalog 廃止 / (c) catalog 一般則 + per-site 固有理由」の 3 番目の意味で `(c)` を使用したもの。一方、catalog 側 (Release.ps1 の `# 採用ガイドライン` セクション) には **PASS_THROUGH 内部 sub-label として `(a) 直 & 演算子版` / `(b) Invoke-ExternalProcess helper 経由` が実在**しており、**同じ `(a)/(b)/(c)` 記号が 2 つの異なる軸 (policy 候補番号 vs PASS_THROUGH sub-label) を表す命名衝突** が dangling reference の構造的根因だった。CHANGELOG 側を「**採用方針: catalog 一般則 + per-site 固有理由**」のような文章記述に書き換えて、catalog の `(a)/(b)` (PASS_THROUGH sub-label) との記号衝突を avoid (H-3 修正と同時に対応)
- **[Low-1] CHANGELOG Notes 「(本 PR でも一度発生)」 process trivia を forward-looking text に**: round 3 [Low-1] / round 4 [Low-1] で確立した「user-facing / forward-looking text に process trivia を入れない」原則を、本 PR Notes が同型違反していた (「本 PR でも一度発生」は当該 PR 開発過程の出来事 embed)。「Write/Edit ツールが encoding を破壊するケース (BOM 付与 / 改行 LF 化) があるため、編集後は `[System.IO.File]::ReadAllBytes($path)[0..2]` で先頭 3 byte を確認」のような forward-looking + 具体検証手順 text に。経緯は git blame で追える

#### Changed (refactor/release-tooling-cleanup、#142 / #143 / #144 / #146)

PR #140 シニアレビューで保留していた small refactor 4 件を 1 PR でまとめて消化、Release.ps1 / Release.bat の clean-up:

- **[#146] `Assert-WorkingTreeClean` の `$Context` 文字列マッチを `[switch]$PostSync` に置換** (PR #140 round 10 M3): 旧実装は `if ($Context -like '*sync 後*')` で特例 Fail message を切り替えていたが、call site 側の文字列 (`"manifest sync 後"`) を変えた瞬間に特例メッセージが silent に失われ汎用メッセージに落ちる脆弱性 (日本語 → 英語化、typo、文言調整等で簡単に壊れる)。`[switch]$PostSync` parameter で明示切り替え、`$Context` は phase identifier (Fail / Warn message に embed される user-facing diagnostic) として責務分離 (round 5 [Low-2] で「ログ表示用」表現を正確化済)。call site (`Assert-WorkingTreeClean -Context "manifest sync 後" -PostSync`) も更新
- **[#144] `Read-*` (LauncherVersion / ManagerVersion / ComponentVersions) → `Assert-*` rename** (PR #140 round 10 M1): 本 project の規約「**Fail する関数は `Assert-*`**」(PR #140 round 6 で `Test-Preflight → Assert-Preflight`、round 9 で `Test-ExpectedFiles → Assert-ExpectedFiles` で確立) に照らすと、ファイル読み出し + `Fail` 到達しうる本 3 関数は同規約の sweep 対象 (PS approved verbs では `Read` も approved だが、本 project では「Fail 到達しうる」を critical 軸として `Assert-*` に揃える internal convention)。`Assert-LauncherVersion` / `Assert-ManagerVersion` / `Assert-ComponentVersions` の 3 関数と全 call site を rename
- **[#142] `2>&1` trap catalog と per-site コメントの方針統一** (PR #140 round 9 M1): Release.ps1 の `# Native command 呼び出しの方針` catalog セクション (`SUPPRESS_BOTH` / `CAPTURE_DIAGNOSTIC` / `CAPTURE_STDOUT` / `CAPTURE_STDOUT_PASS_STDERR` / `PASS_THROUGH` / `STOP_TRAP`) と per-site コメントが「ラベル参照 + ほぼ同内容の詳細説明」を両方書く形に逆戻りしていた問題に対処。**catalog 一般則 + per-site 固有理由** 方針で統一、catalog 冒頭に per-site 書き方ガイドラインを明示 (「catalog 既述の一般則は per-site から削除」「per-site にはその call site でしか起きない silent danger / 特殊配慮のみ書く」「判定基準: catalog の説明と等価なら per-site から削除」)。実 per-site (`Assert-WorkingTreeClean` の `CAPTURE_STDOUT_PASS_STDERR` 引用) も「git 失敗時の silent pass 防止」の固有理由のみ残す形に短縮済 (#146 修正と同時)
- **[#143] Release.bat docstring の cmd.exe 経緯を SPECIFICATION.md §3.7.9 に分離** (PR #140 round 9 M3): Release.bat (165 行) の REM (~100 行) が BOM 失敗症状 / chcp フロー / Side effect 警告 / findstr validation 経緯 / top-level goto pattern 等を inline で全部抱えていた。SPECIFICATION.md に新節 **§3.7.9 「Release.bat の cmd.exe 互換性ノート」** を新設 (3.7.9.1 ファイル形式の制約 / 3.7.9.2 chcp 65001 切替 / 3.7.9.3 delayed expansion `!` 副作用 / 3.7.9.4 exit code dispatch を top-level goto label で行う理由 / 3.7.9.5 exit code 体系 / 3.7.9.6 codepage 復元のタイミング)。Release.bat 本体は「Usage + ASCII boundary 注記 + SPEC §3.7.9 参照」の最小構成に圧縮 (165 → **110 行**、約 33% 削減。#143 完成時は 108 行、その後 round 4 L-2 で ASCII boundary REM を 1 行 → 3 行に分割した結果 +2 行)。次に Release.bat を触る reader の読み解きコスト削減

#### Notes (Release.bat encoding 取扱い)

Release.bat の編集は **UTF-8 (no BOM) + CRLF** 厳守 (SPEC §3.7.9.1 参照)。`.gitattributes` の `*.bat eol=crlf` で改行は enforce 済、BOM は規約レベルで禁止。**encoding 破壊 (BOM 付与 / 改行 LF 化) を検知した場合の incident response 手順**: `[System.IO.File]::ReadAllBytes($path)[0..2]` で先頭 3 byte 確認 → `EF BB BF` であれば `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))` + 改行も `-replace "\r?\n", "\r\n"` で CRLF 統一の後処理を実施。通常 commit 時の verify は将来 pre-commit hook (BOM reject + CRLF enforce) で物理的 fence 化する予定 (別 issue 候補、本 PR scope 外、round 1 [High-2] / [Medium-2] で確立した「規約は fence で物理的に防ぐ」原則の incremental hardening)

#### 検証

通常 DryRun: Preflight → Bundle 参照リンク定義の検証 (skip + 2 行 warn) → コンポーネント version を読み取り (Assert-LauncherVersion / Assert-ManagerVersion 動作確認) → Build- 群 → ExpectedFiles 15/15 OK → DRY-RUN 完了。Release.bat parse エラー無し、`@echo off` 機能 OK (BOM 無し 110 行、round 4 L-2 後の最終値)。

---

### [Release Tooling v0.1.13] - 2026-05-14

#### Changed (PR #155 シニアレビュー round 1)

- **[Medium-1] 全ペア pre-release skip 時の「OK」誤表示を解消**: 旧実装は pre-release suffix を含む隣接ペアで `continue` skip 後にループ抜け、無条件で `Write-Ok "降順整列 OK"` を出していた。**1 度も実比較していなくても「OK」表示** になる silent danger。例: footer に `[Bundle v0.3.0-rc1]` / `[Bundle v0.2.0-rc1]` だけが並ぶ状態で「実比較 0 / OK」になる path。修正: `$comparedCount` / `$skippedCount` カウンタ導入、ループ後を 3 分岐:
  - **全 skip** (`comparedCount == 0 && skippedCount > 0`): `Write-Warn "全 N ペアが pre-release suffix のため skip (実比較なし、presence のみ PASS)"`
  - **一部 skip**: `[OK] Bundle 行群の降順整列 OK (N 件中 M ペア比較、K ペア pre-release skip)`
  - **全実比較**: `[OK] Bundle 行群の降順整列 OK (N 件)`
- **[Low-1] 「SemVer 比較」表記を「`[version]` (.NET System.Version, numeric)」に訂正**: AGENTS.md / CHANGELOG / Release.ps1 関数 header コメントで「SemVer 降順」と表現していたが、実装は `[version]` cast (= .NET `System.Version` の 4-part numeric `major.minor.build.revision`) で SemVer pre-release semantics (`1.0.0-rc1 < 1.0.0`) 未サポート。Bundle が 3-part numeric の限り SemVer 順序と一致するが、「比較器そのものは SemVer 準拠ではない」事実を明文化。「現状は `[version]` numeric 比較、pre-release semantics 未対応 (= pre-release suffix 検出時は順序 check skip)」と各所注記
- **[Low-2] 等値 (重複 link def) と「下が大きい」(ordering 違反) の message を分岐**: 旧 message は `下にあるが version が大きい / 等しい` の OR 表記で両 case を 1 メッセージに統合していたが、user の修正手段が違う (等値 = 重複 link def を片方削除 / 大きい = ordering 違反で並び替え)。`if ($upperVer -eq $lowerVer) { 重複 } elseif ($upperVer -lt $lowerVer) { ordering 違反 }` で分岐、Fail message と修正案内も case 別に
- **[Low-3] fixture test を 3 件降順 / 順序逆転 / 重複 / 1 件のみ の 4 case に拡張**: 旧 case A (現状 v0.2.0 / v0.1.0 降順) は **新ロジック追加前から PASS していた経路** で、新規 ordering 比較 ロジック (`[version]` cast、`-le` 判定) の retention check になっていなかった。case A' (3 件降順、2 ペア実比較) を追加、case D (重複 link def、Low-2 の新 branch verify) も追加して比較ロジック全 branch を独立 verify
- **[Low-4] 違反位置表示を 1-indexed に統一**: 旧 `位置 0 / 位置 1` / `[0] [Bundle v...]` は 0-indexed で、Release.ps1 内他 user-facing 表示 (`[Step N/4]` 系) の 1-indexed と乖離。release 直前の急ぎ修正 context で「位置 5 は上から 5 つ目? 6 つ目?」と一瞬迷う path を排除、`位置 $($i + 1)` / `[$($j + 1)]` に統一 (内部 loop index は 0-indexed のまま、表示時のみ +1)

**手動 fixture test 4 case PASS (round 1)** (Release.ps1 冒頭の auto-promote 一時 comment out):

- **A'** (3 件降順 `v0.3.0 / v0.2.0 / v0.1.0`): `[OK] Bundle v0.2.0 の参照リンク定義 OK (presence)` + `[OK] Bundle 行群の降順整列 OK (3 件)` → 2 ペア実比較 PASS
- **B** (順序逆転 `v0.1.0 / v0.2.0`): presence OK → ordering 違反で「位置 1 (上) / 位置 2 (下) ← 下にあるが version が大きい (ordering 違反)」 + 全 Bundle 行リスト (1-indexed) + 違反箇所マーカー → Fail
- **C** (Bundle 1 件のみ): presence OK + ordering check 自体 skip
- **D** (重複 `v0.2.0` × 2): presence OK → 「位置 1 と位置 2: 両方とも [Bundle v0.2.0]:」+ 「修正: どちらか片方の link def を削除してください」 + 重複箇所マーカー → Fail (Low-2 新 branch 動作確認)

#### Added (feature/changelog-bundle-ordering、#154)

- **`Assert-ChangelogLinkDefs` に Bundle 行群の SemVer 降順整列 enforce を追加** (presence check に追加で ordering check): PR #153 で導入した fence は「footer block 内に `[Bundle vX.Y.Z]:` 行が **存在するか**」だけ verify する presence check で、AGENTS.md「**追加位置: 既存 `[Bundle vX.Y.Z]:` 行群の先頭 (降順を維持)**」規定は convention 任せだった。例えば `[Bundle v0.1.0]` の下に `[Bundle v0.3.0]` を書いても通過する状態で、CHANGELOG の Bundle 行群が時系列ぐちゃぐちゃになり human reader が「最新リリースがどれか」を直感的に判断できなくなる運用劣化リスクと、規約と fence の non-symmetric (doc-vs-impl mismatch) があった。`#154` で別 issue 化していた incremental hardening を実装。
  - **実装**: footer block 内の `^[Bundle vX.Y.Z]:` 独立行を順序通り抽出 → 隣接ペアで SemVer 比較 (`[version]` cast) → 降順 (上 > 下) でなければ Fail
  - **pre-release suffix の扱い**: `0.3.0-rc1` 等の suffix 付き version は `[version]` cast 不可のため SemVer 比較ロジック範囲外、warning で順序 check を skip + presence check は維持 (現状 Bundle で pre-release 運用なし、将来運用拡張時に SemVer 比較ロジック拡張で対応)
  - **Bundle 1 件以下**: 順序自明のため ordering check 自体不要 → presence check 後そのまま return
  - **Fail message**: 違反箇所 (位置 i 上 / 位置 i+1 下) + 全 Bundle 行の並び順 + 違反箇所マーカー (`← 違反箇所`) を表示、修正しやすい形に
  - **AGENTS.md `Release and Versioning` の強制 fence 記述を `(1) presence + (2) ordering` の両方 enforce 表記に更新**: 規約と fence の対称性を回復
  - **手動 fixture test 3 case PASS**:
    - A (現状 v0.2.0 / v0.1.0 降順): `[OK] Bundle v0.2.0 の参照リンク定義 OK (presence)` + `[OK] Bundle 行群の降順整列 OK (2 件)` → PASS
    - B (順序逆転、v0.1.0 が上 v0.2.0 が下): presence は OK、ordering で「位置 0 (上): v0.1.0 / 位置 1 (下): v0.2.0 ← 下にあるが version が大きい」と違反箇所表示 + 全 Bundle 行リスト + 違反箇所マーカー表示 → Fail
    - C (Bundle 1 件のみ): presence OK + ordering check 自体 skip (順序自明) → PASS

---

### [Release Tooling v0.1.12] - 2026-05-13

#### Added (fix/changelog-link-sync、PR #153)

- **CHANGELOG 末尾 Bundle 参照リンク定義の運用ルール + 強制 fence を追加**: PR #152 マージ後に発見した「CHANGELOG 末尾の Keep a Changelog 参照リンク定義が 2026-03 (Launcher v0.5.7 / Manager v0.7.6) から完全に止まっており、Bundle 移行後 (2026-05-11 以降) の `[Bundle v0.1.0]` / `[Bundle v0.2.0]` が dangling reference 状態」の問題に対処。
  - **CHANGELOG.md**: 末尾参照リンクブロックに `[Bundle v0.2.0]` / `[Bundle v0.1.0]` の link 定義追加 + `<!-- ... -->` コメントで Bundle 移行後の規約 (個別 component リンクは追加しない、Bundle release が SoT) を明文化
  - **AGENTS.md** `Release and Versioning` セクション: 「Bundle entry 追加時に CHANGELOG 末尾の参照リンク定義も同時追加」ルールを明文化 + Bundle 移行後の個別 component 見出しが Markdown 上 dangling reference になることを許容理由付きで規定 (SPEC §3.7.7「Bundle release が SoT」規約整合)
  - **Release.ps1**: `Assert-ChangelogLinkDefs` 関数を追加 (Phase 0.5 = Preflight 直後、round 1 Medium-1 で位置調整)、main flow に組み込み。release 実行前に該当 Bundle version の参照リンク定義が末尾にあるか verify し、無ければ `Fail` で停止する fence。自動 mutation (script が CHANGELOG 末尾を書き換える) は採らず、規約遵守を物理的に強制する形 (人間 / Claude いずれのミスも release.bat 実行直後 = build 前に物理的に検知される、fail-fast)
- **DRY-RUN 検証**: 本 PR 内で「リンク定義が存在する case」(PASS) を確認、別 fixture で「未追加 case」を `Assert-ChangelogLinkDefs` が `Fail` するか動作確認 (= fence 機能の実証)

#### Changed (PR #153 Codex round 5 後追い + シニアレビュー round 6)

- **[Critical-1] sentinel 設計が同 PR 内で自己破綻していた path を二重防御で根治**: round 5 で導入した「明示的 sentinel `footer-link-defs-begin` を埋め込み `IndexOf` で位置取得」が、**同じ round 5 commit で破壊**されていた。round 5 entry 本文中に sentinel 文字列 literal を書いた瞬間 (説明のため引用) CHANGELOG.md 内に sentinel が 2 箇所出現 (round 5 entry body + 末尾 HTML comment) → `IndexOf` が body 内の最初の出現を拾って footer block が CHANGELOG ほぼ全体 (~99%) に再拡大する **自爆** が発生。round 3 Codex P2 で塞いだはずの false-positive path (本文中の例示 link def を拾う) が復活する状態。round 6 で二重防御に再設計:
  - **[1] sentinel を unique 文字列に変更**: `footer-link-defs-begin` → `GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1` (ALL CAPS + hyphen + V1 suffix、human writing で偶発出現しない pattern)。CHANGELOG 末尾 HTML comment 内に **単独行** で配置 (`<!-- GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1 -->`)、本物の sentinel として識別可能
  - **[2] `IndexOf` → `LastIndexOf` に変更**: 万一 body 中で sentinel が引用された場合でも末尾の本物の sentinel を選ぶ semantics に。CHANGELOG 構造上「上 = 新エントリ、末尾 = HTML comment + link def」で本物 sentinel は常にファイル中最後の出現になる前提
  - **動作確認** (fixture test 3 case PASS、auto-promote 一時 off):
    - A (sentinel + link def 存在): `[OK] Bundle v0.2.0 の参照リンク定義 OK` → PASS path 動作
    - B (link def 削除): `footer block に ... 見つかりません` + 「sentinel 'GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1' 以降の独立行のみ認識」hint 表示 → Fail
    - C (sentinel 削除): `sentinel 'GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1' が見つかりません` → Fail (sentinel 必須化)
- **[Medium-1] CHANGELOG 内の行番号参照を関数名 / セクション名に anchor 化**: round 4 Low-2 で「行番号 drift を現状値に同期」したと宣言した直後の round 5 commit で再 drift していた (round 5 で sentinel handling block 追加で `$expectedUrl` 行番号がさらに変動)。「行番号を CHANGELOG entry に embed する文化そのもの」が rot 源泉と判明。修正: 既存 entry 内の line 番号参照 (`Release.ps1:1022` / `現 line 1029` / `現 line 1093` 等) を **PR 内で rename しない anchor** (関数名 `Assert-ChangelogLinkDefs` / セクション名 `Phase 0.5 header` / Release.ps1 冒頭の `auto-promote 行` 等) に置換。round 4 Low-2 の応急処置 (drift 追従) を round 6 で根治 (embed 廃止)
- **[Medium-2] PR description Test plan の fixture C claim と現 commit 状態の矛盾を解消**: Critical-1 修正後 (sentinel unique + LastIndexOf) に fixture B / C を再 verify、PR description の Test plan + 本 entry の動作確認 record を round 6 実機 verify 結果に同期
- **[Low-1] Fail message hint を実体に揃え**: 旧 Fail message は「CHANGELOG 末尾 HTML comment marker 以降の独立行のみ認識」と謳っていたが Critical-1 の通り実体は 99% の領域を match していた user-facing 乖離。Critical-1 修正と同時に hint 文言を「CHANGELOG 末尾 sentinel '$FooterSentinel' 以降の独立行のみ認識」に更新、実装と一致
- **[Low-2] `$changelogPath` local 変数を削除して module-level `$ChangelogPath` 定数 (script 冒頭 paths section、SoT) を使用**: 既存 SoT を活用、命名衝突 / 1 行重複の保守ノイズを排除
- **[Low-3] UTF-8 read 統一の scope を CHANGELOG entry 内に明文化**: round 1 Low-3 で `Assert-ChangelogLinkDefs` 内を `Get-Content -Raw` → `ReadAllText(UTF8)` 統一したが、本 PR scope 外の他箇所 (`Read-LauncherVersion` の version.gd / AssemblyInfo.cs 読み取り等) は `Get-Content -Raw` のまま。「本 PR は CHANGELOG.md 読み取りのみ統一、他は ASCII 確実なので実害なし、script 全体統一は別 issue 化候補」を round 1 Low-3 entry に追記

#### Changed (PR #153 Codex round 4 後追い + シニアレビュー round 5)

- **[Codex P2] footer 検出を「明示的 sentinel marker」ベースに切替**: round 3 で導入した `LastIndexOf('-->')` は「ファイル中で最後の HTML comment 閉じ」を footer marker とみなす pattern だったが、将来 link def 群の **下** に別の HTML comment (例: `<!-- markdownlint-disable -->` 等の lint directive) が追加された瞬間に footer block が link def 群を含まない範囲に切り出されて normal publish で **false "同期忘れ" Fail** が起きる脆弱性があった。修正: CHANGELOG 末尾 HTML comment 内に明示的 sentinel 文字列 `footer-link-defs-begin` を埋め込み、Release.ps1 は `IndexOf(sentinel)` で位置を取得する形に切替。link def の後ろにいくつ HTML comment が追加されても sentinel は 1 つで識別される構造に。sentinel 変更時は CHANGELOG.md / Release.ps1 の `$FooterSentinel` 定数を同期更新する規約も明文化
- **[Medium-1] round 4 で新規追加した Write-Warn message の backtick escape 再発を解消 (round 3 Low-2 + round 4 Low-1 の自己矛盾)**: round 4 で他 Fail message から backtick を削除する作業 (Low-1) を行ったが、同 commit で新規追加した Write-Warn (`` "  → 本番 publish (flag なし `Release.bat -NoPause -Force`) では..." ``) には backtick を含めてしまっていた。round 3 Low-2 と全く同型の指摘 (PowerShell double-quoted string で backtick は escape として消費される) を round 4 で半分にしか適用していない自己矛盾。修正: backtick を削除して `Release.bat -NoPause -Force` の裸 string に
- **[Low-1] Fail message 末尾の `(round 3 Codex P2)` process trivia を削除**: `Fail "CHANGELOG.md 末尾の HTML comment marker (<!-- ... -->) が見つかりません。footer block 開始の sentinel が必要 (round 3 Codex P2)。"` の末尾「(round 3 Codex P2)」は process trivia (review round 番号 + bot 名) で Fail message 本文情報には寄与しない。round 3 Low-1 で AGENTS.md / Release.ps1 header コメントから PR 識別子を削除した critique (「forward-looking な箇所に履歴情報を埋め込む」「2 年後の読者にとって意味を失う」) を user-facing Fail message にも適用。round 3 / Codex 経緯は git blame / CHANGELOG で追える
- **[Low-2] PR description Test plan を round 1〜5 + Codex round 1〜4 反映に同期**: 初版から「[x] round 1 / round 2 のシニアレビュー対応 (High 1 + Medium 3 + Low 7)」のままで round 3 / 4 / 5 + Codex 反映が抜けていた doc-vs-impl mismatch (5 者同期チェックの対象 = PR body)。round 5 までの items 総数 + 各 round の status を反映
- **[Low-3] v0.1.12 entry 内の round label 命名を統一**: round 1 (`[High-1]` / `[Medium-1 + Low-2]` / `[Low-1]` 等のフルスペル) と round 3 (フルスペル) と round 4 (`[Low]` 番号なし) と round 2 (`[M2]` / `[L1]` 等の短縮) で 4 round の label 形式がバラバラだった。「4 round の history を 1 entry に集約した本 PR の整理機会」として全体を `[High-N]` / `[Medium-N]` / `[Low-N]` のフルスペル + 番号ありに統一 (番号体系は round ごとに reset、Codex 由来は `[Codex P2]` で識別性維持)。具体的には round 2 の `[M2]` → `[Medium-2]`、`[L1]` → `[Low-1]` 等、round 4 の `[Low]` × 3 → `[Low-1]` / `[Low-2]` / `[Low-3]` に書き換え。round 1 / round 3 は既にフルスペル形式なので変更なし

#### Changed (PR #153 シニアレビュー round 4)

- **[Low-1] Release.ps1 内 Fail message の backtick escape 漏れを解消 (round 3 Low-2 の取りこぼし)**: round 3 Low-2 で Fail message から backtick を削除する作業を行ったが、本 PR で新規追加した別の Fail message (`Fail "CHANGELOG.md 末尾の HTML comment marker (\`<!-- ... -->\`) が見つかりません..."`) に backtick が残置していた。同 round 内で全体に展開する作業漏れを補完
- **[Low-2] CHANGELOG.md 内の Release.ps1 行番号参照を現状値に同期**: round 1 / 2 / 3 の commit を重ねるうちに Release.ps1 内の line 番号が drift していた (旧 commit 時点では Phase 0.5 header / `$expectedUrl` hardcode 箇所等を指す行番号が複数 entry に embed されていた)。CHANGELOG entry 内の line 番号参照を実態に追従する応急処置を実施。**根本対応は round 6 Medium-1 で実施 (行番号 embed 文化そのものを廃止、関数名 / セクション名で anchor 化、本 entry 含む)**
- **[Low-3] SkipUpload skip 時の Warn message にリマインダー 1 行追加**: round 2 M2 で `-SkipUpload` (DryRun/Offline 経由 auto-promote 含む) 時の skip + warn 挙動を導入したが、「**本番 publish (flag なし `Release.bat -NoPause -Force`) では本検証が enforce される、Bundle entry 追加と同時に link def も追加してください**」というリマインダーが無く、DryRun を繰り返している開発者が初回 publish 時に「DryRun では通ってたのに publish で Fail」と混乱する path があった。Warn を 2 行構成にして 2 行目で本番挙動を予告
- **[scope 外 / 別 issue 登録]** ordering check (Bundle 行群の降順 enforce、現状の fence は presence のみ check で順序は AGENTS.md convention 任せ) は別 issue として記録、本 PR では実装しない (incremental hardening、本 PR の core は presence check 導入)

#### Changed (PR #153 Codex round 2 後追い + シニアレビュー round 3)

- **[Codex P2] Bundle link 検証を footer block 限定 match に補強**: round 1 Low-1 で line anchor `(?m)^...\s*$` を導入したが、ファイル全体に対して match していたため、release notes 本文の fenced code block 内に同形式の独立行 (例:「link def の追加例」を release notes で説明) が紛れた場合に footer 不在でも check 緑で素通りする path があった (= dangling Bundle heading link で release)。修正: CHANGELOG 末尾の **最後の HTML comment marker** (`<!-- ... -->`) を footer block の開始 sentinel とみなし、`$changelogContent.LastIndexOf('-->')` 以降の部分文字列だけを match 対象に。footer marker 不在時は明示 Fail で停止 (sentinel 必須化)
- **[Medium-1] CHANGELOG v0.1.12 entry の round 1 heading 欠落を解消**: round 2 commit で `#### Changed (PR #153 シニアレビュー round 1)` heading を入れ忘れ、round 1 items (High-1 / Medium-1+Low-2 / Low-1 / Low-3 / Low-4) が round 2 heading 配下に紛れる integrity 問題があった。空行 3 行が heading 挿入忘れの痕跡。round 1 heading を空行位置に挿入、各 round の items を heading 単位で分離
- **[Medium-2 案 C] fence Fail path を merge 前に手動 fixture でテスト実施**: `-SkipUpload` gate (round 2 M2) 導入後、`-DryRun` / `-Offline` の auto-promote で fence の Fail path が dry-run で検証不能になり「初発火 = 本番 publish」問題があった。merge 前に手動 fixture で fence の Fail path 動作を 1 度実機 verify:
  - **fixture A** (link def 存在 + Release.ps1 冒頭の DryRun → SkipUpload auto-promote 行を一時 comment out + DryRun): `[OK] Bundle v0.2.0 の参照リンク定義 OK` → fence PASS path で build まで進む **動作確認 OK**
  - **fixture B** (link def 削除 + auto-promote 一時 comment out + DryRun): `CHANGELOG.md 末尾 footer block に Bundle v0.2.0 の参照リンク定義が見つかりません` + `追加位置: 既存 [Bundle vX.Y.Z]: 行群の先頭 (降順を維持、CHANGELOG 末尾 HTML comment ブロック直下)` 表示 → **1.7 秒で Fail で停止** (fail-fast 維持) **動作確認 OK**
  - 案 A (検証専用 flag 新設) / 案 B (verify-only mode) と比較して案 C 採用、scope creep ゼロで merge 前確度を担保。Phase 4 完成時の本番 Bundle release では本検証済の fence ロジックが初発火する想定
- **[Low-1] Release.ps1 Phase 0.5 header コメント (`# Phase 0.5: CHANGELOG 末尾 Bundle 参照リンク定義の検証`) から `(fix/changelog-link-sync)` 削除**: round 2 L1 で AGENTS.md から PR 識別子を削除した理由 (「forward-looking な規約に履歴情報を埋め込む」「2 年後の読者にとって PR 名は意味を失う」) は Release.ps1 関数 header にも同じく適用される。同 PR の同 critique を半分にしか適用していなかった自己矛盾を解消。経緯は git blame / CHANGELOG で追える
- **[Low-2] Fail message の backtick escape を削除**: `Write-Host "... 既存 `[Bundle vX.Y.Z]:` 行群..."` の backtick は PowerShell double-quoted string で escape 文字として消費 (`` `[ `` → `[`、`` `<space> `` → space) → console 出力で意図した code-formatting 表記が消えていた。backtick 削除して直接 `既存 [Bundle vX.Y.Z]: 行群の先頭 (...)` に簡略化 (現在の出力と等価で保守者の混乱なし)
- **[Low-3] GitHub repo URL を `$GitHubRepoSlug` 定数に集約**: round 1 で `https://github.com/ken1208git/TonePrism/releases/tag/v$Version` を Release.ps1 内に hardcode していた (本 script 内初登場、他箇所は `gh` CLI の repo 自動検出に依拠) ため、fork / repo rename / org transfer 時に検証ロジックだけ古い URL を見るリスクがあった。script 冒頭の paths section に `$GitHubRepoSlug = 'ken1208git/TonePrism'` を定義 (SoT)、`Assert-ChangelogLinkDefs` 内で参照
- **[Low-4] AGENTS.md の追加 bullet を sub-bullet に分割**: round 2 L1 で複数主張 (規約 / Markdown 形式 / 追加位置 / fence の存在 / `-SkipUpload` 時の挙動 / SPEC §3.7.7 整合) を 1 文に統合した結果、bullet が ~280 文字に膨らみ release 直前の急ぎ lookup で各情報を素早く拾えない問題があった。同 AGENTS.md 内他 bullet (`Major / Minor / Patch` 列挙) に揃えて sub-bullet 分割 (Markdown 形式 / 追加位置 / 強制 fence / SkipUpload 時の挙動 / Bundle 移行前後の規約) で情報量変えず lookup 性改善

#### Changed (PR #153 シニアレビュー round 2)

- **[Medium-2] `Assert-ChangelogLinkDefs` に `-SkipUpload` gate を追加して既存 Preflight 契約と整合化**: 初版は `-SkipUpload` を gate せず無条件 Fail だったため、既存 `Assert-Preflight` の CHANGELOG `### [Bundle v$Version]` セクション検証 (`if (-not $SkipUpload) {...Fail} else {Write-Warn}` pattern) と非対称だった。SkipUpload は publish しない = 参照リンク URL の resolution 自体が無意味で、staging テスト (`Release.ps1 -SkipUpload -DryRun`) で link def 未追加だけで停止される path があった。修正: `Assert-ChangelogLinkDefs` 冒頭で `if ($SkipUpload) { Write-Warn ...; return }` を入れて既存 Preflight pattern と揃え、AGENTS.md「release 実行時に verify」文言とも整合化。`-DryRun` / `-Offline` は Release.ps1 冒頭の auto-promote 行で `$SkipUpload = $true` に **auto-promote** される (Codex P2 #137 経緯) ため、DryRun 経由でも skip + warn path に流れる = 既存 Preflight と完全同期。実 fence の動作確認は本番 publish 経路 (flag なし `Release.bat -NoPause -Force`) で初発火を verify する
- **[Low-1] AGENTS.md rule から PR 識別子 (`fix/changelog-link-sync PR で導入`) を削除**: rule 末尾の PR 識別子は forward-looking な規約に履歴情報を埋め込んでいて、CHANGELOG 側 (v0.1.12 Added) に既に詳細経緯あり SoT 重複 + 時間と共に rot する (2 年後の読者にとって PR 名は意味を失う)。同 AGENTS.md 内他 rule は pure rule 形式で PR 識別子なし。「`fix/changelog-link-sync` PR で導入、」を削除し、SPEC §3.7.7 への横参照は残置。あわせて「追加位置は既存 `[Bundle vX.Y.Z]:` 行群の先頭 (降順を維持)」と「`-SkipUpload` 時のみ skip + warn」を 1 文に統合
- **[Low-2] `Write-Step` の位置メタ括弧書きを削除、convention に揃え**: 初版 `Write-Step "CHANGELOG 末尾 Bundle 参照リンク定義の検証 (Preflight 直後 / build 前)"` は近傍の他 `Write-Step` (`"Preflight: 環境とパラメータを検証"` / `"GitHub Releases タグ衝突チェック"`) と異なり位置メタを混入していた。位置情報は header コメント (Release.ps1 Phase 0.5 セクション) で既に伝達済なので Step 表示は action のみに短縮
- **[Low-3] Fail message + CHANGELOG HTML comment に「追加位置 = 既存 Bundle 行の先頭 (降順維持)」hint を追加**: 初版 Fail message は「末尾の参照リンク定義ブロックに追加」とだけ案内、CHANGELOG.md 末尾の HTML comment + 既存 link def 群の中で「どこに追加するか」が user message から読み取れなかった。Release.ps1 Fail 出力に「追加位置: 既存 `[Bundle vX.Y.Z]:` 行群の先頭 (降順を維持、CHANGELOG 末尾 HTML comment ブロック直下)」を追記 + CHANGELOG.md 末尾 HTML comment にも「**追加位置は既存 `[Bundle vX.Y.Z]:` 行群の先頭 (降順を維持、本コメント直下)** とする (= 新しいほど上)」を明示

#### Changed (PR #153 シニアレビュー round 1)

- **[High-1] CHANGELOG 構造修正: v0.1.11 / v0.1.12 entry の分離**: 初版 commit (`7bb0102`) では既存 `### [Release Tooling v0.1.11]` 見出しを `v0.1.12` に **書き換えてしまい**、配下にあった PR #152 round 8 の Fixed 群 (UseShellExecute=false + WaitForExit 2000ms / Codex P2-1, P2-2 / Medium / Low の重大発見根治) が PR #153 = v0.1.12 の作業として表示される状態になっていた。AGENTS.md「1 PR 内の version bump は原則 1 回のみ」は PR をまたいで version 番号を付け替えるのは想定外 (= PR #152 = v0.1.11、本 PR = v0.1.12 が正しい対応関係)。修正: 旧 v0.1.11 entry の見出し + 配下 Fixed 群を復元、新 v0.1.12 entry を v0.1.11 の **上** に並べる形に再構成。これで「v0.1.11 と v0.1.12 の差分は何だったか?」を CHANGELOG だけで遡れる状態に戻る
- **[Medium-1 + Low-2] Assert の発火タイミングを build 前 (Preflight 直後) に移動 + AGENTS.md 文言を実装と整合化**: 初版は `Assert-ChangelogLinkDefs` を `Assert-ExpectedFiles` の **後** (= Build-Launcher / Build-Manager / Build-Updater + Copy-Templates の後) に置いていた。link def 忘れを「数分のフル build を捨ててから」検出する fail-fast 違反 + AGENTS.md「Release.bat 実行直後の Assert で物理的に防ぐ」記述と実装の document-vs-impl mismatch があった。修正: `Assert-Preflight` の直後 (build 開始前) に移動、link def 忘れを **数秒で検出 → 修正 → 再 Release.bat** のサイクルに整える。AGENTS.md の「実行直後」記述も実装と一致
- **[Low-1] Assert を substring match → 正規表現 anchor 化**: 初版の `$changelogContent.IndexOf($expectedDef)` 単純 substring match は、CHANGELOG 本文中のコードブロック / 引用に同形式文字列が紛れた場合 false-positive で PASS する path があった。Markdown 仕様上 reference link 定義はどこにあっても resolve されるので rendering 上は問題ないが、運用規約「末尾参照ブロックに集約」と乖離する。`(?m)^\[Bundle v...\]: <URL>\s*$` の行 anchor で末尾ブロック内の行のみ match
- **[Low-3] `Get-Content -Raw` → `[System.IO.File]::ReadAllText(..., UTF8)` に統一**: 初版の `Get-Content -Raw` は PowerShell 5.1 で BOM 無し UTF-8 ファイルを Windows ANSI (日本語環境では CP932) として読む既知挙動があり、Release.ps1 冒頭の Bundle version 抽出 (`$_changelogContent`) と read 方式が不整合だった。本件 match 対象は ASCII で実害ゼロだが、保守ノイズ + 将来 defensive のため `Assert-ChangelogLinkDefs` 内で統一。**scope**: 本 PR は CHANGELOG.md 読み取りのみ統一、Release.ps1 内の他 `Get-Content -Raw` (`Read-LauncherVersion` 等の version.gd / AssemblyInfo.cs 読み取り) は ASCII 確実なので実害なし、別 issue 化候補 (round 6 Low-3 で scope 明文化)
- **[Low-4] `#### Added` subsection 末尾の余分な空行 2 行削除**: 他 subsection 間は単一空行 convention に揃え

### [Release Tooling v0.1.11] - 2026-05-13

#### Fixed (PR #152 Codex bot round 7 後追い + シニアレビュー round 8 + 重大発見への対応)

- **[round 8 重大発見 → C 案で根治] early-crash check の race condition を構造的に解消**: round 7 で「シナリオ A (early-crash) PASS」と記録した手動テストを round 8 で再実行したところ、**同一コード・同一テストシナリオで PASS しない race condition** を発見。原因は 2 層:
  - **[1] `UseShellExecute=true`**: Windows shell 経由 spawn のため Process オブジェクトと実 process の handle 紐付けが間接的、`WaitForExit` / `HasExited` の応答が遅延する path がある (.NET Framework 4.8 公式ドキュメントでも UseShellExecute=true は handle 制約あり明記)
  - **[2] 500ms threshold**: csc cold start + 大きな .NET exe で実 race 範囲内 (round 7 では偶然 PASS、round 8 では検出失敗)
  - 修正 (C 案): **(B) `Process.Start` の `UseShellExecute` を `true` → `false` に切替** で handle 紐付けを確実化 + **(A) `WaitForExit(500)` → `WaitForExit(2000)` に拡大** で cold start race の確率的余裕を確保。両方の修正で「構造的 + 確率的」両面で防御。
  - 副作用: Updater 完了が ~1.5 秒遅くなる (許容範囲)。Manager.exe は GUI app (`Application.Run` loop) なので stdout/stderr inherit でも実害なし、`.exe` 直接 spawn で問題なし。
  - SPEC §3.7.4 の round 4 M-5「UseShellExecute=true 経由の UAC prompt」記述 + round 7 Low-4「500ms 前提」記述を C 案に合わせて更新済 (5 者同期維持)。
  - **手動テスト 3 シナリオ全 PASS 再確認**: A (early-crash、ExitCode=99 検出 → rollback → 旧 Manager 復元、test marker dummy が bit-perfect 保持) / B (restart-exe 不在、Step 2 後 NG → rollback → 旧 Manager 復元) / E (PID 再利用、caller-pid=自 PowerShell PID で `"PID=N は別プロセス 'powershell' (PID 再利用と判定)、Manager 既終了扱い"` を確認)

- **[Codex P2-1] PID-only モードで「同名 exe 別 install / session」の PID 再利用検知が破綻していた silent danger を解消**: round 3 H1 で `ProcessName == "GCTonePrism_Manager"` 検証を入れたが、これでは「**同じ exe 名で起動した別 install / 別 session の Manager**」(例: D:\Install_A\Manager と E:\Install_B\Manager が同時稼働) による PID 再利用を区別できなかった。Phase 4 で同 PC 複数 install の運用が起きた場合に `--force-kill` 指定で別 install を kill する path が残っていた。修正: `GetTargetProcesses` に `expectedExePath` 引数を追加 (`WaitForManagerExit` signature 拡張、Program.cs から `args.RestartExe` を渡す)、`Process.MainModule.FileName` を取得して期待 path と比較。不一致なら「別 install / session」とみなして空配列扱い (= 待機 skip 経路、`Win32Exception` / `InvalidOperationException` も同経路で安全側 default に倒す)
- **[Codex P2-2] `RollbackFromBak` の `bakExists == false` branch が silent false-success を返していた**: round 7 までは `bakExists == false` で target 削除して return without throwing していたが、Program.cs の caller (`RollbackAndReturn6` / restart-exe 検証失敗時の RollbackFromBak) は「正常 return = 旧 Manager 復元成功」と解釈して exit 6 を返す。実態は「target も .bak も両方無い致命的状態」で false positive。修正: `InvalidOperationException` を throw → caller の既存 `catch (InvalidOperationException)` 経路で **exit 5 (rollback も失敗した致命的状態)** に倒す。target 削除は best-effort で先に試みる (新 Manager の半端コピーは起動に使えないゴミ、消しておく方が clean)

#### Changed (PR #152 シニアレビュー round 8)

- **[Medium-1] round 7 entry の `OLD_MANAGER_PLACEHOLDER` literal 表現を一般化して credibility 問題を解消**: round 7 シナリオ A / B の PASS 記述に test 用 placeholder 文字列がそのまま残っていて「テスト identifier 忘れ」「本当に test 走ったのか?」と読まれる credibility 問題があった。実態は testbed で `Set-Content` で test marker 文字列を中身に持つ dummy ファイルを置いた、というシンプルな手順。round 7 entry の表現を「test marker 文字列を仕込んだ dummy ファイルが bit-perfect 復元」に書き換え、本 round 8 entry のテスト結果記述も同 pattern で統一
- **[Medium-2] CliArgs.cs:106 の stale 行番号 `Program.cs:77` 削除 (round 7 Low-1 の漏れ補完)**: round 7 Low-1 で FileReplacer.cs:63 の `Program.cs:64` 参照は削除したが、同型の stale 参照が CliArgs.cs:106 に残っていた抜けを解消。round 6 で Main の `catch (Exception)` 追加により行番号が rot していた。コメント引用 (`Program.cs Main の catch (Exception)`) に置換
- **[Low-1] `ProcessWaiter` の force-kill `continue` で `iter++` が skip される silent issue を解消**: force-kill `Thread.Sleep(1000); continue;` で while ループ底の `iter++` を skip するため、`iter == 0` (初回ログ) / `iter % LogEveryNIter == 0` (継続ログ) の判定が誤発火して同じ「N 件検出」log が複数回出る path があった (実害なし、ログノイズのみ、round 5 M-2 / Low-2 のログ表記精度との整合性低下)。`continue` 前に明示 `iter++;` 追加
- **[Low-2] SPEC §3.7.4 exit 6 説明の表記揺れ解消**: `restart-exe が target 配下に不在 等` という曖昧表現を `restart-exe (target 配下を指す path) のファイルが staging 欠落で存在しない 等` に修正。「target 配下でない path 指定」は parse-stage で exit 2 として reject される (round 4 M-3) ので exit 6 の領域ではない点を明確化、他 4 者の `restart-exe 不在` 表現と意味的に揃え (5 者同期維持)
- **[Low-3] `ProcessWaiter` docstring の「Manager は caller」表現を「parent process」に明示化**: 「caller」は通常「この関数を呼ぶ側 = Updater 自身」と読める ambiguity があったため、`callerPid` パラメータ名と相まって瞬間的に誤読される path を排除。round 6 Codex P2 / Medium-4 等で一貫使用してきた「Manager UI 側 = Updater を spawn した親プロセス」と整合
- **[Medium-3 + Medium-4] round 7 で確立した「軽量 2 シナリオ手動テスト」「PR body の SPEC 3 bump 明示的逸脱注記」は round 8 でも維持** (新規対応なし、round 7 で完了)

#### Fixed (PR #152 Codex bot round 6 後追い + シニアレビュー round 7)

- **[Codex P2] parse 段階の stderr 出力が UTF-8 で出ていない自己矛盾を解消**: `Console.OutputEncoding = UTF-8` を `Logger.Initialize` 内でしか設定していなかったため、parse 失敗 path (exit 2 / parse-stage exit 1) は Logger 初期化前に走り stderr が OS default codepage (日本語 Windows = CP932) で出ていた。round 6 Medium-4 で SPEC §3.7.4 に「Phase 4 Manager UI は UTF-8 で stderr capture する規約」と明文化したのに、その capture 対象の stderr 自体が UTF-8 で出ていない自己矛盾 → Manager UI 側で mojibake する path。修正: Main 冒頭 (`CliArgs.Parse` の前) で `Console.OutputEncoding = Encoding.UTF8` を best-effort 設定、Logger.Initialize 側の同設定は idempotent なので defensive に残置
- **[Medium-3 検証] round 6 で新規追加した silent path 防御コードの軽量 2 シナリオ手動テスト PASS**: round 6 で導入した「Process.Start 失敗時 / spawn 直後 early-crash 時の RollbackFromBak」path はコード追加のみで動作確認が伴っていなかったため、軽量 2 シナリオを手動実行で検証:
  - **シナリオ A (early-crash)**: csc で build した「spawn 直後 `Environment.Exit(99)` する dummy `GCTonePrism_Manager.exe`」を staging に配置 → Updater 実行 → `proc.WaitForExit(500)` で ExitCode=99 検出 → `RollbackAndReturn6` で旧 Manager (test marker 文字列を仕込んだ dummy ファイル) が `.bak` から bit-perfect に復元 → exit 6 を確認 **PASS** (round 8 で race condition 発覚、C 案で再検証、下記 round 8 entry 参照)
  - **シナリオ B (restart-exe 不在)**: staging から `GCTonePrism_Manager.exe` を意図的に欠落させて Updater 実行 → restart-exe 存在 check NG → `RollbackFromBak` で旧 Manager (test marker dummy) が復元 → exit 6 を確認 **PASS**
  - **deferment**: シナリオ C (Process.Start throw、0-byte exe による Win32Exception) / シナリオ D (parse-stage SecurityException、権限のない drive 要) は Phase 4 連携 E2E で実施。シナリオ A の `catch (Exception)` path はカバー、SecurityException path は別環境要のため deferment

#### Changed (PR #152 シニアレビュー round 7)

- **[Medium-1 + Medium-2] Step ラベル系列を `3/3` → `4/4` に揃え、class docstring 責務列挙を log と同期**: round 6 Codex P1 で導入した「CleanupBak を Step 4 に移動」が outer log ラベルに反映されておらず、`[Step 1/3]` 〜 `[Step 3/3]` のままで Step 4 が silent (CleanupBak の log が無い) だった。あわせて class docstring の責務列挙が 5 項目 (CLI parse / 待機 / 置換 / 起動 / 自分終了) で log ラベル 3 段とも実体 4 段とも矛盾。修正: Program.cs の全 `[Step N/3]` → `[Step N/4]` + `Step 4/4 .bak を best-effort 削除` の log を追加、class docstring を「Step 0 parse / Step 0.5 Logger init / Step 1/4 待機 / Step 2/4 置換 / Step 3/4 起動+early-crash check / Step 4/4 .bak 削除 / exit」に再編、FileReplacer.cs の outer step 列挙コメントも 4 段表記に更新 (round 1 M2 の「outer/inner ラベル分離」方針を round 6 Step 4 追加に追随させる)
- **[Medium-4 PR body 明示的逸脱注記] 本 PR で SPEC を v1.10.10 → v1.10.11 → v1.10.12 と 3 回 bump した点を「AGENTS.md 1 PR 1 bump 規約からの明示的逸脱」として PR body に注記**: round 3 M1 (`--caller-pid` 追加) / round 4 (exit code 3 分割 + Console UTF-8 規約 + 非 admin 前提) / round 6 (exit 2 ログ不在 + stderr capture + exit 6 自動 rollback) と 3 ラウンドで段階的に SPEC が確定したため。履歴改変 (v1.10.10 に統合する案) は下流の追跡性を失うため見送り、規約からの逸脱を可視化することで規約遵守の意図を残す。AGENTS.md 規約の「6+ ラウンド review の例外条項」追加は別 PR で検討
- **[Low-1] FileReplacer.cs:63 の stale 行番号参照 `Program.cs:64` を削除**: round 6 で Step 0 catch 追加により行番号が後退して `Program.cs:64` が Logger 初期化のコメント行を指していた rot 状態。行番号削除 + コメント引用 (`Path.GetDirectoryName(ManagerTargetDir.TrimEnd(...))`) に置換、Claude.md / system 指示の「line-number reference は容易に rot する」原則に整合
- **[Low-2] CliArgs.UsageText の usage 1 行 summary に `[--caller-pid <PID>]` を追加**: round 3 M3 で CHANGELOG `## Updater v0.1.0` ファイル列挙には追記したが UsageText の usage 1 行版だけが 6 オプションのまま残っていた抜けを解消。Optional セクション側には説明あり、`--help` で「Optional に caller-pid あるけど usage 例にはない、内部 only?」と誤読される path を排除
- **[Low-3] FileReplacer.CleanupBak の「新規インストール時など」コメントを round 3 L2 方針と整合**: round 6 Low-1 で `Rollback` の `bakExists=false` branch は「pathological state / 外部・手動呼出しの fallback 経路」に書き換えたが、同 file 内の `CleanupBak` (line 184 付近) の同種コメントが「新規インストール時など、そもそも `.bak` が作られていないケース」のまま残って **同 file 内で round 6 Low-1 が半分しか適用されていなかった抜け** を解消。「Replace が rename 前 (Step 1) で abort して `.bak` 作成に至っていない pathological 経路、または過去 run で既に CleanupBak が走った後の想定外再呼出し」と方針整合化
- **[Low-4] SPEC §3.7.4 に「Manager.exe は spawn 後 500ms 以内に exit しない GUI 常駐 process 前提」を 1 行明文化**: round 6 で追加した `proc.WaitForExit(500)` early-crash check は「Manager が即 exit するモードを将来追加」した場合に正常 fast-exit を early-crash と誤判定する silent assumption を抱える。Manager に `--version` のような short-lived モードを追加する前に SPEC §3.7.4 の early-crash check 仕様 (exitCode 判定追加 等) を再設計する規約を明文化、round 4 M-5 (Manager 非 admin 前提) と同 pattern の defensive SPEC 規約として固定

#### Fixed (PR #152 Codex bot round 5 後追い + シニアレビュー round 6)

- **[Codex P1 + シニア Medium-5] 新 Manager.exe 起動失敗時に rollback できない silent danger を解消 + spawn 直後 early-crash 検出を追加**: 旧実装 (round 1 H1 以降〜round 5 まで) は `.bak` 削除を「restart-exe 存在 check 後 / Process.Start 前」で行っていたため、`Process.Start` が null/throw する path (DLL load 失敗 / access-denied / runtime 依存欠落 / shell association reuse 等) や spawn 直後 0.1s で Manager.exe が crash する early-crash path で「旧 Manager 消失 + 新 Manager 起動失敗」の復旧不能 broken state を作っていた (round 1 H1 fix で broken state を一段階遠ざけたが、Process.Start 周辺がまだ残っていた)。修正: `CleanupBak` を **Process.Start 成功確認後 (Step 4) に移動**、`Process.Start` null/throw/early-crash 各 path で `RollbackAndReturn6` ヘルパー経由で `RollbackFromBak` を呼んで旧 Manager を `.bak` から復元 + exit 6。round 6 Medium-5 と統合し、`proc.WaitForExit(500)` で spawn 直後 500ms の early-crash check を追加 (`proc != null` は OS が spawn process を作った保証だけで、DLL load 失敗 / 0-byte exe / managed exception in Main 等の即 crash を検出できなかった silent failure path も同経路で塞ぐ)。Rollback も失敗した致命的 case は exit 5 (`.bak` から手動復元要)。SPEC §3.7.4 exit 6 説明 + Program.cs class docstring + CliArgs.UsageText + CHANGELOG `## Updater v0.1.0` の 4 箇所に「失敗時自動 rollback + early-crash 検出」を同期反映

- **[Codex P2] Parse 段階の非 ArgumentException が CLR 既定 exit code で抜ける silent danger を解消**: 旧 Main の `try { CliArgs.Parse } catch (ArgumentException)` は `ArgumentException` のみ catch、`Path.GetFullPath` 由来の `SecurityException` / `UnauthorizedAccessException` / `IOException` 等の権限・環境問題は CliArgs.Parse 内部の絞り込み catch (round 2 M2) でも拾えず、CLR 既定の uncaught exception で documented exit codes 0-8 と乖離した予期しない exit code を返す silent danger があった (Phase 4 Manager UI の retry/diagnostic 分岐が壊れる)。修正: Main の Step 0 に `catch (Exception)` を追加、stderr に `ex.GetType().Name` + stack trace + UsageText を出力してから **exit 1 (documented)** に倒す。Logger 未初期化なので stack trace はログファイルに残らず stderr のみ (Medium-4 で SPEC 明文化済)

#### Changed (PR #152 シニアレビュー round 6)

- **[Medium-1] Program.cs class docstring の Exit codes 同期表記を「三者同期」→「5 者同期」に訂正**: round 5 H-1 で「以降の review 完了基準として 5 者同期 (SPEC / Program docstring / UsageText / CHANGELOG / PR body) を固定化」と宣言した meta-rule を、当の Program.cs class docstring が `"CliArgs.UsageText() / SPEC §3.7.4 と三者同期、round 4 H-1 + M-1"` のまま残していて round 5 H-1 が塞いだはずの「自己撞着」を再生産していた。本 entry / `CliArgs.UsageText()` 内部 / Program.cs docstring の同期表記を「5 者同期」に揃え、Phase 4 Manager UI 実装者がこの docstring を見て「3 箇所だけ同期すればよい」と誤解する misleading な lookup path を排除
- **[Medium-2] SPEC 変更履歴 v1.10.11 entry に round 5 L-3 を加筆 + 新 v1.10.12 entry で round 6 範囲を追加**: v1.10.11 entry が round 4 範囲しか記録しておらず、本文 (SPEC §3.7.4 exit 4 説明の auto-recovery 注記) は round 5 L-3 で加筆済の drift があった。v1.10.11 entry に「round 5 L-3 で exit 4 の auto-recovery 経路注記追加」の 1 文を加筆 + 新 v1.10.12 entry で round 6 範囲 (exit 2/1 Logger 未初期化 + stderr capture 必須 + exit 6 自動 rollback) を追加、AGENTS.md「1 PR 1 bump」規約に従って既存 entry 加筆 / 範囲新規エントリの両建てで同期
- **[Medium-3] `## Updater v0.1.0` entry 末尾に「詳細な review 経緯」参照行を追加**: round 1〜6 の review 対応詳細は実体が Updater 本体コードの変更でも `## Release Tooling v0.1.11` 配下に詰まっており、Phase 4 以降に「Updater FileReplacer の `.bak` 保持仕様はいつ変わった?」を CHANGELOG で辿る開発者が `## Updater` セクションを見ても出てこない異常導線があった。AGENTS.md「他セクションから参照」原則に従い、`## Updater v0.1.0` 末尾に「詳細な review 経緯は `## Release Tooling v0.1.11` 配下の各 round entry を参照」の 1 行を追加。CHANGELOG 大規模再構成 (本体コード変更 entry を Updater セクションに移動) は scope creep のため見送り、参照導線の確立で代替
- **[Medium-4] SPEC §3.7.4 に「exit 2 / 1 (parse 段階) はログファイルに残らず stderr のみ」+ 「Phase 4 Manager UI は stderr capture 必須」規約を明文化**: Logger 初期化が CliArgs.Parse の **後** に行われるため、exit 2 (引数エラー、最頻発の user-facing error) は `logs/updater/` に何も残らない可観測性 hole があった。round 4 M-3 で `--restart-exe` validation 追加により exit 2 のヒット確率自体も上がっている。SPEC §3.7.4 exit 2 説明に「parse 段階のため Logger 未初期化、stderr のみ」を明記 + 「Phase 4 Manager UI は `RedirectStandardError = true` で stderr を必ず capture し log viewer に流す規約」を明文化 (Logger 先行 init 案は意味づけ変更の副作用が広いため見送り、SPEC 規約で対応)
- **[Low-1] FileReplacer.Rollback の `bakExists=false` branch のログメッセージを round 3 L2 方針と整合**: round 3 L2 で「Updater は更新 spawn 専用、新規 install は Install.bat」と方針確立後、本 branch は外部 / 手動呼出しで `.bak` が消えた pathological 状態でのみ到達する fallback 経路に変わったが、Logger メッセージは `"rollback: 新規インストール用の target を削除"` のまま矛盾していた。`"rollback: .bak が存在しないため target のみ削除 (pathological state、外部 / 手動呼出しの fallback 経路)"` に書き換え
- **[Low-2] ProcessWaiter の `iter == 0` ログで `timeout=0` 時に「無制限」と表示**: `--wait-timeout 0 = 無制限待機` は UsageText / XML doc / SPEC §3.7.4 で公式仕様化済だが、ランタイムログには反映されておらず「timeout 0s」と表示されると「0 秒待ち = 即 timeout」と誤読される可能性があった。三項演算で `timeoutSeconds == 0 ? "無制限" : $"{timeoutSeconds}s"` の表記分岐に
- **[Low-3] Program.cs:215 の `try { pid = proc.Id; } catch { swallow }` bare catch を `InvalidOperationException` に絞る**: round 4 〜 round 5 を通じて「silent path 全部塞ぐ」防御方針が一貫しているのに、本 1 行だけ bare catch で `NullReferenceException` 等の bug 由来例外も silent に飲み込んでいた。`UseShellExecute=true` で PID 取得不能なケースが docs 明記 (`InvalidOperationException`) なのでこれだけ swallow、それ以外は逃がす。round 2 M2 (`CliArgs.Parse` の catch 範囲絞り) と同じ防御方針に揃える

#### Fixed (PR #152 シニアレビュー round 5)

- **[H-1] CHANGELOG `## Updater v0.1.0` Exit codes 列挙が 6 件のままで他 3 者 (SPEC §3.7.4 / Program.cs class docstring / CliArgs.UsageText) の 9 件と乖離していた自己撞着**: round 4 H-1 entry が明示的に「Exit codes 表を 4 箇所で三者同期」と主張していたが、4 箇所目に該当する CHANGELOG `## Updater v0.1.0` の Exit codes セクション (`0/2/3/4/5/6` の 6 件) が round 4 で更新されておらず、round 4 で追加された exit 1 (M-1) / 7 / 8 (H-1 分割) が抜けていた。Phase 4 Manager UI 実装者が CHANGELOG `## Updater` entry をリファレンスにすると 7/8 への分岐が漏れる misleading な lookup path。修正: CHANGELOG entry を 9 件版に同期 + 「round 5 H-1 で本 entry を 6 件→9 件同期」と経緯記述。あわせて round 5 M-3 で auto-recovery 経路の exit 4 仕様化 (SPEC L-3) と timeout 経路の exit 8 排他化も entry に反映。**5 者同期チェック** (SPEC / Program docstring / UsageText / CHANGELOG / PR body) を以降の review 完了基準として固定化

#### Changed (PR #152 シニアレビュー round 5)

- **[M-2] `CliArgs.ReadValue` が次の `--` 引数を値として消費する silent path を解消**: 旧実装は `--staging --manager-target D:\Manager\ ...` のような value 1 つ忘れパターンで `--manager-target` を `--staging` の値として吸収 → 次 iter で `D:\Manager\` が「未知の引数」として throw する misleading な error path に流れていた。Phase 4 で Manager UI が `--restart-exe "$emptyVar"` のような引数を空変数展開する case も同じ症状なので、明示 check で user-facing error をまっとうな「値が指定されていません (次トークンが別の引数 '...'、value 忘れ疑い)」に倒す。`StartsWith("--", Ordinal)` で判定、負数 / `--` 単独 token は現状の `--wait-timeout` / `--caller-pid` が正整数のみ受理なので副作用なし
- **[M-3] `ProcessWaiter` の timeout 経路で `enumerationFailed` 単独でも `EnumerationFailed` (exit 8) を返していた too-eager 分岐を排除**: round 4 H-1 では「timeout 時に `enumerationFailed` なら exit 8」と分岐していたが、`consecutiveEnumerationFailures` を check せず **1 回でも失敗** すれば exit 8 を返していたため、「偶発的 1 回失敗 + timeout コインシデンス」が exit 8 になり Phase 4 Manager UI が「短時間後再試行」を選んで同じ timeout で再度 exit 8 → 無限ループ化する path があった。修正: timeout 経路は **常に** `TimedOutNoForceKill` (exit 3) を返し、`EnumerationFailed` (exit 8) は `consecutiveEnumerationFailures >= MaxEnumerationFailures` の早期 abort path **専用** に限定 (両者排他)。enum docstring + Logger メッセージ + SPEC §3.7.4 / CHANGELOG Updater v0.1.0 / Program.cs docstring / CliArgs.UsageText 5 者同期で「8 は連続失敗 path 専用」を明文化
- **[M-4] `Process.Start` の戻り値 `Process` インスタンスを `using` で wrap (handle leak 防止)**: 旧実装は `Process proc = Process.Start(psi);` で受けたまま Dispose せず finalizer 任せで OS handle (SafeProcessHandle) を release していた。本 CLI は ~1 秒で exit するので OS が cleanup する想定だが、`proc.Id` アクセス時の InvalidOperationException 等で finally に入る path で handle leak する可能性。round 4 まで「silent path 全部塞ぐ」防御方針で揃えてきた整合性に合わせ、`using (Process proc = Process.Start(psi))` パターンで最後の leak を埋める
- **[L-1] FileReplacer.Replace の親 dir check エラーメッセージを 2 branch に分割**: 旧実装は `parentDir` が null/empty (drive root `C:\` 等の病的入力で `Path.GetDirectoryName` が null/empty を返す) と「親 dir 不在」の両 case で `"manager-target の親 dir が存在しません: {parentDir}"` 一括だったため、前者で log が末尾切れ ("...存在しません: ") になり障害解析しづらかった。round 3 M5 で「drive root 病的入力は defensive fallback として明示化」方針が確立済なので、ここの障害ログも同レベルの明示性に揃える。`IsNullOrEmpty(parentDir)` 時は「親 dir を計算できません (drive root 等の病的入力疑い): {managerTargetDir}」、`!Directory.Exists` 時は現行メッセージ + `{managerTargetDir}` 併記
- **[L-2] Release.ps1 Build-Updater で「任意の .exe」ではなく **特定 exe 名** (`GCTonePrism_Updater.exe`) の存在 check を追加**: round 4 L-3 で追加した `.exe` 1 件以上の check は、csproj の `AssemblyName` を将来誰かが変更して別名 .exe を生成しても build step が green になる (任意の .exe で pass) → 後段 Assert-ExpectedFiles で初めて検出する遠回り。特定名 check を `Test-Path (Join-Path $binRelease 'GCTonePrism_Updater.exe')` で追加、csproj 仕様変更時の早期検出に倒す
- **[L-3] SPEC §3.7.4 の exit 4 に「auto-recovery 経路も同 code を返す」を 1 行明文化**: Codex round 2 P1 #3 で導入した「target 不在 + `.bak` 存在 → `.bak` を target に rename 戻して abort」auto-recovery path は Program.cs で exit 4 を返すが、SPEC 上「単純な replace 失敗 + rollback」と区別できない記述だった。Phase 4 Manager UI が「即 retry が次回 run で正常 path に乗る」(auto-recovery 経路) と「同じ操作を即 retry してもまた fail」(単純失敗経路) を区別する判断材料として、SPEC §3.7.4 に「auto-recovery 経路も本 code を返す、ログメッセージで両 case を区別可能」を 1 行追記。両 case を別 exit code に分けるかは scope creep のため Phase 4 retry policy ガイド執筆時に再検討

#### Fixed (PR #152 シニアレビュー round 4)

- **[H-1] exit code 3 が 3 種類の異なる失敗を一括していて Phase 4 retry 戦略の障壁になっていた**: round 2 Codex P2 #2 (force-kill bounded retry exhausted) + Codex P2 #4 (enumeration 連続失敗) の追加で、`WaitForManagerExit` が `false` を返すパスが「(a) timeout + `--force-kill` 未指定」「(b) `--force-kill` 指定下で MaxForceKillAttempts (3) 超過」「(c) MaxEnumerationFailures (5) 連続失敗」の 3 種に分岐していたが、Program.cs はすべて exit 3 に倒していた。Phase 4 Manager UI が exit 3 を見て「単に `--force-kill` 指定忘れ」と誤判定 → permission denied (構造的問題、(b)) で `--force-kill` 付与 retry を組まれて無限再試行する silent bug 化リスク。修正: ProcessWaiter を `bool` 返しから `WaitResult` enum 返し (`Success` / `TimedOutNoForceKill` / `ForceKillExhausted` / `EnumerationFailed`) に変更、Program.cs で switch して exit 3 / 7 / 8 に分岐。SPEC §3.7.4 / Program.cs class docstring / CliArgs.UsageText の Exit codes 表を 4 箇所で三者同期 (現在は SPEC + 実装 2 箇所の三者同期)

#### Changed (PR #152 シニアレビュー round 4)

- **[M-1] exit code 1 (予期しない実行時例外) が公式仕様から完全に欠落していた**: Program.cs:81 の `catch (Exception)` は exit 1 を返すが、Program.cs class docstring の Exit codes 表 / CliArgs.UsageText / SPEC §3.7.4 すべてに記載がなく、唯一 CliArgs.cs 内のインライン comment だけが exit 1 の存在を示唆していた。Phase 4 Manager UI が exit code 表ベースで分岐実装する際に未定義 code を受信すると caller 任意で「skip / log / report」になり矛盾源を作る。3 箇所すべてに「1 = 予期しない実行時例外 (Logger に stack trace、bug report 対象)」を追記、`--help` ユーザーも `1` を見て「想定内」と判断できる形に
- **[M-2] `Process.Start(psi)` の戻り値を無視 → 起動成否を検出できない silent path**: 旧実装は `Process.Start(psi);` を即「Manager 起動完了」ログで通過していたが、`UseShellExecute=true` では「OS が既存プロセスを reuse」「OS が起動を抑止」等で null を返すと公式ドキュメントに明記。null/非 null 問わず embedded false success を残し、Manager UI / 部員視点で「Updater は exit 0 で抜けたから OK」と誤誘導される silent failure path があった。修正: 戻り値を `Process proc` で受けて null check、null なら Logger.Error + exit 6 で fail。PID も best-effort で記録 (取得失敗しても起動成功扱い、UseShellExecute=true は PID アクセス保証外)
- **[M-3] `--restart-exe` が `--manager-target` 配下でない誤 path でも素通り → 誤起動 risk**: 旧実装は `File.Exists(RestartExe)` のみ check で、caller (Manager UI Phase 4) の typo で `--restart-exe C:\Windows\System32\calc.exe` のような誤 path が渡されると、Updater は新 Manager dir を置き換えた後に calc.exe を起動して exit 0 で抜ける silent failure path が残っていた (Manager UI 側は「アップデート成功」表示 → 部員 / 顧問は新 Manager が起動したと信じる mismatch)。修正: CliArgs.Parse の Path.GetFullPath 後に `RestartExe.StartsWith(ManagerTargetDir + DirectorySeparatorChar, OrdinalIgnoreCase)` check を追加、不一致なら ArgumentException で exit 2 に倒す。round 2 L2 (target 不在 typo) と同じ防御方針、末尾 separator 揺れを `TrimEnd` で吸収しつつ prefix 偶然衝突 (`Manager` + `ManagerExtra`) も separator check で排除
- **[M-4] `Console.OutputEncoding` 未設定 → Manager UI stdout capture 経由で日本語 log が mojibake する path**: Logger 内の全 Info / Warn / Error メッセージは日本語混じり (「[Step 1/3] Manager プロセスの終了を待機」等) で、ファイルログは UTF-8 BOM なし (FileStream + UTF8Encoding(false)) と明示設定済だったが、Console 側は未設定。default は Windows console codepage (日本語 Windows = Shift-JIS / CP932) で、Phase 4 で Manager UI が `RedirectStandardOutput=true` で stdout を log viewer に流す前提なのに encoding が揃わないと mojibake する遅効性 bug。修正: Logger.Initialize 冒頭で `Console.OutputEncoding = Encoding.UTF8` を best-effort で明示設定、SPEC §3.7.4 にも「Manager UI 側も UTF-8 で読む規約」を 1 行追記して双方の規約を固定
- **[M-5] SPEC §3.7.4 に「Manager.exe は admin 権限を要求しない manifest 前提」を 1 行追記**: `UseShellExecute=true` で起動する Updater の構造上、将来 Manager.exe が requireAdministrator manifest を持つようになった場合に「Updater が消えた直後に UAC prompt が突然出る」体験になる silent assumption だった。SPEC §3.7.4 に「Manager は admin 権限を要求しない設計、将来変更する場合は §3.7.3 / §3.7.4 を再設計すること」と固定し、Program.cs:166 にも同コメントを残して将来 breakage を防ぐ
- **[L-2] `Logger.CurrentLogPath` が Shutdown 後も古い path を保持する stale 状態を解消**: Shutdown() は `_writer = null` + `_initialized = false` をセットするが `_currentLogPath` は clear していなかった。本 CLI は Main で 1 回 Shutdown して即 exit するので実害なしだが、test code や将来の re-initialize 経路で `Shutdown → CurrentLogPath getter` が前回 path を返す混乱源を断つ。1 行修正 (`_currentLogPath = null;`)
- **[L-3] `Build-Updater` の copy ループが空 `bin/Release` で silent success する path**: msbuild が exit 0 で抜けたが成果物 dir が空 (msbuild target 設定誤り等の pathological case) の場合、`Get-ChildItem` が 0 件で `Copy-Item` ループが silent に 0 回回り、「Updater 成果物コピー完了」を空コピーで通過する path があった (最終的に Assert-ExpectedFiles で fail するが原因切り分けが遠い)。修正: `Test-Path` check 直後に `.exe` 1 件以上の存在 check を追加、不在なら Build-Updater レベルで早期 fail させて「msbuild 出力なし」を明示
- **[L-4] FileReplacer.CopyDirectory の docstring に attribute preserve 仕様を 1 行追記**: `File.Copy(..., overwrite: true)` は内容のみコピーし source の ReadOnly / Hidden / System 等の attribute は preserve しない挙動を docstring に明示。Manager 配下は全て通常 attribute なので現状実害なしだが、将来「user data 残し更新」path で attribute 維持が必要になった場合の sleeper bug 化を防ぐ予防的 doc

#### Fixed (PR #152 シニアレビュー round 3)

- **[H1] PID-only モードで `Process.GetProcessById(pid)` の戻り値を `ProcessName` 検証せず、PID 再利用で別プロセスを誤 kill するリスク**: round 2 Codex P1 #1 で導入した `--caller-pid` PID-only モードは「Manager exit → OS が同 PID を別プロセス (例: notepad.exe) に再割当 → `--force-kill` 指定時に notepad を kill」という silent danger を抱えていた (Windows PID は exit 済プロセスから再利用される)。修正: `GetTargetProcesses` で `Process.GetProcessById` 直後に `p.ProcessName == "GCTonePrism_Manager"` を検証、不一致時は「PID 再利用 → Manager 既終了」とみなして空配列 (= 待機 skip 経路) に流す。`ProcessName` アクセス中 exit の `InvalidOperationException` も同経路扱い

#### Changed (PR #152 シニアレビュー round 3)

- **[M1] SPEC §3.7.4 に `--caller-pid <PID>` 引数を追記 + 変更履歴 v1.10.10 entry 追加**: round 2 Codex P1 #1 で実装した `--caller-pid` が SPEC に未反映の二者乖離。Updater CLI 引数表に `--caller-pid <PID>` (推奨 = Phase 4 Manager UI が `Process.GetCurrentProcess().Id` を渡す、未指定時は system-wide `GetProcessesByName` fallback) を追記、変更履歴 v1.10.10 entry で round 3 H1 / M1 の SPEC 影響を要約
- **[M2] CHANGELOG `## Updater v0.1.0` の「約 750 行」行数指標を「8 ファイル」構成指標に置換**: round 2 までの追記で実コード規模が増え行数指標が stale 化。エンドユーザー向け summary としては「行数」より「8 ファイル構成」の方が安定で意味ある粒度
- **[M3] CHANGELOG `## Updater v0.1.0` のファイル列挙に `--caller-pid` 追記 + ProcessWaiter.cs 説明刷新**: CliArgs.cs 引数列挙 / ProcessWaiter.cs 説明が round 2 の `--caller-pid` + PID-only mode + bounded retry 追加に追随していなかった三者矛盾を解消。CliArgs.cs 列挙に `--caller-pid` 追加、ProcessWaiter.cs 説明に「PID-only モード (caller-pid > 0) + system-wide fallback (未指定時)、`MaxForceKillAttempts = 3` / `MaxEnumerationFailures = 5` の bounded retry」を追記
- **[M4] CHANGELOG `## Updater v0.1.0` 動作確認項目の `3-step 置換` 記述を round 1 H1 + Codex P1 #3 反映の正確な記述に書き換え**: round 2 M3 で同 entry の API 説明は「2-step + CleanupBak/RollbackFromBak」に直したが、動作確認項目内の「3-step 置換が正しく動作」が漏れていた残骸を解消。「Manager dir 置換 (Replace 2-step + CleanupBak) + restart-exe 不在時の RollbackFromBak 自動復元 + Codex P1 #3 自動復元 (target 不在 + .bak 存在パターン)」と動作内容を正確化
- **[M5] Program.cs / Logger.cs の「Logger fallback は到達不能」コメントを「通常運用では到達しないが defensive、消さないこと」に訂正**: round 1 M1 + L3 で「Program 側 path 確定で Logger fallback は到達不能化」と表現したが、CliArgs.Parse の `Path.GetFullPath` でも drive root 病的入力 (例: `--manager-target C:\`) では `Path.GetDirectoryName` が null/empty を返し fallback 経路に流れる極限ケースが存在する。「到達不能」表現を訂正、「通常運用では到達しないが極限ケース用に残してある defensive fallback、消さないこと」に書き換え (Program.cs / Logger.cs L43 / Logger.cs L58 の三者同期)
- **[L1] FileReplacer.Replace の `targetExisted` dead value を削除、`Rollback` 呼び出しで `bakExists: true` を named arg で明示**: round 2 L2 で「target 不在 case を Error + return false」に塞いだ後、`targetExisted` 変数は計算するだけで使われない dead value 化していた。`if (!Directory.Exists(managerTargetDir)) { Error; return false; }` の early return に integrate、変数廃止。同 Replace 内 fail path で `Rollback(managerTargetDir, bakDir, true)` を `Rollback(managerTargetDir, bakDir, bakExists: true)` の named arg にして「Replace 経路では `.bak` は必ず存在する」という invariant をコード上で明示
- **[L2] FileReplacer.RollbackFromBak のコメントを round 2 L2 後の現実に合わせて刷新**: 「bak が存在しない = 新規インストール扱い」という旧コメントは round 2 L2 (target 不在 case を Replace で塞いだ) 後の現実と乖離していた stale。「round 2 L2 後は Replace 成功 → 検証失敗で本関数が呼ばれる時点で `.bak` は実質的に存在する。defensive check として `bakExists` を計算して渡すのは外部 / 手動呼出しの fallback 経路として残す」に書き換え
- **[L3] Logger.OpenSessionFile の counter 100 到達時 Warn message を loop 実体と一致させる**: round 2 L6 で追加した Warn が「100 件」と書いていたが、loop は `counter < 100` で抜けるので試行する候補は base name + suffix `_2` 〜 `_99` の計 99 件で off-by-one。「base + suffix _2 〜 _99 の 99 件全て衝突」に正確化。実害なしの表記ズレ

#### Fixed (PR #152 Codex bot round 2 後追い)

シニアレビュー round 2 と並行して Codex bot が 4 件発見 (P1 × 2 + P2 × 2):

- **[Codex P1 #3] `.bak` を target 検証より先に削除 → 前回 rollback 失敗からの retry で復旧不能**: 前回 run で Step 1 (target → .bak rename) 成功 + Rollback も失敗した場合、`.bak` のみが intact な Manager。次回 retry で「過去 run の残骸 .bak 削除」branch が `.bak` を消すと、唯一の intact Manager が消失 + target も新 rename されて空 → 復旧不能。修正: `.bak` 削除前に target の存在を check し、**target 不在 + .bak 存在** = 前回 rollback 失敗パターンとして自動復元 (`.bak` → target に rename 戻し) して Replace を fail で抜ける構造に。次回 run で正常 path (target あり) に乗る。単体テスト (前回 rollback 失敗状態を artificial 再現) で旧 Manager 自動復元動作確認済
- **[Codex P1 #1] `GetProcessesByName` system-wide 巻き添えリスクを `--caller-pid` で構造的解消**: round 1 L5 / round 2 L7 では「校内 1 PC 1 install 前提なら実害なし」と comment で acknowledged したが、Codex は P1 として「コード対応」を要求。`--caller-pid <PID>` optional 引数を追加、指定時は `Process.GetProcessById(pid)` で PID-only wait/kill (同 PC の他 install Manager 巻き添えを構造的に排除)。未指定時は従来の `GetProcessesByName` system-wide fallback (後方互換)。Phase 4 で Manager UI が `Process.GetCurrentProcess().Id` を渡す前提
- **[Codex P2 #2] `--force-kill` の kill 失敗時に無限ループする**: permission denied (elevated Manager 等) で `Process.Kill` が失敗しても `continue` で再 polling → また同じプロセスが見つかる → 永遠にループ。bounded retry (`MaxForceKillAttempts = 3`) を追加、3 回連続 kill 失敗で fail (`Logger.Error` + return false → exit 3)
- **[Codex P2 #4] `Process.GetProcessesByName` throw 時に空配列 fallback → 「Manager 既終了」誤判定**: IPC / WMI 一時不調等で enumeration が throw した場合、空配列で続行 = Manager 終了済扱いになり Manager 生存中に置換進行 → File-in-use エラー path。修正: enumeration 失敗を sentinel flag で区別、「unknown state、待機継続」扱いに変更 (空配列 fallback でも `return true` には流さない)。`MaxEnumerationFailures = 5` 連続失敗で abort

#### Fixed (PR #152 シニアレビュー round 2)

- **[M1] FileReplacer.Replace の parent dir 存在チェックが trailing-slash で誤動作する bug**: `Path.GetDirectoryName(managerTargetDir)` を TrimEnd なしで呼んでいたため、`managerTargetDir = "D:\Manager\"` (CliArgs の `Path.GetFullPath` が trailing slash を保持) の場合に `GetDirectoryName` が `"D:\Manager"` (Manager dir 自身) を返し、parent check が Manager dir 自身の存在を見る silent divergence があった。Program.cs:64 の log-dir 計算と pattern を揃え、`TrimEnd('\\', '/')` してから `GetDirectoryName` に渡す形に修正
- **[M2] CliArgs.Parse の `Path.GetFullPath` catch が広すぎ、想定外例外を引数エラー (exit 2) に倒していた**: 旧実装は `catch (Exception ex)` で全例外を `ArgumentException` 変換 → exit 2。`SecurityException` / `UnauthorizedAccessException` 等の権限・環境問題まで「引数エラー」表示で Manager UI 側の障害解析を misleading にする path。`Path.GetFullPath` 公式契約の「引数自体の不備」系 3 種 (`ArgumentException` / `PathTooLongException` / `NotSupportedException`) に catch を絞り、それ以外は Program.cs:77 の `catch (Exception)` で exit 1 (予期しない例外) に倒す形に変更

#### Changed (PR #152 シニアレビュー round 2)

- **[M3] CHANGELOG `## Updater v0.1.0` の `3-step` 記述を正確化**: 同 PR 内の round 1 H1 修正で FileReplacer を「Replace (2-step) + CleanupBak / RollbackFromBak 別 API」に分離したのに、Updater v0.1.0 entry は「rename-rollback 3-step 置換」と旧記述のままだった unfortunate 残骸を解消。「Replace (Step 1 rename + Step 2 copy の 2-step API) + CleanupBak (cleanup) + RollbackFromBak (rollback) の 3 API、概念的には rename → copy → cleanup/rollback の 3 動作」と正確な API 説明に書き換え
- **[L1] CliArgs クラス頭部 XML doc に `--wait-timeout 0 = 無制限待機` 追記** (round 1 L2 漏れ): round 1 L2 で UsageText には反映したが XML doc が漏れていた三者矛盾。漏れを解消、XML doc + UsageText で「default: 60、0 = 無制限待機」と一致
- **[L2] FileReplacer の `targetExisted == false` を silent typo 吸収 → Error + return false に変更**: SPEC §3.7.4 で Updater は Manager UI からの更新 spawn 専用 (新規 install は Install.bat 担当) なので target dir 不在は caller の typo (`--manager-target` 誤指定) しかありえない。旧実装は Warn だけで copy を進めて誤 path に新規 install してしまう silent failure mode を作っていた。Error + return false に変更、caller (Manager UI / Phase 4) に引数エラーとして検出させる。「Updater は Manager UI からの更新 spawn 専用、新規 install は Install.bat を使用」案内も追加
- **[L3] FileReplacer.Replace の stateful API (cleanup caller 責務) を XML doc 警告強化**: Replace 成功時の `.bak` cleanup が caller 規約に依存する footgun を XML doc 冒頭に `⚠ stateful API` で明示警告 + 「新規 caller を追加する場合は必ず CleanupBak/RollbackFromBak の呼び出しをペアで実装すること」を追記。API signature 変更 (e.g. IDisposable) は本 PR scope 外、docstring 強化で対応
- **[L4] ProcessWaiter の `iter % 10` を `LogEveryNIter` 名前付き定数に抽出**: `PollIntervalMs × LogEveryNIter = 実 interval` の magic number 連動を `private const int LogEveryNIter = 10;` で明示化。PollIntervalMs を変えるとログ間隔も silent に変わる罠を解消、コメントで「現状 500ms × 10 = 5 秒ごと」と意図を明記
- **[L5] Build-Updater の `Test-Path $binRelease` を `New-Item $outDir` より先に**: msbuild が exit 0 で抜けたが成果物 dir 生成失敗の pathological case で空 staging dir 残骸を作らないよう、check 先行・mutate 後 の order に整理。Build-Manager との pattern は今後も整える方向 (本 PR scope は Updater のみ)
- **[L6] Logger.OpenSessionFile の counter 100 到達時に Console.Error Warn を追加**: 同一秒に 100 回 Initialize 試行で `FileMode.CreateNew` が IOException → Initialize catch で silent fallback → Console のみで続行する path を可視化。Phase 4 で Manager UI が retry loop を組んだ場合 / 自動テスト時に発火可能、現状運用では発火しないが silent fallback を可視化

#### Fixed (PR #152 シニアレビュー round 1)

- **[H1] Updater で restart-exe 検証が `.bak` 削除後 → 復旧不能 broken state を作る**: 旧実装は `FileReplacer.Replace` 内で .bak 削除まで行ってから Program 側で `File.Exists(args.RestartExe)` チェックしていた。staging 側に `GCTonePrism_Manager.exe` が無い release packaging bug 等で「旧 Manager 消失 + 新 Manager 不在」の復旧不能状態に陥る path。修正: `FileReplacer.Replace` を Step 1 (rename) + Step 2 (copy) のみに絞り、`.bak` 削除は `CleanupBak` メソッドに分離。失敗時の rollback も `RollbackFromBak` を public 化。Program.cs 側で Replace 成功後に restart-exe 存在検証 → OK なら CleanupBak、NG なら RollbackFromBak で旧 Manager 復元 + exit 6 の flow に変更。H1 シナリオの単体テスト (staging に Manager.exe を意図的に欠損させる) で「旧 Manager.exe 復元 + user data 維持 + .bak 消費済」の動作確認済

#### Changed (PR #152 シニアレビュー round 1)

- **[M1 + L3] `--log-dir` default の三者矛盾を解消**: UsageText / CliArgs XML doc / Logger fallback で「exe 隣」と「`<install>/logs/updater/`」が混在していて user が `--help` 読んだ後にログを別場所で探す silent path があった。SPEC §3.7.4 準拠の `<install>/logs/updater/` (manager-target の親から導出) に三者統一、UsageText / CliArgs コメント明記、Logger fallback は Program 側で path 確定保証 (CliArgs path 絶対化と相まって到達不能化) + コメントで「通常 path は Program 側確定、Logger fallback は到達不能化」明記
- **[M2] FileReplacer 内 Step ラベルを `[Replace X/2]` に分離**: outer Program.cs の `[Step 1/3]` `[Step 2/3]` `[Step 3/3]` と inner FileReplacer の同じラベル形式が衝突して実機ログの障害解析時に紛らわしかった。inner を `[Replace 1/2]` `[Replace 2/2]` に変更、合わせて step 数も 3 → 2 (`.bak` 削除分離による H1 修正の副次効果) + CleanupBak は単独メッセージ
- **[M3 + L4] CliArgs.Parse で path 4 種を `Path.GetFullPath` で絶対化**: `--staging` / `--manager-target` / `--restart-exe` / `--log-dir` が相対 path で渡されると Updater プロセスの CWD に依存する silent path があった。Parse 末尾で 4 path 全てを `GetFullPath` 通すことで、後段の Logger / FileReplacer / Process.Start 全箇所で path 絶対性を仮定可能に。L4 (`"\\"` 等の病的 root 入力) も `GetFullPath` で drive root absolute に正規化されて副次的に解消
- **[L1] ProcessWaiter で初回 polling 時に既終了済の場合もログ残す**: Manager が呼び出し前に既に終了していると `[Step 1/3] Manager プロセスの終了を待機` の直後に何もログが出ず Phase 4 で「待機が機能しているか」を後追い確認できない問題を解消。`iter == 0` でも「Manager プロセスは既に終了済み、待機 skip」を 1 行出す
- **[L2] `--wait-timeout 0` = 無限待機を UsageText に明記**: `ProcessWaiter.WaitForManagerExit` は `timeoutSeconds > 0` を check gate にしていて 0 → 無限待機の挙動だが、UsageText / SPEC は default 60 しか書いていなかった。`--wait-timeout <seconds>  ... (default: 60、0 = 無制限待機)` と UsageText に追記、誤って 0 渡して Updater hang する path を明文化で防ぐ
- **[L5] ProcessWaiter の `GetProcessesByName` system-wide コメント追加**: `--force-kill` 時に同 PC で test 用 / production 用 Manager.exe が同時稼働している edge case で両方 kill される挙動を明文化。校内 1 install 想定では実害なしだが、将来 `--caller-pid` で自身の PID のみ wait/kill する形に拡張する余地ありと明記
- **[L6] Logger に `_initFailed` ガード不要理由を明記**: Manager Logger は `_initFailed` ガード持ちだが Updater 版は持たない非対称性を「Initialize は Main() で 1 回しか呼ばれない設計、冪等性は `_initialized` の単純 return で十分」とコメントで明文化
- **[L7] Manager と同じ ProjectGuid / Guid 同一値運用を確認**: Manager csproj の `ProjectGuid` と AssemblyInfo の `Guid` が同一値 (`EA046367-...`) で運用されているので、Updater 側 (`b5d71e9c-...`) も同一値で OK。既存慣行に従う

#### Added (#108 Phase 3 完成: Updater 実装着手)

- **`Build-Updater` function in Release.ps1**: `Companions/Updater/GCTonePrism_Updater.csproj` を `msbuild /p:Configuration=Release` で build、staging `<staging>/files/Companions/Updater/` にコピー。Manager と同じ pattern で nuget restore / native DLL 抽出は不要 (Updater は SQLite / WindowsAPICodePack 等の外部依存を持たない単純な Console app)
- **Build-Updater 呼出し追加**: Main flow `Build-Launcher → Build-Manager → Build-Updater → Copy-Templates` の順に統合
- **ExpectedFiles +2 件 (13 → 15)**: `files\Companions\Updater\GCTonePrism_Updater.exe` + `.exe.config` を SPEC §3.7.1 正規 zip 構造に追加
- **TODO コメント更新**: `TODO Phase 3 (#108): Companions/Updater/ の build + staging を追加` を「Phase 3 完成: Companions/Updater/ の build + staging を `Build-Updater` で実装済」に書き換え

詳細は `## Companions` セクション v0.1.0 entry (= 旧 `## Updater (Companions/Updater)`、#160 で rename) を参照。

### [Release Tooling v0.1.10] - 2026-05-13

#### Changed (主変更: ディレクトリ命名規約 + Companions 再定義、SPEC v1.10.9 連動、#108 Phase 3 着手準備)

- **トップレベル dir rename**: `GCTonePrism_Launcher/` → `Launcher/`、`GCTonePrism_Manager/` → `Manager/`。リポジトリ全体が GCTonePrism なので prefix 冗長、Folder 名は短縮の方が視覚的にスッキリ。csproj / アセンブリ / exe 名は `GCTonePrism_<Name>` prefix を維持 (process 検知 uniqueness のため、`tasklist` / `Process.GetProcessesByName` で他アプリの `Manager.exe` / `Updater.exe` と衝突を避ける)。AGENTS.md に新規 `## Naming Conventions` セクションを追加して命名規約を明文化
- **Companions 概念再定義** (SPEC §2.4): 旧仕様「Launcher 専用サブコンポーネント、`GCTonePrism_Launcher/Companions/` 配下」を「主要 (Launcher / Manager / Monitor) を補助する独立 exe 群、リポジトリルート `Companions/` 配下、dev/runtime 一貫配置」に拡張。Updater (Phase 3) もこのカテゴリに含まれる。Launcher 補助 Companion (#101 WindowProbe / #30 PauseOverlay) も runtime で `<install>/Companions/<Name>/` 配置に変更 (旧仕様の「Launcher exe と同じ dir に同梱」を廃止)
- **§3.7.3 / §3.7.4 Updater 役割を Manager-heavy + minimal Updater に再定義**: 旧仕様の fat Updater 設計 (Updater が全 component 置換) を改め、「Manager 自身の置換だけが Updater を必須とする」(Launcher / Companions は外部プロセスで Manager から kill + 直接置換可能、shortcut bat / Updater.exe 自体は稼働していないので Manager から直接置換可能) に整理。Updater のスコープ大幅縮小 (50-150 行の最小 CLI)、Phase 4 Manager UI が大半の責務 (download / 各 component 置換 / progress バー) を持つ形に
- **Release.ps1 path 更新**: `$LauncherDir` / `$ManagerDir` / `$FilesDir` 配下の staging path / `ExpectedFiles` の path 全て新 dir 名 (`Launcher/` / `Manager/`) で更新。`Build-Launcher` / `Build-Manager` の中身 logic は不変 (csproj / exe 名は prefix 付き維持なので変更不要)
- **templates path 更新**: `Launcher.bat` / `Manager.bat` の `%~dp0GCTonePrism\GCTonePrism_<X>\GCTonePrism_<X>.exe` → `%~dp0GCTonePrism\<X>\GCTonePrism_<X>.exe` (dir 短縮、exe 名 prefix 維持)。Install.bat の `tasklist` 引数は exe 名 (`GCTonePrism_Manager.exe`) なので変更不要
- **Install.bat に v0.2.0 旧構造 migration 追加**: 既存検出 + Y 経路で `<install>/GCTonePrism_Manager/` / `<install>/GCTonePrism_Launcher/` を検出したら `<install>/Manager/` / `<install>/Launcher/` に `move` でリネームしてから robocopy 実行。`move` で dir 名のみ変更 = 中身そのまま carry-over。一度移行すれば以降はリネーム不要 (旧 dir 不在で skip)。top-level goto pattern に従って `:migrate_legacy_manager` / `:migrate_legacy_launcher` / `:migrate_conflict_*` / `:migrate_failed` / `:do_robocopy` の独立ラベルで構造化
- **PathManager.cs / path_manager.gd の self-reference 修正**: Manager / Launcher 自身が runtime で `"GCTonePrism_Manager"` / `"GCTonePrism_Launcher"` という親 dir 名を検出してプロジェクトルートを解決していたロジックを `"Manager"` / `"Launcher"` に置換。新 install 構造で正しく動く
- **README.md ディレクトリ構成図を新 dir 名で更新** + 命名規約への参照を追加

#### Fixed (PR #150 シニアレビュー round 7)

- **[M1] migration `move` の stderr 抑制で失敗原因が user に届かない**: 旧 `move ... >nul` は stdout のみリダイレクト、stderr 経由の失敗詳細 (アクセス拒否 / 別プロセス使用中 / ファイルロック等) が握り潰されていた。round 3 M2 の `show_folder_dialog` 呼び出しで確立した「stdout/stderr 分離キャプチャ + 失敗時 type 表示」規約から逸脱していた catalog/call-site mismatch。修正: `move ... >"%TEMP_MV_OUT%" 2>&1` で stdout+stderr 両方を tmp file にキャプチャ、`:migrate_failed_manager` / `:migrate_failed_launcher` でそれぞれ `type "%TEMP_MV_OUT%"` して move コマンドの実出力 (= 失敗理由の詳細) を user に表示。tmp file は 2 段階 move で共有、各失敗 path と success 経路 (`:migrate_done`) で cleanup
- **[L5] PathManager priority-3 detection に Manager/Launcher sibling 同時存在検証を追加**: round 1 L2 で acknowledged されていた priority-3 false-match 余地 (`<install>/Manager/` 単独 dir で起動した場合に他アプリ等の Manager dir と誤マッチする path) を構造的に解消。我々の install 構造は Manager と Launcher が必ず同一の親 dir 配下にセットで配置される (SPEC §3.7.1 / §7.5.1) ため、priority-3 で「Manager/ AND Launcher/ の両方が currentPath 直下に存在」を確認する形に強化。Manager 側 `PathManager.cs` + Launcher 側 `path_manager.gd` 両側に対称的に追加。issue #151 (priority-3 detection 強化) の主要 scope を本 PR で close 可能に

#### Changed (PR #150 シニアレビュー round 7)

- **[L1] AGENTS.md "Naming Conventions" に Common 系 csproj 命名例外を追記**: 旧記述は「csproj 名 = `GCTonePrism_<Name>`」と例外なしで書いていたが、SPEC §2.4 の `Common/GCTonePrism_CompanionsCommon.csproj` (= csproj 名に Parent prefix を含める形) が catalog 内矛盾だった。「`Common` / `Core` / `Shared` 等の汎用すぎる名前は assembly 衝突回避のため `GCTonePrism_<Parent><Name>` 例外を許容 (例: `Companions/Common/` → `GCTonePrism_CompanionsCommon.csproj`)」と 1 行例外規約を追記、SPEC §2.4 と AGENTS.md の整合を回復
- **[L2] robocopy 共通フラグを `ROBOCOPY_COMMON` 変数化**: overwrite path (`/E /XF prism.db /XD games backups responses logs /NFL /NDL /NJH /NJS /NC /NS /NP /R:1 /W:1`) と new_install path (`/E /NFL /NDL /NJH /NJS /NC /NS /NP /R:1 /W:1`) で共通フラグが重複していて、片方修正時にもう片方が乖離する事故 path があった。`set "ROBOCOPY_COMMON=/E /NFL /NDL /NJH /NJS /NC /NS /NP /R:1 /W:1"` で共通化、overwrite 側は `%ROBOCOPY_COMMON% /XF ... /XD ...` を追加する形に統一
- **[L3] `:overwrite_set_mode` 直下のコメント flow 記述を `:copy_shortcuts` dispatcher に集約**: 旧コメントは「migration / mkdir → ...」と両 path の flow を `:overwrite_set_mode` (overwrite 専用ラベル) の直下で議論していて、構造的に読みづらかった。`:copy_shortcuts` dispatcher 直下に「overwrite path: migration → shortcut → robocopy」「new_install path: mkdir → robocopy → shortcut」と path-specific に整理、`:overwrite_set_mode` 側はリンクのみ
- **[L4] `:migrate_conflict_launcher` に MANAGER_MIGRATED 状態案内追加**: Manager 移行成功 + Launcher 側で新旧 dir 並存ケースで「Manager 側はすでに移行済」を案内しない問題を解消 (`:migrate_failed_launcher` / `:shortcut_failed` と同パターン、catalog/call-site uniformity)。user が「両方ある = まだ移行されていない、全部一旦戻そう」と Manager 側も旧 dir に戻す誤対処 path を防ぐ
- **[L6] CHANGELOG `## Manager v0.8.10` / `## Launcher v0.5.17` を Release Tooling 参照のみに圧縮**: 各 component entry に begins_with 修正 / sibling guard 等の技術詳細が重複記述されていた (AGENTS.md「重複記述は避ける」規約違反)。両 entry を「PR #150 で dir rename 連動、詳細は Release Tooling v0.1.10 参照」の 2 行に圧縮、SoT を Release Tooling v0.1.10 に集約

#### Fixed (PR #150 Codex bot round 6 後追い)

- **[Codex P2] new_install path で robocopy 失敗時に broken shortcut bat が残る regression**: round 3 L3 で「shortcut copy を robocopy の前に統一移動」した時、overwrite path の partial-failure 対策 (migration 後の robocopy 中断で shortcut bat 旧 path 残存問題) を解消するためだったが、`INSTALL_MODE=new` の場合に **副作用 regression** を導入していた。新規 install で shortcut copy 成功 + robocopy 失敗 (権限 / disk full / Ctrl+C) のとき、partial / 空の `<install>/GCTonePrism/` を指す `<親>/Launcher.bat` / `<親>/Manager.bat` が壊れた状態で残る path。修正: `INSTALL_MODE` で順序分岐:
  - overwrite: shortcut → robocopy (round 3 L3 維持、migration partial-failure 対策)
  - new:       robocopy → shortcut (shortcut bat は完全インストール成功後にのみ作成、broken shortcut の regression 解消)
  - `call :do_shortcut_copy` / `call :do_robocopy` の subroutine 風実装 (`exit /b N` で成否伝播) で共通 shortcut copy ロジックを 1 箇所に集約
  - `:copy_failed` メッセージも `INSTALL_MODE` で条件分岐 (「shortcut bat はすでに新版で配置済み」(overwrite) vs 「shortcut bat はまだ配置されていません」(new))

#### Changed (PR #150 シニアレビュー round 6)

- **[M1/M2] AGENTS.md / SPEC §3.7.3 / §3.7.6 / §2.2 機能13 の「Updater / Companions」並列列挙を包含関係に整理**: 本 PR 自身が §2.4 で「Updater は Companions の一員」と再定義したのに、4 箇所 (AGENTS.md L30, SPEC L584/L939/L1040) で並列列挙が残っていた catalog (§2.4) vs call site の矛盾。「Launcher / Manager / 各 Companion (Updater / WindowProbe 等、§2.4)」形式に統一して包含関係を反映。1 PR 内の自己矛盾を解消
- **[M3] SPEC §3.7.6 step [2] の `dotnet publish` を `msbuild /p:Configuration=Release` に修正**: Manager / Companions は `.NET Framework 4.8` で `dotnet publish` 不可 (`.NET Core / .NET 5+` 向け cmd)、実装の Release.ps1 は `msbuild` を使っている。§3.7.4 で「Build-Updater が個別に msbuild」と明記してるのに §3.7.6 では `dotnet publish` 表記が残っていた同 PR 内の自己矛盾。「`msbuild /p:Configuration=Release` で個別ビルド (`.NET Framework 4.8` 系は `dotnet publish` 不可、`msbuild` 直叩き)」と正確化
- **[L1] `:shortcut_failed_with_migration_note` に shortcut bat ダブルクリック回避警告追加**: 2 段階 `copy /Y` (Launcher.bat → Manager.bat) で 1 段目成功 + 2 段目失敗の partial-state では、Launcher.bat は新 path / Manager.bat は旧 path の不揃いになる (migration 後なので旧 path 壊れている)。再実行までの間 user が壊れた bat をダブルクリックする path を防ぐため、「Install.bat 再実行までは Launcher.bat / Manager.bat をダブルクリックしないでください」と注意書きを追加 (round 3 L3 の精神「user の操作が破綻状態の dir 構造を見ない」を貫徹)
- **[L2] SPEC §7.5.1 runtime 構造の `Companions/` に「Phase 3 以降」注記追加**: 本 PR では Updater 実装なし、`Build-Updater` も `ExpectedFiles` の `Companions/...` 項目もない。次の publish (v0.3.0) では `<install>/GCTonePrism/Companions/` は作られない。読者が「Companions/ がすでにある」前提で書き始める path を防ぐため「Phase 3 以降で Updater 配布開始、それまでは dir 自体が存在しない」と明記
- **[L3] SPEC §2.4 構成方針表の `CompanionsCommon/` を `Common/` に rename**: AGENTS.md 「`Companions/` 配下のサブツール dir は短縮」規約 (`Companions/Updater/` / `Companions/WindowProbe/`) と一貫させるため、`Common/` に短縮 (`Companions/` 配下に居る dir 名に再度 `Companions` を含めるのは冗長)。csproj 名 `GCTonePrism_CompanionsCommon` は disambiguation のため prefix 維持
- **[L4] CHANGELOG `## Manager v0.8.10` / `## Launcher v0.5.17` 冒頭に patch bump 判断根拠追記**: 配布構造変更を含むため SemVer 厳密だと minor 寄りだが、Install.bat の自動 migration で吸収するため user 視点で invisible → 0.x 系慣習で patch bump 扱い、と CHANGELOG 冒頭で根拠を明示
- **[L5 sentinel align] `:shortcut_failed_with_migration_note` の `if defined VAR echo` 空白を統一**: VAR 名長さに依存した手動 align (`MANAGER_MIGRATED` 2 個 vs `LAUNCHER_MIGRATED` 1 個) を空白 1 個に統一 + 「将来 sentinel 追加時に align が崩れる」リスクをコメントで明文化

#### Fixed (PR #150 シニアレビュー round 5)

- **[M1] `:shortcut_failed` ラベルが migration 完了状態を案内しない**: overwrite 経路で migration 成功 + shortcut copy 失敗のケースで、user が「shortcut が壊れたから手動で旧 dir 名でフォルダ作り直そう」と誤対処して migration を巻き戻す path があった。`:copy_failed` には「shortcut bat はすでに新版で配置済み」hint があるのに `:shortcut_failed` は非対称で「書き込み権限確認」だけだった。修正: round 3 M1 (`:migrate_failed_launcher` の `MANAGER_MIGRATED` sentinel 条件付き案内) と同パターンで、`:shortcut_failed` に `MANAGER_MIGRATED` / `LAUNCHER_MIGRATED` sentinel を確認する `:shortcut_failed_with_migration_note` 経路を追加。両 sentinel のいずれかが立っていれば「dir rename は完了済、旧 dir 名に戻さないこと」「Install.bat 再実行で続行可能、migration は冪等」を案内。`LAUNCHER_MIGRATED` sentinel も新規追加 (`:migrate_legacy_launcher` 成功時に set)

#### Changed (PR #150 シニアレビュー round 5)

- **[L1] `set INSTALL_MODE=overwrite` / `set INSTALL_MODE=new` を quoted set に統一**: Install.bat 冒頭 line 47-55 の規約「numeric sentinels だけが unquoted、path / user-input は quoted」に対し、`INSTALL_MODE` は `"overwrite"` / `"new"` の string sentinel で numeric ではないため quoted 形式が一貫する。実害は限定的だが、行末空白が紛れた場合に trailing space で `if "%INSTALL_MODE%"=="overwrite"` が false になる silent bug 余地。`set "INSTALL_MODE=overwrite"` / `set "INSTALL_MODE=new"` の quoted 形に修正
- **[L2] `:do_robocopy` ラベルを `:overwrite_set_mode` に rename**: ラベル名は「robocopy を実行する」と読めるが実体は `set INSTALL_MODE=overwrite` + `goto :copy_shortcuts` だけで、実際の robocopy は `:do_robocopy_overwrite` で行われる。round 3 L3 の flow 並び替え (migration / mkdir → copy_shortcuts → robocopy) で生じた名前と実態の乖離。`:overwrite_set_mode` に rename して「overwrite 経路の終端 sentinel」であることを明示
- **[L3] Manager csproj `<RootNamespace>` を `Manager` → `GCTonePrism.Manager` に**: AGENTS.md "Naming Conventions" で明文化した「C# namespace = `GCTonePrism.<Name>`」規約と csproj 設定が不一致だった。既存 30+ ファイルは全て `namespace GCTonePrism.Manager` 明示宣言なので実害なしだが、VS で新規ファイル scaffolding すると namespace 候補が `Manager` で出てきて新規 contributor が誤った namespace で書く余地があった。csproj 修正で scaffolding default も規約準拠に。msbuild Release で既存ビルド成功確認済 (既存 .cs は明示 namespace 宣言で影響なし)
- **[L4] SPEC §マイルストーン1 line 2604 を新 dir 名に**: 完了済 milestone の技術的達成項目に旧 dir 名 `GCTonePrism_Launcher/` / `GCTonePrism_Manager/` がそのまま残っていた pre-existing inconsistency。本 PR の dir rename sweep の一環で「Launcher/フォルダとManager/フォルダの作成 (旧 dir 名 ... から v1.10.9 でリネーム)」に更新

#### Acknowledged (PR #150 シニアレビュー round 5 L5)

- **PR #149 由来の「シニアレビュー round X LY」識別子の残存**: round 4 L3 で本 PR 由来の round tag を削除する catalog を出したが、PR #149 由来 (Phase 2 PR、`templates/Install.bat:98/101/116/488` および `templates/show_folder_dialog.ps1:34/49/64`) は本 PR scope 外として未 sweep。**意図的判断**: 本 PR の責務は dir rename + Companions 再定義 + Updater 役割再定義であり、過去 PR 由来のコメントスタイル sweep は別 cleanup PR の scope。本 PR では PR #150 由来分のみ削除 (round 4 L3) + 過去 PR 由来は据え置きで static inconsistency が意図的であることを明記

#### Fixed (PR #150 シニアレビュー round 4)

- **[H1] round 2 M2 の Launcher 側 begins_with regression**: `exe_path.begins_with(launcher_folder_check + "/")` 形式に変更したが、`exe_path = OS.get_executable_path().get_base_dir()` は **末尾 "/" を持たない** ため、正規 install 構造 (`<install>/GCTonePrism/Launcher/GCTonePrism_Launcher.exe` で base_dir = `.../Launcher`) で `begins_with(".../Launcher/")` が **常に false** を返す regression があった。priority-1 (prism.db) で base_directory は正しく取れているのに post-loop validation で false にひっかかり、Launcher 起動時に毎回 `push_error("実行ファイルが Launcher フォルダ内にありません")` が走る path。Manager 側 (.NET の `AppDomain.CurrentDomain.BaseDirectory` が末尾 `\` 付き) は偶然動いていたため round 2 では発覚せず。修正: 「等値 OR separator 付き begins_with」の二段比較 (`exe_path == folder OR exe_path.begins_with(folder + "/")`) に変更、Godot get_base_dir の trailing slash 無し仕様に対応。Manager 側も対称性 + .NET ランタイムの BaseDirectory 仕様変更への future-proofing のため同じ二段比較に揃えた。**今後 path_manager 系を編集する場合は実機 Launcher 起動でエラー出ないことを必ず確認すること** (DRY-RUN だけでは検出不能、本 PR で見落としたのと同じパターンを避けるため)
- **[M1] `:migrate_failed_launcher` メッセージが Manager 未存在ケースで誤情報**: 「Manager 側はすでに移行済」を無条件案内していたが、Manager 不在 case (旧 install で Manager 系のみ削除済 / partial extract 状態) では誤情報。`MANAGER_MIGRATED=1` sentinel を `:migrate_legacy_manager` 成功時にセット、`:migrate_failed_launcher` で `if defined MANAGER_MIGRATED echo ...` で条件付き化、3 状態 (skip / 成功 / fail [別経路]) を正しく分岐

#### Changed (PR #150 シニアレビュー round 4)

- **[L1] `:migrate_conflict_*` メッセージに「通常は新側を残す」推奨を追記**: 旧記述では「新側を残す」「旧側を残す」を対等選択肢として並べていたが、「旧側を残す」は実質ダウングレード操作で、Install.bat 再実行で結局 v0.3.0+ binary が上書きされるためデフォルトでは無効。「推奨: 新側を残す (通常はこちら)」「旧側を残す (v0.2.0 にダウングレードしたい場合のみ)」と推奨を明示、ダウングレードの結果も「結局 v0.3.0+ binary が入るので、v0.2.0 で運用したい場合は zip も v0.2.0 を使うこと」と明記。round 2 M1 で「user data merge 案内」を削除したのと同じ精神
- **[L2] CHANGELOG `## Launcher v0.5.17` / `## Manager v0.8.10` entry を round 2/3 内容含む形に拡張**: 旧記述は「self-reference リテラル修正」だけで、round 2 M2 (begins_with/StartsWith separator fix) や round 3 L1 (ends_with NOTE) の中身が CHANGELOG エンドユーザー側からは見えなかった。component 別エントリは「いつ何が入ったか」のインデックスとしても機能するため、ロジック改良の概要 + Release Tooling entry への参照を 1 行ずつ追加。Manager 側にも同様の begins_with → StartsWith 二段比較化追記
- **[L3] コメント内「PR #150 round X MY」識別子を削除**: コードコメントから「(PR #150 round 2 M2)」「(シニアレビュー round 3 L1)」等のタスク識別子を削除。WHY 説明 (sibling dir 名と prefix collision する等) は残し、識別子は CHANGELOG / git log / PR description 側で履歴を辿れるよう一方向参照に。コメントの rot を防ぐ
- **[L4] Release.ps1 TODO #101 の `<Launcher 補助 Companion>` を具体名 `WindowProbe` に**: SPEC §2.4 / #101 で具体名が確定済みなので generic placeholder のまま放置する必要なし。「#30 PauseOverlay 等が増えたら配列化」のコメント追記でスケール時の方針も明示
- **[L5] SPEC §3.7.6 step [6] の `release_notes/v<version>.md` 言及を CHANGELOG パースに修正**: v1.10.6 で `release_notes/` ディレクトリ廃止 → CHANGELOG を SoT 化したが、§3.7.6 step リストの該当行が更新漏れで残っていた pre-existing inconsistency。「`CHANGELOG.md` の `## Bundle` セクションから該当 Bundle entry をパース (旧仕様の `release_notes/` ディレクトリは v1.10.6 で廃止、§3.7.7 参照)」に修正

#### Fixed (PR #150 シニアレビュー round 3)

- **[M1] `:migrate_failed` 共通ラベルが partial-failure 時に不正確な手動復旧手順を案内していた**: Manager 移行成功 + Launcher 移行失敗のケースでも、`:migrate_failed` のメッセージが両方の rename 手順を案内していた。この時点で `<install>/GCTonePrism_Manager/` は既に rename 済 → 移動元が存在しないため user が指示通り作業すると「移動元が無い」と混乱する path。修正: `:migrate_failed_manager` / `:migrate_failed_launcher` の独立ラベルに分離、`:migrate_legacy_manager` の `if errorlevel 1` は `:migrate_failed_manager` に、`:migrate_legacy_launcher` の `if errorlevel 1` は `:migrate_failed_launcher` に飛ぶ形に変更。各ラベルは失敗側だけの手動 rename 手順を案内し、Launcher 失敗時は「Manager はすでに移行済」と状況も明示。round 1 M2 (`:migrate_conflict_*` 独立ラベル化) の精神と一貫
- **[L3] Install.bat: migration / mkdir → robocopy の間に partial-failure 窓があった**: 旧 flow は「migration / mkdir → robocopy → copy_shortcuts」順だったが、robocopy が partial failure (Ctrl+C / OS reboot / 権限エラー等) で中断されると、shortcut bat (`<親>/Launcher.bat` / `Manager.bat`) は旧 path `%~dp0GCTonePrism\GCTonePrism_Launcher\...` のままで実体は `<install>/Launcher/` に既に移動済 → user が Launcher.bat ダブルクリックで「ファイルが見つかりません」エラーになる経路があった。修正: shortcut copy を robocopy の前に統一移動し、両 path (overwrite / new_install) で「migration/mkdir → copy_shortcuts → robocopy → install_done」順に整理。`INSTALL_MODE` sentinel + `:do_robocopy_dispatch` で overwrite (`/XF /XD` 付き) と new_install (除外なし) を分岐させる構造に。`:copy_failed` メッセージにも「shortcut bat は新版で配置済み、Install.bat 再実行で復旧可能」を案内する hint を追記

#### Changed (PR #150 シニアレビュー round 3)

- **[L2] SPEC §3.7.3 step [10] + §3.7.4 Updater 自身の更新に判定方針を明文化**: 「変更ありの場合のみ Updater 置換」という記述に対して判定方法 (hash / manifest / version 比較 / 常に置換) が一切書かれていなかったため、Phase 4 Manager UI 実装時に手戻りリスクがあった。「**実装上は常に staging の新 Updater で置換する** (バージョン比較 / hash 確認による diff 検出は実装簡素化のため省略、Updater は 1〜2 ファイルの小規模 dir なので毎回 copy しても無視できるコスト)」と 1 文追加、両セクションで整合

#### Added (PR #150 シニアレビュー round 3)

- **[L1] `Launcher/scripts/path_manager.gd:56` の `ends_with` に NOTE comment 追加**: editor 起動時の fallback path で `ends_with("Launcher")` / `ends_with("GCTonePrism")` を使っており、文字列 prefix collision の余地はあるが、本 path は editor 専用 (`project.godot` 起動時の prism.db 未生成初期状態) で発火するため、実機 install 経路 (round 2 M2 で separator 付き begins_with に修正済) とは別。NOTE で「editor 文脈での false-match は project.godot の位置で project_root が自動決まるため実害低」と意図を明文化、issue #151 (priority-3 detection 強化) の scope に将来統合検討する旨を記載

#### Fixed (PR #150 シニアレビュー round 2)

- **[M1] `:migrate_conflict_*` メッセージが round 1 H1 で明文化した user data 実態と矛盾していた**: 「中身を merge → 手動で安全な方をベースに必要ファイルだけコピー」という選択肢を案内していたが、実際 `<install>/Manager/` / `<install>/Launcher/` 配下には binary しか入らず、merge すべき user data は存在しない (user data は `<install>/` 直下、§3.7.3「保護の仕組み」)。同 PR 内 H1 の趣旨 (誤った carry-over コードを書く失敗経路を防ぐ) と矛盾するため、Install.bat メッセージから merge 案内を削除、「どちらか一方を削除すれば足りる」「user data は `<install>/` 直下にあるので Manager/Launcher dir の削除と無関係に維持される」と明示する形に書き換え
- **[M2] PathManager priority-3 detection の `StartsWith` がパス区切り無しで prefix collision する bug**: `exePath.StartsWith(Path.Combine(currentPath, "Manager"))` (Manager) / `exe_path.begins_with(launcher_folder_check)` (Launcher) において末尾区切り (`Path.DirectorySeparatorChar` / `"/"`) を付与せずに比較していた。dir 名短縮で `"Manager"` / `"Launcher"` という generic 名になった本 PR では、`<install>/ManagerStudio/bin/...` のような兄弟 dir 名を誤検知する path が生じていた (round 1 L2 で acknowledged されていた priority-3 false-positive 余地の具体実装バグ)。修正: priority-3 fallback の StartsWith 比較を `managerCandidate + Path.DirectorySeparatorChar` / `launcher_folder_check + "/"` で行う形に変更 (Manager 内部の下流バリデーション `exePath.StartsWith(managerFolderPath, ...)` も同様)。issue #151 (priority-3 detection の汎用名化リスク) は引き続き複合 guard 追加の余地として残るが、本 round 2 M2 で StartsWith bug は閉じた

#### Changed (PR #150 シニアレビュー round 2)

- **[L1] Release.ps1 TODO コメントの曖昧な指示語を明確化**: 旧「`TODO Phase 3 (#108): Companions/Updater/ の build + staging を追加 (本 PR で着手予定)`」の「本 PR」が PR #150 と次 PR (`feature/updater-phase3`) のどちらを指すか曖昧で、将来 reviewer が「本 PR で着手と書いてあるが実装されていない、レビュー漏れ?」と誤読する余地があった。「次 PR `feature/updater-phase3` で着手予定」に書き換え
- **[L2] CHANGELOG v0.1.10 entry のセクション順を「主変更 → review fix」に並び替え**: 旧順は `Fixed (round 1)` → `Changed (round 1 M1)` → `Acknowledged (round 1 L2)` → `Changed (主変更)` で、エンドユーザーが「v0.1.10 は何が変わったの?」と確認する時に最初に目に入るのが副次的な review fix で本筋の主変更が下に隠れていた。「Changed (主変更)」を先頭に、その下に review fix 群を続ける順に整理 (本 round 2 で他 PR との order 一貫性も担保)

#### Fixed (PR #150 シニアレビュー round 1)

- **[H1] SPEC §3.7.3 / §3.7.4 の user data 保護記述が実態と乖離していた**: 「Manager 側 / Updater 側ともに rename-rollback の `.bak` から保護対象を新 dir に carry-over する形で保護を実現」と記述していたが、実際の user data (`prism.db` / `games/` / `backups/` / `responses/` / `logs/`) は `<install>/` 直下に配置されていて Manager / Launcher dir の外。`Manager/` を `.bak` にリネームしても `.bak/prism.db` は存在せず carry-over 対象自体がない。**実際の保護機構は構造的なもの** (user data が component dir の外にあるので、各 component dir の置換と無関係に残る)。Phase 3 / Phase 4 の実装者がこの誤った記述を信じて余計な carry-over コードを書くと no-op になるか Manager 内部の設定ファイル等を user data と勘違いする path があった。修正: §3.7.3 step [13] のコメントを「user data は `<install>/` 直下にあるので置換と無関係に残る」に書き換え、「**保護されるユーザーデータ**」段落に「保護の仕組み」サブ項目を追加して「`<install>/` 直下配置による構造的保護 vs `.bak` (binary atomic rollback 用) の役割分離」を明文化。§3.7.4 Updater 責務 (3) も同期
- **[M2] Install.bat migration が「新 dir も既存」のケースで silent failure する path**: Windows の `move srcdir dstdir` は dst が既存ディレクトリの場合、エラーで失敗するのではなく **src を dst の中にネスト移動** (`dst\src\` を作る) する挙動を取るバージョン / シェル組合せがある。errorlevel 0 で済んで `:migrate_failed` には飛ばず、`<install>/Manager/GCTonePrism_Manager/` の壊れたネスト構造ができたまま `:do_robocopy` が走り、ユーザーに見えにくいゴミが堆積する path。発生シナリオは v0.3.0 install + 過去 zip バックアップ復元 / partial install 再試行など theoretical だが silent 性が高い。修正: `move` の前に `if exist "<new>\" goto :migrate_conflict_<name>` の事前 destination-exists ガードを追加、両 dir 並存時は user に手動判断を促す `:migrate_conflict_manager` / `:migrate_conflict_launcher` ラベルで `:fail` に倒す
- **[L1] SPEC 変更履歴 v1.10.9 の旧仕様引用 path ミス**: (b) 項で「旧仕様「Launcher 専用サブコンポーネント、`Launcher/Companions/` 配下」」と書いていたが、旧仕様 (v1.10.3〜v1.10.8) の実 path は `GCTonePrism_Launcher/Companions/`。§2.4 「旧仕様との差分」段落とも不一致だった。修正

#### Changed (PR #150 シニアレビュー round 1)

- **[M1] Manager v0.8.10 + Launcher v0.5.17 への version bump**: PR #150 の PathManager.cs / path_manager.gd の self-reference リテラル変更は **runtime 動作変更** (新 binary は旧 install 構造を正しく解決できない / 逆も同様)。AGENTS.md 「Release and Versioning」§ の「コミット直前に各 binary version 番号を上げるべきかを必ず提案する」規約に従い、Manager / Launcher 共に patch bump + CHANGELOG `## Manager` / `## Launcher` 各セクションに entry 追加

#### Acknowledged (PR #150 シニアレビュー round 1 L2)

- **PathManager priority-3 detection の汎用名化による false-positive 余地** (issue #151): dir 名短縮で `"Manager"` / `"Launcher"` は他アプリ / 他配置でも一般的な名前になり、priority-1 (`prism.db`) / priority-2 (`.git`) がともに hit しない極限状況での誤判定余地が増えた。round 1 時点では `exe_path.StartsWith(...)` ガードで実害は限定的としていたが、round 2 M2 でその StartsWith 自体に separator 不付与の prefix collision bug が発見され同 PR で fix 済。残る issue (#151) のスコープは複合 guard (sibling `Launcher/` + `Manager/` の同時存在検証 / prism.db への parent 一致等) による強化

### [Release Tooling v0.1.9] - 2026-05-12

#### Fixed (PR #149 シニアレビュー round 5)

- **[M1] `isInteractive` 検出ロジックの catch reset が片側判定の non-interactive を上書きする silent path**: round 4 で導入した non-interactive 検出ブロックで、`[Environment]::UserInteractive` が `$false` 確定後に `[Console]::IsInputRedirected` getter が non-console host で例外を投げると、catch が `$isInteractive = $true` で上書きする path があった。WSH host / カスタム PS host で `UserInteractive=$false` だが IsInputRedirected getter が IOException を投げる → catch で reset → Read-Host 空文字 → exit 3 silent skip という、本修正が解消したかった silent path に戻ってしまう構造。修正: 各 API を独立 try で取得し最後に AND 合成 (`$ui = try { ... } catch { $true }` / `$inputRedirected = try { ... } catch { $false }` / `$isInteractive = $ui -and -not $inputRedirected`)。片側 API 失敗が他方の確定判定を巻き戻さない構造に
- **[M2] exit 3 メッセージの「ビルドキャッシュは温存」表現が実装と乖離**: round 4 L4 で tag conflict path と表現統一した結果、「Godot export / msbuild は再実行されず、zip のみ再生成」と書いてしまったが、実装上は `Build-Launcher` / `Build-Manager` が毎回呼ばれ、`Clear-Staging` で staging も毎回削除、`bin\Release\` も clean build される。温存されるのは `tools/godot/` / `tools/nuget.exe` の **DL キャッシュ** のみで、Godot export / msbuild 出力は実際には再生成される。修正: 両 path のメッセージを「再 build (Godot export / msbuild) は走るが、Godot / nuget の DL キャッシュは温存されるため初回より速い」と正確化、Resolve-TagConflict 側も「再 build は走るが DL キャッシュは温存」と同じ表現に統一

#### Changed (PR #149 シニアレビュー round 5)

- **[L1] Install.bat:59 `set "EXIT_CODE=0"` → `set EXIT_CODE=0`**: numeric 規約 (line 51-55 で明文化済の「quote rule applies to path / user-input values, not to numeric flags」) を自分で破っていた 1 箇所を是正。`:fail` の `set EXIT_CODE=1` と表記揃え、他の numeric sentinel (`MANAGER_FOUND` / `LAUNCHER_FOUND` / `MANAGER_STARTED`) と一貫
- **[L3] SPEC §3.7.2 入れ子検知に case-insensitive を明記**: 実装 (`if /i not "..." == "GCTonePrism"`) は case-insensitive だが SPEC は厳密 case-sensitive にも読めた。「比較は case-insensitive、`gctoneprism` / `GCTONEPRISM` も検出する。Windows の伝統的 path 比較に合わせる」と一文追加、将来 case-sensitive fs (ReFS / WSL) で挙動が変わる場合の参照点を明示
- **[L5] INSTALL_README の copy 失敗 Q&A を 2 path で区別**: 旧 Q&A は `:copy_failed` (files/ → GCTonePrism/ の robocopy 失敗) だけを想定した記述で、`:shortcut_failed` (Launcher.bat / Manager.bat → `<親>/` の copy 失敗) の場合の権限確認先が異なる点に触れていなかった。「ファイルコピーに失敗」(GCTonePrism\ 配下の書き込み権限) と「ショートカット bat のコピーに失敗」(`<親>` 自体の書き込み権限) を別 Q&A に分離、学校サーバーで `<親>` のみ制限つきの稀ケースを救う

#### Added (PR #149 シニアレビュー round 5)

- **[L2] `show_folder_dialog.ps1` に try/finally Dispose 追加**: `FolderBrowserDialog` は `IDisposable` 実装、短命プロセスで GC でも回収されるが、`ShowDialog` 中の COM 例外 / Add-Type 後の例外 path で確実に native handle を解放するため明示 Dispose。catch 経路 + 通常終了経路の両方で `$d.Dispose()` が呼ばれる
- **[L4] `show_folder_dialog.ps1` に `Set-StrictMode -Version Latest` 追加**: Release.ps1 (line 93) との整合性。$d が null 状態で property assign に至った場合に明確なエラー surface、silent runtime fault を防ぐ防御強化

#### Fixed (PR #149 シニアレビュー round 4)

- **[M2] robocopy コメントが「ユーザーデータ保護の主機構」を誤って伝える bug**: 旧コメントは `/XF` `/XD` を保護の主軸として説明していたが、実際に user data (prism.db / games / backups / responses / logs) を保護しているのは **robocopy の default 非ミラー挙動** (dest 側にあって source にないファイル / ディレクトリは touch しない) であり、`/XF /XD` は「source 側に勘違いで同名ファイル / ディレクトリが混入した場合の defense-in-depth」に過ぎない。現状 source (`files/`) には保護対象名は入らないので `/XF /XD` は 実質 no-op。誤解の害: 将来「コピー効率化のため `/MIR` 追加」を検討した時に「`/XF /XD` があるから user data は守られる」と誤判断 → `/MIR` の "source にないものを削除" 挙動で user data が即削除される silent path。修正: コメントを「PRIMARY protection = default 非ミラー挙動 / `/XF /XD` = defense-in-depth / **`/MIR` 追加禁止**、必要になった場合は `/XO` + pre-copy snapshot + SPEC §3.7.3 と同期」の警告文に書き直し
- **[M3] `Read-Host` が non-interactive 環境で silent exit 3 になる bug**: Y/N upload prompt は対話前提だが、`Read-Host` は stdin redirect / 端末なし環境で空文字列を返し、`'^(y|yes)$'` regex に一致しないため exit 3 (= N 回答 skip) で終了する。CI で `-SkipUpload` 付け忘れた場合、エラーメッセージなしで Warn 行のみ出して silent skip。exit code 体系 (2 = env state, 3 = user 判断) の区別も崩れる。修正: Read-Host 前に `[Environment]::UserInteractive` + `[Console]::IsInputRedirected` で non-interactive を検出し、検出時は明示的に `Fail "non-interactive environment: -SkipUpload / -DryRun 未指定で Read-Host を呼ぼうとしました"` (exit 1) で abort、`-SkipUpload` または `-DryRun` を案内する Write-Info 付き
- **[M1] Launcher.bat の `exit` 採用理由コメントが Launcher.bat の文脈で literally false**: 旧コメントは「Install.bat が Manager を起動する経路で residual cmd window 問題が出た」と書かれており、Manager.bat の文脈では正しいが Launcher.bat 自体は Install.bat の auto-start path から呼ばれない (Install.bat に Launcher 起動経路はない) ため事実関係がそのまま当てはまらない。copy-paste 痕跡で未来の保守者が「Launcher.bat も Install.bat に呼ばれているのか」と誤解する path。修正: 「leaf shortcut (他 bat の building block ではない) として Manager.bat と同じ `exit` discipline を予防的に適用」「観測された residual cmd 問題は Manager 経路のみ、Launcher.bat 自体は forward-looking consistency choice」と書き直し、参照は Manager.bat docstring に集約

#### Changed (PR #149 シニアレビュー round 4)

- **[L1] SPEC §3.7.5 「階層変更」表現を修正**: 旧記述「Phase 2 で `GCTonePrism/Launcher.bat` から `<親>/Launcher.bat` に階層変更」は、リリース歴を辿る読者に「以前は `GCTonePrism/Launcher.bat` として配布されていた」と誤解させる。実際には `GCTonePrism/Launcher.bat` 配置は PR #149 内の中間コミット時点の設計で published version 履歴ではない。「Phase 2 で `<親>/Launcher.bat` 直下配置として新規導入、初期案では `GCTonePrism/Launcher.bat` も検討されたが published 前に確定」と整理
- **[L2] Install.bat の `set /p` プロンプト内の `(Y/N)` を `[Y/N]` に統一**: line 19 docstring rule の「echo arguments MUST NOT contain literal `(` or `)`」を echo に限定して書いていたが、`set /p` プロンプトでも `(Y/N)` を露出させていた整合性欠如。`set /p` parser も内部的に block 解釈と独立している保証は薄く、将来の cmd 挙動変化への安全マージンとして `(` `)` 禁止ルールを `echo / set /p prompt` 両方に拡張。既存の 2 箇所 (`OVERWRITE_CONFIRM` / `START_MANAGER` プロンプト) も `[Y/N]` に置換
- **[L4] exit 3 N 回答メッセージを tag conflict path と表現統一**: 旧文言「同 zip を再生成」が「ファイルが消える → 再作成」と誤読されやすかった。「ビルドキャッシュは温存され、Godot export / msbuild は再実行されない (zip のみ再生成で retry は速い)」と tag conflict graceful exit path の説明と同じ表現に揃え、技術的に正確な記述に統一
- **[L5] PR description の "Known untested" を UNC share root と sub-path で区別整理**: 旧表記は `\\学校サーバー\PCクラブ` を UNC root の例として挙げていたが、`PCクラブ` が share name か sub-path か曖昧。本当に未テストなのは share root 直接選択 (`\\server\share` 形式) のケース。`\\server\share\sub` は通常 path 扱いで edge case ではない、と区別。**ドライブルート (`C:\` 等)** も追加で Known untested に明記、leaf extraction が空文字列を返して INSTALL_TARGET= drive root + GCTonePrism で続行し、mkdir が権限不足で graceful fail する path を docstring 化

#### Added (PR #149 シニアレビュー round 4)

- **Install.bat docstring の leaf extraction edge case 注記 (L3)**: `for %%F in (...) do %%~nxF` がドライブルート (`D:\`) と UNC root (`\\server\share`) で divergent な値を返す挙動を明文化、各ケースの後段挙動 (drive root mkdir 権限失敗 / UNC share-as-folder 続行) を `:nest_check` 周辺コメントに記述
- **Install.bat docstring の structural rule (2) を `set /p` 含む形に拡張**: 「echo / set /p prompt arguments MUST NOT contain literal `(` or `)`」「even top-level placement isn't formally guaranteed by docs against future cmd version changes」と一貫性を明記

#### Fixed (PR #149 シニアレビュー round 3)

- **[M2] `:dialog_fail` 経路で PS stderr (実際の失敗理由) が捕捉されていなかった bug**: 旧実装は `> "%TEMP_DIALOG_OUT%"` で stdout のみリダイレクト、stderr は親 cmd console に直流していた。インタラクティブ実行では人間が画面で見られるが、Phase 3 Updater が `cmd /c install.bat > log.txt 2>&1` で呼ぶ運用に入ると stderr 行は log に残らない (= 自動化呼出しで診断情報が失われる) silent path。`show_folder_dialog.ps1:catch` の `[Console]::Error.WriteLine` 出力も同じ理由で消える。修正: `> stdout.tmp 2> stderr.tmp` に分離キャプチャ、`:dialog_fail` で `PS stderr の内容:` + `PS stdout の内容:` を順に表示。`:dialog_ok` / `:dialog_cancel` でも err tmp ファイルを cleanup
- **[M3] Manager 自動起動経路が SPEC §3.7.5 の「日常起動は Manager.bat 経由」規約を bypass していた**: round 2 で「Manager.bat 経由だと中間 cmd 残骸が出る」問題を「Manager.exe 直叩き」で回避していたが、SPEC で規約として明文化した「日常起動は Manager.bat 経由」を Install.bat の auto-start path だけ破る silent inconsistency。将来「Manager.bat 内で working dir 設定 / 環境変数 export / ログ転送」等を追加した時に auto-start 経路だけ漏れる path を防ぐため、規約準拠側に揃え直す。修正 2 段:
  - **Manager.bat / Launcher.bat 末尾に `exit` 追加**: 中間 cmd 残骸の根本原因 (Manager.bat の cmd プロセスが `start "" Manager.exe` 後も "次の行" を待ってアイドル) を Manager.bat 側で解消。`start` で Manager.exe を detach した後は cmd が do nothing なので、`exit` で cmd を強制終了 → 親 (Install.bat) から見ても子 cmd は即時終了 → window 残骸なし
  - **Install.bat auto-start を Manager.bat 経由に復元**: `start "" "%INSTALL_TARGET%\GCTonePrism_Manager\GCTonePrism_Manager.exe"` → `start "" "%INSTALL_PARENT_NO_TRAIL%\Manager.bat"`。SPEC §3.7.5 と整合し、Manager.bat lifecycle 変更時の漏れ path を解消
  - trade-off: `call Manager.bat` で呼ぶと caller bat も `exit` で巻き添えで終了する。Manager.bat / Launcher.bat は leaf shortcut (他 bat の building block ではない) という前提で許容、docstring に明記
- **[M4] `Resolve-TagConflict` 既存タグ検出 / Y/N の N で `exit 0` が「成功」と「skip」を区別不能だった bug**: caller (CI / 上位 script) から見ると `Release.bat` の `exit 0` が「publish 成功」「tag 衝突で skip」「N で skip」のいずれかを区別できない。CI で `.\Release.bat -SkipUpload:$false` 回しても、tag 衝突で publish せず exit 0 を返すと CI は緑になる silent path。同 PR 内で「誤 publish 防止優先」(Y/N 完全一致マッチ) と書きながら「期待通り publish できたか」を caller が exit code で検出できない設計矛盾。修正: exit code 体系を細分化:
  - `0` = success (publish 成功 / `-SkipUpload` / `-DryRun`)
  - `1` = failure (script の本来失敗: build / publish / env)
  - `2` = skip (tag conflict + `-Force` なしによる publish skip、env 起因)
  - `3` = skip (Y/N の N 回答による intentional skip)
  - Release.bat 側も 4 状態を区別表示 (`正常終了` / `publish skip [exit 2: ...]` / `publish skip [exit 3: ...]` / `[FAIL]`)、exit code はそのまま透過
- **[L1] `Release.ps1:940` のコメントで関数名が `Assert-NoTagConflict` (実体 `Resolve-TagConflict`)**: 同 PR 内で命名 divergent、Resolve-TagConflict に修正 + コメント内容も最新の "zip 完成後 / Y/N upload prompt の前に呼ぶ" 配置説明に更新

#### Changed (PR #149 シニアレビュー round 3)

- **[M1] CHANGELOG `### [Release Tooling v0.1.9]` の `#### Added` を最終形に書き換え**: 旧記述は round 1 時点の事実を残しつつ round 2 までの修正を `#### Fixed` に追記する累積型だったため、同一 version エントリ内で「`<親>\GCTonePrism\Launcher.bat` 配置」(Added) vs 「1 階層上に変更」(Fixed)、「`chcp 65001` save/restore」(Added) vs 「cp932 staging で chcp 撤去」(Fixed)、「ExpectedFiles 12 件」(Changed) vs 「13 件」(別 bullet) が並存して読みづらかった。AGENTS.md "1 PR 1 bump、レビュー対応コミットでは既存エントリの description を加筆・修正" 規約に従い、`#### Added` 側を最終形 (`<親>/` shortcut + cp932 staging + ExpectedFiles 13 件 + `show_folder_dialog.ps1` 同梱 + `exit` 終端 + Phase 3 起動規約) に書き換え、journey 自体は `#### Fixed` 各 bullet に残す形に整理
- **[L3] FolderBrowserDialog SelectedPath の trailing whitespace 防御コメント**: `:dialog_ok` の `set /p INSTALL_PARENT=<...` 直前に「.NET 4.x の SelectedPath は trailing space を付けない実装で確認済、問題化したら whitespace trim を入れること」を明記、将来の OS / .NET 変更に対する fail-safe ガイドラインを残す
- **[L4] `%TEMP_DIALOG_OUT%` / `%TEMP_DIALOG_ERR%` の衝突確率を 1/32K → 1/1G に低減**: 旧実装は `%RANDOM%` 単独 (15-bit、1/32768)、新実装は `%RANDOM%%RANDOM%` (30-bit、1/1G 弱)。インタラクティブ double-click 想定のため並列実行はまずないが、「ユーザー誤って 2 回 double click → 前回 instance がまだ dialog 待ち」のケースで tmp ファイル shared → `set /p` が前回 path を inherit する silent bug を構造的に低減

#### Added (PR #149 シニアレビュー round 3)

- **SPEC §3.7.8 チェックリスト「Updater」項目に Phase 3 Install.bat 起動規約を追加 (L5)**: 「`Process.Start("cmd", "/c install.bat ...")` 形式必須、`call` 形式 / 直接起動禁止、理由は §3.7.4」を着手前チェック項目として明示。AGENTS.md から本節へのリンク済みなので、Phase 3 着手時に自然と参照される導線が確保される

#### Fixed (PR #149 シニアレビュー round 2 + Codex P1/P2 round 2)

- **[Codex bot P1] `show_folder_dialog.ps1` setup エラーが Cancel と区別不能 → real failures が exit 0 に丸まる bug**: `Add-Type` / `New-Object` / property 代入の非終了エラー後も `if ($d.ShowDialog() -eq OK)` 行に到達し、`$d` が null だと else 分岐に流れて `exit 2` (user cancel と同じ) を返してしまう問題。Install.bat 側は exit 2 を Cancel として処理して `goto :end` (成功扱い、exit 0) するため、自動化呼出し / Phase 3 Updater から見ると「ユーザがキャンセルした」のか「PS が壊れた」のか区別不能だった。`$ErrorActionPreference = 'Stop'` で非終了エラーを終了エラーに昇格 + try/catch で Add-Type 〜 ShowDialog を囲み、catch 時は stderr にメッセージ + `[Environment]::Exit(1)`。Install.bat 側の 3-way dispatch (0/2/else) で exit 1 は自動的に `:dialog_fail` に流れるので bat 側修正不要。exit code の意味 (0=OK / 1=catch / 2=Cancel / その他=PS host 起動失敗) を冒頭コメントに追記
- **Install.bat の残骸 cmd window 問題 (Manager 自動起動 Y 経路のみ)**: 「だいたい問題なくなったけど、最後に残骸だけ残る」報告対応。原因 2 段。
  - **段 1: `exit /b %EXIT_CODE%` → `exit %EXIT_CODE%`**: ダブルクリック起動 (`cmd /c install.bat`) では `exit /b` で caller cmd が追従終了するはずだが、Windows Terminal 等一部の terminal host で空 prompt が残るケースがあった。`exit` (without `/b`) で cmd プロセスを直接終了させ、window を統一的に閉じる。トレードオフ: 将来 `call install.bat` を書くと caller bat も巻き添えで終了するため、SPEC §3.7.4 Updater 仕様に「`Process.Start("cmd","/c install.bat ...")` 経由で呼ぶこと」を明記 (シニアレビュー L3)
  - **段 2: `start "" "Manager.bat"` → `start "" "Manager.exe"` 直叩き**: 段 1 でも Y 経路のみ window 残存が継続。Manager.bat は単に `start "" "...Manager.exe"` する 2 行 wrapper のため、Install.bat から `start "" Manager.bat` すると中間 cmd プロセスが一瞬発生 → Windows Terminal がそれを子プロセスとみなして Install.bat の window を「終了待ち」状態に保持していた。直接 Manager.exe を `start ""` することで中間 cmd を排除し、Install.bat 終了後に親 window がクリーンに閉じる。Manager.bat 自体は `<親>/` 直下の日常起動用として残り、機能影響なし
- **INSTALL_README.txt 冒頭文言の組織名誤読対策**: 旧「ゲームセンターTONE 開発の Prism ランチャーシステム」は「ゲームセンターTONE という会社/組織が開発した」と読めてしまっていた。ゲームセンターTONE は文化祭企画の名前なので、「文化祭企画『ゲームセンターTONE』の Prism ランチャーシステム」に修正

#### Changed (PR #149 シニアレビュー round 2)

- **[M1] 1 PR 1 bump 規約に整合**: SPEC 変更履歴の v1.10.9 (ショートカット bat 1 階層上 relocation) を v1.10.8 (Phase 2 元仕様) に統合。両方とも同じ「Phase 2 / #108」スコープで breaking change でも別関心事でもないため、AGENTS.md "CHANGELOG Section Roles" の規約 (1 PR 1 bump、レビュー対応コミットでは既存エントリの description を加筆) に揃える
- **[M2] Y/N 判定の寛容度を Release.ps1 と統一**: Install.bat の `OVERWRITE_CONFIRM` / `START_MANAGER` は `if /i "%X%"=="Y"` で **Y/y のみ受理** だったため、Release.ps1 の Y/N upload prompt (`y/yes` 両受理) を触っているユーザーが「yes」と打って意図せず abort する path があった。Install.bat の 2 箇所も `Y` / `YES` 両方を受理する形に拡張、INSTALL_README にも「Y / y / yes」明示
- **[M3] `Resolve-TagConflict` の network 失敗 path にも zip path 案内を追加**: 既存タグ + `-Force` なし時は graceful exit + zip path 案内だったが、gh release view の auth/network 失敗時は `Fail` で exit 1 のみで zip path を案内せず「ビルド完了 → ネットワーク一時障害 → Fail → ユーザー: zip が捨てられたと誤解」する path があった。Fail 直前に `Write-Info "zip は $ZipPath に残っています"` を追加、graceful exit path と同じ "publish 失敗とは独立して zip は流用可" メッセージで統一
- **[M4] Install.bat 最終 pause を日本語化**: 周囲が全て日本語 UX なのに cmd default の "Press any key to continue . . ." だけ英語だった一貫性破れ。`pause >nul` + `echo  何かキーを押して終了します...` の 2 行に置換、文言を制御
- **[L1] set quoted/unquoted の規約コメント追記**: line 44-46 で「path-derived は quoted set 必須」と宣言しつつ numeric sentinels (`MANAGER_FOUND` / `LAUNCHER_FOUND` / `MANAGER_STARTED` / `EXIT_CODE`) は unquoted という不整合が将来 maintainer を混乱させる懸念。「quote rule applies to path / user-input values, not to numeric flags」とコメントで明文化、混在の合理化を行った
- **[L2] PR #149 description の検証ログを最新化**: ExpectedFiles 12 → **13** (`show_folder_dialog.ps1` 追加で +1)、staging 構造の記述も最新の `<親>/` ショートカット bat 配置に同期、検証 Stage 3 の "deferred" を実機 E2E 完了済みにマーク
- **[L3] SPEC §3.7.4 Updater に Install.bat 起動方式を明記**: `Install.bat` 終端の `exit` (not `exit /b`) は `call install.bat` で呼ぶと caller bat も巻き添えで終了する silent danger があるため、Phase 3 Updater は `Process.Start("cmd", "/c install.bat ...")` 形式で呼ぶこと、を SPEC 側にも明記。bat 末尾の REM コメントだけだと埋もれる懸念があり、SPEC の Updater 責務節に格上げ
- **[L4] `:wait_close` の unbounded loop を docstring に明記**: Manager.exe / Launcher.exe を user が close できない場合 (hung process / 別 session / 権限不足) Ctrl+C しか退出手段がない設計を **意図** として docstring 化。Phase 2 の対象 (人がダブルクリック) では「インストーラが固まっている、なぜ?」と気付かせる方が auto-fail で原因を隠すより良いという根拠と、Phase 3 Updater が forced termination の責務を持つ役割分担を明記。将来 unattended re-install フローで問題化したら max-iterations 追加の hint も併記
- **[L5] INSTALL_README に shortcut bat 上書き注意を追加**: 再 install (上書き Y) で `copy /Y` により `<親>/Launcher.bat` / `<親>/Manager.bat` が無条件上書きされる挙動を README の「緊急アップデート」項目に明記。ゲームデータ保護リストと並べて wrapper bat も列挙し、カスタマイズ消失の path をユーザに事前認知させる

#### Fixed (PR #149 シニアレビュー round 1 + Codex P2)

- **[Codex P2] FolderBrowserDialog 選択パス内の `!` 文字が delayed expansion で破壊される bug**: `Install.bat` 全体で `setlocal enabledelayedexpansion` を有効化していたため、選択パスに `!` が含まれる場合 (例: `D:\Backup!\` 等のユーザー命名パス) に `for /f ... do set INSTALL_PARENT=%%P` の段階で `!` が delayed expansion token として解釈され削除される。本ファイル refactor 後は `!VAR!` 参照が実質ゼロのため、`setlocal disabledelayedexpansion` に変更して構造的に解消
- **PR #149 Codex bot review 対応 (P2 #4 #5 #6)**:
  - **P2 #4**: `INSTALL_PARENT` が caller env から inherit して `set /p` が input なしの場合に stale 値で続行する path を解消。`set "INSTALL_PARENT="` を dialog 起動 *前* に追加して initialize
  - **P2 #5**: `set SCRIPT_DIR=%~dp0` / `set FILES_DIR=...` の unquoted 形式は zip 展開 path に `&` 等の cmd metachar (例: `D:\R&D\`) が含まれると line split で abort する path だった → `set "VAR=value"` quoted 形式に統一
  - **P2 #6**: `echo %INSTALL_TARGET%` 等 user-controlled path を出力する 7 箇所の echo を `echo "%VAR%"` 形式に変更。`%VAR%` 展開後の path に `&` 含むと cmd の multi-command split で異常出力 / fragment 実行になる path を解消。引用符付きの出力 (`インストール先: "D:\Games\GCTonePrism"`) になるが、edge case 防御として allowed
  - **過去 review で既に解消**: P1 #1 (overwrite-process delayed expansion) は top-level goto refactor 済、P2 #2 (path 内 `!`) は disabledelayedexpansion 済、P2 #3 (PS 失敗 vs Cancel) は 3-way dispatch 済
- **Install.bat の cmd parse cascade 問題を根本解決: staging encoding を cp932 (Shift-JIS) に変換**: ユーザー実機テストで何度試しても解消しなかった「`'�に'` `'em.Windows.Forms'` `'��データは維持されます:'` 等の 'is not recognized' 連鎖エラー + Manager 起動後の黒画面残存」の根本原因が判明: **`chcp 65001` は console output codepage のみ切り替え、cmd の bat ファイル parser は **システム codepage** (JP Windows = cp932) で読み続ける** 仕様。UTF-8 で書かれた長文 Japanese echo (`Manager が壊れて起動できない / クリーンインストールしたい場合のみ Y を押してください。` 等 30+ chars) の byte 境界を parser が mis-tokenize → cascade。修正:
  - **Release.ps1 Copy-Templates が .bat staging 時に UTF-8 → cp932 変換**: cmd の system codepage と一致するので parser が natively 読める。長文 Japanese 行も安全に処理。デメリットの非 JP Windows での mojibake は JP 校内向け配布なので OK
  - **Install.bat から `chcp 65001` ロジック撤去**: cp932 file ↔ cp932 system で一致するため不要。同時に「ASCII boundary rule」も削除 (codepage 切替がないので boundary 自体存在しない)
  - **Install.bat docstring の構造規約 (1)(2)(3) は維持**: cmd parser の `(...)` block / literal `(` / inline 日本語の各 quirk は cp932 でも残るので、引き続き必要
  - 副次効果: Manager 自動起動後の黒画面残存も解消 (parser cascade で `start` の後始末が狂っていたのが root cause だった)
- **ショートカット bat (`Launcher.bat` / `Manager.bat`) の配置を 1 階層上に変更** (ユーザー UX 要望):
  - 旧: `<親>/GCTonePrism/Launcher.bat` (部員が `GCTonePrism/` サブフォルダに入る必要があった)
  - 新: `<親>/Launcher.bat` (`<親>` を開けば即ダブルクリック可能)
  - インストール後の見た目: `<親>/Launcher.bat` + `<親>/Manager.bat` + `<親>/GCTonePrism/` が並ぶ
  - zip 内構造: `files/Launcher.bat` → zip ルートの `Launcher.bat` に移動 (`files/` は component 本体専用に)
  - Install.bat: `:copy_shortcuts` label を追加し、files/ → `<親>/GCTonePrism/` の robocopy 後に zip ルートの `Launcher.bat` / `Manager.bat` を `copy /Y` で `<親>/` に配置
  - Launcher.bat / Manager.bat 内 path: `%~dp0GCTonePrism_Launcher\...` → `%~dp0GCTonePrism\GCTonePrism_Launcher\...` (1 階層分の親パス追加)
  - Manager 起動 Y/N の `start` path: `%INSTALL_TARGET%\Manager.bat` → `%INSTALL_PARENT_NO_TRAIL%\Manager.bat` (`<親>/Manager.bat`)
  - Release.ps1 Copy-Templates: `filesTemplates` を空配列に、`rootTemplates` に Launcher.bat / Manager.bat を追加
  - Assert-ExpectedFiles: `files\Launcher.bat` / `files\Manager.bat` → zip ルートの `Launcher.bat` / `Manager.bat`
  - INSTALL_README.txt: 日常使い path 例 (`D:\Games\Launcher.bat`) に更新
  - SPEC §3.7.1 (zip 構造 + インストール後構造) + §3.7.5 (Launcher 日常起動 path) を更新、変更履歴は v1.10.8 entry に統合 (1 PR 1 bump 規約、シニアレビュー M1)
- **Install.bat の cmd parser 問題を構造的に解消 (`.ps1` 切り出し + `[...]` 使用)**: 数回の試行錯誤を経て、根本原因は (a) 長い `set "PS_DIALOG_CMD=...日本語..."` の Japanese byte 列が cmd の line tokenize を壊し PS に malformed command を渡す、(b) `set "..."` 内の `^|` が literal で残り PS に届く (cmd quoted set では `^` 非 escape)、(c) `echo (text)` の `(` が cmd で block 開始と解釈される、と判明。これらを構造的に回避:
  - **PS dialog code を `templates/show_folder_dialog.ps1` に切り出し**: cmd parsing を経由せず PS native の UTF-8 処理に任せる。Japanese description (`'GCTonePrism のインストール先の親フォルダを選択してください'`) を維持可能。Install.bat 側は `powershell.exe -File "%~dp0show_folder_dialog.ps1"` で起動するだけ
  - **echo の `(` `)` を `[` `]` に置換 (14 箇所)**: `[` `]` は cmd で escape 不要、`^(` `^)` の top-level 不安定挙動を回避
  - **Release.ps1 Copy-Templates**: .ps1 を **UTF-8 BOM + CRLF** で staging に書き出し (PS 5.1 default の ASCII 読み込みで Japanese mojibake を防ぐため BOM 必須)
  - **Assert-ExpectedFiles**: 12 → 13 件 (`show_folder_dialog.ps1` 追加)
  - **Install.bat docstring の構造規約 (3) 新規追記**: 「PS 起動の引数で日本語を含む長い文字列を inline しない、別 .ps1 に切り出して `-File` 経由で起動する」を明文化、将来 maintainer が誤って inline に戻すのを防ぐ
- **Install.bat 実行時に「'em.Windows.Forms' is not recognized」等 cmd parse error が連発する bug**: ユーザー実機の testing で、Install.bat が `[FAIL] PowerShell が exit 0 を返しましたが選択パスが取得できませんでした` と並んで `'��よう' is not recognized` `'em.Windows.Forms' is not recognized` `'場合は' is not recognized` 等の cmd error が散発した。原因: cmd は `if cond (echo 日本語... goto :fail)` のような `(...)` ブロックを parse-time に展開する際、UTF-8 で書かれた日本語の byte 列を mis-tokenize して fragment を command として実行する動作。chcp 65001 が success していても、cmd の bat parser はブロック展開時に system codepage (cp932 on JP Windows) で byte を解釈する余地があり、Japanese 含む `(...)` block が壊れる。welcome 等 top-level の echo は正常動作するが、`if (...) echo ... goto :fail` パターンは全滅。
  - 修正: 全 `(...)` ブロック内の Japanese echo を **top-level goto pattern** に refactor。`if cond (echo X / goto Y)` → `if not cond goto :ok / [...echo X...] / goto :fail / :ok / [...continue...]` の linear flow に統一
  - 既存 refactor (Codex P1 で existing_install branch のみ実施) を全 block (files/ 不在 / dialog_ok 防御 / dialog_fail / 入れ子検知 / overwrite cancel / robocopy fail × 2 / mkdir fail / Manager 起動) に展開
  - docstring に「日本語 echo は (...) ブロック内に置かない」規約を構造規約として明文化
  - 副次効果: 一部 echo の `^(` `^)` エスケープが不要になった (ブロック外なので) → 可読性向上
- **Install.bat ダブルクリックで一瞬だけ開いて即閉じる bug (LF/CRLF 不一致)**: cmd.exe は LF-only bat を正しく parse できず double-click で即終了する (PR #140 の Release.bat 同種事故、本 Phase 2 で Install.bat に再発)。原因: `.gitattributes` の `*.bat eol=crlf` は git checkout 時に working tree を CRLF 化するが、Write tool 経由の編集で working tree に LF が残っており、Release.ps1 の `Copy-Item` がそのまま staging へ LF コピーしていた。zip の Install.bat は LF だったため double-click で開いた瞬間に cmd.exe parse 失敗 → 即 close。修正: `Copy-Templates` 内で `$src -match '\.bat$'` の場合に `ReadAllText` → `\r\n` 正規化 → `WriteAllText` で強制 CRLF 化。working tree の改行状態に依存せず確実に CRLF zip を出力できるように
- **[Codex P2 round 2] PowerShell 起動失敗とユーザー Cancel が exit code で区別不能 → real installer failures が exit 0 に丸まる bug**: 旧 `for /f ... do set INSTALL_PARENT=%%P` + `if not defined INSTALL_PARENT` チェックは「PS 起動失敗 (PS 未 install / AppLocker block / PS_DIALOG_CMD syntax error 等)」と「ユーザー Cancel」の両方で `INSTALL_PARENT` undef → cancel 扱い (exit 0) になる。Phase 3 で Updater が Install.bat を invoke する場合、real failures を成功扱いしてしまう実害ある silent failure path。修正:
  - PS 終了コードを 3 値で意味付け: `0` = OK + path 出力 / `2` = ユーザー Cancel (旧 `1` → `2` に変更、PS 内部 error の exit 1 と区別) / その他 = PS 実行失敗
  - 出力を `%TEMP%\gctone_install_dialog_<RANDOM>.tmp` 経由で受け取り、bat 側で `ERRORLEVEL` を確実に捕捉 (`for /f` の弱い exit code 伝播を回避)
  - 3-way dispatch: `:dialog_ok` (続行) / `:dialog_cancel` (`goto :end`、exit 0) / `:dialog_fail` (`goto :fail`、exit 1 + Execution Policy 確認手順案内 + PS stdout 内容表示)
  - PS one-liner も `[Console]::Out.WriteLine` → `[Console]::Out.Write` に変更 (末尾 CRLF を抑止、`set /p` の cmd.exe 版差での CR 残留 trap を回避)
- **[M2] Install.bat の失敗 path も `exit /b 0` で caller から成否区別不能**: 4 つの失敗経路 (files/ 不在 / 入れ子検知 / robocopy 失敗 / mkdir 失敗) がすべて `:end` に合流して `exit /b 0`。Phase 3 で Updater から Install.bat を呼び出す場合に exit code でエラー判定できない。`:fail` label を新設 + `EXIT_CODE` sentinel を導入、失敗 path は `goto :fail` で 1、成功 / ユーザーキャンセル (folder dialog cancel / 上書き N) は 0 を返す形に
- **[M3] docstring の ASCII 規約と実装の乖離**: 「chcp 65001 より上の REM / echo は ASCII 必須」と書きながら、自身の docstring REM 行が日本語だった。`@echo off` 下で REM は表示されないので mojibake は echo にしか発生しないのが実態。docstring を「echo は ASCII 必須、REM は日本語 OK」に修正
- **[M4] PS one-liner の多行出力に対する防御**: `Write-Output $d.SelectedPath` だけだと将来 Add-Type warning が stdout に出るケース等で for /f の最終行が pollute される可能性。`[Console]::Out.WriteLine + [Environment]::Exit(0)` で明示的に 1 行のみ書き出し + 後続出力を封じる形に変更

#### Changed (PR #149 シニアレビュー round 1)

- **[M1] `:wait_close` 文言を `pause` の挙動に整合**: 「Enter キーを押してください」→「何かキーを押してください」(`pause` は ReadKey ベースで任意キーで進むため、文言通り Enter を期待するユーザーには直感に反していた)
- **[L1] `robocopy /XD` 名前マッチの副作用を明記**: `/XF /XD` はツリー全体で同名 file/dir を除外するため、将来 component 内に `Companions/logs/` 等の同名 dir が登場すると意図せず除外される。現状 files/ には保護対象名と衝突する物がないので実害なし、コメントで明記
- **[L2] Manager 起動 path で Install.bat の `pause` を抑止**: Manager.bat 起動 → Manager UI 表示中に Install.bat の「何かキーを押してください」が同時表示される UX 退行を回避、`MANAGER_STARTED=1` sentinel で `:end` の pause を skip
- **[L4] `set /p` 空 Enter の「前回値保持」事故を防ぐ事前初期化**: `set "OVERWRITE_CONFIRM="` / `set "START_MANAGER="` を `set /p` 直前に追加。現状の variable chain では発火経路なしだが、将来上流で同名変数が定義される変更が入った時の silent break を防ぐ
- **[L5] `Release.ps1` の Y/N 判定を厳格マッチ化**: 旧 `-inotmatch '^y'` は先頭 y 一致のみで `yikes` / `yo` / 「YES (確認)」末尾括弧等の typo でも公開が走る。`-imatch '^(y|yes)$'` の完全一致に変更、prompt 文言も「y/yes/n/no で回答」に明示。誤判定で abort → 再実行する方が誤 publish より低コスト (GitHub Releases publish は巻き戻し不可)

#### Acknowledged (PR #149 L3 scope creep)

- 本 PR は (a) Install.bat 等 Phase 2 本体 (b) Release.ps1 Y/N upload prompt 追加 (c) Release Tooling v1.0.x → v0.1.x rename の 3 つの関心事が混在している scope creep の指摘 (PR review L3)。次回類似シナリオでは分割を検討、本 PR ではすでに review が進行しているため merge 完了させる方針

#### Fixed (PR #149 Codex P1)

- **`Install.bat` の parenthesized block 内で `%VAR%` parse-time 展開 bug**: 既存検出 branch の `MANAGER_RUNNING` / `LAUNCHER_RUNNING` は `if exist (...)` ブロック内で `set` していたが、続く `if %VAR% EQU 0` の比較が parse-time に展開される (cmd.exe 仕様)。これにより stale/empty 値で `EQU was unexpected` の parse error が発生し、**GCTonePrism が既存の場合の overwrite フロー全体が壊れる** P1 bug だった。さらにラベル `:checkprocess` / `:wait_close` / `:do_overwrite` が `()` ブロック内に置かれており `goto` の動作も不安定。両 issue を構造 refactor で解消:
  - `if exist () (...) else (...)` を **`goto :existing_install` / `goto :new_install` の top-level 分岐** に書き換え、すべての label を `()` 外に移動
  - `tasklist | findstr` の結果取得を top-level に置き、`%ERRORLEVEL%` が run-time に正しく評価される構造に
  - 変数名も `MANAGER_RUNNING` → `MANAGER_FOUND` に変更 (findstr exit 0 = 発見 = 稼働中、の意味を明示)

#### Changed (upload prompt + タグ衝突チェック位置変更)

- **`Release.bat` / `Release.ps1`: zip 化後の `Y/N` 公開確認 prompt 追加**: user 提案、Install.bat 等の動作確認ワークフローを安全に作るため。新フロー: ビルド → zip 化 → 「GitHub Releases に v$Version を公開しますか？ (Y/N)」prompt → Y で `gh release create`、N で「zip だけ残して終了」。これにより:
  - **本番 release publish を毎回明示的に同意する形に変更**、誤 publish のリスク削減
  - zip だけ作って別環境に持ち出して Install.bat 動作確認、という運用が default で可能 (`-SkipUpload` を毎回付け忘れる必要なし)
  - `-SkipUpload` は引き続き有効 (prompt 自体を skip、CI / non-interactive 運用向け)
  - prompt の Read-Host 入力が `y` / `yes` 完全一致 (大小文字不問) の場合のみ公開、それ以外は abort (round 1 L5 で typo 寛容を厳格化)
- docstring の `gh release create でアップロード（-SkipUpload で抑止）` → `zip 完成後、Y/N 確認プロンプト → Y なら gh release create、N なら zip だけ残して終了` に更新
- **タグ衝突チェックを `Assert-Preflight` → `Resolve-TagConflict` (zip 後 / Y/N 前) に移動**: 段階的に 3 つの設計を経た最終形。
  - 旧 (v0.1.7 以前): preflight でタグ衝突を確認 → 既存なら build 前に即 fail。「Install.bat 検証用に zip だけ欲しい」シナリオで毎回 `-SkipUpload` を付け忘れる問題があった
  - 中間 (v0.1.9 途中): build → zip → Y/N prompt → Y 確定後にタグ衝突チェック → 既存なら Fail。「publish 不可なのに Y を聞いて、Y 押させた後に fail」というミスリードな順序
  - 最終 (v0.1.9): build → zip → **タグ衝突チェック** → Y/N prompt。publish 可能な状態 (衝突なし or `-Force`) に絞ってから Y/N を聞く。
  - 既存 + `-Force` なし時の挙動: 旧 `Fail` (exit 1 + 赤字 FAIL) ではなく `Write-Warn` + 復旧手順案内 + `exit 0` で graceful exit。「zip 生成は成功している」「publish 不可は env 状態であって script の失敗ではない」「caller (CI 等) も exit 0 を正常扱いで判定可能」のため。
  - preflight は env 系 (gh auth / CHANGELOG / working tree) のみに役割を絞り、「事前 fail-fast」と「build 投資後の状態確認」の責務を分離。

#### Changed (versioning scheme)

- **Release Tooling の version numbering を v1.0.x → v0.1.x に renumber**: 初版 (Phase 1) 時に v1.0.0 開始としたが、他コンポーネント (Launcher v0.5.x / Manager v0.8.x / Bundle v0.1.0) が全て pre-1.0 dev mode の中で Release Tooling だけ v1.x になっていた。さらに毎 PR で構造変更を繰り返している現実 (本 entry までに 9 patch、結構な breaking 含む) と SemVer v1.0 = stable の意味が乖離していた。v1.0.x には git tag / GitHub Release が一切存在せず外部参照ゼロのため、CHANGELOG / Release.ps1 inline コメント / AGENTS.md の歴史言及をすべて v0.1.x に retroactive rename。今後の patch も v0.1.10, v0.1.11 ... と続く。Bundle が 1.0 に到達した時点で各 component と合わせて Release Tooling も v1.0 を検討する想定

#### Added

注: 本セクションは PR #149 最終状態の事実のみを記述する。レビュー round 1/2/3 で複数回書き換わった項目 (cp932 staging / `<親>/` shortcut 配置 / ExpectedFiles 件数 / `show_folder_dialog.ps1` 切り出し 等) は、その変遷理由を `#### Fixed` 各 bullet で記録している (シニアレビュー round 3 M1)。

- **`templates/Install.bat`** — 初回インストーラ実装 (#108 Phase 2)
  - PowerShell `FolderBrowserDialog` で親フォルダを GUI 選択 (`set /p` 経由のパス入力 typo を回避、dialog は `show_folder_dialog.ps1` に切り出し `-File` 起動)
  - 入れ子検知: 親パス末尾が `GCTonePrism` なら警告 + abort (二重入れ子 `<親>\GCTonePrism\GCTonePrism\` 防止)
  - 既存検知: `<親>\GCTonePrism\` ディレクトリ存在で判定 (metadata file 不要、単純化)
    - Y/N 警告メッセージで「アップデートは Manager UI から推奨 / Manager 壊れた / クリーンインストール時のみ Y / ゲームデータ (prism.db / games / backups / responses / logs) は維持」を明示
    - Y → Manager.exe / Launcher.exe 稼働中チェック (`tasklist`) → 稼働中なら「閉じてから Enter」表示で手動 close 待機 (自動 kill しない、§3.7.4 Updater の責務に残す) → robocopy で保護データ除外 (`/XF prism.db /XD games backups responses logs`) しつつ上書き
    - N → abort
  - 新規時: ディレクトリ作成 + robocopy で `files/*` 全コピー、加えて `<親>/Launcher.bat` / `<親>/Manager.bat` (parent-level shortcut) を `copy /Y` で配置
  - 完了後 Manager 起動 Y/N プロンプト → Y なら **`<親>/Manager.bat` 経由で Manager.exe 起動** (旧設計の自動起動は廃止、SPEC §3.7.5 の Manager.bat 経由規約と整合)
  - file format: 編集ソースは UTF-8 (no BOM) + CRLF、staging 時 Release.ps1 Copy-Templates が **cp932 (Shift-JIS) + CRLF** に変換 (cmd の bat parser が system codepage で読む仕様に合わせる、JP Windows 校内向け配布スコープのため非 JP locale で mojibake になる trade-off は許容、詳細は `templates/Install.bat` 冒頭 docstring 参照)
  - 終端 `exit %EXIT_CODE%` (not `exit /b`) で cmd プロセスを直接終了させ、ダブルクリック起動時の window が確実に閉じるように。Phase 3 Updater 呼出し時は `Process.Start("cmd", "/c install.bat ...")` 形式必須 (SPEC §3.7.4)
  - exit code: `0` = success / cancel、`1` = failure (files/ 不在 / 入れ子検知 / robocopy 失敗 / mkdir 失敗 / PS 失敗) — Phase 3 Updater integration 用
- **`templates/show_folder_dialog.ps1`** — FolderBrowserDialog launcher (Install.bat の `-File` 経由で起動)
  - Install.bat 内 `-Command "..."` インラインだと cmd parser が長い `set "PS_DIALOG_CMD=...日本語..."` を破壊するため別ファイル化、Japanese description を維持可能
  - `$ErrorActionPreference = 'Stop'` + try/catch で setup / launch 失敗を `exit 1` で区別
  - exit code 3-way dispatch: `0` = OK + stdout に選択 path / `1` = catch (stderr に詳細) / `2` = user Cancel / その他 = PS host 起動失敗
  - file format: UTF-8 BOM + CRLF (PS 5.1 default ASCII 読み込みでの Japanese mojibake 防止)
- **`templates/INSTALL_README.txt`** — 配布 zip 同梱の部員向け手順書
  - インストール手順 (zip 展開 → Install.bat → folder dialog → Y/N → Manager 起動 Y/N)
  - 日常起動方法 (`<親>/Launcher.bat` / `<親>/Manager.bat` を `<親>` 直下から直接ダブルクリック)
  - アップデート方法 (通常: Manager UI、緊急: Install.bat 上書き、ゲームデータ保護リスト明記)
  - トラブルシューティング 4 項目
- **`templates/Launcher.bat` / `templates/Manager.bat`** — 部員日常起動用 **parent-level shortcut** (`<親>/` 直下配置)
  - 内容: `start "" "%~dp0GCTonePrism\GCTonePrism_<comp>\GCTonePrism_<comp>.exe"` (1 階層下の component exe を起動)
  - インストール後の最終構造: `<親>/Launcher.bat`、`<親>/Manager.bat`、`<親>/GCTonePrism/` が `<親>` 直下に並ぶ。部員は `<親>` を開けば即ダブルクリックで起動可能、`GCTonePrism/GCTonePrism_<comp>/` まで辿る煩雑さを排除 (SPEC §3.7.1 / §3.7.5)

#### Changed

- **`Release.ps1` Copy-Templates 拡張**: 旧仕様の Install.bat / INSTALL_README.txt の 2 件 WARN を廃止、**5 ファイル** (zip root × 5: Install.bat / INSTALL_README.txt / show_folder_dialog.ps1 / Launcher.bat / Manager.bat) の正規 staging 配置に。`.bat` は cp932 + CRLF、`.ps1` は UTF-8 BOM + CRLF に staging 時変換 (それぞれ cmd parser / PS 5.1 のデフォルト読み込み挙動に合わせる)。テンプレート不在時は `Fail` (旧 WARN だったが Phase 2 完成後はテンプレート存在が必須前提のため厳密化)
- **`Release.ps1` Assert-ExpectedFiles 拡張**: 期待ファイル一覧を 8 → **13 件** に (zip ルート 5 + files/ 配下 8)。SPEC §3.7.1 正規 zip 構造との対応を明示
- **`SPECIFICATION.md` §3.7.1 / §3.7.2 / §3.7.4 / §3.7.5 更新** (変更履歴 v1.10.8):
  - §3.7.1 正規 zip 構造に zip-root レベルの `Launcher.bat` / `Manager.bat` (parent-level shortcut) + `show_folder_dialog.ps1` を追加、ルートショートカット規約の理由 (部員日常使いの煩雑さ解消、`<親>` 直下から直接起動) を明文化
  - §3.7.2 を Approach C 仕様に再定義 (FolderBrowserDialog / 既存検知 Y/N / Manager UI 推奨 / 保護データ温存 / Manager 起動 Y/N)、旧仕様の自動起動 + `GCTonePrism_Manager` 配下チェックを廃止
  - §3.7.4 Updater 仕様に「Install.bat は `Process.Start("cmd", "/c install.bat ...")` 形式で呼ぶこと、`call` 形式 / 直接起動は禁止」を明記 (Install.bat 終端 `exit` の caller 巻き込み trade-off に対する制約)
  - §3.7.5 Launcher 側の役割に「日常起動は `<親>/Launcher.bat` から」の規約を明記

### [Release Tooling v0.1.8] - 2026-05-12

#### Fixed

- **msbuild 後の日本語 doubled rendering (Wave 2)**: 症状例 `完了` → `完完了了`、ASCII は影響なし、複数 Write-Host が 1 行に collapse。PS 5.1 + chcp 65001 環境で子プロセス (msbuild) がコンソールハンドル継承後にコンソール encoding を OEM 系に戻して去ることが原因の既知バグ。修正:
  - script 冒頭で `[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)` + `$OutputEncoding` を明示ピン留め
  - `Invoke-ExternalProcess` の finally ブロックで再ピン留め (二重防御、msbuild 等の毎呼び出し後)
  - 同じ try/finally で Process オブジェクトの Dispose() も追加 (handle leak 防止)
- **upload progress が表示されない問題 (Wave 2)**: `gh release create` は TTY 検出で進捗描画を OFF にするため、PS から呼ぶと upload 中ずっと無音 → ハング懸念。修正:
  - `Invoke-NativeWithCapture` に `-ShowProgress` / `-ProgressMessage` パラメータを追加 (500ms 間隔で経過秒数を `\r` 上書き表示)
  - `Invoke-GhRelease` (gh release delete / create) を PASS_THROUGH → helper + ShowProgress に移行、zip サイズも表示 (`アップロード中 (zip 59 MB)... 12s 経過`)
  - 完了後は progress 行を消して、gh が stdout に出す release URL を `Write-Info` で再表示
- **PR #148 round 17 シニアレビュー反映**:
  - **[R17 #2] UTF8Encoding 一意ソース統一**: `Invoke-GhRelease` の `WriteAllText` (`tmpNotes` 書き込み) と `Write-FileUtf8NoBom` helper が `[System.Text.UTF8Encoding]::new($false)` を新規生成しており、本 PR の「`$script:Utf8NoBomEncoding` を一意ソースとして共有」設計に違反していた。両箇所を `$script:Utf8NoBomEncoding` 参照に置換、UTF-8 encoding instance を script 内で完全に一意化
  - **[R17 #3] `$OutputEncoding` 再ピン留め不要の理由を明文化**: `Invoke-ExternalProcess` finally で `[Console]::OutputEncoding` だけ再ピン留めし `$OutputEncoding` (PS pipeline 側 encoding) は触らない理由 (PS 変数なので子プロセスから変更不可) をコメント追記、保守者が「漏れか?」と判断して不要な再ピン留めを追加する誤修正を防止
  - **[R17 #4] `Invoke-NativeWithCapture` docstring 注 1 を vswhere `-utf8` 対応反映**: 旧記述「vswhere は ASCII 中心」は同 PR 内で追加した `-utf8` 化と乖離。「vswhere はデフォルト system codepage 出力なので、本 helper 経由の call site では `-utf8` を必ず付与」に更新、日本語 VS install path も正しく decode できる旨を明示
  - **[R17 #5] ShowProgress を `IsOutputRedirected` で抑止**: 非 TTY (CI / log file redirect) では `\r` が行リセットとして機能せず、progress 更新ごとに改行付きで log に展開されてノイズになる。`[Console]::IsOutputRedirected` (取得失敗時は redirected 扱いで safe-side) で検出して live progress を skip、redirected 環境では従来の gh TTY-off モードと同じく完了まで無音 → URL 表示の動作に degrade
  - **[R17 #1 (false positive)]** PR body Commits 数: reviewer は "(7)" と認識していたが、round 16 push 後の `gh pr edit` で既に "(8)" に更新済み、stale view を見ていた可能性。本 round では body 再更新 (commit 8 を含む) のみ
- **PR #148 round 16 シニアレビュー反映**:
  - **[R16 #1] vswhere 失敗時の `$vsInstall` クリア**: round 15 で `Write-Info "PATH fallback に切替"` と宣言したのに、続く `$vsInstall = $vswhereResult.StdOut.Trim()` が無条件実行で「失敗時 stdout の部分出力」も後段 `Test-Path` 経路に流れる構造矛盾。`if/else` に分けて失敗 branch で `$vsInstall = ''` を明示、最終的に `Test-Path` で実害は止まるが、宣言と実装の意図不一致を解消
  - **[R16 #2] `WaitForExit()` の両 path 役割を明示**: 旧コメント「.NET 慣習との表面的対称性のみ」は非 ShowProgress 経路で誤誘導 (実際にはここがプロセス完了を明示待機する唯一のポイント)。「ShowProgress 経路 = no-op / 非 ShowProgress 経路 = 必須」と path 毎の役割を明記、削除不可の根拠を両 path で示す
  - **[R16 #3] `clearLine` 全角 cell 幅の注意書きを正確化**: 旧コメント「Japanese 文字 cell 幅によらず消し残しが出ない」は実装より強い保証に読める。実態は「現 ProgressMessage 長では WindowWidth-1 幅で覆える前提に依存」「全角 2 cell 幅を構造的に補正していない」を明文化、長文 ProgressMessage 追加時の修正 hint も併記
  - **[R16 #4] CHANGELOG R13 ナンバリング順を整理**: R13 L1 (保留) を L4 の後から L2 の前 (= L1/L2/L3/L4 の自然順) に移動、後追い時のスキャンが直感的に
- **PR #148 round 15 シニアレビュー反映**:
  - **[R15 M1] 死参照訂正**: `Invoke-NativeWithCapture` のセクションヘッダコメント `(冒頭の \`2>&1\` trap セクション参照)` が v0.1.8 のセクション再構成で stale に。「冒頭の『Native command 呼び出しの方針』セクション参照」に修正
  - **[R15 M2] WindowWidth fallback コメントと実装の divergence 解消**: コメント「0 以下を返す」と実装 `-lt 30` の食い違いを明文化。「30 未満」は WindowWidth=0 の非 console host と極端に狭い実コンソールの両方を catch する threshold である旨を明示
  - **[R15 M3] vswhere の silent pass 解消**: コメントが「実行環境破損で stderr 出力する可能性」を挙げて Invoke-NativeWithCapture に移行していたにも関わらず ExitCode / StdErr を完全に無視していた silent pass を修正。vswhere 失敗時は `Write-Warn` で診断情報を出して PATH fallback に切替 (release は続行可能なため Fail にはしない)
  - **[R15 L1] Combined 4 case コメント精度向上**: 第 4 case「stderr 空 → stdout のみ」は stdout 末尾改行なしのとき不正確 (実は `\n` が付く)。stdout 末尾改行の有無を主軸にした 2 分岐構造に書き換え、各分岐で stderr の各 case を入れ子で記述
  - **[R15 L2] gh release delete dead code を future-proofing と明示**: 現行 gh では成功時 stdout 空なので `if ($delOut -match '\S')` ブランチは常に false。コメントを「現行は発火しない、gh 将来 version への future-proofing として残置」に書き換え、reader が「`Write-Ok` では不十分な case があるのか?」と誤解する path を防止
  - **[R15 L3] CHANGELOG R13 L2/L3 フォーマット統一**: 他エントリの `**[R## L#] 見出し**: 説明文` 形式に揃える ( `↔` や文の ぶつ切りを解消)
- **PR #148 round 14 シニアレビュー + Codex bot P2 反映**:
  - **[Codex P2] vswhere に `-utf8` フラグ追加**: `Invoke-NativeWithCapture` は stdout/stderr を UTF-8 として decode するが、vswhere は default で system codepage 出力。非 UTF-8 locale で日本語 VS install path 等 non-ASCII path が mojibake → 後段 `Test-Path` 失敗 → MSBuild 検出失敗の silent path に落ちる。`-utf8` を Arguments に追加して vswhere 出力を UTF-8 強制
  - **[Codex P2 ×2] `[Console]::OutputEncoding` を try/catch でガード**: non-console host (CI / headless / redirected execution) では console API setter が `IOException` を投げ、`$ErrorActionPreference='Stop'` 下で release 開始前に script abort する path。script 冒頭の pin + `Invoke-ExternalProcess` finally の再 pin 両方を try/catch でラップ、script-level `$script:Utf8NoBomEncoding` を一意ソースとして共有
  - **[R14 H1] `WaitForExit()` コメントの自己矛盾を訂正**: 旧コメント「パイプバッファ完全フラッシュを保証」は誤り (WaitForExit no-arg のフラッシュ保証は `BeginOutputReadLine` 系の event-based async 読み取りに対するもので、本実装の `ReadToEndAsync` Task-based には適用されない)。実際のフラッシュ保証は `$outTask.Result` / `$errTask.Result` が EOF までブロックすることで提供。コメントを「`.Result` を削除すると出力切り捨てバグが発生するため touch しないこと」に書き換え
  - **[R14 M1] CHANGELOG label 重複解消**: 同 v0.1.8 entry 内に「Wave 2 シニアレビュー反映 (M1-M3)」と「PR #148 シニアレビュー反映 (M1-M3)」が共存し M1-M3 が 2 セット存在、後追い不能だった。本 entry のラベルを「R14」「W2」「Codex P2」等の round 識別子付きに変更
  - **[R14 L1] zip size 表示の小ファイル対応**: `[int]($bytes / 1MB)` は 1MB 未満で 0 表示になり破損誤解を招く。`if ge 1MB → MB / ge 1KB → KB / else B` の自動切替に変更、Phase 2 以降の Updater 単体 zip 等で発火する想定
  - **[R14 L2] ShowProgress 中の Task リーク (Known follow-up)**: `ReadToEndAsync()` 開始後に ShowProgress ループ内で例外発生 → finally で Dispose() → Task が `ObjectDisposedException` で faulted のまま GC まで放置。実害ほぼなし (現状実行 path で発火経路なし) だが、post v0.1.8 で `-TimeoutSeconds` + CancellationToken 対応する際に合わせて整理
- **PR #148 round 13 シニアレビュー反映**:
  - **[R13 M1] `gh release delete` UX 退行**: 成功時 stdout/stderr 無音のため `if ($delOut -match '\S')` が false で ShowProgress 行消去後に「無の状態」。`Write-Ok "既存タグ v$Version を削除完了"` を無条件追加して旧 PASS_THROUGH UX を回復
  - **[R13 M2] PASS_THROUGH catalog のメカニズム乖離**: catalog の例示は `& native-cmd` 直書きだが現実装は `Invoke-ExternalProcess` (Process 直叩き)。「(a) 直 & 演算子版」「(b) helper 経由 (推奨)」の 2 実装に分割記述
  - **[R13 M3] `ShowProgress` パスで `WaitForExit()` 未呼び出し**: HasExited ループ後にも `WaitForExit()` 明示呼びを追加、両 path 合流点で対称化 (上記 R14 H1 でコメント内容を訂正)
  - **[R13 L1 (保留)] CHANGELOG 日付ポリシー**: JST 統一 / UTC 統一 / PR merge 日のいずれかに統一する議論は CHANGELOG 全体に関わるため別途
  - **[R13 L2] WindowWidth fallback 条件の記載追加**: R13 M3 説明文に「`[Console]::WindowWidth` が 0 以下を返す non-console host も同様に fallback 120」を追記、コード側との整合を明示 (round 15 M2 で更に「30 未満も含む」に精度向上)
  - **[R13 L3] 引数 quoting backslash 制約のドキュメント化**: trailing backslash を持つパス引数 (`"C:\path\"`) は CommandLineToArgvW 規則上 `\"` が閉じ引用符として機能せず引数 parse 破損する既知制約を helper の inline コメントに明文化、現 call site は該当なし
  - **[R13 L4] `Invoke-ExternalProcess` の Process.Start 失敗 rethrow**: `Invoke-NativeWithCapture` と同じ context 付き例外メッセージ粒度で対称化
- **PR #148 round 12 (Wave 2) シニアレビュー反映**:
  - **[W2 M1]** catalog の PS 7.3+ 移行注意から vswhere を削除 (Wave 1 で helper 化済みのため stale)、残る `&` イディオムは `Assert-WorkingTreeClean` の `git status --porcelain` のみと正確化
  - **[W2 M2]** `Invoke-NativeWithCapture` docstring に「`$LASTEXITCODE` は更新されない、`.ExitCode` を使え」を明記
  - **[W2 M3]** ShowProgress の clear-line 幅を 70 ハードコード → `[Console]::WindowWidth - 1` で動的算出 (fallback 120)
  - **[W2 L1]** gh release create 成功時の URL 表示が gh の stdout フォーマット依存である旨をコメントに明記
  - **[W2 L2]** encoding pin コメントの「特に msbuild」断定を「Godot CLI / msbuild / nuget 等」に緩和
  - **[W2 L3]** `.Trim() / .TrimEnd()` 二重呼び解消 (`-match '\S'` + 一時変数化)
  - **[W2 L4]** `Combined` separator 判定コメントを 4 case 網羅に書き換え

#### Changed

- **Native command 呼び出しを `Invoke-NativeWithCapture` helper に一本化 (Wave 1: trap pattern 整理)**: `gh release view` (v0.1.7) / `gh auth status` (Round 11 Critical #1) / `vswhere` (Round 11 Low) を Process 直叩きベースの helper に移行。catalog から「失敗 path で stderr を出すコマンドでは罠を踏む」パターン (`SUPPRESS_BOTH` / `CAPTURE_DIAGNOSTIC` / `TRY_CATCH_NATIVE`) を anti-pattern に格下げ
  - **`Invoke-NativeWithCapture` helper 新設**: `System.Diagnostics.Process` で stdout/stderr/exit code を直接捕捉。PS の error stream を経由しないため NativeCommandError trap を構造的に回避。両 stream を async 読みでデッドロックも回避。返り値は `[PSCustomObject]` で `.StdOut` / `.StdErr` / `.ExitCode` / `.Combined` を提供 (Round 12 #1/3 のリネーム指摘もこの構造変更で自動解消)
  - **catalog 大幅整理**: 6 個あった pattern を「Invoke-NativeWithCapture 推奨 + 3 個の安全な `&` pattern + anti-patterns」に再構成。Round 11 Low の命名軸統一 + Round 12 全般の意図明確化を満たす形に
  - **`gh release view` の structured parse 表現訂正 (Round 11 High + Round 12 #2)**: `--json id` の効果は「存在時の stdout を最小化」のみで、parse はしていない。stderr 文字列マッチでの「不在 vs 別種失敗」判定は gh の英語メッセージ依存である旨をコメントに明記、本来の structured parse (`ConvertFrom-Json` + HTTP 404 判定 etc.) は将来課題として記録
  - **Round 11/12 の Medium / Low 一括対処**: `$_.Exception.Message` 単一行依存 (helper で StdErr 直接取得に変更で解消)、`$releaseViewOutput` mixed content (helper で StdOut/StdErr 分離で解消)、`Out-String` 末尾改行 `.TrimEnd()` 化、elseif → ネスト if/else (exit code を一次軸、stderr を二次軸の構造に)、catalog ↔ call site 重複圧縮 (helper 化で per-site コメントが固有理由 1-2 行に)
  - **`gh auth status` の同 trap も同時解消 (Round 11 Critical #1)**: v0.1.7 で CHANGELOG note として deferred していたものを Wave 1 で本対応
- **PASS_THROUGH の「例外節」呼称を廃止**: 旧 catalog では「実 release 操作 (gh release create/delete) は例外」と書いていたが、PASS_THROUGH 自体を catalog の一級 pattern として再定義したため例外節は不要に。`Invoke-GhRelease` 内の 2 件のコメントから「例外節 -」を削除

#### Known follow-up (post-v0.1.8 で対処予定)

- **`Invoke-NativeWithCapture` 内 TODO**: (a) 引数 quoting helper 切り出し (`Invoke-ExternalProcess` と duplicate)、(b) `-TimeoutSeconds` 引数で network hang ガード — いずれも post v0.1.8 で対処
- **既存 issue #142 / #143 / #144 / #146**: catalog 重複は本 v0.1.8 で大幅解消、`Release.bat` docstring 分離 / `Read-*` 命名 sweep / `$Context → $PostSync` は別途
- **#145 (CAPTURE_DIAGNOSTIC ラベル拡張) を本 v0.1.8 で close**: パターン自体を anti-pattern に格下げしたため拡張議論不要に

### [Release Tooling v0.1.7] - 2026-05-12

#### Fixed

- **本番 release で `gh release view` が NativeCommandError trap を踏んで preflight が失敗する問題 (#141 のインライン解決)**: v0.1.6 までの `& gh release view "v$Version" 2>$null | Out-Null` は DRY-RUN で `-SkipUpload` 自動 promote により実行されず、本番 release で v0.1.0 を publish しようとして初めて発火した
  - **根本原因**: PS 5.1 + `$ErrorActionPreference='Stop'` 環境では、native command が **exit 非ゼロ + stderr 出力** という組合せを返した場合に `2>$null` redirect が trap を防げない。これは PS が native command 用に別途生成する NativeCommandError ErrorRecord が `2>$null` の redirect 処理よりも先 (exit code 確定時点) に作られるため。v0.1.6 までの集約コメントは「`Out-String` を経由すれば Stop の判定対象から外れる」と書いていたが、これは exit 0 限定の挙動で、`gh release view "v0.1.0"` 不在時の `exit 1 + stderr "release not found"` には適用できなかった
  - **修正**: `try/catch` で受ける `TRY_CATCH_NATIVE` パターンを新設 + 該当 call site に適用。`--json id` で stdout を最小化 (#141 で提案していた structured parse)、`"release not found"` 文字列マッチで "確実に存在しない" を確証、別種の失敗 (auth / network / API rate limit / gh install 破損 等) は preflight で早期 Fail させる形に。これで H2 silent false-negative (gh の auth/network 障害を「タグ衝突なし」と誤判定して zip ビルド完了後に fail する path) も同時解消
  - **catalog 全体の精度向上**: 集約コメントの機構説明に「重要な制約」セクションを追加、`SUPPRESS_BOTH` / `CAPTURE_STDOUT` / `CAPTURE_DIAGNOSTIC` の各パターンが「success/failure path のどちらで stderr を出すか」によって安全性が変わる旨を明記。失敗 path で stderr を出すコマンドには `TRY_CATCH_NATIVE` 一択
  - 影響範囲は preflight の 1 call site のみ。zip / upload ロジックには変更なし
- **#141 (元シニアレビュー round 8 H2) を本 fix で close**: 当時「別 issue で `--json id` への移行」と切り出した内容を、本番踏み抜きを機にインラインで本格対応

#### Known follow-up (本 PR スコープ外、別ブランチで対処予定)

- **`gh auth status` の call site は本 PR の catalog 制約に未追従**: `Release.ps1` の `Assert-Preflight` 内 `$authStatusOutput = & gh auth status 2>&1 | Out-String` (CAPTURE_DIAGNOSTIC) は、本 PR で新設した制約 (「失敗 path で stderr を出すコマンドには TRY_CATCH_NATIVE 必須」) に該当する。`gh auth status` は未認証時 exit 1 + stderr 出力なので、`gh auth login` 未実行の dev clone / token 期限切れ / `GH_TOKEN` 消失 等のシナリオで NativeCommandError 例外で abort し、本来表示するはずの `Fail "gh 認証に失敗しました ..."` メッセージが届かない。本 PR のスコープは `gh release view` の 1 call site に絞ったため未対応、改善ブランチでまとめて TRY_CATCH_NATIVE に移行予定。シニアレビュー round 11 で同 PR 内対応 or CHANGELOG note のどちらかが許容ラインとされたため、後者を選択

### [Release Tooling v0.1.6] - 2026-05-11

#### Fixed

- **`Release.bat` ダブルクリック / ターミナル実行で実質動作しない問題**: cmd.exe が UTF-8 BOM (`EF BB BF`) を CP932 として解釈、1 行目の `@echo off` が機能せず、全 REM 行を echo on で splay + cp932-mojibake で表示する状態だった。UTF-8 (no BOM) + ASCII プレフィックス (`chcp 65001` 以前は ASCII 限定) に変更して解消
- **`gh release view` が release 不在時に script を terminating error で止める問題**: preflight タグ衝突チェックの `2>&1` が PS 5.1 + `$ErrorActionPreference='Stop'` 下で NativeCommandError 化、本来「衝突なし続行」のはずの正常系で fail していた問題。`2>$null | Out-Null` パターンに変更
- **同 anti-pattern が `gh auth status` と `git status --porcelain` にも残っていた問題**: シニアレビューで指摘され全 3 箇所を統一
  - `gh auth status`: `& cmd 2>&1 | Out-String` パターンで診断情報を文字列として保持。失敗時に `gh auth login` 以外の原因 (network / proxy / token expiry / install 破損) も Fail メッセージに出して切り分け可能に
  - `git status --porcelain`: redirect 削除 + 明示的 `$LASTEXITCODE` チェック + Fail 追加。redirect 単純削除では git 失敗時に "clean" 誤報告の **silent pass regression** を踏むため exit code check 必須

#### Changed

- **v0.1.5 で導入した `[WARN]` メッセージの日本語併記行を削除**: chcp 取得失敗パスは codepage 未切替 + ファイル no-BOM のため日本語 echo の文字化けが確定的、ASCII-only ルールに整合させる形で意図的に撤回
- **`2>&1` trap 関連の per-site コメント 3 箇所を集約 + 参照形式に整理**: Release.ps1 冒頭の `Set-StrictMode` 直後に集約コメントを設置、各 call site は集約参照 + 1-2 行の理由のみ。集約ラベルは self-documenting な名前 (`SUPPRESS_BOTH` / `CAPTURE_DIAGNOSTIC` / `CAPTURE_STDOUT` / `CAPTURE_STDOUT_PASS_STDERR` / `PASS_THROUGH` / `STOP_TRAP`) で索引参照型コメントの欠点 (表まで戻る往復) を解消。集約コメント内に「機構」セクションを追加して PS 7.x 等への移植時の調査起点を明示
  - **シニアレビュー round 7 反映**: `Assert-WorkingTreeClean` の git status call site は stdout を変数 capture / stderr を console 直書きする hybrid なので、PASS_THROUGH (console 直書き、変数 capture なし) では実態と乖離していた。`CAPTURE_STDOUT_PASS_STDERR` パターンを新設して移行。call site のパターンマーカーと catalog 定義の整合性を保つことが「self-documenting パターン名」アプローチの前提
  - **`STREAM_TO_VAR` の独立記載を廃止**: `STOP_TRAP` と本質的に同じ罠 (`2>&1` 自体が原因) で、変数 capture 有無は表面の違い。「PS バージョンで挙動が変わる」表現が誤読を招くため統合し、両形式を `STOP_TRAP` 配下にまとめて回避策を 2 つ並記
  - **`Invoke-GhRelease` の gh release create / delete に pattern マーカー追加**: 集約 catalog の「例外」節に書いてあるが call site にマーカーがなく「対象外」と読まれる余地があった。`# pattern: PASS_THROUGH (例外節)` を 2 箇所に追加
- **`Test-Preflight` → `Assert-Preflight` リネーム**: PowerShell 規約で `Test-*` は `[bool]` 返却用 (`Test-Path` / `Test-Connection` 等)。preflight は違反時 `Fail` (= `exit 1`) する性質なので `Assert-*` 系に揃え、同ファイル内の `Assert-WorkingTreeClean` と命名一貫性を取る
- **`Release.bat` の防御性向上**:
  - `ORIGINAL_CODEPAGE` の数値 validation (`findstr /R "^[0-9][0-9]*$"`) を追加。chcp 出力が想定外フォーマット (unicode digit / 想定外 locale 等) の場合に exit 時の `chcp %ORIGINAL_CODEPAGE%` が garbage を渡して cmd 窓が壊れるレアケースを防御
  - `FORWARDED_ARGS` 連結ロジックを `if defined` 分岐で書き換え、初回 append 時の leading space を解消 (echo 出力の見た目改善)
- **Release.bat の docstring 整理**: BOM 失敗症状の記述を「最初の 1 行目で `@echo off` ITSELF が fail する」に厳密化 (旧記述 "subsequent commands fail" は誤り)、chcp 65001 境界 banner を 4 行 → 1 行 marker に簡素化 (詳細は docstring と一元化)
- **Release.bat に codepage 切替の Flow ダイアグラム追加**: `for /f` + 3 if 文の状態遷移 (`captured + numeric` / `captured + invalid` / `not captured`) を docstring 冒頭の Flow セクションで明示。3 つの独立 if を逐次読まなくても判断できる
- **`Get-BundleReleaseNotes` の正規表現に `\Z` 追加**: 旧 lookahead `(?=^### |^---|^## )` は必ず後続セクションマーカーを要求し、Bundle entry が CHANGELOG 末尾 (後続なし) だと空文字列を返す regression。現状の CHANGELOG 構造 (Bundle 配下に Launcher / Manager / Release Tooling が続く) では発火しないが、将来セクション順を入れ替えた場合や最小 CHANGELOG での誤動作を防ぐ保険
- **`gh auth status` の success 時 warning を抽出して `Write-Warn`**: `gh` は exit 0 でも stderr に token scope 不足 / token expiry 近接の warning を出すことがある。失敗ではないが早期の気付きをリリース担当に届けるため、出力中の特定パターンを検出して警告表示 (release 自体は継続)
  - **シニアレビュー round 8 (M1) 反映**: 初版の `warning|expir` regex は `expiration` / `experimental` / 通常 success 時の `Token expires:` 等にも hit する false positive 多数。特異性高めの `(token has expired\|token expir(es\|ed\|ing) in \d+\s*(day\|hour)\|missing.*scope\|insufficient.*scope\|^warning:)` に厳密化
- **シニアレビュー round 10 反映**:
  - **L4**: catalog `PASS_THROUGH` の「exit code チェック必須」理由を cross-reference から自己完結型に修正。旧コメントは「CAPTURE_STDOUT_PASS_STDERR と同じ理由」と参照していたが、後者の理由は「出力空でも `$LASTEXITCODE` 非ゼロ誤判定防止」で変数 capture が前提。`PASS_THROUGH` は変数 capture なしで構造的に該当しない。`PASS_THROUGH` の真の理由「成否判定の信号が exit code のみのため」に書き換え
  - **L5**: `Get-BundleReleaseNotes` の `-SilentMissing` switch を `-AllowMissing` にリネーム。旧名は「CHANGELOG.md が見つからない時」のみを silent にする読みだが、実体は「Bundle セクションが見つからなかった時」も含めて empty 返却する semantics。`AllowMissing` の方が実態に近い
- **別 issue 化**:
  - **M1 (#144)**: `Read-LauncherVersion` / `Read-ManagerVersion` / `Read-ComponentVersions` の命名規約 sweep — `Read-*` は PowerShell では対話的入力 (`Read-Host` 等) を意味、ファイル読み出しは `Get-*` 系が原則。さらに `Fail` する性質を踏まえると round 6/9 の `Test-*` → `Assert-*` sweep の対象範囲外として漏れていた
  - **M2 (#145)**: catalog `CAPTURE_DIAGNOSTIC` ラベル説明 (「失敗時に表示するため」) が実態より狭い。実装では success 時の `^warning:` 検出にも再利用しているため、「両 stream 文字列化キャプチャ」相当に拡張すべき
  - **M3 (#146)**: `Assert-WorkingTreeClean` の `$Context -like '*sync 後*'` 文字列マッチを `[switch]$PostSync` パラメータに構造化 — call site の文字列を変えると特例メッセージが silent に失われる脆さを解消
- **シニアレビュー round 9 反映**:
  - **H1**: `Test-ExpectedFiles` → `Assert-ExpectedFiles` リネーム。round 6 で `Test-Preflight` → `Assert-Preflight` した時と完全に同じ条件 (`Fail` (exit 1) する関数で PowerShell の `Test-*` = `[bool]` 規約に違反) に該当していた漏れを解消、命名規約の対象範囲を完結させる
  - **M2**: `gh auth status` warning 検出 regex を `^warning:` (gh 公式の warning prefix) のみに簡素化。round 8 の特殊形式 (`token expir(es|ed|ing) in \d+...` 等) は false negative リスク (「Token will expire soon」「tomorrow」等の日数表記なし形式の取りこぼし) があり、かつ gh 出力フォーマット変更に脆弱。本格的な structured 検出は別 issue (#141 系) で JSON parse に寄せる方針なので、ここでは過信を生む特殊形式を持たない方向に倒した
  - **L2**: `Get-BundleReleaseNotes` の `\Z` コメントを 6 行 → 1 行に圧縮。発火確率の低さに対しコメント長が不釣り合いだった
  - **L4**: `Assert-Preflight` 関数内のリネーム言い訳コメント (2 行) を削除。リネーム判断の justification は CHANGELOG / PR 説明に書く内容で、関数定義に残すと半年後の reader が「なぜここに?」となる
  - **L5**: `Release.bat` の `enabledelayedexpansion` 副作用例から架空引数 `-Tag` を削除、現存 pass-through 引数の列挙 + 「新規 pass-through 引数追加時の注意」framing に変更
- **別 issue 化**:
  - **M1 (#142)**: catalog vs per-site コメントの方針統一 — ラベル参照 + 詳細説明の二重化がメンテナンスコストを生む構造に逆戻りしていた問題。本 PR スコープ外で trackable 化
  - **M3 (#143)**: `Release.bat` の docstring 経緯を `SPECIFICATION.md` に分離 — 100/150 行が REM の状態を整理する separate PR 候補
- **シニアレビュー round 8 反映**:
  - **H1**: `Release.bat` の `findstr` validation コメントに「`findstr` 自体の起動失敗 (minimal WinPE / PATH 破損) も同じ skip path に落ちる」旨を追記。区別不可なので同一扱いは意図的だが、コメントが反映していなかった
  - **M2**: catalog ⇔ call site 整合性の最終 sweep。`Resolve-MsBuild` の vswhere call site (CAPTURE_STDOUT 該当) に label が欠落していたため追加。これで全 6 件の native `&` call site にパターンマーカー揃った
  - **M3**: PS 7.3+ の `$PSNativeCommandUseErrorActionPreference` (default `$true`) が `& cmd` の非ゼロ exit code を terminating error 化する仕様を集約コメントに追記。本スクリプトの「2>&1 を外して `$LASTEXITCODE` で判定」イディオムが PS 7 で silent regression する可能性 + 回避策 (`$false` 固定 or try/catch) を記録
  - **L1**: `Release.bat` の `setlocal enabledelayedexpansion` で引数中の `!` が消費される副作用を docstring に明記
  - **L2**: anti-pattern の「変数 capture なし版」が現実に書かれる経緯 (副作用 only call で stderr も console に出したい意図の typo) を 1 行追加
  - **L4**: chcp 65001 skip path で日本語 echo が文字化けする旨を ASCII 1 行で改めて警告 (line 89-90 の `[WARN]` だけでは見落とされる可能性に対する保険)
  - **L5**: `Get-BundleReleaseNotes` の `\Z` コメントを精度向上。現実の発火条件は「初回 Bundle release + 後続セクション未追加の極初期状態」のみで、汎用的な「セクション順変更時」は誤誘導
  - **H2 → 別 issue 化 (#141)**: `gh release view` の exit code 単独依存による silent false-negative。zip ビルド完了後に fail する path が残るが、本 PR スコープ外で `--json id` への移行を別 issue として trackable 化

### [Release Tooling v0.1.5] - 2026-05-11

#### Fixed

- **`Release.bat` ダブルクリック / ターミナル実行で何も出力されない問題を修正**: リポジトリの `.gitattributes` に `* text=auto eol=lf` がデフォルト設定されており、checkout 時に `Release.bat` も LF 改行に強制されていた。**cmd.exe は LF only の bat を正しくパースできない**ため、ダブルクリックしても無音で fail していた (process は起動するが何も実行されない)
  - `.gitattributes` に `*.bat text eol=crlf` / `*.cmd text eol=crlf` 例外を追加し、`.bat` / `.cmd` ファイルは checkout 時に CRLF 改行に強制
  - `Release.bat` 自体も UTF-8 BOM + CRLF に書き換え (旧 SJIS 形式は VS Code 等のモダンエディタで開くと文字化けして編集体験が悪い、新形式は cmd.exe / エディタ両方で正しく扱える)
  - `Release.bat` 冒頭で `chcp 65001 >nul` を発行して UTF-8 codepage を強制 (念のための保険、cmd.exe の UTF-8 BOM 認識挙動が環境依存のため)。exit 時には元の codepage を復元
  - codepage 取得失敗時 (chcp 出力フォーマットが想定外のロケール等のレアケース) は `chcp 65001` への切替自体を skip して呼び出し元 cmd 窓への副作用を回避、警告メッセージを表示
  - 警告メッセージは **英語先 + 日本語後** の併記 (失敗経路では UTF-8 codepage 未切替で日本語が文字化けする可能性が高いため、ASCII で確実に届く英文を先頭に配置)
  - `setlocal` の endlocal が `chcp` を復元しない (chcp は console-wide な状態) ため明示復元が必要、というハマりやすい挙動の経緯をコード上に明記
  - **BOM 認識不能環境での脱出経路** (Win 10 1809 以前の古い cmd.exe build 等) を docstring に記録: 「BOM 外して UTF-8 (no BOM) + CRLF に戻し、chcp 65001 より前の REM / echo は ASCII 化」の 3 ステップ
  - `Release.bat` の docstring に CRLF 必須の経緯を追記

### [Release Tooling v0.1.4] - 2026-05-11

#### Fixed

- **`-DryRun` モードでも GitHub preflight が走る問題を修正 (Codex P2 #137)**: 旧実装は `-DryRun` 時も `-SkipUpload` がなければ `gh auth status` / `gh release view` を呼び出していた。`-DryRun` は zip 化と upload を skip するモードのため、preflight だけ network 必須にする意味は無い。gh 認証なし環境やオフライン環境で `-DryRun` 単体実行が fail していた問題を解消。v0.1.3 で導入した `-Offline → -SkipUpload promote` ロジックを拡張し、`if (($Offline -or $DryRun) -and -not $SkipUpload) { $SkipUpload = $true }` の形に統合。docstring も `-DryRun` の説明を更新

### [Release Tooling v0.1.3] - 2026-05-11

#### Fixed

- **manifest sync 後の working tree 再検証を追加 (Codex P1 #137)**: `Test-Preflight` で working tree clean を要求した後、`Set-ManifestVersions` が `project.godot` / `export_presets.cfg` を書き換えると tree が dirty になり、その状態で packaging + tag 付けが進むと **source ↔ artifact traceability が崩れる** 問題を解消。新規 `Assert-WorkingTreeClean` 共通関数を切り出し、preflight と sync 後の 2 タイミングで呼ぶように変更。sync 後の dirty 検出時は「`Set-ManifestVersions` が書き換えた差分をコミットしてから再実行」という具体的なメッセージで fail (`Set-ManifestVersions` は idempotent なので 2 回目以降は no-op)
- **`-Offline` モードで GitHub preflight が走る問題を修正 (Codex P2 #137)**: 旧実装は `-Offline` 時も `-SkipUpload` がなければ `gh auth status` / `gh release view` を呼び出していた。オフライン環境ではこれらが必ず fail するため `-Offline` フラグが advertise 通り機能していなかった。`param` block 直後で `if ($Offline -and -not $SkipUpload) { $SkipUpload = $true }` の自動 promote を追加し、`-Offline` 指定時は upload 関連の preflight + 実 upload を全て skip する形に統一。docstring も `-Offline` の説明を更新

### [Release Tooling v0.1.2] - 2026-05-11

#### Fixed

- **`export_presets.cfg` が gitignore で除外されてクリーン clone で Release.ps1 が即 fail する問題を修正 (Codex P1 #137)**: Godot のデフォルト `.gitignore` テンプレが `export_presets.cfg` を除外する慣習で、本プロジェクトの初期 `.gitignore` もそれを踏襲していた。しかし Release.ps1 の `Set-ManifestVersions` が `application/file_version` を書き換えるため必須ファイルになっており、別開発者の clean clone では `ReadAllText` の段階で fail していた。`.gitignore` から `export_presets.cfg` を除外し tracked 化、初期の Godot エディタ生成版を repo に含める形に変更
- **`bin\Release\` 再帰コピーで前回ビルド時の runtime ゴミが zip に混入し得る問題を修正 (Codex P1 #137)**: 開発者が Manager を直接 `bin\Release\` から起動した場合、log / db / backups 等の runtime ファイルが `bin\Release\` に発生する。`Get-ChildItem -Recurse -File | Where Extension -ne '.pdb'` で拾ってると、これら不要ファイルが release zip に紛れ込む可能性があった。`Build-Manager` の msbuild 直前に `bin\Release\` を `Remove-Item -Recurse -Force` で完全削除し、毎回クリーンビルドする形に変更。これで bin\Release/ には msbuild が生成した正規の output のみが残り、コピー対象の予期せぬ追加が起きない

### [Release Tooling v0.1.1] - 2026-05-11

#### Changed

- **`RELEASE_VERSION` ファイル廃止、`CHANGELOG.md` を Bundle version の SoT に統合 (#108 Phase 1)**: 旧設計では `RELEASE_VERSION` ファイル (リポジトリルート) と `CHANGELOG.md` の `### [Bundle vX.Y.Z]` エントリの 2 箇所にバージョン情報を持つ二重管理だったが、整合性チェックが必要になり煩雑だったため、CHANGELOG 1 本に集約
  - `Release.ps1` の `-Version` 引数を optional に変更、省略時は `CHANGELOG.md` の最上段 (最新) の `### [Bundle vX.Y.Z]` エントリから自動取得
  - `-Version` を明示指定した場合は CHANGELOG の最新版数と一致するか検証し、不一致なら fail
  - `Release.bat` から `RELEASE_VERSION` ファイル読み取り処理を削除、引数を Release.ps1 にそのまま forward する形に簡素化
  - SPEC §3.7.7 / AGENTS.md "Release and Versioning" / §3.7.8 チェックリストも同方式に対応する形に更新

### [Release Tooling v0.1.0] - 2026-05-11

#### Added

- **`Release.ps1` を repo root に新設 (#108 Phase 1)**: Launcher (Godot CLI export) + Manager (msbuild Release ビルド) を一括ビルドし、`release/v<version>/files/` に staging、`release/GCTonePrism_v<version>.zip` を生成、`gh release create` でアップロードする PowerShell スクリプト
  - **Bundle version 制度**: `CHANGELOG.md` の最新 `### [Bundle vX.Y.Z]` エントリで Bundle 版数を管理。zip タグは `v<X.Y.Z>` 形式で既存の `Launcher_v*` / `Manager_v*` tag との命名衝突を回避
  - **Godot エディタ + export templates の自動 DL**: `project.godot` の `config/features` から major.minor を読み取り、`$GodotPatchTable` で patch をピン留めして `tools/godot/<patch>/` と `%APPDATA%/Godot/export_templates/<patch>.stable/` にキャッシュ。SHA256 検証 + 3 回 retry + キャッシュ命中時 skip + 古い version は最大 2 件まで自動削除 (AppData 側は `.gctone_managed` マーカー方式で外部管理 templates を保護)
  - **DL 進捗表示**: PS 5.1 標準の `Invoke-WebRequest` はプログレスバー描画バグで DL が極端に遅くなるため、`System.Net.Http.HttpClient` でチャンク読み出し + 50MB / 5 秒ごとに `MB / MB (MB/s)` を表示
  - **NuGet 自動 DL**: `tools/nuget-<version>.exe` にバージョンピン留めでキャッシュ。`$NugetPinnedVersion = '6.10.0'`
  - **MSBuild 自動検出**: `vswhere` → PATH の順で VS / Build Tools を検出。Manager コードは C# 7+ (ValueTuple / string interpolation 等) を使うため Roslyn を含む MSBuild 14+ が必須で、Windows 同梱 .NET Framework MSBuild は不使用。MSBuild 未検出時は VS Build Tools のインストール手順 (https://aka.ms/vs/17/release/vs_BuildTools.exe、~1-2GB) を案内する詳細エラーで fail
  - **`nuget restore` の x64/x86 漏れ修正**: `Stub.System.Data.SQLite.Core.NetFramework` の packages.config 形式 restore で `build/net46/x64/SQLite.Interop.dll` と `x86/` が展開されない既知問題を、nupkg を直接 `System.IO.Compression.ZipFile` で開いて欠損ファイルだけ抽出する形で防御
  - **Process.Start ベースの外部プロセス呼び出し**: PowerShell 標準 `&` (call operator) は大量の stdout で非同期 return することがあり、`Start-Process -ArgumentList` は配列要素にスペースを含むと argument 分割するため、`ProcessStartInfo.Arguments` を自前で quoting する形を採用 (`Invoke-ExternalProcess` ヘルパー)
  - **`-DryRun` / `-SkipUpload` / `-Force` / `-Offline` / `-GodotExe` / `-GodotPatch` / `-MsBuildExe` / `-NugetExe` 引数**: 開発・運用シナリオに合わせて部分実行可能
  - **export_presets.cfg / project.godot の version 自動同期**: `version.gd` の MAJOR/MINOR/PATCH を SoT として `application/file_version`、`application/product_version`、`config/version` を Release.ps1 が機械的に書き換え (`Write-FileUtf8NoBom` で BOM なし UTF-8 で書き出し、Godot ConfigFile パーサと互換)
  - **release_notes は CHANGELOG.md から自動抽出**: 該当 Bundle セクション (`### [Bundle v<X.Y.Z>]`) をパースして `gh release create --notes` に渡す。`release_notes/` ディレクトリは持たない（CHANGELOG が SoT、重複記述なし）
- **`Release.bat` を repo root に新設**: `Release.ps1` のラッパーバッチ。`RELEASE_VERSION` ファイルを読んで `-Version` を自動補完するため、本番運用は `.\Release.bat` 1 発で完結（ダブルクリック実行も可能）。引数を Release.ps1 にそのまま forward する仕組みのため `.\Release.bat -DryRun -SkipUpload` 等の組み合わせも可能。`-NoPause` 引数で CI / 自動化用の pause 抑止にも対応 (Shift-JIS + CRLF で保存、cmd.exe の日本語環境互換)
- **`.gitignore` 拡張**: `release/` (Release.ps1 生成物) / `tools/godot/` / `tools/nuget-*.exe` (auto-DL) を git 追跡対象から除外

---

## Companions（runtime exe 群）

SPEC §2.4 で定義される「主要 (Launcher / Manager / Monitor) を補助する独立 exe 群」の **runtime exe** の変更履歴。`Companions/Updater/TonePrism_Updater.exe` (Manager 自身の dir 置換用) + `LauncherAgent` (#30/#101/#216、probe/sensor/focus を統合した Launcher 補助の常駐エージェント、旧 WindowProbe を吸収) の deployment 配置と整合。本 section は **#160 で `## Updater (Companions/Updater)` から rename + 一般化**、`## Release Tooling` (= build / 配布スクリプト) と責務分離 (= 後者は build 時のみ動く scripts、本 section は runtime exe)。SPEC §2.4 / §3.7.4 参照。

### [Updater v0.2.2] - 2026-09-04

#### Fixed — アプリ内アップデートで Manager だけ更新されない不具合（`fix/updater-64bit`、#440）

- **管理ソフトの「アップデート」タブから更新すると、Manager だけが古いまま残る**不具合を修正しました。しかも Launcher と CHANGELOG は先に更新されるため、**アップデート後の画面は「最新版を実行中です」と表示**します（実際には古い Manager が動いています）。**Bundle v0.9.0 以降ずっと発生していました。**
- **原因**: Updater は `PlatformTarget=AnyCPU` でビルドされていますが、.NET Framework の exe は **`Prefer32Bit` の既定が true** のため 32bit プロセスとして起動します。一方 Manager は Bundle v0.9.0（#258）で .NET 10 の **64bit 単一ファイル**になりました。32bit の Updater からは 64bit の Manager プロセスの `MainModule` を読めず（「32 ビット プロセスは、64 ビット プロセスのモジュールにアクセスできません」）、`ProcessWaiter` がこれを **「Manager は既に終了済み」と誤判定**して待機を skip → Manager が起動したまま `Manager` → `Manager.bak` の rename に進む → アクセス拒否 → ロールバックして「内部エラー」。
- **対処 1（原因）**: `Prefer32Bit=false` を明示し、Updater を 64bit で動かすようにしました。
- **対処 2（同種の再発防止）**: `MainModule` を読めなかったときに**「識別できない」を「終了済み」と読まない**ようにしました。判定を諦める方向の「安全側」は kill の話であって、待機の話ではありません。プロセス名の一致は直前に確認済みなので、**同名プロセスが生きている以上は待つ**方に倒します。
- **ただし無限には待ちません（60 秒で中止）**: Manager は通常経路で `--wait-timeout 0`（無制限）を渡すため、待つ方に倒しただけだと、恒久的に `MainModule` を読めない生存プロセス（権限差・ウイルス対策による module 列挙阻害など）に当たったときに**永久ループ**します。そのとき Manager は既に終了処理へ入っていて画面が無いので、ユーザーからは「**管理ソフトが消えたまま何も起きない**」に見えます。**待たずに進むのも、無限に待つのも駄目**なので、同一性を確認できない状態が 60 秒続いたら Manager dir に触らずに中止し（exit 3）、「管理ソフトを手動で閉じてからもう一度」に倒します。あわせて警告ログは既存の待機ログと同じ間引き（5 秒に 1 回）にしました（毎 poll で出すと無限待機時に 2 行/秒でログが肥大します）。
- **同一性を確認できないプロセスは kill 対象から外しました**: 新しい経路は `MainModule` の path 検証を通さずにプロセスを返すため、そのままだと `--force-kill` を配線し直した瞬間に「同名 exe の別 install を巻き添えで落とす」経路（path 検証がまさに防いでいる事故）が読み取り不能ケースについてだけ復活します。現在 `--force-kill` は未配線ですが、戻ったときに気づけないので今のうちに分けました。
- **修正版は自分で配れます。`Install.bat` での入れ直しは不要です**: Manager の更新フローは `Companions/Updater` を置換してから（Step 9）Updater を起動する（Step 10）ため、次回のアプリ内アップデートでは**修正版の 64bit Updater が使われます**。この順序は壊れている install に入っている古い Manager（v0.9.0 の 0.27.9）にも既にあることを、リリースタグ `v0.9.0` のコードで確認済みです。
- **「最新版を実行中です」の誤表示は Manager v0.34.1 で対処しました**（詳細はそちらのエントリ）。CHANGELOG.md のコピーは「Updater の **spawn 成功**後」に後置されていますが、spawn した Updater が**その後で**失敗するケースは想定されていませんでした。
- bump 判断: bugfix のみ。**patch（v0.2.1 → v0.2.2）**。

### [LauncherAgent v0.3.0] - 2026-06-12

#### Changed (#258 PR4.x — net48 → net10 + self-contained single-file)

- **net48 → net10 移行 + SDK-style 化**: classic csproj（`<Reference>` のみ）→ SDK-style（`net10.0`・非 -windows）。依存ゼロ・WinForms/WPF 不使用の純 Win32 P/Invoke + UDP socket のため `net10.0` base runtime で十分（WindowsDesktop ランタイム不要＝Manager の ~176MB より小さい **~73MB**）。`AppDomain.CurrentDomain.BaseDirectory`（single-file で well-defined）・Sockets・P/Invoke は全て net10 in-box で **コード無改変**（`ConfigurationManager`/`Registry`/`System.Drawing` 等の net48-ism は grep 0 件）。
- **配布 = self-contained single-file**: `Release.ps1 Build-LauncherAgent` を `msbuild` → `dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true` に変更（配布形態を Manager と揃える）。出力 = `TonePrism_LauncherAgent.exe` 1 個、旧 `.exe.config` は net10 で非生成のため expected-files（`$script:BundleManifestFiles`）から撤去。`ValidateStagingLegacy` には元々 LauncherAgent を載せない方針（SPEC §3.7.8）のため touch 不要。
- **App.config 削除**（`ConfigurationManager` 不使用）。Release.ps1 の `.NOTES` / ビルド手順コメントを「LauncherAgent = net10 dotnet publish、Updater = net48 msbuild（番人）」に更新。
- **`SYSLIB0014` 抑止 + net10 shim 挙動差の明記**: サービスモードのネット速度テスト（`Internet()` / #287）が `HttpWebRequest` + `ServicePointManager` を使う。net10 では obsolete だが shim として動作。ただし **net48 と挙動が変わる点**あり（レビュー）: `ReadWriteTimeout` が **no-op**（ストリーム読み込み中の stall が 8s で中断されず、低速/切断時に最大 ~10s 余計にハングしうる）、`DefaultConnectionLimit=64` も実質 no-op（SocketsHttpHandler 既定で接続数は実質制限なし＝並列 DL は維持）。機械的移行で速度テストのロジック書き換えは behavioral リスクのため `<NoWarn>SYSLIB0014</NoWarn>` で抑止し、**HttpClient 化（読み込みタイムアウトを CancellationToken で再導入）は #360 で追跡**。実機での「低速/切断時にハングせず終了」確認は #287/#360。
- **single-file 不変条件ガード**: Manager の `Assert-ManagerSingleFile` と対称に **`Assert-LauncherAgentSingleFile`** を追加（同一 publish フラグを使うため、staging の `Companions/LauncherAgent/` が `TonePrism_LauncherAgent.exe` 1 個であることを `Build-LauncherAgent` 直後に machine-enforce。`Assert-ExpectedFiles` は presence のみ検証で sidecar 余剰を見ないため、`createdump.exe` 等の silent 混入を upload 前に fail-fast）。
- **版数公開前ゲート**: Manager の `Assert-PublishedManagerVersion` と対称に **`Assert-PublishedLauncherAgentVersion`** を追加（レビュー指摘）。net10 apphost stamp 由来の exe FileVersion ↔ SoT（AssemblyInfo）を `Build-LauncherAgent` 直後に hard fail。**§3.7.8 のゲート判定軸を「表示 ∧ stamp」→「stamp パイプラインの有無」に修正**: 当初「LauncherAgent は版数タブ未掲載（#310）＝対象外」としたが、stale stamp の実害＝「誤版数を焼いた exe を zip 同梱」は**表示の有無と無関係**に起きるため撤回し、stamp 経由（net10 apphost）の LauncherAgent も Manager と対称にゲート。`Assert-ComponentVersions` に LauncherAgent SoT 読取を追加。
- **（レビュー）`AppendTargetFrameworkToOutputPath=false` のコメント精緻化**: 本フラグは dev `dotnet build` 出力を `bin/{Release,Debug}/` 直下にフラット化し、Launcher の dev 起動 fallback（`launcher_agent.gd` `_EXE_CANDIDATES` が `bin/Release`・`bin/Debug` を直探索）を成立させる **load-bearing** な設定。旧コメントの「Release.ps1 が bin\Release\ を直参照」は誤帰属（リリースは `dotnet publish -o bin\Release\publish` を使う）で、消すと dev 起動が無言で壊れる温床だったため実態に修正。
- bump: net10 移行という土台変更のため minor（v0.2.1 → v0.3.0）。Bundle 反映は v0.9.0。
- 検証: net10 single-file publish 実測（`TonePrism_LauncherAgent.exe` 1 個・73MB・FileVersion **0.3.0.0**＝SoT 一致）。`Release.ps1 -DryRun` で Bundle v0.9.0 を全ビルド + 全ゲート緑（`Assert-LauncherAgentSingleFile` 含む）。常駐 probe/sensor/focus + UDP handshake + HOME overlay の実起動 smoke と net10 self-extract 経路は **pre-release / 部活で実機初確認**（コード読みでは確定不能）。

**Note**: LauncherAgent は Manager「アップデート」タブの版数**表示**は未実装（#310 で追加予定）だが、exe 版数の**公開前ゲートは表示有無と独立に追加済**（上記・§3.7.8 改定）。#310 で表示を足す際は VersionInventory に LauncherAgent 行を追加する。

### [LauncherAgent v0.2.1] - 2026-06-09

#### Fixed (#314 — 排他フルスクリーン系（WOLF等）で中断オーバーレイの表示/復帰が不安定）

- **強制前面化 `ForceForegroundHwnd` で、対象ウィンドウが最小化されていれば `SW_RESTORE`（復元）を使うように修正**（`Win32Windows.cs`、従来は `SW_SHOW` 固定）。`SW_SHOW` は最小化ウィンドウを元に戻さないため、resume（`GameSession.resume` → `focus` → `ForceForeground`）で最小化されたゲームが前面に戻らず、プレイ中シーンに取り残されていた。
  - **背景**: WOLF RPG（ウディタ）等の排他フルスクリーンゲームは、HOME 押下でオーバーレイ窓に前面を奪われると**自分から最小化して排他を手放す**（だからオーバーレイ自体は出る）。詰みの実体は「オーバーレイが出ない」ではなく「**続けるで最小化ゲームを復帰できていなかった**」こと。最小化時のみ `SW_RESTORE`、非最小化は従来どおり `SW_SHOW`（最大化を巻き込まないため）。`IsIconic` で判定。`focus`(pid) / `focus_hwnd` 双方がこの関数を通るので 1 箇所で両対応。
  - **補足（#314 の見え方）**: 「排他フルスクリーン＝原理的にオーバーレイ不可」は **真の排他（古い DirectDraw/DirectX、Windows の Fullscreen Optimizations 対象外）に限る**。モダンエンジン（Godot/Unity/Unreal）や FSO 対象は実体がボーダーレス（DWM 合成）でオーバーレイは出る。WOLF 等の真の排他でも自分から最小化する型は本修正で救える。残課題は「最小化せず入力を握ったままの回」のたまの操作不能（オーバーレイは前面化できているが排他ゲームが入力を握る）で、**HOME 再押下で復帰**できるため強制最小化（要・ゲーム単位フラグ）は過剰として **#337** に保留（guideline #133 で運用吸収）。
- **`ForceForegroundHwnd` を前面化が反映されるまで数回リトライするよう変更**（最大3回・各60ms、1回目成功で即抜け）。Windows の foreground-lock や、排他FSゲームが最小化する直後の前面遷移レースで 1 回の `SetForegroundWindow` が弾かれ、**HOME でオーバーレイが出ずプレイ中画面だけになる／オーバーレイのフォーカス（グロー）が動かない**ことがあったため。各試行で foreground スレッドを取り直す（ゲーム最小化で別窓が前面化しても追従）。`focus`(pid) / `focus_hwnd`（オーバーレイ表示）双方がこの関数を通るので一括対応。判定は `GetForegroundWindow()` の実結果で行う（`SetForegroundWindow` の戻り値は foreground-lock 下で不正確なため最終判定に使わない）。
- レビュー対応（堅牢化）:
  - **タイトル無し＋最小化の窓を `focus`(pid) 経路で取りこぼさない**よう、`IsMeaningfulVisibleWindow(acceptMinimized)` と `FindTopLevelWindow(acceptMinimized)` を引数化し、**`ForceForeground`（focus）経由のみ `true`**を渡す。最小化窓は `GetWindowRect` がオフスクリーン小サイズを返し size 判定を通らないため、タイトル無し排他FS窓が最小化した瞬間に発見できず復帰しなかった。**`PlaceWindowCentered`（モニタ寄せ）と probe 経路は従来どおり `false`**＝最小化窓を移動対象にしない／「可視」と誤検知して PLAYING/anomaly を狂わせない（共有ヘルパの暗黙挙動変更を回避）。WOLF 等タイトル有りは元から救えていたが本対応で取りこぼしクラスも復帰可。
  - リトライ早期 break を `beforeFg == target && !IsIconic(target)` に厳格化（「前面かつ最小化」を成功扱いで返して最小化のまま取り残すのを防止）。
  - `maxAttempts` を 4→3 に（#216 anomaly recovery が 500ms 間隔で focus 再発行する外側ループなので、失敗継続時に単一ループスレッドを長く塞いで probe/HOME 検知を鈍らせない）。
- 検証: VS MSBuild で Release ビルド成功（compile 確認）。**※実機で (1) HOME → オーバーレイメニューが毎回出てフォーカスも動く (2) 「続ける」でゲームに復帰できる ことは pre-release で目視**（前面化レースは確率的なので連続試行で確認）。

### [LauncherAgent v0.2.0] - 2026-05-26

- **速度計測コマンド `speedtest <run_id> <共有ファイルパス>` を追加** (サービスモードのネットワーク接続テスト用。`run_id` は古い遅延結果の取り違え防止用に Launcher が要求と結果を照合する識別子)。Godot 単体では正確に測れない 2 つを Companion で実施し `{"type":"speedtest","kind":"internet|server","ok":..,"text":".."}` イベントで返す:
  - **インターネット速度**: `HttpWebRequest` を **6 本並列**で約 5 秒回し合計バイト/秒から Mbps を算出。各接続は **75MB を1回要求して締め切りまで流しっぱなし**にする (小さいサイズで細切れに再リクエストするとリクエスト準備の隙間＋スロースタート再開で大幅に過小評価される: 25MB だと 50〜60Mbps しか出なかった)。測定サイト同様の継続ストリーム並列方式で実速に近づける (例 232Mbps)。**Cloudflare `__down` は bytes が大きすぎると 403 を返す (75MB はOK / 100MB は403) ため 75MB が上限**。失敗時は理由を「測定不可 (HTTP 403)」等と結果に表示。短時間の連打は 429 (Too Many Requests) になり得るが現地での単発利用では問題なし。
  - **共有サーバー読み込み速度**: `CreateFile` に **`FILE_FLAG_NO_BUFFERING`** を指定して **OS ファイルキャッシュを回避**し実 MB/秒を測る (Godot の `FileAccess` はキャッシュ回避不可で、頻繁に読まれる DB は RAM キャッシュから読まれて実態と乖離するため)。`VirtualAlloc` でセクタ境界の 1MB バッファを確保し `ReadFile` でシーケンシャル読み (最大 100MB)。**計測対象は Launcher から渡された `games` フォルダ配下で最も大きいファイル** (`ResolveReadTarget`: `DirectoryInfo.EnumerateFiles` の `FileInfo` は列挙時にサイズを保持するため SMB 上でも追加 stat 不要で速い、時間予算 5 秒で打ち切り)。**exe を測らない理由**: Godot ゲームの exe は数百KBと小さく (本体は別の `.pck`)、量が少なすぎて速度がブレるため。実際の games ツリーには 286MB のプレビュー動画 (.mp4) / 284MB の .pck / Unity の 94〜106MB の .resS 等があり、最大ファイルを選ぶことで意味のある量 (100MB) を読める。
- 計測は専用バックグラウンドスレッドで実行し、メインループ (メッセージポンプ / 親プロセス監視) を止めない。

### [LauncherAgent v0.1.0] - 2026-05-23

> **命名**: 当初 `LauncherCompanion` で実装したが、`Companions/` 配下の命名一貫性 (Updater と同じ機能/役割ベース、カテゴリ名 "Companion" のスタッター回避) のため **`LauncherAgent`** にリネーム (#214、folder/csproj/AssemblyName/namespace `TonePrism.LauncherAgent`/exe `TonePrism_LauncherAgent.exe`/Godot autoload/ログ prefix `[LauncherAgent]` を一括更新)。本 entry は初版 v0.1.0 を最終形で記載。

#### Added (#30 / #101 / #216 — WindowProbe を統合した常駐エージェント)

Launcher 系の Win32 機能を 1 プロセスに集約した**常駐エージェント**。旧 WindowProbe (単発 CLI) を**置換・廃止**し、probe (窓状態監視) + sensor (HOME/Guide グローバル検知) + focus (前面化) を統合、Godot ランチャーと**双方向 localhost UDP** で通信する。

- **probe**: watch 中、指定 PID ツリーの可視/前面窓状態を内部ポーリングし、変化時 + 1 秒 keepalive で `window` イベント送出 (#101 起動中→プレイ中 / #216 前面化異常)。150ms ごとの WindowProbe プロセス spawn を廃し常駐ポーリング化。
- **sensor**: watch 中のみ HOME (`WH_KEYBOARD_LL`, down 遷移で 1 回) / コントローラ Guide (`XInputGetStateEx` ordinal #100) をグローバル検知し `trigger` イベント送出 → 中断オーバーレイ (#30) の開閉。同時押しコンボ (L3+R3 / START+BACK) は不採用 (HOME / Guide の 2 系統)。
- **focus**: `SetForegroundWindow` + `AttachThreadInput` でゲーム窓を強制前面化 (foreground-lock 回避、`focus <pid>`)。中断オーバーレイ窓だけを前面化する `focus_hwnd <hwnd>` も持つ (メイン窓を巻き込まない、2 枚構成 #214)。マルチモニタでは `watch <pid> <x> <y> <w> <h>` でゲーム窓をランチャーのモニタへ寄せる (`PlaceWindowCentered`)。
- **IPC**: 起動時に Launcher が event 受信ポートを bind → companion が cmd 受信ポートを自動 bind し hello イベントで通知 (固定ポート衝突なし)。event (window/trigger/log, JSON) ← / cmd (watch/unwatch/focus/focus_hwnd/quit, テキスト) →。Godot 4 は子プロセス stdout を逐次読めないため UDP を採用。
- **ログ**: 専用ファイルログ (`logs/launcheragent/`) + WARN/ERROR/主要イベントを UDP で Launcher へ転送 → launcher ログに `[LauncherAgent]` 付きで記録 (Manager のログ閲覧「Launcher タブ」に出る、Manager 改修不要)。
- **ライフサイクル**: Launcher 起動時に 1 個だけ常駐起動、parent-pid 監視で孤児時 self-exit、Launcher 終了で kill。
- **構成**: `Program.cs` / `Win32Windows.cs` (WindowProbe から移植) / `InputSensor.cs` / `Logger.cs` / csproj / App.config / AssemblyInfo。.NET Framework 4.8 / `TonePrism_<Name>` 命名 (SPEC §2.4)。中断オーバーレイのすりガラス背景用に試作した `ScreenCapture.cs` (画面キャプチャ) は、オーバーレイをライブゲーム透過方式 (#214) に変更したため撤去 (本 PR 内で追加→撤去、net zero)。

#### Removed — WindowProbe 廃止

`Companions/WindowProbe/` を削除し本 Component に統合。Release.ps1 を `Build-WindowProbe` → `Build-LauncherAgent`、`$script:BundleManifestFiles` / 実行順も WindowProbe → LauncherAgent に更新。Manager update-apply の Companions 置換 step は dir 列挙のため LauncherAgent を自動的に deploy/更新する。

### [WindowProbe v0.1.0] - 2026-05-21

初回リリース (#101 / #216)。指定 PID の**プロセスツリー (PID + 全子孫)** が可視ウィンドウ / 前面ウィンドウを持つかを判定する単発 CLI。Launcher の「ゲーム起動中 → プレイ中」遷移検知 (#101) と、ゲーム実行中のランチャー前面化異常検知 (#216) の共通基盤。

**CLI**: `TonePrism_WindowProbe.exe <pid>` → stdout 1 行で `visible_foreground` / `visible_background` / `not_visible` / `not_found` のいずれかを出力。終了コード 0=成功 / 2=引数エラー / 1=実行時例外。

**構成** (5 ファイル): `Program.cs` (entry + 引数 parse + 結果出力) / `Win32Windows.cs` (P/Invoke + 判定ロジック) / csproj / App.config / AssemblyInfo.cs。

**設計判断**:
- **プロセスツリー走査** (`CreateToolhelp32Snapshot` で PID + 全子孫を BFS): Launcher は `cmd.exe /C "cd /d <dir> && game.exe"` でゲームを起動するため握る PID は cmd.exe で、ゲームウィンドウは子の game.exe に属する。ランチャー型ゲームが孫プロセスを生むケースもあるため、PID 単体ではなく子孫まで辿る。
- **可視ウィンドウの判定** (`EnumWindows` + `GetWindowThreadProcessId` + `IsWindowVisible`): オーナーウィンドウを持つもの / `ConsoleWindowClass` (cmd 経由起動時に一瞬出るコンソール) を除外し、タイトルあり or 十分な大きさ (200px 以上) を「実ウィンドウ」とみなす。
- **前面判定** (`GetForegroundWindow`): 前面ウィンドウの所有 PID がツリーに含まれれば `visible_foreground`。#216 の前面化異常検知に使う。
- **ログファイルを作らない**: Launcher が ~150ms / プレイ確定後 ~1s 間隔で繰り返し呼ぶ高頻度ツールのため、起動毎ログファイル (Updater の `Logger.cs` 方式) は採らず stdout/stderr のみ。意味のある遷移ログは呼び出し元 Launcher 側で記録する。

**Updater との非対称**: CompanionsCommon 共有 lib は作らず P/Invoke を WindowProbe 単体に直接実装 (YAGNI、現状これを使う Companion は WindowProbe のみ。PauseOverlay #30 追加時に共通化を再検討)。.NET Framework 4.8 / `TonePrism_<Name>` 命名 (SPEC §2.4) は Updater 同様。

### [Updater v0.2.1] - 2026-05-19

#### Changed (#170 — copyright metadata sync)

`AssemblyInfo.cs:10` の `AssemblyCopyright` を `Copyright ©  2026` (著者名なし、年単独) → `Copyright © 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)` に書換、`LICENSE:3` / `README.md:96` と同期。Updater.exe を右クリック → プロパティ → 詳細の Copyright 表示が LICENSE と整合するようになる。

書式判断: copyright holder を `TonePrism Project` 単独に整理、`Kenshiro Kuroga` は `Lead maintainer:` 役割明示で併記、学校所属は個人側に attach (= project は #168 で汎用化したため学校に固有でない、所属は個人属性として attach する方が史実整合)。SPDX 慣用「`<Holder>` 単独 or `<H1>, <H2>`」から見ても dash 区切り「`A - B (Org)`」より明瞭、将来 contributor 追加時の拡張性も確保 (= `and contributors` 形式へ移行可能)。

marker 判断: `(c)` と `©` は **意図的に file family 別の convention を保持** する split (= 「literal 文字列 5 か所完全一致」ではなく「holder 文字列の semantic sync」を目的とする)。
- `(c)` group (3 file): `LICENSE:3` / `README.md:96` / `Launcher/export_presets.cfg:50` — MIT License spec の例文が `(c)` を採用しており LICENSE / README は同期、Godot export config は marker 規約なしのため元 file の `(c)` を維持
- `©` group (2 file): `Manager/Properties/AssemblyInfo.cs:13` / `Companions/Updater/Properties/AssemblyInfo.cs:10` — .NET / Visual Studio template default の `©` を維持 (= `dotnet new` 自動生成 marker)
- 法的同等性: 米著作権法は `(c)` と `©` を copyright notice として等価に認める、Windows file properties 上の表示も人間の読み取り意味は同一
- verify 手法: 単一 grep `Copyright.*Kuroga` ではなく 2 系統別個に `Copyright \(c\) 2025-2026 TonePrism Project` (3 hit) + `Copyright © 2025-2026 TonePrism Project` (2 hit) で sweep する

bump 判断: AssemblyInfo metadata 変更は SemVer 上 patch (0.2.0 → 0.2.1)。コード behavior は完全に無変更、build 出力の PE metadata だけが変わる。同様の sync 動機は `## Manager v0.12.1` / `## Launcher v0.6.1` も同時 bump、cross-cutting copyright 統一として 3 component 同期。

### [Updater v0.2.0] - 2026-05-19

#### Changed (#168 — 完全 rename + 配布対象拡張、破壊的変更)

Bundle v0.5.0 完全 rename の Updater 側 contribution。詳細は `## Manager v0.12.0` entry 参照、本 entry は Updater 単体の変更点のみ記録。

minor bump 判断: SemVer pre-1.0 原則 (= 0.x で breaking change は minor bump OK) に乗って 0.1.0 → 0.2.0。exe filename rename (`GCTonePrism_Updater.exe` → `TonePrism_Updater.exe`) は OS layer の breaking change だが、AGENTS.md「実機 OS との接点で `Updater.exe` のような汎用名は他アプリと衝突」原則の prefix uniqueness 維持目的は据置、prefix 文字列のみ brand に合わせて update。

- **exe filename rename**: `GCTonePrism_Updater.exe` → `TonePrism_Updater.exe` (`csproj` `AssemblyName` / `RootNamespace` 同期)
- **`Companions/Updater/GCTonePrism_Updater.csproj` → `Companions/Updater/TonePrism_Updater.csproj`** (= `git mv`)
- **C# namespace rename**: `namespace GCTonePrism.Updater` / `using GCTonePrism.Updater.*` → `TonePrism.Updater` / `TonePrism.Updater.*` (5 .cs file 内)
- **AssemblyInfo.cs metadata update**: `AssemblyTitle("GCTonePrism_Updater")` / `AssemblyProduct("GCTonePrism_Updater")` / `AssemblyDescription("Updates GCTonePrism Manager...")` → `TonePrism_Updater` / `Updates TonePrism Manager...` 同期 (+ `AssemblyVersion` 0.1.0.0 → 0.2.0.0)

### [Updater v0.1.0] - 2026-05-13

初回リリース (#108 Phase 3)。Manager 自身のファイル置換 + 再起動を担う最小 CLI。Windows のファイルロック制約「実行中のプロセスは自分自身を含むファイルを置き換えられない」を Manager に対してのみ解決する。Launcher / 常駐 Companions / shortcut bat は Manager UI 側 (§3.7.3、Phase 4) が直接置換できるため、Updater の責務は意図的に「Manager 置換 + 再起動」のみに絞られている。

**構成** (8 ファイル):
- `Program.cs` — entry + main flow (CLI parse → Manager 終了待ち → 置換 → 再起動)
- `CliArgs.cs` — `--staging` / `--manager-target` / `--restart-exe` / `--log-dir` / `--wait-timeout` / `--force-kill` / `--caller-pid` の parser
- `ProcessWaiter.cs` — Manager プロセス終了の polling。`--caller-pid` 指定時は `Process.GetProcessById(pid)` + ProcessName 検証で PID-only wait/kill (round 3 H1)、未指定時は `Process.GetProcessesByName("GCTonePrism_Manager")` の system-wide fallback。`--force-kill` 時の強制終了は bounded retry (`MaxForceKillAttempts = 3`)、`Process.GetProcessesByName` throw は連続 5 回で abort
- `FileReplacer.cs` — `Manager/` dir 単位の rename-rollback 置換。`Replace` (Step 1 rename + Step 2 copy の 2-step API) + `CleanupBak` (`.bak` 削除、caller が restart-exe 検証 OK 後に呼ぶ) + `RollbackFromBak` (`.bak` から復元、caller が検証失敗時に呼ぶ) の 3 つの API に分割 (round 1 H1 修正により API 分離)。概念的には「rename → copy → cleanup or rollback」の 3 動作を rename-rollback の atomic スナップショットで実現。user data は `<install>/` 直下にあり Manager dir の外なので carry-over 不要 (SPEC §3.7.3「保護の仕組み」構造的保護に従う)
- `Logger.cs` — Manager の `Services/Logger.cs` を簡略化、`Console.SetOut` フック無しの直接書込み式、出力先 `<install>/logs/updater/updater_<PCname>_<YYYY-MM-DD_HHmmss>.log`
- csproj / App.config / AssemblyInfo.cs

**Exit codes** (SPEC §3.7.4 / Program.cs docstring / `CliArgs.UsageText()` / PR #152 body と **5 者同期**、round 4 H-1 で 3 を分割 + M-1 で 1 を追記、round 5 H-1 で本 entry を 6 件→9 件同期、round 6 で 6 失敗時 rollback 仕様化):
- `0` 成功
- `1` 予期しない実行時例外 (Logger に stack trace、bug report 対象。parse 段階の例外は stderr のみ、round 6 Codex P2)
- `2` 引数エラー / 必須引数不足 / `--restart-exe` が `--manager-target` 外 等。**parse 段階のため Logger 未初期化、stderr のみ** (round 6 Medium-4、Phase 4 Manager UI は stderr capture 必須)
- `3` Manager プロセスが timeout 内に終了せず (`--force-kill` 未指定、付与か手動 close で再試行可)
- `4` ファイル置換に失敗 (rollback 実施済、auto-recovery 経路も同 code、SPEC §3.7.4 参照)
- `5` rollback にも失敗した致命的状態 (`.bak` から手動復元要)。round 6 で「新 Manager 起動失敗時の rollback も失敗」case を含む
- `6` 新 Manager.exe の起動に失敗 (Process.Start null/throw、**spawn 直後 early-crash** (500ms HasExited check)、restart-exe 不在 等)。**round 6 で .bak から旧 Manager を自動復元してから本 code を返す** (Codex P1 + Medium-5)
- `7` force-kill 試行が bounded retry (3 回) 超過 (permission denied 等、機械的再試行は無意味)
- `8` process enumeration が連続 5 回失敗 (IPC/WMI 一時障害、短時間後の再試行で回復見込み)
  - round 5 M-3 で timeout 経路は常に `3`、本 code 8 は「連続 N 回失敗で早期 abort」path 専用に限定 (両者排他)

**呼出し前提**: Manager UI (Phase 4) が事前に download / staging / Launcher / Companions / shortcut bat / Updater 自身の置換まで完了させた後、Manager が `Process.Start("Companions\Updater\GCTonePrism_Updater.exe", "--staging ... --manager-target ... --restart-exe ...")` で spawn する。Manager は spawn 直後に graceful 終了、Updater は ProcessWaiter で完全終了を確認してから Manager 置換に進む。

**動作確認**: ローカル単体テスト (staging dummy / target dummy / user data dummy) で Manager dir 置換 (Replace 2-step + CleanupBak) + user data 維持 + 前回 rollback 失敗状態からの自動復元 (round 2 Codex P1 #3) を確認。Manager UI 連携テストは Phase 4 で実施予定。

**詳細な review 経緯**: round 1〜6 のシニア + Codex bot レビュー対応の詳細は `## Release Tooling v0.1.11` 配下の各 round entry を参照 (AGENTS.md「他セクションから参照」原則準拠、round 6 Medium-3)。本 entry は Updater v0.1.0 の高レベル summary、各 round で塞いだ silent path / 規約整合は Release Tooling v0.1.11 entries に詳述。

---

## Launcher（ランチャー本体）

### [Launcher v0.15.0] - 2026-09-04

#### Added — 初回ゲーム起動時に中断メニューの案内を表示（`feature/launcher-pause-hint`、#344）

- **来場者がその日 1 本目のゲームを起動する直前に、やめかたを案内するダイアログを 1 回だけ出す**ようになりました。「ゲームを途中でやめたいときは HOMEキー（コントローラーは Guideボタン）」と伝え、OK を押すとそのまま起動します。
- **なぜ起動直前なのか**: やめかたを知らないとゲームから戻れずスタッフ呼びになる = 当日いちばん人手を食う事故。初回説明スライド（#253）でも触れられますが、来場者は読み飛ばしますし、遊ぶ頃には忘れます。**「これから遊ぶ」直前が最も文脈が近く刺さる**ため、そこに 1 回だけ置きました。
- **頻度は来場者ごとに 1 回**（同じ人の 2 本目以降は出しません）。フラグは `AppState.pause_hint_shown` に持ちます。
- **リセットは `screensaver.gd` の `_ready()` に置きました**。設計時の想定どおり `AppState.clear()` に紐づけると**案内が出ない来場者が出ます** — `transition_to_screensaver` の呼び出し 13 箇所のうち `clear()` を通るのは 2 箇所だけで、**「遊び終えて退出」「放置して帰る」という最も多い 2 つの帰り方が通りません**。しかも出ないのは前の人の帰り方次第なので、当日その場で再現できず、案内が出なかった来場者はやめかたが分からずスタッフを呼ぶ = この機能が解決しようとしている当の事態が起きます。スクリーンセーバーに着いた = 来場者が入れ替わった、は経路を問わず成立するので、1 箇所で全経路をカバーできます（初回説明 #253 と同じ「毎回が初回」の考え方）。`clear()` 側でも畳んでいますが、そちらは補助です。
- **出す位置は `_launch_game()` の冒頭・`GameSession.begin_launch` の前**。起動演出が始まる前なので干渉しません。OK のコールバックで `_launch_game()` を呼び直す形にし、**フラグは出す前に立てます**（後だと無限ループになりますし、ダイアログが何らかの理由で閉じられなかった場合も次の起動は素通りします — 案内が出ないことより起動できないことの方が来場者にとって重いため）。
- **サービスモードの試遊では出しません**。試遊は `_launch_game()` を通らず `GameSession.begin_launch` を直呼びするので、追加のガードは不要でした（コードで確認済み）。
- **検証**: Godot headless で 12 項目（フラグの初期値 / `clear()` でも畳まれる / **スクリーンセーバーの `_ready()` で実際に false に戻る** / 試遊経路が `_launch_game` を通らない / フラグを立ててからダイアログを出す順序）。
- **未確認（実機）**: 1 本目で出て 2 本目で出ないこと、スクリーンセーバーを往復すると再び出ること、パッドだけで OK を押せること。
- bump 判断: 機能追加（破壊的変更・DB スキーマ変更なし）。**minor（v0.14.0 → v0.15.0）**。

### [Launcher v0.14.0] - 2026-09-03

#### Added — サービスモードに「記録・アンケートの動作確認」を追加（`feature/launcher-survey`、#297 / #34 / #35）

- **点検画面に「6. 記録・アンケートの動作確認」を追加**（既存項目は 6〜14 → 7〜15 に繰り下げ）。開場前に「今日ちゃんと記録が取れる状態か」を 1 画面で確認できます。
- **なぜ専用画面が要るのか**: 既存の「ゲーム動作テスト」で試遊しても、**スタッフの試遊はプレイ記録から意図的に除外される**（#311、試遊が人気ランキングを汚さないようにするため）。つまり**試遊しても記録は 1 件も出ない**ので、「試して確かめる」が原理的に使えない。記録は文化祭当日にしか取れず取り直しも効かないため、確認する出口がどうしても必要だった。
- **確認する内容**: データベースが記録に対応しているか（v24 以降）/ 番号が未割り当てのゲームが無いか / `responses/` に実際に書き込めるか / 日付ごとの保存件数と最後の記録時刻 / アンケート 2 トグルの状態 / 直近ログの書き込みエラー。すべてに対処方法を添えた（「Manager を起動して更新してください」等）。
- **偽のレコードは書かない**: 書き込み可否は `.probe` ファイルで確かめる。本物のプレイ記録やアンケートを混ぜると集計が汚れるため（試遊を記録から除外している #311 と同じ理由。しかもスタッフは開場前に何度も押しうる）。`.tmp` / `.done` という拡張子にしてあるので、**`.json` は一度も作らない**＝件数カウント（`.json` のみ数える）にも採番走査（日付フォルダ配下の `.json` のみ見る）にも混ざらない。
- **probe は本物と同じ手順を通す**（作る → 書く → 成否確認 → **rename** → 削除）。rename を省くと、「作成は許可されているが rename は不可」な共有設定や、ウイルス対策ソフトが `.tmp` を掴んでいる環境で **probe だけ ✓ になり本物の記録は全滅する** — 診断画面が一番防ぎたい事態を見逃すため。
- **トグル状態の表示**: 「アンケートが 1 件も出ない」の原因が『壊れている』のか『設定で OFF にしてある』のかを現場で切り分けられるようにした。ピーク時に OFF にして戻し忘れる、が最も起こりやすい事故のため。
- **件数はファイル名を数えるだけ**で中身を開かない（ファイル名が `<unix_ts>-<game_no>-<uuid>.json` のため）。SMB 越しでも点検画面が固まらない。
- **検証中に silent pass を 1 件修正**: v23 の DB（`game_no` 列が存在しない）で未採番チェックのクエリが失敗した際、結果 0 件を「問題なし」と読んで **「✓ 全ゲームに番号が割り当てられています」と嘘の OK を出していた**。版数 NG のときはチェック自体を走らせず、かつ `query()` の戻り値を必ず見るようにした（AGENTS.md「silent failure / silent pass する path がないか」）。異常系を実際に流さなければ気付けない類のもの。
- **検証**: Godot headless で画面出力を 3 シナリオ確認（検証後削除）。正常系（v24・全採番済・記録あり・トグル OFF 表示）/ v23 の古い DB（対処付きで ✗、嘘の ✓ が出ないこと）/ 未採番ゲーム 2 本（本数と対処を表示）。
- **「4. ゲーム動作テスト」側にも注記を追加**: 試遊の選択肢の説明と実行画面の両方に「**試遊のプレイは記録に残りません**（人気ランキングを汚さないため意図的に除外）。記録が取れる状態かは『6. 記録・アンケートの動作確認』で確かめてください」を表示。**入口側にも書かないと「試遊できた＝記録も取れている」と誤解したまま開場**してしまい、当日ぶんの記録が丸ごと失われる（取り返しがつかないデータ）。
- **必要 DB 版数を定数化**（`MIN_DB_VERSION_FOR_RECORDS = 24`）: 判定は「以上」。これは「現在の版数」ではなく「`game_no` が導入された版数」なので `CURRENT_DB_VERSION` が上がっても追随させない。同一視すると、Manager だけ先にアップデートした正常な環境で「記録できません」と誤報する。
- **書き込みエラー欄の文言を実態に合わせた**（レビュー指摘）: 「直近のログに〜」と書いていたが、実際に見えるのは Logger のメモリ上リングバッファ＝**今回の起動以降**だけで、前回の起動で出たエラーは出てこない。0 件は「エラーが無かった」ではなく「今回はまだ書き込んでいない」場合もあるため、表示も「今回の起動以降」に限定した（診断画面が実際より広い範囲を保証しているように読めるのを避ける）。
- **docs**: 開場前チェックリストに項目を追加し、「**記録の確認は試遊ではできない**」旨を警告ボックスで明記。
- **書き込みエラーの判定根拠をログからカウンタへ移した**（レビュー指摘）: 「今回の起動以降、書き込みエラーは出ていません」の根拠が `Logger` の 400 行リングバッファだったため、**同じ起動の中でも古い行が押し出されて消える**。来場者が回った日の夕方には朝の失敗が見えなくなり、断言が嘘になる。`ResponsesWriter` のセッション通算カウンタ（Launcher v0.12.0）を根拠にし、成功件数も併記、失敗時は最後の理由と対処を出す。ログ由来の行は「参考（古い行は流れます）」として補助表示に格下げした。**この画面の存在理由が「嘘の OK を出さないこと」**なので、同じ画面の別経路に同種の嘘を残さない。
- **SPEC §機能23（サービスモードの項目定義 = SoT）を更新**（レビュー指摘）: §4.1 画面12 の参照側だけを「15 項目」に直して、参照先の §機能23 が 14 項目のまま残っていた。実装は 6 番に新項目を挿入して以降を繰り下げているため、**SPEC の番号が全部 1 つずれた**状態だった（スタッフ向け docs は正しく「6.」と書いていたので、SPEC だけが取り残されていた）。新項目を 6 番として追記し、7〜15 へ繰り下げ。
- **「番号の再利用」を検出できるようにした**（レビュー指摘）: 従来は「全ゲームに番号が割り当てられているか」しか見ておらず、**SPEC §7.5.3 が唯一の残存リスクとして名指ししているケース**（記録は残っているのに DB を古い状態へ復元した）を検出できないまま ✓ を出していた。この状態で新しいゲームを追加すると、削除済みゲームの過去記録を横取りする（JSON は番号しか持たないので誰も気づけない）。`settings.game_no_seq` と `MAX(games.game_no)`、および**記録ファイル名から読んだ最大番号**を突き合わせ、食い違えば ✗ と対処を出す。ファイル名を見るだけなので 1 ファイルも開かない。Manager 側も走査失敗時に警告を出すが**それは Manager のログにしか出ず**、スタッフが朝見るのはこの画面なので、ここでも判定する。
- **書き込み確認の後始末も戻り値を見るようにした**（レビュー指摘）: probe の作成・書き込み・rename はすべて戻り値を見て ✗ を出しているのに、最後の削除だけ捨てていた。残骸自体は無害（件数カウントも採番走査も `.json` しか見ない）だが、**消せない = 権限かウイルス対策の問題**という診断上意味のある信号を捨てることになる。この画面は同じ PR で silent pass を潰したばかりで「戻り値を必ず見る」を自分の規約にしているのに、同じ関数の中で 1 箇所だけ例外になっていた。成功と警告を分けて出す。
- bump 判断: 機能追加（点検画面の新項目）。**minor（v0.13.0 → v0.14.0）**。

### [Launcher v0.13.0] - 2026-09-03

#### Added — アンケート機能（`feature/launcher-survey-ui`、#297 PR3 / #35）

- **ゲームを遊び終えたときと、席を離れるときにアンケートを表示**するようになりました。★1〜5 の評価と、書きたい人だけが開く自由記述欄（200 字まで）を集めます。回答は 1 件 1 ファイルの JSON として `responses/surveys/YYYY-MM-DD/` に出力されます（SPEC §7.5.3）。
- **どのゲームの評価かを取り違えさせない**: ゲーム終了時は背面に `playing` シーンが残っており、そのゲームの背景画像と大きなサムネイルが既に表示されている。その上にダイアログを重ねることで、**サムネイル（視覚）＋ゲーム名（文字）の二重**で対象を示す。新しい全画面レイアウトを起こさずに解決している。
- **発火点の切り分け**: **ゲームを 1 本遊び終えたら、退出するかどうかに関わらず必ずゲーム個別アンケートを出す**。退出する場合はその後に全体アンケートを続けて出す（2 つ並ぶが、来場者はもう帰るところで、どちらも 1 タップでスキップできる）。遊び終えた瞬間が**そのゲームの評価を聞ける唯一のタイミング**で、「退出を選んだ」というだけで取り逃すのは損失が大きい（退出は普通にある終わり方）。ゲームを遊んでいない退出（カルーセル / ストアから）は全体アンケートのみ。
- **ゲーム個別は PLAYING 確定後（`playing` シーン）からのみ**出す — 起動に失敗して落ちた人に感想を聞かないため。**アイドルタイムアウトでのスクリーンセーバー復帰では出さない**（誰もいないため）。
- **全体アンケートに移る前に背面のサムネイルを隠す**: 直前までゲームを遊んでいた場合、背面にそのゲームのサムネが残ったままだと「今日は楽しめましたか？」がそのゲームへの質問に見えてしまう（取り違え防止の裏返し）。あわせて見出しの下に「展示全体についてお聞きします」と対象を明示し、個別アンケートとの違いを文言でも切る。
- **文言を通常の漢字表記に**: 「たのしかった？」→「このゲームは楽しかった？」、「こたえない」→「答えない」、「おくる」→「送る」、「★をえらんでください」→「★を選んでください」等。ひらがなに寄せすぎると幼く読め、来場者（中高生〜大人）に対して不自然だったため。ゲーム個別は見出しと対象名（「ゲーム名」）の両方で対象を示す。
- **登場・消滅アニメーションを既存ダイアログと共通化**: `DialogAnimator.animate_in` / `animate_out`（`DialogManager` / `ErrorManager` と共有）を使うようにした。自前で出し入れしていたため「アンケートだけ出方・消え方が違う」状態になっていた。消滅は**アニメ完了を待ってから**ポーズ解除と画面遷移を行う（先に遷移すると閉じるアニメの途中でシーンごと差し替わり、画面が飛んで見える）。
- **フォーカス枠を既存ダイアログと同じ動きに**: 枠が対象へ滑らかに移動・拡縮しながら追従し、ブリージング発光する共有枠。従来この動きは `common_dialog.gd` の `_process` に直書きで**再利用できず**、新規ダイアログは Godot 既定の白い矩形枠になっていた。再利用可能な **`FocusBorderMorph`（`scripts/focus_border_morph.gd`、新設）** に切り出して使用。各ボタンの `focus` スタイルは透明化し、共有枠 1 枚に一本化している（既存ダイアログと同じ流儀）。**`common_dialog.gd` 側の移行は #426 で別途**（全ダイアログが通る最頻経路で、かつ headless では見た目を検証できないため、文化祭直前に触るのを避けた）。
- **マウスカーソルの表示制御**（`common_dialog.gd` と同じ流儀）: マウスを動かしたときだけカーソルを出し、キーボード / パッド操作中は隠す。キオスクは既定でカーソルを隠しているため、これが無いとマウスで操作したい来場者がカーソルを見失う。逆に常時表示だとキー操作中に画面中央へ居座って邪魔になる。
- **★はフォーカスを当てただけでは点灯しない**（押して初めて点く）。当初はフォーカス移動でプレビュー点灯していたが、実機で見ると「カーソルを合わせた時点でもう評価が決まったように見えて気持ち悪い」ため撤去した。未確定と確定が色で区別できる方が押す前に迷える。位置はフォーカス枠が示すのでプレビューが無くても操作に困らない。あわせて**初期状態を明示的に全消灯**にした（プレビュー撤去に伴い必須 — 塗らないとテーマ既定の文字色のままで「最初から全部点いている」ように見え、未選択であることが伝わらない）。
- **スキップは保存しない**（SPEC §機能10）。無回答と区別できず★の平均も歪めるため。★未選択では「送る」を押せない（空の回答は集計を汚すだけ）。ESC もスキップ扱いにしている — 閉じる手段が無いと、適当な★を押して立ち去られる方が困るため。
- **入力欄は「フォーカス」と「編集」を分けた**（実機フィードバック）: 従来はフォーカスが入った瞬間に編集状態になり、キーで移動しているだけのつもりが文字入力モードに落ちて他のボタンと挙動が揃わなかった。**フォーカスが当たっただけでは編集せず**（他のボタンと同じく共有枠が付くだけ）、**決定キー / パッドの決定で編集開始**、`Esc` で編集終了してフォーカス状態に戻る。編集中は共有枠を出さない（キャレットが位置を示すので二重の指示になる）。案内文も状態で切り替える（「決定キーで入力できます」↔「Esc または Tab で入力欄から出る」）。感想欄の開閉に合わせてフォーカス経路も繋ぎ替える（畳んでいるとき見えない入力欄へ飛ぶと操作不能に見えるため）。
- **`Esc` は 1 回目で「答えない」にフォーカスを移すだけ**にし、同じ状態でもう一度押して確定する（誤爆で回答が消えるワンクッション）。**確認ダイアログは作らない** — アンケートは元々スキップ可能で失うものが無く過剰であるうえ、本画面も `DialogManager` と同じくツリーを止めているためダイアログを重ねるとポーズの二重管理になる。（走行中のゲームを kill する「退出する」は取り返しがつかないので確認が要る、という判断の差。#424）
- **非編集状態の入力欄から矢印キーで抜けられるようにした**（実機で発覚）: `TextEdit` は **`editable = false` でも矢印をキャレット移動として消費する**ため、「フォーカスは当たるが編集しない」状態を作っても矢印が食われて `focus_neighbor` が発火せず、**入力欄に入ると出られなくなっていた**。非編集時のみ矢印を自前で捕まえ、`_wire_comment_neighbors` が張った neighbor を読んで移動する（経路の定義を 1 箇所に保つため、neighbor をそのまま使う）。押せないボタン（★未選択時の「送る」）へは移さず「答えない」へ逃がす。左右は移動先が無いので消費だけする（放置するとキャレットだけ動いて「反応したのに何も起きない」状態になる）。編集中は従来どおり矢印がキャレット移動。
- **入力欄のフォーカス二重表示と文字色を修正**（実機で発覚）: focus スタイルの透明化を**ボタンにしか適用していなかった**ため、`TextEdit` は Godot 既定の focus 枠（`bg_a=0.75`）を描き続け、共有枠と**二重に出た**うえ「編集中は共有枠を隠す」処理をしても既定枠だけ残っていた。`TextEdit` にも透明な focus スタイルを適用。あわせて `font_color` / `font_readonly_color` / `caret_color` を明示（既定のままだと文字が薄く、さらに非編集状態＝フォーカスのみのときに `font_readonly_color` でより薄く見えていた。両者を同色にして状態で色が変わらないようにした）。
- **★のフォーカス色を通常色と一致させた**（実機で発覚）: `font_focus_color` だけ明るくしていたため、マウス操作で**共有枠が消えた後も★が明るいまま残り「選んだように見える」**状態になっていた。マウス操作で隠れるのは枠だけでフォーカス自体はコントロールに残るため。フォーカスの表示は共有枠 1 本に任せ、色では示さない（hover はマウスに追従して消えるので残す）。
- **ゲームパッドから編集に入れない穴を修正**: 決定の判定を `InputEventKey` ガードより後ろに置いていたため、パッドの決定（`InputEventJoypadButton`）が弾かれていた。
- **入力欄からキーボードだけで抜けられるようにした**（実機で発覚）: `TextEdit` は矢印をキャレット移動、Tab をインデントに使うため、通常のフォーカス移動では脱出できず**来場者が入力欄に閉じ込められる**。`Esc`（開いた場所＝感想ボタンへ戻る）と `Tab` / `Shift+Tab`（次/前のボタンへ）を明示的に割り当てた。Tab の飛び先は状態を見て決める（★未選択で「送る」が無効なら「答えない」へ）ので、押せないボタンに飛んで詰まらない。脱出方法は文字数ラベルに併記して見えるようにした（行を増やすとパネルの高さが変わるため同居させている）。
- **あわせてバグを 1 件修正**: `_unhandled_input` のコメントに「入力中は TextEdit がキーを消費するのでここには来ない」と書いていたが、**`Esc` は `TextEdit` が消費しない**。そのため修正前は**入力欄で `Esc` を押すとアンケート全体がスキップされて消えていた**（「入力をやめたいだけ」で回答ごと失う）。`accept_event()` で止めて 2 段階にし、コメントも実態に合わせた。
- **表示の on/off を Manager 設定から切り替え可能に**（`survey_game_end_enabled` / `survey_launcher_end_enabled`、既定はどちらも ON）。**トグルは表示直前に毎回読む**（キャッシュしない）ので、Manager で切り替えた瞬間に全キオスクへ効く。起動時に読んでキャッシュすると各 PC を再起動するまで反映されず（#263）、「混雑してきたから今すぐ止めたい」という本トグルの存在理由が消える。展示中に全台を再起動して回るのは運用上ありえない。
- **`settings_repository.gd` を新設**: これが **Launcher が `settings` テーブルを読む最初の経路**（従来 Launcher はゲーム情報とストア設定しか読んでおらず、Manager の設定は Launcher の挙動に影響しなかった）。真偽値は `"true"/"false"` と `"1"/"0"` の両方を解釈し、解釈できない値は既定値へフォールバックする（値が壊れているというだけで機能が黙って消えるのを避けるため）。
- **`survey_flow.gd`（autoload）に判定と進行を集約**: アンケートの発火点は 4 箇所あり、判定や「スキップは保存しない」の扱いを各所に散らすと少しずつズレる。呼び出し側は「アンケートを挟んでからこれをして」と後続処理を渡すだけにした。**どの経路でも必ず後続処理を呼ぶ**のが最重要の契約 — DB が開けない・画面が作れない等どんな状態でも、来場者を画面に閉じ込めない。
- **`survey_dialog.tscn` / `survey_writer.gd` を新設**: 画面は既存 `common_dialog.tscn` と同じ見た目に揃え、来場者から「いつものダイアログの一種」に見えるようにした。自由記述は既定で畳んであり、★だけ押したい人の摩擦を増やさない。空欄は空文字ではなく `null` で出力する（「書かなかった」と「空欄で送った」を集計側が区別できるように / SPEC §6.5）。
- **検証**: Godot headless で確認（検証後削除）。画面 — ★5 個生成 / ★未選択では送信不可 / 感想欄は既定で畳まれる / 200 字で切る / 送信後にスキップを押しても二重発火しない / **★は初期 0 個点灯・フォーカスしても 0 個のまま・押して初めて点く** / **入力欄で `Esc` を押すと感想ボタンへ戻りアンケートは閉じない・`Tab` で抜けられタブ文字も入らない** / **ボタン個別のフォーカス表示が 8 個すべて不可視**（共有枠と二重に出ないこと。当初これを「既存 `.tscn` と同じ値か」で確認していたため発光付きの値をコピーしたバグごと合格していた。「見えないこと」を直接確認する形に改めた）。フロー（実 DB 使用）— トグル ON で表示され★5 送信で JSON が出る / トグル OFF では表示せず後続処理だけ走る / 両経路とも後続処理が呼ばれる / 保存されるのはちょうど 1 件 / 送信後にツリーのポーズが解除される。**個別 → 全体の連鎖** — 個別を送信した直後に全体が表示される（`_show` の「表示中なら捨てる」ガードに引っかからない）/ 全体をスキップしても保存は個別の 1 件のみ / 後続処理が 2 回とも呼ばれる。
- **アンケートを放置すると自動的に閉じ、タイトル画面へ戻る**（レビュー指摘）: アンケート表示中は背後のシーンを止めているため、来場者が答えずに立ち去るとその台は**アンケートを出したまま固まり、次の来場者が触れない**（アイドル → スクリーンセーバーの復帰経路も止まっている）。開場中に誰も気づかなければその台は一日死ぬ。予告なく消すと「考えている途中で消えた」になるので 2 段階にし、残り時間を出してから閉じる。どんな入力でも 0 に戻るので、書いている人が巻き込まれることはない。**タイムアウトで閉じた場合は保存しない**（★を選んだだけで立ち去った状態を意思表示とみなすと、自由記述を書こうとして諦めた人の中途半端な評価まで混ざる）。**残り時間は既存のヒント行を書き換えて出す** — 別の確認ダイアログを重ねると、この画面と `DialogManager` の両方がツリーの停止を持ち、片方が先に解除して背面が動き出す（下記と同種の不具合）。
- **タイムアウトの行き先はタイトル画面**（「答えない」で断られた場合とは別扱い）: タイムアウト = その場に人がいないということなので、通常の後続処理（ゲーム個別アンケートなら選択画面へ戻る）へ進めると、**そこで通常のアイドルタイマーを最初から待ち直す**ことになり、無人の台がもう一度同じ時間だけ放置される。「人がいて断った」スキップと signal を分け、タイムアウトだけは後続処理を捨てて直接スクリーンセーバーへ戻す。
- **放置時間は通常のアイドル復帰と共有**（`IdleManager.IDLE_WARNING_TIME` / `IDLE_RESET_TIME`）: 来場者から見ればアンケート画面も通常画面も同じ「放置」で、画面ごとに戻るまでの時間が違う理由が無い。警告の文言も通常のアイドル警告に揃えた（行き先が同じなので、アンケート中だけ違う言い方をすると別の何かに見える）。数字を書き写すと、キオスクの放置ポリシーを調整したときに片方だけ古い値のまま残る。
- **ポーズの二重所有を封じ込めた**（レビュー指摘）: `DialogManager` は自分が出したダイアログの消滅アニメーションが終わった時点で無条件にツリーの停止を解除するが、退出確認 → アンケートの経路では**その頃すでにアンケートが出ている**。結果、退出確認が消え終わる 0.2 秒後に背面が動き出し、(1) アンケート操作で背面のカルーセルも一緒に動く、(2) 背面のアイドルタイマーが進んでスクリーンセーバーへ遷移しアンケートだけが画面に残る → 内部状態が「表示中」のまま残り**以降そのキオスクではアンケートが二度と出なくなる**、という壊れ方をしていた。背面の入力ハンドラは軒並み `if get_tree().paused: return` で守られているため、**停止さえ維持できていればフォーカスも入力もアンケートに集まる**。アンケート表示中は毎フレーム停止を主張し直す形にした（外れても次のフレームで戻るので自己修復。漏れるのは最大 1 フレーム）。本来は停止の所有者を 1 つに寄せるべきだが、`DialogManager` は全ダイアログが通る最頻経路で headless では見た目を検証できないため、文化祭直前に触るのは避けて封じ込めに留めた（根治は #429）。
- **送信時に「ご協力ありがとうございます」を挟む**: 押した直後に画面が消えると「送れたのか分からない」まま終わる。**画面は増やさず**、同じパネルの中身を 0.8 秒だけお礼に差し替えてから既存の消滅アニメーションへ渡す。要素は `hide()` せず透明にしている（`PanelContainer` が中身に合わせて縮み、消える直前にカードの大きさが跳ねるのを避けるため）。**スキップ時は出さない**（礼を言われる筋合いが無いうえ、立ち去る人を足止めするだけ）。
- **カルーセルの「戻る」に全体アンケートを配線**（レビュー指摘）: 戻り先を見失った場合の受け皿になっている分岐だけがアンケートを素通りしてスクリーンセーバーへ行っていた。経路によって集まったり集まらなかったりすると集計が偏るため、退出はすべて全体アンケートを挟む形に揃えた。
- **コントローラーのスティックドリフトでタイムアウトが無効化される不具合を修正**（レビュー指摘・High）: 放置タイマーを「何か入力が来たらリセット」で書いていたため、アナログスティックにドリフトのある個体が挿さった台では**タイマーが永久に発火しない**。展示は共用コントローラーを各席に挿して回す運用なので、1 本のドリフト品がその台を一日固める（しかもアンケート表示中はツリーを止めているので通常のアイドル復帰も同時に封じられ、自己修復の経路がゼロになる）。**同じ判定は `service_mode.gd` が既に持っていた**ので、`InputIntent`（`scripts/input_intent.gd`、新設）に切り出して両者で共有した。書き写すと「新しい画面がまた素朴に書く」が繰り返されるため。
- **マウスの微小な揺れも同様に無視する**: 当初 `InputIntent` はマウス移動を「そこに人がいる証拠」として無条件に数えていたが、この前提は展示会場では成り立たない（机がぶつかって揺れる／センサーが汚れて微小な動きを拾う／何かに寄りかかっている）。移動イベントが出続ければスティックドリフトとまったく同じ壊れ方をする。**1px を超えた移動だけ**を数えるようにした（`input_handler.gd` など既存 4 箇所が「微小なマウス移動は無視」として使っている閾値に合わせた）。アンケート画面のカーソル表示判定も同じ閾値に揃えている（揺れでカーソルが現れると、フォーカス枠だけ消えて★の色が残る以前の見え方が再発するため）。
- **本編 3 画面（カルーセル / ストア / 初回説明）の同種の穴は #430 に切り出した**: あちらも「何か入力が来たらアイドルタイマーをリセット」で書かれており同じ罠があるが、実害はスクリーンセーバーへ戻らなくなること（台は操作可能なまま）で、アンケート表示中に固まるのとは重さが違うため本 PR には含めない。あわせて、カルーセルだけマウス移動を presence と数えていない（マウスだけで操作していると 90 秒で落とされる）という逆向きの不具合も同 issue に記載した。
- **「回答が 1 ミリも進まないまま 5 分」で閉じる上限を併置**: 上の判定は既知の原因（ドリフト・ボタンの固着）を潰すが、「判定をすり抜ける新しい入力源」には無防備なまま。判定に依存しない上限が要る。ただし**基準を「表示からの経過時間」にしてはいけない** — 自由記述（200 字）を打つのに数分かかる来場者は普通にいるので、書いている最中に問答無用で閉じることになる。故障と本物の来場者を分けるのは**入力の有無ではなく、回答が前に進んでいるか**で、壊れた入力は★も選ばせないし文字も増やさない。よって**★の選択・文字の増減があるたびにリセット**する。「入力は来ているのに何も進まない」状態だけを打ち切るので、書いている人は巻き込まれない（眺めているだけの人は先に 90 秒の放置タイマーが拾う）。
- **ゲーム終了直後の DB オープンを 1 回に畳んだ**（レビュー指摘）: トグルが OFF のとき、個別アンケートの判定 →（出さずに）退出処理 → 全体アンケートの判定 が数フレームの間に走り、SMB 上の SQLite を 2 回開いていた。1 回の open は `journal_mode` / `busy_timeout` の PRAGMA と版数チェックを伴い、ロック競合時は最大 10 秒待ちうる。**ゲームが終わった直後は一番待たせたくない瞬間**なので、1 回の open で 2 キーとも読み、1 秒以内の再問い合わせはその結果を使う。1 秒は来場者が知覚できる遅延ではないので「Manager で切り替えた瞬間に効く」（#263）は保たれ、個別 → 全体を両方出す経路では回答操作で必ず 1 秒以上あくため 2 回目は読み直しになる。
- **閉じるアニメーション中もポーズ維持の watchdog を効かせ、フェイルセーフを付けた**（レビュー指摘）: watchdog の条件が「ダイアログが存在する間」だったため、`animate_out` の 0.2 秒だけ無防備だった（ポーズ解除は tween の完了コールバック 1 本に依存しており、そこが発火しないと全画面フリーズが永続する）。閉じ始めから 2 秒たってもポーズが戻らなければ強制解除してタイトル画面へ逃がす。watchdog を置いたことで新しく生まれた失敗経路なので、出口も一緒に用意した。
- **bool 設定の表現について、コメントが実装と逆だったのを修正**（レビュー指摘）: 「Manager は `"1"/"0"` で保存する」と書いていたが、実際は `"true"/"false"`（`SetString` 経由）。さらに Manager 側の読みが「`"false"` 以外はすべて ON」で、`"0"` を **Manager は ON・Launcher は OFF** と読む非対称があった。解釈を `SettingsKeys.ParseBool` / `FormatBool` に集約して Launcher の `get_bool` と同じ表に揃え、両側の表が一致することをテストで固定した。揃っていないと「画面では ON なのにアンケートが出ない」という現場で切り分け不能な食い違いになる。
- **アンケート表示中も heartbeat を出し続けるようにした**（レビュー指摘・High）: `SessionHeartbeat` の 10 秒周期 Timer はポーズ中に止まる設定だった。一方 Manager の生存判定は 60 秒（`LauncherSessionService.StaleTimeoutSeconds`）で、アンケートは無操作 90 秒まで表示され続ける。つまり **SPEC が「必ず起きる」と想定している「答えずに立ち去られる」ケースそのもので、生きているキオスクが Manager のダッシュボードから消える**。当日スタッフが「落ちた台」を見に走ることになる。ポーズは画面の話でプロセスは動いているので、`PROCESS_MODE_ALWAYS` にした（退出確認ダイアログでも同じ穴はあったが、そちらは数秒で答えるものだったのに対し、本 PR は 90 秒の滞留を設計上の正常系にするため実質的に新規の露出）。
- **「進捗」を、呼ばれたことではなく回答内容が実際に変わったことで判定するようにした**（レビュー指摘・High）: 上限のリセットが無条件だったため、(a) 決定ボタンのチャタリング / 固着で同じ★が繰り返し「選ばれる」、(b) 本文が 200 字に達した状態でキーが押しっぱなしになり、切り戻して同じ本文のまま `text_changed` だけが飛び続ける、の 2 つを進捗と誤認していた。**どちらも上限が拾うべき当のケース**で、放置すると 90 秒も 300 秒も永久に発火しない。★と本文のスナップショットを比べ、変化があったときだけ戻す。
- **試遊（サービスモードのゲーム動作テスト）をアンケートからも除外**（レビュー指摘）: プレイ記録は `GameSession.test_session` で試遊を弾いていたのに、アンケート側は `ServiceMode.is_open()` ガードに依存していた。試遊中に 60 秒のオートクローズでサービスモードが先に閉じると、その後スタッフが退出したときに**スタッフの回答が本物のアンケートとして保存される**。`play_record_writer.gd` 自身が「終了時の `is_open` 判定は使ってはいけない」と規約化しているのに、その不正確な判定にだけ依存している呼び出し側が残っていた形。`test_session` を**同期で読む**（`game_session.gd` が emit の後に false へ戻すため、deferred では常に false になる）。
- **消滅アニメの failsafe が、遅れて届くコールバックを打ち消していなかった**（レビュー指摘）: failsafe がタイトル画面へ逃がした後に `animate_out` のコールバックが発火すると、解放済みの `playing` ノードに触るか、タイトル画面から勝手に選択画面へ戻る。閉じるたびに世代番号を進め、コールバック側で自分が現世代かを確認するようにした。
- **DB を開くときの PRAGMA 順序を修正**（レビュー指摘）: `journal_mode=DELETE` を `busy_timeout` より**先**に実行していたため、Manager がバックアップ等で DB を握っている瞬間は**リトライ猶予ゼロで即失敗**しうる。しかも戻り値を見ていなかったので、DELETE モードに落ちないまま続行して「SMB 上で WAL を使わない」(#103) という前提が静かに崩れる経路になっていた。`busy_timeout` を先に張り、失敗時は警告を残す。
- **カルーセルの「戻る」でも `AppState` を畳むようにした**（レビュー指摘）: 退出ボタン経由は `AppState.clear()` してから遷移するのに、戻り先を見失った受け皿の分岐だけ畳んでいなかった。経路によって絞り込み結果が次の来場者に残ったり残らなかったりするのは追いにくい。
- **bool 設定の解釈を `SettingsValueFormat`（新設）へ切り出した**（レビュー指摘）: `SettingsKeys` は key 定数の SoT であって値の解釈は責務が違う（AGENTS.md「File Structure」）。あわせて、`ParseBool` の直前に別の定数の `<summary>` が積まれて **doc が 1 つずれ、`SurveyGameEndEnabled` が無説明になっていた**のを直し、同じメソッド内に残っていた自動バックアップトグルの旧解釈（`"false"` 以外はすべて ON）も揃えた。
- **`PRAGMA journal_mode=DELETE` の成否判定が silent pass だったのを修正**（レビュー指摘）: 前回のレビュー対応で戻り値を見るようにしたが、**`journal_mode` PRAGMA は切り替えられなかった場合でもエラーにならず、現在のモードを結果行として返して成功する**。つまり bool を見るだけでは「DELETE に落ちていないのに OK と読む」ままで、直したつもりの silent pass がそのまま残っていた。結果行の `journal_mode` を実際に読んで `delete` と照合する。
- **アンケートのトグル読み取りを、待ち上限つきの軽量 open にした**（レビュー指摘）: `DatabaseManager.open()` に待ち時間と版数チェックの引数を足し、ここでは **500ms / 版数チェックなし**で開く。再利用窓（1 秒）は 2 回目以降しか畳めないので、**1 回目のロック競合**が既定の 10 秒待ちに当たると、ゲームが終わった直後に画面が最大 10 秒固まる。読めなければ既定（表示する）に倒す — アンケートは出しすぎてもスキップできるが、来場者を待たせるのは取り返しがつかない。
- **消滅処理の failsafe がダイアログ実体を解放していなかった**（レビュー指摘）: `_dialog` を null にした後は誰も参照を持たず、tween が完走しない場合に **スクリーンセーバーの上へ古いアンケートパネルが残り、全画面 Control がマウスクリックを吸い続ける**（キー / パッドは素通りするので「見た目は残っているのに操作はできる」という一番分かりにくい壊れ方になる）。閉じている間の参照を保持し、failsafe で解放する。
- **放置タイマーのリセット条件について、docstring と SPEC が実装と逆だったのを修正**（レビュー指摘）: 「どんな入力でもリセットする」と書いたまま、実装は `InputIntent` で意図的入力に絞っていた。**安全側の仕様なので、誤読は次の実装者が判定を外す判断につながる**（＝ドリフト固着バグの再導入）。実装に合わせ、緩さの範囲（1px / デッドゾーン 0.5）まで明記した。
- **診断画面の版数取得も戻り値を見るようにした**（レビュー指摘）: 失敗すると `v0` に落ちて「データベースが古く記録できません (v0)」という**誤った原因**を出し、スタッフが「Manager を起動して更新」しても直らない切り分け不能状態に送り込む。読めなかったときは「? 版数を確認できませんでした」に分岐する。判定の正確さと原因表示の正確さは、この画面では同格。
- **未使用の `FocusBorderMorph.set_target_radius` を削除**（レビュー指摘）: 「★ボタンの角丸に合わせたいとき」と用途まで書いてあるのに呼び出し元ゼロだった。
- **サービスモードのマウス判定が変わったことを明記**（レビュー指摘）: 判定を `InputIntent` へ共有した際、コメントには「移した」と書いたが**純粋な抽出ではなく挙動が 1 点変わっている** — 旧実装はマウス移動を無条件に意図的入力として扱っていたが、共有後は 1px 超のみになった。机の振動程度ではサービスモードの 60 秒オートクローズがリセットされなくなり、わずかに閉じやすくなる。スタッフが操作していれば必ず 1px を超えるので実害は無いと判断したが、「移した」だけでは挙動同一に読めるため明記した。
- **docs**: `docs/usage/troubleshooting.md` の「こんなときは」に「アンケートが出てこない」「プレイの記録が増えていない」を追加。当日スタッフが最初に引くのは運用手順ではなくトラブルシュート章なので、そこから設定 → 点検画面への導線を張った（試遊では確かめられないことも明記）。
- bump 判断: 新機能（アンケートの収集開始）。**minor（v0.12.0 → v0.13.0）**。Manager v0.34.0 と同 PR。

### [Launcher v0.12.0] - 2026-09-03

#### Added — プレイ記録の JSON 出力（`feature/launcher-play-record`、#297 PR2 / #34）

- **ゲームを 1 回遊び終えるたびに、プレイ記録を 1 件 1 ファイルの JSON として `responses/play_records/YYYY-MM-DD/<unix_ts>-<game_no>-<uuid>.json` に出力**するようになりました（SPEC §6.5 / §7.5.3）。中身は `type` / `source_pc` / `created_at` / `game_no` / `start_time` / `end_time`。**来場者から見た画面・操作は一切変わりません**（記録は完全に裏側で走ります）。
- **ファイル名に `game_no` を持たせた**（`<unix_ts>-<game_no>-<uuid>.json`）: ストアの「人気ランキング」（ゲーム別の件数）と「最近プレイ」（最新 N 件）が、**1 ファイルも開かずディレクトリ一覧だけで求まる**ようになる。本番は SMB 共有で「ファイルを開く回数 = ネットワーク往復回数」になり、Launcher は会期中ずっと数十秒おきに再スキャンし続けるため、この差が効く（ローカル実測で 3,000 件・全件パース 220ms に対し一覧のみ 13ms、SMB ではさらに開く）。中身を開く必要があるのはプレイ時間・★評価・コメントなど文化祭後の分析だけになる。全体アンケート（ゲームに紐づかない）は番号部分が `0`、JSON 本体は `null`（集計側が「0 番のゲーム」と読み違えないよう対にした）。**ファイル名と中身の重複は意図的**で、「中身が正本・ファイル名はそれを速く読むための索引」という関係にしている（レコードが単体で完結していないと、コピーツールの改名や手動のフォルダ整理で取り直し不可能なデータが失われるため）。
- **共通ライター `ResponsesWriter` を新設**（`scripts/responses_writer.gd`）: 日付フォルダの導出・ファイル名規則・共通フィールドの付与・atomic write（`.tmp` に書いて rename）・失敗時の振る舞いを 1 箇所に集約する。プレイ記録とアンケート（#35 / PR3）は書き出し方が同一で違うのは category と固有フィールドだけなので、両者の SoT にする。共通フィールドはライター側が付けるので「付け忘れたレコード」が構造的に作れない。日付フォルダは **ローカル時刻**で導出する（UTC のままだと日本時間の朝 9 時より前が前日フォルダに落ち、スタッフがフォルダを覗いたときに会期日と 1 日ズレる）。
- **`PlayRecordWriter` autoload を新設**（`scripts/play_record_writer.gd`）: `GameSession` の signal を購読するだけの受動的な autoload。**`game_started` でゲームと開始時刻を控え、`game_exited` で書き出す**二段構え — `GameSession._on_exited()` は `current_game = null` を `game_exited` の emit **より前**に実行するため、終了時の購読者からは「どのゲームだったか」が読めないため。
- **サービスモードの試遊テストを記録から除外**（#311）: 試遊も本番と同じ `GameSession` 経由で起動するので、素朴に記録すると開場前の全ゲーム試遊が本番プレイとしてカウントされ、母数の小さい直近 N 日ランキング（#36）が「試遊順」に汚染される。`GameSession.test_session` で弾く（終了時に `ServiceMode.is_open()` を見る案は、試遊中の 60 秒オートクローズでサービスモードが先に閉じうるため不可）。signal は**同期接続**する（deferred だと `test_session` のリセット後にコールバックが走り、常に false を読んで除外できない）。
- **`game_no` 未採番（DB v24 未満）のゲームは記録しない**: 参照先を解決できない孤児レコードになるだけなので、書かずに警告を残す。
- **fail-soft**: 書き込みに失敗しても警告を残すだけで、ゲームプレイ・画面遷移は一切止めない。記録のために来場者の体験を壊さない。
- **`player_count` は出力しない**（キーごと省略）: 取得法が未確定のため。常に `null` を書くと読み手が「取ろうとして取れなかった」と誤読するうえ、JSON はスキーマレスなので予約の必要が無い。将来 取得法を実装した時点でキーが現れ、その有無がそのままデータ世代の判別になる（SPEC §7.5.3）。
- **ログ**: `game_no` を実際に使う処理なので `tetris_clone (no.12)` の形で ID と番号を併記する（JSON は番号しか持たないため、障害調査でログだけから記録とゲームを突き合わせられるようにする / SPEC §7.5.3 の露出方針）。
- **検証**: Godot headless で使い捨てスクリプトを流して確認（検証後削除）。ファイル名 `<unix_ts>-<game_no>-<uuid>.json` が意図どおり出ること・全体アンケートが名前 `0` / 本体 `null` になること・ゲーム個別アンケートが名前と本体で同じ番号を持つことを含む。`ResponsesWriter` — 同一秒に 6 件書いてもファイル名衝突なし・`.tmp` 残骸なし・日付フォルダがローカル日付と一致・`created_at` がディスク上で整数表記かつファイル名 prefix と一致・`player_count` 不在。`PlayRecordWriter` — 通常プレイで 1 件出る / 試遊は出ない / `game_no` 未採番は出ない / `game_started` 無しの `game_exited` では出ない / 2 回目のプレイで 2 件目が出る（状態が正しく畳まれている）。
- **書き出しの成否をセッション通算のカウンタで持つようにした**（レビュー指摘）: 診断画面（v0.14.0）が「エラーはありません」の根拠にしていたのは `Logger` のメモリ上リングバッファ（400 行）で、**同じ起動の中でも古い行は押し出されて消える**。来場者が回った日の夕方には朝の失敗が見えなくなり、診断画面が一番やってはいけない「嘘の ✓」を出す。成否は溢れないカウンタで持ち、ログ由来の行は補助表示に格下げした。あわせて失敗経路を `_fail()` 1 本に束ね、カウンタと最終エラーの更新漏れが構造的に起きないようにした（`return` ごとに書くと必ずどこかで忘れる）。
- **`LogBridge` を新設**（`scripts/log_bridge.gd`）: Godot 4 には組み込みの `Logger` クラスがあり `Logger.info()` と書くと autoload ではなくそちらに解決されるため、Launcher の各所が `print` / `push_warning` に落ちていた。**しかし「呼べない」わけではなく**、`service_mode.gd` には `/root/Logger` を引く実装が既にあった（本 PR の新規ファイルはその事実を見落とし、コメントに「呼べないため」と誤って書いていた）。`Engine.get_main_loop()` 経由で解決するので **`RefCounted` や static 関数からも呼べる**。標準の出力関数はレベルを指定できず（AGENTS.md「Cross-component Standards」が禁じている理由そのもの）、診断画面の WARN 抽出が Godot 標準ログの 0.5 秒ポーリングのテール頼みになるため、新規コードは本経路に寄せた。
- **本 PR に集計は含まない**: ストアの「人気ランキング」「最近プレイ」を実データで動かすのは別途（`StoreSectionForm.AllSources` の `Hidden` 復帰も含む）。まず**当日しか取れない書き込み**を通す。
- bump 判断: 新機能（プレイ記録の収集開始。破壊的変更なし・DB スキーマ変更は同 issue の先行 PR 側）。**minor（v0.11.9 → v0.12.0）**。

### [Launcher v0.11.9] - 2026-09-03

#### Changed — DB v24（`games.game_no`）への追従（#297 PR2）

- **`CURRENT_DB_VERSION` を 23 → 24 へ**（Manager `SchemaManager.CurrentDbVersion` と歩調を合わせる）。v24 は `games.game_no` の追加（#297 PR2、詳細は Manager v0.33.0 を参照）。
- **`GameInfo.game_no` を追加し `GameRepository` で読む**: プレイ記録・アンケートの JSON がゲームを指す不変キー。`get_all_games` / `get_game_by_id` は `SELECT *` なので v24 以降の DB では自動的に含まれる。**v24 未満の DB / 未採番行では `-1`** になり、この場合は記録を書き出さない契約（書込側の実装は続く PR）。
- 本 PR の Launcher 側は**読み取りの配線のみ**で、来場者から見た挙動は一切変わらない（JSON の書き出しはまだ行わない）。
- bump 判断: 内部配線のみ（破壊的変更・来場者向けの挙動変更なし）。patch（v0.11.8 → v0.11.9）。Manager v0.33.0 と同 PR。

### [Launcher v0.11.8] - 2026-06-11

#### Changed (アプリ表示名の整理)

- **窓タイトル（Alt+Tab / タスクバーでスタッフが見る名前）を「TonePrism ランチャー」に設定**（`app_manager.gd` `_ready` で `get_window().title` を設定）。従来は project.godot の `config/name`（=「TonePrism_Launcher」、exe 名と同じ技術名）が既定の窓タイトルになっていた。exe / `config/name` は OS 衝突回避の規約どおり据え置き、**見える名前だけ** Manager の「TonePrism マネージャー」（v0.27.5）とトーンを揃えて日本語化（システム名 TonePrism ＋ 役割。Launcher だけが TonePrism 全部ではないので "TonePrism" を名乗りきらない）。全画面キオスク中は非表示、Alt+Tab 時に表示。
- bump 判断: 表示名の変更（破壊的変更・schema 変更なし）。patch (v0.11.7 → v0.11.8)。Manager v0.27.5（マネージャー表示名）と同 PR。

### [Launcher v0.11.7] - 2026-06-11

#### Added (#345 — ストア導線の分かりやすさ)

- **スライドショー / タイルグリッドにもセクション見出しを表示**（通常行と同じ `store_section_header`）。従来は厳選枠（slideshow/tile）だけ見出しが無く、ストア → カルーセル遷移時に「これは何のゲームの集まり？」が分かりにくかった。店とカルーセルで同じセクション名が見える連続性を作る。`store_browse.gd` `_build_one_section` で showcase を `VBox[header, banner]` に包む最小実装（既存の `container.get_node("SlideshowPrev")` 等のノード探索 / `_section_ui` / `_switch_slide` を一切壊さない）。カルーセル側の件数表示・パンくず等（#345 ②③④）は follow-up。

#### Changed (top_bar グラデーションの責務整理)

- **`top_bar` の黒グラデーション高さの二重がけを解消**。`top_bar.gd` が `_background.offset_bottom = bar_height` を設定していたが、Background は anchors=full rect（`anchor_bottom=1.0`）で既に Panel を埋めており、二重に効いて gradient が実質 **2×bar_height** に伸びていた（ストアでセクション見出しが黒帯に沈む原因）。Panel 側だけ設定し `bar_height` ＝そのまま gradient 高になるよう修正。各画面が必要な高さを実値で宣言（`store_browse=100`：セクション見出し y=100 直前まで／`game_selection=500`：カルーセルのセクション名ラベルを覆う＝旧 2×250 と同値で**見た目不変**）。共有 `top_bar.tscn` の利用は store_browse / game_selection の 2 つのみで影響範囲確認済み。

#### Fixed (ストア — トラックパッドの高速スクロール)

- **トラックパッドでストアをスクロールすると超高速になる問題を修正**（`store_browse.gd`）。`MOUSE_BUTTON_WHEEL_UP/DOWN` 1 イベントごとに固定 150px を加算していたが、マウスホイール（離散・少数イベント）と違いトラックパッドの高精度スクロールは 1 イベントあたり `event.factor` が小さい値（≈0.1）で高頻度に飛んでくるため、`150 × イベント数` で爆速になっていた。`_wheel_scroll_step` を新設し `150 × factor`（上限 150）で正規化。**通常マウスホイールは `factor=1.0` で 150px/ノッチのまま不変**、factor 未設定（≤0）は 1.0 フォールバック。

#### Fixed (ストア — `max_display_count` がセクション実データに効かない)

- **ランキング系セクション（random 等）で `max_display_count` を N にしても、開いたカルーセルに全件が出る問題を修正**（`store_section_repository.gd` / `store_browse.gd`）。従来 `max` は行 builder の**表示トリミングだけ**に効き、`_on_select` が `get_all_games_for_section` で**再クエリ**するとランダムは `ORDER BY RANDOM()` で全件返していた（「ランダムピックアップ max=8 なのに 27 件出る」）。(1) repo の random query に `max>0` のとき `LIMIT N` を追加して `section.games` 自体を N 件にし、(2) `_on_select` を再クエリ廃止で**行が読み込んだ `section.games` を再利用**するよう変更。これで行・カルーセルが同じ N 件で一致し、副次的に「行で押したタイルが再シャッフルでカルーセルに居ない」既存の不整合も解消。filter 系（genre / 新作 / 手動）は元々 LIMIT 無し＝全件で `section.games` も全件のため**「すべて見る＝全件」は不変**。

#### Changed (初回説明 — 画像レイアウト)

- **初回説明スライドの「画像＋本文」レイアウトで、画像が片寄って見えるのを修正**（`intro_guide.gd` `_make_image_rect`）。画像枠を固定サイズ（820×500）で予約していたため、正方形に近いロゴ等を入れると枠の左右にデッドスペースが残り、本文が右へ押しやられて構図が片寄っていた。テクスチャのアスペクト比で**枠内に収まる実寸**を算出して `custom_minimum_size` にし、ロゴと本文が中央に寄るようにした（画像のみのスライドは余白対称のまま不変）。

- レビュー対応（挙動不変の整理）: `_on_select` の再クエリ廃止で未使用化した `get_all_games_for_section` を削除＋ `_get_games_for_section` の自動再接続コメントを実態に更新／`top_bar.gd` の未使用 `_background` onready 変数を削除／random の `LIMIT` を文字列連結から `?` binding に変更（本ファイルの他クエリと統一）／`_on_select` の防御的 `_db_manager.close()` の意図をコメント明記。random の「すべて見る」は N 件キャップを厳守する仕様（行・カルーセル一致のため）で、本番 1920 単一モニタでは 8 件が行に収まり ViewAll は出ない。
- 検証: 同梱 Godot 4.6 headless の editor import が compile / parse エラー無しで通過。**※実機で (1) ストアのスライドショー/タイルに見出しが出てグラデに沈まない (2) トラックパッド/マウスホイールのスクロール速度 (3) random セクションが行・カルーセルとも max 件数で一致・genre のすべて見るは全件 (4) 初回説明の画像＋本文が中央に寄る、を目視（pre-release）**。カルーセルのグラデは 500=旧2×250 で不変のはずだが共有コンポーネントを触ったため要確認。
- bump 判断: ストア導線の見出し追加（小機能）＋表示/スクロール/件数の修正。patch (v0.11.6 → v0.11.7)。Manager 変更なし。

### [Launcher v0.11.6] - 2026-06-10

#### Changed (#311 — サービスモードの試遊テストで本物の中断オーバーレイを確認できるように)

- **サービスモード「④ ゲーム動作テスト → ③ 試遊テスト」を、本番と同じ `GameSession` 経由の起動に変更し、HOMEキー / Guideボタンで本物の中断オーバーレイ（再開／別のゲーム／退出）が出るようにした** (`service_mode_overlay.gd` の `_pt_*`)。従来は `_spawn_game_process`（GameSession 非経由）で起動し、HOME/Guide を押すと [`_pt_on_trigger`](Launcher/scripts/service_mode_overlay.gd) が**即 taskkill** していたため、本番で出るはずの中断オーバーレイをサービスモードから一切確認できなかった（#311 のギャップ。特に WOLF RPG 等の排他フルスクリーン #314 の挙動を実機検証する手段が無かった）。
  - 起動を `GameSession.begin_launch` → `OverlayManager.set_current_game` → `GameSession.start_process` に置換。トリガ（HOME/Guide）は本物の `OverlayManager` が拾ってオーバーレイを出すので、試遊側の直接 kill (`_pt_on_trigger`) と毎フレーム process polling (`_pt_tick`) は撤去。ゲーム終了（手動終了 / オーバーレイの「別のゲーム」「退出」由来の quit）は `GameSession.game_exited` を購読して受け、従来どおり 〇× を記録 → 次へ進む。中止/離脱時の置き去り防止も `taskkill` 直叩きから `GameSession.quit()` に統一。
  - **browse シード側のガード**: `GameSession` の `playing_confirmed`（→ playing.tscn へ scene 切替）と `game_exited`（→ カルーセル復帰 / スクリーンセーバー遷移）は `game_selection.gd` が購読しており、signal は tree paused でも届く。サービスモード中（`ServiceMode.is_open()`）はこれらを早期 return で無視し、裏の browse シーンが勝手に遷移して壊れるのを防ぐ。退出（スクリーンセーバー）フラグもテスト中は無視。
  - **pause 整合**: サービスモードは `get_tree().paused = true`（裏の browse シーン凍結）だが、中断オーバーレイ (`overlay_menu`) は `PROCESS_MODE_ALWAYS`（既存設計、ダイアログ等での pause 中も入力/アニメを止めない）なので、paused 下でもボタン操作・glow が効く。`GameSession` も `ALWAYS`、`LauncherAgent.trigger_received` は旧試遊テストの HOME→kill が paused 下で機能していた実績どおり発火する。よって追加の unpause 処理は不要。
  - スタッフ向け文言（③ のボタン / 説明 / 開始確認モーダル / 試遊画面の案内）を「HOME/Guide で本番と同じ中断メニューが出る・そこから終了すると 〇× へ」と実挙動に合わせて更新。起動テスト②（`_lt_*`）は従来どおり `_spawn_game_process`（GameSession 非経由）のまま。
  - **将来のプレイ記録汚染の予防 (`GameSession.test_session`)**: 試遊が GameSession 経由になったことで、将来のプレイ記録 (#297 PR2 / #36 ランキング) が GameSession のライフサイクルにフックすると**サービスモードの試遊も本番プレイとしてカウントされる**導線になった（母数の小さい直近N日ランキングが開場前チェック直後に「試遊順」へ汚染される）。`begin_launch(game, test:=false)` に test 引数を追加し、試遊起動は `test=true` で `test_session` フラグに**セッション開始時に焼き込む**。終了時に `ServiceMode.is_open()` で弾く案は、試遊中はゲームが前面でランチャー無操作扱い → 60 秒オートクローズがプレイ中に発火しうるため不正確（だからフラグ焼き込み方式）。フラグは `game_exited` 発火（購読者の処理）後にリセットされ、PR2 はこのフラグを見て試遊を集計から除外するだけでよい。現時点では記録機構が無いので挙動変化ゼロ。
  - **〇× を 2 問に拡張（レビュー後の実機運用要望）**: ゲームごとに「正しく遊べたか」に加えて**「中断メニューは正しく出て操作できたか」**も 〇× で記録する（結果列は「遊〇 / 中断〇」の形式、どちらか × なら赤）。終了は**原則 HOMEキー / Guideボタン → 「試遊を終了する」**とする運用に文言を統一（開始確認モーダル・③ の説明・モード説明。毎回オーバーレイを通ることで中断メニューの動作確認を全ゲームで取る。出ない場合はゲーム自体の終了操作で閉じて中断に × を付ける）。
  - **試遊中の中断オーバーレイを 2 択化**: `GameSession.test_session` 中は `overlay_menu` の項目から「別のゲームをあそぶ」を除き、exit を試遊専用の**「試遊を終了する」（サブ「ゲームを終了して記録へ」、黒字）**に差し替えた**2 択**にする（`_rebuild_items` で項目を組み替え、番号も詰め直す。`TEST_EXIT_ITEM`）。「別のゲーム」除外は、試遊がゲーム選択画面へ戻る文脈ではなく（裏のシーンはサービスモードで paused のまま）選ぶと文脈破壊になるため。exit のラベル・色の差し替えは、本番の「退出する」（赤字）が「席を離れてスクリーンセーバーへ」の意味で、試遊の実態（ゲームを終了して 〇× 記録へ進む）と異なるため＝**赤=退出の意味の色を試遊終了に流用しない**。「続ける」は本番と同一。通常プレイは従来どおり 3 択。
  - **サービスモード内モーダルのキーボード/コントローラー対応**: 従来は (a) `_apply_focus_style()` の対象にモーダルのボタンが含まれず、マウス操作中にモーダルを開いてキー/パッドへ切り替えるとフォーカス枠が透明のまま＝どこにフォーカスがあるか見えない、(b) ゲーム終了直後の 〇× モーダルで窓フォーカス遷移により GUI focus owner が失われると矢印/決定が無反応、(c) モーダルを閉じるとフォーカスを持ったボタンごと hidden になり focus owner が消えて以後キー操作が死ぬ、の 3 点で実質マウス専用だった。(a) `_apply_focus_style()` にモーダルボタンを追加、(b) モーダル表示中のキー/パッド入力で focus owner がモーダル外なら先頭ボタンへ復帰（復帰に使った押下は消費＝見えない状態の Enter での誤決定防止）、(c) モーダルを閉じた後に focus owner が消えていたら詳細ペイン/左リストへ復帰、で解消。
  - **60 秒オートクローズが試遊中のゲームを強制終了する問題の修正** (`service_mode.gd`): 試遊中の入力はゲーム側に行きランチャーに届かないため、無操作タイマーが進み続け、60 秒を超える試遊で自動クローズ → `_pt_stop` が**プレイ中のゲームを強制終了**していた（試遊が常に 60 秒制限になる実害）。`GameSession.is_running()` の間は無操作タイマーをリセットし続けて自動クローズを抑止（サービスモード中に GameSession が走るのは試遊だけ）。ゲーム終了後（〇× 待ち）は従来どおりタイマーが効く＝置き去り防止は維持。
  - **レビュー対応（Low 3 点）**: (C-2) `_exit_to_screensaver` を `game_exited` emit 後に毎回リセット — 従来は次の `begin_launch` まで true が残り、試遊の最終ゲームを overlay 経由で閉じた後などに不正確な値が居座っていた（`begin_launch` が毎回リセットするので実害は無いが latent）。(D-1) `begin_launch` が false（前セッション残存の競合）のときの試遊ステータスを「× 起動失敗」→「**× セッション競合**」に区別 — ゲーム固有の問題と誤診させない。(D-2) `test_session` / 退出フラグの「emit 後リセット」は**同期接続前提（CONNECT_DEFERRED 不可）**であることを宣言コメントに明記（#297 PR2 着手時の事故防止）。C-3（`set_current_game` を `start_process` 成功後へ移す）は通常プレイ経路との順序整合を割らないため見送り＝両経路同時に揃える別 PR の課題。
- 検証: 同梱 Godot 4.6 headless の editor import が compile エラー無しで通過（stderr 空）。**※実機で (1) 試遊中に HOME/Guide → 本物の中断オーバーレイが「続ける/試遊を終了する」の 2 択で出る（試遊終了は黒字。通常プレイは 3 択のままで、試遊⇔通常を往復しても切替が毎回正しい＝レビュー F-1） (2) 「続ける」でゲームに戻れる (3) 「試遊を終了する」/ゲーム手動終了で 〇× が 2 問（遊べたか→中断メニュー）出て次へ進む (4) 〇× モーダル・開始確認モーダルがキーボード/コントローラーで操作できる（フォーカス枠が見える・矢印移動・Enter/A 決定） (5) 60 秒を超えて遊んでもサービスモードが閉じずゲームが落ちない (6) サービスモードの裏で勝手に画面遷移しない (7) 排他フルスクリーン系（WOLF RPG 等）でもオーバーレイが見える、を目視（pre-release）**。focus/window 重なり（service CanvasLayer ↔ オーバーレイ窓 ↔ 〇× モーダル）は実機依存のため要確認。
- bump 判断: サービスモード試遊テストの挙動変更（破壊的変更・schema 変更なし）。patch (v0.11.5 → v0.11.6)。Manager 変更なし。

### [Launcher v0.11.5] - 2026-06-09

#### Changed (#316 フォローアップ — NO IMAGE 文字サイズの統一)

- **カルーセルの NO IMAGE 文字サイズだけ突出して大きかったのを他箇所に合わせて縮小** (`game_selection.tscn` `NoImageLabel` font_size 30→16)。カルーセルのカードは選択時に ×1.8 拡大されるため、font 30 は実表示で ≈54px（枠の約15%）となり、オーバーレイ/プレイ中（28px・360px枠の約7.8%）やストアのタイル(18/200px≈9%)・スライド(40/~500px≈8%)の「枠に対する割合 ~8%」から突出していた。font 16 で実表示 ≈29px（×1.8）＝オーバーレイの28とほぼ一致し、全箇所が ~8% で揃う。
- 検証: 同梱 Godot 4.6 headless で `game_selection.tscn` の import 通過。**※実機での見た目（カルーセル NO IMAGE が他と同サイズに見えるか・判読できる濃さか）は pre-release で目視・最終微調整**。
- bump 判断: 表示調整のみ。patch (v0.11.4 → v0.11.5)。Manager 変更なし。

### [Launcher v0.11.4] - 2026-06-09

#### Fixed (#315 — 空ストア（0セクション / 全0タイル）で詰む・「すべてのゲーム」ボタンだけになる)

- **ストア入口で事前分岐し、空ストア (0 セクション) なら store_browse を挟まず直接カルーセルへ向かう `StoreEntryRouter` を新設** (`store_entry_router.gd` / `screensaver.gd` / `intro_guide.gd` / `store_section_repository.gd`)。**セクション0件・ゲームありで store_browse に入ると、`_ready` の `_fallback_to_carousel()`→カルーセル遷移が screensaver→store_browse の遷移アニメ中に走り、`change_scene` が再入ガードに飲まれてカルーセルに移れず、early-return 済の空 store_browse（コンテンツ無し・Exit 未構築・idle 未起動）に取り残されて詰んでいた**（`screensaver.gd` #253 と同クラス）。入口 (screensaver / intro_guide) で `has_visible_sections()`（軽量 EXISTS チェック）を見て、0 件なら store_browse を一切経由せず AppState に全ゲームを積んでカルーセルへ直行する。これで「一瞬空の store_browse がちらつくワンクッション」も消える。**※ちらつき除去が保証されるのは「0 セクション」のとき。可視セクションは存在するが中身（games）が0件の構成では `has_visible_sections()` が true を返すため store_browse に入ってから defense fallback でカルーセルへ落ちる（詰みはしないが一瞬のちらつきは残る）。`has_visible_sections()` は入口での二重ロード回避のため games の有無までは見ない軽量チェックという割り切り。なお **DB を開けない/クエリ失敗（一時ロック等）のときは安全側で true を返し** store_browse の通常エラー処理（`get_store_sections` の push_error ＋ 遷移後に独立してもう一度評価＝retry ループではない時間差再評価。ロック継続時はフラットカルーセルに落ちる）に委ねる（false＝「0件」と取り違えて、セクションのあるストアを一時ロック1回で silent に最上位フラットカルーセルへ化けさせないため。`push_warning` でログも残す）。**
- **直カルーセル (最上位) は戻るボタンを出さず、ESC を「戻る」ではなく「退出ダイアログ」にする** (`app_state.gd` に `carousel_top_level` フラグ追加 / `game_selection.gd`)。空ストア直行カルーセルは戻り先のストアが無いので、(1) TopBar の戻るボタン非表示 (2) ESC/exit_requested を `_on_exit_button_pressed()`（退出しますか？ダイアログ）に回す (3) 操作ヒントを「Esc 退出」に、と store_browse と同じ最上位の退出挙動へ揃えた。あわせて **store_browse の操作ヒントも「Esc 戻る」→「Esc 退出」に修正**（ESC は退出ダイアログを開くのに「戻る」表記で挙動と不一致だった）。これで **「退出」= ESC が退出ダイアログ（store_browse / 直カルーセル）／「戻る」= ESC がストアへ戻る（ストア経由の通常カルーセル）** と表記が実挙動に一致する。フラグは全カルーセル入口 (router / `_fallback_to_carousel`=true、ストア経由の全ゲーム/すべて見る=false) で明示設定し、`AppState.clear()` でも reset するため、直カルーセル→通常カルーセル間で stale にならない。
- **defense: `store_browse._fallback_to_carousel()`**（入口分岐をすり抜ける稀ケース＝可視セクションはあるが中身が空/0タイル → store_browse に入ってから fallback）を救う。この fallback は incoming 遷移（screensaver→store_browse）中に呼ばれると `change_scene` が再入ガードに弾かれるため、**`while TransitionManager._transitioning: await process_frame` で遷移完了を待ってから遷移する**（`intro_guide._go_to_store_when_free` と同パターン）。当初は TransitionManager に「遷移中の要求を保持する last-wins キュー」を入れていたが、それだと**通常の入力起点遷移まで挙動が変わる**（遷移アニメ中の Enter 連打が破棄されず再遷移する＝コア動線への副作用）ため撤回し、defense 経路だけが待つ wait パターンに変更（TransitionManager 自体は不変）。最上位カルーセルの AppState 準備は router と本 fallback で共通化（`AppState.prepare_top_level_carousel()`）し drift を防ぐ。
- **games があるのに type/source/max_display_count の組合せでタイルが0件描画になるセクションへ多層ガードを追加** (`store_browse.gd` / `store_browse_builder.gd`)。`get_store_sections()` は `not section.games.is_empty()` でフィルタ済なのに、store_browse 側でタイル生成が0件になると「すべてのゲーム」ボタンだけの空ストアになっていた。
  - **全セクションが0タイルならカルーセルへフォールバック**（0件フォールバックと同経路を `_fallback_to_carousel()` に関数化し再利用）。reported の「1セクションが空 → ボタンだけ」を直接救済。
  - **0タイルセクションを警告ログに出す**（`section_id` / `type` / `source` / `max_display_count` / `games数`）。原因 config を実機で追跡可能にした（#315 は config 流動で再現条件未確定だった）。
  - **`build_normal_section` の `max_tiles` に下限1を保証**（`maxi(1, …)`）。極小/未確定ビューポート（`viewport_width≈0`）で `max_tiles=0`→`display_count=0` になり games があっても0枚描画になる経路を塞ぎ、フィルタ（games 判定）と描画を揃えた。通常ビューポートでは値不変。
  - **`_collect_focusable_tiles` / `_build_image_load_queue` に `_` default を追加**（type 0 を `_` に統合）。`_build_one_section` の routing（`_`=通常セクション）と非対称で、未知 section_type のセクションが描画されてもフォーカス不能・サムネ永久 LOADING になる不整合を解消（`_section_has_content` 含め通常/未知 type の扱いを全関数で統一）。
  - セクションの drop は `_section_ui` の index が `_sections` とズレてナビ（クロージャが元の i 参照）を壊すため行わず、global フォールバックで対処。
- 検証: 同梱 Godot 4.6 headless で import 通過 + `_section_has_content()` の判定（通常/スライド/タイルグリッド/未知 type の full/empty）を `.new()` 単体呼びで実測（full→true・empty→false）。**※実機で (1) 0セクション・ゲームあり → store_browse を挟まず直接カルーセル（ちらつかない・詰まない） (2) ストアのセクション正常描画 (3) 通常の画面遷移（セーバー↔ストア↔カルーセル↔プレイ／スライドあり intro 経由含む）に回帰が無いこと は pre-release で目視**（遷移系は headless では検証不能）。

- bump 判断: バグ修正（空ストア防止の多層ガード）。patch (v0.11.3 → v0.11.4)。Manager 変更なし。v0.8.2 同梱（#315）。

### [Launcher v0.11.3] - 2026-06-09

#### Changed (#316 — サムネ未登録時の「NO IMAGE」表示を全画面で統一)

- **サムネ/バナー画像が未登録のときの no-image 表示を「明るいグレーの箱 + 灰字『NO IMAGE』」に統一** (新規 `no_image_placeholder.gd`)。従来は場所ごとにバラバラ（カルーセル=明るい箱、オーバーレイ=暗い箱、プレイ中／ストアのサムネ・スライド・パネル=表示なし）だった。共通ヘルパー `NoImagePlaceholder.make(corner_radius, font_size)` を新設し、**オーバーレイ・プレイ中・ストアのサムネ(タイル)・スライド・パネル(グリッド)** に展開。カルーセルは元から明るい箱なので正典として無改修。
  - **loading（暗ヴェール `Color(0.08…)` + 「LOADING」）とは別デザイン**にして、「読込中（暗）」と「画像なし（明）」を視覚的に区別。黒系の no-image は loading と混同するため、あえて明るいグレーにした。loading 側はカルーセル(`game_selection.gd` の `DimBackground`)・ストア(`store_browse_builder.gd` の `_create_loading_label`)とも既に暗ヴェールで統一済みのため無改修。
  - **全画面の背景アート**（カルーセル背後のぼかし／プレイ中・オーバーレイの背景）は装飾レイヤーなので対象外。従来どおり暗い下地 `Color(0.1,0.1,0.1)` にフォールバック（ストアのスライド/パネルは `background_path` を「中身のタイル」として使うので no-image 対象）。
  - 灰色は単一定数 `BG_COLOR = Color(0.85,0.85,0.85)`（文字 `TEXT_COLOR = Color(0.5,0.5,0.5)`）で**本ヘルパーを使う 4 箇所が一致**（カルーセルは元の .tscn 実装＝白パネル×フェード由来の灰で、視覚的近似・本定数では動かない。真の単一 SoT 化は文化祭後）。濃さは 1 行で調整可。
  - **NO IMAGE が出る条件は「パスが空、またはファイルが存在しない」**（4箇所＋カルーセル共通。store/carousel は setup 時に `file_exists` で判定するのでファイル不在なら NO IMAGE）。**例外＝ファイルは存在するが `Image.load_from_file` が失敗（破損/0バイト/未対応形式）するケースのみ**、store/カルーセルでは LOADING が永続する既存挙動で本 PR 対象外（**#332**）。playing/overlay は同期ロード＋`texture==null` 判定なので破損でも NO IMAGE になる。
  - **スライドショー下部グラデの二重がけを解消** (`store_banner_builder.gd`)。バナー自身の `GradientOverlay`(0.5) に strong(`0.85`) の `SlideshowGradient` を重ねており最下部が実効 ≒0.92 黒の濃い帯になっていた（実画像では馴染むが、明るい NO IMAGE 箱の上で露呈）。strong の重ねを撤去し、バナー 1 枚の 0.5 グラデ＝**タイルグリッドと同じ濃さ**に統一。未使用化した `shaders/gradient_overlay_strong_material.tres` を削除。**※実画像スライドで白 `SlideshowTitle` が飛ぶ場合は、全幅 strong 帯ではなくタイトル局所 scrim（タイトル背後だけ濃く）を別途検討**（no-image とのトレードオフ両立案）。
- 検証: 同梱 Godot 4.6 headless で全スクリプトの import 通過 + `NoImagePlaceholder.make()` が親枠を満たす（200×200・アンカー潰れなし）ことを実測。**実機でも各画面の NO IMAGE 表示・灰色の濃さを目視確認済み（いい感じ）**。**※スライドショーのグラデ変更は実画像スライドの白タイトル可読性も含め pre-release で目視**。

#### Changed (#293 — 説明文なしのプレースホルダを半透明に)

- **ゲーム説明文が未登録のとき表示する「このゲームには説明文がありません。」を半透明（`modulate.a = 0.45`）にして、実際の説明文と見分けられるようにした** (`game_info_display.gd`)。空/空白/NULL 由来の説明文をプレースホルダ判定し、半透明フラグを立てて適用。
- 検証: 同梱 Godot 4.6 headless で `game_info_display.gd` の import 通過。**※実機での半透明表示は pre-release で目視**。

- bump 判断: UI 改善（no-image 表示の全画面統一 + 説明プレースホルダの半透明化）。patch (v0.11.2 → v0.11.3)。Manager 変更なし。v0.8.2 同梱（#316 + #293）。

### [Launcher v0.11.2] - 2026-06-09

#### Fixed (#313 — 期生「不明」(空欄) を「教員」と誤表示しない)

- **製作者の期生が空欄（不明）のとき、誤って「(教員)」と表示される不具合を修正** (`game_info_display.gd`)。grade 空文字を `int("")` で 0 に変換し、`GameInfoFormatter.get_grade_string(0)` が「(教員)」を返していた。#313（Manager v0.27.3）で期生を空欄（不明）保存できるようになったため、**空/空白の grade は期生・教員を一切表示しない**（製作者名のみ）ようガードを追加。「0=教員」「N=N期生」は従来どおり。
- 検証: 同梱 Godot 4.6 headless で `game_info_display.gd` のコンパイル確認。**※実機で空欄期生の製作者が名前のみ表示されることは pre-release で目視**。

#### Fixed (#327 — ジャンル未設定(NULL)で「<null>」タグが出る)

- **ジャンルを設定していない（`games.genre` が NULL）ゲームで、ジャンルタグに文字列「<null>」が表示される不具合を修正** (`game_repository.gd`)。`str(row.get("genre", ""))` が真 NULL で `str(null)="<null>"` を返し `_parse_genre("<null>")` が `["<null>"]` を生成していた（#313 の grade 修正と同根）。読み込み層で genre の NULL を空文字に正規化し、ジャンル未設定はタグなしにした。説明文は表示側ガードで既に救済済み・grade は #313 で修正済みで、本件は genre への横展開。
- 検証: 同梱 Godot 4.6 headless で `game_repository.gd` のコンパイル確認。**※実機でジャンル未設定ゲームに「<null>」タグが出ないことは pre-release で目視**。

#### Changed (#328 — 「すべてのゲーム」を名前順に)

- **「すべてのゲーム」一覧の並びを追加順（display_order）から名前順（title）に変更** (`game_repository.gd` `get_all_games`)。Manager のゲーム一覧（タイトル順）と並びを揃え、来場者が見る順を把握しやすくした。ストアのセクション（新着=制作年順 / ランダム 等）は意図的な並びなので変更なし。`display_order` 列はストアセクション・将来の手動並べ替え (#86) 用に残置（名前順の間「すべてのゲーム」では休眠）。
  - 既知の差: Manager は .NET CurrentCulture 照合、Launcher は SQLite 既定（コードポイント順）のため、漢字タイトルの細かい順は完全一致しない（かな・英字は概ね一致）。完全一致は別途照合の作り込みが必要。
- 検証: 同梱 Godot 4.6 headless で `game_repository.gd` のコンパイル確認。**※実機で「すべてのゲーム」が名前順に並ぶことは pre-release で目視**。

#### Changed (#329 — ストアの単年/人気仮セクションも名前順に)

- **ストアの `popular`（人気・#297 暫定）/ `recent`（新作）/ `release_year:YYYY`（指定年）セクションの並びを `display_order` → 名前順（title）に変更** (`store_section_repository.gd`)。これらは「単年内は新しさ順が無意味」で全体 `display_order` を借りていたが、#328 の名前順方針に揃えた。これで **`games.display_order` は ORDER から完全に外れ休眠列**に（manual セクションは `store_section_games.display_order` ＝手動順を継続使用、フィルタ系の `release_year DESC` は意図的なので不変）。休眠列の撤去検討は #330、手動並べ替え #86 はクローズ。
- 検証: 同梱 Godot 4.6 headless で `store_section_repository.gd` のコンパイル確認。

- bump 判断: バグ修正 + 並び順統一。patch (v0.11.1 → v0.11.2)。Manager v0.27.3 と同じ v0.8.2 に同梱（#313 + #327 + #328 + #329）。

### [Launcher v0.11.1] - 2026-06-08

#### Fixed (#318 — 初回説明スライドの表示調整)

- **本文の改行が 2 行ぶん空いて見える不具合を修正** (`intro_slide_repository.gd` の読み込み層)。初回説明の本文は Manager の WinForms TextBox で編集するため改行が **CRLF (`\r\n`)** で保存されるが、Godot の `Label` は `\r` を独立した改行扱いするため `\r\n` が「2 連続改行」に見えていた。`IntroSlideInfo` 構築時に `\r\n`→`\n` 正規化し、見た目どおり 1 行ぶんの改行にした。**当初は描画層 (`intro_guide.gd _make_body_label`) で正規化していたが、ゲーム説明文 (`game_repository.description`) と同じ「読み込み層で一括正規化」方針に揃え、将来 body_text の表示経路が増えても二重改行が再発しないようにした**（レビュー指摘の設計対称性）。
- **本文のみ（画像なし）スライドの本文幅を 1100 → 1400 に拡大** (`_make_slide_content` の else 分岐)。画面幅 1920 の余白を活かして中央寄せ本文を読みやすくした。画像つきスライドは従来どおり左寄せ・640 幅で据え置き（変更なし）。
- **ゲーム説明文の改行も同根の CRLF 二重改行を正規化** (`game_repository.gd` `_create_game_info_from_row_dict`)。Manager v0.27.2 の #312 で説明文欄に `AcceptsReturn` を付けて Enter 改行を解禁したため、ゲーム説明にも CRLF が入りうるようになった。説明文は `game_info_display.gd` で素の `Label` に流れる（初回説明と同じ条件）ため、読み込み層で `description` を `\r\n`→`\n` 正規化し、ゲーム閲覧の中核動線で二重改行が出ないようにした（レビュー指摘の #312↔#318 相互作用）。
- 検証: 同梱 Godot 4.6 ヘッドレスで全スクリプトのコンパイル（`intro_guide.gd` / `game_repository.gd` 含む、autoload 込みの editor import）でエラー無しを確認。**※実機での改行 1 行化（初回説明・ゲーム説明の両方）・本文のみスライドの幅・画像つきスライドの左寄せは pre-release で実機目視**（Launcher UI は build 緑だけでなく起動目視が必要）。
- bump 判断: 表示調整のみ（バグ修正 + 余白調整、破壊的変更なし）。patch (v0.11.0 → v0.11.1)。Manager v0.27.2 と同じ v0.8.1 リリースに同梱。

#### Fixed (#320 — 初回説明画面で Alt+F4 の終了案内ダイアログが一瞬で消える)

- **`intro_guide._input` の先頭に `if get_tree().paused: return` ガードを追加**。初回説明画面で Alt+F4 を押すと、終了案内ダイアログ（「この画面からランチャーを終了することはできません…」）が一瞬で消える不具合を修正。原因は (1) `IdleManager.reset()` が `DialogManager.close_current_dialog()` で**表示中のダイアログを無条件に閉じる**、(2) `intro_guide._input` が毎入力で `_idle_mgr.reset()` を呼ぶ、(3) 本シーンが `PROCESS_MODE_ALWAYS` でダイアログのポーズ中も `_input` が走る、の合わせ技。`store_browse._input` には元々あったポーズガード（`if get_tree().paused: return`）が intro_guide だけ抜けていた。
- 検証: 同梱 Godot 4.6 headless で `intro_guide.gd` のコンパイル確認。**※Alt+F4 で終了案内が表示されたまま留まる（一瞬で消えない）ことは pre-release で実機目視**。

### [Launcher v0.11.0] - 2026-06-07

#### Changed (#297 PR1 — play_records 非参照化、JSON 直読み化への布石)

- **DB v23 で `play_records` テーブルが撤去されるため、`store_section_repository.gd` のセクションクエリを非参照化**（Manager v0.27.0 と対。撤去後に旧 SQL を実行すると「no such table」エラーになるのを防ぐ。本番では元々空でデータは無い）。
  - **`popular`（人気ランキング）**: 旧 `LEFT JOIN play_records ... ORDER BY play_count DESC` を撤去し、`SELECT * FROM games WHERE is_visible=1 ORDER BY display_order ASC, title ASC`（表示ゲームを安定順）に変更。**順位は仮**で、#297 PR2 の in-memory 集計（`responses/play_records/` を直読みする `play_stats_service` 想定）に差し替えて実データ化する。
  - **`recently_played`（最近プレイ）**: 旧 play_records サブクエリを撤去し `SELECT * FROM games WHERE 1=0`（**0 行**）に変更。`get_store_sections()` が空セクションを表示一覧から落とすため、**データが揃うまで「最近プレイ」セクションは自動的に非表示**になる（UI 非破壊）。PR2 で最新 start_time 上位 N の集計に差し替え。
- **`database_manager.gd` `CURRENT_DB_VERSION` 22→23**。v23 の DB を「Launcher の対応版より新しい」と誤認して `push_warning` を出すのを防ぐ（v15〜v23 はいずれも Launcher が読まないテーブル/制約変更なので定数追従のみ）。コメントに v23 = play_records/surveys/launcher_surveys DROP の経緯を追記。
- 検証: 同梱 Godot 4.6 ヘッドレスで `store_section_repository.gd` / `database_manager.gd` のロード（パースエラーなし）を確認。**※実 DB（v23）での popular/recently_played を含むストア表示・push_error 無し・recently_played 空時のセクション非表示・「DB が新しい」警告無しは pre-release で実機目視**（#297 全体の実データ集計は PR2 で実装後に確認）。
- bump 判断: DB スキーマ追従（v23）+ ストアクエリ変更。`.pck` が変わり Manager v0.27.0 とセットで動く前提のため minor (v0.10.3 → v0.11.0)。**#297 はこの PR では閉じない**（`(#297)` 文末参照。書込+集計=PR2、アンケート UI=PR3）。

### [Launcher v0.10.3] - 2026-06-01

#### Added (#291 — ストアセクションソース「制作年指定」)

- **`store_section_repository.gd` に `release_year:YYYY` ソース分岐を追加**。`source.begins_with("release_year:")` で `int(source.substr(13))` を取り出し、`SELECT * FROM games WHERE is_visible=1 AND release_year=? ORDER BY display_order ASC, title ASC`（指定年のゲームを表示順で全件）を実行。既存の `genre:` / `difficulty:` / `players_min:` 等のフィルタ分岐と同型。
- **新作 (`recent`) との違い**: `recent` は `release_year=今年`（システム日付）固定だが、`release_year:YYYY` は Manager 側で指定した**任意の年**を引く。`max_display_count<=0`（Manager が 0 保存）で該当年を全件表示。
- Manager 側 UI（ソース「制作年」の追加・値入力・条件系グレーアウト）は上記 [Manager v0.20.2] を参照。

#### Fixed (#211 起因 — タイルグリッドが空表示になる回帰)

- **`store_banner_builder.gd` `build_tile_grid_section` が `max_display_count<=0` を「上限なし（最大 3 枚）」と扱うよう修正**。従来は `mini(section.max_display_count, 3)` をガード無しで取っており、#211 で手動/フィルター系ソースが `0` 保存になった結果＋#212 でタイルグリッドが手動固定 → `mini(0,3)=0` で `tile_count=0` → **1 枚も出ない空グリッド**になっていた。通常セクションの `>0 else max_tiles` ガードと同じ扱いに揃えた（ランダム等で `max>0` のときは従来どおり `mini(max,3)`）。

#### Changed (#212 — 厳選枠でランキング系ソースを許可)

- **スライドショー / タイルグリッドで「ランキング系（人気ランキング・最近プレイ・ランダム）」ソースを許可**（Manager v0.20.2 の #212 改と対。どのソースを許可するかは Manager 側のゲートで決まり、Launcher の描画はソース非依存）。背景画像・タイトルはゲーム自身のものを使うため、ランキング系でも見栄えが保てる。
- **スライドショーは `max_display_count>0` のときスライド枚数を上限する**（`build_slideshow_section`）。手動は `0` 保存＝全件（従来どおり）、ランキング系は max が有効なので「特集 N 枚（TOP N）」が成立する。生成枚数を container の `slide_count` meta に持たせ、**`store_browse.gd` `_switch_slide` の wrap-around を `section.games.size()` から `slide_count` に変更**（枚数を絞った際に存在しない `Banner_*` へ飛んで空スライドになるのを防止）。バナー画像の遅延ロードは `Banner_*` を null まで走査する `while` ループなので追従済（無改修）。
#### Changed (フィルター系ソースの並びを「なるべく最新の制作年を頭に」)

- **フィルター系ソース（`genre:` / `players_min:` / `players_max:` / `difficulty:` / `play_time:` / `online` / `controller`）の `ORDER BY` を `display_order ASC, title ASC` → `release_year DESC, title ASC` に変更**（ユーザー要望「名前順に加えてなるべく最新が頭に」）。`games` には作成日時列が無く `release_year`（制作年）が唯一の新しさ指標のため、制作年の新しい順を主キー・同年内は名前順（`title ASC`）とする。`release_year` が NULL のゲームは `DESC` で末尾（＝制作年不明は最後）。
- **単年フィルター（`recent`＝今年固定 / `release_year:YYYY`＝制作年指定）は対象外**（その年だけを引くので「最新が頭」が無意味）。`manual`（割当順）/ `popular`・`recently_played`（ランキング）/ `random`（シャッフル）も従来の並びを維持。
- 検証: 同梱 sqlite3 で実 DB（`toneprism.db`）に対し新旧 `ORDER BY` を実行し、新方式が **2025→2024→2023 の年降順＋各年内 title 昇順**で並ぶことを確認（read-only）。
- 検証: 同梱 Godot 4.6.2 ヘッドレスで `store_section_repository.gd` / `store_banner_builder.gd` / `store_browse.gd` のロード（パースエラーなし）を確認。**※実 DB でのランダム/制作年取得・タイルグリッド/スライドショーの実描画は Manager 実機 UI 確認とあわせて別途必要**（特にタイルグリッド空表示修正・スライド wrap は実機目視）。
- bump 判断: ユーザー向けソース種別の追加（#291）＋表示回帰修正（#211 起因）＋ランキング系許可（#212）＋フィルター並び順変更。.pck が変わるため patch (v0.10.2 → v0.10.3)。

### [Launcher v0.10.2] - 2026-06-01

#### Changed (#281 — Launcher 版数の SoT を project.godot config/version に一本化)

- **`version.gd` から版数の数字（`const MAJOR/MINOR/PATCH`）を撤去し、`project.godot` の `[application] config/version="X.Y.Z"` を SoT に一本化**。version.gd は `ProjectSettings.get_setting("application/config/version")` を読むだけの薄いアクセサに変更（API `get_version_string()` / `get_version_number()` は不変なので consumer〔`debug_overlay` / `service_mode_overlay` / `session_heartbeat`〕は無改修）。従来は version.gd の定数と project.godot config/version の二重持ちで、開発バンプのたびに手で両方を合わせる必要があった。
- 旧 version.gd 冒頭の「DO NOT CHANGE FORMAT（Manager が parse する）」制約を撤廃（Manager は version.gd を parse しなくなった、下記 Manager v0.19.4 参照）。
- 検証: 同梱 Godot 4.6.2 ヘッドレスで `Version.get_version_string()` が project.godot から `v0.10.2` を返すことを確認（parse エラーなし）。**加えて `--export-pack` で実際のエクスポート pck を生成し、ディスク上に project.godot を置かない状態で pck 単体をロードして実行 → `has_setting=true` / `config/version=0.10.2` を確認**（= 配布版 exe と同条件＝pck 内 project.binary のみが情報源、でも runtime で読めることを実証。「ProjectSettings 経由読みは旧 const と違いエクスポート版で初実行される新経路」というレビュー懸念への直接対応）。
- bump 判断: 版数の出力は不変（出どころを移しただけ）の内部リファクタだが、.pck（version.gd）が変わるため patch (v0.10.1 → v0.10.2)。

### [Launcher v0.10.1] - 2026-06-01

#### Changed (#278 ② — ブラウズが DB ハンドルを握りっぱなしにしない)

- **`store_browse` が DB 接続を表示中ずっと保持するのをやめ、初回ロード後に `close()`**。必要データ（`_sections` と各 `section.games`）は `get_store_sections()` で eager ロード済で、段階的 build はメモリ上のデータのみ使い DB を引かないため、`_ready` のロード直後に閉じてよい。「すべて見る」(`_on_select`) /「すべてのゲーム」(`_on_all_games_pressed`) のナビは repo の `is_open()`→`open()` ガードで一時再接続し、取得後すぐ閉じる。**※コードレビュー指摘 (Critical)**: 「すべて見る」が使う `StoreSectionRepository._get_games_for_section` には元々この再接続ガードが無く、close 後に `_db_manager.db=null` を叩いて空配列/エラーになる回帰があった（`game_repository.get_all_games` / `get_store_sections` だけがガードを持っていた）。`_get_games_for_section` に同じガードを追加して対称化。ヘッドレスで close 後 `get_all_games_for_section` が再接続し全 7 セクション計 55 件取得を確認。
- **効果**: store_browse 表示中も OS ファイルハンドルを握らない（screensaver / カルーセル / intro_guide と同じ open→query→close に統一）。これで Manager の **Restore / DB 初期化が store 表示中でもファイル差し替えで衝突しない**ようになり、#278 ① の「Restore/Reset は Launcher 単独でも警告維持」の根拠（表示中だけハンドルを握る窓）自体を縮小する defense in depth。
- 検証: 同梱 Godot 4.6.2 ヘッドレスで store_browse を起動し、`_ready` 後 `is_open()=false`・ナビ相当の `get_all_games()` が自動再接続で 20 件取得を確認。

### [Launcher v0.10.0] - 2026-06-01

#### Added (#253 part 3/3 — 初回説明の表示)

- **初回説明画面 (`scenes/intro_guide.gd` / `.tscn`)** を追加。スクリーンセーバーの「PRESS ANY KEY」後、ストアブラウズに入る前に案内スライドを表示する。各来場者にとって毎回が「初回」になるため**毎回表示**、**手動ナビ**（`→`/`Enter` 次へ・`←` 戻る・`Esc` スキップ、自動送りなし）。最終スライドで「次へ」=案内終了→ストアへ。背景は `store_browse` の Background と同じ単色 `Color(0.08,0.08,0.08)` に統一。**レイアウトは中身で分岐**: 画像＋本文の両方は**左に画像・右に本文の横並び**、画像のみ／本文のみはそれを中央に1つ（いずれもアスペクト維持・折り返しあり）。#244 方針に従い DB 由来の動的コンテンツは builder（シーン script 内で構築）で組み、`.tscn` はルート + script の最小構成。
- **上部左に見出し「はじめに」**（カルーセルのグループ名「すべてのゲーム」等と同じ `NotoSansJP-Bold` / 56px、左揃え。内部呼称「初回説明」は Manager タブ名のまま、来場者向け表示は柔らかい語に）。スライド位置表示は **「1/3」テキストをやめ、戻る/進むの少し上に**ドット（白=現在 / 灰=他、スライド数ぶん）で表現。白⇄灰の切替は `modulate.a` を tween して**フェード**（地は白固定で明暗のみ変える）。
- **送り/戻しは横スライド + フェード**（中断メニュー `overlay_menu` 登場と同じ `TRANS_QUINT`/`EASE_OUT`）。次へ=新スライドが右から入り旧が左へ抜ける、戻る=逆。`_stage`(clip_contents) 内でスライドコンテンツを都度生成し `position.x` を tween、旧/新を同時にアニメ（cross-slide）、完了/割り込みで旧を破棄。
- **画面下部に操作ボタン**を追加。配置は **戻る・進む＝中央 / スキップ＝右端の独立ピル**。戻る・進むは **2分割の segmented**（左=戻る(左だけ角丸・グレー地)・右=進む(右だけ角丸・**青アクセント**)を **非対称角丸のまま少し隙間をあけて並べる**＝合わせ目は角丸なしの直線エッジが 8px のギャップを挟んで向かい合う。`clip_contents` は角丸でクリップしないため各ボタンに非対称角丸を当てる方式）。**全ボタン枠なし**（`StyleBoxFlat` の border 幅0）。**キーボード/コントローラーは `←`/`→` でボタン間をフォーカス移動し、`Enter`/決定 (`ui_accept`) で押下する形式**（中断メニューと同じ操作系。Godot 標準のフォーカス系に委ね、`_input` では `ui_left`/`ui_right`/`ui_accept` を consume しない）。マウス/タッチは直接クリック。初期フォーカスは「進む」、先頭スライドでは「戻る」を無効化（`focus_mode=NONE` にして ← でも選べないようにし、無効化した瞬間にフォーカスを持っていれば「進む」へ自動退避）、最終スライドでは「進む」を「ストアへ」表記に（seg ボタンの内側パディングを 18 にして最長ラベル「ストアへ  →」を min 幅 160 に収め、表記変更でボタン幅が伸びないよう固定）。`Esc` (`ui_cancel`) は素早いスキップ用ショートカットとして残置。
- **フォーカス表示はブラウズ/カルーセルと同じ「追従するグロー枠」** (`store_browse` の `FocusBorder` と同 StyleBox: `draw_center=false` + shadow でやわらかく発光、`GlowAnimator` で明滅) を流用。フォーカス中のボタンへ毎フレーム lerp 追従（speed=delta×25）。**初出現は他画面（store_browse）と同じ zoom-in + フェードイン pop**（中心基準に scale 1.15→1.0・α 0→1 を 0.25s、CUBIC/EASE_OUT）で現れ、以降の移動は lerp で滑らかに。ボタン自身の標準フォーカス装飾は空 StyleBox で抑止し二重表示を防止。**ダイアログ等が出てフォーカスが自分の 3 ボタン以外へ移ったら枠を隠す＝追従も奪い返しもしない**（`grab_focus` は初期化と「戻る」無効化退避のみ、いずれも自ボタンが focus を持つ時だけ）。シーン遷移中は枠を隠す。**マウス操作中（ポインタ移動を検知）はグロー枠を隠し**、キー/パッドに戻ると再び pop で出す（store_browse と同じ「マウス時はフォーカス表示を出さない」分離）。マウス移動でカーソル表示・キー/パッドで非表示。
- **操作説明バー**（カルーセル/ブラウズ共通の `BottomBar` コンポーネント）を流用して追加。ヒントは **`Enter` 決定のみ**（`set_hints([["Enter","決定"]])`）。グロー枠と同様に**マウス操作中は隠す**（`get_panel().visible = not _using_mouse`）。CanvasLayer ベースなのでシーン遷移のフェードにも追従。操作ボタンの帯は本バーに重ならないよう下端から ~104px に一段上げた（従来 ~48px でバーに隠れ気味だった）。ボタンバーは下端中央にアンカー+offset で高さ72pxの帯として明示配置（`MarginContainer`+preset の min-size タイミング依存で高さ0に潰れる問題を回避）。
- **`scripts/models/intro_slide_info.gd`**: `intro_slides`（DB v22）に対応する読み取りモデル（`slide_id` / `display_order` / `body_text` / `image_path` / `is_visible`）。
- **`scripts/intro_slide_repository.gd`**: `intro_slides` の読み取り専用クエリ（`GameRepository` と同流儀）。`get_visible_slides()`（`is_visible=1` を表示順で取得、`image_path` の DB NULL を空文字へ正規化）+ `has_visible_slides()`（COUNT による軽量存在チェック）。
- **`scripts/path_manager.gd`**: `get_guide_folder()` を追加（スライド画像の格納先 `guide/`、Manager の `PathManager.GuideFolder` と対応）。

#### Changed

- **`scenes/screensaver.gd`**: キー押下時の遷移先を、表示対象スライドが**あれば** `intro_guide` を挟み、**無ければ**従来どおり直接 `store_browse` へ、と事前分岐（`_has_visible_intro_slides()`）。空スライドのとき `intro_guide` を挟むと `TransitionManager` の遷移中再入ガードで `intro_guide → store_browse` の再遷移が無視され画面が固まりうるため、screensaver 側でルーティングする（まっさら新規インストールはスライド 0 件なので通常はこの経路）。`intro_guide` 側にも稀な race 用の空フォールバック（遷移完了待ち後にストアへ）を保持。
- **incoming 遷移 (screensaver → intro) 中のユーザー操作で固まる経路を塞いだ** (コードレビュー指摘)。`_go_to_store` / `_navigate` / `_input` がローカル `_transitioning` だけ見て `TransitionManager._transitioning`（incoming 遷移進行中）を見ておらず、遷移中（≈0.45s）の `Esc`・「進む/ストアへ」押下で `change_scene` が再入ガードに弾かれ、ローカル `_transitioning=true` が残り永続フリーズしうる非対称があった（空スライド経路だけ待ち保護されていた）。全 store 遷移経路を `TransitionManager._transitioning` 完了まで gate して統一。空フォールバックも固定 0.5s タイマでなく `TransitionManager._transitioning` の落下を待つ形に変更（遷移時間定数への暗黙依存を排除）。
- **`.gitignore` に `guide/` を追加**。スライド画像の runtime 置き場（SPEC §7.2）を `games/` と同様に除外（誤コミット防止）。
- **対応 DB スキーマを v14 → v22 に追従** (`database_manager.gd` `CURRENT_DB_VERSION`)。Launcher が本リリースで `intro_slides`（v21 新設 / v22 で `duration_sec` 削除）を読むようになったため。v15〜v20 は Launcher が読まないテーブル / index / 制約のみの変更で読み取り不変（コメントに各版数の根拠を明記）。これで本番 DB(v22) 起動時に毎回出ていた「対応版より新しい」警告を解消。
- **放置時のスクリーンセーバー復帰を追加** (Codex 指摘)。screensaver は既に本シーンに置換されているため、来場者が起こして離席すると初回説明のまま固定されてしまう。store_browse / game_selection と同じ `IdleManager`（60s 警告 → 90s 復帰、入力で reset）を `_process`/`_input` に組み込み。
- **OS キーリピート(echo) を無視** (Codex 指摘)。スクリーンセーバーを起こしたキーを握り続けると echo が連続ナビ／1枚デッキでの即スキップを起こすため、`InputEventKey.is_echo()` を focus 系に渡さず破棄（意図的な押し直しのみ受理）。
- **本文なし かつ 画像が読めないスライドを除外** (Codex 指摘)。画像のみスライドの画像がファイル欠落/非対応形式で読めないとブランクページが出るため、`_load_slides` で除外（全滅時は空フォールバックでストア直行）。あわせて `_get_texture_for` の画像解決/読込失敗を `push_warning` でログし失敗も cache（無言失敗の解消＋再試行抑制、コードレビュー指摘）。

#### Bump 根拠 (v0.9.1 → v0.10.0)

新機能（初回説明画面）の追加のため SemVer minor (`version.gd` MINOR 9→10 / PATCH 0)。読み取り専用追加で DB 破壊的変更なし。Bundle 反映は #253 part 1/2 と合わせてリリース実行時に行う。

### [Launcher v0.9.1] - 2026-05-27

#### Fixed (累積コードレビュー指摘の対応)

- **DB オープン失敗の silent success を解消** (`database_manager.gd`): `db.open_db()` の戻り値を無視し、後続の `if db == null` が常に false の dead code だったため、パス不正 / 権限不足 / ロック等で DB を開けなくても `open()` が `true` を返していた。戻り値で判定し、失敗時は `db = null` をセットして `false` を返すよう修正。これにより「DB を開けないのにゲーム 0 件として正常起動」する経路が塞がれる。
- **ゲーム起動失敗時のログを ERROR レベル化** (`game_session.gd`): 実行ファイル未検出 / プロセス起動失敗の経路が `print("❌ …")` だったのを、同ファイルの既存パターンに揃えて `push_error` に変更 (ログのレベルフィルタで追跡可能に)。あわせて `database_manager.gd` `open()` の失敗経路 (DB ファイル不在 / オープン失敗) も同じ理由で `push_error` に昇格。
- **画面遷移失敗時に復帰演出フラグを汚さないようガード** (`playing.gd`): `change_scene_to_file` の戻り値を確認し、失敗時は `AppState.returning_from_game` / `returning_from_quit` を設定せず early return。成功時のフラグ設定は deferred 遷移より前なので新シーンの `_ready` から正しく参照される。
- `version.gd` の stale なマイルストーンコメントを削除し、ファイル責務の記述に置換。

#### Changed

- **対応 DB スキーマを v13 → v14 に追従** (`database_manager.gd` `CURRENT_DB_VERSION`)。v14 は Manager 側で `games.arguments` を正規 migration 化しただけで最終スキーマは不変、Launcher は `arguments` を既に扱えるため定数追従のみ (マイグレーション不要、§8.2 #5 の共有定数規約)。これで本番 DB(v14) 起動時の「対応版より新しい」警告とサービスモードの DB バージョン非一致表示を防ぐ。

#### Bump 根拠 (v0.9.0 → v0.9.1)

bugfix + DB 対応版数の追従のため SemVer patch (`version.gd` PATCH 0→1)。挙動変更は失敗経路の早期検知 / ログ精度向上に限定、DB 追従は読み取り専用で破壊的変更なし。

### [Launcher v0.9.0] - 2026-05-27

#### Added (#74 — サービスモード / 機能23)

`Ctrl+Alt+F12` で開くスタッフ専用の全画面診断メニュー (autoload `ServiceMode` + `scripts/service_mode_overlay.gd`、CanvasLayer layer 200 / `PROCESS_MODE_ALWAYS` / 裏シーンを pause + 完全不透明の黒背景で凍結 / 60 秒無操作で自動復帰)。左に項目リスト・右に詳細の master-detail で、キーボード (↑↓ / Enter / Esc) とコントローラー (D-Pad / A / B) の両対応。主リストの上下は端でラップ。SPEC §機能23 参照。実装した 14 項目:

1. **入力チェック** — 接続中コントローラー一覧 (`get_joy_info` の `raw_name` で実機の製品名を表示、例: Xbox Series X Controller) + 「入力確認モード」で押したボタン/キー/スティックをライブ表示。日本語配列キーや軸も判別し、Esc / Guide を 3 回で抜ける。
2. **音声チェック** — 880Hz のテスト音を生成再生して音声出力を確認。
3. **画面表示テスト** — グリッド / カラーバー (SMPTE RP 219 / ARIB の HD カラーバー) / 解像度+グレースケール / 単色などのパターンを順次スライドショー表示 (任意キーで次へ・← / Backspace で戻る・Esc / B で中断)。全画面 `Control._draw()` 描画 (画像アセット不要・解像度追従)。
4. **ゲーム動作テスト** — 確認方法を選ぶサブ階層の 3 段階: ①ファイル存在チェック (起動せず exe 有無を全件一括) / ②起動テスト (自動で起動→ウィンドウ生成確認→自動終了で起動可否を判定) / ③試遊テスト (1 本ずつ起動→手動 or HOME/Guide で復帰→〇× 記録→自動で次へ)。チェックリスト + ゼブラ背景。
5. **ネットワーク接続テスト** — 8 段階 (IP→ゲートウェイ→DNS→インターネット→インターネット速度→共有サーバー接続→共有サーバー読込速度→Monitor) を手前から確認 (最初に × が出た所が原因)。疎通は別スレッドで `OS.execute` / TCP、ゲートウェイは ping 無応答ルーター対策で `arp -a` フォールバック + 3 回 ping。速度測定は Godot 単体では不正確なため LauncherAgent(Companion) に委譲 (詳細は `## Companions` の `### [LauncherAgent v0.2.0]`)。Monitor は未実装表示。
6. **データベース整合性チェック** — DB ファイル存在 / 接続 / 読み取り / 必須テーブル / バージョン / テーブル別レコード数を確認。
7. **簡易ログ確認** — 現セッションの直近ログをメモリバッファから一覧表示 (WARN/ERROR 色分け)。あわせて `logger.gd` にリングバッファを追加。
8. **システム情報** — CPU / GPU / メモリ / 解像度 / リフレッシュレート / OS / ロケール / 版数 / パス等を 4 分類で表示し、変動項目 (FPS / メモリ / 日時 / 稼働時間) はリアルタイム更新。
9. **デバッグオーバーレイ切替** — ON で FPS・メモリ・PC名・シーン状態・DB接続等を常時表示する透明・最前面の別 OS ウィンドウ (autoload `DebugOverlay`)。中断メニュー / ゲームの上にも表示継続、メモリのみ保持 (再起動で OFF)。
10. **フルスクリーン切替** / 11. **ランチャー表示モニタ選択** / 12. **再読み込み** / 13. **再起動** / 14. **ランチャー終了** (二段階確認なしで即終了、ゲーム実行中は除外)。

#### Added (#84 — 終了制御)

Alt+F4 / × ボタンを封印し、サービスモードの「14. ランチャー終了」のみを正規の終了手段にした。例外としてサービスモード表示中 (ゲーム非実行時) のみ Alt+F4 を許可。

#### Changed

- **対応 DB スキーマを v12 → v13 に追従** (`database_manager.gd` `CURRENT_DB_VERSION`)。v13 で追加の `manager_sessions` (#179) は Manager 専用で Launcher (読み取り専用 §6.5) は非対象のため、定数追従のみ (マイグレーション不要)。これで本番 DB(v13) 起動時の「対応版より新しい」警告とサービスモードの DB バージョン非一致表示を解消。
- **エラーダイアログにエラーコード別の対処法を併記** (`error_dialog.gd` `_REMEDY`、ゲーセン筐体のエラー表示と同様)。スタンドアロンの `ERROR_CODES_MANUAL.txt` を廃止。
- フォントを Noto Sans JP に統一、配色を 見出し=白 (C_ACCENT) / 本文=薄灰 (C_TEXT) / 補足=濃灰 (C_MUTED) の 3 段で統一。

#### Bump 根拠 (v0.8.1 → v0.9.0)

大規模な新機能 (サービスモード 14 項目 + 終了制御) の追加のため SemVer minor (`version.gd` MINOR 8→9 / PATCH 1→0)。DB 対応版数の追従は読み取り専用で破壊的変更なし。

### [Launcher v0.8.1] - 2026-05-25

#### Changed (#219 — ゲーム中のランチャー誤前面化を自動復旧)

#216 (前面化異常検知) のフォローアップ。従来は「異常検知 → 即スタッフ警告」だったのを、**警告の前にゲーム窓を強制前面化して自己修復を試み、リトライを尽くしても background のままなら警告**する二段構えに変更。

- `GameSession._update_anomaly_detection`: 異常がデバウンス (2s) を超えて確定したら、即 `ErrorManager.show_error` せず `LauncherAgent.focus(running_pid)` でゲーム窓を強制前面化。`ANOMALY_RECOVERY_INTERVAL_MS` (500ms) 間隔で最大 `ANOMALY_RECOVERY_MAX_ATTEMPTS` (3) 回リトライし、次 probe で復旧 (ゲーム前面) を確認できたら警告なしでリセット。尽きても background ならスタッフ警告 (`GAME_LAUNCHER_FOREGROUND_ANOMALY`) を出す。
- Windows の foreground-lock 制限で `SetForegroundWindow` が効かないケース (タスクバー点滅のみ等) があるため、復旧は 100% 保証せず「トライ → 失敗時のみ警告」を前提とする。
- 意図的な前面化 (中断オーバーレイ表示 #30 / quit 中) は既存の whitelist (`OverlayManager.is_open() or _quitting`) で異常カウントから除外済み (#219 タスク項目4)。

#### Bump 根拠 (v0.8.0 → v0.8.1)

既存 #216 セーフガードの挙動強化 (自己修復の追加) で新規 UI/機能面はないため SemVer patch (`version.gd` PATCH 0→1)。

### [Launcher v0.8.0] - 2026-05-22

#### Added (#30 — ゲーム実行中の中断オーバーレイメニュー)

ゲーム実行中に **HOME キー / コントローラ Guide ボタン**で開く透明・最前面の中断メニューを実装。メニュー項目は「**続ける** / **別のゲームをあそぶ** / **退出する**」の 3 つ (spike #218 当時は「再開 / 選択画面に戻る」の 2 項目 MVP、その後 #214 の作り替えで 3 項目に拡張)。spike #218 で「Godot 透明オーバーレイ (同一プロセス) でゲームの上にメニューを描き、ゲームは裏で描画継続」が実機 (Only Up) で成立することを確認のうえ採用 (WPF 別窓案は不採用)。

- **描画**: `scenes/overlay_menu.tscn` + `scripts/overlay_menu.gd` — 透明・最前面・borderless の実 OS `Window` (`project.godot` に `per_pixel_transparency/allowed=true` + `subwindows/embed_subwindows=false`)。中央に減光パネル + メニュー、show 時に最前面再アサート、初期フォーカスは「再開」(誤決定が安全側)、`ui_cancel` (Esc / コントローラ B) で再開。
- **トリガ**: 常駐 `LauncherAgent` (sensor) が watch 中のみ HOME/Guide をグローバル検知 → UDP `trigger` → `OverlayManager` (autoload) が開閉トグル。Companion sensor は watch 中=ゲーム実行中のみ発火するため、トリガはゲーム中限定。同時押しコンボ (L3+R3/START+BACK) は不採用 (#30 議論)。
- **操作 (停止 OK 案)**: メニューに排他入力を渡す＝ゲームからフォーカスを奪う＝ゲームは一時停止しうる (ポーズメニューとして許容)。再開時は `LauncherAgent.focus` でゲーム窓を前面復帰、終了時は `taskkill /T` でゲームプロセスツリー終了 → 既存 `_on_game_exited` で選択画面復帰 (#84 連動)。
- **#216 連携**: 中断オーバーレイ表示中はランチャーが意図的に前面化するため、前面化異常検知を whitelist (表示中は異常カウントせず、close 後はデバウンスから再計測)。

#### Changed (#101 / #216 — probe を常駐 LauncherAgent へ移行)

旧 `WindowProbe` (単発 `OS.execute` を専用スレッドで poll) を**常駐 `LauncherAgent` + 双方向 UDP** に置換。150ms ごとのプロセス spawn を廃し、Companion 内部ポーリングの `window` イベント push を `GameSession._process` が消費する形に。起動中→プレイ中遷移 (#101) / 前面化異常検知 (#216) の判定ロジックは温存 (#214 で `GameSession` autoload へ移管)。

- 新 autoload `scripts/launcher_agent.gd` (`LauncherAgent`): Companion を起動時に 1 個常駐起動、hello ハンドシェイクで cmd-port 取得、`window` 状態保持 + `WindowState` enum 提供、`trigger` を signal 発火、`log` を `[LauncherAgent]` 付きで launcher ログへ転送 (Manager の Launcher タブに出る、Manager 改修不要)、`watch`/`unwatch`/`focus` cmd 送信。
- probe スレッド/Mutex を撤去し `LauncherAgent.watch/unwatch/get_window_state` に置換 (#214 で監視は `scripts/game_session.gd` (`GameSession`) に移管、`game_launcher.gd` は演出ヘルパーに縮小)。`scripts/window_probe_client.gd` 削除。
- WindowProbe の撤去・Release.ps1 同期は `## Companions` の `### [LauncherAgent v0.1.0]` を参照。

#### Changed (#214 — プレイ中軽量シーン化 + 中断オーバーレイの 2 枚構成 + 背景非同期ロード)

i3 内蔵GPU・8GB のメモリ逼迫 (#214) 対策と、中断オーバーレイの描画方式の整理のため以下に作り替えた:

- **ゲームセッションの autoload 化**: 起動/監視/PLAYING 確定/前面化異常(#216)/resume/quit/プロセス死活を `scripts/game_session.gd` (`GameSession` autoload) に移管。シーンをまたいで監視が途切れない。`game_launcher.gd` は起動/復帰の画面演出ヘルパーに縮小。
- **プレイ中軽量シーン**: PLAYING 確定で重い `game_selection` (全ゲーム分のカルーセル/サムネ) を破棄し、背景+選択ゲームのサムネだけの軽量 `scenes/playing.tscn` へ `change_scene` (メモリ削減)。ゲーム終了で `game_selection` へ復帰し、起動モーションの逆再生でカルーセルに戻る。
- **中断オーバーレイの 2 枚構成**: 中断メニューは**透明・最前面・borderless の別 OS Window** (`overlay_menu`、`per_pixel_transparency/allowed=true` + `embed_subwindows=false`) として走行中ゲームの上に重ね、背面に**不透明・全画面の playing シーン (背景アート)** を据え置く。透明窓部分はゲーム窓のところ=ライブゲーム / ウィンドウゲームの隙間=背景アートを映すため、デスクトップが透けない (2 枚サンドイッチ)。overlay 窓のフォーカス奪取は companion の `focus_hwnd` で overlay 窓だけを前面化 (メイン窓を巻き込まない)。メニュー項目は「続ける / 別のゲームをあそぶ / 退出する」の 3 つ。
  - 試行錯誤の経緯: 当初は別 OS Window、次に「メイン窓内の単一 `CanvasLayer` + メイン窓 per-pixel 透明化 + companion topmost」案を試したが、ウィンドウ起動ゲームの隙間にデスクトップが漏れる退行のため**上記 2 枚構成 (別窓 + 不透明 playing 背景) に戻した**。単一ウィンドウ案で要した companion `topmost` cmd・すりガラス用 `ScreenCapture.cs` / `frosted_image.gdshader` / `capture` cmd は撤去 (本 PR 内で追加→撤去、net zero)。
- **背景ロードの非同期キャッシュ化**: カルーセルの背景画像をワーカースレッドでデコード + 上限付き LRU キャッシュ化し、スクロール時のメインスレッドブロック (フルHD 同期デコード) を解消。あわせて死んでいた背景描画の旧経路 (`GameInfoDisplay._update_background`) を削除。
- **マルチモニタ対応**: ゲームが別モニタに開いても 2 枚構成が崩れないよう、(a) overlay をゲーム窓のいるモニタへ追従表示 + (b) watch 開始時にゲーム窓をランチャーのモニタへ寄せる (`Win32Windows.PlaceWindowCentered`)。本番=単一モニタでは無害。

#### Bump 根拠 (v0.7.0 → v0.8.0)

中断オーバーレイ (#30) + プレイ中メモリ削減アーキ (#214) の新機能追加のため SemVer pre-1.0 minor bump (`version.gd` MINOR 7→8)。#214 のオーバーレイ構成見直し + プレイ中軽量シーン化は #30 と同一 PR (feature/overlay-menu) 内の継続作業のため、AGENTS.md「1 PR 1 bump」原則に従い本 v0.8.0 entry に加筆 (新 version は起こさない)。

### [Launcher v0.7.0] - 2026-05-21

#### Added (#101 / #216 — WindowProbe による起動中→プレイ中の遷移同期 + ランチャー前面化異常検知)

WindowProbe Companion (`## Companions` の `### [WindowProbe v0.1.0]` 参照) を Launcher に統合。

**起動中→プレイ中の遷移同期 (#101)**: 旧来は `OS.create_process` 直後に即「プレイ中」表示へ切り替えていたため、Windows Defender スキャンやゲーム初期化で実際のウィンドウ出現が遅れると表示と実態にラグがあった。新たに probe を専用スレッドで ~150ms 間隔に呼び、ゲームのプロセスツリーに可視ウィンドウが出現した時点で `LaunchingOverlay.State.PLAYING` へ遷移する。可視ウィンドウを検出できないまま 1 分（60 秒）経過した場合はフォールバックで強制 PLAYING（下記「フォールバック」参照）。spawn 前の固定 1 秒待機は最低表示時間としてそのまま残す。

**ランチャー前面化異常検知 (#216)**: ゲーム実行中に「ランチャーが前面 (`window.has_focus()`) かつゲームが前面でない」状態が 2 秒継続したら、新エラーコード `2005 (GAME_LAUNCHER_FOREGROUND_ANOMALY)` でスタッフ向けエラーを表示する。ゲームが前面に戻れば自動でエラーをクリア。誤検知対策として (a) **異常監視を arm するのは「WindowProbe が可視ゲーム窓を実際に一度でも観測した」時のみ** — 初回起動の Defender / SmartScreen スキャン等で窓出現が遅れている間 (= 窓が無い) に「窓が無い＝異常」と誤発報するのを防ぐ。フォールバックタイムアウト (下記) で PLAYING ラベルにしただけでは arm しない、(b) プロセス消滅は既存の終了処理に委ね「プロセス生存 × 前面喪失」のみ異常とする、(c) 2 秒デバウンスで一瞬の Alt-Tab を除外。

**フォールバック**: 可視窓を検出できないまま 1 分経過したら「起動中」で固まらないよう強制的に PLAYING ラベルへ (初回スキャンが長引くケースを許容するため 60s に設定)。ただし上記のとおりこの強制 PLAYING では異常監視を arm しないため、窓が出ないゲームで誤ってスタッフ呼び出しが出ることはない。

**実装**:
- 新規 `scripts/window_probe_client.gd` (`WindowProbeClient`): exe path 解決 + `OS.execute` 実行 + 出力 → enum 変換。exe は本番配置 (`Companions/WindowProbe/TonePrism_WindowProbe.exe`) と **dev ビルド出力** (`Companions/WindowProbe/bin/{Release,Debug}/`) の候補を順に探索し、Godot エディタ実行でも probe が効くようにする。いずれも不在なら `UNAVAILABLE` を返し、呼出し元は従来挙動 (即 PLAYING / 異常検知なし) にフォールバック。
- `scripts/game_launcher.gd`: spawn 後に probe 専用 `Thread` を起動し結果を `Mutex` 保護の共有変数に格納。PLAYING 遷移判定 / 前面化異常判定はメインスレッド (`monitor_process`) で共有結果 + `has_focus()` を読んで行い、全 UI/Window アクセスをメインスレッドに集約 (call_deferred 不要)。プレイ確定後は poll 間隔を ~1s に粗くして i3 実機の負荷を抑える (#214 関連)。旧来 write-only で未使用だった `_has_lost_focus_since_launch` フラグは、前面判定を `window.has_focus()` の直接参照に統一したため削除。
- `scenes/game_selection.gd`: `_exit_tree` で probe スレッドを join (ゲーム実行中にランチャーが閉じられた場合の保険)。
- `scripts/error_code.gd`: `GAME_LAUNCHER_FOREGROUND_ANOMALY = 2005` 追加。
- `scripts/error_manager.gd`: `hide_error()` を追加 (自己回復するエラーの自動クローズ用)。
- `scenes/components/error_dialog.gd`: コード別の文言上書きマップを追加し、2005 にスタッフ向け文言を表示 (既存コードは tscn 静的文言を維持)。

**ログ方針**: Launcher の Logger API 直接呼び出し (#85 で対応予定) は未整備のため、本実装も既存どおり `print()` (godot.log tail 経由で INFO 取り込み) を使用。異常検知のみ `push_warning()` で WARN レベルに振り分け。

### [Launcher v0.6.2] - 2026-05-20

#### Added (#201 — Unified logs root path 設定の Launcher 側受信)

Manager v0.15.0 で導入される `logs_root_path` setting (= 全 component 共通の親 logs root) を Launcher が受信して log dir を移設するための受信経路を追加。

**実装** (`Launcher/scripts/logger.gd`):
- `_open_log_directory_and_file` 内で project root 解決後、新 helper `_read_logs_root_from_responses(project_root)` を呼出
- `<project_root>/responses/launcher_logs_root.json` を read、parse 成功 + `logs_root_path` field 非空なら `<custom_root>/launcher/` を log dir に使用
- JSON 不在 / parse 失敗 / path 空 はすべて既存 default `<project_root>/logs/launcher/` に fallback、`push_warning` のみ + Launcher 起動は阻害しない
- autoload 順序 (= Logger 最先頭) は維持、本 file read は DB 接続前で完結 (= SPEC §6.5 「Launcher は SQLite write しない」原則維持、read も SQLite ではなく drop file 経由)

**Manager 側の SoT**: Manager v0.15.0 の `LauncherLogsRootBridge.WriteCurrentLogsRoot` が `responses/launcher_logs_root.json` を atomic write する (= SessionHeartbeat と同 pattern)、Manager UI 変更時 + Manager 起動時に file 更新。Launcher は本 PR で受信側 logic のみ実装、書出はしない (= unidirectional Manager → Launcher 設定伝搬)。

**反映タイミング**: 次回 Launcher 起動時。Manager save 時に file は即時更新されるため、Launcher 再起動だけで反映 (Manager 再起動は不要)。

**docstring**: Logger.gd 冒頭の保存先記述を unified semantic に書換え、Manager v0.15.0 との連動 + responses/ drop file pattern + SPEC §6.5 原則維持を明示。

#### Bump 根拠 (v0.6.1 → v0.6.2)

SemVer pre-1.0 patch bump: Launcher 単体 user 視点で UI 変化ゼロ、Manager 連動機能の Launcher 側 contribution は patch 慣例 (= PR #184 manager_sessions / PR #189 launcher heartbeat と同 pattern)。詳細は `## Manager v0.15.0` 参照。

### [Launcher v0.6.1] - 2026-05-19

#### Changed (#170 — copyright metadata sync)

`export_presets.cfg:50` `application/copyright` を `Copyright (c) 2025 Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)` (旧個人表記、年 2025 単独) → `Copyright (c) 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)` に書換、`LICENSE:3` / `README.md:96` と同期。`TonePrism_Launcher.exe` を右クリック → プロパティ → 詳細の Copyright 表示が LICENSE と整合するようになる (= 次回 Godot export 以降反映)。

書式判断は `## Companions Updater v0.2.1` entry 参照、3 component で同じ表記に統一。

bump 判断: export config metadata 変更は SemVer 上 patch (0.6.0 → 0.6.1)。GDScript behavior / scene / runtime logic は完全に無変更、Godot export 出力 exe の Windows PE metadata だけが変わる。`version.gd` `PATCH=0 → 1`、`project.godot` `config/version="0.6.1"`、`export_presets.cfg` `file_version="0.6.1.0"` / `product_version="0.6.1.0"` を同期更新 (SPEC §3.7.8 launcher version SoT 3 か所同期チェックリスト準拠)。同様の sync 動機は `## Manager v0.12.1` / `## Companions Updater v0.2.1` も同時 bump、cross-cutting copyright 統一として 3 component 同期。

### [Launcher v0.6.0] - 2026-05-19

#### Changed (#168 — 完全 rename + 配布対象拡張、破壊的変更)

Bundle v0.5.0 完全 rename の Launcher 側 contribution。詳細は `## Manager v0.12.0` entry 参照、本 entry は Launcher 単体の変更点のみ記録。

minor bump 判断: SemVer pre-1.0 原則 (= 0.x で breaking change は minor bump OK) に乗って 0.5.18 → 0.6.0。Launcher 単体での user 視点変化 (= `TonePrism_Launcher.exe` filename / title `TonePrism`) は brand 統一の visible part、patch (= 旧 PR3b の `0.5.17 → 0.5.18` 等) では収まらない範囲のため minor bump 妥当。

- **exe filename rename**: `GCTonePrism_Launcher.exe` → `TonePrism_Launcher.exe` (`project.godot` `config/name` + `export_presets.cfg` `product_name` 同期)
- **`config/version` / `file_version` / `product_version` を 0.6.0 / 0.6.0.0 に bump** (`version.gd` `MAJOR=0 / MINOR=6 / PATCH=0`、project.godot `config/version="0.6.0"`、export_presets.cfg `file_version="0.6.0.0"` / `product_version="0.6.0.0"`)
- **`export_presets.cfg` `file_description`** を `ゲームセンターTONE 統合ランチャーシステム「Prism」` → `TonePrism` に短縮統一
- **GDScript 内 `prism.db` literal sweep**: `scripts/path_manager.gd` / `scripts/logger.gd` / `scripts/session_heartbeat.gd` の DB filename literal を `prism.db` → `toneprism.db`。**round 2 review fix (Critical-1)**: 初版 commit `f2ab083` の `\bprism\.db` regex sweep が `path_manager.gd` 内の Japanese 文字隣接 occurrence を miss → round 1 fix で補完 `Edit replace_all` を実行したが、当時の file 状態が「一部 `toneprism.db` (既置換) + 一部 `prism.db` (未置換)」混在で、literal pattern `prism.db` が **既置換側の `toneprism.db` 内の `prism.db` 部分** にも match → 二重置換で `tonetoneprism.db` (double-`tone`) が 4 callsite + 4 comment 計 8 箇所で生成される Critical bug が発生。本番 install で Launcher の DB 解決が完全に壊れる (= E-1001 DATABASE_NOT_FOUND emit、ゲーム一覧 / プレイ記録 / アンケート参照が即死) 致命的状態。round 2 で `replace_all 'tonetoneprism.db' → 'toneprism.db'` で 8 箇所を一括修正。同類 double-prefix bug は他 file になし (grep `tonetone` / `TonePrism_TonePrism` で 0 hit confirm)
- **GDScript 内 `GCTonePrism` 参照 sweep**: `path_manager.gd` の self-reference detection literal を `GCTonePrism` → `TonePrism`

### [Launcher v0.5.18] - 2026-05-18

#### Added (#179 PR3b — LAN-wide session tracking heartbeat 出力)

- **新規 autoload `scripts/session_heartbeat.gd`**: 学校 LAN 上の SMB 共有 `prism.db` 運用で、Manager 編集中に Launcher の SQLite read が file lock 競合する path (= 「DB を開けません」error / Manager INSERT stall / 最悪 prism.db 破損) を予防するため、Launcher 側から「自 PC で Launcher 稼働中」を Manager に伝える heartbeat 機構を追加。`<base>/responses/launcher_sessions/<pc_name>.json` (= 1 PC 1 file、heartbeat 専用 sub-folder) に 10 秒周期で JSON を atomic write (`.tmp` → rename) し、Manager 側 `LauncherSessionService` が on-demand polling で読込。
- **JSON schema** (= SPEC §3.8.7.2 で literal 定義、Manager / Launcher 両 implementation の SoT):
  ```json
  { "pc_name": "PC-A", "started_at_unix_ms": 1715379600000,
    "last_heartbeat_at_unix_ms": 1715379630000, "pid": 12345,
    "launcher_version": "0.5.18" }
  ```
- **動作**:
  - `_ready()`: `responses/launcher_sessions/` directory 不在時に `DirAccess.make_dir_recursive_absolute` で自動作成、初回 heartbeat write、`Timer` node (`wait_time=10`、`autostart=true`、`one_shot=false`) を child として add
  - `_on_heartbeat_tick()`: 10 秒周期で JSON 再書込 (`last_heartbeat_at_unix_ms` を update + atomic rename)
  - `_notification(NOTIFICATION_PREDELETE)`: self JSON 削除 (clean shutdown 即時反映)、削除失敗時は `push_warning` trail (= Launcher autoload `Logger` の Godot log tail で自動 WARN 分類) + Manager 側 30 秒 stale fallback で fail-safe
  - `_get_pc_name()`: COMPUTERNAME (Windows) → HOSTNAME (Linux/macOS) → "unknown" の 3 段 fallback (`logger.gd:204-210` と同 logic)
- **fail-soft 戦略**: directory 作成失敗 / write 失敗時は `_init_failed = true` に倒し、以降 silent skip。`push_warning` で trail を残しつつ Launcher 起動 / ゲームプレイは一切止めない (= 部員視点で見えない fail-soft 原則、`logger.gd` の同型 pattern を踏襲)。本 PR は **Godot 4 built-in `Logger` class と autoload `Logger` の名前衝突 (= GDScript パーサーが built-in に解決して static method lookup 失敗) を避けるため `print` / `push_warning` legacy API を使用**、Launcher autoload `Logger` の Godot log tail で INFO / WARN に自動分類される。明示 `Logger.info / warn / error` 直 call への移行は #85 (Launcher 統一ログ基盤 sweep) 完了後に実施予定 (= 既存 logger.gd L10 で明記済の落とし穴を新規実装で踏まないようにする規約)
- **`project.godot` `[autoload]` 登録**: `SessionHeartbeat="*res://scripts/session_heartbeat.gd"` を `Logger` 直後に追加。`Logger` (= 最先頭規約) / `Version` (class_name RefCounted、autoload ではない) / `PathManager` (同) に依存
- **`config/version` を `0.5.17` → `0.5.18`** + `version.gd` の `PATCH` も `17` → `18` に同期 (= `Manager/Services/VersionInventory.cs` の regex parse 要件を維持、SPEC §3.7.8 チェックリスト)
- **patch bump 判断**: Launcher 単体 user 視点で UI / 操作変化ゼロ (= disk に 1 file 書出すだけの additive 拡張)、Manager v0.11.0 と連動して初めて「他 PC Launcher 稼働中」dialog 警告が動作する。AGENTS.md「Release and Versioning」minor=「機能追加」の解釈で Launcher 単体追加機能なら minor だが、本 PR は **Manager 連動機能の Launcher 側 contribution** という framing で patch bump 慣例
- **scope 外** (= 別 PR 余地): Launcher 側で「他 PC Manager 編集中」を逆方向検出する機構は本 PR scope 外、後追い PR で対称化可能
- **詳細は SPEC §3.8.7** および `## Manager v0.11.0` 参照

### [Launcher v0.5.17] - 2026-05-13

PR #150 で dir rename (`GCTonePrism_Launcher/` → `Launcher/`) に連動して `scripts/path_manager.gd` の self-reference リテラル + priority-3 detection ロジック (begins_with 二段比較 + Launcher/Manager sibling 同時存在検証) を修正。配布構造変更を含むため SemVer 厳密だと minor 寄りだが、Install.bat の v0.2.0 → 新構造 migration で自動吸収されエンドユーザー視点では invisible のため patch bump 扱い。

**詳細は [Release Tooling v0.1.10](#release-tooling-v0110---2026-05-13) entry および SPEC §2.4 / §3.7.x 変更履歴 v1.10.9 を参照** (AGENTS.md「重複記述は避ける」規約準拠、round 7 L6)。

### [Launcher v0.5.16] - 2026-05-11

#### Added

- **ファイルログ基盤 (#116, #85 の土台先行)**: 新規 autoload `scripts/logger.gd` を追加し、`<project_root>/logs/launcher/launcher_<PCname>_<YYYY-MM-DD_HHmmss>.log` に **1 起動セッション = 1 ファイル** でログ出力。INFO / WARN / ERROR の 3 段階、`[YYYY-MM-DD HH:mm:ss] [LEVEL] [Module] msg` 形式（Manager と統一）
  - **既存 print 系を Godot 標準ログのテールで自動キャプチャ**: 既存 41 件 / 6 ファイルの `print()` および `printerr()` / `push_warning` / `push_error` がすべて自動的にファイルにも流れる仕組み（コード変更ゼロ）。実装は Godot 標準ファイルログ (`user://logs/godot.log`) を 0.5 秒間隔でテール → 新規追加分を本セッションファイルに `[Godot]` プレフィックス付きで転送
    - 行頭の `WARNING:` / `USER WARNING:` → WARN、`ERROR:` / `SCRIPT ERROR:` / `USER ERROR:` → ERROR、それ以外 (print 等) → INFO で自動振り分け
    - **設計の経緯**: 当初は `OS.add_logger` (Godot 4.5+) で `Logger` クラスを継承したカスタムロガーを登録する方針だったが、Godot 4.6 の GDScript パーサーが script 継承の `Logger` 型変換を蹴る (inner class / class_name / preload + as Logger キャストすべて NG) ため、Godot 標準ログのテール方式に切替。0.5 秒の polling 遅延が出るが、Godot 内部エラーまで含めて全部キャプチャできるメリットあり
  - **明示 API**: 新規コードからは `Logger.info(msg)` / `Logger.warn(msg)` / `Logger.error(msg)` でレベル指定可能
  - **保存先**: prism.db と同じ共有先 `<project_root>/logs/launcher/` に集約。Manager 側 `<project_root>/logs/manager/` と並列配置で、将来 Manager のログビューア UI から複数 PC の Launcher ログも 1 箇所で閲覧可能に
  - **1 セッション 1 ファイル設計**: PC 名 + 起動時刻でファイル名がユニークになるため、複数展示 PC の Launcher が同時に同じ共有先へ書き込んでも書き込み競合・行間 interleaving が一切起きない。同秒衝突は連番サフィックスで回避
  - **30 日 retention**: 起動時に `logs/launcher/launcher_*.log` をスキャンし、`get_modified_time` が 30 日より古いものを削除。現セッションのアクティブファイルは保護
  - **prism.db 自動検出 + フォールバック**: PathManager と同じく exe ベースで上に prism.db を 10 階層まで探す軽量ロジックを Logger 内部に持つ（PathManager の起動 print も Logger でキャプチャしたいため、依存を持たせず重複実装）。見つからなければ exe 隣（エディタ実行時は `res://`）にフォールバック
  - **起動・終了イベント記録**: `_init()` で「Launcher 起動 (PC=...)」、`NOTIFICATION_WM_CLOSE_REQUEST` / `NOTIFICATION_PREDELETE` で「Launcher 終了」を必ず INFO 出力
  - **`Logger` autoload を最先頭に登録**: `project.godot` の `[autoload]` 先頭に追加して、他の autoload (`ErrorManager` / `AppManager` 等) の `_init/_ready` の出力も確実にキャプチャ
  - **既存 `user://logs/` (Godot 標準) との関係**: %APPDATA% 配下の Godot デフォルトログは引き続き残るが、本基盤の `<project_root>/logs/launcher/` が事故調査時の正規場所。本番展示 PC のリカバリで揮発しない
  - **横断要件として SPEC §3.6 / AGENTS.md "Cross-component Standards" に格上げ**: 同じベースラインを Monitor 等の将来コンポーネントでも適用する仕組みを文書化

#### Changed

- **`config/version` を `0.5.15` → `0.5.16` に更新、`version.gd` の `PATCH` も `14` → `16` に同期**
- **`scripts/database_manager.gd` の `CURRENT_DB_VERSION` を 8 → 12 に追従**: Manager 側 DB が v9 → v12 まで進んでいたが Launcher が 8 のまま放置されており、起動毎に「DBバージョン(12)が Launcher の対応バージョン(8)より新しい」警告が出ていた問題を本 PR の動作確認で発見。v9 / v10 / v12 は backup_log 関連で Launcher は触らない、v11 の surveys / play_records 新スキーマには Launcher のクエリが既に対応済 (`pr.start_time` 等を参照) のため、定数追従のみで安全に解消

#### Changed

- **`prism.db` のジャーナルモードを WAL → DELETE へ移行 + `busy_timeout=10000` (#103)**: 学校 SMB ファイルサーバー上で `prism.db` を共有する運用形態において、SQLite 公式が WAL モードの動作を保証外と明言しているため、Manager v0.8.2 と歩調を合わせて `PRAGMA journal_mode=DELETE` に変更
  - 続けて `PRAGMA busy_timeout=10000` を発行し、書き込み競合時に即時 SQLITE_BUSY を返さず最大 10 秒待機する挙動に
  - Launcher は実質 Read-Only（アンケート/プレイ記録は drop-folder 経由）のため運用上の体感影響は無い見込み
- **`config/version` を `0.5.8` → `0.5.15` に同期**: `project.godot` の `config/version` が v0.5.9〜v0.5.14 のリリース時に更新されていなかった drift を本リリースで解消

### [Launcher v0.5.14] - 2026-05-03

#### Fixed

- **ゲーム情報パネルの製作者欄が空になる問題を解消**: v0.5.8 で製作者クエリを `developers JOIN game_versions` の INNER JOIN 形式に変えたが、Manager の通常追加/更新フローでは `developers.version_id` を NULL のまま INSERT するため、全ゲームで製作者が表示されなくなっていた。`get_developers_by_game_id` を 2 段階クエリに変更し、現行バージョン (`games.version` ↔ `game_versions.version`) に紐付いた製作者があればそれを返し、無ければ `version_id IS NULL` の行にフォールバックする挙動に修正

### [Launcher v0.5.13] - 2026-05-01

#### Added

- **ゲーム起動中・プレイ中オーバーレイ (`launching_overlay.tscn` / `.gd`)**: ゲーム起動から終了までの間、画面右側に状態表示を出すオーバーレイ
  - 全画面うっすら白オーバーレイ（α=0.5）で背景を透けさせつつ "別モード" 感を演出
  - 右側に「ゲーム起動中...」/「プレイ中」のステータス文字（呼吸アニメ付き）
  - 細い区切り線の下にゲームタイトル（太字・大）。タイトルが幅を超えたら `auto_scroll_container` で自動スクロール
- **状態切り替え API**: `LaunchingOverlay.set_state(LAUNCHING / PLAYING)` で文言とアニメ速度が切り替わる。ゲームウィンドウ起動前後で自動的に LAUNCHING → PLAYING へ遷移
- **ゲーム起動・終了時の背景ズーム演出**: `_switch_to_running_view` / `_switch_to_normal_view` で背景画像を中心からほんのちょっと拡大（×1.05）/縮小して、フェードと同じ TRANS_QUINT で同期させた映画的な遷移に

#### Changed

- **GameLauncher のシグネチャを刷新**: 未使用だった `running_overlay: Control` パラメータを廃止し、新規 `launching_overlay: LaunchingOverlay` に置き換え。`_switch_to_running_view` / `_switch_to_normal_view` も同様に整理。背景ズーム用に `background_texture: TextureRect` パラメータも追加
- **遷移イージングを TRANS_CUBIC → TRANS_QUINT に変更**: 起動中画面とのフェードを映画的なカーブに。所要時間も 0.4-0.5s → 0.55s に統一
- **遷移は全要素 EASE_OUT で統一**: 起動時 / 終了時とも `TRANS_QUINT EASE_OUT` で「決定的に始まり、ゆっくり収まる」スナップ感のあるカーブに統一
- **カルーセルカードの透明度を中心からの距離で連続補間**: 従来は「選択中=1.0/それ以外=0.6」の二値で、中央到達時にパッと変化していたのを、`diff` の絶対値で線形補間する形に。トラックパッド free scroll で半分だけ移動した時も両カードが半分の濃さになる
- **背景画像をカルーセルの scroll_index に応じて連続クロスフェード + 上下スライド**: `BackgroundTexture` (前面) と `BackgroundTextureOld` (背面) に floor/ceil(scroll_index) のゲーム背景をそれぞれロードし、fract で前面の alpha を 1 から 0 に補間。さらに lower bg は上に、upper bg は下から上に、最大 ±50px スライドする視差効果を追加。スクロール途中で次のゲームの背景がだんだん表れ、中央到達時には完全に切り替わってる挙動に。`_update_background` の従来 tween 方式は廃止
- **背景なしゲームとの切り替えで bg が突然現れる/消える問題を解消**: 各 bg の `texture != null` を見て alpha を計算。背景なし → ありの遷移では bg_b を `fract` で徐々にフェードイン、あり → なしでは bg_a を `1-fract` でフェードアウト
- **キーボード/コントローラー操作中はマウスカーソルを自動的に隠す**: 入力イベント毎に `Input.mouse_mode` を `HIDDEN` / `VISIBLE` で同期切替。マウスを動かすと即座に再表示。`game_selection` / `store_browse` / `common_dialog` 各画面で対応。シーン遷移時には状態を持ち越し（`_ready` での強制リセットはしない）。pause 中のダイアログでも `process_mode = ALWAYS` の dialog 側 `_input` でカーソル状態を更新
- **起動中/プレイ中ステータステキストにシマーシェーダー適用**: LOADING 表示と同じ `progress_shimmer.gdshader` を「ゲーム起動中...」「プレイ中」に流用し、暗いベース → 中間色 → 暗いベースの波が文字を流れる効果に。LAUNCHING は速め (speed=1.8)、PLAYING はゆっくり (speed=0.7) に切替。`ShimmerHelper.apply_with_params` を新設して任意のパラメータ指定を可能に

#### Fixed

- **起動中/プレイ中のカルーセル入力をブロック**: `game_selection._unhandled_input` で `_game_launcher.is_running()` 時に早期 return、`_process` 内で `_trackpad_offset = 0` 強制リセット。トラックパッド/ホイール経由でカルーセルが動いてしまう問題を解消

### [Launcher v0.5.12] - 2026-04-28

#### Added

- **トラックパッド向けフリースクロール対応**: `InputEventMouseButton.factor` を見て、マウスホイール（factor>=0.5）はディスクリート1ゲーム移動、トラックパッド（factor<0.5）はフリースクロール + 離したら最寄りゲームにスナップ、と入力デバイスに応じて挙動を分離。`InputHandler.free_scroll(delta_amount: float)` シグナル追加
- **CarouselController に視覚オフセット引数を追加**: `update_cards(... free_offset: float ...)` で `current_scroll_index` の補間先に上乗せできるように。フリースクロール中は `new_active` を `selected_index` で固定してチラつきを防止

#### Changed

- **InfoPanel の縁ぼかしを除去**: 12px の透明ボーダー + `border_blend` + `expand_margin` を削除し、すりガラスのエッジをくっきりさせた。角丸 32px は維持

#### Fixed

- **トラックパッド2本指でカルーセルが爆速で流れる問題を解消**: 従来は1イベント=1移動だったため、Windows precision touchpad の高頻度イベントで暴走していた。factor 蓄積方式 + スナップ遅延でなめらかな操作感に

### [Launcher v0.5.11] - 2026-04-27

#### Added

- **すりガラスシェーダー (`frosted_glass.gdshader`)**: `SCREEN_TEXTURE` を 49-tap でサンプリング（Vogel disk / 黄金角スパイラル分布で擬似一様配置）してぼかし、tint と合成するキャンバスアイテムシェーダー。`blur_radius` / `tint_color` / `tint_strength` を uniform として公開し、インスペクタから調整可能

#### Changed

- **ゲーム選択画面の InfoPanel をすりガラス風に変更**: 背景を単純な半透明黒（α=0.8）から、背景画像をぼかして見せるすりガラス効果へ置き換え。StyleBoxFlat の角丸 32px と縁ぼかし 12px は維持し、形状マスクとして利用
- **スクリーンセーバーのレンガモザイク背景を実ビューポートサイズに追従**: `viewport_w` / `viewport_h` のハードコード（1920×1080）をやめ、`get_viewport_rect().size` で実サイズを取得。16:10 等のアスペクト比でも上下に偏らず画面全体に行き渡るよう修正
- **モザイク行数のデフォルトを 5 → 4 に変更**: タイルがより大きく見える構成に
- **モザイクタイルサイズを画面高さ自動フィットに変更**: 新規 `@export fit_height_to_viewport`（既定 true）で `row_count` 行がビューポート高さを埋めるよう tile_size を自動拡縮。アスペクト比は `tile_size` の x/y で指定（既定 1.8）。固定サイズで運用したい場合は false に

### [Launcher v0.5.10] - 2026-04-19

#### Added

- **シマーシェーダー (`progress_shimmer.gdshader`)**: 白い光の帯が左→右に流れるエフェクトをGPUで実装。プログレスバーと LOADING ラベルで共通利用
- **ShimmerHelper**: シマーエフェクト適用を一元管理するヘルパースクリプト。プログレスバー用とラベル用で明るさのベース値を分けて提供
- **LOADING 状態の暗背景（DimBackground）**: ストアブラウズのタイル/バナー、カルーセルカードで読み込み中に暗い背景を表示し、NO IMAGE 状態と差別化

#### Changed

- **ストアブラウズのプログレスバー刷新**: 標準 `ProgressBar` から背景パネル＋フィルを分離したカスタム構成に変更。フィル側にシマーシェーダーを適用し、角丸を維持
- **LOADING ラベルのアニメーションをシェーダーに統合**: Tween ベースのブリージング（明滅）から、光の帯が横方向に流れるシマーエフェクトへ置き換え
- **LoadingLabel の構造変更**: 単純な Label から「暗背景 + Text」を内包する Control wrapper 構造に変更し、読み込み中の視認性を向上

### [Launcher v0.5.9] - 2026-04-14

#### Changed

- **ストアブラウズのUI構築を段階的に変更**: `_ready`での一括構築をやめ、`_process`で1フレーム1-2セクションずつ構築するローディングフェーズを導入（プログレスバー付き）
- **カルーセルのサムネイル読み込みを非同期化**: 同期的に全カードのサムネイルを読み込んでいた処理をバックグラウンドスレッドに移行し、LOADING→フェードインで表示

#### Fixed

- **画面遷移時のプチフリーズを解消**: スクリーンセーバー/ストアブラウズ/カルーセルのバックグラウンド画像読み込みスレッドにキャンセルフラグを追加し、シーン遷移時の`wait_to_finish()`ブロックを最小化
- **カルーセル画面でフォーカスがボタン等にあるときESCが効かない問題を修正**: 各フォーカスブロックに`ui_cancel`ハンドリングを追加

### [Launcher v0.5.8] - 2026-04-13

#### Added

- **TopBar / BottomBar コンポーネント分離**: TopBar（時計＋退出ボタン）とBottomBar（操作ヒント）を CanvasLayer ベースの独立 tscn に分離し、トランジション演出の影響を受けないよう改善
- **KeyHintBuilder**: BottomBar 用のキーキャップ風操作ヒントUI生成ヘルパーを追加
- **BrickMosaicBackground**: ゲーム背景画像をレンガ状に敷き詰め、行ごとに交互スクロールする背景コンポーネントを追加（バックグラウンドスレッド読み込み対応）
- **説明文スクロール対応**: ゲーム選択画面の説明文エリアをマウスホイール＆キーボードで滑らかにスクロール可能に
- **ゲーム情報パネルにアイコン表示**: プレイ人数・難易度・プレイ時間・コントローラー・オンラインの各スペックにアイコン画像（PNG）を追加

#### Changed

- **AutoScrollContainer の汎用化**: Label 専用だったスクロールコンテナを任意の Control 子ノードに対応
- **制作者表示をタグ形式に変更**: 単一ラベルから HBoxContainer ベースのタグ表示に変更
- **スペック表示のデザイン刷新**: ProgressBar を廃止し、アイコン＋バッジ形式のコンパクトな表示に変更
- **退出ボタン画像を exit.jpg → exit.png に差し替え**
- **FocusLayer導入**: フォーカス枠を CanvasLayer (layer=11) に移動し、TopBar より前面に確実に表示

### [Launcher v0.5.7] - 2026-04-01

#### Added

- **カルーセル上下操作用矢印ナビゲーション**: 選択中のゲームアイコンの上下に操作用の矢印ボタンを動的に配置。画面端での自動表示制御を実装
- **StoreBrowseスライドショー矢印の画像化**: 矢印をテキストから `arrow.png`（反転シェーダー付き）に変更し、デザイン性を向上

#### Changed

- **ゲーム起動時の演出改善**: フェードアウト時、BottomBarやカルーセルの矢印も一緒に同期して消えるように修正し、没入感を向上
- **スライドショーの操作レスポンス改善**: アニメーション中の再入力に対し、即座に連打した地点から次のスライドへ遷移するよう追従性を向上
- **ゲーム情報パネル（InfoPanel）の視覚効果**: エッジが背景に柔らかく溶け込むグラデーションぼかし（12px）と、角丸（32px）を適用

### [Launcher v0.5.6] - 2026-03-29

#### Changed

- **ダイアログ背景フェードアニメーション追加**: CommonDialog・ErrorDialog表示時のオーバーレイ（背景暗転）にフェードイン/フェードアウトアニメーションを追加
- **ゲーム起動エラーをErrorManager経由に変更**: 実行ファイル未検出(E-2002)・起動失敗(E-2001)をErrorDialog（エラーコード付き）で表示するよう変更
- **ErrorDialogから終了ボタンを削除**: エラー表示は情報提示のみとし、終了操作はAlt+F4（AppManager経由）に統一
- **ErrorDialog表示中のAlt+F4を即終了に変更**: エラーダイアログ表示中は確認ダイアログをスキップして即終了

### [Launcher v0.5.5] - 2026-03-29

#### Added

- **フルスクリーンをデフォルト化**: 起動時からフルスクリーンで表示
- **解像度スケーリング対応**: canvas_items stretchモードでFHD/WQHD等どの解像度でも同じUIレイアウトを維持
- **ダイアログのフォーカス枠をマウス操作時に非表示**: マウス/キーボード・コントローラーの入力切替を検知して表示制御

#### Changed

- **Godot Engine 4.5 → 4.6にアップデート**: project.godot、SPECIFICATION.md、README.md、AGENTS.mdのバージョン表記を更新

### [Launcher v0.5.4] - 2026-03-29

#### Fixed

- **戻る操作時のAppStateクリア順序を修正**: 遷移中の戻る操作を無視し、遷移受理後にAppStateをクリアするよう変更

### [Launcher v0.5.3] - 2026-03-29

#### Fixed

- **スライドショー1枚時の画面消失を修正**: ゲーム1枚以下のスライドショーで遷移アニメーションをスキップ

### [Launcher v0.5.2] - 2026-03-29

#### Fixed

- **最近プレイのソート不具合を修正**: `recently_played` クエリを `GROUP BY` + `MAX(start_time)` に変更し、ゲームごとの最新プレイ時刻で正しくソート
- **スライドショーアニメーションのロックをセクション単位に変更**: グローバルフラグからDictionaryに変更し、複数セクション間のブロッキングを解消
- **「すべて見る」ボタン不在時のフォーカス飛びを修正**: ボタンが存在するセクションでのみ `_on_view_all` を有効化

### [Launcher v0.5.1] - 2026-03-29

#### Fixed

- **ダイアログ連続表示時のポーズ解除バグを修正**: ダイアログ閉じアニメーション完了時に新しいダイアログが開かれていればポーズを維持するよう修正
- **StoreBrowseのmax_display_count未適用を修正**: セクションタイプ0（通常行）でManagerで設定した表示上限が反映されるよう修正

### [Launcher v0.5.0] - 2026-03-27

#### Added

- **StoreBrowse画面を新規導入**
  - `store_browse.tscn` / `store_browse.gd` / `store_browse_builder.gd` / `store_section_info.gd` を追加
  - `manual/popular/recent/recently_played/genre/players/difficulty/play_time/online/random/controller` セクションの表示に対応
- **画面遷移制御を追加**
  - `AppState` と `TransitionManager` をAutoLoad登録
  - `screensaver -> store_browse -> game_selection` の遷移フローと戻り導線を実装

#### Changed

- **UI/操作性を改善**
  - `game_selection` / `common_dialog` / `error_dialog` のフォーカス表示と遷移演出を調整
  - コントローラ操作時の視認性を改善
- **DBスキーマをv8へ更新**
  - `CURRENT_DB_VERSION` を8に更新
  - `store_sections` / `store_section_games` 取得APIを追加
- **アプリ名設定を更新**
  - `project.godot` の `config/name` をプロジェクト意図に合わせて変更

### [Launcher v0.4.6] - 2026-03-21

#### Changed

- **game_selection.gd を6つのコンポーネントに分割**
  - 1,257行のメインスクリプトを責務ごとに分離し、保守性を向上
  - `carousel_controller.gd`: カルーセルUIの座標計算・アニメーション
  - `input_handler.gd`: キーボード・コントローラー・マウス入力処理
  - `game_launcher.gd`: ゲーム起動・プロセス監視ロジック
  - `idle_manager.gd`: アイドル検知・スクリーンセーバー遷移
  - `game_info_display.gd`: ゲーム情報パネルの表示・更新
  - `button_style_manager.gd`: ボタンスタイル生成・グローアニメーション
  - メインの `game_selection.gd` はオーケストレーター（各コンポーネントの連携役）として残存

### [Launcher v0.4.5] - 2026-02-27

#### Added

- **ゲーム選択時の背景アニメーション改善**
  - ゲーム選択画面でスクロール操作に合わせて背景が上下にスライドする演出（`transition_up`, `transition_down`）を追加
  - スクロールを連続して行った場合（ドラムロール）でも、アニメーションが途切れずに次の位置から引き継がれてスムーズに繋がるように、内部制御を `AnimationPlayer` から `Tween` に移行

#### Changed

- **UIコンポーネントの tscn 化**
  - `CommonDialog`, `ErrorDialog` 内の UI 定義・スタイル割り当てをコードベースから `.tscn` ファイルの GUI エディタ設定へ統合
  - ダイアログボタンの動的サイズ調整やグローエフェクト、フォーカス時のスタイルを改善
- **スクリーンセーバーの機能改善**
  - `CenterContainer` を用いてロゴの配置とリサイズ制御を簡素化・安定化
  - 画面の「PRESS ENTER OR A BUTTON」の文字を「PRESS ANY KEY」に変更し、フォントサイズを拡大

### [Launcher v0.4.4] - 2026-02-14

#### Added

- **ゲーム選択画面のUI拡張**
  - 画面上部に現在時刻と「遊び終わる」ボタン（トップバー）を追加
  - 画面下部に操作ガイド（ボトムバー）を追加
  - 選択中のゲーム情報パネル内に「プレイ」ボタンを追加
  - サムネイル画像がない場合の「NO IMAGE」プレースホルダー表示を追加
  - マウスホイールによるスクロール操作に対応
- **UIエフェクトの追加**
  - フォーカスされたボタンやカード枠に対し、時間経過で明滅するブリージング（グロー）アニメーションを追加
- **共通ダイアログの機能拡張**
  - ダイアログボタン個別に色（緑のプレイボタンなど）を指定できるオーバーライド機能を追加

#### Changed

- **アイドルタイマーの仕様変更**
  - 警告ダイアログ表示までの時間を変更し、タイムアウト時にカウントダウンメッセージを更新するように修正

### [Launcher v0.4.3] - 2026-02-10

#### Added

- **「ゲーム登録なし」エラー(E-1006)の追加**
  - データベースは存在するがゲームが1件も登録されていない場合に特定のエラーコードを表示するように改善

#### Fixed

- **エラーダイアログの視認性改善**
  - `ErrorManager` と `DialogManager` を `CanvasLayer` に移行
  - 実行環境（ビルド後）において、背景の描画順序によりエラーダイアログが隠れてしまう問題を修正

### [Launcher v0.4.2] - 2026-02-10

#### Fixed

- **データベース読み込みの安定性向上**
  - データベースのカラムが`NULL`の場合にクラッシュする問題を修正（`_safe_int`, `_safe_bool`の導入）

### [Launcher v0.4.1] - 2026-02-09

#### Fixed

- **データベース読み込みの安定性向上**
  - データベースの整数・ブール型カラムにNULLが含まれていた場合にクラッシュする問題を修正
  - すべての必須フィールドに対してNULLチェックとデフォルト値を適用
- **起動オプション（Arguments）の読み込み修正**
  - データベースの `arguments` カラムが読み込まれていなかった問題を修正
  - 管理ソフトで設定した起動引数が正しく反映されるように改善
- **データベースカラム読み込みエラーの修正** (`e-1003`)
  - 新しく追加された `supported_connection` カラムの読み込みに対応
  - マネージャーによるデータベースマイグレーション後に正しく動作するように調整

### [Launcher v0.4.0] - 2026-02-08

#### Added

- **データベースバージョニング機能**
  - `DatabaseManager`クラスに`_check_and_migrate_db`メソッドを追加
  - スキーマバージョン管理用の`CURRENT_DB_VERSION`定数を導入
  - 古いデータベース（v0）から最新版（v1）への自動マイグレーション機能
- **ゲーム選択画面（Game Selection Screen）**
  - カルーセルUIによるゲーム選択機能
  - ゲーム情報の詳細表示（タイトル、サムネイル、説明など）
  - キーボード/コントローラーでの操作サポート
- **共通ダイアログシステム（Common Dialog System）**
  - `DialogManager`による統一されたダイアログ管理
  - 確認ダイアログ、情報ダイアログ、エラーダイアログのサポート
  - 最前面表示とフォーカス管理
- **エラーハンドリングシステム**
  - `ErrorManager`によるエラーコード（E-xxxx）管理
  - ユーザーフレンドリーなエラーメッセージ表示
  - `E-0001`（DB接続エラー）などの定義
- **管理者用終了確認機能（Global Exit Confirmation）**
  - `AppManager`による終了リクエスト（Alt+F4等）のフック
  - 誤操作防止のための確認ダイアログ表示
- **アイドルタイマー機能**
  - 実装: 30秒放置で警告、60秒でスクリーンセーバーへ自動遷移
- バージョン情報を`version.gd`のみで一元管理するように変更

### [Launcher v0.3.1] - 2025-12-27

#### Fixed

- データベースから取得したnull値の処理を修正
  - すべての文字列型プロパティ（game_id, title, description, genre, thumbnail_path, background_path, executable_path, controls, key_mapping）にnullチェックを追加
  - データベースのNULL値が原因で発生していたエラーを解消
- SQLite APIの互換性問題を修正
  - `query_with_args()`が存在しないため、`query()`メソッドを使用するように変更
  - SQLインジェクション対策として`_escape_sql_string()`関数を追加

### [Launcher v0.3.0] - 2025-12-27

マイルストーン4: データベース連携

#### Added

- データベース接続管理クラス（DatabaseManager）の実装
  - SQLiteデータベースへの接続機能
  - ゲーム情報の取得機能（get_all_games, get_game_by_id）
  - 製作者情報の取得機能（get_developers_by_game_id）
- データモデルクラスの実装
  - GameInfoクラス（ゲーム情報を表すデータモデル）
  - DeveloperInfoクラス（製作者情報を表すデータモデル）
- パス管理クラス（PathManager）の実装
  - プロジェクトルートの自動検出
  - データベースパス、ゲームフォルダパスの取得
- ゲーム選択画面でのデータベース連携
  - データベースからゲーム情報を読み込んで表示

#### Technical

- godot-sqliteプラグインを使用したSQLiteデータベース接続
- データアクセス層の実装（CRUD操作の読み取り部分）
- パス管理の統一（管理ソフトと同様のロジック）

### [Launcher v0.2.0] - 2025-12-26

マイルストーン3: 基本画面・画面遷移

#### Added

- スクリーンセーバー画面の実装
  - ロゴ画像（GCToneLogo.png）の表示
  - レスポンシブレイアウト（解像度・アスペクト比に応じた動的サイズ調整）
  - スタートメッセージの表示
- 画面遷移の基本実装
  - スクリーンセーバー → ゲーム選択画面への遷移（EnterキーまたはAボタン）
  - ゲーム選択画面 → スクリーンセーバーへの遷移（ESCキー）
- ゲーム選択画面のテスト実装（将来実装予定のプレースホルダー）
- Noto Sans JPフォントの導入（Regular/Bold）

#### Changed

- 背景色を統一（Color(0.1, 0.1, 0.1, 1)）

#### Technical

- Godot 4.5のシーン管理システムを使用
- 基本的なUIノードの配置（Control, ColorRect, VBoxContainer, Label, TextureRect）
- ビューポートサイズ変更時の動的レイアウト更新

### [Launcher v0.1.0] - 2025-12-26

マイルストーン1: Godotプロジェクトセットアップ完了

#### Added

- Godot 4.5プロジェクトのセットアップ
- SQLiteプラグイン（godot-sqlite）の導入
- プロジェクト構造の確立（scenes/, fonts/, images/フォルダなど）
- データベース接続確認機能

#### Technical

- Godot Engine 4.5のセットアップ
- GDExtension（godot-sqlite）の導入と動作確認
- SQLiteデータベース（prism.db）への接続確認
- データベース接続テストスクリプトの実装

### Launcher 将来のリリース予定

#### Launcher 開発版（v0.x.x）

- **v0.1.0** (マイルストーン1): Godotプロジェクトセットアップ完了
- **v0.2.0** (マイルストーン3): 基本画面・画面遷移
- **v0.4.0** (マイルストーン4, 5, 6): データベース連携・ゲーム表示・起動機能
- **v0.5.0** (マイルストーン7): UI完成・ゲーム情報詳細表示

#### Launcher 正式リリース版（v1.0.0以降）

- **v1.0.0** (マイルストーン8): MVP完成
- **v1.1.0** (マイルストーン9): 基本機能完成
- **v1.2.0** (マイルストーン10): データ管理機能完成
- **v2.0.0** (マイルストーン12): 完全版リリース

---

## Manager（管理ソフト）

### [Manager v0.34.1] - 2026-09-04

#### Fixed — アップデートに失敗しても「✓ アップデート完了」と表示していた（`fix/updater-64bit`、#440）

- **アップデートが失敗しても、再起動後に「✓ アップデート完了 / 新しい管理ソフトが起動しています」と表示されていた**のを修正しました。実際には置換に失敗した**古い Manager** がそう言っている状態で、失敗に気付けるのは「アップデート」タブを開いて「前回のアップデート結果: 内部エラー」を読んだときだけでした。**この誤表示のせいで、更新失敗が v0.10.0 / v0.11.0 の 2 リリース分見過ごされました。**
- **原因**: 完了 sentinel（`.update_completed`）は **Updater の spawn 成功後**に書かれるだけで、spawn した Updater が**その後で**失敗するケース（＝ Manager dir の置換失敗、#440）を見ていませんでした。起動側もその sentinel を**何も検証せずに**成功 dialog へ流していました。
- **対処**: sentinel に「**これから入るはずの Manager の版数**」を書き足し、再起動した Manager が**自分の assembly 版数と突き合わせて**から表示を決めるようにしました。一致しなければ、原因が何であれ置換は完了していないので「✗ アップデート未完了」を出し、実際の版数・Updater が残した終了コード由来の原因・復旧手順（もう一度試す / それでも駄目なら開発者へ連絡）を提示します。**「成功したと言う前に、本当に成功したかを確かめる」**という形にしました。
- 旧 sentinel（版数を持たない）は検証を skip して従来どおり完了 dialog を出します（後方互換）。**したがって、この検証機構が効き始めるのは v0.11.1 *から* の更新です** — v0.11.0 → v0.11.1 の更新を実行するのは修正前の Manager なので、その成否は検証されません（構造上避けられません）。**この 1 回だけは、更新後に版数タブを目視することが唯一の安全網です。**
- **Updater が実行結果を `<install>/.update_result` に書き残すようにしました（判定をログ解析から卒業）**。Manager は Updater の**プロセス終了コードを受け取れません**（受け取るには待つ必要があり、待っていると dir を置換できない）。そのため従来は「Updater ログの末尾 20 行に `[ERROR]` があれば失敗」という推測をしていました。これには 3 つ問題がありました — (1) **ログは人間向けの副産物であって API ではなく**、文言を変えた人が判定を壊せる、(2) 致命的でない `Logger.Error`（`.bak` の削除失敗など、処理は継続する）で失敗に倒れる、(3)「どの実行の話か」が分からないので「直近 2 分」という窓が要り、**失敗の翌朝に起動すると読めない**。答えは Updater が持っている（終了コード）のだから、解析で復元せず消えない場所に書いてもらう形にしました。ログは人間のために残し、判定だけをそこから剥がしています。
- **成否はファイルに持たせず `exitCode == 0` から導出します**。同じ事実の出所が 2 つあると食い違ったときどちらが正か決まりませんし、`bool` は「欠けている」と「false」を区別できないため、欠落したファイルを失敗と読んで**偽の「✗ 未完了」**を出しかねません。終了コードは `int?` で受け、**null = 不明**として判定材料から外します。
- **書き出せない経路は 3 つだけ**です（`--help` / 引数 parse 失敗 / parse 中の例外）。いずれも `--manager-target` が読めておらず書き込み先が決まらないためで、この 3 つでは Manager dir が一切触られていないので**版数比較の側が失敗を捉えます**（原因欄が「原因不明」になるだけ）。`Logger.Initialize` の失敗も取りこぼさないよう `try` の内側に移しました。
- **`.update_result` は成功なら読んだ時点で消し、失敗のときだけ残します**（＝**平常時は存在しません**）。成功はもう覚えておく必要がありませんが、失敗は「アップデートタブの再試行ボタンを有効に戻す」ために後で（別セッションでも）参照する必要があるためです。残った失敗の記録は、**実行中の Manager が記録された目標版数に達していれば自動的に失効**します（手動で `Install.bat` を実行して直した場合も勝手に解消する＝時間ではなく事実で失効させる）。次の更新試行でも上書きされるので、いずれにせよ溜まりません。
- **成否の判定は「版数の不一致」と「Updater の終了コード」の OR** にしました。版数比較だけだと、Manager の版数が変わらない Bundle リリース（Launcher だけ上げた等）で置換に失敗しても `expected == running` になって成功扱いになります。「一致しなければ失敗」は正しいのですが、その逆（一致すれば成功）は成り立ちません。版数の比較は **3-part** で行います（`running` は AssemblyVersion、`expected` は apphost の FileVersion と **SoT が違い**、リリースゲートも 3-part までしか一致を強制していないため。4-part で比べると revision だけ drift した場合に全ユーザーが偽の「✗ 未完了」を食らいます）。
- **失敗ダイアログの版数行は不一致のときだけ出します**。終了コードだけで失敗した経路では両者が同値になり、「v0.34.1.0 / 本来は v0.34.1.0」という不可解な表示になるためです。
- **リリース時に Updater の bitness を機械強制するようにしました**（`Release.ps1` の `Assert-UpdaterBitness`）。csproj に `Prefer32Bit=false` があっても、Visual Studio が per-configuration の PropertyGroup に `true` を書き戻すと**後勝ちで無言に revert**します。SPEC に「必須」と書くだけでは守られない（実際 2 リリース気付かれなかった）ので、他の版数 stamp 系と同じく公開前に hard fail させます。判定は PE ヘッダの machine ではできない（AnyCPU は常に I386/PE32）ため `Assembly.GetPEKind` の COR フラグを見ます。
- **`docs/usage/manager.md` のアップデート手順も更新**しました。「✓ アップデート完了 のお知らせが出ます」と 1 種類しか書いていなかったところに、「✗ アップデート未完了」とその場合の動線（もう一度試す → 駄目なら開発者へ）を追記しています。
- **再起動予告のダイアログも「完了のお知らせが表示されます」と約束しないようにしました**。そこで完了しているのはダウンロードと展開までで、Manager の置換はその後に Updater がやります。約束すると「**引き渡した時点を完了と呼ぶ**」という今回の間違いを別の場所でもう一度することになるため、「アップデートの結果をお知らせします」に改めました。なお他の成功メッセージ（バックアップ / 復元 / DB リセット）は結果オブジェクトの成否を見てから出しており、同種の問題はありません（確認済み）。
- **失敗後に「今すぐアップデート」が押せなくなる問題も同時に修正**しました。現在の Bundle 版数は `CHANGELOG.md` から読みますが、その CHANGELOG は Updater の spawn 成功後に置換されるため、置換に失敗すると **CHANGELOG だけ新しくなって「最新版を実行中」＝ボタン無効**になり、**UI から再試行する手段が無くなります**（実際に v0.10.0 / v0.11.0 でこの状態になりました）。Updater の終了コードは失敗を正しく記録しているので、それを見て判定を覆し、「前回のアップデートが完了していません。もう一度お試しください。」と表示してボタンを有効に戻します。既に最新なら再適用しても同じ内容が入るだけなので、再試行を許す方が安全側です。
- **失敗ダイアログの案内は「開発者に連絡」に統一**しました。当初は zip を展開して `Install.bat` を実行するよう案内していましたが、部員に手動の入れ直しを求めるのは無理があります。あわせて `docs/usage/troubleshooting.md` に残っていた「部の担当（開発した先輩・先生）」も **「開発者」** に揃えました（`UpdaterClient` の rollback 失敗メッセージとサービスモードの診断画面は元から「開発者に連絡」で、docs だけ表現が割れていました）。
- bump 判断: bugfix のみ。**patch（v0.34.0 → v0.34.1）**。Updater v0.2.2 と同 PR。

### [Manager v0.34.0] - 2026-09-03

#### Added — 設定にアンケートの表示切り替えを追加（`feature/launcher-survey-ui`、#297 PR3 / #35）

- **設定ページに「アンケート」セクションを追加**。「ゲーム終了時のアンケート」と「退出時のアンケート」を**個別に**オン／オフできる（既定はどちらも ON）。
- **なぜ 2 つに分けたか**: ゲーム終了時は**毎ゲーム = 高頻度**、退出時は退出のたび 1 回 = 低頻度で、来場者にかかる摩擦の質が違う。混雑時に「高頻度な方だけ切って回転を落とさない」ができる方が実用的で、実装コストは 1 トグルとほぼ変わらない。
- **切り替えは稼働中の Launcher に即座に効く**（再起動不要）。Launcher 側がアンケートを出す直前に毎回読む設計にしたため。設定画面にもその旨を明記した。
- **既定は ON**: 新規インストールで何もしなくても収集が始まる。文化祭は 1 日勝負で、設定し忘れて 1 件も取れない方が損失が大きいため、既定 OFF ではなく「要らないときに切る」形にした。
- **注記は見出しの直後・スイッチより前**に置いた: 「切り替えるとすぐ反映されます／回答は自動で保存されます／集めた回答を見る画面は準備中です」は 2 つのトグル**両方**に掛かる話。カード（`Border`）の中に置くと直前の項目（退出時のアンケート）だけへの補足に見えてしまい、カードの下に置くと**切り替えた後で初めて挙動を知る**ことになる。「見出し → 何が起きるか → 操作」の順に読ませる。文言も当初「回答はランチャー側に保存されます」としていたが、これは実装の都合（DB ではなくファイルに保存する）をそのまま書いたもので部員の行動につながらないため、「**保存操作は不要**」と「**結果を見る画面はまだ無い**」が伝わる書き方に改めた（集計画面を探して見つからず『壊れている？』となるのを防ぐ）。
- 保存は自動バックアップのトグルと同じ即時保存パターン（`SettingsKeys.SurveyGameEndEnabled` / `SurveyLauncherEndEnabled` に `"true"/"false"` で書く）。他 PC との競合チェック（`AllowWrite`）も同様に通す。
- **docs 更新**: `docs/usage/manager.md` に「設定 ＞ アンケート」節を追加（2 つの違い・混雑時の運用・戻し忘れ注意）。`docs/operations/overview.md` の当日運用にも導線を追加。あわせて、**設定画面の説明が古かったのを修正**（「『適用』で確定／『元に戻す』で取り消し」と書かれていたが、WPF 化（#362）で**変更するとその場で保存される**挙動に変わっていた）。
- bump 判断: 機能追加（破壊的変更・DB スキーマ変更なし。`settings` への新規 key 追加は migration 不要）。**minor（v0.33.0 → v0.34.0）**。Launcher v0.13.0 と同 PR。

### [Manager v0.33.0] - 2026-09-03

#### Added — `games.game_no`（プレイ記録・アンケート JSON 用の不変キー）を追加（`feature/game-no-key`、#297 PR2 / #34 / #35）

- **DB スキーマ v23 → v24**: `games` に **`game_no INTEGER`**（+ UNIQUE INDEX `idx_games_game_no`）を追加。ゲームに一度だけ振られる**不変の内部番号**で、プレイ記録・アンケートの JSON（`responses/`）がゲームを指す唯一のキーになる。
- **なぜ必要か**: #297 でプレイ記録・アンケートは SQLite を離れ JSON になった。DB の FK は ID 改名に追随できるが **JSON にその仕組みは無い**ため、`game_id`（スタッフが手入力する文字列・`games/<game_id>/` のフォルダ名兼用・**改名可**）を JSON に書くと、ゲーム ID を改名した瞬間に過去の全記録がどのゲームのものか分からなくなる。記録がまだゼロの今のうちにキーを確定させるのが最安。
- **主キーは差し替えない**: 当初案（`game_id` を `slug` に降格し整数 `id` を主キーにする）は、子テーブル 3 つ（`game_versions` / `developers` / `store_section_games`）の FK 貼り替えと `game_id` / `GameId` 365 箇所の語彙変更を伴い、本番稼働 DB への主キー手術になる。JSON を腐らせないために必要なのは「不変の整数キー」だけなので、**列を 1 本増やすだけ**に留めた（`ALTER TABLE ADD COLUMN` + backfill + INDEX のみ、テーブル recreate なし）。既存コードへの影響はゼロで、「ゲームID」という部員向けの語彙・UI・docs も一切変わらない。
- **採番と番号の再利用防止**: `MigrateV23ToV24` が既存行へ `game_id` 昇順で backfill し（開始値は下記 3 情報源の最大値の次。記録が 1 件も無い通常の移行では 1 から）、以降は `GameRepository.AddGameRowInTransaction` が games の INSERT と同一トランザクションで払い出す。払い出す値は **(a) `responses/` の記録ファイル名から読んだ最大 `game_no` / (b) `settings.game_no_seq` / (c) `MAX(games.game_no)` の最大値 + 1**。
- **なぜ 3 つ見るのか**: それぞれ埋められない穴があり、しかも**穴が重なっていない**ため。(c) は最大番号のゲームを削除すると下がる。(b) はバックアップ復元・DB リセットで巻き戻る（settings は DB の中なので DB と運命を共にする）。(a) は DB の外にあるので両方を越えて生き残るが、SMB 断や誤削除で読めなくなりうる。**「実際に記録が参照している番号」が真値**という発想で (a) を主情報源に据え、(b)(c) をその補完に置いた。これにより「復元後に追加したゲームが、削除済みゲームの過去の記録を引き継ぐ」という**静かなデータ破損**（JSON は番号しか持たないので誰も気づけない）を構造的に防ぐ。塞げないのは「(a) が読めない」かつ「DB を古い状態に復元した」の二重障害のみで、その場合は警告ログを残す。
- **走査コスト**: 記録のファイル名が `<unix_ts>-<game_no>-<uuid>.json` なので、**ディレクトリ一覧を取るだけで済み 1 ファイルも開かない**。本番は SMB 共有で「ファイルを開く回数 = ネットワーク往復回数」になるため、この差は大きい（ローカル実測で 3,000 件・全件パース 220ms に対し一覧のみ 13ms）。走査失敗時もゲーム追加はブロックせず警告に留める（会期中に SMB が一時的に不調というだけでスタッフの作業を止める方が実害が大きい）。
- **走査は書き込みトランザクションの外で行う**: 一覧だけとはいえ SMB 越しの全走査は件数に比例して伸びうる。これを games の INSERT と同じトランザクションの中で行うと、その間 SQLite の書き込みロックを握り続け、**他のキオスク / Manager の書き込みまで巻き添えで待たせる**（ゲーム 1 本の追加が全台に波及する）。走査結果は `AllocateNextGameNo` の引数として渡す形にし、「外で済ませてから開く」という前提をシグネチャに固定した。migration だけは例外で、起動時に 1 度きり・DB を排他で握る局面なので待たせる相手がいない。
- 記録ファイル名のパーサの docstring を実装に合わせた（レビュー Low）: 旧形式を弾いているのは「uuid が 16 進なので数値解析に失敗する」からではなく、**ハイフン区切りの個数判定**（uuid はハイフンを含まない 32 桁の 16 進なので旧形式は必ず 2 個）。次の読み手が `TryParse` 側を load-bearing だと誤解しないようにした。
- **v0 fast-path（版数管理前の古い DB）の回帰テストに `game_no` の検証を追加**（レビュー指摘）: v0 経路は migration chain を通らず版数を直接 stamp するため、各 migration を明示適用しないと「中身は古いのに最新を名乗る」穴が空く。ところが既存テストは `GetTargetDatabaseVersion()` との一致しか見ておらず、**v24 でも緑のまま通ってしまう**状態だった。列の存在・backfill 済み（NULL / 0 が無い）・high-water mark の一致まで固定し、テスト名も版数固定 (`ReachesV23`) をやめた。
- **`responses/` のパスをもう 1 箇所 SoT に寄せた**（レビュー指摘）: 「2 箇所のハードコードを `PathManager.ResponsesFolder` に置き換えた」と書きながら、`LauncherLogsRootBridge` の 1 箇所が残っていた。
- **記録フォルダの走査に時間予算（1.5 秒）を設けた**（レビュー指摘）: この走査は**ゲーム追加のたびに UI スレッドで同期実行**され、本番の SMB 共有では件数に比例して秒単位になりうる。「ゲーム追加でフリーズ」は既に高優先の別 issue（#292）になっている経路なので、そこへ新しい原因を足すわけにいかない。**途中で打ち切っても壊れない**のがこの設計の要点で、求めているのは番号の**下限**＝打ち切った結果も正しい下限。通常運用では `settings.game_no_seq` が同じ値以上を持つので実質的な精度低下も無い。打ち切ったときは警告を残す（SPEC §7.5.3 が「(a) が読めなければ警告を残す」と定める経路）。
- **v0 fast-path（版数管理前の古い DB）の回帰テストに `game_no` の検証を追加**（レビュー指摘）: v0 経路は migration chain を通らず版数を直接 stamp するため、各 migration を明示適用しないと「中身は古いのに最新を名乗る」穴が空く。ところが既存テストは `GetTargetDatabaseVersion()` との一致しか見ておらず、**v24 でも緑のまま通ってしまう**状態だった。列の存在・backfill 済み（NULL / 0 が無い）・high-water mark の一致まで固定し、テスト名も版数固定 (`ReachesV23`) をやめた。
- **`responses/` のパスをもう 1 箇所 SoT に寄せた**（レビュー指摘）: 「2 箇所のハードコードを `PathManager.ResponsesFolder` に置き換えた」と書きながら、`LauncherLogsRootBridge` の 1 箇所が残っていた。
- **走査を外で済ませる契約は、migration だけが例外**であることを docstring に内包させた（レビュー Low-2）。「必ず transaction の外で」と無条件に書いていたが `MigrateV23ToV24` は内側で評価しており、契約と実装が食い違ったままだと「migration と同じ書き方でいい」と別経路にコピーされて元の事故が再発する。
- **`PathManager` に `ResponsesFolder` / `PlayRecordsFolder` / `SurveysFolder` を追加**: 従来 `"responses"` は 2 箇所でハードコードされていた。走査でこのパスを使うため、Launcher 側の `path_manager.gd` と対になる SoT としてアクセサ化した。
- **不変性の担保**: `game_no` を書く経路は games の INSERT **のみ**。UPDATE 経路（`UpdateGameRowInTransaction`）は本列に一切触れないため、ゲーム内容の更新でも版の差し替えでも番号は動かない（回帰テスト `GameNo_SurvivesGameUpdate` で固定）。
- **露出方針**: GUI には出さない（部員が触るのは今までどおり「ゲームID」）。ログに出すのは `game_no` を実際に使う処理（JSON 書込・集計）に限り、`game_id (no.12)` の形で併記する（JSON は番号しか持たないため、障害調査でログだけから記録とゲームを突き合わせられるようにする）。詳細は SPEC §7.5.3「game_no の設計」。
- **`CreateTables` の INDEX 作成ガード**: `CreateTables` は migration より**前**に毎回走るため、v23 以前の DB では `game_no` 列が無い状態で UNIQUE INDEX 作成に到達する。列の存在を確認してから張るようにし、無ければ後続の `MigrateV23ToV24` に委ねる（無ガードだと "no such column: game_no" で起動が落ちる）。
- **テスト基盤**: 採番が `PathManager` 経由で `responses/` を走査するようになったため、`SchemaMigrationTests` も静的 base dir seam を使う側になった。`[Collection("PathManagerStatic")]` に追加して直列化し（未追加だと #409 と同じ並列競合で flaky 化する）、各テストが一時 install dir を向くようにして実 install の記録を読まない・汚さないようにした。
- **検証**: 単体テスト 289/289 緑（新規 7 件 = backfill / 再実行で振り直さない / 削除後の番号非再利用 / 更新で不変 / 記録が参照する番号を再利用しない / `.tmp`・旧形式・`0` に惑わされない / 記録フォルダ不在でも動く）。加えて**本番 DB のコピー**に対する実データ round-trip を実施し、27 ゲームへ 1〜27 が採番・`game_no_seq=27`・`integrity_check ok`・`foreign_key_check` 違反ゼロ・全子テーブルの行数不変・v24 到達を確認（SPEC §7.6 のワークフロー準拠、作業 DB は未変更）。
- bump 判断: 機能追加 + DB スキーマ変更（既存データは非破壊・列追加のみ）。**minor（v0.32.0 → v0.33.0）**。Launcher v0.11.9 と同 PR。

### [Manager v0.32.0] - 2026-06-30

#### Added / Changed — ゲーム画像を `.toneprism/` 予約名前空間へ取り込む共有基盤 + EDIT の外部画像取り込み解禁（`feature/manager-image-toneprism`、#386）

- **画像取り込み共有ヘルパー `GameImageAssetHelper` を新設**（#386）: ゲームのサムネ/背景画像を版フォルダ配下の予約名前空間 `<version>/.toneprism/thumbnail.<ext>` / `background.<ext>` へコピー取り込みする。**役割正規化**（元ファイル名でなく役割固定名）・**copy-not-move**（元画像は残す）・予約名前空間で game 本体ファイルと物理分離（役割名の clobber 防止）。guide の `IntroGuideAssetHelper` と同流儀。ADD/EDIT WPF で**共用する想定**の共有基盤だが、本 PR の配線は **EDIT のみ**（ADD は WinForms のままで #324 follow-up）。Launcher 読み出しは相対サブフォルダ解決のため変更不要。
- **ゲーム編集（EDIT）で外部画像の取り込みを解禁**（#386）: 旧実装は「ゲームフォルダ外の画像はブロック（フォルダ内に置いてから選び直して）」だったのを、保存時に `.toneprism/` へ自動取り込みするように置換。取り込みロジックは VM 非依存の共有 service `GameImageSaveImporter` として抽出（ADD/EDIT 共通の保存ロジック共有化＝#242 の起点）。`CommitToVersion` は外部画像パスを **null 化せず絶対のまま保持**し（`ToRelOrKeepExternal`）、保存時に **全版**を走査して外部画像を `.toneprism/` へ取り込む。これにより「版 A に外部画像 → 版 B に切替 → 保存」で **A の指定が silent に消えない**（レビュー指摘1。旧 selected-only 取り込みでは版切替の `ToRel` が非選択版の外部パスを null 化していた）。`.toneprism/` は版 leaf 直下なので既存の版 rename の prefix 書換（`VersionFolderRenameService.ReplaceVersionPrefix`）とも整合（gameId/版 rename にも追従）。取り込みは保存末尾（rename 直前）で実行し、未変更の内部画像は素通り。**保存 abort 時に取り込みファイルは削除しない**（削除すると非選択版の in-memory 相対パスが dangling になり、ロック解除等での retry で欠落ファイルを指す相対パスが保存成功してしまう＝silent loss。ファイルを残せば retry がその実体を解決して正常保存できる。放棄時の `.toneprism` 内 orphan は役割固定名の無害な dead bytes＝#348 地続き。レビュー指摘1 round2）。あわせて **rename 前に全版の実行ファイルが内部（非 null）かを検証**（非選択版に外部 exe が残ると rename 後に NOT NULL 違反で落ちるのを先回りで弾く。レビュー指摘2）。**EDIT の外部画像取り込みを footgun 無しで実現**（外部画像を naive に扱うと絶対パスが DB に残り他 PC / ファイルサーバで壊れるが、必ず版フォルダ内へコピーして相対保存することで回避。※現行 `AddGameForm` / pre-#386 EDIT は外部画像を `IsPathInside` で検証ブロックしていた＝絶対保存はしないが外部取り込みも不可だった。本 PR は EDIT でその取り込みを安全に解禁）。唯一 snapshot 欠落版の skip 経路だけは絶対パスが残りうるが、現状 add-version UI が無く到達不能（将来 UI 追加時はブロック方向へ）。取り込み対象の外部画像は保存前に全版で拡張子・存在を検証してブロック（round4）。abort 時に既存の同名役割ファイルを上書き済みの場合の整合（DB は旧・実体は新）は暫定でダイアログ注記、恒久 staging 化は #417。exe の外部取り込みは本 PR 対象外（画像のみ）。
- **`.toneprism` 内の未参照役割ファイルを掃除**（拡張子変更後の旧 `thumbnail.png` 等が主目的だが、範囲は「未参照の役割ファイル全般」）: **すべての成功保存後**に `CleanupStaleRoleFiles` で、各版の `.toneprism` から**どの版も参照しない** `thumbnail.*` / `background.*` を削除する（best-effort）。削除は不可逆なので、全版の thumbnail/background を集めて**ファイル名でなく完全な相対パスで照合**し、版跨ぎ参照や legacy 直下配置があっても live を消さない。取り込み時（保存確定前）に消すと abort で旧画像消失＋DB dangling になるため、必ず成功後に掃除する（#417 と同根）。guide 側の同種 orphan は #348。
- **test infra**: `PathManager.SetBaseDirectoryForTest`（静的 `_baseDirectory` 差し替え）を使う test class を `[Collection("PathManagerStatic")]` で直列化し、並列実行の base dir クロバー race を解消（新テスト追加で顕在化、既存の潜在 flaky も同時に解消）。
- bump 判断: 新機能（画像取り込み基盤 + EDIT 外部画像解禁。破壊的変更 / DB スキーマ変更なし）。**minor（v0.31.1 → v0.32.0）**。Launcher 変更なし。**本番の画像書き込み凍結が完全に解けるのは ADD（#324）も対応した Bundle リリース時**。

### [Manager v0.31.1] - 2026-06-29

#### Fixed / Changed — ゲーム編集の未保存離脱ガード + 確認ダイアログのモダン化（`fix/manager-edit-unsaved-guard`、#383）

- **未保存のまま離脱時の破棄ガード**（#383）: WPF サブページ化（v0.31.0）で編集中もサイドバーが活性になり、誤クリックで未保存入力が無確認破棄される退行を解消。シェルの `NavigationView.Navigating` を割り込み、未保存があれば確認ダイアログを出して遷移を保留する（サイドバー・戻る等のナビゲーション離脱で共通。ウィンドウ自体を閉じる経路 `×`/Alt+F4 は本 PR では未ガード＝follow-up）。`e.Cancel` で同期的に遷移を止めてから非同期ダイアログ → **保存 / 破棄して移動 / 編集に戻る** の3択。当初の「編集中サイドバーをグレーアウトする擬似モーダル」案から、**サイドバーは押せるまま割り込む**方式に変更（より自然）。
- **未保存判定は load 時スナップショット比較**: フィールド単位の dirty フラグだと「変更 → 元に戻す」で誤検知するため、保存対象の全状態（ゲーム項目 + 全版 + 選択版 + 製作者）を canonical 文字列化して load 時と比較。trim / 人数コアース / Grade 整形等の正規化も両側で効くため、保存しても実質変わらない編集は未保存扱いにしない。保存成功時は基準を更新（`MarkSaved`）。
- **確認ダイアログを Fluent 化**: 旧 WinForms `MessageBox`（OS ネイティブの古い見た目）→ WPF-UI `MessageBox`（ダーク・モダン、Primary/Secondary/Close の3ボタン）。シェルと一貫した見た目に。
- **組み込み戻るボタンを全廃**（`IsBackButtonVisible="Collapsed"`）: `Navigate` でバックスタックを作るサブページは編集画面だけで、それは自前の戻るボタンを持つ。既定 Auto だと dirty チェックを迂回する2個目の戻るが出ていたため除去（サブページは各自の戻るボタンを持つ規約）。
- **保存成功トーストを Popup 化**（レビュー派生）: WinForms ホスト画面（ストア/初回説明/バックアップ/ログ/アップデート＝`WindowsFormsHost`）の上にも出るように。Grid 内 Border だと airspace で裏に隠れ、指摘2 で保存後にホスト画面へ着地できるようになると保存フィードバックが見えなくなるため、別 HWND の Popup（右下配置 `CustomPopupPlacementCallback`）に移した。見た目/寸法は従来のまま。各画面の WPF 化後も有効。
- **確認ダイアログはモーダル**（レビュー指摘1）: WPF-UI `MessageBox.ShowDialogAsync()` は既定で `base.ShowDialog`＝モーダル（表示中は主窓を無効化。逆コンパイルで確認、`Show`/`ShowDialog` は例外を投げ ShowDialogAsync 一択の設計）。よってダイアログ中の再入（別項目クリック）は起きず、`Owner`/`WindowStartupLocation=CenterOwner` もこの前提で正しく機能する。
- **未保存判定の署名を衝突耐性化**（レビュー指摘5）: 状態の canonical 文字列化を長さプレフィックス符号化に変更。Title/説明/ジャンル名/製作者名などの自由入力に区切り文字（`|` `:` 改行等）が含まれても、異なる状態が同一署名へ潰れない（= false-negative で未保存を無確認破棄する事故を構造的に防止）。回帰テスト 4 件を追加（`EditViewModelDirtyTests`）。
- **`HasUnsavedChanges` の副作用を明文化**（レビュー指摘7）: 署名計算が表示中版へ in-memory commit する意図的な副作用（署名 ＝「いま保存したら DB に乗る内容」の対称性を保つため）・離脱直前専用・冪等であることを doc コメントで明示。新たな呼び出し元を足す際は非破壊化を検討する旨を注記。
- **離脱処理の silent failure 防止**（レビュー指摘2/3）: `Navigating` 割り込みの離脱処理（`HandleGuardedExitAsync`）は fire-and-forget 起動のため、ダイアログ/遷移で例外が出ると unobserved task として消えユーザーが無言で取り残される。全体を try/catch で包み `Logger.Error` に残す（失敗時は編集画面に留まる＝安全側）。前進遷移で離脱先の型が解決できない場合も `Logger.Warn` でログ化し silent no-op を排除。
- **確認ダイアログを主窓に紐付け**（レビュー指摘5）: 確認ダイアログに `Owner` + `WindowStartupLocation=CenterOwner` を設定。z-order・最小化連動・主窓中央表示を担保（マルチモニタ/最小化での迷子を防止）。
- **離脱判定・保存後遷移の堅牢化**（追加レビュー）: (1) `Navigating` 内の未保存判定（`HasUnsavedChanges`）を try/catch し、失敗時は安全側＝未保存ありとみなして確認ダイアログを出す（判定例外で遷移が素通りし無確認破棄するのを防止）。(2) ガード経由保存の**成功後**に画面遷移が失敗した場合、「更新に失敗しました」と誤表示せずログのみにし保存成功トーストは出す（保存済をユーザーに正しく伝える）。
- bump 判断: v0.31.0 編集フォームの退行修正 + UX 改善 + レビュー対応（破壊的変更 / DB スキーマ変更なし）。**patch（v0.31.0 → v0.31.1）**。Launcher 変更なし。

### [Manager v0.31.0] - 2026-06-18

#### Added / Changed — ゲーム「編集」の WPF ネイティブ化（`feature/manager-game-edit-wpf`、#324 PR1 / #242）

- **ゲーム編集を WinForms モーダル `EditGameForm` → WPF サブページ `EditGamePage`** に（一覧の「編集」が `RootNavigation.Navigate` で遷移、MVVM = `GameFormViewModel`/`EditViewModel` + 葉 UserControl 群＝メタデータ/製作者/版/画像/プレビュー/SemVer）。保存オーケストレーションは #380/#381 で抽出済みの service（`GameVersionSetValidator`/`GameIdRenameService`/`VersionFolderRenameService`/`UpdateVersionsAndGame`）を再利用し、旧 `btnOK_Click` フロー（検証→アクティブ版確認→session conflict→gameId rename→版フォルダ rename→1 トランザクション保存→失敗時 rollback）を再現。ゲーム「追加」は当面 WinForms 据え置き（#324 後続）。
- 人数/難易度/年を `int?` 直持ちにして旧 WinForms の null 保護スナップショット glue を撤去（難易度/プレイ時間の null は WPF binding の挙動で保持＝触らなければ書き戻らない）。**プレイ人数は常に数値**（旧 NumericUpDown 同様「不明」不可、null は 1 にコアース）。
- **製作者をカード型インライン編集**（姓/名/期生を直接入力、教員/不明の排他トグル、左ハンドルでドラッグ並べ替え＝離した順＝クレジット順で保存）。**画像プレビューはランチャー表示を模した合成 1 枚**（背景枠＝PC の縦横比、その上に正方形サムネを左寄せ、両方 UniformToFill）。
- **保存成功は右下の緑トースト**（非モーダル・約3秒で自動消滅、WinForms ダイアログを廃止）。シェルレベルの `ShowSuccessToast` なので GoBack 後の一覧の上に表示。成功通知 + #295 アセットバックアップは保存成功直後に同期実行し、`Loaded` 再発火依存を排除。
- **意図的な挙動差**: SemVer 不正な version は保存前に修正必須（旧の silent v0.0.0 化を廃止、load 時に集約警告）／範囲外メタデータは保存時に矯正／外部フォルダの画像・exe は保存前にブロック（版フォルダ自動コピーは #324 PR4 送り）／版即時削除は #324 follow-up 送り。
- gameId 変更後に DB 更新が失敗した場合、失敗メッセージで「ゲームID 変更は確定済み」と正確に表示（部分 rollback の既知ギャップ #382 (iii)、完全 rollback は #382 で継続）。未保存のまま画面離脱時の破棄ガードは #383 で follow-up。
- （付随）全 NumberBox の幅を最大桁に合わせ統一（一覧の人数フィルタ・設定の保存日数/世代数を含む）。`Program.cs` への横断スタイル注入は不要と判断し撤去、各欄インライン指定に統一。
- （レビュー対応 C-1）人数 **min>max の破損版は load 時に連動クランプで silent heal せず温存**し、保存時に `GameVersionSetValidator.PlayerCountViolations` でブロック → ユーザーに修正させる。旧実装は「閲覧しただけで 5/3 → 3/3 に heal」して当該検証が viewed 版に対し dead 化していた（SemVer 不正版の「直させる」方針と非対称）。範囲 [1,99] クランプ・null→1 コアースは維持。あわせて `ImagePathPicker` docstring の dangling cref（`ImagePreview`→`LauncherPreview`）と警告組立の `vm` 参照統一を修正。
- bump 判断: 機能追加（破壊的変更 / DB スキーマ変更なし＝v23 据置）。**minor（v0.30.0 → v0.31.0）**。Launcher 変更なし。
- docs（部員向け編集手順 `docs/usage/games.md`）は **WPF 編集画面が未リリースのため今回は更新せず**（部員が使うのはリリース版＝現行 WinForms）。WPF 編集をリリースする回でまとめて更新（版ドロップダウンのラベル変更・「このバージョンを削除」の扱い等）。

### [Manager v0.30.0] - 2026-06-14

#### Added / Changed — ゲーム一覧の WPF ネイティブ化 + 全ページ見出し固定（`feature/manager-game-list-wpf`、#245 関連）

- **ゲーム「一覧」を WPF ネイティブ画面 `GameListPage` に**（ナビ「ゲーム」を旧 `GameHostPage`＝WinForms `GameSectionPanel` の WindowsFormsHost から差し替え）。Win11 設定アプリ「インストール済みアプリ」風のカード型リスト（角丸カード＋アイコン＋2 行テキスト＋右にバージョン）。ホバーで淡く反応するのみで**選択の青ハイライト・フォーカスの黒点線枠は持たない**（`IsSelected` トリガ削除 + `FocusVisualStyle={x:Null}`。操作はカードの ⋯ メニュー / ダブルクリックで、選択は内部用途のみ＝どのカードが選択中かを見せる必要がない。**ダブルクリックは実カード上のみ**で発火し、余白 / スクロールバー / ⋯ ボタン上では編集を開かない＝旧 `dgvGames_CellDoubleClick` の「セル上のみ」相当・レビュー指摘対応）。**キーボード矢印 / Page / Home / End での選択移動・自動スクロールも無効**（mouse 主体。クリック後にカードへ keyboard focus が残り、矢印で `ScrollIntoView` が勝手にスクロールするのを `PreviewKeyDown` で抑止。ホイール / スクロールバーは残す）。
- **検索 / 並べ替え / フィルター**: 検索（名前・ID・製作者の部分一致・大小無視）/ 並べ替え（タイトル・製作者・リリース年）/ フィルターはフライアウトで多軸 AND（ランチャー表示状態・通信プレイ・プレイ人数レンジ・難易度・プレイ時間・ジャンル複数選択）。絞り込みは操作・画面遷移をまたいで維持、件数は「N 個中 M 個を表示」。
- **プレイ人数フィルターはチェックボックスで明示的に ON/OFF**（レビュー対応）。コンボの各軸は index 0=「すべて」で OFF を表せるが、人数レンジ単体では「絞らない」状態を表現できないため、`プレイ人数で絞り込む` チェックを OFF の明示トグルにし（NumberBox はチェック時のみ有効）、heuristic（下限>1 or 上限<99）での暗黙有効判定を廃止。**プリセットは `[1,1]`**＝チェックして下限を N に上げるだけで `[N,N]`（連動クランプ）になり「N 人で遊べるゲーム」に絞れる（`[1,99]` 始まりだと両端を触る必要があり、チェックしても全件のまま no-op だった）。あわせて**人数未設定（null=Launcher で「不明」。`EditGameForm` が 1 への drift を防いで保持する 1 人用とは別状態）は範囲不明なので推測で隠さず常に通す**（旧実装は `?? 1` で「不明＝1 人用」と決めつけ、下限>1 で不明ゲームが消えていた。新規 install では UI 上 `Minimum=1` ゆえ実発生はレアだが、システム全体の null=不明 扱いと整合させる）。
  - 下限/上限は **`min<=max` を「相手を押し上げ/押し下げ」で保つ**（ブロックでなく範囲スライダー的に押す）。チェック OFF 時は `IsEnabled=false` に加え**コンテナ Opacity で行全体を一様減光**（`ui:NumberBox` は `IsEnabled=false` でも矢印/数字が減光されず背景しか暗くならないため）。この連動クランプ方針は今後ゲーム追加・編集の WPF 化（#242/#324）でも採る（保存時 `ValidatePlayerCount` の代わりに対話中に整える）。
- **サムネイル**: アクティブ版のサムネをアバターに表示（背景スレッドで後追いロード＝SMB でも UI を固めない、`UniformToFill`、解決は `RestoreReconciliationService` と同じ三段＝絶対 / gameFolder / install）。**非表示ゲームはカードごと薄く**（`Opacity` で「ランチャーに出ない」を一目で示す。表示中/非表示バッジは廃止）。サムネ背景ロードは `CancellationTokenSource` で**再入時 + ページ離脱（Unloaded）に前回ループを打ち切る**（画面遷移や操作後の再 `LoadGames` で、もう表示されないリストへ SMB I/O を出し続ける旧ループと新ループが二重に SMB を叩くのを防ぐ。fire-and-forget の予期しない例外も `Logger.Warn` で握る。レビュー指摘対応）。
- **操作は抽出済 service を再利用**（バージョンアップ＝`GameVersionUpService` / 削除＝`GameDeletionService`）+ 既存 `AddGameForm`/`EditGameForm`。WPF から WinForms モーダルを開く owner は**可視シェル窓 HWND を包む `ShellOwner`**、競合チェックは `SessionConflictHelper` に WPF 用 overload（`Application.OpenForms` から MainForm 解決）を追加。各カードの操作は ⋯ メニュー、追加は全体ボタン。版up の `VersionUpForm`/`ProcessingDialog`/各 `MessageBox` も `owner` を渡してシェルに正しくモーダル化（削除経路と対称・レビュー指摘対応）。`Add_Click` は起動完了前(SharedDb 未確定)の NRE 防御に Db null ガードを追加。
- **全ページ見出し固定**（ゲーム一覧 / ダッシュボード / 設定）: WPF-UI NavigationView の内蔵 ScrollViewer がページ全体をスクロール可にして見出しが流れる問題（lepoco/wpfui#1041）に対し、各ページ root の `MaxHeight` を祖先 ScrollViewer の `ViewportHeight` に縛り、見出しは固定行・コンテンツのみ内部スクロールに。ゲーム一覧 ListBox は `CanContentScroll=False` でピクセルスクロール（トラックパッドの段飛び解消）。
- **フライアウト挙動を共通化**（`FlyoutDismiss`）: 左クリックで開く Popup / ContextMenu を Win11 流に（開いている間の本体側クリックは「閉じる」だけに消費＝再オープン / 誤操作なし、中身クリックは操作させる）。フィルターと ⋯ メニューに適用、今後の新フライアウトも本ヘルパーに統一。
- **ダッシュボードの「更新」ボタンを削除**（タイマー自動更新があり冗長）。ダッシュボードの空状態緑箱・「・自動更新中」文言は v0.29.2 で整理済。
- bump 判断: 機能追加（破壊的変更 / DB スキーマ変更なし＝v23 据置）。**minor（v0.29.2 → v0.30.0）**。Launcher 変更なし。
- 残（マージ前）: 新一覧での **追加 / 編集 / バージョンアップ / 削除の実機確認**（捨てゲームで・実データ非破壊）。

### [Manager v0.29.2] - 2026-06-13

#### Changed — ダッシュボードの冗長表示を整理（`fix/manager-dashboard-drop-empty-state`）

- **「✓ 気になる項目はありません」の緑箱（`EmptyText`）を削除**。要対応 findings がゼロのとき、同じ all-clear を総合ステータス盾（緑「準備は整っています / 起動を妨げる問題は見つかりませんでした」）が既に表示しており冗長だったため。空状態は盾だけで表現する。**画像未設定 finding（v0.29.0）は維持**。
- **サブタイトルの「・自動更新中」文言を削除**（`最終更新 HH:mm:ss・自動更新中` → `最終更新 HH:mm:ss`）。常時固定文字列で状態を語らず、タイムスタンプが動くこと自体がライブ更新の証左なので冗長。時刻が止まれば更新停止の合図にもなる「最終更新」は残す。
- ブランチ経緯メモ: 当初 `fix/manager-dashboard-drop-unset-image` という名で切ったが、これはユーザーの「画像のやつ（＝添付スクショの緑箱）が要らない」を「画像未設定 finding を消す」と誤読した命名だった（コンテキスト圧縮でスクショが落ち文字だけ残ったため）。実体は緑箱削除なので `drop-empty-state` にリネーム。
- bump 判断: ダッシュボード UI の軽微な整理（機能追加 / DB スキーマ変更なし＝v23 据置）。**patch**。v0.29.1（PR #374・生 UNC 直起動の DB open 修正）が先にマージされたため、本 PR はその上に積んで **v0.29.2**。Launcher 変更なし。

### [Manager v0.29.1] - 2026-06-13

#### Fixed — UNC 直起動時に DB を開けない不具合

- **生 UNC パス (`\\server\share\...`) から Manager を起動すると `toneprism.db` が開けず起動失敗していたのを修正**（`SQLiteException: unable to open database file`、`MainForm_Load`→`TablesExist`→`connection.Open()`）。原因は **System.Data.SQLite の native (SQLite 3.46.1) が `Data Source` の生 UNC (`\\`) を弾く**こと（再現ハーネスで実測: `\\…`=NG / `//…`=OK / `FullUri=file:////…`=OK / `\\?\UNC\…`=NG。`sqlite3.exe` は別ビルドで `\\` も通る）。**UNC のときだけ `\` → `/` に変換するヘルパー `DatabaseConnection.ToSqliteDataSource` に集約**し、`Data Source=` を組み立てる箇所すべてで通す（SQLite は Windows で `/` を受理）。マップドライブ (`Z:\`) / ローカル (`C:\`) は `\\` 始まりでないので**無変換＝既存挙動ゼロ変化**。
- **(PR #374 review #1) 変換を 1 ヘルパーに集約し、DB 本体接続だけでなく `Data Source=` を組む全経路に適用**: 起動時ログ設定の読み出し+migration（`Program.cs`）/ 復元前の整合性チェック `CheckIntegrity`・現 DB 退避（`RestoreService`）/ バックアップ作成・検証 `VerifyBackupIntegrity`（`BackupService`）。当初は `DatabaseConnection` ctor のみの変換で、これら直開き経路が UNC 直起動時に取りこぼされ「起動はするがバックアップ/復元だけ落ちる」部分破綻になり得たため。`\\?\`（extended-length）は変換後の挙動が未実証ゆえ対象外（`PathManager` は生成しない）。純粋文字列変換の回帰テスト `DatabaseConnectionDataSourceTests`（8 ケース: UNC変換 / マップ・ローカル無変換 / null / 冪等 / `\\?\`除外）を追加。
- 背景: 本番はファイルサーバをマップドライブ（`Z:` 等）で運用しており元々この経路を踏まない（学校環境で動作確認済）。家の SMB テストで UNC 直起動して発覚した堅牢性バグ。SMB / 共有権限 / ファイル属性 / WAL は全て無実と切り分け済（`sqlite3.exe` は同 UNC を read-write で開けた）。
- bump 判断: bugfix のみ（破壊的変更 / DB スキーマ変更なし＝v23 据置）。**patch（v0.29.0 → v0.29.1）**。Launcher 変更なし。

### [Manager v0.29.0] - 2026-06-13

#### Added — ダッシュボード（準備完了度 + 要対応チェックリスト、`feature/manager-dashboard`）

- **新ページ `DashboardPage`（WPF ネイティブ）+ `DashboardService`** をナビ先頭 / 起動着地に追加。セキュリティソフトの設定 UI 風「要対応チェックリスト」（左）+ 概況タイル（右: 登録コンテンツ / バックアップ、列幅 Auto＝中身ぴったり）+ 総合ステータス盾 + LAN ランチャー稼働バッジ。
- **要対応 findings は `RestoreReconciliationService.Analyze()`（現 DB↔games フォルダ突き合わせ）を流用**: 重大度は「来場者が"今"プレイする物をブロックするか」基準で、**アクティブ版の起動不能 exe / スキーマ未完（Critical）**・非アクティブ版の不備（別バージョン不備・版フォルダ欠落）・画像欠落・スライド画像欠落（Recommended）・孤児フォルダ（Info）。非アクティブ版は表示中の版に影響しないので Critical→Recommended に下げ「別バージョン不備」へ改名し版フォルダ欠落と整合（PR #372 review）。加えて **画像未設定（サムネ/背景が未割当のゲーム）を Info で検出**（recon の「設定済みだが欠落」とは別軸、games を直接走査）。すべて部員に分かるプレーン日本語。総合ステータス盾は Critical（アクティブ版の起動不能 / スキーマ未完）だけ赤化し、画像系の任意項目は緑のまま＝対応を迫らない（盾下に「確認をおすすめ X 件・参考 Y 件」を分けて表示）。主リストは Critical + Recommended に絞り、Info（画像未設定・孤児フォルダ）は埋もれ防止に「参考（N）」折り畳みへ分離（PR #372 レビュー対応）。
- **× で finding を恒久非表示 → settings K/V（`dashboard_dismissed_findings`）に永続**（finding Id 単位。新規 key のみ＝**schema migration 不要 / `CurrentDbVersion` 据置 v23**）。「非表示にした項目」折り畳みから「戻す」で復帰可。**Critical（起動不能 / スキーマ未完）は × 不可＝必ず表示**（× で黙らせて盾を偽グリーンにする経路を構造的に封鎖、PR #372 review #1）。× の説明文（「× で非表示にできます」等）は冗長なので削除し × ボタンの自明性に委ねる。
- **LAN-wide ランチャー稼働検出を流用**: 編集前競合チェックと同一の `LauncherSessionService`（`responses/launcher_sessions/*.json` heartbeat、stale 除外済）を `MainForm.LauncherSessionService` アクセサ経由で共有。別PC のキオスクも「稼働中（N 台）」+ PC 名ツールチップで表示（read-only ファイルスキャンで背景スレッド安全）。
- **自動更新（near-real-time）の二段構え**: 軽いランチャーバッジは 3 秒、重い全体スキャン（recon + backups + 件数）は 約20 秒。ページ表示中のみ / 実行中の tick は skip（self-throttle）/ 取得は `Task.Run` で背景実行（SMB I/O を含むため UI を固めない）。
- **開発者向けの生ログ（WARN/ERROR）はダッシュボードに出さない**方針（部員に意味不明なため。生ログは『ログ』タブが SoT）。
- **チェック失敗を all-clear に見せない**: recon（`RestoreReconciliationService.Analyze()`）が `AnalysisFailed`（`GetAllGames` 失敗等で例外を投げず立つ）を返したら緑「準備は整っています」を出さず警告表示（PR #372 レビュー対応）。
- WPF 知見: `ItemsControl` の `DataTemplate` 内 TextBlock には `Page.Resources` の暗黙スタイルが届かず WPF 既定の黒文字に落ちるため、テンプレ内テキストは明示 `Foreground` 必須。
- フォロー: **#371（finding → 該当ゲーム編集画面への deep-link、ゲーム編集 WPF 化後＝#242 / #324 依存）**。
- bump 判断: Manager への機能追加（破壊的変更 / DB スキーマ変更なし＝v23 据置）。**minor（v0.28.0 → v0.29.0）**。Launcher 変更なし。

### [Manager v0.28.0] - 2026-06-13

#### Added / Changed (#245 PR5 — WinForms → WPF シェル移行)

- **可視メイン窓を WPF シェル（`FluentWindow` + `NavigationView`、WPF-UI 4.3・Win11 設定アプリ風ダーク）に移行**。`MainForm` は隠し裏方オーケストレータ化（`Opacity=0` → `Hide()`、message loop 所有権は WinForms 維持＝実績ある起動シーケンスを無改変温存）。シェル生成 / Show 失敗時は `Opacity=1` で旧 WinForms UI へ graceful fallback（Show 後の前面化 / ステータス反映の失敗はフォールバックさせずログのみ＝Hide 後の死蔵 Opacity を回避）。起動 init は前半（DB migration / session init ＝ `MainForm_Load`→`LoadCore` ラッパ）も後半（パネル初期化等 ＝ `ContinueLoadWithFallback`）も例外を degraded-but-visible で受け、`Opacity=0` + fail-open スプラッシュ下での「不可視窓＋スプラッシュ固まり」サイレントハングを起動全区間で防止。
- **既存 WinForms セクションパネルを `WindowsFormsHost` で単一インスタンスホスト**（`ShellHostBinder` の Loaded attach / Unloaded detach で host 破棄による共有パネル Dispose を回避。fresh 生成廃止＝二重 DB アクセス無し）。
- **設定を初の WPF ネイティブ画面に＋即時反映（#362）**: 純粋ヘルパー `SettingsPathPolicy`（空 / 相対 / 不正 / Ok / ローカル不在 / 到達不能 を分類・`Directory.Exists` 注入でテスト可）、パス / 数値 / トグルの即時反映、バージョン情報＋DBリセット、#201 未保存ガード撤去。数値は**デバウンス書込**（スピナー連打を 1 回に）、パスは **last-saved 追跡で変更時のみ書込**（no-op flush によるセッション競合ダイアログ誤発火を防止）。ログ保存先の到達不能は保存拒否（Logger が書けず失うため、共有サーバ想定のバックアップ先の緩和とは非対称）。
- **全進捗オペレーション（復元 / バックアップ / 更新 / アセット処理）をシェルのタスクバー進捗（緑バー）に集約**（`ProcessingDialog.ReportProgress` → `TaskbarItemInfo`、個別配線ゼロ。定量=Normal+% / Marquee=Indeterminate / 完了・中止・失敗=None、cosmetic 失敗は握り潰し worker に例外非伝播。シェル不在の fallback 時はダイアログ自身に taskbar ボタンを出す）。
- **起動スプラッシュを追加（#246）**: 専用 STA スレッド + 独立 Dispatcher で起動 init ブロック中も再描画継続、fail-open（障害で起動を止めない）、非トップモストで起動モーダルは前面、全 exit 経路で Close。別スレッドにフォアグラウンドを取られシェルが前面に来ない事象は `Activate` + `Topmost` 一瞬トグルで解消。
- **Fluent ネイティブのステータスバー**（左=DB接続状態 / 右=バックアップ feedback）。シェルのペイン / コンテンツ背景を窓と同色（#FF202020）に統一。
- **基盤**: WPF-UI 導入、Phase 0 共存スパイク撤去、`TonePrism.slnx`（VS の net10 NuGet 復元エラー対策、SPEC §2.4 / v1.10.64）、`DpiUnaware` 明示固定（WinForms↔WPF 共存の小窓化解消）。Mica すりガラスはホスト WinForms が airspace 衝突で透けるため、中身が WPF ネイティブ化するまで封印（`WindowBackdropType=None` + 不透明背景）。
- **未着手（後続 PR）**: ゲーム登録画面の WPF ネイティブ化（#242 god-file 分割 + #324 ウィザード）、MainForm 撤去（エンドゲーム）、ホストパネルの WPF ネイティブ化（黒文字 on ダーク等の過渡的見た目）。フォロー: #365（復元の統合プログレスバー）/ #366（テーマ切替）/ #292 🔴高#1（ゲーム追加フォルダ選択フリーズ）。
- bump 判断: WPF シェルへの UI 機能追加（破壊的変更 / DB スキーマ変更なし＝v23 据置）。**minor（v0.27.9 → v0.28.0）**。Launcher 変更なし。

### [Manager v0.27.9] - 2026-06-11

#### Changed (#258 PR4 — net10 配布: self-contained single-file)

- **配布形態を self-contained single-file に**（net10 は OS 同梱でないため、ランタイムを exe に同梱して「解凍 → すぐ動く・オフライン安全・ランタイム導入不要」の現行モデルを維持）。Manager の bundle 構成が **`TonePrism_Manager.exe` 1 個に集約**（旧 `.exe.config` / `System.Data.SQLite.dll` / `x64,x86\SQLite.Interop.dll` は exe 内包、native は初回 `%TEMP%/.net` へ self-extract）。代償は Manager サイズ ~170MB（一度きりの DL、Launcher(Godot) も元々数十MB のため許容）。
- **`Assembly.GetExecutingAssembly().Location` → `Environment.ProcessPath`**（`UpdaterClient` / `Program`）。single-file で `Location` が空文字を返す問題（IL3000、自己更新の Manager パス空 + IE11 emulation の exe 名空）の解消。single-file / 通常の両方で実 exe パスを返す堅牢化。
  - （レビュー Low）`UpdaterClient` の `managerExe` に null/空ガードを追加（`Environment.ProcessPath` は理論上 null 可。空だと `--restart-exe ""` で Updater が置換後に Manager を再起動できず silent 降格 → 明示 `Fail` で `Program.cs` と対称化）。`ProcessPath` は throw しない dead な try/catch を明示 null チェックに置換。`Quote` の stale コメント（caller に `Assembly.Location` 記載）も `Environment.ProcessPath` に更新。
- **expected-files 刷新**: `Release.ps1 $script:BundleManifestFiles` と `UpdateDownloader.ValidateStagingLegacy` の Manager 行を exe 1 個に（drift で apply 永久 abort の二層 fence を同期）。
- 検証: net10 ビルド 0 警告 0 エラー・**xUnit 199/199 緑**・**single-file 実起動 smoke**（隔離 temp + repo `toneprism.db` のコピー、原本不変）で 169MB 単一 exe 起動 → DB バージョン 23 / 全 8 テーブル整合 OK / **SQLite native (self-extract) ロード**・assembly load エラー 0。実 GitHub 更新確認 / 実更新適用（DL→Updater→再起動）の end-to-end は pre-release 全体検証へ。
- bump 判断: 配布形態の変更（self-contained single-file）+ single-file 対応コード修正。patch (v0.27.8 → v0.27.9)。Launcher 変更なし。

### [Manager v0.27.8] - 2026-06-11

#### Changed (#258 PR3 — net48 → net10 切替)

- **Manager / Manager.Tests の TargetFramework を `net48` → `net10.0-windows` に flip**。PR1 (SDK-style 化) / PR2 (System.Web・JSON 撤去) で地ならし済のため本 PR はほぼ機械的:
  - 旧 net48 framework `<Reference>` 群 (CustomMarshalers / System.Transactions / System.Net.Http / System.IO.Compression(.FileSystem) / System.Data.DataSetExtensions / Microsoft.CSharp) を**全撤去** (net10 は shared framework が in-box 提供。DataSetExtensions/Transactions/CustomMarshalers は実使用ゼロを確認、`AsEnumerable` は System.Linq 由来で DataSetExtensions ではない)。
  - SQLite を `Stub.System.Data.SQLite.Core.NetFramework` → net10 対応の `System.Data.SQLite.Core` 1.0.119.0 へ差し替え (native interop は `runtimes/<rid>/native/SQLite.Interop.dll` で同梱)。
  - `System.Text.Json` PackageReference を撤去 (net10 同梱)。
- **空・未使用の `Properties/Settings.settings` + `Settings.Designer.cs` を削除** (`<Settings/>` 空・`Properties.Settings`/`Settings.Default` 参照ゼロを確認) → `System.Configuration.ConfigurationManager` 依存を回避。net48 専用の `App.config` (`<startup><supportedRuntime>` のみ) も削除。
- **net10 WinForms SDK の新エラー/警告に対応**:
  - **WFO1000 (error 化)**: custom control の runtime 専用プロパティ (`SemverInputControl` の VersionString/Major/Minor/Patch/Suffix、`ProcessingDialog` の MarqueeMode/AllowCancel — いずれも child control 委譲で backing field 無し) に `[DesignerSerializationVisibility(Hidden)]` を付与 (designer シリアライズ対象外を明示)。
  - **SYSLIB0014**: `Program.Main` の `ServicePointManager.SecurityProtocol = Tls12` を撤去 (net10 では obsolete かつ HttpClient に無効＝no-op。Win10/11 + net10 は default で Tls12/13)。
  - **CA1416**: Windows 専用アプリ (net10.0-windows) のため csproj `<NoWarn>CA1416</NoWarn>` で一律抑止。
- 検証: **net10 ビルド成功 (0 警告 0 エラー)**・**xUnit 199/199 緑 (.NETCoreApp v10.0)**・**実起動 smoke** (隔離 temp + repo `toneprism.db` コピー、原本不変) で net10 apphost exe 起動 → DB バージョン 23 / 全 8 テーブル整合 OK / session 登録・**SQLite native interop が runtimes/win-x64 経由で runtime ロード**・assembly load エラー 0 を確認。
- **⚠️ 配布 (Release.ps1 / bundle) は PR4 で対応**: net10 出力は `.dll` + apphost `.exe` + `runtimes/<rid>/native/` (旧 `x64/x86/` flat 構造でない) + `.exe.config` 非生成のため、現 `$script:BundleManifestFiles` (`TonePrism_Manager.exe.config` / `x64,x86/SQLite.Interop.dll` を期待) と drift する。**本 PR では Release.ps1 を触らず** (CI `dotnet test` 経路のみ追従)、self-contained publish + expected-files 刷新は **PR4** で実施 (それまで Manager の bundle release は `Assert-ExpectedFiles` で fail-fast)。SPEC の Companions ランタイム / 配布記述の同期も PR4 / Companions 移行 (PR4.x) で。
- bump 判断: ランタイム移行 (net48→net10)。挙動は smoke + 199 緑で不変確認。patch (v0.27.7 → v0.27.8)。Launcher 変更なし。

### [Manager v0.27.7] - 2026-06-11

#### Changed (#258 — JavaScriptSerializer → System.Text.Json 移行 + System.Web 一族撤去)

- **JSON serializer を `JavaScriptSerializer`（System.Web.Extensions、net10 に存在しない）→ `System.Text.Json` に移行**。新規 `Services/JsonCompat.cs` を**挙動保存アダプター**として挟み、各 call site の周辺コードを無改変に保つ:
  - `Deserialize<T>`: `PropertyNameCaseInsensitive=true` で旧 case-insensitive 挙動を再現（camelCase wire ↔ PascalCase DTO 互換。sentinel `UpdateCompletedSentinel` / `LogsRootMigratedSentinel`、update cache `CacheDto` が依存）。
  - `DeserializeToObjectTree`: 旧 `DeserializeObject` / `Deserialize<Dictionary<string,object>>` の動的型（object→`Dictionary<string,object>`、array→`object[]`、string/bool/long/double/null）を再現 → `GitHubReleaseChecker` の nested assets 走査・`UpdateDownloader` の manifest 読取・`LauncherSessionService` の session JSON 解析を**無改変**で維持（`AsLong` の `is long`/`is int` 両対応を利用）。
  - `Serialize`: compact 出力で wire format 不変（匿名型 camelCase / DTO PascalCase をそのまま）。`UpdateChecker` cache の `MaxJsonLength=1MB` guard は明示 length check で再現。
- **`HttpUtility.HtmlEncode`（System.Web）→ `System.Net.WebUtility.HtmlEncode` に置換**（`UpdateSectionPanel` / `MarkdownRenderer`、drop-in）。これで `System.Web` の最後の利用も消滅。
- **csproj: `System.Web` / `System.Web.Extensions` 参照を撤去、`System.Text.Json` 8.0.5 PackageReference を追加**（netstandard2.0 で net48 から利用可、net10 化後は framework 同梱版に透過解決）。System.Web 一族の net10 ブロッカーを解消。
- **テスト追加（重要）**: 移行前これらの JSON 経路には test が無く「190 緑」が網にならなかったため、`JsonCompatTests`（converter 型 / case-insensitive / round-trip 5件）+ `GitHubReleaseCheckerTests`（nested assets 走査 / array / throw 4件）を追加（**199 緑**）。`LauncherSessionService` の session 解析は既存 `LauncherStaleDetectionTests` が既に網羅。
- 検証: Debug/Release ビルド成功・**xUnit 199/199 緑**・`bin\Release` に System.Text.Json + 依存（System.Text.Encodings.Web 等）同梱・exe.config に `System.Runtime.CompilerServices.Unsafe` の binding redirect 自動生成を確認。**実起動 smoke**（隔離 temp + repo `toneprism.db` のコピー、原本不変）で System.Text.Json の **両 read 経路を exe プロセスで実証**: (1) `.update_completed` sentinel → `JsonCompat.Deserialize<T>` 成功（log `update_completed dialog 表示: Bundle v9.9.9`）、(2) `responses/launcher_sessions/` に session JSON 投入 → `JsonCompat.DeserializeToObjectTree`（`JsonDocument.Parse`）成功（log `(#278) … Launcher 1 件` = parse + count）。いずれも assembly load エラー 0 = net48 ロード + binding redirect を runtime 確認。`Serialize` 経路は同一 loaded assembly + 199 net48 テストで担保。実 GitHub 更新確認 / 実更新適用 / 実 Launcher セッションの end-to-end は pre-release 全体検証へ（レビュー F 項目）。
- bump 判断: 内部 serializer 移行（挙動非変更）+ dead dep（System.Web 系）撤去。patch (v0.27.6 → v0.27.7)。Launcher 変更なし。

### [Manager v0.27.6] - 2026-06-11

#### Changed (ビルド基盤の近代化: SDK-style 化 + dead 依存撤去 #309)

- **Manager の csproj を classic (packages.config) → SDK-style (`Microsoft.NET.Sdk` / PackageReference) に変換**（#245/#258 の WPF・net10 移行の前提となる「器」の刷新。**TFM は net48 のまま据え置き**＝ランタイム変更は別 PR に分離し「書式変更」と「ランタイム変更」を 1 変数ずつ切り分ける）。`UseWindowsForms`+`UseWPF` で WinForms/WPF 相互運用を維持、`GenerateAssemblyInfo=false` で既存 `Properties/AssemblyInfo.cs`（版数・`InternalsVisibleTo`）を温存、`AppendTargetFrameworkToOutputPath=false` で出力を `bin\$(Configuration)\` に固定（Release.ps1 の `bin\Release\` 直参照を維持、net10 flip 後もパス不変で A4 の配布差分を restore/publish 形態のみに絞る）。
- **dead 依存を撤去（#309）**: `Microsoft.WindowsAPICodePack`(Core/Shell) はフォルダ選択の `FolderBrowserDialog` 化（PR #308）で実コード未使用のため撤去。併せて使用箇所ゼロの `System.Deployment` 参照も削除。bundle 同梱からも外し、SoT である `Release.ps1 $script:BundleManifestFiles`（= `Assert-ExpectedFiles` + manifest 生成を駆動）と `UpdateDownloader.ValidateStagingLegacy` の expected-files を**両経路同期して除去**（drift で Manager UI apply が永久 abort になる二層 fence のため両方）。
  - 併せて packages.config の整理: 明示参照していた `System.Buffers` / `System.Memory` / `System.Numerics.Vectors` / `System.Runtime.CompilerServices.Unsafe` は PackageReference の transitive 復元へ移行（`Span<>`/`Memory<>` の直接使用は repo にゼロ）、二重登録だった `System.Data.SQLite.Core`（実参照は Stub 側 HintPath 由来で非 Stub パッケージは未使用）も撤去。いずれも挙動非変更（レビュー Low: CHANGELOG 網羅性）。
- **配布 / CI スクリプト側の追従**（`Release.ps1 Build-Manager` の `msbuild /restore` 化・不要 nuget 経路撤去・CI `manager-tests.yml` の packages.config restore step 撤去）は **`## Release Tooling` v0.1.25** に集約（配布スクリプトの「件」・本 component 変更と同 PR）。packages.config 削除と CI 修正は不可分。
- 検証: VS MSBuild で Debug/Release ビルド成功、**xUnit 190/190 緑**（CI `manager-tests.yml` の `dotnet test` 実走も緑）、`bin\Release` から WindowsAPICodePack 消滅・`SQLite.Interop.dll`(x64/x86) 健在を確認、exe の埋め込み resx マニフェスト名（9 件）が classic と完全一致を reflection で確認。**GUI 実起動 smoke も実施**（レビュー対応）: `bin\Release` を隔離 temp（`.git` pin で repo root 解決を固定 + repo `toneprism.db` の【コピー】を投入、原本は不変）に置いて起動 → ログで **0 ERROR・DB 接続・スキーマ整合 8 テーブル OK・session 登録(ver=0.27.6)・heartbeat 起動** を確認＝アセンブリロード（binding redirect は exe.config 0 件で正・PackageReference unification）/ resx / SQLite native interop が exe プロセスで成立。Manager UI の各タブ操作・game add round-trip の full smoke は引き続き A4 の clean publish 時に実施。
- bump 判断: ビルド基盤刷新 + dead 依存撤去（#309 close）。挙動非変更だが依存撤去を含むため patch (v0.27.5 → v0.27.6)。Launcher 変更なし。

### [Manager v0.27.5] - 2026-06-11

#### Changed (アプリ表示名の整理)

- **メインウィンドウのタイトルを「TonePrism 管理ソフト」→「TonePrism マネージャー」に変更**（`MainForm.Designer.cs` `this.Text`）。Launcher の「TonePrism ランチャー」（v0.11.8）とトーンを揃え、「TonePrism ＋ カタカナ役割名（コンポーネント名と一致：マネージャー／ランチャー）」で一族の表示名を統一。exe / `AssemblyProduct`（=「TonePrism_Manager」）は規約どおり技術名を据え置き、可視名のみ変更。併せて設定タブ「製品名」表示の fallback 文字列も「TonePrism マネージャー」に揃えた（通常は AssemblyProduct を表示するため実発火しないが drift 防止）。
- **スコープ（意図的な据え置き）**: 本変更は**窓タイトル（＝アプリの"名前"レイヤ）のみ**。アップデート通知ダイアログ等の**本文 prose（例: `MainForm.cs` の「新しい管理ソフトが起動しています」）と `docs/` は平易語「管理ソフト（Manager）」を維持**する。理由は「名前＝タイトルバー / 機能の説明＝prose・docs」の別レイヤで、部員・スタッフ向け説明文は機能を表す平易語のほうが分かりやすいため（SPEC §3.7.3 等でも prose は「管理ソフト」で一貫）。よって **docs 更新は不要**（語彙の意図的な使い分け）。
- bump 判断: 表示名の変更（破壊的変更・schema 変更なし）。patch (v0.27.4 → v0.27.5)。Launcher v0.11.8（ランチャー表示名）と同 PR。

### [Manager v0.27.4] - 2026-06-10

#### Changed (#297 — 未実装の「人気ランキング」「最近プレイ」をストアセクションのソース選択肢から一時除外)

- **ストアセクション編集フォームのソースドロップダウンで「人気ランキング」「最近プレイ」を新規選択肢から隠した** (`StoreSectionForm.cs` `AllSources` に `Hidden` フラグ追加)。両ソースは実ランキング（responses の in-memory 集計）が #297 PR2 / v0.9.0 で未実装のため現状プレースホルダ：「人気」は実態がタイトル順なのに「人気」と表示され**来場者に誤解**を与え、「最近プレイ」は0行で**セクション自動非表示**になりスタッフが「追加したのに出ない」と混乱しうる。誤って選べないよう新規選択肢から隠す。
  - **既存セクションは round-trip 保持**：`RebuildSourceCombo` で Hidden ソースも「編集中セクションの現ソースと一致するとき (`entry.Source == desiredSource`) だけ」combo に出すため、既に `popular`/`recently_played` で保存済みの既存セクションを開いても**手動に silent coerce されず元の値が保存される**（`AllSources` から丸ごと消すと開いて保存で `manual` に化けて値が消える＝当初実装の不具合をレビューで是正）。`CanonSourceFromString` で canonical も保持。
  - **#297 PR2 で実ランキングを実装したら `AllSources` の両者の `Hidden` を `false` に戻すこと**（コード内コメント＋#297 に再追加メモを記載）。
  - **round-trip で露出する Hidden ソースに「（準備中）」サフィックス** (レビュー指摘2): 既存 `popular`/`recently_played` セクションを開いたとき combo に出るラベルを「人気ランキング（準備中）」「最近プレイ（準備中）」にし、通常の有効ソースと見分けられるようにした（実態がタイトル順／0行のプレースホルダと一目で分かる）。表示ラベルのみの変更で、保存値は `_sourceMap` の canonical ID から `GetSourceString` が再生成する（ラベル文字列は参照しない）ため round-trip は壊れない。PR2 で `Hidden=false` に戻せば suffix も自動で消える。
  - docs ドリフト対応 (レビュー指摘1): `docs/usage/store.md` を整合させた。(a) 自動ソース一覧の直後に**早期 warning**（人気/最近プレイは準備中・以下の記述は実装後の姿）を追加し top-to-bottom 読者が working source 説明に達する前に告知。(b) 「厳選枠はこの **4 つだけ**出る」の枚数記述を「実装後は最大 4 つ／**現在は手動・ランダムの 2 つ**」に修正（catch-all 注記では上書きできない具体的個数の矛盾を是正）。(c) 末尾 warning は早期注記を参照する短縮形にして二重管理を回避。
- 検証: VS MSBuild で Release ビルド成功（compile 確認）。**※実機で Manager のストアセクション編集→(1)新規でソースに「人気」「最近プレイ」が出ない・他ソースは従来どおり選べる (2) 既存の人気/最近プレイセクションを開くと現ソースが「（準備中）」付きで保持され手動に化けない（保存して `section_source` が `popular`/`recently_played` のまま）ことは目視**（検証 seed はコピーDBで・marker 限定後始末）。
- bump 判断: UI 選択肢の一時調整のみ。patch (v0.27.3 → v0.27.4)。Launcher 変更なし。

### [Manager v0.27.3] - 2026-06-09

#### Fixed (#313 — リリース年・何期生を「不明」(空欄)で登録可能に)

- **ゲーム追加/編集の「リリース年」と製作者の「期生」を、不明（空欄）のまま登録できるようにした**。DB は両方 nullable だが UI が NumericUpDown で値を強制していたため、「年・期生が分からない古いゲーム」を正しく登録できず非表示にせざるを得なかった（nullable schema に UI を合わせる過剰制約の修正）。
  - **リリース年**: `AddGameForm` / `EditGameForm` の `numReleaseYear` に「不明」チェックボックスを併設。チェック時は入力を無効化し `release_year = null` で保存。`EditGameForm` は読込時に DB が null（または範囲外 clamp）なら自動でチェック。`VersionUpForm` は既存ゲームの値を継承するだけなので変更なし。
  - **期生**: `DeveloperForm` で「期生（数値）」に加えて **「教員」「不明」の排他チェックボックス**を併設。教員 ON → `grade = "0"`、不明 ON → `grade = ""`（空＝不明）、どちらも OFF → N期生。チェック時は `numGrade` を無効化（グレーアウト）。読込時に DB の grade が `""`→不明 / `"0"`→教員 を自動判定。旧実装は「0 で教員」を数値直入力させ、かつ空でも 1 に coerce して「不明」を失っていたのを解消（`numGrade` 最小値も 0→1、0=教員 はチェックボックスへ移行）。
  - **製作者名の表示**: 姓または名の一方のみ登録された製作者で、表示名に余分なスペース（`山田 ` / ` 太郎`）が出ていたのを解消（`DeveloperInfo.FullName` / Launcher `developer_info.get_full_name` を両空欄対応に）。`game_info_display` も手組み `"%s %s"` から `get_full_name()` に統一。
- 検証: build 緑 + 189 テスト合格。**実機で「不明」登録 → 保存 → 再読込 → Launcher 表示が崩れないことを目視（pre-release）**。
- bump 判断: 過剰制約の修正（破壊的変更・schema 変更なし）。patch (v0.27.2 → v0.27.3)。Launcher v0.11.2 と同じ v0.8.2 に同梱。

### [Manager v0.27.2] - 2026-06-08

#### Fixed (#317 — 整合性レポート「まず確認」文言の訂正)

- **整合性レポート (`RestoreReportForm`) 冒頭の「まず確認」文言が「バックアップ／復元の対象は DB だけ」と誤って案内していたのを訂正**。#250 以降、通常のバックアップ／復元は toneprism.db に加えて**ゲームファイル本体・初回説明の画像も対象**になっているのに、文言が旧仕様（DB のみ）のまま残っていた。
  - **standalone（手動で整合性チェックを実行したとき）**: 「通常のバックアップ／復元は DB に加えてゲームファイル・初回説明画像も対象。ただし手動でファイルを変更した／古い形式のバックアップを復元した等で DB とディスクの『時点』がズレることはある」という正確な説明に差し替え。
  - **復元直後（`_postRestore` かつ `_assetResult == null`）**: アセットを一緒に復元しなかった旨を案内する。当初は「今回の復元は古い形式のバックアップ（DB のみ）だった」と理由を断定する文言にしたが、`_assetResult == null` は (a) 旧/unknown 形式の DBのみバックアップだけでなく (b) **新形式バックアップだが復元前のゲームファイル退避に失敗して DBのみ復元へ degrade したケース**（`BackupSectionPanel` の `assetRetreatFailed`）も含むため、(b) で「古い形式だった」と断定すると同時に出る degrade 告知ダイアログ（`retreatFailedNote`）と矛盾する。**理由を断定せず「ゲームファイル・初回説明画像は一緒には復元されていない」事実だけ述べる**文言に修正（degrade の具体的理由は呼び出し側の別ダイアログに委ねる）。
  - 併せて `RestoreReportForm` の**クラス doc コメントも訂正**: 旧仕様「バックアップ/復元は toneprism.db のみが対象」と断言したままだったのを、#250 以降の実態（games/+guide/ も対象。手動変更・旧形式復元・degrade で時点ズレはなお起きうる）に更新（本文だけ直してコメントが旧仕様を温存し、将来逆戻りさせる温床になるのを防ぐ）。

#### Fixed (#312 — フォーム入力中の Enter で誤保存される不具合)

- **ゲーム追加 / 編集 / バージョンアップ / 初回説明スライド編集の各フォームで、入力途中に Enter を押すと保存が走ってしまう事故を防止**。原因は各フォームに `AcceptButton = btnOK` が割り当たっており、リリース年などの**各フィールドで「値を確定しよう」と Enter を押すと保存ボタンが発火**していたこと。4 フォームで `AcceptButton` を**未設定**にし、Enter での自動保存を無効化した（保存は保存ボタンのクリックで明示。`CancelButton`=Esc によるキャンセルは従来どおり残す）。
- 併せて**複数行入力欄の改行**も確保: 説明文欄 `txtDescription`（追加/編集/版up）・初回説明スライドの本文欄 `_txtBody`（`IntroSlideEditForm`）・更新ノート欄 `txtUpdateNote`（版up）は `Multiline = true` だが `AcceptsReturn` 未設定だと（AcceptButton の有無にかかわらず）Enter で改行されないため、`AcceptsReturn = true` を設定し Enter を**改行**にした。**特に初回説明スライドの本文は #318 で Launcher 側の複数行レンダリングを直しており、入力側（このフォーム）で改行できないと整合しないため同時に対応**（レビュー指摘で発覚した同 PR 内のスコープ漏れ）。
  - **対象外と判断したもの**: `txtVersionDescription`（編集フォーム）は `ReadOnly = true` の表示専用欄なので入力対象外。`txtArguments`（起動引数、全3フォーム）は `Multiline = true` だが**引数に改行が入ると不正**なため `AcceptsReturn` は付けない（AcceptButton 撤去で Enter は無反応になるが、これは「改行も保存もしない」= 引数欄として安全な挙動）。`DeveloperForm`（製作者の追加）は `AcceptButton = btnOK` を持つが、入力欄が姓・名の**単一行のみ**で複数行欄の改行を潰す問題が起きず、2 項目の小ダイアログでは Enter=確定が自然な UX のため**意図的に据え置き**（誤保存リスクの本質は複数行欄を持つフォームに限る）。
- 検証: build 緑。**実機で各フォーム（リリース年などの各フィールドで Enter を押しても保存されない・複数行欄で Enter が改行になる・保存ボタンで保存できる・Esc でキャンセルできる）を目視**。初回説明スライド本文は複数行入力 → 保存 → Launcher 初回説明で改行表示（#318）まで通しで確認。
- bump 判断: バグ修正のみ（破壊的変更・schema 変更なし）。patch (v0.27.1 → v0.27.2)。Launcher v0.11.1 と同じ v0.8.1 リリースに同梱。

### [Manager v0.27.1] - 2026-06-07

- **フォルダ選択ダイアログを開くたびにウィンドウが縮むバグを修正**: ゲーム追加 / バージョンアップの「ゲームフォルダ選択」を開閉するたびに、Manager 本体ウィンドウ（＋ダイアログ）が**少しずつ縮んでいく**不具合があった（拡大率 100% 超の環境、本機は 200% で発生）。本番DB作成でゲームを多数登録する際に作業不能なため修正。
  - **原因**: フォルダ選択に使っていた WindowsAPICodePack の `CommonOpenFileDialog` は **per-monitor DPI 対応のネイティブ COM ダイアログ**。一方 Manager は DPI awareness 未宣言（unaware）なため、このダイアログを開くたびに WinForms 側ウィンドウが DPI 再スケールされ縮む（画像/実行ファイル選択の標準 `OpenFileDialog` では起きないのは、こちらが per-monitor COM ダイアログでないため）。標準 `OpenFileDialog` はフォルダを選べないので元々この COM ダイアログを使っていた。
  - **試して不発だった対策**（記録）: (1) `SetThreadDpiAwarenessContext` でスレッドの DPI コンテキストをオーナーに固定 → 縮み止まらず（COM ダイアログが自前でコンテキストを張り直す）。(2) ダイアログ前後で全フォームのサイズを保存・復元 → 止まらず（再スケールが復元後／子コントロールごと一様に縮む）。(3) app.manifest で **System DPI awareness 宣言**（根本対策）→ 全フォームが AutoScale 再計算され**起動時点でメイン画面のレイアウトが崩壊**（実機確認、特に AutoScaleDimensions が `(6,12)` の 4 フォーム）。(4) ダイアログを**別 STA スレッド**で表示 → `CommonOpenFileDialog` がワーカースレッドで `InvalidOperationException`。
  - **採用した修正**: フォルダ選択を WinForms 標準の **`FolderBrowserDialog`（旧来のツリー型）に変更**（新 `Services/DpiSafeFolderPicker.cs` に集約）。per-monitor COM ダイアログを使わないため awareness ミスマッチ自体が起きず**確実に縮まない**。DPI/レイアウト/manifest には一切触れない surgical な修正。UX がツリー型になる分は、**直近に選んだフォルダを記憶して次回の起点にする**ことで緩和（bulk 登録時に毎回ツリーを頭から辿らず、兄弟フォルダをすぐ選べる）。対象は `AddGameForm`（ゲームフォルダ）/ `VersionUpForm`（バージョンフォルダ）の 2 箇所。
  - **将来**: モダンなフォルダピッカーの復活は、DPI aware 前提でレイアウトを組み直す **WPF 移行（#245）**で扱う（WPF は本来 DPI aware なのでこのミスマッチが構造的に発生しない）。
- 検証: build 緑。**実機（拡大率 200%）でフォルダ選択を反復開閉してもウィンドウが縮まないこと・メイン画面レイアウトが正常なこと・直近フォルダ起点で開くことを目視確認**。
- bump 判断: バグ修正のみ（破壊的変更・schema 変更なし）。patch (v0.27.0 → v0.27.1)。Launcher / Companions は無関係。

### [Manager v0.27.0] - 2026-06-07

- **(#297 PR1) プレイ記録・アンケートを SQLite から撤去（JSON 直読み化へのピボット・スキーマ側）**: プレイ記録/アンケートの保存方式を「Launcher が JSON drop → Manager が SQLite へ取り込む（drop-folder）」から「**Launcher が JSON を直読みしてメモリ集計**（SQLite を経由しない）」へ転換する #297 の第 1 弾。本 PR は **Manager 側のスキーマ撤去**と SPEC 改定、Launcher の非参照化まで（書込/集計は PR2、アンケート UI は PR3）。本番DB作成前の最後のスキーマ変更として、v23 のクリーンスキーマを確定させる。
  - **設計判断（なぜ撤去）**: 旧 drop-folder 取り込みは (1) 取り込み時点でデータが固定され**常に最新を表示できない**、(2) `play_records`/`surveys` のスキーマ drift を Manager が抱え続ける、(3) Launcher が読む人気順表示に Manager 起動が必要、という構造的弱点があった。`play_records`/`surveys`/`launcher_surveys` は **定義のみで実装ゼロ**（取り込み INSERT も Launcher 書込も未実装、本番データ未蓄積）だったため、**撤去が最安**の段階で JSON 直読み + メモリ集計へピボットした（常に新鮮・drift 解消・retention をフォルダ単位に単純化）。
  - **`MigrateV22ToV23` 追加**（`DROP TABLE IF EXISTS surveys / play_records / launcher_surveys`）+ `CurrentDbVersion` 22→23。これら 3 テーブルは `games` を参照する子テーブルだが **CASCADE 波及はなく安全**（親 games を消すわけではない。前例 `MigrateV18ToV19` の backup_log DROP と同型）。migration chain に `if (currentVersion < 23)` ブロックを追加（v22→v23、v22 未満は warn して skip）。
  - **`CreateTables` から撤去**: `CreatePlayRecordsTable`/`CreateSurveysTable` の呼び出し + launcher_surveys CREATE ブロックを削除（メソッド本体・dead な `GetTableRowCount` も削除）。`ExpectedSchema` から 3 エントリ削除（`VerifySchema` 対象外に）。
  - **`MigrateV10ToV11` を no-op 化**（`return true` のみ。旧 `FixSurveysSchemaDrift`/`FixPlayRecordsSchemaDrift` を撤去）。chain の連続性維持のため呼び出しは残すが、結局 v23 で DROP されるテーブルの drift 修正は無意味なため本体を空に。
  - **stale モデル削除**: 参照ゼロだった `Models/Survey.cs` / `Models/PlayRecord.cs`（+ csproj の `<Compile Include>`）を削除。
  - **潜在ランタイムバグ修正（`GameRepository.UpdateGameId`）**: game_id リネーム時の子テーブル更新が `UPDATE play_records / surveys SET game_id ...` ＋ `UPDATE launcher_surveys SET favorite_game_id ...` を実行していた。v23 で 3 テーブルを DROP すると、これらは**コンパイルでは検出されない**「no such table」ランタイム例外を投げ、**game_id リネームがロールバックして失敗**する。子テーブル配列から `play_records`/`surveys` を除去（残すのは `game_versions`/`developers`/`store_section_games`）し、`launcher_surveys` UPDATE ブロックを削除。回帰テスト `DataLayerRoundTripTests.GameRepository_UpdateGameId_RenamesWithoutTouchingDroppedTables`（fresh v23 DB で rename が例外なく完走＋developers が新 ID へ追従）を追加。`GameSectionPanel` のゲーム削除 CASCADE コメントも撤去済テーブルを除外して更新。
  - **撤去回帰テスト**: `SchemaMigrationTests.V22ToV23_DropsEventTables`（v22 DB に games + 3 テーブルを空で作り、`InitializeDatabase` 後に `sqlite_master` に 3 テーブル 0 件・`user_version=23`・`integrity_check ok` を assert）。既存 `V19ToV20_...` の `COUNT(*) FROM play_records` assert は撤去（CASCADE 非発生の検証意図は developers/game_versions の COUNT で担保）。`IntroSlideTests` の固定版数 assert（旧 v22）を `GetTargetDatabaseVersion()` 動的化して将来 bump に耐性を持たせた（`FreshDb_ReachesV22_...` → `FreshDb_ReachesCurrentVersion_...` に改名）。
  - **SPEC 改定**（§6.2/§6.4/§6.5/§7.1〜§7.6.4/機能10-12）: drop-folder 3-state/2-phase 取り込みを JSON 直読み + Launcher メモリ集計へ全面改定、テーブル 3/4/10 を「廃止 — DB v23」表記（番号欠番、game_genres/backup_log 廃止記法を踏襲）、ER 図から play_records/surveys 削除、§7.5.3 を日付フォルダ + JSON スキーマ確定に改定。IPC 用 subfolder（`launcher_sessions`）/ 直下 file（`launcher_logs_root.json`）は存続。`PathManager.LauncherSessionsFolder` の §6.5 参照コメントも追従（旧 3-state pattern 参照を IPC 用 subfolder 表現に更新）。
- **レビュー対応（同 PR・version 据え置き）**: (#1 Low) **v0 fast-path が 3 テーブルを DROP しないまま v23 を刻む穴を是正**。`currentVersion==0` の retrofit 経路（versioning 導入前 DB 用）は `CurrentDbVersion` を直接 stamp するが `MigrateV22ToV23` を呼ばず、かつ no-op 化した `MigrateV10ToV11` を「drift を直す体」のコメント＋到達不能な false 分岐＋発火しない警告ログ付きで残していた。→ (a) v0 path の `MigrateV10ToV11` 呼び出し＋stale コメント＋dead branch を撤去、(b) `MigrateV22ToV23`（`DROP TABLE IF EXISTS`＝冪等、新規 DB では no-op）を stamp 直前に明示適用し、versioning 導入前から 3 テーブルを物理的に持つ旧 DB でも撤去して真の v23 へ揃える。これで CHANGELOG/SPEC の「既存 DB は `MigrateV22ToV23` で DROP する」を v0 サブセットでも成立させる。回帰テスト `V0FastPath_DropsEventTables_AndReachesV23`（user_version=0＋3 テーブル物理存在 → `InitializeDatabase` 後に DROP・v23 到達・games 保持）を追加。※ `backup_log`（v19 DROP）の v0 path 未適用は #297 とは別件の既存 gap で本 PR scope 外（コメントで明示）。(#2 Low・運用注意) PR1 単独で Bundle release すると「人気」セクションが暫定順（display_order）で出るため、production に届く Bundle は PR2（popular 実集計）とセットにする運用を担保（本番 play_records は元々空で実害は順序のみ）。
- 検証: Manager build 緑 / **テスト 189 件合格**（撤去回帰 `V22ToV23_DropsEventTables` ＋ `UpdateGameId` 回帰 ＋ v0-path 回帰 `V0FastPath_DropsEventTables_AndReachesV23` を追加）。**※新規 DB および v22 実 DB での v23 到達（3 テーブル不在・integrity ok）は sqlite3.exe で実 DB round-trip 検証済。Manager.exe 実機 + 本番 SMB DB での最終確認は本番DB作成と pre-release で実施**。
- bump 判断: **DB schema 変更（テーブル DROP）を含むが、撤去対象が実装ゼロ・本番未蓄積のため実データ移行リスクなし**。ユーザー向け破壊的影響なし。minor (v0.26.0 → v0.27.0)。Launcher も同 PR で非参照化（v0.11.0）。**#297 はこの PR では閉じない**（`(#297)` 文末参照。プレイ記録書込+集計=PR2/`Closes #34`、アンケート UI=PR3/`Closes #35` `Closes #297`）。

### [Manager v0.26.0] - 2026-06-06

- **(#250 PR3b) アセット復元エンジンを復元 UI へ配線（DB＋ゲームファイルの一貫時点復元）**: PR3a で入れた `AssetRestoreService`（reconcile-in-place）はエンジンのみで UI 未配線だった（「取れるが戻せない」が半分残っていた）。本 PR で復元フローに配線し、**控えのある世代を復元すると DB だけでなく games/guide もその時点へ一緒に戻す**（控えの無い世代は DBのみ）。これで #250 の核心「DB とアセットを一貫した時点に復元」が実機操作で完結する。<br>※ round2 のユーザー判断で「DBのみ/DB+ゲーム」のチェックボックス選択は廃止し、**復元＝一貫時点復元に一本化**＋**復元前の自動退避で可逆化**する形に変更（下記「round2 ユーザー判断」参照）。
  - **安全方式は reconcile-in-place（ユーザー判断）**: 当初計画の rename-retreat（games/ を退避してから再構成。peak ~2倍ディスク＋6GB の SMB コピー/削除）は本番 SMB の容量・速度都合で**不採用**。変わった分だけ pool から上書き・余剰だけ削除する省容量/SMB効率な in-place を採用。取り消しは別世代を復元し直す（全状態は自動バックアップ済、DB は safety_*.db）。エンジンの安全契約（パストラバーサル拒否／部分・破損 manifest では削除抑止／pool blob 不在は live 保持）で被害を限定。
  - **`.db`↔`.manifest` 時刻ペアリング（新 `AssetSnapshotService.FindSnapshotForBackup`）**: DB と manifest は別ファイルで厳密な紐づけ ID を持たないため、**T（= 復元する .db の作成時刻）以下で最大時刻の manifest** を対にする。**replace-in-session**（DB-only 操作は .db を新時刻で書き直すが manifest は据え置き）で `.db` 時刻が manifest より後になる事象を、この「T 以下で最大」が正しく直前フル世代へ解決する。host 一致を優先（同秒 tie 分け）、無ければ全体最新、tie-break はファイル名降順。不正ヘッダ（時刻解釈不能）は除外、SMB 不達等は null（= DBのみ復元へフォールバックし阻害しない）。auto+manual 横断。
  - **`RestoreService` は無改修**: アセット復元は `BackupSectionPanel.btnRestore_Click` のワーカーで **DB 置換成功後**に実行（復元ロックの構造は変えない）。**アセット phase は非キャンセル**（`CancellationToken.None`）＝この時点で DB は置換済で後戻り不可なので、途中キャンセルで「DB は変更されていません」と誤報告するのを避ける（reconcile は冪等で再実行可）。
  - **ペアリングは auto/manual バックアップ限定**: safety（復元の直前に退避した live DB）/ unknown（v0.20.0 以前の旧フラット形式）は DB バックアップと同一 timestamp の manifest を co-create しないため対の控えを持たない。これらを時刻ペアリングすると無関係な世代を拾うので、**trigger type を gate して safety/unknown は常に DBのみ復元**（pairedSnap=null）にする。gate は純ロジック `Services/RestorePairingPolicy.IsAssetPairingEligible`（WinForms 非依存で単体テスト可、CLAUDE.md「UI は薄く、ロジックは外へ」）に切り出し、`btnRestore_Click` から呼ぶ。allowlist 方式で将来の新 trigger type も既定 DBのみに倒す。
  - **確認ダイアログ（`RestoreConfirmForm`）の控え表示・警告**（round2 で確定形に変更）: 控えのある世代では「ゲームファイル (games/guide) もこの時点に戻す／この時点より後に追加・変更したファイルは削除される／削除前に自動退避するのでやり直せる」を**赤字で明示**＋対の控えの日時/取得PC/ファイル数を表示。控えの無い世代は「DBのみ復元（ゲームファイルは現在のまま）」。チェックボックスは round2 で廃止し、アセットも戻すか否かの判断は呼出側 (`btnRestore_Click`) が同じ `pairedSnap` から行う（真実の源は 1 つ。round4 で未使用の `RestoreAssets` プロパティを削除＝フォームは確認コードと警告表示に徹する）。
  - **復元レポート（`RestoreReportForm`）にアセット節**: optional `AssetRestoreResult`（既存呼出は無改修で compile）。コピー/変更なし/削除の件数、pool 実体欠落（MissingBlob＝起動不能/表示欠けの可能性、別世代でやり直し案内）、削除抑止（控え不完全で余剰が残りうる）を表示。アセット問題があれば reconcile がクリーンでも headline を警告色に格上げしレポートを出す（reconcile==null は MessageBox fallback に件数を併記）。DB+アセットを一緒に戻したときは前置きを「games は含まれない」前提から「一緒に復元した／控え欠落で食い違いが残りうる」へ切替。
  - **配線**: `DatabaseManager` に `AssetRestoreService`（field＋`new AssetRestoreService(_conn, _backupService)`＋public accessor）を追加。`AssetSnapshotService.EnumerateManifests`/`ReadManifestHeader` を internal 化（ペアリング解決で再利用）。
- **レビュー対応（同 PR・version 据え置き）**: (#1 High) **safety_*.db の復元でゲームファイルが消えうる穴を是正**。`FindSnapshotForBackup` は trigger type を見ないため、対の控えを持たない safety（復元 undo の主経路）/ unknown でも「T 以下で最大時刻」の fallback が無関係な世代を非 null で拾い、復元が（控えがあれば games も戻すため）reconcile の余剰削除で「その後追加したゲームファイル」を消しうる（manifestComplete な世代だと削除が走る）。**ペアリングを auto/manual に限定**し safety/unknown は常に DBのみ復元に倒した（純ロジック `RestorePairingPolicy` に切り出し + eligibility テスト 7 ケース追加）。これに伴い旧コメント/CHANGELOG/SPEC の「旧 safety_*.db は控えなし」記述（実際は PR1 以後の safety も時刻 fallback で非 null になっていた乖離）も実態に合わせて訂正。(#2 Low) `RestoreReportForm` の前置きがアセット復元**全体失敗**時に「games は含まれません」という DBのみ前提文へ落ちる矛盾を、失敗専用の前置きを分岐して是正。(#3 Low) reconcile==null の MessageBox fallback が「一部問題がありました」の定型文だけで件数が出ない（CHANGELOG の「件数併記」と乖離）のを、copied/deleted/failed/控え欠落の件数併記に修正。(#4 Low) 未使用の単一引数 ctor `RestoreConfirmForm(entry)` を削除（呼出は 2 引数版のみ）。(#5 Medium・UX) 非キャンセルなアセット phase の入口で「ゲームファイルを反映中（この処理は中断できません）」を進捗に明示（DB phase 100%→0% 戻り＋中止不能の誤解を防ぐ。中断不能自体は後戻り不可ゆえの設計どおり）。
- **レビュー round2 対応（同 PR・version 据え置き）**: (#1 Medium) `FindSnapshotForBackup` の host 優先が **時間距離を無視して候補リスト全体**から「最新の host 一致」を返していた（docstring の「同秒 tie 分け」と乖離）。games/+guide/ は SMB 上の単一共有ツリー（host 非依存）で、時点 T の最良推定は**時間的に最も近い manifest**。exact pair 欠落の degraded ケースで「別 PC の T 直前 manifest」より「同 PC の数世代前 manifest」を選び、古い世代で reconcile して T 以降に増えたファイルを誤削除しうる穴だった。**host 優先を最新秒グループ内の tie 解決に限定**し、同秒に host 一致が無ければ全体最新（時間的最近）へフォールバックするよう修正（degraded ケースの fail-first テスト追加）。(#4 Low) `RestoreReportForm` の見出しで DB 側（AnalysisFailed / DB-critical）が優先されるとアセット重大問題が見出しから消える（本文には出る）点を、見出しに「／ゲームファイルの復元にも問題あり」suffix を併記して是正。(#5 情報) degraded ペアリングで「どの時点に戻ったか」は確認ダイアログの控え日時表示（`lblAssetInfo`）と復元ログ（`manifest=…`）で事前/事後に追跡可能なため追加対応なし。
- **レビュー round2 ユーザー判断（同 PR・version 据え置き）**: review #2（既定 ON の破壊性）/ #3（アセット復元に safety_*.db 相当の退避が無い非対称）について、ユーザー判断で次の方針に確定。**(a) 「DBのみ / DB+ゲーム」チェックボックスを廃止し、復元＝一貫時点復元に一本化**＝控えのある世代は常に games/guide も戻す。代わりに確認ダイアログで「この時点より後に追加・変更したゲームファイルは削除される」旨を赤字で強く明示する（`RestoreConfirmForm` から `chkRestoreAssets` を撤去）。**(b) 破壊的 reconcile の前に現在の状態を退避して可逆化**（実装の最終形は下記 round3 で確定）。退避が不完全なら破壊的 reconcile せず DBのみ復元へ degrade（games 無変更＝安全）し明示。トレードオフ: DB+ゲーム復元時は退避（games 走査）＋reconcile（再走査）で SMB I/O が増える（ユーザー了承済、稀な操作）。
- **レビュー round3 対応＋ユーザー判断による退避の全面再設計（同 PR・version 据え置き）**: round2 の退避は `RunManualBackup`（DB+assets を手動バックアップ）を **DB 復元の前**に取っていたが、レビューで 3 つの問題が判明: (i) **DB の二重退避**（`RestoreService` が既に作る `safety_*.db` ＋手動バックアップ）、(ii) 手動バックアップは retention 対象外で**退避が無制限に蓄積**（既存 `safety_*.db` は `ApplySafetyRetention` で自動削除されるのに非対称）、(iii) 退避のアセット取得フェーズ（最長の SMB 走査＝最も中止を押しやすい）のキャンセルを `RunManualBackup` が握って `Success(Skipped)` を返すため、degrade に化けて DB が置換される（「キャンセル＝不変」違反）。**本番本格運用前の今のうちに、というユーザー判断で全面再設計**:
  - **退避を「DB 復元後・reconcile 前に、games/guide だけを `safety_*.db` と同 timestamp/host のアセット safety 控えとして取る」に変更**（`AssetSnapshotService.CreateSnapshot(ts,"safety",…)`、ts は退避された `safety_*.db` のファイル名から流用）。DB は `safety_*.db` に任せ **(i) 二重退避を解消**。退避が DB 復元後なので **(iii) 「キャンセル＝不変」の罠が構造的に消滅**（退避は非キャンセル、round3 で一旦入れた token 直読みは不要になり撤去）。退避が不完全（退避時刻の解析失敗 / 列挙失敗 / 部分取得）なら破壊的 reconcile せず DBのみ復元へ degrade。
  - **(ii) 退避の自動削除**: 新 `AssetSnapshotService.PruneSafetySnapshots`（`safety_*.db` と同じ `DefaultSafetyRetentionCount` 件で掃除＋GC）。
  - **GC が退避控えの実体を誤回収しないよう** `EnumerateManifests(includeSafety)` を新設し **GC の参照集合だけ safety 控えを含める**（ペアリング探索 `FindSnapshotForBackup`・hash キャッシュは auto/manual のまま＝review #1 の誤ペア防止を維持）。
  - **undo**: `safety_*.db` を「復元」すると DB もゲームファイルも復元前へ戻る。ペアは新 `FindSafetyManifestForBackup`（同 ts/host の **完全一致**、時刻 fallback を使わず review #1 の誤ペア穴を構造的に回避）で解決。
  - (#4 Low) 退避失敗 degrade 時の成功メッセージ「整合性に問題なし」と「DBのみ復元」の同居矛盾を「データベースのみ復元しました」に切替えて解消。(#3 non-issue) host tie-break の `entry.PcName`（ファイル名 regex）と manifest `Host`（META）は両者とも `SanitizeHostForFileName`（`_`→`-` 置換）由来で食い違わないことをコードで確認（変更なし）。これで round3 の (#1)(#2) と round2 ユーザー判断 (b) の蓄積問題が一括解消（別 issue 不要）。
- **レビュー round4 対応（同 PR・version 据え置き）**: (B-1 Low) チェックボックス廃止後に未使用化していた `RestoreConfirmForm.RestoreAssets` プロパティを削除（呼出側は同じ `pairedSnap` で判断＝二重の情報源を解消、フォームは確認コード+警告表示に徹する）。(B-2 Low) `AssetSnapshotInfo.TriggerType` の doc を `"safety"` 込みに更新。(C-2/C-3 既知の非対称をコメント明記) **新規 install 相当（live games 空）の世代を退避すると対のアセット控えが作られず、その safety_*.db の undo は DBのみ＝reconcile で増えた games が孤児として残る**（整合性チェックで検出可・データ消失なし・新規直後に過去復元→即 undo の稀ケース）／**同一秒・同一 host で 2 連続復元すると safety undo ペアが新しい採番に偏りうる**（人手では実質発生しない）。いずれも恒久対策は backup 操作 ID を `.db`/`.manifest` 双方に埋める案（**S-1**）で、ファイル名規約変更ゆえ pre-release 後の別 issue。(S-2 運用注意) undo 点 `safety_*.db` は retention `DefaultSafetyRetentionCount`(=10) 件でローリングするため、**pre-release で復元を 11 回以上反復すると古い undo 点が落ちる**（検証時は undo を 10 回以内に）。
- **レビュー round5 対応（同 PR・version 据え置き）**: (#1 Medium) 退避＋reconcile が `RestoreService.Restore` の restore-lock 解放後（**lock 外**）で走る点を整理・明記。**自己発火は構造的に起きない**（この phase 中は ProcessingDialog がモーダルで Manager 操作不能＝#295 で時間トリガ撤去済の操作単位 auto/session バックアップは発火しない）。**別 PC 同時復元**は SessionConflictHelper 警告＋DB phase の restore-lock で抑止し、reconcile phase（lock 外）の窓は multi-PC 同時復元時のみ＝稀・reconcile は live のみ書くため被害は当該 PC の当該世代限定（pool/別世代は無事）。コメント＋SPEC に明記、別 PC は pre-release F6 で実機確認、厳密化は将来の heartbeat-lease。(#2 Low-Med) `ParseSafetyTimestamp`（safety_db 名→退避 ts 抽出）が `RestoreService` の命名規約 `safety_{yyyyMMdd_HHmmss}[_host]` と暗黙結合し、ズレると退避が silent に DBのみ degrade する点を、純ロジック `RestorePairingPolicy.ParseSafetyTimestamp` へ移して **invariant 回帰テスト 8 ケース**で固定（実フォーマット・衝突 suffix・host 無し・sanitize 済 host・safety 以外→null 等）。(#3 Low) 空 games 退避（控え manifest 無し＝`ManifestPath==null`）で undo 案内が「ゲームファイルも戻せる」と過剰約束していたのを、**実際に控えが書かれた（`assetRetreatHasControl`）ときだけ**案内するよう gate（C-2 の非対称を UI 文言にも反映）。
- **レビュー round6 対応（同 PR・version 据え置き）**: (#1 Medium) **fresh install（本番移行の本命）の初回復元で undo 案内が過剰約束**だったのを是正。`games/` が「存在するが空」（DB 初期化時に dir だけ作られる）の世代を退避すると `CreateSnapshot` は新規 install 分岐（dir 自体が無い場合のみ）に入らず **0 エントリの manifest** を書く＝`ManifestPath != null` だが `FileCount==0`。round5 #3 の `assetRetreatHasControl = ManifestPath != null` がこれを「undo 可能」と誤判定し、undoHint で「ゲームファイルも戻せる」と案内するが、空 manifest の undo は `RestoreFromManifest` の空ガード（非空 live を 0 エントリで全消去する暴発防止）で Failed になる。`FileCount > 0` を gate に加えて空退避を「undo 可能」と誤案内しないようにした。(#4 Low) `reconcile==null`（整合性チェック自体が失敗/skip）でも成功 MessageBox が「整合性に問題はありませんでした」と断定していた silent pass を、「整合性チェックは実行されませんでした（詳細はログ）」に切替。(#2 Low・既知) アセット reconcile が restore-lock 解放後（lock 外）に走る窓は round5 #1 でコメント/SPEC 済、multi-PC 同時復元は pre-release F で確認・厳密化は heartbeat-lease（将来）。(#3 Low) safety_*.db↔アセット safety 控えの host 往復は各部品（`ParseSafetyTimestamp` 8 ケース / `FindSafetyManifest` の host 一致・不一致テスト）で担保、衝突 suffix の往復ズレ（C-3）は操作 ID 埋込（#305）で恒久対策。
- **UI 文言の平易化（ユーザー指摘）**: エンドユーザー向け画面の `games`/`guide` というフォルダ名併記を**中身で説明**する表現に置換＝「ゲームファイル (games/guide)」→「**ゲームファイルや初回説明の画像**」（確認ダイアログ `RestoreConfirmForm`・復元レポート `RestoreReportForm`・今すぐバックアップ通知）。docs `usage/manager.md` の呼称「案内画像」→「初回説明の画像」に統一。**さらに復元レポートの「直し方の手順」を GUI 操作主役に並べ替え**（ユーザー指摘: 部員はふだん Manager(GUI) で操作し、生フォルダをエクスプローラーで触る機会がほぼ無い。PR3b で復元/undo が GUI 完結するようになったため）。「控えのある世代を『復元』して DB+ゲームファイルをそろえる」「safety_*.db を『復元』して undo」を手順 2-3 に格上げし、**手動フォルダコピーは「最終手段・ふだんは使いません」に格下げ**。孤児フォルダは「起動に影響しないので基本そのまま、容量が気になるときだけ手動削除」を前面に。手動操作箇所のみフォルダ名 `games` を残置（その操作はエクスプローラーで実体を触るため）。コード内コメント（開発者向け）は技術名のまま。**さらに確認ダイアログ/レポートを「対比構造」に**（ユーザー指摘）＝「**ゲームの登録情報（データベース）だけでなく、ゲームファイル本体など、ディスク上のファイルも**この時点に戻す」と、何に対して「も」なのかを 1 文で明示（DB＝概要 vs ファイル＝本体）。**ゲーム本体と初回説明の画像を同列に並べると主従が崩れて不自然**なため、主役のゲームファイル本体を代表に「など」で包括する形に（初回説明の画像は「ディスク上のファイル」に含め、内訳は復元レポートで個別表示）。確認ダイアログは行増に合わせ `RestoreConfirmForm` の `lblAssetInfo` 高さ＋下段コントロール位置を再調整。**「退避して戻せる」案内の重複も解消**（ユーザー指摘）＝確認ダイアログに「退避から戻せる」が警告詳細 (`lblWarningDetail2/3`) とアセット警告 (`lblAssetInfo` の※) の 2 か所あったのを、復元全体の安全網として `lblWarningDetail` に 1 本化（PR3b 前の DB-only 前提「現在のデータベースは退避／退避ファイルから手動で戻す」も「いまの状態を退避／safety_*.db を『復元』で戻せる」に更新）、`lblAssetInfo` の※（やり直し案内）を撤去。`lblAssetInfo` は 4 行に戻り高さ・下段位置も元へ。
- 検証: Manager build 緑 / **テスト 186 件合格**（PR3b 新規 22 件＝ペアリング 10: T以下で最大 / replace-in-session(db>manifest) / host一致優先 / **host 一致でも時間的に近い別 host を優先（degraded）** / host無し→全体最新 / T以前なし→null / 空 / auto+manual 横断 / 同秒tie→名前降順 / 不正ヘッダ skip ＋ eligibility 7 ＋ **safety undo 完全一致 3**（一致 / 不一致→null / auto・manual 無視）＋ **GC が safety 控え blob を保護 1** ＋ **退避控え retention 1** ＋ **ParseSafetyTimestamp invariant 8**、いずれも fail-first）。**※実機 UI（控えあり世代の警告ダイアログ・DB 復元→ゲームファイル退避→reconcile→レポート・DB+assets round-trip・退避失敗で DBのみ degrade・本番 SMB 体感・safety_*.db 復元で DB もゲームファイルも当時へ戻る undo）は pre-release で目視（F1〜F7）＝本 PR は #250 の実機 UI 初確認対象。**
- bump 判断: ユーザー向け機能追加（復元時に DB+ゲームファイルを一貫時点へ戻せるよう拡張）。破壊的変更なし。schema 変更なし。minor (v0.25.0 → v0.26.0)。Launcher/Updater は無関係。**#250 はこの PR では閉じない**（PR3c [整合性レポートの半自動復元連携] の要否をマージ後に判断＝それを見て #250 を手動クローズ or PR3c 実施）。

### [Manager v0.25.0] - 2026-06-04

- **(#250 PR3a) アセット復元エンジン `AssetRestoreService` を追加**: バックアップは PR1/PR2 で「DB + アセット(games/+guide/)を共有プール(CAS)＋manifest」で取れるが、**復元は DB しか戻せなかった**（「取れるが戻せない」）。本 PR で manifest(relpath→hash) を読み `asset_pool/<hash>` を live の games/+guide/ へ書き戻す**エンジン**を追加（= `AssetSnapshotService.CreateSnapshot` の逆操作）。**まだ UI には未配線**（2モードUI・ペアリング・safety 退避は PR3b）。
  - **reconcile-in-place**: live が既に一致するファイル(size+mtime)は再コピーせず skip（SMB 再読込回避）、違う/欠落だけ pool から copy、manifest に無い余剰 live は削除し、ツリーを manifest と完全一致させる。**コピーを削除より先**に行い、pool は内容アドレスで不変なので途中中断でも「置換前に live を消さない」。コピー後に mtime を manifest 値に刻む（次回 snapshot の cache hit + 再復元 skip を成立＝`HashAndStore` の配置時刻トリックの逆）。
  - **安全側設計**: relpath を `games/`/`guide/` 配下に限定（**パストラバーサル拒否**で install dir 外への書込/削除を防止）、空 manifest で非空ツリーを消す暴発を**ガード**（`allowEmpty`）、pool blob 不在は per-file 失敗に集計し**該当 live を保持**（削除しない）、reparse point / `.pending-delete-*` は削除対象外（外部実体・ゲーム削除 retry を壊さない）。best-effort（per-file は throw せず `AssetRestoreResult` に集計、`IsPartial` で警告）。long-path/SMB 安全（`EnsureLongPath`/`ForceLongPath`）。
  - **フォーマット SoT 一本化**: manifest 行解釈と pool パスを `AssetSnapshotService.TryParseManifestEntryLine`/`PoolPathFor`（internal 化）に集約し、`LoadHashCache`/`GarbageCollectPool`/新 `AssetRestoreService` が共用（書き手 `WriteManifest` と乖離させない）。既存 snapshot テストで回帰担保。
- **レビュー対応（同 PR・version 据え置き）**: (#1 Medium) `EnumerateLiveFiles` の reparse 判定が dir のみで、snapshot が捕捉しない reparse **ファイル**を余剰削除で消しうる非対称（doc の「reparse は削除対象外」と不一致）を是正＝ファイル列挙にも reparse 判定を入れ、snapshot/restore どちらも reparse 実体を「触らない」で対称化。(#2 Low-Med) SoT リファクタで `GarbageCollectPool` の参照抽出が strict 化し、**破損 manifest 行が blob を保護しなくなった**退行（旧実装は tab があれば先頭フィールドを hash として保護）を是正＝GC は「保護側に倒す」とし、strict parse 失敗行でも META でなく先頭フィールドがあれば hash 候補として参照集合に入れる（restore/cache は strict のまま）。破損行で参照中 blob を誤 GC する穴を塞ぐ（fail-first テスト追加）。(#3 Low) `AssetRestoreService` の未使用 `SettingsRepository` 注入を除去（restore は設定を gate しない＝YAGNI、ctor は `(conn, backup)`）。
- **レビュー round2 対応（同 PR・version 据え置き）**: **「manifest が完全な desired tree を表していないのに restore が"余剰"として live を削除する」同根のデータ消失2点**を是正。(#1 High) **部分取得 (IsPartial) 世代から復元すると、snapshot が取りこぼした live が"余剰"判定で恒久削除される**。manifest META 行に `skippedDir/skippedFile` を追記して**部分取得を永続化**し（旧 6 フィールド META は complete 扱い＝後方互換）、partial 世代の復元では**余剰削除を抑止**。(#2 High) **破損 manifest 行（entry の parse 失敗）を silent skip すると、対応する live が"余剰"判定で削除され `IsPartial` にも乗らない silent データ消失**。破損行を `failed` 計上（IsPartial 可視化）し、破損行が1行でもあれば**削除フェーズ全体を抑止**（GC が「1件でも読めなければ全GC中止」とした安全側ポリシーを restore にも適用）。抑止は新 `AssetRestoreResult.DeletionSuppressed` で呼出側/UI に伝える（live に余剰が残りうる＝完全一致でない旨）。(#4 Low) pool ルート dir 名 `"asset_pool"` のリテラル重複を `AssetSnapshotService.PoolDirName`（internal 化）共用に集約（SoT 一本化の趣旨に統一）。据え置き: #5（進捗報告が copy フェーズのみ＝削除主体で 100% 後に無進捗に見える、UI 配線の PR3b で対応）/ #6（`preferContentFromDir` 未使用は plan の rename-retreat 用予約＝具体的用途ありで保持、用途無しだった SettingsRepository 除去と非対称だが意図的）。**全破損 manifest は entries 0 件で既存の空ガードが救う**（それも安全側）も確認。
- **レビュー round3 対応（同 PR・version 据え置き）**: (#1 Low-Med) round2 #1 の判定軸が「META 8 フィールドか」だったため、**PR3a 以前の旧 6 フィールド META 世代**（本番 2026-05-27〜の世代等）が当時 partial でも無条件 complete に倒れ、PR3b 配線後にそこから復元すると旧取りこぼし live を誤削除しうる穴を是正。`IsMetaLinePartial`→`TryReadMetaSkipped` にし、**8 フィールドで skipped==0 と明示確認できたときだけ complete**（旧形式・META 欠落・判定不能はすべて削除抑止＝「不明なら消さない」安全側既定）に統一。(#3 Low) `TryParseManifestEntryLine` に hash 長検証（SHA-256 hex 64 桁）を追加し、不正 hash 行を破損行扱い（削除抑止＋failed 可視化、`PoolPathFor` の `Substring` crash も防止）。(#2 Low) `SafeGetDirs` の例外握り潰しに Warn ログを追加（`SafeGetFiles` と対称）。据え置き: #4（pool root を manifest 相対でなく現バックアップ先から導出＝任意パス manifest 復元 UI を作る PR3b で co-location 検証を入れる）/ #5（進捗 UI、PR3b）。
- 検証: Manager build 緑 / **テスト 156 件合格**（PR3a 12 + round1 1 + round2 2 + round3 2 [旧形式 META で削除抑止 / 不正 hash 行で削除抑止]、いずれも fail-first）。既存 snapshot テストも緑（META 8 フィールド化・SoT リファクタ無回帰）。
- bump 判断: 新サービス追加（#250 PR3 の土台）。UI 未配線でユーザー向け挙動は不変だが、独立した機能追加なので minor (v0.24.0 → v0.25.0)。schema 変更なし。**#250 は閉じない**（PR3b/c 残）。Launcher/Updater は無関係。

### [Manager v0.24.0] - 2026-06-04

- **(#250 PR2) 復元の整合性チェックを `guide/`（初回説明スライド画像）にも拡張**: 旧 `RestoreReconciliationService` は復元後に **`games/` しか突き合わせず**、別時点の DB を復元すると games/ のズレ（起動できないゲーム／無い版／孤児フォルダ）は検出されるのに、`intro_slides.image_path`（`guide/<file>`）が指す画像の欠落は**無警告（silent）**という非対称があった（Codex PR #274 P1）。「DB だけ復元 → 初回説明スライドが存在しない画像を指す」silent breakage を塞ぐため、intro_slides の画像参照も突き合わせて欠落を検出（新 finding `BrokenIntroSlides`、復元レポートに「初回説明スライドの画像の欠落」セクションを追加）。画像欠落はスライド表示が劣化するだけで起動を妨げないため **warning 扱い**（`HasCriticalFindings` には含めず、games の thumbnail/background と同格。text-only スライド＝ImagePath 空は対象外）。
- **整合性チェックを手動再実行できる「整合性チェック」ボタンを追加（バックアップタブ）**: 整合性チェックは **復元直後にしか走らない**（`Analyze()` の呼び出しは `btnRestore_Click` 内の 1 箇所のみ＝通常起動では走らない）。一方、復元レポートの手順は「修正後に **Manager を再起動するとこのチェックが再度かかります**」と案内しており、これは**不正確（再起動では再チェックされない）**だった。バックアップタブに「整合性チェック」ボタンを追加し、復元を伴わず現在の DB ↔ `games/`/`guide/` のズレをオンデマンドで再チェック可能に。あわせて復元レポートの手順③を「**バックアップ画面の『整合性チェック』ボタンで再チェック**（再起動では再チェックされない）」に修正。`RestoreReportForm` を **復元後／手動の 2 モード対応**にし、手動時は「復元完了」等の復元前提の文言を避ける（headline・前置き・手順を切替）。
- **復元レポートの「退避ファイルから復元」案内を是正（ユーザー指摘）**: `safety_*.db` は復元の直前に退避した DB ＝**復元前の状態**。「今の games に合わせたいなら safety から再復元が確実」とだけ書くのは、何か問題があって復元したケースでは**その問題ごと元に戻す**ことになり誤誘導だった。「これは**今回の復元を取り消す**操作で、元の DB に問題があったならその問題も戻る」と明示し、当時の games を補う手順（2〜3）を本筋として案内。手動チェック（復元してない）モードでは safety 文言自体を出さず「履歴から合致時点を復元」に切替。
- **バックアップタブのグループを 3→2 箱に統合（ユーザー指摘で「バックアップ操作」と「操作」の二重が気持ち悪い）**: 下の「操作」箱を廃止し、**復元・削除・整合性チェックを「バックアップ履歴」の表の下へ移動**（いずれも選択行に対する操作なので表と同じ箱が自然）。保存先パスは最下部の枠なしラベルへ。→ 「バックアップ操作」＋「バックアップ履歴（表＋操作ボタン）」の 2 箱に。
- **テスト基盤**: `PathManager` に test seam（`SetBaseDirectoryForTest`/`ResetBaseDirectoryForTest`、internal）を追加し、PathManager 静的に依存していた `RestoreReconciliationService` を実 install を触らず一時 install dir で検証可能に（#239）。**reconciliation の初テスト**を新規追加（guide 画像欠落→`BrokenIntroSlides` 検出＋非 critical / 全存在→非検出、fail-first）。
- **レビュー対応（同 PR・version 据え置き）**: (#1 Medium) **非表示スライド（`is_visible=0`）を対象外に**。`GetAllIntroSlides()` は全件返すが Launcher は `is_visible=1` のみ表示するため、非表示スライドの画像欠落を `BrokenIntroSlides` に上げると「画像なしで表示されます」というレポート文言が虚偽になり可視 breakage も無い。`slide.IsVisible` で skip（fail-first テスト追加）。(#2 Low) 画像欠落だけが finding のとき、無関係な「余分なフォルダを削除」案内しか出ず修正手順が無かったのを是正＝孤児削除案内は孤児がある時だけに限定し、画像欠落の直し方（当時の games/guide から補う／編集で貼り直す）を追記。(#3 Low) 手動「整合性チェック」ボタンの `Analyze()`（SMB 上で全ゲーム×全版を走査）に wait カーソルを追加（完全非同期化は将来課題、SMB 体感は pre-release）。(#4 Low) `BrokenIntroSlides.ExpectedPath` の区切り混在（`…\guide/file`）を `Replace('/', Path.DirectorySeparatorChar)` で解消（表示のみ、検出は元々正しい）。
- **レビュー round2 対応（同 PR・version 据え置き）**: (#1 Medium) レポート文言「画像なしで表示されます」が image-only スライドでは虚偽だったのを是正。Launcher の `_load_slides` は **本文なし かつ 画像なしのスライドを丸ごと除外**する（ブランクページ抑止）ため、本文のないスライドの画像欠落は「画像なし表示」でなく**スライドごと消える**。文言を「本文のあるスライドは画像なしで表示／本文のないスライドはイントロガイドから外れる」に一般化。(#2 Low) 手動チェック（postRestore=false）モードの前置き「games フォルダは**復元されません**」が復元してない文脈にそぐわないのを「**含まれません**」に一般化。(#3 Low) 画像欠落だけの finding のとき手順1「Launcher を閉じる」が無関係に浮くのを、フォルダ差し替え/削除が要る finding（起動不能/無い版/孤児）のときだけ出すよう条件化。据え置き: #4（同一画像を複数スライドが参照→N 件表示＝スライド単位の列挙は「N スライドが影響」を正しく示すので妥当、per-slide のまま）。
- 検証: Manager build 緑 / **テスト 139 件合格**（#250 PR2 新規 3 件: guide 欠落検出＋非 critical / 全存在→非検出 / 非表示スライドは非検出、いずれも fail-first）。**※整合性チェックボタンの実機 UI（ボタン配置・レポート文言の 2 モード切替・SMB 体感）は pre-release で目視。**
- bump 判断: ユーザー向け挙動の機能追加（復元レポートに guide 欠落検出を追加）。破壊的変更なし。schema 変更なし。minor (v0.23.0 → v0.24.0)。Launcher/Updater は無関係。**#250 はまだ閉じない**（PR3＝DB+アセット一式の復元 2 モードが残るため）。

### [Manager v0.23.0] - 2026-06-04

- **(#299) 操作単位バックアップの進捗を「非ブロッキング＋下部ステータスバー統合」に改装**: #295 では games/guide を変える操作の直後にモーダル進捗ダイアログ（「バックアップを作成中」）が出て、~6GB の SMB 走査が終わるまでメインウィンドウが操作不能だった。これを撤去し、**バックアップはバックグラウンド worker で実行・操作はそのまま継続可**に。進捗は既存ステータスバー（statusStrip1）に統合した `[バックアップ中...][中止][進捗バー][N%][ファイル名]` で表示（別バー＝2 段にせず 1 段、左詰め）。
  - **コアレス**: 実行中に来た変更は dirty フラグ＋includeAssets を OR 蓄積し、現行完了後に蓄積分でもう 1 回だけ走る（単一 worker で直列、CAS＋replace-in-session で最終世代は必ず正しい）。状態遷移を `SessionBackupCoordinator.TryStartRun`/`TryContinue` に切り出してスレッド無しで単体テスト（新規コアレス 2 件）。#295 レビューで保留していた perf/debounce 論点（Medium #1 / M1）をこの非ブロッキング＋コアレスで解消。
  - **中止**: ステータスバーの「中止」で進行中バックアップをキャンセル（変更データ自体は保存済み＝バックアップだけ後回し）。**未バックアップ時**は警告＋「**今すぐバックアップ**」ボタンで 1 クリック復旧（対処法を提示）。
  - **閉じる確認**: バックアップ中に × すると「バックアップを中止して閉じますか？」（既定=いいえ）。閉じても live は無事（次回起動の最初の操作で取り直し）。
  - 進捗 UI コールバック `ProgressReporter`/`BackupRunningChanged`/`IsBackupRunning`/`CancelCurrentBackup` を coordinator に追加、MainForm が UI スレッドへ marshal。
  - **実機フィードバック反映**: ①進捗ラベル見切れ→AutoSize ②2 段→1 段（ステータスバー統合）③全部左詰め ④ファイル名(可変幅)を末尾に置き中止ボタンの per-file 高速移動を解消（phase 固定文言「バックアップ中...」で中止位置を完全固定）⑤進捗バーとファイル名の間に固定幅の % 表示 ⑥中止/今すぐバックアップを **ToolStripButton + 専用レンダラー(`BorderedStatusButtonRenderer`)で枠付き表示**（実 Button のホスト `ToolStripControlHost` は StatusStrip のレイアウト破壊で他 item 非表示 + 残像を招くため不採用）。
- **(#299関連) 共有 ProcessingDialog の進捗に数字の % を併記**: 手動バックアップ・フォルダコピー・復元・アップデート適用・削除など `ProcessingDialog` を使う全モーダル進捗で「フェーズ + N%」を表示（定量進捗のときだけ。Marquee=不定のときは出さない）。
- **(UX) ユーザー表示の「控え/控える」→「バックアップ」に統一**: 「控える」は馴染みが薄く分かりにくいとのユーザー指摘。ステータス警告・restore-lock 延期メッセージ・`docs/usage/*` の名詞「控え」/動詞「控える」を「バックアップ」へ（コメント・Logger の内部概念は据え置き）。
- **レビュー対応（非ブロッキング化で新たに開いた並行性の堅牢化）**: モーダル撤去でバックアップ中もユーザーが `games/` を編集できるようになったため、その副作用を 4 点修正。
  - **(C-1 / Medium) 走査中のファイル消失で世代まるごと Failed → 当該ファイルだけ best-effort skip**: `AssetSnapshotService.WalkTree` の per-file 経路に try/catch が無く、走査中のファイルが並行操作（ゲーム削除 / 版up）で消える / 掴まれると `HashAndStore` の `FileStream.Open` が例外を投げ、`CreateSnapshot` の catch で**世代まるごと Failed**（=~6GB 再走査 + 「⚠ バックアップ失敗」のチラつき）になっていた。dir 列挙失敗と同じ best-effort 思想で当該ファイルだけ skip（`SkippedFileCount`）し、世代は **IsPartial Success** に留める（消えたファイルは次のコアレス再走査で削除後ツリーとして整合）。キャンセル（OCE）は skip にせず伝播。
  - **(B-1) 「中止」がコアレス済み pending を止めなかった → 止める**: `CancelCurrentBackup` が現 iteration の `_cts` のみ cancel し、`_dirty` が立っていると `TryContinue` が次 iteration を新 cts で起動してストリップが消えず再走査が走っていた。cancel 時に `_dirty`/`_pendingIncludeAssets` もクリア（「中止＝今は止める」、新変更が来れば次操作で再 trigger）。
  - **(D-1) worker 起動失敗で稼働フラグが永久 true → 巻き戻し**: `TryStartRun` が `_workerRunning=true` を立てた後の `Task.Run` が投げると（スレッドプール枯渇等）`WorkerLoop` が走らずフラグが固まり、以降の自動バックアップが無言停止 + `IsBackupRunning` 常時 true で閉じる確認が誤発火。`Task.Run` を try/catch して失敗時にフラグを巻き戻す。
  - **(A-1 / Low) DB フェーズの進捗 Detail がフルパス → ファイル名**: `BackupService` の 0% / 100% 報告が `destinationPath`（フルパス）を Detail に入れ、ストリップのファイル名スロットに長いパスが一瞬出ていた。`Path.GetFileName` でファイル名のみに。
  - **据え置き（記録のみ）**: D-2（`BackupRunningChanged` の worker 跨ぎ表示順レース）は次 worker の進捗報告で自己回復するため未対応。E-1（`ProcessingDialog` の % は全モーダルに波及）は設計どおりで、復元/更新の進捗に不自然な `0%` が出ないかは pre-release 実機確認項目。
- **レビュー round2 対応**: ①(#1) `SkippedFileCount` を `SkippedDirCount` と分離し UI 文言を「フォルダ N 個 / ファイル N 個」に修正（round1 で skip 総数を `skippedDirCount` に合算したため、ファイル消失 skip を「N 個のフォルダ」と誤報する回帰を是正）。②(#4) per-file の try スコープを実 I/O のみに絞る（`entries.Add`/`progress.Report` まで囲むと、それらの例外を「ファイル消失」と誤計上し entries 投入と skip の二重カウントになるため後続は try 外へ）。③(#2) 非ブロッキング化で worker 稼働中も「復元」を起動できるようになったので、復元前に進行中の自動バックアップを協調キャンセル（live DB の `File.Replace` 置換と worker の DB コピーの衝突回避。手動バックアップは共有プール CAS + 24h grace で同時実行安全のため gate せず）。④(#3) 復元は live を置換する**前**に復元元を `PRAGMA quick_check` で検証し、壊れ / 不完全 .db（worker の DB フェーズ中 abrupt exit 残骸を含む。`BackupCatalogService` は list 時 quick_check を省くため復元候補に出うる）を置換前に弾く（live 無傷で中止、SMB 越しのコピー破損一般への防御でもある）。⑤(#6) CHANGELOG のテスト件数の中間値「計 129」を除去。据え置き: #5（D-2 = `BackupRunningChanged` 表示順レース、自己回復のため再確認のうえ未対応）。
- **レビュー round3 対応**: ①(#1 / High) **UI 凍結の再来を修正**。`SessionAssetCaptureFailed` の getter だけが重い `_gate`（RunSessionBackup が ~6GB 走査の間ずっと保持）をロックしており、その唯一の UI 読み取りが `BackupRunningChanged(false)` コールバック内 → worker1 完了の apply が UI 処理される前に worker2 が `_gate` を取ると、UI が worker2 の走査完了までフリーズ（= #299 が消したはずの凍結）。フラグを `volatile bool` 化し getter をロックフリーにして UI を `_gate` から切り離した（単一 bool で原子読み不要、書込は `_gate` 下のまま）。②(#6) DB-only 実行中にアセット変更が pending の状態で「中止」すると、破棄される pending アセットが無警告で未バックアップのまま落ちる穴を、中止時に pending にアセットが残れば未バックアップ警告を立てて解消。③(#3 / ユーザー判断 A) 復元前 quick_check の「非 ok は一律中止」を **段階化**: open すらできない破損（切り詰め/非 DB）は中止のまま、**open はできるが quick_check 非 ok** な「不健全」バックアップは「それでも復元しますか？」を UI 確認し Yes のときだけ続行（`RestoreService.CheckIntegrity` + `allowIntegrityWarnings`）。「復元＝最後の手段」で唯一のバックアップが少し不健全な災害時に override を残す（safety 退避済で可逆）。据え置き（記録のみ）: #2（一時ロックで完全→部分 manifest 置換＝SMB+常駐AV では「Failed で前 manifest 温存」案の方が「毎回 ~6GB 再走査で一度も完全世代が取れない」悪化を招くため現挙動維持。live 無傷＋前セッション完全世代 retention＋IsPartial 警告が安全網。pre-release で部分化頻度を確認）/ #4（協調キャンセルは fire-and-forget だが、復元の safety 退避+temp コピー+ClearAllPools+File.Replace の IOException fallback の多段で worker のサブ秒 DB コピーは置換前に解放され実害ほぼ無し）/ #5（「今すぐバックアップ」が auto 設定で gate＝auto OFF では worker も走らず警告自体ほぼ出ない限定ケース）。
- **レビュー round4 対応**: ①(H-1 / High) 復元 vs worker の `File.Replace` 衝突を緩和。非ブロッキング化で復元前に協調キャンセルした worker が live DB ハンドルを解放しきる前に置換へ到達する狭い窓があった（worker の DB コピーはサブ秒で復元の退避+コピー+ClearAllPools の間に解放される公算が高いが**同期保証は無い**）。共有違反（IOException）を最大 ~800ms 短くリトライしてから既存 fallback に落とす `ReplaceWithSharingRetry` を追加（transient な worker 解放待ちは置換成功・永続 IOException は従来どおり Delete+Move fallback）。②(M-1 / Medium) **IsPartial（一部ファイル skip）を sticky 警告化**。C-1 の per-file skip で部分取得経路が増えたが、IsPartial は Kind=Success のため healthy 扱いになり「ファイル欠落世代でも次の DB-only 緑✓で『完全に控えた』と誤認」する穴があった。`_sessionAssetCaptureFailed` を IsPartial でも立て、回復は**完全**アセット成功時のみに（round3 #2 deferred の『IsPartial 警告が安全網』を、警告が 1 回で消える点を是正して強化）。③(L-1 / Low) 復元起点の協調キャンセルは「未バックアップ」警告を立てない（これから現データを置換するので spurious）＝`CancelCurrentBackup(flagPendingAssetsUnhealthy:false)`。④(L-3 / Low) `ProcessingDialog` の % 併記で `_lastMessage` 未到達（空）時に先頭スペース付き "  0%" にならないよう結合を分離。据え置き（記録のみ）: M-2（コアレス遷移境界での中止取りこぼし＝TryContinue が true を返した直後〜新 cts 生成前の microsecond 窓 / 中止フラグと worker 完了の別ロック last-writer。いずれも次操作で自己回復、窓が極小のため未対応）/ L-2（`_tsBackupPercent` 固定幅 40px が高 DPI で "100%" clip しうる＝実機 DPI 確認項目、本番 PC は標準 DPI 想定）。
- 検証: Manager build 緑 / **テスト 136 件合格**（コアレス 2 + round1 2 [B-1/C-1] + round2 1 [復元が壊れ/不完全を置換前に弾く] + round3 3 [#6 / `CheckIntegrity` / `allowIntegrityWarnings`] + round4 2 [M-1 部分取得が sticky+完全成功で回復 / L-1 復元起点キャンセルは警告を立てない]、いずれも fail-first で確認）。**※実機（UIは実機で確認）: 非ブロッキングで操作継続・進捗 1 段表示・中止→未バックアップ警告＋今すぐバックアップで復旧・閉じる確認、を目視済（残像/見切れ/枠なしの実機フィードバックは反映済）。本番 SMB での体感・多 PC・並行編集 churn（C-1/M-1）・worker 稼働中の復元/手動同時実行（H-1/#2/#4）・連続アセット操作直後の UI 応答（#1）・整合性警告の確認ダイアログ（#3）・% 表示の高 DPI clip（L-2）は pre-release 全体テストで。**
- bump 判断: ユーザー向け挙動変更（バックアップ進捗 UX の非ブロッキング化）。破壊的変更なし。minor (v0.22.0 → v0.23.0)。レビュー対応は同 PR 内のため version 据え置き（1 PR 1 bump）。Launcher/Updater は無関係。

### [Manager v0.22.0] - 2026-06-03

#### Changed (#295 — 自動バックアップを「起動時間隔」→「変更時・操作単位 / replace-in-session」に再設計)

- **自動バックアップのトリガを「Manager 起動時の時間間隔」から「データ変更操作の成功直後」に変更。** 旧方式は「変更→閉じる→次の起動までに DB が壊れると、その変更が一度も控えられない」穴があった。新方式はゲーム追加/編集/版up/削除・ストアセクション・イントロスライド等の**操作が成功した直後に**バックアップを取るので、その作業がその場で守られる。
- **1 Manager 起動 = 1 自動世代（replace-in-session）。** 同一セッション内で次の操作が控えるとき、このセッションが前回書いた自動世代（`.db` + ペア `.manifest`）を消して上書きする。セッション最初の控えは前セッションの世代を消さない。retention（`backup_retention_count`）は「直近 N **セッション**」を残す（旧「直近 N **編集**」の食い潰しを解消）。手動バックアップは従来どおり別枠で温存（不変）。
- **DB とゲーム本体の非対称性を使う。** DB（~124KB）は毎操作控える（サブ秒、バックグラウンド）。重い games/guide のアセット取得（~6GB の SMB 走査）は **games/guide を実際に変える操作のときだけ**走らせる（ゲーム追加・版up・ゲーム削除・id rename・外部画像取込・スライド画像追加/差替/削除）。メタデータのみの編集（タイトル変更・ストアセクション・スライド本文）は DB だけ控えて重い走査を skip する。各 Form が `AssetsChangedOnDisk` で「ディスクのゲーム本体を触ったか」を正確に返し、不要な走査を避ける。
- **新規 `Services/SessionBackupCoordinator.cs`**（AGENTS: 新ファイル/責務分離）: セッション状態（この起動の前回 `.db`/`.manifest` パス、メモリ保持）+ enable gate + UI 段取りを持つ。実バイト書き出しは `BackupService` に委譲し WinForms 依存をここに閉じる。`RunAfterOperation(owner, assetsChanged, label)` を各コール地点が 1 行で呼ぶ。アセット変更操作は短い進捗ダイアログ、DB-only 操作はバックグラウンド（モーダル無し、ステータスバーに「✓ 変更をバックアップしました」）。**best-effort**: バックアップ失敗は操作を巻き戻さず（操作コミット後に走る）、例外を投げず `Logger.Warn` + ステータス表示のみ。
- **`BackupService`**: `RunSessionBackup(includeAssets, …)` を追加（`RunBackupCore` に `includeAssets` ガード）。**撤去**: `IsAutoBackupDue` / `RunAutoBackupIfDue` / `RollbackLeaseOnFailure`、`MainForm.StartAutoBackupIfDue`（起動時トリガ）、`SettingsRepository.TryAcquireBackupLease`（同時編集は `SessionConflictHelper` が警告）。**lease 撤去の多ホスト影響（round7 #2 で正確化）**: 旧 lease は `BEGIN IMMEDIATE` で auto を interval 毎・全ホスト 1 回に律速する間接的排他で、これにより並行 GC が起きにくかった。操作単位化 + lease 撤去で「全ホストが毎操作 backup+GC」になり**多ホスト並行 GC の窓は拡大**。grace で直近書込 blob を守るが、**初回フル ingest(~6GB SMB)が grace を超える間に他ホストの GC が走ると取得中 blob を誤回収しうる窓(= #250 round8 C2)**があった。**対応（round7 #2、ユーザー判断）: `GcGracePeriod` を 1h→24h に延長して塞いだ**＝現実的 ingest（数十分〜1h 級）は 24h を超えず保護される（24h 超の非現実的 ingest だけ heartbeat-lease が要る #250 領域に残る）。なお同 PC 重複起動は Program.cs の Named Mutex で物理 block 済、別 PC 同時編集は SessionConflictHelper が警告するので、C2 に至るには「警告を無視した別 PC 同時編集 + 24h 超 ingest」の二重条件が要る。被害も限定的で、GC は pool のみ対象＝壊れるのは当該バックアップ世代だけ（live games/ は無事、次回 backup で再コピーされ自己回復）。`last_backup_at` はトリガ gate ではなくなったが「最終バックアップ」表示用に書き続ける。
- **設定タブ簡素化**: 時間間隔の UI（`numBackupInterval` / `cmbBackupIntervalUnit` / ラベル）と key（`backup_auto_interval_hours` / `backup_auto_interval_unit`）を撤去。残すのはチェック「**変更があったら自動でバックアップする**」（旧 `backup_auto_enabled` を再定義、"false" 厳密一致のみ無効）＋ 保持世代数 ＋ 保存先。
- **レビュー対応 (round 2)**: ①**ゲーム本体の控え失敗/部分取得を「✓ 成功」に潰さない**＝旧 `StartAutoBackupIfDue` が持っていた可視化 (round5 #1 / round8 C1) を `SessionBackupCoordinator.DescribeResult` に移植。DB 成功でもアセットが `IsFailed`/`IsAnomaly`/`IsPartial` なら緑「✓」ではなく橙警告（SMB 一過性不達等でゲーム本体が控えられていないのに誤認させない）（High #1）。②**失敗ステータスを sticky 化**＝成功は 7 秒で消える transient、失敗/警告は `autoRevert:false` で残す（保存先設定ミス等の恒常失敗の見落とし防止。旧 modal 通知の代替、操作単位なので modal 連発は避ける）（M #3）。③**操作のたびにバックアップタブを再描画**（履歴/最終バックアップ表示の stale 解消）（M #4）。④**自動バックアップ削除時の `last_backup_at` rewind を撤去**＝撤去済 `IsAutoBackupDue` 前提のデッドロジック（#295 で last_backup_at はトリガ gate でなく表示も GetLastSuccess 由来）（M #2）。⑤撤去済メンバ参照の stale コメント整理（M #6）。
- **レビュー対応 (round 3)**: ⑥**同一セッション 2 回目以降のアセット操作が失敗/キャンセルすると直前の控えを消す High バグを修正**＝success ブロックで前 `.manifest` 削除を `result.IsSuccess`(=DB の成否のみ) で行っていたため、includeAssets=true でもアセット取得が失敗/キャンセル(Skipped)だと、新 manifest が無いのに前 manifest を削除し「DB はあるがゲーム本体の控えが 0 件」になった。削除と `_sessionAutoManifestPath` 更新を同一述語 `newManifestWritten`(=includeAssets かつアセット IsSuccess) に揃え、未成功なら前世代を温存（round2 #1 が可視化で守った不変条件を実データ側でも担保）。⑦**ストアセクション/スライドの並び替え (display_order 変更) をバックアップトリガに配線**＝追加/編集/削除のみ wired で並び替えが抜けており「変更があったら控える」宣言と乖離していた (DB-only)。⑧**ゲーム追加/編集の「成功メッセージ→バックアップ」順を版up/削除と統一**（成果確認を先に見せ、重い ~6GB 進捗で確認を遅らせない）。⑨SettingsKeys の撤去済ハンドラ参照コメントの掃き残し整理、SPEC 変更履歴のテスト件数を CHANGELOG と一致 (1 PR 1 bump 加筆)。
- **レビュー対応 (round 4)**: ⑩**アセット走査を「キャンセル」すると緑✓が出る High バグを修正**＝`assetsChanged:true` の操作は進捗ダイアログ（キャンセルボタン既定表示）でゲーム本体を走査するが、ユーザーが中断すると `CreateSnapshot` が OCE を握って `Skipped` を返し、DB は成功なので `DescribeResult` が緑「✓ 変更をバックアップしました」を表示していた（round2 #1 の「ゲーム本体未控えを成功と誤認させない」不変条件を、本 PR が新たに導入したキャンセル可能 modal 経由で破る新規回帰）。`DescribeResult`/`ReportResult` に `assetsRequested` を渡し、**ゲーム本体の控えを要求した操作でアセットが非成功（キャンセル/無効/null）なら橙警告**に倒す。⑪設定タブの撤去済 `_prevIntervalUnit` の orphan コメント掃き残しを整理（Low #4）。**PR3 申し送り (Medium #2)**: `.db`/`.manifest` の世代ペアは DB-only 末尾セッションで timestamp が一致しない（replace-in-session で `.db` だけ更新し manifest は温存するため）＝アセット復元は timestamp 一致でペアリングできない点を #250 にコメント。retention テストの同一秒衝突懸念 (Low #5) は `.db` 側にも衝突回避ループ (`_2`/`_3`) があり非該当。
- **レビュー対応 (round 5)**: ⑫**sticky 警告がセッション内の後続 DB-only 成功に上書きされ消える Medium バグを修正**＝アセット控えが SMB 一過性不達で失敗し橙 sticky 警告が出た後、メタデータのみ編集（DB-only）を 1 回でも行うと緑「✓」が上書きし 7 秒後に消える（round2 #3 の「失敗を見落とさせない」不変条件が「アセット失敗→以後 DB-only 成功」の非対称ケースで破れる）。coordinator がセッションの「ゲーム本体控え未完了」状態 (`_sessionAssetCaptureFailed`) を保持し、**未控えの間は DB-only 成功でも緑✓を出さず毎操作で警告を再表示**（回復は次のアセット操作成功時）。`asset_snapshot_enabled=false`（隠し escape hatch）時の毎操作警告は **意図的 OFF に対する正確な表示**（ゲーム本体は実際に控えられていない）として許容＝WONTFIX。retention テストの同一秒衝突 (round4 Low #5) は `.db` 側にも衝突回避ループ (`_2`/`_3`) があり非該当を再確認。
- **レビュー対応 (round 6)**: ⑬**retention が「直近 N セッション」を保てず履歴を過剰に削る High バグを修正**＝`RunBackupCore` 内の `ApplyRetention()` が新 `.db` 書込直後に走る一方、replace-in-session の前世代削除は `RunBackupCore` の return 後に coordinator が行うため、retention が「これから消す前世代」を母数に数え、本来残すべき過去セッションを 1 操作ごとに 1 件余計に削っていた（K 操作のセッションで過去 K-1 世代が消失。文化祭準備のように 1 起動で多数ゲームを追加する大編集で、約束の retention 世代数が静かに崩れる）。アセット側 `ApplyRetentionAndGc` も同型で、過剰に消えた manifest だけが参照していた pool blob まで直後の GC が道連れに回収＝復元素材が `.db`/manifest/blob の三層で消える。**修正**: coordinator がこの直後に消す前世代 (`prevDb`/`prevManifest`) を `RunSessionBackup`→`RunBackupCore`→`ApplyRetention`/`CreateSnapshot`/`ApplyRetentionAndGc` に渡して retention の母数から除外（除外世代は coordinator が確実に消すので二重カウントなし）。アセット側は `Directory.GetFiles(ForceLong(...))` が `\\?\` prefix 付き path を返すためファイル名で比較。**再現テスト 2 本**（DB / manifest、修正前は Expected 2 / Actual 1 で fail → 修正後 pass）。⑭**restore-lock で延期した backup が完全 silent だった Medium を修正**＝他 PC 復元中の延期は `DescribeResult` で null になり何も出ず、復元ウィンドウ中の編集が未控えのまま気づかれなかった。`BackupResult.Deferred`（`IsDeferred`）を新設し「変更は保存したがまだ控えていない（復元完了後に再操作で控えられる）」を sticky 警告で表示。round5 のアセット健全性 flag は延期 (IsSkipped) では触らないようガード。⑮**デッドコード撤去**＝last_backup_at rewind 撤去で呼び元ゼロになった `BackupCatalogService.GetLastAuto`/`ScanAuto` を削除（Low #4）。連続ゲーム追加の 1 操作あたり体感（Medium #2 perf）は本番 SMB 実測待ち。
- **レビュー対応 (round 7)**: ⑯**lease 撤去後も「lease で多ホスト排他」と書く stale コメント＋CHANGELOG の「多ホスト安全」過大主張を訂正**（Medium #1/#2）＝撤去済 `TryAcquireBackupLease` を安全保証の根拠として参照する `ApplyRetentionAndGc` docstring を、grace-only 緩和＋#250 C2 残存（多ホスト並行 GC が >grace の初回フル ingest 中に取得中 blob を誤回収しうる窓。操作単位化+lease 撤去で窓は拡大、被害は backup 世代のみで live は無事・次回 backup で自己回復、PR2/PR3 へ deferred）に正確化。CHANGELOG の lease 撤去根拠も同内容に修正。**多ホスト並行 GC 対策はユーザー判断で `GcGracePeriod` を 1h→24h に延長**＝書きたて blob を 24h 守り、初回フル ingest(~6GB) が grace を超える間の誤回収窓を塞ぐ（advisory lock は「失効タイマー<ingest 時間」だと窓が再発する穴があるため不採用、ingest 中ずっと札を更新する heartbeat-lease は #250 領域。grace 延長は 1 行・contention なし・穴なしで現実的 ingest を確実に保護）。コスト＝削除済ゲームの未参照 blob が最大 24h 長く pool に残る一時的容量増のみ（~6GB 規模で誤差）。⑰**アセット操作の DB フェーズ中キャンセルが完全 silent だった Low を修正**＝進捗 0-10%（DB コピー中）でキャンセルすると top-level `Skipped("キャンセル")` になり `DescribeResult` が null＝無表示だった（round4 が塞いだのは DB 成功後のアセット走査キャンセルで別経路）。`assetsRequested` の top-level Skipped(非 Deferred) を「⚠ 変更はまだバックアップされていません（中断されました）」と 1 回警告（round5 flag で後続も再警告）。DB-only の Skipped は従来どおり沈黙。
- **レビュー対応 (round 8)**: ⑱**DB 側 retention 母数除外の full-path 完全一致依存を修正**（Low #2）＝round6 High 修正の核「前世代を retention 母数から除外」が `DirectoryInfo.FullName`(正規化済) と `excludePath`(`GetEffectiveDestinationDirectory` は raw `configured` を返す) の完全一致依存で、`backup_destination_path` が非正規化（末尾区切り / "." / ".." 混入）だと一致せず除外が外れ、round6 の過剰削除バグが silent 再発しうる穴をファイル名比較（アセット側と対称）に修正。**fail-first で teeth 確認**（非正規化 dest で full-path 比較は Expected 2/Actual 1、ファイル名比較で pass）。⑲**`IntroSlideEditForm.AssetsChangedOnDisk` の将来縛りコメント追加**（Low #3）＝現状 edit パスは画像クリア/差替で guide/ 旧画像を物理削除しないため false で整合するが、将来 orphan 掃除を足すなら削除でも true にしないと silent drift になる旨を doc に明記（スライド削除パスの imageRemoved 追跡と対称化を縛る）。⑳**連続アセット操作の coalesce/debounce（Medium #1 perf）と post-commit 残存窓（Low #4）は実機 SMB 確認待ち / 情報**＝#1 は本番 SMB の体感計測後に coalesce 設計判断、#4 は best-effort post-commit の原理的窓（旧方式より改善・許容範囲）。㉑**バックアップ進捗ダイアログ名を「変更を保存中（バックアップ）」→「バックアップを作成中」に変更**（UX 明確化）＝操作の DB commit + 成功メッセージは既に完了済で、このダイアログはその後の控え作成段。旧名は「今セーブ中＝キャンセルすると保存されない」と誤読されうるが、実際はキャンセルしても**変更は残り控えだけ後回し**になる（②のキャンセルは追加操作をロールバックしない＝commit 後の best-effort 控えは別レイヤ。操作自体のキャンセル/失敗時の物理 rollback は `AddGameForm` の copy 段で commit 前に別途担保）。㉒**手動バックアップ成功ダイアログの「ゲーム本体 (games/guide) もバックアップしました（N ファイル / 実使用 X）」明示を削除**（UX）＝クリーン成功時は冗長（「バックアップ＝全部まとめて控える」が当たり前に取られる）。「便りがないのは良い便り」で**問題があるときだけ**出す方針に変更し、**部分取得・失敗・異常の ⚠ は残す**（「DB 成功 ≠ ゲーム本体の控えあり」を隠さない round2-7 の不変条件は維持）。件数・実使用はバックアップタブで常時確認できる。㉓**ユーザー表示の「ゲーム本体」→「ゲームファイル」に統一**（UX）＝「本体」が「ハード/基本パッケージ」を連想させ分かりにくいとのユーザー指摘。バックアップタブ（`ゲームファイル N 個（実使用 X）`/`ゲームファイル: 未取得`）・手動ダイアログ ⚠・ステータスバー警告（`SessionBackupCoordinator.DescribeResult`）・`docs/usage/manager.md` を統一（件数は「ファイル ファイル」重複回避で「個」に）。コードコメントの内部概念名「ゲーム本体」と `RestoreReportForm`/`games.md`（別意味＝ゲームの exe/ビルド、復元文は PR3 で全文書換）は据え置き。**レビュー round10 #3**: 上記「統一」で取りこぼした user-visible 3 箇所（進捗ラベル `BackupService`/`AssetSnapshotService` の「ゲームファイルをバックアップ中…」、異常メッセージ `SkippedAnomaly("ゲームファイルのフォルダが見つかりません…")`）も統一＝同一フローで「進捗＝本体／警告＝ファイル」混在を解消。**#4**: SPEC の `last_backup_at` 記述を実態に修正＝「表示用に更新」→「write-only / read 経路なし（表示は `GetLastSuccess` のファイル走査由来）」、および #295 で撤去済の lease 方式・auto 削除時 rewind の旧記述（559 行の「lease 撤去」と矛盾していた）を撤去明記。**#5**: 死にフォーム `StoreSectionListForm`（`.cs`/`.Designer.cs`/`.resx` + csproj 参照）を削除＝`store_sections` を DB 変更するが #295 の `RunAfterOperation` backup trigger に未配線で、現行 UI は `StoreSectionPanel` を使用し全 .cs で参照ゼロの死にコード。残すと将来復活時にバックアップ漏れ経路になるため、#295 の「全 DB 変更操作に backup trigger」coverage を完結させる意味で除去（元から死んでいたが #295 review で発見）。**レビュー round11**: SPEC §6.5（応答取り込み）の「バックアップフェーズ（起動時/定期）」とトリガ表が #295 で撤去した旧モデルのまま残存していた drift を改定＝バックアップは操作単位へ移行済を明記し、**取り込みフェーズ実装時に取り込み成功直後 `RunAfterOperation(assetsChanged:false)` を呼ぶ縛り**（さもなくば取り込みデータが次の Manager 編集まで未控え＝coverage の将来穴）と、**「Manager を開けば編集有無と独立に控える」周期セーフティネット撤去のトレードオフ**を記録。§機能12 にアセット走査 perf 特性（操作回数に線形）追記。取り込みフェーズ自体は未実装（INSERT は test のみ）のため現状 runtime 影響なし。
- **レビュー対応 (round 9)**: ㉒**`last_backup_at` のコメント訂正**（Low #1）＝lease 撤去で read 経路が消滅し write-only 化（「最終バックアップ」表示は `GetLastSuccess` のファイル走査由来）。旧コメント「表示用に更新」は実態と乖離していたため「現状 read されない dead-but-cheap write（将来の履歴用に残置）」へ訂正。㉓**ゲーム削除の退避フォルダ `games/{id}.pending-delete-{guid}` を asset snapshot から除外**（Low #2）＝物理削除を諦めた (pendingGivenUp) 場合に games/ 配下へ残り、直後の `gamesRenamed=true` の snapshot が「削除したはずのゲーム実体」を manifest に取り込む（復元時に蘇る）混乱を、`WalkTree` で `.pending-delete-` 名のフォルダを skip して防ぐ。**fail-first で teeth 確認**（skip 無効だと manifest に `games/g1.pending-delete-…` が入る → skip で除外）。㉔**操作単位トリガで debounce を採らなかった判断を明文化**（Medium M1、issue #295「実装時に詰める点」への回答）＝reorder を含む全 DB 変更を commit 境界で都度発火する（debounce / アイドル / 終了時集約は採らない）。理由: 「変更をその場で守る」guarantee を最優先し、reorder は DB-only（重い走査なし・背景・modal 無し）で 1 回 124KB の DB online backup + retention 列挙 + バックアップタブ再描画に留まるため。**ただし遅い SMB での reorder 連打・連続編集の churn（背景 backup キュー + RefreshDisplay の SMB 走査）は本番計測対象**（許容外なら reorder の debounce を後続で検討、#1 perf と併せて判断）。
- 検証: Manager build 緑（0 警告）/ **テスト 127 件合格**（新規 `SessionBackupCoordinatorTests` 15: replace-in-session で 1 世代 / DB-only は manifest を増やさず前 manifest 温存 / retention は直近 N セッション / 無効で skip / 失敗 never-throw / **アセット失敗は ✓ でなく警告 (round2 #1)** / **アセット要求が非成功(キャンセル相当)でも ✓ でなく警告 (round4 #1)** / **同一セッションのアセット失敗で前 manifest を温存 (round3 High)** / **アセット失敗→DB-only 成功でもセッションは未控えのまま、回復はアセット成功時 (round5 #1)** / **複数操作セッションでも DB/manifest が直近 N セッションを保持 (round6 High)** / **restore-lock 延期は silent でなく警告 (round6 #3)** / **DB フェーズ中キャンセルも silent でなく警告 (round7 #3)** / **非正規化 dest でも retention 母数除外が効く (round8 #2)** / **削除退避フォルダは snapshot から除外 (round9 #2)**）。**※実機（保存系必須）: ゲーム追加→直後にバックアップ進捗→もう1ゲーム追加で世代が増えず上書き / 1 起動で 4-5 回連続編集しても retention 世代数が設定どおり保たれる / ストア編集・並び替えは DB のみ（重い走査なし）/ 設定変更ではバックアップ走らない / Manager 再起動で新セッションは別世代 / アセット取得を失敗 or キャンセルすると「✓」でなく橙警告で、その後 DB-only 編集しても緑✓に戻らない / 多 PC 同時編集での並行 backup/GC（#250 C2 窓） / 連続ゲーム追加の 1 操作あたり体感 + ストア/スライドの**並び替え連打**での背景 backup キュー + RefreshDisplay の SMB 走査もたつき（perf／M1 churn）、を本番 SMB で確認すること。**
- bump 判断: ユーザー向け挙動変更（自動バックアップのタイミング・設定 UI）。破壊的変更なし（既存 DB は interval key を読まなくなるだけ、settings は K/V）。minor (v0.21.0 → v0.22.0)。Launcher/Updater は無関係。

### [Manager v0.21.0] - 2026-06-02

#### Added (#250 PR1 — アセット控え: games/ + guide/ の共有プール (CAS) バックアップ)

- **DB バックアップ作成時に `games/` + `guide/` を「共有プール方式 (CAS / SHA-256)」で同時に控える**。従来 `toneprism.db` 単体のみだったバックアップを Manager 管理アセット一式に拡張する #250 の **PR1 (取得エンジン)**。**復元 2 モードは PR3、`RestoreReconciliationService` の guide/ 拡張は PR2**（本 PR は取得 + retention/GC + 設定 + UI 可視化まで）。
- **方式の選定経緯 (実機指摘で改訂)**: 当初ハードリンク世代スナップショットで実装したが、**プロジェクト全体が SMB 上にあり顧問のファイルサイズ管理がシビア**。ハードリンクは「1 実体に複数エントリ」のためエクスプローラー / SMB サーバーの容量計算が**二重カウント**し、実際は減っていても削減が見えない（=実質意味がない）。実測で **games/ は中身の 63% が重複ファイル**（学生作品が共通ランタイム/エンジンを多数共有、版違いフォルダの重複）→ 共有プールなら **5.73GB → 2.1GB**。**共有プールは中身ごとに実体 1 個だけ置く**ので、ファイルサイズを単純合計するどんな仕組みでも実サイズしか出ない（削減が見える）。コピーベースなので **SMB 越し / 別ボリュームでも有効**（ハードリンクと違う）。
- **新規 `AssetSnapshotService` (共有プール)**: `CreateSnapshot(timestamp, triggerType)` を DB バックアップ成功直後に**同一 timestamp/trigger** で best-effort 呼び出し (`BackupService.RunBackupCore`)。失敗・キャンセルは throw せず `SnapshotResult` で返し、**DB バックアップの成否・`last_backup_at` を一切壊さない**。
  - **プール**: `<backup_dest>/asset_pool/<hash[0:2]>/<sha256hex>` に中身ごとに実体 1 個（先頭 2 桁で分散）。**SHA-256** なので「中身違いが同一 hash」は起こらず、**名前が同じでも中身が違えば必ず別保存**、名前が違っても中身が同じなら 1 個に集約。
  - **目録 (manifest)**: `<backup_dest>/asset_snapshots/<auto|manual>/<yyyyMMdd_HHmmss>[_host].manifest`（`META\t…` ヘッダ + `hash\tsize\tmtimeTicks\trelpath` 行、relpath は `games/…`/`guide/…`）。temp→rename で atomic。
  - **SMB ハッシュキャッシュ**: 直近 manifest を読み `relpath+size+mtime` 完全一致なら**前回 hash を流用（再ハッシュ＝再読込しない）**。2 回目以降は新規/変更ファイルだけネットワーク越しに読む（初回のみ全読み）。size+mtime 据え置きで中身だけ変える特殊ケースに弱い rsync 同等のトレードオフ（games/ は追記専用で実害なし）。
  - **dedup**: `pool/<hash>` が既存ならコピーしない（temp→rename で atomic、配置レースは既存なら no-op）。symlink/junction はスキップ、長パスは `\\?\`、除外リストは適用しない（丸ごと）。
- **retention / GC**: **auto の古い manifest のみ削除**（`asset_snapshot_retention_count` 既定 30、manual 温存、#235 同様）。その後 **mark-sweep GC**＝残る全 manifest が参照する hash 集合を作り、pool 内の未参照ファイルを削除（**直近 1 時間以内に更新された pool ファイルは grace で残す**＝並行/直近書込のレース回避）。`backup_retention_count` とは独立。
- **設定**: `asset_snapshot_enabled` (既定 "true") / `asset_snapshot_retention_count` (既定 30) を settings(K/V) に追加。設定タブ「バックアップ」section に enable チェック + 世代数 NumericUpDown。**schema 版据置 v22**（settings は K/V data、migration 不要、既存 DB は default 引数で吸収）。
- **UI**: バックアップタブに「最終アセット控え」ラベル（時刻 / ファイル数 / **控えの実使用量＝プール物理サイズ**）。手動バックアップ成功ダイアログにも「アセットも控えました（N ファイル / 控え全体の実使用 X）」を併記。
- **レビュー対応 (commit 後追い・round 1)**: ①**GC の grace を機能させる**＝pool blob の mtime を「配置時刻」に刻む（`File.Copy` は元ファイルの古い mtime を継承し grace が常に無効化＝多ホスト並行 backup で他ホストの取得中 blob を誤 GC しうる重大バグを修正）。②**列挙も `\\?\` 長パス対応**（深い games/ で `GetFiles` 自体が PathTooLong → 世代 Failed を防止、列挙失敗はそのフォルダだけスキップ）。③**ソースを 1 回だけ読む**（ハッシュ計算と pool 配置を同一ストリームで、SMB の二重読込を回避＋チャンク読みで token 観測しキャンセル可）。④進捗バーを 95-99% にマップ（DB 段 95% 後の逆行を防止）。⑤GC が orphan `.tmp_` を grace 経過後に掃除。
- **レビュー対応 (round 2)**: ⑥**`GetPoolPhysicalBytes` の pool 全列挙を UI スレッドから排除**（SMB で数千往復→フリーズ懸念）＝バックアップ時にバックグラウンドで算出し `.poolsize` キャッシュへ、UI は即時読み（M1）。⑦**GC を auto に限定**（auto は lease で多ホスト排他＝並行 GC が起きない。manual は manifest 温存で未参照 blob を生まないため GC 不要、サイズキャッシュのみ更新）（M3 緩和）。⑧**retention/GC を try で best-effort 化**（manifest 書込済なのに retention 例外で「失敗」と誤報告するのを防止）（L2）。⑨**ファイルの reparse point もスキップ**（dir と同扱い、spec 整合）（L3）。⑩サイズ算出で `.poolsize`/`.tmp_` を除外（L4）。多ホスト並行で**初回フル取得が grace(1h) を超える残リスク**は PR2/PR3 で世代基準 GC/排他を検討（実機確認項目）。
- **レビュー対応 (round 3)**: ⑪**SMB 一時不達の silent skip を解消**＝games/ も guide/ も見えないとき、以前に控え (manifest) があれば「異常の可能性」として Warn + Skipped で通知（履歴が無ければ「未登録 install」と判断し Info + Success(0)）（#1）。⑫**manual のプールサイズ更新を全列挙→差分化**（既存 `.poolsize` + 今回新規分。manual は削除しないため単調増加で正確、SMB の毎回数千 blob 列挙を回避）（#4）。⑬Designer の `lblLastSnapshot` 既定文言を実行時と統一「最終アセット控え」（#5）。進捗分母の概算をコメント明記（#2）。manual アセットの無制限温存（#6）・grace 残存込みの `.poolsize` 概算（#7）は spec 通り据置。
- **レビュー対応 (round 4)**: ⑭**非対称欠損の検出**＝`games/` だけ消えて `guide/` が残るケースでも、当該 sub が「以前は控えにあったのに今 dir 不在」なら異常として世代まるごと Skipped（guide-only manifest を黙って書いて将来 games blob が GC されるのを防止）（M1）。⑮**アセット控えの失敗/異常を UI に表示**＝`SnapshotResult` を `BackupResult` に持ち回り、手動バックアップ成功ダイアログで失敗/異常 (`IsFailed`/`IsAnomaly`) のとき「アセット控えは取得できませんでした（DB は成功）」を併記。あわせて成功時の併記も `GetLatestSnapshot`+文字列マッチ→**result 直接**に変え多ホスト同秒の取り違えを解消（M2/L2）。⑯**長パス対応を全経路に拡張**＝GC・retention・manifest 列挙/読込も `ForceLong`/`EnsureLongPath`（従来 WalkTree のみ）。これで深い backup_dest でも GC abort→pool 無制限増加が起きない（M3）。コメントの行番号ハードコード除去（L3）。
- **レビュー対応 (round 5)**: ⑰**auto バックアップでもアセット異常を UI に出す**＝従来 manual ダイアログにしか結線されておらず、無人主動線の auto では DB 成功で「緑チェック」のみ＝アセット控えの失敗/異常が silent だった。`MainForm` の auto 成功分岐で `result.AssetSnapshot` が失敗/異常なら**橙ステータス**「DB 完了／⚠ アセット控えは取得できませんでした」を表示（DB 失敗ほど致命的でないため modal は出さない）（round5 #1）。⑱**manifest 書込/rename も長パス対応**（`File.Move`/`File.Exists` を `EnsureLongPath` 化、`ResolveUniqueManifest` 保証済の死コード削除）（round5 #2）。非対称検出が直近 manifest 基準である旨をコメント明記（round5 #3）。SPEC に「manual アセット控えは無期限・無制限蓄積」の運用注意を追記（round5 #4）。
- **レビュー対応 (round 6)**: ⑲**【Critical】UNC 長パスの構文不正を修正**＝`ForceLong`/`EnsureLongPath` が `\\?\` を常に単純前置していたため、UNC パス (`\\server\share\…`) に対し正しい `\\?\UNC\server\share\…` ではなく構文不正な `\\?\\\server\…` を生成していた。本番はプロジェクト全体が SMB 上にあり、**UNC 直アクセスだと `WalkTree` の `Directory.GetFiles` が毎フォルダ "syntax is incorrect" 例外→そのフォルダ skip→木全体が空走査→0 件の manifest を Success で書き、毎回 silent に空の控えを成功扱いで積む**最重大欠陥だった（ローカル `\\?\C:\` は有効なので単体テストでは緑のまま検出不能）。UNC 分岐を `FileOperationService.ApplyLongPathPrefix` に集約し `ForceLongPath`(公開)/`EnsureLongPath`/`AssetSnapshotService.ForceLong` を委譲化、`NormalizePath` も `\\?\UNC\` を対称に逆変換（C1）。⑳**進捗分母を walk と一致**＝`CountFiles` に `applyExclusions` 引数を追加し、控えの分母を WalkTree と同じ「除外なし」で数える（控えはバックアップなので Electron 系の `node_modules` 等「実行時に必須」なフォルダも丸ごと残す＝除外すると復元データが壊れる。従来は分母だけ ExcludedFolders 除外で過小→pct が 100 に張り付いた）（M1）。㉑`BackupResult.AssetSnapshot` を `internal set` 化（外部可変を封じ他プロパティと揃える、代入は `RunBackupCore` のみ）（L1）。㉒GC が manifest 読込失敗で全 GC を保守的に中止する早期 return では `.poolsize` が前回値据え置き（過大表示はあれど過小表示しない安全側）である旨をコメント明記（L2）。設定 UI レイアウト（M2）は Designer 上で右カラム重なり無しを確認、実機目視は残課題。
- **レビュー対応 (round 7、silent failure 経路の堅牢化)**: ㉓**「存在するが列挙失敗」を不在と同じ異常扱いに**＝従来 games/ の「不在」(`!Directory.Exists`) のみ異常検出していたが、dir は見えるが `Directory.GetFiles` が例外（SMB 一過性 I/O・権限等）を投げる「見えるが読めない」状態だと、`WalkTree` が best-effort で skip→sparse manifest を Success で書き→auto なら GC が将来 blob を刈りうる。履歴のある sub の **root 列挙失敗**を `SkippedAnomaly` に倒す（深部サブフォルダの単発失敗は従来どおり best-effort skip）（M-1）。㉔**新規 install / 異常の判別に DB games 件数を権威軸として追加**＝games/ も guide/ も見えないとき、到達不能共有では `Directory.Exists` が false を返し manifest 履歴も空に見える（`EnumerateManifests` は dir ガードで throw せず空）ため「未登録の新規 install」と区別できなかった。DB は直前の DB バックアップ成功で到達済＝「本来 games があるはず」を知っているので、`SELECT COUNT(*) FROM games` を判別軸に加え、件数>0（or 履歴あり）なのにフォルダ不在なら異常扱い。判別軸取得失敗も Warn を残す（旧 `catch {}` の silent 解消）（M-2）。㉕**pool blob の配置時刻 mtime stamp 失敗を Warn 化**＝`File.SetLastWriteTimeUtc` の `catch {}` を握り潰さずログ。失敗すると blob が元ファイルの古い mtime を継承し GC の grace が静かに無効化＝多ホスト並行 backup で他ホストの取得中 blob を誤 GC しうる（根治の世代基準 GC は PR2/PR3）（M-3）。㉖SPEC 変更履歴のテスト件数ドリフト（101→108）を是正（L-1）。
- **レビュー対応 (round 8、部分取得の可視化)**: ㉗**深部フォルダの列挙失敗で「部分的な控え」になったことを Success に潰さず明示**＝round7 M-1 は sub の **root** 列挙失敗のみ異常検出していたが、各ゲーム/`v{}/` 配下の深部 `GetFiles`/`GetDirectories` が SMB 一過性 I/O・権限で throw すると `WalkTree` は best-effort で skip して続行し、半分しか含まない世代を `Success`・FileCount 低めで記録、ユーザーには「DB 完了／✓」しか見えず**部分バックアップに気づく信号が無かった**。skip 件数を `Stats.SkippedDirCount` に集計し、>0 なら完了ログに「⚠ N 個のフォルダを列挙できずスキップ＝部分的な控えの可能性」を Warn、`SnapshotResult.IsPartial`/`SkippedDirCount` で UI へ伝播。auto は橙ステータス「⚠ アセット控えは一部のフォルダを取得できませんでした (N 個スキップ)」、手動ダイアログは成功併記に「⚠ ただし N 個のフォルダを…スキップ」を追記（世代まるごとの異常 `SkippedAnomaly` ほどではないので Success のまま `IsPartial` で区別）（C1）。㉘**実使用量 0 B の矛盾表示を回避**＝`.poolsize` 未更新/読込失敗時に `GetPoolPhysicalBytes` が 0 を返し「N ファイル ／ 控え実使用: 0 B」と矛盾表示しうるのを、0 は「計測中」に倒して未計測と実 0 を区別（最終アセット控えラベル + 手動ダイアログ両方）（A/L1）。なお多ホスト×初回フル取得が grace(1h) 超で他ホストの取得中 blob を誤 GC しうる件 (C2)、GC が毎 auto で pool 全列挙する perf (C3)、manifest timestamp↔.db 名の衝突 suffix 乖離 (PR3 相関、B-L2)、改行入りファイル名での manifest 行破損 (D-L3) は #250 に申し送り（PR2/PR3 で対応）。
- **レビュー対応 (round 9、品質)**: ㉙**長パス安全化関数の自己矛盾を解消**＝`ApplyLongPathPrefix` 内の `Path.GetFullPath` は .NET Framework 既定の legacy path handling では ≥260 字入力で `PathTooLongException` を投げる (= 長パスを安全化する関数が、まさに対象の長パスで落ちる)。深い backup_dest で manifest/pool 実パスが ≥260 字になると `EnsureLongPath` が機能する前に落ち世代が Failed になりうるため、GetFullPath が throw したら caller が渡す正規化済み絶対パスをそのまま `\\?\` 化する fallback を追加（games/ 走査は再帰先が既に `\\?\` 付きで GetFullPath 非経由＝従来から影響なし。深い backup_dest のみ Failed→Success に改善）（B-1）。㉚`lblSnapshotRetentionUnit` の `TabIndex` 未設定を補完（A-1）。㉛docs に「最初の1回だけ時間がかかる」運用注意を追記＝既存本番 DB は `asset_snapshot_enabled` 既定 true で次回バックアップから ~6GB の初回 full ingest を始めるため、混雑しない時間に手動で一度回す案内（C-2、コード変更なし）。なお改行入りファイル名での manifest 破損 (D-L3) は NTFS が制御文字をファイル名に許さず実質発生しないため申し送り優先度は最低に降格。
- **実機検証フィードバック (UI 簡素化・用語・進捗)**: 本番 SMB での手動バックアップ実機検証中に判明した UX 問題を是正。①**進捗バーの重み付け是正**＝DB コピー 0-10% / ゲーム本体取得 10-99% / 完了 100%（旧: DB が 0-100% を使い切り→retention で 95% に逆戻り→一番重い初回 ~6GB 取得を 95-99% に圧縮、で「95% で固まって遅い」ように見えた）。②**ProcessingDialog のメッセージ見切れ修正**（AutoSize 依存をやめ進捗バー幅 460 に固定）。③**UI 用語を「アセット控え」→「ゲーム本体のバックアップ」に統一**（部員に分かりやすく。内部ログ/クラス名/コメントは据え置き）。④**バックアップの一体化**＝「ゲーム本体も世代保存する」チェックと「ゲーム本体の保持世代数」を設定 UI から撤去し、DB(設定込み)+ゲーム本体を 1 バックアップとしてまとめて扱う。保持世代数は `backup_retention_count` に統一（`.db` とアセット manifest をペア保持/削除＝PR3 復元のペア整合に有利、CAS 重複排除で世代増の増分は変更分のみなので「アセットは別に少なめ」の当初分離理由は弱い）。`asset_snapshot_enabled` は隠し既定 true として残置（将来/開発用 escape hatch）、`asset_snapshot_retention_count` は廃止。バックアップ操作行の「最終バックアップ」表示も整理（1 行目=取得日時 / 2 行目=ゲーム本体のファイル数+実使用。DB の 124KB は省略。左右にボタンがあり狭いので 1 行に詰めず 2 行にして「更新」ボタンへの被りを解消）。
- 検証: Manager build 緑 / **テスト 112 件合格**（`AssetSnapshotServiceTests` 16: 初回プール格納 / **同一中身は別パスでも 1 個** / **名前同じ中身違いは別保存** / 不変は新規 0 / 変更で新 blob / retention+GC で未参照 pool 削除 / **grace で直近未参照 blob は残る** / **blob mtime は配置時刻** / **履歴ありで sources 消失→Skipped** / **非対称欠損(games だけ消失)→Skipped** / **DB に games 登録済でフォルダ不在→Skipped (round7 M-2)** / **skip>0 の Success は IsPartial (round8 C1)** / manual 温存 / 無効 / 空(未登録)→Success / 失敗 never-throw）+ **`FileOperationServiceLongPathTests` 9**（UNC→`\\?\UNC\` / ローカル→`\\?\` / 既存前置素通し / 短い UNC は無前置 / 長い UNC は UNC 前置 / `NormalizePath` の UNC 逆変換 / **260字超ローカル・UNC で throw せず正しい前置 (round9 B-1)**、= 長パス変換を回帰固定）。**C1 の UNC 列挙は `\\localhost\C$` 管理共有で end-to-end 実証済**（旧前置 `\\?\\\…` は "syntax is incorrect" 例外・新前置 `\\?\UNC\…` は実ファイル 564 件を列挙成功）。**※本番 SMB 共有での最終 round-trip（再取得で控えがほぼ増えない / サーバー容量計算で実サイズが出る / 深い長パス / 多ホスト並行 GC 安全性 / 設定 UI 実機目視）は別途必要**。
- bump 判断: ユーザー向け新機能 (データ保護)、破壊的変更なし・既存 DB 自動互換。minor (v0.20.2 → v0.21.0)。Launcher/Updater は無関係。

### [Manager v0.20.2] - 2026-06-01

#### Changed (#211 / #212 / #291 — ストアセクション編集の条件付き UI)

- **(#212) スライドショー / タイルグリッドのソースを「手動 ＋ ランキング系（人気ランキング・最近プレイ・ランダム）」に制限**。厳選枠は**少数を大きく見せる**枠なので、**表示数を制御できるソース**だけ合う（手動＝割当数 / ランキング系＝`max_display_count` で TOP N）。背景画像・タイトルは**ゲーム自身のもの**にフォールバックするので自動でも崩れない（人気 TOP5 を大きくスライド、など）。一方 genre/新作/制作年等の**フィルター系は条件一致を全件表示で枚数を絞れず**厳選にならないため不可。結果として **「厳選枠で許可するソース集合」＝「最大表示数が有効なソース集合 ∪ 手動」** と一致（1 つの原則で説明できる）。
    - **UI 方式（#212 改訂 / 実機指摘対応）**: 当初は「ドロップダウンには全ソースを出し、厳選枠で許可外を選んだ瞬間に手動へ戻す（coerce）」方式だったが、**スライドショー/タイルグリッドでも一覧に全フィルターが並んで紛らわしい**との指摘を受け、**ソースのドロップダウン自体をタイプに応じて構築し直す**方式に変更。厳選枠では `{手動, 人気ランキング, 最近プレイ, ランダム}` の 4 つだけを一覧に出す（許可外はそもそも選べない）。combo の表示 index と canonical なソース ID（0-12）がズレるため、`AllSources` マスタ＋`_sourceMap`（表示index→canonical）＋`SelectedSource` アクセサを導入し、フォーム内ロジックは canonical を見る。タイプを厳選枠に変えたとき/legacy データを開いたときに現在ソースが許可外なら手動へ落として案内（`RebuildSourceCombo` / `ShowShowcaseCoerceDialog`、旧 `ApplyTypeSourceConstraint` は廃止）。通常カテゴリ行は従来どおり全ソースを一覧に出す。
    - Launcher 側の空グリッド修正・スライド枚数上限は下記 Launcher v0.10.3 参照。
- **(#211 fix) `max_display_count=0` のセクションを開くとクラッシュする回帰を修正**。#211 で手動/フィルター系は `0` 保存になったが、`nudMaxDisplayCount.Minimum=1` のため `nudMaxDisplayCount.Value=0` 代入で `ArgumentOutOfRangeException` になっていた。読み込み時に NumericUpDown の Min/Max へクランプする（`ClampToNud`、グレーアウト中の表示値は保存に影響しない＝btnOK で 0 を書く）。同様に `nudSourceValue`（プレイ人数/制作年）の読み込みもクランプ。**※round-trip 不成立の保存系バグのため実データ往復確認が必要**。
    - **(関連)** 「人気ランキング」の **何を"人気"とするか（アルゴリズム）は別 issue で後日詰める**（プレイ記録ベースの集計方法・期間・重み付け等）。現状はプレイ記録（#34/#36、開発中）依存で、記録が貯まるまで並びが弱い可能性がある（厳選枠で許可しても空なら自動で非表示なので害はない）。
- **(#211) 最大表示数 (`nudMaxDisplayCount`) をソース別に有効/グレーアウト**。**ランキング系**（人気=play_count順/最近プレイ=last_played順/ランダム）のみ有効（TOP5 等の特集枠で上限が意味を持つ）。**手動**（割り当て全件表示）と**条件系**（ジャンル/プレイ人数/難易度/プレイ時間/通信プレイ/コントローラー、および **新作**［`release_year=今年` を display_order 順に並べるだけで本物のランキングでないため #290 review で条件系に分類変更］、条件一致を全件表示）はグレーアウトし、保存時に `MaxDisplayCount=0`（= 上限なし、Launcher の `max_display_count<=0` 解釈）で書き、手で選んだ/条件一致のゲームが意図せず切られないようにする。
- 新規ヘルパ `IsRankingSource` / `TypeIsShowcase` / `TypeAllowsSource` / `UpdateMaxDisplayCountEnabled` / `RebuildSourceCombo` / `ShowShowcaseCoerceDialog` / `CanonSourceFromString` / `ClampToNud`（Load・タイプ変更・ソース変更で適用）。スキーマ変更なし（`max_display_count` の値の使い方を変えるのみ、既存の手動/フィルターセクションは次回保存で 0 に正規化）。※当初コミットの `TypeRequiresManualSource` / `ApplyTypeSourceConstraint` はドロップダウン再構築方式（上記「UI 方式」）への置換で廃止済み。
- **(#291) 新ソース「制作年」(`release_year:YYYY`) を追加**。「値」に西暦を入れるとその制作年のゲームを `display_order` 順で全件表示。**新作**（今年固定）に対し**任意の年**を選べる汎用フィルター。条件系扱いで `max_display_count` はグレーアウト（0 保存）。切替時は現在年を初期値に補完。`nudSourceValue.Maximum` を 10→2100 に拡張。Launcher 側のクエリ分岐は下記 Launcher v0.10.3 参照。
    - **ドロップダウンの表示名・位置（レビュー後の調整）**: 当初「制作年指定」を combo 末尾に置いていたが、ラベルを **「制作年」** に短縮し、`release_year` つながりで **「新作」の隣**に配置。combo の表示順は `AllSources` 配列の並びで決まり canonical ID（=12、DB の `release_year:` に対応）とは独立なので、ID を保ったまま配列内で移動＋ラベル変更（`_sourceMap` 経由で解決され DB 解釈は不変）。
- **(#290 review) 難易度 / プレイ時間の値指定を数字直打ちからラベル付きドロップダウンに変更**。`cmbSourceValue`（新規 combo, idx=7/8 で表示）にゲーム編集と同じ選択肢（`1 - 易しい` / `2 - 5分～15分` 等、`GameFormHelper.InitializeDifficultyCombo` / `InitializePlayTimeCombo` を再利用）を入れ、保存時に `SelectedIndex+1` を値に。プレイ人数・制作年は従来どおり数値入力 (`nudSourceValue`)。「指定の数字だけ不親切」だったのを解消。
- docs `usage/store.md`・SPEC §7.3 を新ルールに更新。
- **※実機 UI 確認は未実施**（条件付き有効/無効・coerce 挙動は WinForms UI のため実機目視が必要）。
- bump 判断: 既存ストアセクションエディタの段階的改善（条件付き UI #211/#212・制作年ソース #291・ドロップダウン値指定 #290review）＋クラッシュ/表示バグ修正。新ソース追加は機能だが、**Launcher 側の同 #291 追加も patch (v0.10.3) としており component 版は patch で揃える**（feature としての版上げはリリース時に Bundle 側で minor 反映する）。patch (v0.20.1 → v0.20.2)。

### [Manager v0.20.1] - 2026-06-01

#### Fixed (#288 — 版アップ/ゲーム追加のロールバック削除を read-only 対応に)

- **ゲーム/版フォルダのコピー失敗・中断時のロールバック削除に残っていた生 `Directory.Delete(..., true)` を `FolderDeletionService.TryDelete`（read-only 再帰解除込み、#209）に寄せた**。コピー元が Unity/Godot プロジェクト（`Assets`/`Library` 等が read-only）だと、これらの生 delete がロールバックで `UnauthorizedAccessException` で失敗し、中途半端な版/ゲームフォルダが残って次回追加の「フォルダが既に存在します」エラーの種になりうる取りこぼしだった（#209 review finding 5）。
  - **`GameSectionPanel`（バージョンアップ）5 箇所**: missing-asset 中止 / 相対パス計算失敗(M4) / DB 保存失敗(M5) / 中断時 tempDir(H3) / `HandleVersionDirMoveFailure` の tempDir。`versionDirOwnedByThisCall` ガード（並行 Manager の勝者フォルダを敗者が消さない不変条件、#234）は維持。
  - **`AddGameForm`（ゲーム追加）2 箇所**（#288 review 指摘で追加）: 既存フォルダ上書き時の wipe（失敗時は従来通り friendly 例外で中断）/ rollback の版フォルダ削除（**旧 bare `catch {}` を `Result` 判定 + `Logger.Warn` 化**＝silent な zombie ゲームフォルダ残留の痕跡を残す）。`versionFolderCreatedThisCall`/`baseGameFolderCreated` ガードは維持。空の親フォルダの非再帰削除（空チェック付き）は対象外。
- **`FolderDeletionService.TryDelete` を「throw せず常に `Result` を返す」契約に**（#288 review）: 従来は `IOException`/`UnauthorizedAccessException` のみ捕捉し他は伝播していたが、cleanup/rollback の呼び出し側が「全例外 swallow」を各所で書かずに `Result.Success` だけ見れば済むよう、想定外例外も捕捉して失敗 `Result` を返す。
- bump 判断: read-only バグの取りこぼし修正。patch (v0.20.0 → v0.20.1)。全 87 テスト合格。

### [Manager v0.20.0] - 2026-06-01

#### Added (#209 — ゲーム編集で個別バージョンを削除)

- **`EditGameForm` の「ランチャーで表示するバージョン」ドロップダウンの隣に「このバージョンを削除」ボタンを追加**。選択中の版を確認ダイアログのうえで**即時削除**（OK/Cancel とは独立した確定操作）。版の DB 行（+ version 別 developers は version_id FK cascade）と版フォルダ `games/<gameId>/v<version>/` を一緒に消す。
- **ガード**: ①**最後の 1 版は削除不可**（ゲームごと削除へ誘導）/ ②**確認ダイアログ必須**（即時・取り消し不可を明示）/ ③**アクティブ版（games.version）を削除したら残りの最新版（id DESC）に自動で付け替え**（表示版の dangling 防止）/ ④`SessionConflictHelper.CheckBeforeWrite("ゲームのバージョン削除")`（行 DML 扱い＝Launcher 単独では警告せず、フォルダロックは下記リトライ案内で処理）。
- **整合性**: 既存のゲーム削除（`GameSectionPanel`）と同じ **3-phase + rollback**（フォルダを `.pending-delete-{GUID}` に退避 → DB 削除＋付け替え → 物理削除、各段で失敗時はロールバック）。新規 `Services/GameVersionDeletionService`（god-file 化を避け UI から分離、#242 / AGENTS「ロジックは外へ」）+ `DatabaseManager.DeleteGameVersionAndReassignActive`（版行削除＋active 付け替えを 1 transaction で atomic）+ `VersionRepository` の in-transaction helper（`DeleteVersionRowInTransaction` / `GetVersionStringByIdInTransaction` / `GetLatestRemainingVersionIdInTransaction` / `CountVersionsInTransaction`）+ `GameRepository.MirrorActiveVersionIntoGameInTransaction`（active 版の全ミラー列付け替え、下記 Codex P1）。フォルダパスは既存 `PathManager.GetVersionFolder` で解決。
- **重要な堅牢化**: active 判定とフォルダパス解決は **DB / disk の確定値**で行う（フォーム上で版番号を pending リネーム中でも `games.version` の dangling や旧フォルダ orphan を起こさないため。DB 側は `versionId` で操作、フォルダは `_originalVersionByDbId` の旧版数で解決）。
- スキーマ変更なし（version_id FK cascade は schema v18 で導入済）。`Manager.Tests/VersionDeletionTests`（4 ケース: 非アクティブ削除で active 据え置き / アクティブ削除で残り版へ付け替え / 3 版で id DESC 付け替え / version 別 developers の cascade）を一時 DB で検証、全 80 テスト合格。テスト基盤として `DatabaseManager(DatabaseConnection)` 内部 ctor を追加（#239 方針）。
- docs: `docs/usage/games.md` 編集セクションに「バージョンを個別に削除する」を追記。
- レビュー対応: ①即時削除は OK を介さず DB 確定するため、`EditGameForm.DataChangedOutsideOk` フラグを追加し `GameSectionPanel` が Cancel/×で閉じても一覧を再読込（active 付け替え後のメイン画面 stale 防止）。②アクティブ版削除後に `originalGame.Version` を DB 戻り値（真値）へ同期（OK 時の active 切替確認が削除済み版数を出す不整合を解消）。③`GameVersionDeletionService.Delete` をフォルダパス注入式に変更（PathManager 非依存）→ フォルダ 3-phase の統合テスト 3 件を追加（正常系で実フォルダが退避→物理削除される / フォルダ不在でも DB 削除 / active 付け替え戻り値）。④版フォルダ削除は file ロックで調停（プレイ中は `FolderLocked` で安全に弾く）。Phase 1 退避リネーム失敗はゲーム削除のようなリトライループでなく `FolderLocked` を返しボタン再押下で再試行する（ワーカースレッドから UI を出さない設計）。
- 実機検証で判明した修正: **read-only 属性のフォルダを削除できない問題を `FolderDeletionService` で修正**。Unity/Godot 等のゲームプロジェクトフォルダはサブディレクトリ（`Assets`/`Library`/`Packages` 等）に read-only 属性が付くことがあり、`Directory.Delete` はファイル削除後に read-only ディレクトリを消せず `UnauthorizedAccessException` で失敗していた（実機で Unity ゲーム Toney_Fox の版削除が「フォルダ物理削除に失敗」= 退避フォルダが orphan 化）。**read-only を外しながら階層ごとに再帰削除する自前実装 `ForceDeleteDirectory` に置換**。なお初回修正は `GetFileSystemInfos("*", AllDirectories)` の単一呼び出しで read-only を一括解除する方式だったが、Unity の深いパス（`Library` 等の MAX_PATH 超）でその API が **atomic に例外 → read-only 解除が丸ごと中断**する実機バグがあった（浅いパスの単体テストでは素通り）。階層ごと処理でこの一括 throw を構造的に排除。実機の Unity read-only フォルダ（Toney_Fox v1.1.3）で同ロジックの削除成功を確認。**`FolderDeletionService` はゲームごと削除（`GameSectionPanel`）でも使うため、read-only な Unity/Godot ゲームの全削除も同時に堅牢化**。`FolderDeletionServiceTests`（read-only dir/file の削除 / 不在パス）。
- 確認ダイアログの冗長な「OK を押さなくても即削除」注記を削除（自明なため、ユーザーフィードバック）。「取り消せません」警告は残置。
- レビュー対応(2巡目): ①版数が**空文字**の異常データ行を削除しようとすると `GetVersionFolderLeaf` が throw しハンドラ内未捕捉 crash になる経路を、削除前の空チェック + friendly メッセージで閉鎖。②`GameVersionDeletionService` の **Phase 3（物理削除）を try で囲み**、`FolderDeletionService` が再 throw しうる想定外例外も `PhysicalDeleteDeferred` に落として「Phase 2(DB)成功後は必ず Result を返す（throw しない）」契約を保証（DB 確定後の silent desync 窓を閉鎖）。③確認ダイアログのバージョン表示を、フォルダ表示と一致する disk/DB 確定版数（`diskVersion`）に統一（pending リネーム中の食い違い表示を解消）。④`EditGameForm` の「game_versions は UNIQUE 制約を持たない」という #158 当時の stale コメントを修正（現在は v15/v17 で `(game_id, version COLLATE NOCASE)` UNIQUE INDEX があり、文字列でも active 行を一意特定できる）。
- レビュー対応(Codex): **P1【重大】アクティブ版削除時に `games` のミラー列が古いまま残り、ゲームが起動不能になる回帰を修正**。従来は `games.version`（版数文字列）だけ付け替えていたが、`games` は active 版の `executable_path`/`thumbnail_path`/`background_path`/`title` 等もミラーしており、Launcher は `games.*` を**直読み**するため、付け替え後も **削除済みフォルダの `executable_path` を指したまま → そのゲームが起動できなくなる**バグだった。`GameRepository.MirrorActiveVersionIntoGameInTransaction` を追加し、残存版へ**全ミラー列を付け替え**るよう修正（developers は Launcher が `games.version`↔`game_versions.version` の JOIN で解決するため touch 不要）。**P2**: 「最後の1版は削除不可」を UI ガードだけでなく **transaction 内でも enforce**（残存版数を数えて 1 以下なら例外）、並行 Manager の race 対策に `BEGIN IMMEDIATE`(Serializable)。**P3**: `games.version` が NULL の異常 DB で仮 active 版を削除した場合も残り最新版へ付け替え（NULL のまま mirror が stale 化するのを防ぐ）。`VersionDeletionTests` に P1 ミラー検証・P2 例外・P3 NULL 付け替えを追加（全 87 テスト合格）。
- bump 判断: ユーザー向け新機能の追加のため minor (v0.19.5 → v0.20.0)。
- **※実機 UI 確認は未実施**（破壊的操作のため作業 DB 上で実行できない）。ボタン表示・選択切替後のメモリ同期・削除後の再選択は、DB コピー等を用いた実機目視を別途行うこと（メモリ「UIは実機起動で確認」）。

### [Manager v0.19.5] - 2026-06-01

#### Changed (#283 — Launcher 版数読み取りを exe FileVersionInfo に変更 / project.godot 同梱廃止)

- **`VersionInventory.ReadLauncherVersion` を「prod=エクスポート済み `TonePrism_Launcher.exe` の FileVersionInfo / dev=`project.godot` 直 parse の fallback」に変更**（#281 派生・案D 採用）。exe の FileVersion は `export_presets.cfg` の `application/file_version` を Release.ps1 `Set-ExportPresetVersions` が SoT（config/version）から stamp → Godot/rcedit が exe の VERSIONINFO リソースに焼いた派生値。**読み取り API は Updater（`ReadUpdaterVersion`）と同じ FileVersionInfo 方式だが、版数を exe に焼く機構は別系統**（Updater は .NET AssemblyFileVersion 属性、Launcher は Godot/rcedit）。後者は本変更で初めて prod の版数 SoT として consume するため、stamp 不発を下記 `Assert-ExportedLauncherVersion` が公開前に守る。リポジトリには exe を置かないため、dev では exe 不在 → `<repo>/Launcher/project.godot` の `config/version` を `ConfigVersionRegex`/`ParseConfigVersion` で読む（#281 の機構を dev fallback として残置、`VersionInventoryTests` も有効）。
- 新規 `PathManager.LauncherExePath`（`<install>/Launcher/TonePrism_Launcher.exe`）。
- 配布側: `Launcher/project.godot` の release zip 同梱を廃止（下記 Release Tooling v0.1.24）。prod は exe から読むため版数用 loose ファイルが不要に。
- **トレードオフ（重要）**: prod の版数は多段 stamp パイプライン（config/version → `Set-ExportPresetVersions` → export_presets.cfg → Godot/rcedit → exe VERSIONINFO）の派生値になるため、stamp が一手抜けると silent に古い/欠落版数を表示しうる（実際、検証時に stamp 前の exe が stale `0.9.1.0` を焼いていた）。→ **本 PR で `Release.ps1 Assert-ExportedLauncherVersion` を追加し、exe FileVersion ≠ SoT を公開前に hard fail で止める安全網を入れた**（Release Tooling v0.1.24）。リリース時の成果物 版数目視は backstop（SPEC §3.7.8）。
- 検証: `export_presets` を SoT 値に stamp 後 `--export-release` で exe を生成し FileVersionInfo が当該版数を返すことを実機確認。dev fallback は exe 不在で `project.godot` を読むことを確認。build 緑 + 全76テスト合格。
- bump 判断: Manager の版数読み取り経路変更（Manager.exe が変わる）。patch (v0.19.4 → v0.19.5)。

### [Manager v0.19.4] - 2026-06-01

#### Changed (#281 — Launcher 版数読み取りを project.godot config/version に変更)

- **`VersionInventory.ReadLauncherVersion` の読み取り対象を `Launcher/version.gd` の `MAJOR/MINOR/PATCH` 3 正規表現 → `Launcher/project.godot` の `[application] config/version="X.Y.Z"` 1 正規表現に変更**（#281 で Launcher 版数の SoT が project.godot config/version に移行したため）。Manager は Godot を実行できないので、従来どおりファイルを直接 parse する。不要になった `MajorRegex`/`MinorRegex`/`PatchRegex`/`TryReadInt` を削除し、`ConfigVersionRegex` 1 本に集約。読み取り失敗時 `null` → UI「不明」表示の fail-soft 方針は不変。
- `ConfigVersionRegex` は `config/version`（スラッシュ）を literal match し、project.godot 先頭の `config_version`（アンダースコア、Godot ファイル形式版）には誤マッチしない。
- 配布側: Release.ps1 が install 先に同梱するファイルを `Launcher/version.gd` → `Launcher/project.godot` に差し替え済（下記 Release Tooling 参照）。dev では `BaseDirectory` がリポジトリルートに解決され `Launcher/project.godot`（ソース）を直読み、prod では `<install>/Launcher/project.godot`（Release.ps1 同梱コピー）を読む。
- レビュー対応: パース部を純関数 `ParseConfigVersion(content)` に切り出し（I/O から分離）、`Manager.Tests/VersionInventoryTests`（16 ケース: 正常 3 part / `config_version=5` への誤マッチ防止 / CRLF / 2・4 part 不可 / クォート・記法違い / Int32 超過 / null）で SoT パーサの回帰を固定。`InternalsVisibleTo("TonePrism_Manager.Tests")` でテストから internal 参照可に。C# `ConfigVersionRegex` ↔ Release.ps1 `Assert-LauncherVersion` の同一 regex に相互同期コメントを追加（format 変更時の両側更新を discoverable に）。
- bump 判断: 版数表示の出力は不変の内部リファクタだが exe が変わるため patch (v0.19.3 → v0.19.4)。

### [Manager v0.19.3] - 2026-06-01

#### Changed (#278 ① — Launcher 起動中でもゲーム情報を編集できるよう警告をスコープ分け)

- **文化祭当日、Launcher を立てたまま Manager で編集してもセッション競合警告を出さない**（通常の行編集に限る）。背景: Launcher は DB 読み取り専用（SELECT のみ、heartbeat は file）で、`journal_mode=DELETE` + `busy_timeout` の下では「Manager の行 write」と「Launcher の read」を SQLite が安全に調停する（write-write 競合なし・持続ロックなし）。従来は Launcher 稼働を検出すると編集のたびに警告が出ていた。
- 判定を純ロジック **`Services/SessionConflictPolicy.ShouldWarn(otherManagerCount, launcherCount, op)`** に抽出（AGENTS「UI は薄く、ロジックは外へ」）。ルール: **別 Manager 検出時は操作種別を問わず常に警告**（write-write の本当の危険）／**Launcher 単独稼働なら、`toneprism.db` をファイルごと差し替える操作（"バックアップ復元" / "データベース初期化"）だけ警告し、通常の行編集（ゲーム/セクション/初回説明/設定/バックアップ作成・削除等）は警告しない**。`MainForm.CheckSessionConflictBeforeWrite` から委譲。
- **Manager 起動時の競合ダイアログも同方針でスコープ分け** (`SessionConflictPolicy.ShouldWarnAtStartup`)。起動時は操作未定なので「別 Manager がいるか」だけで判定し、**Launcher 単独稼働では起動時ダイアログを出さない**（Launcher 立てっぱなしで Manager を開くたびに「【危険】別の Manager / Launcher が稼働中」が出る摩擦を解消。危険な Restore / 初期化は操作時に警告される）。別 Manager 検出時は従来どおり起動時ダイアログを表示し、検出 Launcher も併せて一覧表示。`MainForm.MainForm_Load` の起動時判定を委譲。
- 注意: 操作種別を文字列ラベルで判定するため、**新たに DB ファイルを置換/再作成する操作を追加したら `IsWholeDbReplacingOperation` に対応ラベルを足すこと**（足し忘れると Launcher 稼働中に警告なしで実行され、store 表示中だとファイル差し替えが衝突しうる。#278 ② で store_browse が DB ハンドルを握らなくなれば緩められる）。
- `Manager.Tests/SessionConflictPolicyTests` で 34 ケース（nobody / 別 Manager 常時警告 / Launcher 単独×通常編集18種は警告なし / Launcher 単独×Restore・Reset は警告 / 分類 / 起動時判定5種）を検証。

### [Manager v0.19.2] - 2026-06-01

#### Changed (#253 — guide/ 内画像の再利用)

- **初回説明スライドの画像選択で、選んだファイルが既に `guide/` 直下にある場合は複製せずその実体を再利用する** (`IntroGuideAssetHelper.CopyImageInto` / `ImportImage`)。従来は常に `guide/` へコピーしていたため、`guide/` 内の画像（孤児含む）を選ぶたびに `_2` / `_3` の重複コピーが増えていた。**別の場所にある同名の別画像は従来どおり自動 suffix で取り込む**（衝突回避は維持）。判定は「選択パスの親フォルダ == `guide/`」（`Path.GetFullPath` 正規化 + Windows 前提で大小・末尾セパレータ無視）。`createdNewFile` を返し、新規コピーか再利用かを caller が判別できるようにした。
- **保存失敗時の orphan 掃除を「新規コピーしたときのみ」に限定** (`IntroSlideEditForm.OnOk`)。再利用した既存 `guide/` 画像（他スライドが参照しているかもしれない）を、DB write 失敗時の後始末で誤って削除しないようにした (#274 review #3 の掃除ロジックの安全化)。
- `Manager.Tests/IntroGuideAssetHelperTests` に再利用ケース2件を追加（guide/ 内選択→複製しない・ファイル数不変／外部選択→従来どおりコピー）。全12件緑。
- **スライド画像ピッカーの形式フィルタから `gif` を除外** (`IntroSlideEditForm`、Codex 指摘)。`gif` は Manager プレビュー (GDI+) では表示できても Launcher の `Image.load_from_file` で読めず、来場者画面で画像が出ない。両方が扱える `png/jpg/jpeg/bmp` に限定。さらに **`すべてのファイル (*.*)` で未対応形式を選んだ場合も `OnSelectImage` で拡張子を検証して弾き警告**（Codex 2nd: プレビューは出るのに来場者画面で出ない silent 失敗を防止）。Launcher 側でも読めない画像のみスライドは除外して blank を防ぐ多層防御。

#### Bump 根拠 (v0.19.1 → v0.19.2)

既存挙動の改良（重複コピー防止）＋保存失敗時の掃除の安全化のため SemVer patch。スキーマ・DB 変更なし。Bundle 反映はリリース実行時。

### [Manager v0.19.1] - 2026-06-01

#### Fixed (ストアセクション並び替えの half-write 解消)

- **ストアセクションの「↑上へ / ↓下へ」並び替えが非トランザクションで、途中失敗時に display_order が壊れる**: `StoreSectionPanel.MoveSection` が 2 セクションの `display_order` を `UpdateSection` の**別々の DB write 2 回**で入れ替えており、片方成功・片方失敗で**両者が同じ display_order になる half-write** が起きうる経路があった（#274（#253 part 2）レビューで指摘、intro 側（`IntroGuidePanel`）は #274 で解消済の同型バグ）。`StoreSectionRepository.SwapDisplayOrder`（2 件を **1 transaction** で atomic 入替）を追加し、`MoveSection` をそれに切替。`DatabaseManager.SwapSectionOrder` facade 追加。`DataLayerRoundTripTests.StoreSection_SwapDisplayOrder_SwapsAtomically` で検証。
- **swap の silent no-op を fail-loud 化（#275 review #1）**: `SwapDisplayOrder`（store / intro 両 repo）で、対象 row が他セッションに削除されている等で **2 行更新できなければ throw → rollback** に変更。旧実装は 0 行更新でも commit され「成功表示なのに無変更」になりえたが、`InvalidOperationException` を投げて caller の「並び替えに失敗」表示に乗せる。`StoreSection_SwapDisplayOrder_MissingRow_ThrowsInsteadOfSilentNoOp` で検証。

#### Bump 根拠 (v0.19.0 → v0.19.1)

既存コードの bugfix（並び替えの atomic 化）のため patch bump。スキーマ変更なし・後方互換。Bundle への反映は次回リリース実行時。

### [Manager v0.19.0] - 2026-05-31

#### Added (#253 part 2/3: 初回説明の編集パネル — Manager UI)

- **「初回説明」タブを追加**: スクリーンセーバー → ブラウズ間に毎回表示する案内スライド（来場者は入れ替わるため各人にとって初回）を Manager から編集できるようにした（ストアタブの次に配置）。スライドの**追加 / 編集 / 削除 / 並び替え（↑↓）/ 再読み込み**を `IntroGuidePanel`（`StoreSectionPanel` をミラーした UserControl）で提供。
- **スライド編集フォーム `IntroSlideEditForm`**: 本文（複数行・空可＝image-only）/ 画像（任意・プレビュー付き・空可＝text-only）/ 表示 ON-OFF を編集。本文も画像も無い空スライドは保存を弾く。UI は `ImageNameConflictDialog` と同じくコード組み（Designer なし）。
- **画像の `guide/` 取り込み**: 選択した画像を `guide/` フォルダ（`games/` の隣、`PathManager.GuideFolder`）へコピーし、DB（`intro_slides.image_path`）には `guide/<file>` の相対パスのみ保存（games のサムネと同流儀）。同名衝突は自動 suffix（`slide.png`→`slide_2.png`）。スライド削除時、その画像を他スライドが参照していなければ `guide/` から物理削除（orphan 防止）。
- **保存ロジックは helper に抽出してテスト**: `Services/IntroGuideAssetHelper`（画像コピー/衝突 suffix/削除のコア、PathManager 非依存）を `Manager.Tests/IntroGuideAssetHelperTests` 5 件で検証（copy→leaf 返却 / 衝突自動 suffix・上書きしない / 連番 increment / source 不在で例外 / guide 配下のみ削除）。
- **session conflict 準拠**: 追加/編集/削除/並び替え/保存の各 DB write 直前に `SessionConflictHelper.CheckBeforeWrite` を挟む（他 PC / Launcher 競合検出、StoreSectionPanel と同位置）。DB アクセスは `DatabaseManager` ファサード経由（`GetAllIntroSlides` 等を追加）。
- **design 変更（ユーザー feedback、DB v21→v22）**: part 1 で入れた自動送り `duration_sec` を**廃止**（来場者操作は**手動ナビ＝全スキップ + 次へ/戻る、自動送りなし**の方針に変更。手動ナビのボタン自体は Launcher 側＝part 3）。CHECK 付き列のため `MigrateV21ToV22` は table recreate で削除。あわせて呼称を「イントロガイド」→「**初回説明**」に統一（タブ名・フォームタイトル・session 操作ラベル）。Model/Repo/UI/テストから `duration_sec`(=秒) を全削除。
- **スコープ**: 本 PR は **#253 part 2/3（Manager 編集 UI）**。part 1（スキーマ、merged）の上に乗る。**part 3（Launcher の手動ナビ表示）は後続 PR**。WinForms の画面（タブ表示・並び・編集フォーム）は実機起動で目視確認済（ctor の `TabPages.Insert` がハンドル前 silent fail でタブ非表示になるバグも実機で発見・修正）。保存・画像コピーのコアロジックはテストで自動検証。

#### Bump 根拠 (v0.18.0 → v0.19.0)

新機能（初回説明の編集 UI）追加のため minor bump。**DB スキーマ v21→v22**（`duration_sec` 削除、`MigrateV21ToV22` の table recreate・後方互換）。Bundle への反映は次回リリース実行時。

### [Manager v0.18.0] - 2026-05-31

#### Added (#253 part 1/3: イントロガイドのスキーマ — intro_slides テーブル + migration)

- **`intro_slides` テーブルを新設（DB v20 → v21）**: スクリーンセーバー → ブラウズ間に表示する「イントロガイド」（展示の説明 / 楽しみ方 / 注意事項 等のスライド）のデータ基盤。列は `slide_id`（PK AUTOINCREMENT）/ `display_order` / `body_text`（空可＝image-only スライド）/ `image_path`（NULL 可＝text-only スライド・相対パス、画像実体は `guide/` フォルダにファイル別管理）/ `duration_sec`（自動送り秒数、CHECK 1-60）/ `is_visible`（削除せず一時非表示）。他テーブルへの FK 無しの独立テーブル。
- **スキーマワークフロー準拠（AGENTS §7.6）**: `SchemaManager.CurrentDbVersion` を 20→21 に増分、`CreateIntroSlidesTable` helper を `CreateTables`（新規 DB）と `MigrateV20ToV21`（既存 DB、`CREATE TABLE IF NOT EXISTS` で idempotent、manager_sessions v13 と同型）の双方から呼ぶ。migration dispatch に v21 ブロック（前段未完なら据え置きの guard pattern）+ `ExpectedSchema` に `intro_slides` を追記し SPEC §7.3 テーブル13 と同期。
- **モデル / リポジトリ**: `Models/IntroSlide.cs` + `Repositories/IntroSlideRepository.cs`（CRUD、`StoreSectionRepository` と同流儀。空/空白の `image_path` は DB 上 null に正規化）。
- **テスト**: `Manager.Tests/IntroSlideTests`（#239 基盤）に 5 件 — fresh DB が v21 到達・CRUD round-trip（image あり/text-only）・空 image_path の null 正規化・duration CHECK 違反の reject・v20→v21 migration がデータを保持しつつ intro_slides を追加。既存 v19→v20 migration テストの version アサートを動的ターゲット化（schema bump 耐性）。
- **スコープ**: 本 PR は **#253 part 1/3（スキーマ）**。本番 DB 作成より前にスキーマを確定させる目的。**part 2（Manager 編集パネル）/ part 3（Launcher スライドショー）は後続 PR**。

#### Bump 根拠 (v0.17.4 → v0.18.0)

新機能（新テーブル＋データ層）追加のため minor bump。DB スキーマ v20→v21（migration 付き・後方互換、既存 DB は自動で intro_slides を獲得）。Bundle への反映は次回リリース実行時（schema 変更を含むため Bundle は major 候補、リリース時に判断）。

### [Manager v0.17.4] - 2026-05-30

#### Fixed (#271: manager_sessions の clock drift / 破壊的 cleanup)

- **Manager 同士の同時起動検出も PC 間の時計ズレに弱く、しかも起動時 cleanup が生存中の遠隔 Manager の row を物理削除しうる欠陥**: `ManagerSessionService` の stale 判定は #269 の Launcher と同根で「読み手 `now` − 書き手自己申告 `last_heartbeat`」で計算するため clock drift を被る。さらに起動時 cleanup `DeleteStaleSessions(now-30s)` が**他 PC の row も 30 秒で DELETE**するため、読み手の時計が 30 秒以上進んでいると**生きている遠隔 Manager の row を消す → 検出から外れる → 両者が同時 write → DB 破損**（#179/#184 が防ごうとした本命の write×write 脅威）に倒れうる。Launcher（read 主体・過小警告）より高 severity。PR #270 レビューで指摘・コードで cross-verify。
- **修正① 検出 stale 閾値 30→60 秒**: `DetectOtherActiveSessions` の閾値をマージン化（heartbeat ×6）して読み手側 skew を吸収。DB ベースで per-row mtime が無く #269 の `max(json,mtime)` は使えないため、閾値が SMB 非依存でできる主防御。
- **修正② 起動時 cleanup を「1 日 abandoned 閾値」に変更**: cleanup は stale 閾値（60秒）ではなく `now − 1 日`の明らかに放置された row のみ削除し、**clock skew で生存中の遠隔 row を消さない**。自 crash 残骸は次回起動の UPSERT（pc_name PK 上書き）で回収、検出は query 時に 60 秒閾値で stale を除外するため放置 row が残っても誤検出しない。table は 1 PC 1 row のため緩い cleanup でも肥大しない。
- **スコープ外（SMB 確定後）**: 検出の根本解（共通参照時計＝サーバ時刻基準化、`net time` / マーカー mtime）は本番ファイルサーバの SMB 構成確認後の別案として #271 に残置。本 PR は SMB 非依存の閾値＋cleanup 限定に絞った。
- **テスト**: `Manager.Tests/ManagerSessionDriftTests`（#239 基盤）に 3 シナリオ追加 — stale だが放置でない他 PC row は cleanup で消えない（破壊的 DELETE を塞いだ核心）／1 日超 abandoned は消える／検出は 60 秒閾値。SPEC §3.8.2・§3.8.3・§7.3（変更履歴 v1.10.46）と同期。

#### Bump 根拠 (v0.17.3 → v0.17.4)

検出ロジック + cleanup の bugfix（clock drift / 破壊的削除の是正）のため patch bump。スキーマ変更なし・後方互換（検出が安全側に緩む + cleanup が保守的になるのみ）。Bundle への反映は次回リリース実行時。

### [Manager v0.17.3] - 2026-05-30

#### Fixed (#269: Launcher セッション stale 判定の clock drift 耐性)

- **PC 間の時計ズレで生存中の Launcher を「死亡」と誤判定し、競合警告から除外しうる欠陥**: `LauncherSessionService` の stale 判定は「読み手 PC の `now` − JSON 内 `last_heartbeat_at_unix_ms`（書き手 PC の自己申告時計）」で計算するため、PC 間 clock drift を直接被っていた。読み手 PC の時計が書き手より進んでいると、生きている Launcher が「30 秒超＝stale」と誤判定され検出リストから除外 → Manager 編集を続行 → **データ競合リスク（過小警告）**。多 PC 同時稼働（＝文化祭運用）で踏みうる。外部レビュー指摘をコードで cross-verify して確定。
- **修正: `max(JSON last_heartbeat, file mtime)` の新しい方で判定**: primary path で json（書き手自己申告時計）と file mtime（SMB サーバの**単一**時計）の新しい方を採用。これで「書き手 PC の時計が遅れて json が古く見える」case を mtime が救い、「mtime の SMB cache 遅延（~10 秒）」を json が救う＝**互いの弱点を補完**（どちらか fresh なら active）。表示用 `LastHeartbeatAtUnixMs` にも effective 値を入れ、active 判定と「最終確認 N 秒前」表示を一致させた。json が parse 成功の `"0"` でも `max(0, mtime)=mtime` に倒れ mtime 判定になる（壊れた 0 値を救う安全方向の挙動変化、#259 review #4）。**防御の分担（#270 review #3）**: `max` が無効化するのは**書き手側**の時計ズレ（書き手が遅れて json が古く見える）。**読み手 PC 自身**のズレは json/mtime 双方が読み手 `now` に対して古く見えるため `max` では救えず、下記の 60 秒閾値 + NTP 運用が吸収する。
- **⚠️ 前提（要実機検証、#259 review #1）**: 本 mitigation は **file mtime が SMB サーバの時計で刻まれる構成**に依存する。Launcher 書込側は timestamp を明示設定しない（確認済: `session_heartbeat.gd` は `store_string`→`rename_absolute` のみ）ため default SMB では前提成立だが、サーバ構成によっては書き手クライアント時計を反映しうる。**本番投入前に実機 SMB で要確認**（SPEC §3.8.7.3 F-1）。前提が崩れても `max` は fresh 方向のみ＝安全側で過小警告の新規回帰は無い（drift 防御が効かなくなるだけ）。
- **stale 閾値 30→60 秒に緩和**: 想定 skew をマージンで吸収（heartbeat 10 秒 ×6）。広げる方向は安全側（過剰警告）でデータ事故方向には倒れない。
- **残留リスクと運用**: ①読み手 PC 自身の時計が大幅に進む単機ケース（両者とも古く見え過小警告）→ 60 秒閾値 + NTP 同期で許容。②`max` が mtime を採るため、**死んだ Launcher の残骸 file の mtime を外部プロセス（バックアップ / ファイル同期 / 再 stamp 等）が touch すると、json が古くても false-active が続きうる**（過剰警告＝安全側、データ事故にはならない。次回同 PC で Launcher 起動時に同名 file が上書きされて解消。AV のスキャンは read だけで mtime を変えないため通常無関係。#270 review #2）。⚠️ `ManagerSessionService`（Manager-Manager 検出、DB ベース）も同じ drift を持つが per-row mtime が無く閾値のみが mitigation のため 30 秒のまま据え置き。**しかも起動時 cleanup の破壊的 DELETE で生存中の遠隔 Manager row を消しうる（write×write 破損）= Launcher より高 severity** のため別 issue **#271** で追跡（本 PR とは scope を分離）。
- **テスト**: `Manager.Tests/LauncherStaleDetectionTests`（#239 基盤）に 5 シナリオ追加 — json 古/mtime 新（drift 防御 + effective 値検証）、json 新/mtime 古（cache 遅延防御）、双方古（真の stale 除外）、45 秒（60 秒閾値内 active）、heartbeat field 欠落（fallback path も 60 秒閾値で判定）。SPEC §3.8.7.3（変更履歴 v1.10.45）と同期。

#### Bump 根拠 (v0.17.2 → v0.17.3)

検出ロジックの bugfix（clock drift 耐性）のため patch bump。スキーマ変更なし・後方互換（検出が安全側に緩むのみ）。Bundle への反映は次回リリース実行時。

### [Manager v0.17.2] - 2026-05-30

#### Fixed (#251: SessionConflictDialog の「他PC前提」文言を汎用化)

- **同時起動警告ダイアログが「他 PC」を前提にしていたが、同一 PC 上の Launcher も検出対象のためズレていた**: `SessionConflictDialog` は SPEC §3.8.7.6 のとおり**同一 PC 上で動く Launcher も検出**する（Manager 編集 × Launcher の SQLite read 競合も安全側で警告対象）ため、検出リストに自分の PC 名が並ぶケースがある。にもかかわらず文言が「**他 PC で** Manager / Launcher が稼働中」「**両方の PC で**同時に」「**他 PC の人に確認してから**」と他 PC 前提で、同一 PC 検出時に噛み合わなかった。Startup / EditOperation 両 context の title・body から「他 PC」前提表現を除去し、`別の Manager / Launcher` の汎用文へ統一（他 PC / 同一 PC どちらでも正しく読める）。title は両 context とも `【危険】別の Manager / Launcher が稼働中です` に統一。
- **文言のみ・挙動は不変**: 起動時 Cancel = Manager 終了（`MainForm` L453 `Close()`）/ 操作前 Cancel = その操作中止、検出ロジック・5 件 cap・merge 表示は変更なし。SPEC §3.8.2 / §3.8.7.4（変更履歴 v1.10.44）と同期。
- **内部記述も「他 PC」前提を一掃（#259 レビュー対応）**: user 向け文言だけでなく、同じ理由で誤りになる内部記述も統一 — enum `Startup` doc / `Show` method summary / `Logger.Warn` の「他 PC 検出」を「別の Manager / Launcher を検出」に（特にログは同一 PC Launcher 検出時に実態と食い違うため）。SPEC §3.8.1 構成要素の `SessionConflictDialog` 説明も同期（`ManagerSessionService` の「他 PC 検出 API」は Manager-Manager 限定で正しいため据え置き）。round-8 履歴コメントの旧引用文言に #251 で更に汎用化した旨を注記。

#### Bump 根拠 (v0.17.1 → v0.17.2)

表示文言のみの精度改善のため patch bump。スキーマ/挙動変更なし・後方互換。Bundle への反映は次回リリース実行時。

### [Manager v0.17.1] - 2026-05-30

#### Fixed (#206: ゲームID 検証エラーの理由別文言)

- **ゲームID が無効なとき、理由に関わらず「英数字…のみ」固定文言を表示していた**: `GameFormHelper.IsValidGameId(string, out errorMessage)` は理由別文言 (空 / 64文字超 / 文字種 / Windows 予約名 `CON`/`PRN`/`NUL`/`COM1` 等) を返せるのに、`AddGameForm` / `EditGameForm` の呼び出しが bool-only overload + ハードコード文言を使い**理由を握り潰していた**。64文字超や予約名で弾かれた user にも「文字種が悪い」と誤誘導する状態だった。両 callsite を `out errorMessage` overload に切替え、返ってきた理由別文言をそのまま MessageBox 表示する。**検証ロジックは不変・表示文言のみ**。`docs/usage/games.md` (#106) の「保存時に Manager が知らせてくれる」記述とも整合。
- **ID 重複エラーの文言が Add / Edit で不統一だった (follow-up)**: 追加 (`AddGameForm`: 「このゲームIDは既に…別のIDを入力してください。」具体 ID なし) と ID 変更 (`GameRepository.UpdateGameId`: 「ゲームID「{id}」は既に…」案内なし) で文言が違っていた。両者を `ゲームID「{id}」は既に使用されています。別のIDを入力してください。`（具体 ID + 案内の両取り）に統一。
- **`IsValidGameId` 直前の冗長な空チェックを削除し helper に一本化 (follow-up, #257 レビュー)**: `AddGameForm` / `EditGameForm` とも `IsValidGameId(out)` の直前に同一文言の `IsNullOrWhiteSpace` ガードが残っており、helper の「空」分岐 (同じ「ゲームIDを入力してください。」を返す) が dead code になっていた。コメントは「空 / …」を含むのに空欄が helper を通らない記述↔実装の不一致もあった。先行ガードを削除して空欄も `IsValidGameId` 経由に統一 (同文言・同 Focus・同 return で挙動不変)。

#### Bump 根拠 (v0.17.0 → v0.17.1)

表示文言のみの bugfix のため patch bump。スキーマ/挙動変更なし・後方互換。Bundle への反映は次回リリース実行時。

### [Manager v0.17.0] - 2026-05-30

> **（統合エントリ / 1 PR 1 bump）** 本エントリは PR #236 の内容を **1 バージョンに統合**したもの: #234 シリーズ（追加/編集/版アップのデータ整合性）+ 累積監査ラウンド 2〜9 + 復元後整合性チェック + `backup_log` 廃止→file-scan 化 + DB schema v16→v20。開発中は v0.16.5〜v0.21.0 と多数 bump したが未リリース（Bundle v0.7.0 が積んだのは v0.16.4）のため単一 bump へ圧縮。以下は実施順の **新→旧** で各ラウンドの詳細を保持し、テーマ（追加/編集/版up/バックアップ/復元/スキーマ）はラウンド間で重複する。旧版の区切りは `<!-- 統合元(旧): ... -->` コメントで追跡可能。なお本エントリ内に残る各 `#### Bump 根拠 (vX → vY)` 見出しは**統合前の各ラウンドの根拠**（履歴）であり、現行の単一 bump は **v0.16.4 → v0.17.0**。

#### Fixed (PR #236 レビュー対応: 復元失敗の通知改善 2 件 + コメント整合)

PR #236 のコードレビュー指摘のうち、復元系の「失敗をユーザーに正しく伝える」2 件を修正 (復元は使用頻度は低いが、失敗時の最悪挙動の可視性は本 PR 目的と直結)。指摘 #3 (exe 未設定ゲームの BrokenGames 計上) はレポートが既に「(実行ファイル未設定)」と明示しており起動不能ゲームとして赤表示するのは妥当と判断し据え置き、#4 の `foreign_key_check` hard-fail 提案は展示 PC の起動可用性優先 (warn 継続) のため不採用としコメント整合のみ実施。

- **#1 (RestoreService / BackupSectionPanel): 復元で toneprism.db が失われた最悪ケースが汎用エラーに埋もれる**: `File.Replace` fallback で現 DB 削除後に `File.Move` も失敗すると toneprism.db が不在になりうるが、`tempPathIsLastResort` フラグが caller に伝わらず「復元中にエラーが発生しました（詳細はログ）」の汎用 Abort メッセージしか出ず、ログを読まないスタッフが DB 喪失に気づけなかった。専用例外 `RestoreDbMissingException` を新設し Message に操作可能な復旧手順 (`.restore-tmp` を `toneprism.db` にリネーム / safety から復元) を入れて画面表示、`BackupSectionPanel` は汎用メッセージと区別して中止する。
- **#2 (RestoreReportForm): 復元後 migration 失敗 = スキーマで DB が読めない深刻状態が「軽微」色で表示**: `RestoreReconciliationService.Analyze()` が "no such column" 等で `AnalysisFailed` になると、レポート見出しが DarkOrange (注意) 止まりだった。critical 同等の Firebrick (赤) +「対処が必要」表記に変更し深刻度を正しく示す。
- **コメント整合 (stale)**: `RestoreService` finally の「`ReleaseRestoreLock` は LIKE 句で…」を実装 (exact-match SELECT+DELETE) に合わせて修正、`BackupCatalogService` の旧 `prism_` を「安全側 manual」→ 実装どおり「unknown 分類」に修正。
- **(追加レビュー対応, SchemaManager): v0 fast-path が `MigrateV19ToV20` を呼ばず `games.play_time` CHECK が付かない非対称**: versioning 導入前から `games` テーブルを持つ旧 v0 DB は `CreateTables` の `CREATE TABLE IF NOT EXISTS` が CHECK 無し games を温存するため、CHECK 不在のまま `user_version=20` を刻んでいた (本 PR が surveys/play_records で解消したのと同型の drift を play_time で 1 件残していた)。v0 path の `SetDbVersion` 直前に冪等な `MigrateV19ToV20` を追加 (新規 DB では CHECK 既存で no-op、範囲外データ残存時は warn + stamp 継続)。本番 (まっさら新規 install) は `CreateTables` 由来で元から CHECK を持つため非到達 (= 影響は旧 v0 DB 限定)。
- **(追加レビュー対応 #4, RestoreService): 復元前 safety スナップショットのファイル名に実行 PC 名が無く複数 PC の同時復元で上書きされうる**: auto/manual は `<種類>_<日時>_<host>.db` と host を埋め込むのに safety だけ `safety_<日時>.db` で host 無しだった。共有 `backups/safety/` で 2 台が同一秒に復元すると両者が同名を作り一方が他方の safety を Online Backup API で上書きしうる (衝突 suffix `_N` は自プロセス内のみで cross-PC を分離できない)。safety にも host を埋め込み `safety_<日時>_<host>.db` に統一 (`BackupService.SanitizeHostForFileName` を internal 化して流用、`BackupCatalogService` の `SafetyRegex`/`ExtractHost` は既に host セグメント対応のため履歴表示も追従)。
- **(追加レビュー対応 #5, SchemaManager): migration 例外時に `foreign_keys=ON` 復帰がスキップされる**: FK=ON 復帰が `using(transaction)` の後・`try` の外にあり、migration が例外で抜けると ON 復帰を通らず接続が FK=OFF のまま close していた。現状は pooling 無効 + 次回 open 時 ON 再設定で self-healing のため実害無しだが、将来 pooling 有効化で FK=OFF 接続がプールへ還る穴になりうる。FK=ON 復帰を `finally` に移して commit/rollback/例外いずれでも必ず実行 (復帰失敗は warn で握り潰し)。
- **(追加レビュー対応 #2, EditGameForm): 版重複チェックが VersionUpForm より弱く DB の NOCASE UNIQUE に raw で当たりうる**: `GroupBy` のキー比較が既定 Ordinal (case-sensitive) のため、正規化不能版の case 違い (例 `V1.0` vs `v1.0`) を UI 重複ガードが素通りし、DB の `UNIQUE(game_id, version COLLATE NOCASE)` に当たって `SQLiteException` (技術的エラー) として表面化していた。`GroupBy` を `StringComparer.OrdinalIgnoreCase` にして DB collation と整合させ、事前にフレンドリーな重複ダイアログで弾く。
- **(追加レビュー対応 #3, SchemaManager): `MigrateV19ToV20` の事前検査が play_time のみで difficulty CHECK を守っていなかった**: `games_new` は play_time / difficulty 両方に CHECK を強制するのに skip 判定は範囲外 play_time のみ数えており、CHECK 不在の旧 v0 DB 等で範囲外 difficulty があると INSERT-SELECT が throw → 起動失敗 (play_time の skip+warn と真逆) になる非対称があった。事前検査に difficulty の範囲外も加え、同じ skip+warn 経路に乗せた。

#### Changed (バックアップ履歴を `backup_log` テーブルから廃し、`backups/` フォルダ走査由来に再設計 — DB v19)

累積監査で見つかった「失敗した復元が次回のバックアップ画面更新で『成功』に化ける」欠陥の**根本原因**は、バックアップ履歴メタデータを「バックアップ対象である `toneprism.db` の中 (`backup_log` テーブル)」に持っていたこと。復元で DB が丸ごと置き換わるたびに履歴とディスク実ファイルが恒常的にズレ、それを埋める `Reconcile*` / `Register*` 系の後付けコード (`BackupLogRepository.cs` 800 行超の過半) がバグの温床になっていた。履歴を**ファイルシステムから導出** (種類別フォルダ + ファイル名) する設計に変更し、ズレの概念ごと根絶した。

- **`backup_log` テーブルを DROP (DB v18 → v19)**: `MigrateV18ToV19` が `DROP TABLE IF EXISTS backup_log` を実行。既存行は破棄されるが**物理バックアップファイルは残り、初回走査で履歴に復活**する (失われるのは失敗履歴と復元監査行のみ = いずれも要件上不要)。新規 DB は `CurrentDbVersion=19` で直接 stamp され `backup_log` を作らない (`CreateBackupLogTable` 本体は古い DB の v9 段階移行が呼ぶため残置)。`ExpectedSchema` からも除去。
- **新 `BackupCatalogService` + `BackupCatalogEntry`**: `backups/` 配下 (`auto/` / `manual/` / `safety/` + 旧フラット形式 `toneprism_*.db` / `prism_*.db`) を走査し、**フォルダ位置で種類・ファイル名で日時と実行 PC・`FileInfo` でサイズ**を導出する。`ScanAll` / `ScanAuto` / `GetLastSuccess` / `GetLastAuto` を提供。並び順はファイル名タイムスタンプ降順 (固定幅ゼロ埋めなので文字列ソート = 時系列)。保存先直下の旧フラット形式 (v0.20.0 以前) は auto/manual の区別がファイル名に無く復元不能なため**「不明」表示** (retention は `auto/` 限定なので不明扱いでも自動削除されない)。
- **実行 PC をファイル名に埋め込み**: バックアップファイル名を `<種類>_<日時>_<host>.db` に統一 (`SanitizeHostForFileName` で禁止文字除去 + 区切り `_`→`-`)。これにより「実行 PC」列を DB なしで維持しつつ、旧来アドホックだった同秒 LAN 衝突回避も一本化 (別 PC は host で自然分離、同ホスト同秒のみ `_2`/`_3`)。旧形式 (host なし) ファイルは PC 欄空表示 (新規バックアップから順に埋まる)。
- **履歴グリッドの列整理**: ファイル由来では開始 / 完了の区別が無く同値になるため、「開始日時 / 完了日時」の 2 列を「作成日時」1 列に統合。「実行PC」列は維持 (新規バックアップから host 入りで全行に表示される)。列幅は `AutoSizeColumnsMode=Fill` で grid 幅にちょうど収めて横スクロールを無くし、ファイルパスは余り幅を埋めて溢れは "…" 省略表示 + ツールチップで全文表示 (固定情報列は `MinimumWidth` で可読性確保)。
- **復元の監査は `safety_*.db` で代替**: 復元のたびに作られる退避スナップショットが「いつ復元したか」の証跡を兼ねる (専用 audit 行 `LogRestoreCompleted` を廃止)。失敗履歴は Logger (ファイルログ) のみに残す (状態列は #200 で撤去済・failed 行は元々自動掃除のため UI 上の損失なし)。
- **retention をファイル走査に**: `ApplyRetention` は `auto/` のファイルをファイル名降順で keep 件残し残りを削除 (DB 駆動の `GetAutoSuccessRetentionTargets` / DB 行削除失敗時の failed 格下げを全廃)。auto 限定はフォルダ分離で構造保証、並行 retention の `File.Delete` 競合は握って冪等。
- **削除コード**: `Repositories/BackupLogRepository.cs` / `Models/BackupLogEntry.cs` / `Services/BackupPathResolver.cs` を撤去。`MainForm` 起動時・復元後の `ReconcileInProgressEntries` / `RegisterUnknownSafetyFiles` 呼び出しと付随ヘルパ、`BackupSectionPanel.CleanupFailedEntries` も削除。

#### Fixed (上記再設計で根治した欠陥)

- **失敗した復元が「成功」に化ける (Medium)**: `ReconcileInProgressEntries(recoverFailedWithExistingFile)` の救済 SELECT が `trigger_type` を絞らず、復元失敗で残った `failed`/`restore` 行を「復元元ファイルが実在する」だけの理由で `success` に蘇生していた (復元元は失敗時に消えないため必ず実在 → 必ず誤蘇生)。`CleanupFailedEntries` の「restore/safety failed は監査証跡として保護」と正面衝突していた。`backup_log` 廃止で `failed`/`restore` 行自体が存在しなくなり原理的に消滅。
- 同根の「復元後の自己参照スナップショットゴースト」「retention の DB↔ファイル drift (#10)」も同時に消滅。
- **プロジェクト移動耐性が無償化**: 常に現在の保存先を走査するため `relative_path` 追従機構が不要に。

##### 協調機構は不変

複数 PC の自動バックアップ排他 (`settings.last_backup_at` lease) と復元 advisory lock (`settings.restore_lock_owner`) は `backup_log` ではなく `settings` テーブルにあり、本変更の影響を受けない (SMB 上のファイルロックは不安定で DB トランザクションが正しい primitive のため意図的に DB のまま維持)。

#### Fixed (バックアップ/ゲーム管理まわりの追加監査: スキーマ migration drift 2 件)

ユーザー依頼の「ゲーム追加・編集・バージョンアップ / DB バックアップまわりの欠陥精査」で発見した残存事項。中核ロジック (トランザクション境界・atomic ファイル置換・復元の safety 退避・並行 race・lease/lock) に Critical/High 級の欠陥は無かったが、スキーマ migration の非対称を 2 件修正した。

- **v0 fast-path が `MigrateV10ToV11` を飛ばす drift (潜在)**: `SchemaManager.CheckAndMigrateDatabase` の `user_version==0` 分岐は `MigrateV13ToV14` (games.arguments) / 条件付き `MigrateV17ToV18` (developers FK) / `EnsureSettingsTableIsKvsSchema` (settings KVS) は明示 retrofit するのに、`MigrateV10ToV11` (surveys/play_records の旧スキーマ→新スキーマ drift 修正) だけ呼んでいなかった。versioning 導入前から旧 surveys/play_records を持つ v0 DB は、`CreateTables` の `CREATE TABLE IF NOT EXISTS` が旧スキーマを温存するため drift が残ったまま v19 を刻み、以後 migration 経路に乗らず永久固定されていた。冪等な `MigrateV10ToV11` を `SetDbVersion(19)` の前に明示実行する (新規 DB では新スキーマ検出で no-op、旧スキーマ空テーブルは再作成、データ残存時のみ skip+警告)。現状の実害はほぼゼロ (surveys/play_records は Manager 未参照 + 2026-05-27 以降の本番はまっさら新規で `CreateTables` が新スキーマ作成) だが、issue #35 (アンケート実装) 着手時に旧 v0 DB が残っていると壊れる時限要素を解消。
- **`games.play_time` の CHECK 制約欠落を DB レベルで復元 (SPEC drift, #247, DB v19 → v20)**: `CreateTables` の `games` は `difficulty INTEGER CHECK(difficulty BETWEEN 1 AND 3)` は持つのに `play_time INTEGER` は CHECK なし。SPEC §7.3 と初代スキーマは両方 `CHECK(1-3)` で、新規DB/旧DB/SPEC の三者 drift だった (`VerifySchema` は列名のみ比較で CHECK 差を検知しない)。`difficulty` との非対称解消 + SPEC 整合のため `MigrateV19ToV20` で `games` テーブルを recreate し CHECK を追加 (CreateTables 側も CHECK 付きに更新、新規DBは native に持つ)。
  - **親テーブル recreate の FK 安全策**: `games` は game_versions / developers / play_records / surveys / store_section_games が ON DELETE CASCADE、launcher_surveys が ON DELETE SET NULL で参照する**親テーブル**。foreign_keys=ON のまま `DROP TABLE games` すると暗黙 DELETE が CASCADE 発火で子行を全消去する。`defer_foreign_keys` は検査遅延のみで CASCADE action を止めない (同梱 sqlite3 で実測確認)。よって `InitializeDatabase` を「**migration 検出時のみ** transaction 開始前に `PRAGMA foreign_keys=OFF` → commit 前に `foreign_key_check` で整合検証 → 後に ON へ復帰」する形に変更 (SQLite 公式のスキーマ変更手順)。通常起動 (version == CurrentDbVersion) は FK=ON のまま既存挙動を維持し blast radius を migration 時に限定。
  - **検証**: 移行 SQL を実スキーマ相当 (games + 全 CASCADE/SET NULL 子テーブルにデータ) で round-trip テストし、全子テーブル行の保全・`foreign_key_check` 整合・CHECK の 1-3 強制 (NULL は許容)・recreate 後も CASCADE 健在を確認。`MigrateV19ToV20` は冪等 (既に CHECK を持つ games では skip)。範囲外 play_time の既存行があれば (UI は 1-3 しか書かないため通常発生しないが外部 DML 等の保険) **hard-fail で起動を止めず skip + 警告 + retry** に倒す (user_version 19 据え置き、sqlite3 で是正後に次回起動で適用。V14→V15 / V16→V17 の重複時 skip+retry と同パターン)。silent な値書き換えはしない。

#### Bump 根拠 (v0.20.0 → v0.21.0)

DB スキーマ破壊的変更 (v18 → v19 `backup_log` DROP、および同 PR 追補の v19 → v20 `games` recreate で `play_time` CHECK 追加, #247) を含むため minor bump。元ブランチ (`fix/version-up-dup-guard`) の想定を超える再設計のため v0.20.0 entry には folding せず新 entry を立てた (AGENTS.md「想定範囲を超える機能追加が混入した場合は例外として新規 version エントリ可」)。既存運用 DB は起動時に自動 migration (v19 → v20 は foreign_keys=OFF + foreign_key_check で子テーブルを保全しつつ recreate)、物理バックアップファイルは保持され履歴に復活するため後方互換あり。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.20.0 - 2026-05-29 -->

#### Changed (バックアップ保存レイアウトを種類別サブフォルダ + 種類接頭辞に統一)

バックアップ保存先を **種類ごとのサブフォルダ + `<種類>_<日時>.db` 命名** に変更した。退避 (safety) が既に `backups/safety/safety_*.db` とフォルダ + 名前の両方で種類を持っていたのに、自動 (auto) / 手動 (manual) は `backups/toneprism_*.db` に混在して**ファイル単体からは種類を区別できない**非対称があり、これが「復元で `backup_log` がスナップショット時点に巻き戻り、孤児ファイルの種類を復元できず一律 manual 扱い → auto が世代管理 (retention) から永久に外れて溜まり続ける」(v0.19.1 で「除外: 受容仕様」とした項目) の根本原因だった。

```
backups/
  ├ auto/    auto_20260529_143000.db      ← 自動 (retention 対象)
  ├ manual/  manual_20260529_150000.db    ← 手動 (retention 対象外)
  └ safety/  safety_20260529_152000.db    ← 復元前の退避 (既存のまま不変)
```

- **保存 (`BackupService.RunBackupCore`)**: `GetEffectiveDestinationDirectory()/<種類>/` 配下に `<種類>_<日時>.db` で書き込む (`triggerType` = `auto` / `manual` をそのままフォルダ名 + 接頭辞に流用)。衝突 suffix (`_2` / `_<PC名>`) は従来通り。
- **孤児再登録 (`BackupLogRepository.RegisterUnknownBackupFiles`)**: 走査を 3 系統に拡張し、`auto/` 配下は `auto`、`manual/` 配下は `manual` として「**フォルダ位置で種類を確定**」して再登録する。これにより `backup_log` を失った auto 孤児が正しく `auto` で復活し、retention が再び効く (Finding 4 根治)。1 フォルダ分の登録処理は `RegisterUnknownInFolder` helper に抽出。
- **safety は完全に現状維持** (`backups/safety/safety_*.db`、移行ロジック・retention とも不変)。
- **本体 DB `toneprism.db` のリネームは見送り** (本番稼働中で Launcher/Manager 両参照 + プロジェクトルート検出キー + 既存実データの移行が必要なため、別 issue で慎重に扱う)。

##### 後方互換

移行前に `backups/` 直下へ直接保存された旧 `toneprism_*.db` はその場所のまま残し、(a) 既存の `backup_log` 行がある間は従来通りの種類で表示、(b) 孤児化した場合は種類不明のため安全側の `manual` で再登録 (= 誤って世代管理対象にして手動バックアップを消さない)。物理ファイルの移動・改名は一切行わない (実データを触らない安全方針)。新規バックアップから新レイアウトで書き、retention で旧 auto が消えるにつれ自然に新レイアウトへ収束する。

#### Fixed (累積監査ラウンド 7: ゲーム編集の画像コピー順序 / 自動検出漏れ / 走査性能の 3 件)

round 6 (v0.19.1) リリース後、ゲーム追加 / 編集 / バージョンアップ / バックアップ / 復元の各経路を再精査。実コード verify で真と確認した bugfix 2 件 + perf 1 件を修正。バックアップ / 復元の致命経路 (partial-commit 窓 / advisory lock / atomic File.Replace / reconcile) は round 1〜6 で塞ぎ済で、本ラウンドの新規発見は編集フォームの局所欠陥に限られた。

- **(EditGameForm): バージョン番号変更とフォルダ外画像指定を同一保存で行うと保存不能 + 孤児フォルダ残留**: `CopyExternalImagesToVersionFolder` が **rename 後の新しい版名** (`SaveGameDataToVersion` で更新済の `currentVersion.Version`) でコピー先 `v{newVersion}/` を計算し `Directory.CreateDirectory` で**先に作成**していた。その後のバージョンフォルダ rename が「移動先 `v{newVersion}/` が既に存在」で Phase 1 衝突 check に弾かれ、(a) 正当な操作 (番号修正 + 画像差し替え) が「フォルダ衝突」エラーで保存不能、(b) 画像だけ入った `v{newVersion}/` が孤児として残留 (Cancel 時に `OnFormClosing` が画像は消すがフォルダは残す)、(c) リトライで番号を戻すと実在しない版フォルダを指すパスが DB に入る軽度ドリフト、が起きていた。exe パスと同じく「画像は**旧 leaf のフォルダ**に置く → rename で一緒に移動 → `ReplaceVersionPrefix` で保存パスを新 leaf に書き換え」へ揃え、`_originalVersionByDbId` の snapshot から on-disk 版名を引いてコピー先を決めることで衝突を構造的に排除 (番号未変更 / 画像のみの通常経路は挙動不変)。
- **(GameFormHelper.AutoDetectFiles, #207): 画像自動検出から `thumbnail.jpg` が漏れ**: 検出パターンが `thumbnail.png` のみで `thumbnail.jpg` が無く、jpg のサムネイルが自動検出されず手動指定を強いられていた。`thumbnail.png` の直後に `thumbnail.jpg` を追加 (png 優先 → 無ければ jpg の順)。
- **(VersionRepository.GetByGameId, perf): 版の走査で `reader.GetSchemaTable()` を行ごとに呼ぶ無駄**: `update_note` 列の有無判定で行ごとに `GetSchemaTable()` (= DataTable を毎行アロケート) を呼んでおり、版が多いゲーム × 全件走査 (復元整合性チェック等) で性能を浪費していた。列存在は結果セット全体で一定のためループ前に 1 回だけ判定する形に変更 (未 migrate DB を読む防御としての presence check 自体は維持)。

#### Fixed (累積監査ラウンド 8: 復元 / 整合性チェック / バージョンアップ / 自動バックアップの異常系堅牢化 7 件)

round 7 (本 entry) 後、ゲーム追加 / 編集 / バージョンアップ + DB バックアップ / 復元の各経路をさらに再精査。実コード verify で真と確認した欠陥 7 件を修正。いずれも正常系ではなく **異常系 (失敗時の後始末・不正データ・姉妹フォーム間の非対称)** の取りこぼしで、正常系の経路 (partial-commit 窓 / advisory lock / atomic File.Replace 主経路) は round 1〜7 で塞ぎ済。

- **(RestoreService, High): `File.Replace` fallback で現 DB と一時コピーの両方を失う致命経路**: SMB DFS / Junction / 別ボリュームで `File.Replace` が失敗した際の fallback (`File.Delete(dbPath)` → `File.Move(tempPath, dbPath)`) で、Delete 成功後に Move が失敗すると例外が外側 catch に伝播し、そこで「DB 無傷」前提のまま唯一残った `tempPath` (= 復元データ) まで削除していた (= 現 DB も復元データも消失、復旧は safety バックアップ手動のみ)。`FallbackDeleteAndMove` helper + `tempPathIsLastResort` フラグで「Delete 後 Move 失敗 = point of no return 越え」を外側 catch に伝え、tempPath を保全 + 手動復旧手順 (`.restore-tmp` → `toneprism.db` リネーム / safety から復元) をログ出力する。
- **(RestoreReconciliationService, High): `version` 空文字の行 1 件で復元後整合性チェックが全停止 → 偽の「問題なし」通知**: `game_versions.version` は `NOT NULL` だが `CHECK(<>'')` が無く空文字を許容。版ループが `PathManager.GetVersionFolderLeaf("")` の `ArgumentException` を catch しておらず、1 行の不正で `Analyze()` 全体が中断 → 呼び出し側 (BackupSectionPanel) が握り潰して「整合性に問題なし」と誤通知し、起動不能ゲーム・孤児フォルダを全件隠蔽していた。版ごとに空文字ガード + try/catch を入れ、不正版のみ skip + 警告して他ゲーム / 他版の検査を継続する。
- **(VersionUpForm, Med-High): 人数が範囲外のコピー元版でバージョンアップ画面がクラッシュ**: `numMinPlayers.Value = baseVersion.MinPlayers ?? 1` の生代入が値 0 / 100+ で `ArgumentOutOfRangeException` を投げ、`Form_Load` が落ちて画面が開けなくなっていた (呼び出し側は `ShowDialog` を try/catch していない)。EditGameForm が既に使う `GameFormHelper.SetClampedNumericValue` (clamp + warn ログ) に置換して対称化。
- **(SettingsRepository / BackupService, Med): 自動バックアップ失敗時に lease (`last_backup_at`) が前進したまま戻らず、次 interval (既定 24h) まで再試行されない**: `TryAcquireBackupLease` が本体実行前に `last_backup_at = now` を即コミットし、本体が失敗 / キャンセルしても巻き戻していなかった。保存先設定ミス等で失敗が続くとバックアップが 1 件も取れない状態が放置される。lease 取得時に直前値を out で返し、失敗 / キャンセル時に `RollbackLeaseOnFailure` で巻き戻して次回起動で再試行されるよう変更 (自動バックアップは `MainForm.StartAutoBackupIfDue` で起動時 1 回呼びのため、巻き戻しても連射 / 警告 modal 連発にはならない)。
- **(EditGameForm / ImageNameConflictDialog, Med): 別フォルダの同名画像 2 枚を同時取り込みすると保存不能**: `ResolveCopyPlan` がコピー先衝突を disk の `File.Exists` のみで判定し、実コピー前は両方 false で同一 destination を予約 → 後段の `File.Copy(overwrite:false)` で 2 枚目が `IOException` (破壊はなく abort)。計画内で予約済みの destination を共有 `HashSet` で衝突扱いにし、`SuggestNonConflictingFileName` も予約済みを回避するよう拡張 + dialog 確定後の再衝突 check を追加。
- **(EditGameForm, Low): 非アクティブ版の難易度 / プレイ時間を「表示しただけ」で NULL → 既定値に化ける非対称**: Min/MaxPlayers には NULL 保護 snapshot があるのに difficulty / play_time には無く、NULL の非アクティブ版を選択 → 別版へ切替で既定値 (普通 / 5-15分) が書き込まれていた。人数と同じ `WasNullOnLoad` + `DisplayedOnLoad` snapshot を difficulty / play_time にも追加 (NULL かつ user 未操作なら NULL 維持)。実運用で NULL が入る経路は限定的 (Add/VersionUp は常に ≥1 を書く) だが非対称を解消。
- **(GameSectionPanel / AddGameForm, Low): `ProcessingDialog` の Dispose 漏れ**: バージョンアップ / ゲーム追加経路のみ `ProcessingDialog` を `using` で囲まず、ネイティブハンドル + 内部 `CancellationTokenSource` を GC 任せにしていた (他の全箇所は using)。両経路を using に統一。

#### Fixed (累積監査ラウンド 9: ゲーム追加/編集/バージョンアップ + バックアップ/復元の残存欠陥 6 件)

round 8 (本 entry) 後、ユーザー依頼でゲーム追加 / 編集 / バージョンアップ + DB バックアップ / 復元を 5 領域に分けて再精査。実コード verify で真と確認した欠陥 6 件を修正 (正常系・トランザクション境界・削除孤児・復元ロールバックは round 1〜8 で塞ぎ済で、本ラウンドの新規発見は「正常に見えて silent に欠落」「異常系・姉妹フォーム間の非対称」「並行 race ガードの stale flag」「集計の二重計上」に限られた)。先に Med 2 件 (外部画像 / 除外フォルダ)、続けて残り 4 件 (並行 race / 全版検証 / バックアップ検証 / 復元レポート) を同 entry に追記。

- **(EditGameForm, Med): バージョンを切り替えると「フォルダ外から選んだ画像」が無警告で消える**: 外部 (gameFolder 外) のサムネ / 背景を選んだあと OK 前に別の版へ切り替えると、`SaveGameDataToVersion` → `ApplyRelativePaths` → `NormalizeRelative` が絶対 path を null へ格下げ (Logger.Warn のみ・UI 無通知) し、版オブジェクト・textbox の双方から選択が消失。OK 時のコピー (`CopyExternalImagesToVersionFolder`) は「表示中の版」しか対象にしないため、切替を挟むと選択が永久に失われていた (フォルダ内画像は round-trip するため影響なし、外部選択に限定)。版 id 単位の `_pendingExternalThumbnail/BackgroundByVersionId` map に外部 path を控え、(a) 切替で戻ったとき `LoadGameDataForVersion` で textbox へ復元、(b) OK 時に表示中以外の版も `CopyPendingExternalImagesForHiddenVersion` で各版フォルダ (rename 前 leaf) へコピーし版オブジェクトの相対 path を確定 (rename ループの `ReplaceVersionPrefix` が新 leaf へ追従、rollback snapshot も正しく capture)。コピーを OK まで遅延する既存方針 (disk を触らない / Cancel で orphan 削除) は維持し、選択の「記憶」だけ in-memory で持ち越す。ProcessingDialog のコピー実行部は `ExecuteImageCopyPlan` に共通化。
- **(FileOperationService / GameFormHelper, Med): コピー除外フォルダに実体があるゲームが silent に不完全コピーで登録される**: コピー除外リストに `Build` / `Builds` / `Saved` / `Logs` / `Temp` という「ゲーム本体の中身にもなりうる総称名」が含まれ、exe / 画像がフォルダ直下にある限り 3 点の post-copy 存在チェックを全通過 → 必要フォルダが欠落したまま「追加成功」していた (Unreal の `Saved`、配布物の `Build` / `Builds` 等で踏みやすい)。さらに自動検出 (`AutoDetectFiles`) は除外フォルダ内の exe も候補にするのにコピーは除外する非対称で、exe が `Build/` 内のゲームは「自動検出されたのにコピー後に見つからず rollback」という不可解な行き止まりになっていた。(a) 除外対象を「再生成可能でほぼ確実に出荷物でない」engine cache (`Library` / `Intermediate` / `DerivedDataCache` / `.import`) + VCS / IDE / 言語キャッシュ (dotfiles 系) に限定し、総称名 `Build` / `Builds` / `Saved` / `Logs` / `Temp` を除外リストから撤去、(b) コピー直前に残る除外フォルダ (`Library` / `node_modules` 等) を `FileOperationService.FindExcludedFolderNames` で列挙し `GameFormHelper.ConfirmExcludedFoldersBeforeCopy` で明示確認 (silent に落とさず続行可否をユーザーに委ねる)、(c) 自動検出も `IsInsideExcludedFolder` で除外フォルダ内を候補から外し非対称を解消。Add / バージョンアップ両経路で共通適用。
- **(AddGameForm, Low-Med): ゲーム追加に一度失敗した後の再挑戦で、並行 Manager の作成済み版フォルダを誤削除しうる**: M7 の「自分が作った disk 状態だけ自分で消す」flag 群 (`baseGameFolderCreated` / `versionFolderCreatedThisCall` / `destinationGameFolder` / `baseGameFolder`) が OK クリック間でリセットされず (リセットされていたのは `wipeExistingOnCopy` のみ)、1 回目 OK が CopyGameFolder で flag を立てた後に失敗 → cleanup で folder は消すが flag は stale true のまま残存。2 回目 OK で wipe-check の DB 再 check が `destinationGameFolder` 再代入より前に早期 throw すると、`CleanupCopiedFoldersOnRollback` が stale な `destinationGameFolder` を「自分が作った」と誤認して削除し、同 gameId で先に追加を完了した並行 Manager (勝者) の version フォルダを巻き込む footgun があった (M7 ガードが stale flag で無効化)。`btnOK_Click` 冒頭で 4 flag を `wipeExistingOnCopy` と同様にリセットして構造的に閉鎖 (CopyGameFolder で必ず再代入されるため通常経路は不変)。
- **(EditGameForm, Low): 非表示版の「最小プレイ人数 > 最大プレイ人数」が OK 時に見逃される**: OK 時の `ValidateInput` → `ValidatePlayerCount` は表示中の NumericUpDown 値しか検証せず、ある版を min>max にしたまま別の版へ切り替えて OK すると、版切替時の `SaveGameDataToVersion` が無検証で commit した矛盾値が素通りしていた (SemVer 重複は `cmbVersionList.Items` 全件 scan するのに対し非対称)。OK 時に全版を走査し min>max (両方非 null のとき) の版を列挙して block する形に揃えた。起動は壊れないが Launcher の人数表示が乱れるデータ品質欠陥。
- **(BackupService, Low/防御的): バックアップ成功記録の前に出力 DB を検証していない**: `BackupDatabase` が例外を投げずに戻れば中身を検証せず `MarkSuccess` しており、理論上は空 / 不完全な出力でも success として記録され「復元すると空」の最悪事故余地があった (実際は全ページ一括コピー + 失敗時例外でほぼ起きないが、本番直前の致命度を考え保険を追加)。成功記録の前に (a) ファイル存在 + サイズ > 0、(b) `PRAGMA quick_check` = "ok" を検証し、NG なら例外 → 既存 catch で failed 記録 + ファイル削除 + lease 巻き戻しに流す (`VerifyBackupIntegrity`)。検証接続が残しうる -wal/-shm/-journal sibling は検証後に再掃除。
- **(RestoreReconciliationService, Low): 復元後整合性レポートでアクティブ版のサムネ/背景欠落が二重カウント**: 版ループの `if (!isActiveVersion)` ガードが exe check しか包んでおらず、thumbnail / background check はガード外で全版 (アクティブ含む) を検査していたため、アクティブ版の画像欠落が games 経路 (`game.ThumbnailPath`/`BackgroundPath`) と版経路 (`v.*`) で 2 件計上され、レポートの「欠落 N 件」が実数より多く表示されていた (データ・復元動作への影響はなく表示のみ)。画像 check も exe と同じくガード内へ移し、アクティブ版は games 経由の 1 回だけ数えるよう修正。

#### Bump 根拠 (v0.19.1 → v0.20.0)

バックアップ保存レイアウトの変更 (= 観測可能な挙動 / 配置変更) を含むため minor bump。schema 変更なし・後方互換あり (旧 `toneprism_*.db` も引き続き読める)。round 7 の bugfix/perf 3 件 + round 8 の異常系 bugfix 7 件 + round 9 の残存欠陥 6 件 (外部画像 / 除外フォルダ / 並行 race flag / 全版人数検証 / バックアップ検証 / 復元レポート) も同 entry に統合 (PR 内 1 bump 原則: 新規 version エントリを作らず本 entry に加筆)。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.19.1 - 2026-05-29 -->

#### Fixed (累積監査ラウンド 6: ゲーム追加/編集/バージョンアップ/バックアップ/復元/スキーマの残存欠陥 17 件)

round 5 (v0.19.0) リリース後、6 領域 (追加 / 編集 / バージョンアップ / バックアップ作成・保持 / 復元・整合性 / スキーマ・DB 接続層) を独立並列で再精査。Agent 報告 25 件超のうち、**実コード verify で真と確認した High 9 / Medium 8 = 計 17 件**を修正。残り 5 件は「設計通り / 到達不能」、3 件は「本番 (新規インストール) では非到達 or 効果に対し実装が過大」として実コード根拠付きで見送り (本 entry 末尾「除外」参照)。schema の最終形 (v18) は不変のため patch bump。

**【High】**

- **H1 (AddGameForm + DatabaseManager): ゲーム追加が games INSERT と初期版 INSERT の別 transaction で partial-commit 窓**: 旧実装は `AddGameAtTop` (games 行 commit) → `AddGameVersion` (初期版 commit) を順次実行しており、前者 commit 直後の電源断 / SMB disconnect で「games 行はあるが game_versions ゼロ件」の起動不能孤児ゲーム (Launcher 一覧に出るが版が無く起動不可) が残る経路があった。`DatabaseManager.AddGameAtTopWithInitialVersion` を新設し、display_order の MIN-1 採番 + games INSERT + 初期版 INSERT を 1 つの Serializable transaction に統合 (`AddVersionAndActivate` / `UpdateVersionsAndGame` と同設計)。初期版の `GameId` も追加対象 game の id に強制して caller 取り違えの二段保険を入れる。
- **H2 (VersionRepository.InsertVersionDevelopers): 製作者の null フィールドが games 側と非対称に DB 流入**: `GameRepository.InsertDevelopers` は `?? ""` で null を空文字に正規化していたのに、version 別 INSERT 側は素通しで、同じ user 入力が games 側 developers では `""` / version 側 developers では `NULL` に乖離していた。後段の集計 / 表示 (null と空文字を区別する経路) で NRE / 不整合を招くため `LastName` / `FirstName` / `Grade` を `?? ""` で揃える。
- **H3 (EditGameForm.SaveGameDataToVersion): version.Developers の浅いコピーで版間 aliasing**: `new List<DeveloperInfo>(developers)` は List だけ新規で中身の `DeveloperInfo` インスタンスを版間で共有し、ある版の製作者を編集すると別の版にも波及しうる温床だった。AddGameForm / VersionUpForm と同じくフィールド単位のディープコピーに変更し、版ごとに独立実体を持たせる。
- **H4 (VersionUpForm.ValidateInput): path textbox 直接編集が `RelativeExecutablePath` に反映されず保存される silent corruption**: v0.19.0 Phase D で `txtExecutablePath` を編集可能化したが、TextChanged は `/`→`\` 正規化のみで `RelativeExecutablePath` を更新しなかった。「autodetect された path が違うので手で別 exe に書き換えて OK」すると、ValidateInput は編集後 textbox 値で File.Exists + IsPathInside を通すのに、DB 保存に使う `RelativeExecutablePath` は autodetect 時の古い値のまま → 古い exe を指す path を保存 → コピーした新 exe が起動できない (フォルダ丸ごとコピーで両 exe が版フォルダに存在するため欠落 check も素通り)。検証通過時点で textbox を SoT として相対 path を再計算する。
- **H5 (VersionUpForm.ValidateInput): dup guard の fallback が空リストを素通り**: 重複チェックの fallback が `existingVersionStrings ?? new List{currentVersion}` で null のみ拾い、game_versions ゼロ件 (過去の中断で games 行だけ残った等) で caller が渡す空 list を素通りさせ、dup check 全 skip → games.version と同じ番号を再入力できる穴があった (UNIQUE INDEX も空集合には発火しない)。`!= null && Count > 0` に変更して空時は currentVersion 単体と比較する。
- **H6 (BackupSectionPanel + BackupLogRepository): backup_log を失った orphan バックアップファイルが「見えず・消えず」永久蓄積**: 復元で backup_log がスナップショット時点の古い状態に置換されると、スナップショット後〜復元前に取られた自動バックアップの log 行だけが消えてファイル実体が残る orphan が生じる。旧実装ではこの orphan は (a) 履歴グリッドに出ず運営から見えない、(b) retention は backup_log 駆動なので永久に削除対象外、という二重の死角だった。`RegisterUnknownBackupFiles` を新設し、保存先フォルダ内で backup_log 未登録の `toneprism_*.db` を `trigger_type='manual'` (= 自動削除対象外 + 履歴/削除 UI に表示 + 復元可能) で可視化 (削除は一切しない安全方針)。**(本 PR 検証で追補)**: 当初の重複判定が `file_path` のみで、SMB 共有運用 (本番) で他 PC が取った auto バックアップを表記揺れ (UNC `\\srv\...` ↔ ドライブ文字 `Z:\...`、GetFullPath でも解決不能) で取りこぼし → manual で重複登録 → その行が retention 対象外になり「auto を manual 化して世代管理から外す」副作用が生じる穴があったため、PC 非依存の `relative_path` (dbDir 基準) も dedup キーに併用して塞いだ。
- **H7 (MainForm): 自動バックアップ失敗が 7 秒のステータス表示のみで運営が気づけない**: 保存先 path の綴り間違い等で毎回静かに失敗していても、失敗履歴は次回 `CleanupFailedEntries` で掃除されるため画面に痕跡が残らず、「いざ復元しようとしたら過去ぶんが 1 件も無い」最悪ケースに直結していた。自動バックアップ失敗時に modal で明示通知 (保存先 / 空き容量 / 書込権限の確認を促す) して見落としを防ぐ。
- **H8 (RestoreService.ApplySafetyRetention): 復元レポートが案内する safety ファイルが間引かれて消える**: 退避 safety を 10 個まで残す retention で、NTFS の CreationTime 解像度 (約 2 秒) により同一秒に複数 safety が並ぶと `OrderByDescending` のタイ順序が不定になり、本来最新の今回 safety が Skip 境界に落ちて削除されうる。RestoreReportForm が「元に戻すならここ」と案内する path が表示時点で消える事故になるため、今回作成した safetyPath を削除候補から明示除外する。
- **H9 (SchemaManager): user_version=0 の旧 DB をアップグレードすると developers の FK が欠落したまま v18 を名乗る**: versioning 導入前から developers テーブルが存在する旧 DB は、CreateTables の `CREATE TABLE IF NOT EXISTS` が既存テーブルを温存するため、v18 で追加した version_id / game_id の FK + ON DELETE CASCADE が付かないまま user_version だけ 18 に刻印される drift があった (VerifySchema は列名のみ検証で FK 欠落を見逃す)。`DevelopersHasVersionIdForeignKey` (`PRAGMA foreign_key_list`) で FK 欠落を検出した場合のみ v0 path で `MigrateV17ToV18` を retrofit する (新規 DB は FK 付きで作られるため検出で skip、common path に table recreate コストを乗せない)。

**【Medium】**

- **M1 (SPECIFICATION.md): §7.3 ドリフト — 廃止済 `game_genres` がテーブル / リレーション / ER 図に残存**: v18 (`MigrateV17ToV18`) で DROP 済 + `ExpectedSchema` からも除去済なのに、SPEC §7.3 テーブル7・§7.4 リレーション・ER 図・機能「ゲーム削除」CASCADE 一覧に `game_genres` が現役テーブルとして残っていた。AGENTS.md「SPEC ↔ ExpectedSchema 同期」則に従い「DB v18 で廃止」へ更新 (テーブル番号は後続参照を壊さないよう欠番で残置)。
- **M2 (VersionUpForm): 新版の製作者 GameId を baseVersion から盲目コピー**: `dev.GameId` を baseVersion 由来の値そのまま transcribe しており、移行バグ等で空 / 別 id を持っていた場合、新版 developers 行に誤った game_id が入り FK 不整合 (親 game 削除で消えない孤児) の温床になる。`GameId = this.gameId` (編集中ゲームの id) に上書き。
- **M3 (BackupService + SettingsRepository): 時計が未来にズレた PC で自動バックアップが永久 skip**: NTP 未同期 / RTC 電池切れで wall clock が未来 (2099 年等) になった PC が `last_backup_at` を未来 unix 秒で書き込むと、以降全 PC で `lastBackupAt + interval > now` が恒真になり自動バックアップが永久 skip される。`IsAutoBackupDue` / `TryAcquireBackupLease` の両方に「1 日以上未来の値は明らかな時計異常として 0 扱い」の sanity を入れて lease 取得を促す。
- **M4 (BackupLogRepository.GetLastSuccess): 「最終バックアップ」表示が時計依存**: retention 側 (`GetAutoSuccessRetentionTargets`) は時計非依存の `id DESC` なのに、UI の最終バックアップ表示 SoT である `GetLastSuccess` は `started_at DESC` で wall clock 依存だった。時計が大きくズレた PC のバックアップが常に「最新」扱いで上に居座り、時計正常な PC の直近バックアップが UI で見えなくなる。`ORDER BY id DESC` (AUTOINCREMENT INSERT 順) に揃えて時計非依存化。
- **M5 (RestoreService): 復元前にディスク空き容量を確認せず途中で容量切れ**: 復元は safety 退避 + tempPath コピー + File.Replace でディスクを最大 2 ファイル分消費する。展示 PC は小容量 SSD が多く、safety だけ書けて tempPath コピーが IOException で落ちると中途半端な残骸 + 不親切なエラーになる。「復元元サイズ × 2 + 16MB 余裕」を事前確認し、不足なら明確なメッセージで先に止める (DriveInfo 取得不能なネットワークドライブ等では check を skip して続行)。
- **M6 (BackupSectionPanel.btnDelete_Click): last_backup_at rewind の last-write-wins 競合**: 自動バックアップ削除時の last_backup_at rewind で、削除中に別 PC が新しい自動バックアップを取得して last_backup_at を前進させていた場合、古い値で上書きすると別 PC の最新取得を打ち消して二重バックアップを誘発していた。現在値より小さくなる (= 真に rewind になる) ときだけ更新する guard を追加 (完全 atomic ではないが TOCTOU 窓を縮小)。
- **M7 (BackupService): Online Backup API が残す `-wal` / `-shm` / `-journal` sibling の掃除**: System.Data.SQLite の版によっては dest 接続の close 時に journal sibling が残り、user がバックアップファイルを別フォルダへ手動 move した際に置き去りになって、復元時に古い journal が誤適用され内容が巻き戻る稀な事故につながる。本体 .db は単独で完結すべきなので backup 完了直後に sibling を best-effort で掃除する。
- **M8 (EditGameForm.UpdatePathTextBox): path 正規化失敗が完全 silent で追跡不能**: `Path.GetFullPath` 例外時の catch が完全 silent で、rename 後に path が旧 gameId のまま残り後段で null 化 → 喪失する経路の追跡が効かなかった。`Logger.Warn` を残して後段 validation に委ねる (挙動は据え置き、可観測性のみ改善)。

**【除外: 実コード根拠付き】**

- **設計通り / 到達不能 (修正不要、5 件)**: (a) EditGameForm の `game.Title = selectedVersion.Title ?? game.Title` は Title が必須入力 (空版を作れない) のため `?? game.Title` は NOT NULL 安全弁で実害なし。(b) BackupService.ApplyRetention の File.Delete 失敗は foreach が continue で後続処理 + 次回バックアップ時に再試行されるため「渋滞」は起きない。(c) 復元 Abort 時の audit は pre-replace 失敗 (DB は OLD のまま) なので OLD DB に `MarkAuditFailed` で残る。(d) `ForceClearRestoreLock` の順序は round 5 M2 で意図的に設計した post-step 処理 (File.Replace 完了後) でデータ破損経路なし。(e) SemverInputControl の範囲外入力は `TryParseAndSet` が `ok=false` を返し (silent でない) + LoadVersions で全件警告済み。
- **本番非到達 / 効果過大で見送り (3 件)**: (a) legacy safety ファイルの移行 retry loop は対象が「v0.8.0 リリース直前まで」の旧ファイルで、2026-05-27 開始の新規インストールには存在せず即 0 返却で到達しない。(b) 復元後整合性チェックの case 違い version 重複検出は、v17 の NOCASE UNIQUE INDEX でアプリ経由の重複が入らず、pre-v17 backup 復元時も migration の index rebuild 失敗 → `SchemaIncomplete=true` で既に検出済みのため、残るは v18 DB への外部ツール直 DML のみで本番非現実的。(c) safety/backup 再登録の UNC↔ドライブ文字 dedup は完全解決に共有マッピングが必要で本質的に困難、害は履歴の重複表示のみ (`RegisterUnknownBackupFiles` は GetFullPath 正規化で部分対応済み)。これら 3 件は GitHub issue 化を検討。

#### Bump 根拠 (v0.19.0 → v0.19.1)

全 17 件が bugfix (新機能なし、path 編集解放は v0.19.0 で追加済でその回帰 fix が H4)。schema の最終形は v18 のまま不変 (H9 は v0 DB の retrofit hardening で新 user_version は引き続き 18) のため patch bump。AGENTS.md「1 PR 1 bump」原則に従い round 6 の修正群を単一 v0.19.1 entry に統合。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.19.0 - 2026-05-29 -->

#### Fixed (累積監査ラウンド 5: 並行 Manager race / GDI lifecycle / 規約 drift の 12 件)

round 4 (v0.18.0) リリース後、独立 2 並列監査でゲーム追加 / 編集 / バージョンアップ / バックアップ / 復元周りに残っていた defect を再精査。Agent 報告 17 件のうち実コード verify で真と確認された High 3 / Medium 6 / Low 3 = **計 12 件** を修正。さらに **path textbox の ReadOnly 解放 + バリデーション強化** (UX 改善) を同 PR に同梱。schema 変更なし、UI 機能追加 (path 編集可能化) を含むため minor bump。

**【High】**

- **H1 (GameSectionPanel.btnVersionUp): `Directory.Move` の `UnauthorizedAccessException` 取りこぼし**: round 4 R4-C1 で導入した tempDir → versionDir atomic Move は `catch (IOException moveEx)` のみで、MSDN 公式仕様の UAE (ACL 拒否 / read-only attr / 親フォルダロック中等) を取りこぼし、WinForms 既定の ThreadException ダイアログ (英文 stack trace) が user に出る経路 + tempDir (`.pending-create-{guid}`) の永続残置による disk 容量蓄積があった。`catch (UnauthorizedAccessException)` を IOException catch の隣に追加 + 共通 `HandleVersionDirMoveFailure` ヘルパに集約。round 4 R4-M10 の legacy safety MoveTo UAE 規約と非対称解消。

- **H2 (BackupService.RunAutoBackupIfDue): 自動バックアップ path に restore advisory lock check が欠落**: round 2 H5 で導入した「他 PC が復元中なら write をブロック」する advisory lock は `MainForm.CheckSessionConflictBeforeWrite` (user 操作経路) のみ check しており、起動時の auto-backup は素通しだった。PC-A が File.Replace 中に PC-B の Manager 起動 → 自動バックアップが Online Backup API で File.Replace 中の DB を読みに行く → 出力 backup が partial / corrupt → 後日その backup を復元すると最新データ消失する致命 race があった。`RunAutoBackupIfDue` 冒頭で `GetActiveRestoreLockOwnerOrNull` check + Skipped で return。`RunManualBackup` も defense-in-depth で同 check を追加 (UI 経路は SessionConflictHelper で既に check 済だが direct 呼出 path への保険)。

- **H3 (ImagePreviewHelper.UpdatePreview): PictureBox の旧 Image を Dispose せず GDI handle leak**: `pictureBox.Image = Image.FromStream(...)` と `pictureBox.Image = null` のいずれも旧 Image を Dispose せず GC 任せの非決定 dispose になっていた。Image は GDI+ unmanaged handle を持つため、9 時間連続展示で編集画面の画像切替を繰り返すと GDI handle 上限 (10,000) に達して WinForms 全体が描画不能になる経路があった。`SetImageWithDispose` private helper に集約し、代入前に必ず `oldImage?.Dispose()` を実行。さらに `Image.FromStream` の戻り値は MS docs 仕様で「stream must remain open for the lifetime of the Image」 — 本実装は MemoryStream を using で即解放しているため、`new Bitmap(raw)` でクローン化してから PictureBox に渡し、stream lifetime と切り離した (将来 PictureBox 表示中に stream が GC されて描画崩壊する path を構造閉鎖)。

**【Medium】**

- **M1 (SchemaManager.MigrateV17ToV18): `PRAGMA defer_foreign_keys` 未指定で developers 再作成中に game_id orphan で migration 即死**: round 4 R4-M12 で導入した v17→v18 migration は INSERT-SELECT 中の FK check が即時 throw され、game_id orphan が 1 件でも残っている過去 DB (= 外部ツール直 DML / round 4 以前の UpdateGameId 中断履歴) で migration 全体が即死する経路があった。SQLite 公式の「FK ありテーブル recreate」推奨手順に従い、transaction 開始直後に `PRAGMA defer_foreign_keys = ON` を発行 (3.7.5+、transaction 内で `foreign_keys` 自体は変更不能なため deferred check に切替) して COMMIT 直前にまとめて check させる。さらに INSERT-SELECT の WHERE に game_id orphan filter (`EXISTS (SELECT 1 FROM games g WHERE g.game_id = d.game_id)`) を追加して version_id orphan filter と対称化、sweep 件数の Logger.Warn も version_id / game_id 別カウントで残す。

- **M2 (RestoreService): snapshot 由来の `restore_lock_owner` 行が NEW DB に持ち込まれ復元後 5 分間 write 全 block**: round 2 H5 + round 3 M11 で設計した「自 PC owner exact match での lock 削除」が裏目に出る経路。snapshot 取得タイミングで他 PC が active な restore lock を保有していた場合、復元すると NEW DB に他 PC 由来の lock 行が蘇り、自 PC の `ReleaseRestoreLock` は owner mismatch で no-op → 5 分 stale 失効まで `CheckSessionConflictBeforeWrite` で全 write 操作が dialog で Cancel 強制される UX 退行があった。`SettingsRepository.ForceClearRestoreLock` を新設 (所有者 check なしの DELETE) + `RestoreService` の post-step 内側 try で File.Replace 直後に呼出す。自 PC lock は finally の `ReleaseRestoreLock` と二重削除になるが no-op で害なし。

- **M3 (EditGameForm): 外部画像 auto-copy 後の Cancel 経路で disk にオーファン画像が残る**: round 2 M10 で導入した `CopyExternalImagesToVersionFolder` は disk にコピー → textbox を destination path に書き換える設計のため、retry 経路では IsPathInside=true で再コピー skip が効くが、user が **Cancel / X ボタンで form を閉じた場合**、新規にコピーされた画像ファイルが `games/<id>/v<version>/<filename>` に永続残置されていた。`_copiedExternalImagePaths` field に copy 済 path を集約、OK 成功で commit としてクリア、`OnFormClosing` で DialogResult != OK 経路でのみ実体削除する best-effort cleanup を追加。

- **M4 (EditGameForm.UpdatePathTextBox): `AltDirectorySeparatorChar` (`/`) の path で旧 folder prefix 置換漏れ**: round 4 R4-M13 で `Path.DirectorySeparatorChar` (`\`) 境界を追加した修正の取りこぼし。textbox 値が `/` 区切り (手入力 / 外部由来 path) の場合、`StartsWith(oldFolder + '\\')` が false → 置換漏れ → 後段 `NormalizeRelative` で base 外として null 格下げ → DB に null 保存で path 喪失する drift があった。比較前に path / oldFolder の両方を `Path.GetFullPath` で正規化 (`/` → `\` 揃え + 相対 path 解決) してから判定する。Phase D の ReadOnly 解除と組合せて初めて表面化する経路だが、DB 由来 path 経由でも発火しうるため round 5 で fence。

- **M5 (PathManager.GetGameFolder / GetVersionFolderLeaf): 空文字 gameId / version で危険 path 返却の defense-in-depth fence**: `Path.Combine(GamesFolder, "")` は `GamesFolder` をそのまま返す .NET 仕様。それに `Directory.Delete(folder, true)` を当てると games/ 配下全削除の核兵器ボタン化する path だった。削除経路 (GameSectionPanel L477) は caller 側で IsNullOrWhiteSpace 防御済 (OK) だが、画像コピー / 編集の path 解決経路で別の caller が ValidateInput 前提でガード無し直呼びしている path が存在。`GetGameFolder` / `GetVersionFolderLeaf` 入口で `IsNullOrWhiteSpace` check → `ArgumentException` throw に変更 (caller 全部に防御を頼らない PathManager 自身の入口 fence)。`GetVersionFolderLeaf` も `version=""` で leaf 名が `"v"` 単独になる経路を同パターンで閉鎖。

- **M6 (DeveloperForm + GameFormHelper): clamp helper 共通化漏れで grade 大きすぎ値で編集 dialog 永久 block**: round 2 M2 で EditGameForm に導入した `SetClampedNumericValue` (DB 由来 int 範囲外を clamp + Logger.Warn + NullOnLoad flag) を `GameFormHelper.SetClampedNumericValue` に昇格、DeveloperForm からも使えるよう公開。DB の `developers.grade` は TEXT 列で長さ制限なし、手書き SQL / 旧 schema 復元で `grade="9999999"` (8 桁) が入った developer 行を「編集」しようとすると `numGrade.Value = 7桁超int` で `ArgumentOutOfRangeException` → ダイアログ自体が表示できず、その製作者を編集する経路が永久 block されていた。EditGameForm の `SetClampedNumericValue` も新 helper への forwarder 1 行に短縮、SoT を 1 本化。

**【Low】**

- **L1 (BackupSectionPanel): 履歴 grid の trigger 列 switch に `"restore"` case が無く生 string 表示**: round 4 R4-M9 で復元 audit 行を NEW DB に `trigger_type='restore'` で INSERT する経路を追加したが、grid 表示の switch は manual/auto/safety のみで restore が default 落ち → 「復元」と並んで生 string `"restore"` が英字混在表示されていた。`case "restore": trigger = "復元"; break;` を 1 行追加。`BackupLogEntry.TriggerType` の XML doc (R4-L3) との対称化。

- **L2 (RestoreConfirmForm.lblWarningDetail2): 存在しない legacy filename pattern を案内する文言**: 「現在のデータベースは安全のため自動的に退避されます (**safety_before_restore_\*.db**)」と書かれていたが、新規生成は `safety_yyyyMMdd_HHmmss.db`、`before_restore_` prefix は `MigrateLegacySafetyFilesToSafetyFolder` の対象 (BackupService.cs:380 regex) のみで新規生成では使われない。user が手動で safety ファイルを探す際に「該当パターンが見つからない」混乱を生む経路を解消。`"(safety_*.db)"` に書き換え。R4-L3 の XML doc 同期と同類の drift 修正。

- **L4 (GameFormHelper.AutoDetectFiles): junction / symbolic link 越しの path 検出で sourceFolder 外を絶対 path のまま返す**: `Directory.GetFiles(... SearchOption.AllDirectories)` が junction 先のファイルを返した場合、戻り値 path が `Path.GetFullPath` 後に sourceFolder 外を指して「絶対 path として `RelativeExecutablePath` に流入 → 後段 assert で『絶対 path 検出、コピー元を指定し直して』MessageBox → 何度やっても抜けられない永久 block UX」する経路があった。新規 private helper `IsPathInsideSourceFolder` で各 path について sourceFolder 内 (等値 OR 区切り境界付き StartsWith) チェックを通し、外れていたら自動検出から除外する。AddGameForm + VersionUpForm の両 caller に同時に効果。

**【Low (除外: 設計通り)】**

- **MainForm.OnDatabaseRestored の `ReconcileInProgressEntries` threshold 無し**: agent は「他 PC active backup を巻き込み failed 化」と指摘したが、CHANGELOG L3335 で「復元直後はスナップショットの状態なので File.Exists で正しく success / failed が判定される」と設計意図明記。`File.Exists` filter があるので巻き込みは起きない。**設計通り、修正不要**。

**【Low (撤回: scope creep)】**

- L3 (AddGameForm の ReleaseYear / MinPlayers / MaxPlayers null 入力 UI): user 判断で round 5 のスコープから除外。新機能として独立 PR で扱う方が妥当。

#### Added (path textbox を編集可能に解放 + バリデーション強化)

- **AddGameForm / EditGameForm / VersionUpForm の 9 textbox を `ReadOnly = false` に解放** (`txtThumbnailPath` / `txtBackgroundPath` / `txtExecutablePath` × 3 form): 旧 ReadOnly 設計は「部員が手入力で typo って path 破壊するのを物理防止」する思想だったが、開発者寄りの user (= ゲーム作者本人 / 顧問の先生) が `v1.0.0/main.exe` → `v1.0.0/sub/launcher.exe` のような微調整を Browse ダイアログ往復なしで行う UX 改善を優先。Designer.cs 9 か所から `ReadOnly = true` を削除 (= class default false に倒す)。
- **TextChanged hook で `/` → `\` 正規化 + ImagePreview 連動**: 各 form の Load で 3 textbox に TextChanged ハンドラを登録。`GameFormHelper.NormalizeSlashInPathTextBox` 共通ヘルパで `/` 区切り混入を `\` に正規化 (cursor 位置保持、再帰 fence で 2 回目は no-op)。サムネイル / 背景 textbox は同 hook で `UpdateThumbnailPreview` / `UpdateBackgroundPreview` も連動、user が手入力した瞬間にプレビューが追従する UX。
- **`GameFormHelper.ValidateFilePath` 共通バリデーション helper を新設**: (a) 空欄 + required flag、(b) 拡張子 (allowedExtensions)、(c) 存在 check (相対なら baseFolder で絶対化) の 3 段検証を統一。AddGameForm.ValidateInput を共通 helper 経由に書き換えて、実行ファイルは `.exe` 必須、サムネイル / 背景は `.png` / `.jpg` / `.jpeg` / `.bmp` のいずれか必須に強制。EditGameForm / VersionUpForm は既存の File.Exists + IsPathInside fence で十分なので Phase D の主要 win (= `/` 正規化 + プレビュー追従) のみ適用。
- **`GameFormHelper.ImageFileExtensions` / `ExecutableFileExtensions` を public static field として公開**: 拡張子集合の SoT 化。将来 `.gif` / `.webp` を許容する等の変更が 1 か所で済む。

#### Bump 根拠 (v0.18.0 → v0.19.0)

bugfix 12 件 + path textbox 編集可能化という UI 機能追加を含むため minor bump。schema 変更なし (v17→v18 migration は M1 で hardening するが新 user_version は引き続き 18)。AGENTS.md「1 PR 1 bump」原則に従い、bugfix 群と UX 機能追加を同 v0.19.0 entry に統合。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.18.0 - 2026-05-28 -->

#### Fixed (累積監査ラウンド 2: ゲーム追加/編集/バージョンアップ/バックアップ周りに残っていた 17 件 + 追加ラウンド 3 件 + 画像 UX 改修)

v0.17.0〜v0.17.2 (#234/#235/v0.17.x の 14 件+ 連続修正) の後に独立 4 並列監査を実行、code 上の根拠付きで残存していた欠陥 17 件のうち High 5 / Medium 8 / Low 7 を修正 (一部 Low 4 件は follow-up issue 候補として deferred、CHANGELOG 末尾参照)。さらに **本ラウンド (round 3) で追加 2 件の defect 修正 + 編集画面の画像 UX 機能改修** を含む。スキーマ変更 (v15 → v17) と DB write 経路に LAN advisory lock を導入したため minor bump。

**【High】**

- **H1: ゲーム編集の実行ファイル path にアクティブ版 fallback を追加**: `EditGameForm.LoadGameDataForVersion` で `version.ExecutablePath` が空のときに `originalGame.ExecutablePath` を出す active-fallback が他 (Thumbnail/Background/Title/Description/Arguments/Genre/Min/Max/Difficulty/PlayTime/Connection/Controller/Developers) には全部入っていたのに ExecutablePath だけ漏れていた。旧 AddGameForm 経路で作られた初期版行 (= `executable_path` NULL) を編集しようとすると、active 版選択中でも txt が空 → 「実行ファイルを選択してください」 validation で永久 block される #234 修正の取りこぼし。
- **H2: ゲーム編集の初回 load で active 判定が不発になる非対称を修正**: `LoadVersions` で `cmbVersionList.SelectedItem = item` が SelectedIndexChanged を発火 → `LoadGameDataForVersion` が走るが、その内部で参照する `_initialSelectedVersionId` への代入は SelectedItem 設定**後**の行で行われていた。初回 load 時 `_initialSelectedVersionId.HasValue == false` 確定 → 全項目で active fallback が機能せず、初期版スカスカが UI 上空のまま見える。dropdown 切替えて戻ると正常化、という silent UX 劣化 (#234 healing が form open 時のみ無効化)。代入順を SelectedItem 設定の**前**に出して構造閉鎖。
- **H3: バージョンアップの Abort 経路で versionDir が掃除されず永久 block する問題を修正**: `ProcessingDialog` の worker が例外を throw すると `DialogResult.Abort` がセットされるが、`GameSectionPanel.btnVersionUp_Click` は `Cancel` しか handle していなかった。コピー途中で disk full / ファイルロック等で落ちると、partial copy された `games/{id}/v.../` が残留、次回同一バージョンで再試行すると「フォルダ衝突」 guard で永久 block (#234 ③ の rollback 対称化が Cancel のみ対象で Abort を漏らした)。`Cancel` と `Abort` を共通 cleanup branch に統合 + Abort 時は ProcessingDialog 側で既に MessageBox 表示済のため二重表示を回避。
- **H4: リストアイベントの監査ログを `backup_log` に記録 (v15 → v16 スキーマ拡張)**: v0.17.0 release notes は「監査ログ完備」を謳うが、`RestoreService.Restore` は `Logger.Info` の file log のみで、ローテーション / 別 PC コピー / 手動 truncate で消失する path だった。`backup_log.trigger_type` CHECK に `'restore'` を追加 (`MigrateV15ToV16`)、`BackupLogRepository.LogRestoreCompleted` を新設して `BackupSectionPanel.btnRestore_Click` の成功 path で `InitializeDatabase` (= migration 完了) **後**に新 DB に audit 行を INSERT。RestoreService 開始時の `InsertInProgress` 行は OLD DB (= safety バックアップに保存される版) に残り、forensic snapshot として保全される。
- **H5: リストア中の LAN advisory lock を導入 (v17 で確定、`settings.restore_lock_owner`)**: SessionConflictHelper の dialog 確認は user 確認層のみで、チェック通過後〜`File.Replace` の数十秒間に別 PC の Manager が write を開けば uncommitted トランザクションごと旧 DB が消える race を緩和。`RestoreService.Restore` 開始時に `SettingsRepository.TryAcquireRestoreLock` で advisory lock (`<pcName>|<unixMs>`) を取得、終了 (success/failure/cancel) で finally release。`MainForm.CheckSessionConflictBeforeWrite` が write 操作前に lock check して他 PC 保有なら即 Cancel + MessageBox。stale (5 分超過) と self lock は無視。lock 取得失敗時 (= 他 PC が active lock 保有) は復元自体を開始前に中止。
- **H6 (round 3 追加): `game_versions` UNIQUE INDEX の NOCASE 化が新規 DB で永久に効かない経路を修正**: M3 (v16 → v17) で導入した NOCASE INDEX は migration 経路 (`MigrateV16ToV17`) で COLLATE NOCASE 付きの index を rebuild するが、`CheckAndMigrateDatabase` の `currentVersion == 0` 分岐 (= 新規 DB) は `MigrateV13ToV14` のみ呼んでから `SetDbVersion(CurrentDbVersion = 17)` で直接 stamp してリターンするため、**v16→v17 migration が永久に走らない**。新規 DB の index 作成経路 (`CreateTables` → `EnsureGameVersionsVersionUniqueIndex`) は BINARY collation のまま CREATE していたため、本番 2026-05-27 のまっさら新規 install DB は **NOCASE が効いていない状態で動いていた**。`EnsureGameVersionsVersionUniqueIndex` の CREATE 文に `COLLATE NOCASE` を付与して、新規 DB / 既存 DB どちらの経路でも常に NOCASE 化されるよう揃える (1 行修正、`MigrateV16ToV17` 側は `IF NOT EXISTS` で no-op、既存 DB の v17 migration による NOCASE rebuild path も互換)。SPEC §7.3 / §7.6 の expected schema は最終形が変わらないため不変。

**【Medium】**

- **M1: ゲーム編集の ReleaseYear null tracking flag を追加**: `numReleaseYear.Value = DateTime.Now.Year` を null 仮表示時に立てるが flag が無く、保存時に `2026` が DB に書き戻されていた。`_gameReleaseYearWasNullOnLoad` flag を追加し、Load 時 null + 表示値未変更なら save で null 維持。Min/MaxPlayers の `_versionXxxWasNullOnLoad` パターンと対称化。
- **M2: ゲーム編集の NumericUpDown 範囲外値を clamp (旧実装は throw で edit 画面が開けなくなる)**: DB に MinPlayers=0/200 / ReleaseYear=9999 等の異常値があると生代入で `ArgumentOutOfRangeException` → 編集画面が永久 block。`SetClampedNumericValue` ヘルパで clamp + Logger.Warn + NullOnLoad flag (= 保存時に clamp 値が書き戻らない)。SemverInputControl の clamp+healing パターンと統一。
- **M3: `game_versions(game_id, version)` UNIQUE INDEX を COLLATE NOCASE 化 (v16 → v17)**: 旧 BINARY collation INDEX は `v1.0.0` と `V1.0.0` を別行として許容。SemverInputControl の `V` 受理仕様と UI dup-check の OrdinalIgnoreCase の間で「外部ツール直 INSERT / レガシー復元データで case 違い重複が DB に入る」経路があった。`MigrateV16ToV17` で NOCASE INDEX に rebuild、case 違い重複残存時は v14→v15 と同じ skip + retry pattern。
- **M4: VersionUpForm の画像 path TOCTOU で絶対 path が DB に流入する問題を修正**: 旧実装は `NewVersion.ThumbnailPath = txtThumbnailPath.Text` (絶対 path) を先にセット、`File.Exists` 経由でのみ相対化していた。validate と OK click の間にユーザが画像を削除すると `File.Exists=false` → 絶対 path が `Path.Combine(versionFolderName, absolutePath)` の「絶対は第一引数を破棄」仕様で DB に流入し Launcher の path 解決が壊れる。初期値を null にし、`File.Exists` 内でのみ relative セット。GameSectionPanel 側にも `Path.IsPathRooted` assert を二段目 fence として追加。
- **M5: バージョンアップで AddGameVersion + UpdateGame を 1 transaction で atomic 化 (partial commit 窓を物理閉鎖)**: 両 commit の間で電源断 / SMB disconnect が起きると `game_versions` に新版行は入るが `games.version` は旧版のまま残り、Launcher で新版が起動できないが UI 上「アクティブ化失敗」MessageBox も出ない silent corruption。`DatabaseManager.AddVersionAndActivate` を新設 (VersionRepository + GameRepository の `*InTransaction` internal helper 経由) し、activation 確認 dialog を DB write より前倒しすることで両 INSERT/UPDATE を共有 connection + transaction で実行。
- **M6: ApplyRetention で物理削除した backup_log 行を DB からも削除 + `GetLastSuccess` が File.Exists を見るように修正**: 旧実装は file のみ削除して DB 行を残置、UI で「最終バックアップ: ファイル無し」表示や `RestoreConfirmForm` の選択候補に残る不整合があった。`ApplyRetention` で `DeleteById(entry.Id)` を併発、`GetLastSuccess` に `File.Exists` filter を追加 (最大 100 行までで打ち切り)。
- **M7: AddGameForm の並行 Manager race で勝者のバージョンフォルダを敗者が rollback で巻き込み削除する問題を修正**: 2 Manager が同 DB を並行操作した場合、敗者 (`Directory.Exists` 判定で「既に存在」throw を踏む) の `CleanupCopiedFoldersOnRollback` が `Directory.Delete(destinationGameFolder, true)` で勝者の直前 `CreateDirectory` した folder を巻き込み削除する footgun。`versionFolderCreatedThisCall` flag を `baseGameFolderCreated` と同パターンで導入し、自分が作った disk 状態のみ自分で消す原則を強制。
- **M8: AddGameForm の RollbackGameRow 失敗を MessageBox で user 通知**: `DeleteGame` 失敗時に `Logger.Warn` のみで silent 継続していたため、「DB に games 行のみ残留 + ファイル消失」の整合性破綻が user 不通知で残り、次回起動時に game_versions の無い行が UI に出る。失敗時に「手動 DB 修復が必要」MessageBox で明示通知。
- **M9 (round 3 追加): `RestoreService` の `tempPath` 残置で次回復元が disk-full chain する経路を修正**: `File.Copy(backupFilePath, tempPath, false)` 後・`File.Replace` 前で例外 (例: WAL 削除中の IOException) や cancel が起きると、フルサイズの `toneprism.db.restore-tmp` が残置されていた。次回復元時 L154 の `File.Delete` で消えるが、本番展示 PC (SSD 小容量) で復元失敗が連続するとフルサイズのゴミファイルが累積 → 次の `File.Copy` が disk-full でさらに失敗する負ループが構造的に起こりうる経路だった。`catch (OperationCanceledException)` / `catch (Exception)` の両方に `TryDeleteTempFile(tempPath)` を追加して best-effort 削除し、削除失敗時は Logger.Warn のみで上位 throw を優先 (= 失敗時の audit 行は確実に残す)。
- **M10 (round 3 追加 / 機能改修): `EditGameForm` でゲームフォルダ外の画像を選んだら自動コピーする UX を追加**: 旧実装は `IsPathInside(gameFolder, ...)` で外部画像を一律 reject していたため、user が「新しい画像に差し替えたい」場合に エクスプローラで手動コピー → 編集画面で選び直す、という 2 段手順を踏む必要があった。新規 `ImageNameConflictDialog` (Designer 不使用・コード生成、`RestoreReportForm` と同方針) と `EditGameForm.CopyExternalImagesToVersionFolder` を追加し、OK 押下時に外部画像 path を検出したら編集中バージョンの `games/<id>/v<version>/<filename>` 配下へ自動コピーする。同名衝突時は dialog で衝突相手 / コピー元 / 提案ファイル名 (`<base>_2.<ext>` 形式で衝突しないまで increment) を表示し、user が TextBox で自由に rename 編集可能 (拡張子は .png/.jpg/.jpeg/.bmp 制限、invalid char check、再衝突 check)。**古い画像ファイルは削除しない** (= 古いバージョンが旧画像を参照している可能性があるため、ファイル名重複による上書きも禁止)。コピーは ProcessingDialog 経由で SMB 越しの数百 ms にも UI freeze なしで対応、cancel / 失敗時は partial copy を rollback して入力画面に戻る。実行ファイル (`txtExecutablePath`) には引き続き `IsPathInside` 制約を適用 (= 外部 exe は VersionUp 経路でしか取り込ませない、設計意図維持)。
- **M11 (round 3 追加 / #6): `ReleaseRestoreLock` の `LIKE @prefix` 巻き込みを解消**: 旧実装は `DELETE FROM settings WHERE key=@k AND value LIKE @prefix` で `@prefix = "<pcName>|%"` 形式の LIKE 検索により lock を削除していた。LIKE の `_` (任意 1 文字) / `%` (任意の連) は wildcard 扱いされるため、PC 名にこれらの文字が含まれると他 PC の lock も巻き込み削除しうる経路があった (例: `PC_A` の解除が `PC1A|...` の行にも一致して削除)。学校 PC で `_` 含む名前は珍しくないため LAN 運用の現実的な race。新実装は (1) Serializable tx で SELECT、(2) `<owner>|<unixMs>` を parse、(3) owner が pcName と完全一致 (OrdinalIgnoreCase) するときのみ exact `value = @v` で DELETE する形に変更。SQL の LIKE 経路を一切使わないため wildcard 巻き込みを構造的に排除。
- **M12 (round 3 追加 / #7): `TryAcquireRestoreLock` の SELECT のみ literal embed だった非対称を parameterized 化**: 同 file 内の INSERT (L173) / `ReleaseRestoreLock` (L197) は `@k` パラメータ化されているのに、本 SELECT (L142) だけ `"SELECT value FROM settings WHERE key = '" + SettingsKeys.RestoreLockOwner + "'"` の string concat だった。現値 `"restore_lock_owner"` は alphanumeric のみで injection 経路は無いが、convention drift で `'` 含む値に rename された瞬間に SQL break する hazard。`@k` パラメータ化で 3 経路を対称化 (1 行修正)。
- **M13 (round 3 追加 / #8): `VersionUpForm` の baseVersion 画像 path が相対値で永久 block する経路を修正**: `txtThumbnailPath.Text = baseVersion.ThumbnailPath` (例: `v1.0.0/cover.png`) のように DB 上の相対 path を絶対化せずに textbox に入れていたため、後段の `ValidateInput` の `File.Exists(txt.Text)` が CWD 基準で false → 「画像が見つかりません」エラーで OK が押せない永久 block UX 退行があった。dialog を一度開いたら何度やっても抜けられない user 体験になっていた。VersionUpForm_Load で `PathConversionHelper.ToAbsolutePath(baseGameFolder, ...)` (= `games/<id>/` 基準) を通して絶対化してから textbox に入れる形に変更。元から絶対だった path は `Path.IsPathRooted` 分岐でそのまま返るため互換。
- **M14 (round 3 追加 / #9): `EditGameForm.ApplyRelativePaths` で gameFolder 外パスの silent 絶対 path 流入を二段目 fence で構造閉鎖**: `PathConversionHelper.ToRelativePath` は base 外 path を「絶対のまま」返す設計のため、`UpdatePathTextBox` の prefix 置換が部分一致しない経路 (例: gameId rename + 古い絶対 path 残存) や画像 UX copy 漏れで絶対 path が `executable_path` / `thumbnail_path` / `background_path` に silent 流入する経路があった。新規 helper `NormalizeRelative` を導入し、`ToRelativePath` 後に `Path.IsPathRooted` を検出したら Logger.Warn で trail を残しつつ null 格下げ。DB 保存値は「相対 path / null」のいずれかに必ず collapse する契約を強制し、Launcher の path 解決が絶対と相対の混在で崩れる経路を構造閉鎖。防御経路 (`selectedVersion==null`) の L1044-1046 も同 helper 経由に統一して非対称解消。
- **M15 (round 3 追加 / #10): `BackupService.ApplyRetention` の DB delete 失敗で retention 件数が silent drift する経路を修正**: 旧実装は物理 `File.Delete` 成功・`DeleteById` 失敗のケースを `Logger.Warn` で swallow するだけだったため、次回の `GetAutoSuccessRetentionTargets` (WHERE `status='success'`) が当該行を 1 件として count してしまい、`keep=30` 設定でも実体は 29 件、また失敗で 28 件、と silent に目減りする drift があった。文化祭直前の保険厚みが知らぬ間に減るのは致命的なので、`DeleteById` 失敗 catch 内で `MarkFailed` (= `status='failed'` に格下げ) を呼んで以降の count から外す。audit trail としても「実体削除済 / DB delete fail で failed 化」の record が残る形 (= 単に row を消すよりも forensic 性が高い)。`MarkFailed` も失敗した場合は `Logger.Error` のみで継続 (= best-effort セマンティクス、Manager は止めない)。

**【Low】(7 件まとめて)**

- **L1: `FileOperationService.NormalizePath` の null/空文字 NRE 防止**: `path.StartsWith` を null guard なしで呼ぶ defensive さ欠如を冒頭 `IsNullOrEmpty` ガードで閉鎖。
- **L2: `PathConversionHelper.ConvertSourceToDestination` 戻り値の絶対化**: 相対 path 経路で `File.Exists` が CWD 基準で評価される footgun を `Path.GetFullPath` 強制で閉鎖。
- **L3: `GameRepository.UpdateGameId` で `PRAGMA foreign_keys = ON` を try-finally で必ず restore**: throw 経路で PRAGMA 復元 skip → connection pool 経由で FK 制約なしで動く silent drift の risk を physical 閉鎖。
- **L4: `EditGameForm.ApplyRelativePaths` の空 path 保存を `""` → `null` に統一**: AddGameForm / UpdateGame と非対称だった「Launcher が null と "" を別 path として扱う silent 表示崩れ」risk を解消。
- **L5: `SemverInputControl.Suffix` setter の長さ制限 enforce**: UI 入力は `MaxLength=32` で物理 block するが setter は素通り → caller drift で 32 文字超 suffix が DB → version folder leaf 名が MAX_PATH を超え `PathTooLongException` で copy 失敗する経路を defensive substring で閉鎖。
- **L6: バックアップファイル名衝突回避の suffix に PC 名を mix**: 2 PC が SMB 共有経由で同 1 秒 backup を発火すると双方 `File.Exists=false` で同 path に書込み出力ファイル破損する LAN race を緩和。collision 検出時 suffix を `_2/_3` → `_<pcName>` 形式に変更 (同 PC 連射は従来通り数値 suffix)。legacy recovery regex は file_path 記録済の新形式を対象外とするため互換維持。
- **L7: `CleanupFailedEntries` で safety / restore の failed 行を audit 保護**: 旧実装は `trigger_type='safety'` の failed 行 (復元途中で死んだ証跡) も `DeleteById` で消していた audit trail 欠損を、`safety` / `restore` の failed 行を明示 skip する。

**【deferred Low (follow-up issue 候補)】**

- developers の DELETE+INSERT pattern を diff/upsert 化 (id drift) — リファクタ規模、別 PR。
- developers.version_id への FK CASCADE 制約追加 — 現状版削除 UI 未存在のため緊急度低。
- VersionRepository.UpdateMany の `__tmp_` suffix が Launcher 直 SQLite read に漏れる経路 — 現状 Launcher は SQLite 直 read しないため将来回帰時に対応。
- `RestoreReconciliationService.Analyze` の worker thread 化 + 手動配置 DB の auto-register — 個別 feature work、別 issue で扱う。

#### Bump 根拠 (v0.17.2 → v0.18.0)

DB schema 変更 (v15 → v17、`backup_log.trigger_type` CHECK 拡張 + `game_versions` UNIQUE INDEX を NOCASE 化) + LAN advisory lock の機能追加 + 編集画面の画像 UX 改修 (M10、外部画像の自動コピー + 衝突解決 dialog 新設) を含むため minor bump。schema 変更は v9→v10 と同じ非破壊 migration (CHECK 拡張 + INDEX rebuild) で auto-applied、user 手動操作不要。H6 の新規 DB NOCASE 化抜けは 1 行修正で `EnsureGameVersionsVersionUniqueIndex` の CREATE 文に `COLLATE NOCASE` を付与、既存 DB は MigrateV16ToV17 経路で既に NOCASE 化されているため重複作業なし。M11–M15 は round 3 で追加した独立 5 件の中規模欠陥修正 (LAN lock 周辺の wildcard 巻き込み / SELECT 非対称 / VersionUp 永久 block / 絶対 path 流入二段目 fence / retention 件数 drift) を含み、すべて DB schema 変更を伴わない実装層の hardening。Bundle への反映は次回リリース実行時。

#### Fixed (累積監査ラウンド 4: ゲーム追加 / 編集 / バージョンアップ / バックアップ / 復元周りに残っていた 28 件)

round 2/3 後にさらに 4 並列で独立監査を実行、Critical 1 / High 6 / Medium 12 / Low 9 の defect を発見・修正。DB schema を v17 → v18 に bump (developers.version_id に FK + ON DELETE CASCADE 追加 / game_genres dead table の整理) するが、PR 単位で 1 bump 規約に従い同 v0.18.0 entry 内にまとめる (round 4 追加分は本セクション参照)。

**【Critical】(round 4 追加)**

- **R4-C1: バージョンアップ並行 Manager race で勝者の versionDir を loser が物理削除する経路を構造閉鎖**: 2 PC の Manager が同じゲームに同じバージョン番号で同時バージョンアップした際、UNIQUE 違反で負けた側の `catch` が `Directory.Delete(versionDir, true)` を無条件実行し、勝者の commit 済 DB が指す `games/{id}/v1.0.0/` を物理削除する経路があった。Launcher は exe 不在で起動不能、UI に rollback 経路なしの silent corruption。`GameSectionPanel.btnVersionUp_Click` を「tempDir に書く → Directory.Move で atomic に versionDir へ昇格」の 2 段に分離し、Move は移動先既存で失敗するため敗者は自分の tempDir のみ delete (勝者の物理ファイルには絶対に触れない)。`versionDirOwnedByThisCall` flag は move 成功後にだけ true で、後段 (missing-asset / IsPathRooted / DB save 失敗) の cleanup でも勝者破壊を物理閉鎖。Medium-15 (missing-asset 最終 check 内の同根 race) と Medium-16 (File.Copy 並行 truncate) も同 fix で一括解消。

**【High】(round 4 追加)**

- **R4-H1 (#2): EditGameForm のアクティブ版切替で UpdateGameVersions + UpdateGame を 1 transaction に atomic 化**: 旧経路は別 transaction で順次実行しており、間で電源断 / SMB disconnect が起きると game_versions は新値 / games は旧版指したまま / disk folder は新名 の partial-commit drift が残る窓があった。AddVersionAndActivate と同設計の `DatabaseManager.UpdateVersionsAndGame` を新設 (VersionRepository に `UpdateManyInTransaction` internal helper 抽出 + GameRepository.UpdateGameRowInTransaction を共有 connection で実行)、EditGameForm を新 method 経由に切替。M5 atomic pattern の踏襲で「全成功 or 全 rollback」二択に整理。
- **R4-H2 (#4): FileOperationService の subdir 再帰 guard に区切り文字境界を追加**: `fullDestDir.StartsWith(fullSubPath, ...)` の生比較で兄弟前方一致 (例: `Foo/` と `Foobar/`) によって正当な subdir が silent skip され、最終的に取り込み後の存在 check で必ず失敗する破損ゲームを生む経路があった。line 81-82 の `sourceDirWithSep` パターンに揃え、`fullSubPath + Path.DirectorySeparatorChar` を suffix した StartsWith + 等値判定の二段に変更。
- **R4-H3 (#6): RestoreService の post-step 例外を内側 try で swallow して point-of-no-return を構造化**: 旧実装は File.Replace 成功後の post-step (ApplySafetyRetention 外側 / progress?.Report / LastRestoreStartedAt 代入等) が万一 throw した場合、外側 catch (Exception) で (a) `MarkAuditFailed` UPDATE が OLD DB の logId を NEW DB に向けて打って 0 行 silent no-op、(b) caller の ProcessingDialog に throw して「復元失敗」MessageBox → ユーザーが二重復元する事故、の 2 つの誤動作を起こしうる経路があった。post-step を内側 try で囲み swallow + Logger.Warn のみに変えて、外側 catch を pre-replace 失敗専用に絞り込む。
- **R4-H4 (#7): RestoreReconciliationService に非アクティブ版 exe / thumbnail / background の存在検証を追加**: 旧実装は `games.executable_path` (= アクティブ版のみ) と版フォルダ存在のみ検証で、非アクティブ版に切替えた瞬間に起動不能になる状態でも「✓ 復元完了：問題なし」と誤通知していた。`BrokenVersions` (非アクティブ版 exe 欠落) / `BrokenAssets` (thumbnail / background 欠落) の新カテゴリを追加し、各版を回って物理存在を check、RestoreReportForm にも対応する section を追加。BrokenVersions は HasCriticalFindings に含めて警告色 headline で表示。
- **R4-H5 (#8): PathConversionHelper.ToAbsolutePath の base 空文字契約を null 返却に変更**: 旧実装は basePath が空文字 / null のとき `Path.Combine("", relativePath)` で相対のまま返し、後段の File.Exists が CWD (= Manager.exe 作業 dir) 基準で評価される silent corruption 経路があった。ToRelativePath / IsPathInside と同じ「base 空なら null 返却」契約に統一し、Logger.Warn で trail を残す。caller (VersionUpForm.cs:176-178 等) は既に `?? ""` fallback 済で互換。

**【Medium】(round 4 追加、12 件)**

- **R4-M1 (#10): ゲーム追加の DisplayOrder 採番を SERIALIZABLE 内で MIN-1 計算 + INSERT を atomic 化**: 旧経路は `GetMinDisplayOrder()` + `AddGame()` が別 transaction で、並行 Manager race で両者が同じ MIN を取得 → 同 DisplayOrder で INSERT する → Launcher 並び順 invariant 「最新が一番上」が壊れる経路があった。`DatabaseManager.AddGameAtTop` を新設し `IsolationLevel.Serializable` (= BEGIN IMMEDIATE) で RESERVED lock を最初に取って serialize、`GameRepository.AddGameRowInTransaction` を internal helper 化して共有 connection で実行。AddGameForm の DisplayOrder = null パラメータ経路で新 method を使う。
- **R4-M2 (#11): AddGameForm の wipe TOCTOU で他 Manager の新規 install を巻き添え削除する経路を fence**: 「フォルダ wipe」UI 警告の OK 押下から worker thread の `Directory.Delete` が走るまでの間に、他 Manager が同 gameId でゲーム追加を完了したケースの保護。worker 内で wipe 直前に `GetGameById(gameId)` を再 check し、existing game ができていれば throw して abort。並行 race の確率は低いが本番 LAN 運用想定で non-zero のため fence を入れる。
- **R4-M3 (#12): AddGameForm の RollbackGameRow zombie 状態に user 復旧ガイダンスを充実**: DB 削除失敗時の MessageBox を「別 ID で再追加 / ゲーム削除 UI から zombie 削除 / 手動 DB 修復」の 3 段ガイダンスに拡張し、復旧 SQL 文を Logger.Warn に残す。同 gameId 再追加が永久 block する zombie 状態への対処方法を user が自力で見つけられるようにする。
- **R4-M4 (#13): EditGameForm.UpdatePathTextBox の prefix 置換に区切り文字境界を追加**: 旧実装は `path.StartsWith(oldFolder, ...)` の生比較で兄弟 gameId (`foo` と `foobar`) の path を誤って書き換える理論的経路 (validation で防御中だが defense-in-depth として規約と非対称)。`oldFolder + Path.DirectorySeparatorChar` 付き StartsWith + 等値判定の二段に揃え、`IsPathInside` / `ToRelativePathAfterCopy` と同じ契約に統一。
- **R4-M5 (#14a): EditGameForm の `originalGame.Version IS NULL` 異常 DB での active fallback healing 漏れを修正**: 過去 migration 中断 / 旧 Manager で games.version 未設定のまま残ったゲームを編集すると、active fallback が無効化されて編集画面が空項目で表示される drift があった。先頭版を仮 active として扱い (OK 保存時 line 1442 で games.version が必ず非 NULL に書き出される healing)、Logger.Info で trail を残す。
- **R4-M6 (#14b): VersionUpForm の malformed version dup 検出に数字トークン semantic 比較を追加**: DB に `"1.0"` (2 parts) のような malformed version が残っていると、新規 `v1.0.0` 追加時の raw 比較を通過してしまい、semantic 上同じバージョンの行が 2 つ並ぶ → Launcher の起動対象が user 意図と無関係に切り替わる drift があった。`TokenSequenceEqualPadded` helper で正規表現 `\d+` で数字トークンを抽出 + 末尾 0 padding して `[1, 0]` ↔ `[1, 0, 0]` を同一視して弾く。
- **R4-M7 (#17): backup_destination_path の危険 path 受理に軽い fence を追加**: drive root 直下 (`C:\` 等) と `%WinDir%` 配下を Logger.Warn + デフォルトへの fall-back で除外。user の path 誤入力でバックアップが OS 重要領域に散布される運用事故を防ぐ。OS 権限で大半 block されるが書込可能領域 (`%APPDATA%` 等) には届くため、最小 guard を入れて silent な誤誘導を避ける。
- **R4-M8 (#18): BackupService / RestoreService の Backup connection を OpenConnectionWithJournalMode 統一**: 旧実装は新規 SQLiteConnection を raw Open しており、`journal_mode=DELETE` / `busy_timeout=10000` / `foreign_keys=ON` / `synchronous=NORMAL` が未適用。別 Manager / Launcher が同時書込中の場合に source 接続の `Open()` が `SQLITE_BUSY` で即 throw する確率を下げる + 将来「Backup 取得直前にチェック SQL」等の拡張で FK off の silent drift を防ぐ convention 統一。
- **R4-M9 (#19): BackupLogRepository.LogRestoreCompleted に relative_path 引数を追加**: 通常のバックアップ INSERT (InsertInProgress) は相対 path も記録するが、復元 audit は絶対 path のみだったため、プロジェクトを別ドライブに移動すると履歴行のリンクが切れる非対称があった。caller (BackupSectionPanel) は `BackupPathResolver.ToRelativeFromDbDir` で dbDir 基準相対 path を計算して渡す。
- **R4-M10 (#20): legacy safety MoveTo 衝突時に skip ではなく suffix で必ず移動完了**: 旧実装は同名ファイルが移動先既存だと `Logger.Warn` + `continue` で旧 path のファイルを残置していた。プロジェクトを 2 PC で並行運用していて legacy safety 名衝突が起きるとプロジェクトルート直下にゴミが永続化 → 起動毎に warn 連発 + user が「これは何？」と削除して safety を失う事故になる。衝突時は `_dup_N` suffix を付けて必ず移動完了させる契約に変える (100 件超 dup は skip + warn)。
- **R4-M11 (#21): MigrateV15ToV16 の冪等性を確保 (前提 step gate を追加)**: 旧実装は v14→v15 が skip された場合でも v15→v16 を無条件実行していたため、backup_log を毎起動で DROP+RECREATE+INSERT-SELECT する高コスト処理が走り続けていた (SMB 上 + 数千行で起動遅延)。前提 step が完了 (`currentVersion >= 15`) のときだけ走らせる gate を追加。
- **R4-M12 (#22): developers.version_id に FK + ON DELETE CASCADE を追加 (v17→v18 migration)**: 旧 schema は version_id INTEGER (FK なし) で、将来「単一版削除」機能 (#101 / #30 関連) が入った時にその版に紐付く developers 行が silent orphan になる経路があった。SQLite は ALTER で FK 追加不能のため `developers_new` を作って `INSERT-SELECT` (orphan 行は除外で sweep) + DROP+RENAME で table recreate。v18 で同時に game_genres dead table も DROP (Low-28/29 参照)。CurrentDbVersion を 17 → 18 に bump。

**【Low】(round 4 追加、7 件)**

- **R4-L1 (#5 demoted): EditGameForm の games.MinPlayers/MaxPlayers null 保護 snapshot を追加**: 防御経路 (`selectedVersion == null` の異常 DB) で NULL→1 の silent 上書きが起き、Launcher の「人数: 不明」表示が「1人」に化ける UX drift があった。ReleaseYear と同じ pattern で `_gameMinPlayersWasNullOnLoad` / `_gameMaxPlayersWasNullOnLoad` flag を追加し NULL 維持。通常経路は selectedVersion 値で上書きされ救われるため影響は防御経路のみ (low priority)。
- **R4-L2 (#23): PathConversionHelper.ToAbsolutePath の base 空契約は High-8 で対応済**: 上記 R4-H5 と同 fix で集約。
- **R4-L3 (#25): BackupLogEntry.TriggerType の XML doc コメントを schema と同期**: 旧コメント `"manual" | "auto"` を `"manual" | "auto" | "safety" | "restore"` に拡張、schema (v10 で 'safety' / v16 で 'restore' 追加) と drift していた些細な doc 不整合を解消。
- **R4-L4 (#26): RestoreConfirmForm の確認コード生成で instance-shared Random を再利用**: 宣言済の `_random` field を実際に使うよう `GenerateConfirmationCode` を instance method 化。旧実装は毎回 `new Random()` を作っていたため高速連打で同一 seed → 同一コード再出で UX 混乱の risk があった。
- **R4-L5 (#27): VersionUpForm で baseVersion に画像がある + 新版が画像未設定のときに警告 dialog を追加**: activation Yes で新版を active 化すると games の旧画像 path が null 化されて Launcher の画像が消える silent UX 退行を防ぐため、OK 押下時に検出して「了承して進む / 戻って指定し直す」の選択肢を出す。
- **R4-L6 (#28/29): game_genres dead table を v18 で DROP + CreateTables / UpdateGameId / ExpectedSchema から除去**: v2 で追加されたが GameRepository.Add/Update は一切書き込まず `games.genre` のカンマ区切り文字列が SoT として動いている dead table。UpdateGameId だけが child table list に含めて更新していたため過去 v2 migration 経由の DB では「rename 時だけ古い行が追従」する半端な状態が残っていた。v17→v18 migration で DROP し、SoT を 1 本化。

#### Bump 根拠 (round 4 追記、v0.18.0 据え置き)

「1 PR 1 bump」規約 (AGENTS.md) に従い round 4 の追加修正分も v0.18.0 entry に統合。schema bump (v17 → v18) は automatic migration で非破壊 (CreateTables の dead table 除去 + developers FK 追加は新規 install 経路でも自動適用、v2 経由の既存 DB は MigrateV17ToV18 で sweep) のため、PR レビュー進行中に user が merge を押しても v0.18.0 として release できる状態を維持。breaking change には該当しないため version 番号自体は変更せず、entry 内に round 4 section を追記する形で対応。本ラウンドは Critical 1 / High 6 / Medium 12 / Low 7 = 計 26 件の修正 + DB schema v18 への bump を含む。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.17.2 - 2026-05-28 -->

#### Fixed (追加精査ラウンド: バックアップ / ゲーム周りに残っていた 8 件)

#234 + #235 + v0.17.0 / v0.17.1 を当てたあと、独立目線でゲーム追加・編集・バージョンアップ・バックアップ / 復元のコード経路を再精査し、コード上の根拠を持つ残存欠陥 8 件を修正。本ラウンドは新規修正で、レビュー対応コミットではないため `v0.17.1 → v0.17.2` patch bump（既知 21 件以外の独立した bug fix 群）。

- **【中】retention のソートが各 PC の wall clock 順だったため、時計ズレ PC が混ざると最新バックアップが先に削除されうる問題を修正**: `BackupLogRepository.GetAutoSuccessRetentionTargets` の `ORDER BY started_at DESC` を `ORDER BY id DESC`（AUTOINCREMENT = INSERT 順）に変更。`started_at` は `DateTimeOffset.UtcNow.ToUnixTimeSeconds()` 由来で各 PC の wall clock に依存するため、LAN 共有上で時計が大きくズレた PC（NTP 同期前 / RTC 電池切れ等）が auto バックアップを取ると、後から作られた行が古い扱いで先に削除対象になる逆転が起きていた。`id` は SQLite が INSERT 時に振る単調増加値で、同一 DB に対する write は serialise されるため真の作成順序を時計に依存せず復元できる。WHERE 句で `trigger_type='auto' AND status='success'` に絞っているため、ORDER 変更は手動 / safety / failed の保護（= 削除対象外、#235 で導入）には影響しない。
- **【中】`FileOperationService.CopyDirectoryRecursive` の個別ファイル copy 失敗が呼び出し側に伝わらず、DB は登録されたが実体が無い起動不能ゲームを silent に生む経路があったのを修正**: 旧実装は `File.Copy` 失敗を `Logger.Warn` / `Error` するだけで catch して continue、`copiedFiles` カウントだけ進めずループは完走し、呼び出し側は `ProcessingDialog.DialogResult == OK` を「コピー成功」と判定して `AddGame` / `AddGameVersion` / `UpdateGame` を commit していた。`main.exe` が他プロセス（Explorer プレビュー / 起動中の同 exe / ウイルス対策スキャン）に開かれている等で発火しうる。
  - 修正: `CopyDirectoryRecursive` に `List<string> failedFiles` 引数を追加して失敗 path を集約、`CopyDirectoryWithProgress` の戻り値を `void` → `List<string>`（= 失敗 list）に変更。呼び出し側（`AddGameForm.CopyGameFolder` / `GameSectionPanel.btnVersionUp_Click`）は list が空でなければ `FileOperationService.FormatCopyFailureMessage` で整形した例外を throw し、既存の rollback 経路（`CleanupCopiedFoldersOnRollback` / versionDir 削除）に流す。
  - さらに DB commit 直前に **exe / サムネイル / 背景** の `File.Exists` post-check を追加（case 違いやコピー直後の race による乖離を最後の砦として弾く）。post-check で欠落が見つかれば物理 rollback して入力やり直しを案内。
- **【低〜中】古い DB を復元したとき v14→v15 マイグレーションが「重複行残存」で partial skip しても、`RestoreReportForm` が「✓ 問題なし」と表示する経路を修正**: `SchemaManager.MigrateV14ToV15` は `UNIQUE INDEX` 作成失敗時に `user_version` を 14 のまま据え置いて `Logger.Warn` のみで起動継続する設計（V10→V11 と同じ pattern）だが、`RestoreReconciliationService.Analyze` は (1) 起動不能ゲーム (2) ディスクに無い版 (3) 孤児フォルダしか見ず、スキーマ未完を検出する経路が無かった。結果として「UNIQUE 制約が未適用の DB」で動いているのに復元レポートは安心メッセージ、その後のゲーム編集で重複行がさらに増殖し得る状態。
  - 修正: `Analyze` 冒頭で `GetActualDatabaseVersion() < GetTargetDatabaseVersion()` を check し、`RestoreReconciliationResult.SchemaIncomplete` / `ActualSchemaVersion` / `ExpectedSchemaVersion` に記録。`HasCriticalFindings` / `HasAnyFindings` も SchemaIncomplete を含む。`RestoreReportForm` に「DB スキーマが未完です（対処が必要）」セクションを追加して具体的なバージョン番号と再起動誘導を出す。本番 DB に重複は確認されていないが、将来の安全策として表面化経路を担保。
- **【低】`EditGameForm` のアクティブ版判定（読込側）が version 文字列比較だったため、版を rename したあと dropdown 切替で戻ると active-fallback が透過的に止まる非対称を修正**: 旧実装の `LoadGameDataForVersion` 内 `isActiveVersion = string.Equals(ToVersionLeaf(version.Version), ToVersionLeaf(originalGame.Version), ...)` は in-memory で rename した版を「別物」と誤判定し、sparse な初期版（旧 AddGameForm 由来で Title/Genre/数値項目が空）の active healing 経路が止まっていた。保存側は既に `_initialSelectedVersionId` との id 比較 (`L810`) に切り替わっているため、**load 側だけ取り残された非対称**。即データ消失ではない（数値項目は `_versionMinPlayersWasNullOnLoad` flag で保護されている）が、healing 機構が透過的に止まる UX 退行。
  - 修正: `isActiveVersion` を `_initialSelectedVersionId.HasValue && version.Id == _initialSelectedVersionId.Value` に変更し、read / write の判定基準を行 identity (= DB id) に揃えた。1 行 fix。
- **【低】`BackupService` / `RestoreService` のファイル名 (`yyyyMMdd_HHmmss`) が同 1 秒衝突したとき前のバックアップが silent に上書きされる問題を修正**: 1 秒粒度のタイムスタンプで衝突 check が無く、`SQLiteConnection("Data Source=<衝突 path>;...")` で開いて `BackupDatabase` を流すと destination の tables 全置換で前の中身が消える経路があった。発火確率は単一 PC では低い（`TryAcquireBackupLease` で auto 連発は防がれる）が、複数 PC が同 1 秒に lease をすり抜けるケースは構造的に起こりうる。
  - 修正: ファイル名生成後に `while (File.Exists(destinationPath))` ループで `_2` / `_3` ... の suffix を付与（衝突 100 件で safety throw）。`safety_*.db` も同 pattern。既存ファイル名形式との互換性のため衝突時のみ suffix を追加する形式とし、`BackupLogRepository.RecoverLegacyFailedEntriesByFolderScan` / `RegisterUnknownSafetyFiles` の regex も `(_\d+)?` optional を追加して新形式を受容。
- **【低】最新の自動バックアップを UI 手動削除すると、`last_backup_at` が rollback されず次回の自動バックアップが「間隔未到達」で skip される UX 不具合を修正**: `BackupSectionPanel.btnDelete_Click` は backup ファイル + `backup_log` 行を消すが `settings.last_backup_at` を更新しないため、削除後 `intervalHours` 経過するまで `BackupService.IsAutoBackupDue` が常に false。手動で取り直しは可能なので回避は効くが「最新が壊れてた / 不要だから消して取り直したい」操作と整合しない。
  - 修正: 削除対象が `trigger_type='auto' AND status='success'` のとき、`BackupLogRepository.GetLastAutoSuccess()`（新設、`ORDER BY id DESC LIMIT 1`）で残存最新を取り直し、`SettingsRepository.SetInt64("last_backup_at", completedAt ?? startedAt)` で rewind。残りが無ければ 0（= 初回扱い、次回 due 判定で auto 取得）。手動 / safety / failed の削除は `last_backup_at` 無関係なので無影響。
- **【低】`RegisterUnknownSafetyFiles` の重複判定が `file_path` 文字列の完全一致のみだったため、LAN 共有運用で UNC / ドライブ文字の表記揺れにより同一物理ファイルが 2 行で登録される問題を修正**: PC-A が `C:\TonePrism\backups\safety\X.db`、PC-B が `\\srv\TonePrism\backups\safety\X.db` で同じ物理ファイルを登録すると別 entry 扱い、履歴 UI に「同じファイルが 2 行出る」混乱を起こしていた（実害は表示のみ、復元・削除は file_path 個別に動くので機能は壊れない）。
  - 修正: `existingPaths` に DB 由来 path の `Path.GetFullPath` 正規化版も併用登録、enumerate 由来 path も同様に正規化して両方で重複判定。`GetFullPath` 不能な不正 path は元の文字列で判定にフォールバック（既存挙動互換）。
- **【低】`RestoreService.File.Replace` が SMB DFS / Junction Point / Symbolic Link 構成で `IOException` で fail したときの fallback が無く、復元失敗 + tempPath + WAL/SHM 削除済みの中途半端な状態が残る問題を修正**: `ReplaceFile` Win32 API は両 path が同一ボリュームでないと失敗するため、SMB 共有運用（#103 で明示サポート）の特定構成で破綻余地があった。safety は既に取れているのでデータ消失は無いが手動復旧が要る UX 退行。
  - 修正: `File.Replace` を `try`、`catch (IOException)` / `catch (UnauthorizedAccessException)` で `File.Delete(dbPath) + File.Move(tempPath, dbPath)` 経路に fallback（atomicity は落ちるが safety で担保済み、Logger.Warn で fallback 経路に流れた事実を記録）。

#### Bump 根拠 (v0.17.1 → v0.17.2)

bug fix のみのため patch bump。DB スキーマ変更なし、UI / 機能の追加も無し（`RestoreReportForm` の SchemaIncomplete セクションは既存ダイアログへの section 追加で新規画面ではない）。AGENTS.md「1 PR 1 bump」原則は、本 PR (#236) では v0.16.x → v0.17.x の連続 bump を「想定範囲を超える追加修正が混入した」例外条項で許容している既存運用に沿う（#234 / #235 の連続 bump と同パターン）。Bundle への反映は次回リリース実行時。

<!-- 統合元(旧): Manager v0.17.1 - 2026-05-28 -->

#### Fixed (v0.17.0 復元後の整合性チェック regression — 古いスキーマで必ず空振り)

- **【中】古い schema (例: `arguments` 列追加前 = v13 以前) のバックアップを復元すると、復元直後の整合性チェックが必ず「実行できませんでした」になっていた回帰を修正**: `BackupSectionPanel.btnRestore_Click` は ProcessingDialog で復元成功（= ファイル置換完了）後、`RestoreReconciliationService.Analyze()` を呼ぶが、**この時点ではまだスキーマ migration が走っていない**ため、現行クエリ（`GameRepository.GetAll` の SELECT に `arguments` 列を含む = v15 schema 前提）が `no such column: arguments` で例外。`Analyze` の catch 節で `AnalysisFailed=true` となり、`RestoreReportForm` が「整合性チェックを実行できませんでした、Manager を再起動してください」と表示。データ自体は無事（後続の `DatabaseChanged?.Invoke()` → `OnDatabaseRestored` で `InitializeDatabase` が走り chain migration 完走、次回起動時は正常）だが、v0.17.0 の目玉機能が古いバックアップ復元シナリオで必ず空振る regression だった。
  - 修正: `Analyze()` 呼び出しの**直前**に `_dbManager.InitializeDatabase()`（idempotent）を明示的に呼んで schema migration を保証する。後続の `DatabaseChanged?.Invoke()` 経路（= `OnDatabaseRestored.InitializeDatabase`）と二重呼出になるが両方 idempotent で害なし。`OnDatabaseRestored` 側で `InitializeDatabase` を呼んでいるからといって、その先で走る `Analyze` が migration 前である事実を見落としていた順序欠陥。

#### Fixed (#235 — 手動バックアップが自動 retention で silent に削除される)

- **【中】手動取得したバックアップが自動世代管理で消えていた問題を修正**: `BackupService.ApplyRetention` は世代数（既定 30）を超える古いファイルを削除するが、**判定がファイル名パターン `toneprism_*.db` のみ**で `backup_log.trigger_type` を参照しておらず、`manual` / `auto` / `safety` を全部同等に扱っていた。手動も自動も同じ `toneprism_{yyyyMMdd_HHmmss}.db` 命名で**ファイル名から区別できない**ため、部員が「念のため」取った手動バックアップが、後で自動バックアップが規定数を超えた瞬間に容赦なく消えていた。文化祭直前の「これだけは残しておきたい」snapshot ほど消えやすい構造だった。
  - 修正: `BackupLogRepository.GetAutoSuccessRetentionTargets(keepCount)` を新設（`trigger_type='auto' AND status='success'` の行を `started_at DESC` で並べて `keepCount` 件を skip した残りを返す DB 駆動 SoT）。`ApplyRetention` をこの結果に紐づくファイルだけ削除する形に書き換え、`manual` / `safety` / `failed` および**DB に未登録のファイル**は絶対に削除しないルールにした（= 自動 retention は「自分が取った自動バックアップだけ整理する」最小権限）。DB 行はそのまま残置（既存挙動互換、表示は `File.Exists` フィルタで自然に hide される）。

#### Fixed (`RestoreConfirmForm` のフルパス表示が古い絶対パスのまま)

- **【低】復元確認ダイアログの「フルパス:」表示が `BackupPathResolver` を通っておらず、プロジェクト移動後に旧絶対パスを表示していた問題を修正**: `_entry.FilePath` を生で表示していたため、`backup_log.relative_path` が記録されている行でもダイアログ上は移動前の絶対パスが見えていた。実際の復元処理（`btnRestore_Click`）は `BackupPathResolver.ResolveAbsolutePath` で正しく解決した値を使うため**動作は正しい**が、ユーザーには「違うファイルが復元されるのでは?」と疑念を与える UX 退行。
  - 修正: `RestoreConfirmForm` の ctor に `dbPath` を追加し、`Load` で `BackupPathResolver.ResolveAbsolutePath` を通した値を表示。呼出元 `BackupSectionPanel.btnRestore_Click` も `_dbManager.DatabasePath` を渡すように更新（表示と実行で同一の解決パスを使う対称化）。

#### Fixed (`EditGameForm` の MinPlayers/MaxPlayers が版切替で silent 上書きされる)

- **【低〜中】非アクティブ版で `min_players` / `max_players` が NULL の版を表示すると、ドロップダウンを切り替えるか OK を押すだけで前の版の値で silent に書き換わる問題を修正**: `LoadGameDataForVersion` の数値系で「`version.MinPlayers.HasValue == false` かつ非アクティブ版」のとき UI を**触らない** else 欠落があり、NumericUpDown には**前 version の表示値が残ったまま**になっていた。一方 `SaveGameDataToVersion` 側は無条件で `version.MinPlayers = (int)numMinPlayers.Value` を実行するため、画面上は何も変えていないのに DB は `null → 前 version 値` に書き換わる経路があった（#224 / #234 で潰してきた silent overwrite と同型の最後のギャップ）。`MaxPlayers` も同パターン（`Difficulty` / `PlayTime` には else 分岐があり影響なし、`SupportedConnection` / `ControllerSupport` は非 nullable で影響なし）。
  - 修正: load 側に else 分岐を追加して「非アクティブ + null」のとき UI を `Minimum` (=1) にリセットしつつ「load 時 null」flag と「表示値 snapshot」をフィールドに保存。save 側で **flag が立ち、UI 値が snapshot のまま**（= user が触っていない）なら null を維持、それ以外は UI 値を書き込む。アクティブ版の null フォールバック（games 値で healing → DB へ書き戻し）は従来の自己修復 path を意図的に温存。
- **【低】`EditGameForm` の防御経路（`cmbVersionList.Items.Count == 0`）で `games.version` が NULL に上書きされる subtle path を併せて修正**: `GameInfo` 構築時に `Version` が未設定で、防御経路の `dbManager.UpdateGame(game)` が `UPDATE games SET ... version = NULL` を発行する経路があった。通常経路（`selectedVersion != null`）では下で `game.Version = selectedVersion.Version` に上書きされるが、防御経路では上書きが走らない。`Version = originalGame.Version` を default に置いて防御経路でも version 文字列を保つ形にした。

#### Bump 根拠 (v0.17.0 → v0.17.1)

bug fix のみのため patch bump。DB スキーマ変更なし、UI / 機能の追加も無し。

<!-- 統合元(旧): Manager v0.17.0 - 2026-05-28 -->

#### Added (復元後の DB↔games フォルダ整合性チェック)

- **DB 復元の直後に「復元した toneprism.db」と「現在の games/ フォルダ」を突き合わせ、ズレを検出して復元手順を案内するようにした**: バックアップ/復元は `toneprism.db` 単体のみを対象とし `games/` フォルダには触れない（`BackupService` / `RestoreService`）。一方リセット（`SchemaManager.ResetDatabase`）は DB と `games/` を両方まっさらにするためズレないが、**別時点の DB を復元すると「DB は在るがディスクに無い版」「ディスクに在るが DB に無い孤児フォルダ」といったドリフトが起こりうる**のに、復元確認ダイアログにはその注意が無く、ズレを検知する仕組みも無かった。
  - 新サービス `Services/RestoreReconciliationService` が復元後に DB を読み直し、(1) **起動できないゲーム**（アクティブ版の実行ファイルが Launcher と同じ解決順＝絶対パス→ゲームルート基準→install 基準のいずれでも見つからない）、(2) **ディスクに無いバージョン**（`game_versions` 行はあるが `games/{id}/v{version}/` フォルダが無い）、(3) **DB に無い余分なフォルダ**（`games/` 直下の未登録ゲームフォルダ／既知ゲーム配下の未登録 `v*` フォルダ）に分類する。孤児版フォルダは `^v\d` 形状に限定して素材フォルダの誤検出を避け、`.pending-delete-*` 退避フォルダは除外する。
  - 新ダイアログ `RestoreReportForm`（Designer 不使用・コード生成）が結果を上記 3 分類で表示し、**整合した状態に戻すための番号付き手順**（全 PC の Launcher を閉じる → 想定パスのフォルダを同時点の games から補完 → 再起動で再チェック → 揃わなければ退避ファイル `safety_*.db` から DB を戻す）を併記する。深刻な問題（起動不能）があれば必ずレポートを表示、軽微なズレ／問題なしのときは簡潔な成功通知に留める。
  - 統合点は `BackupSectionPanel.btnRestore_Click` の復元成功後。チェック自体の失敗は握り潰して従来通り復元成功として扱う（復元結果そのものには影響させない）。

#### Fixed (`RestoreConfirmForm` の対象ファイル情報が縦に見切れる)

- **復元確認ダイアログの「対象 / 作成日時 / サイズ / フルパス」4 行のうち、下 2 行（サイズ・フルパス）が見切れていたのを修正**: `lblTargetFile` の高さが 40px しかなく、9pt 4 行分の縦サイズ（約 60–70px）に足りていなかった。Size を 88px に拡張し、下方のコントロール（警告文 3 行 / 確認コード / 入力欄 / 説明 / ボタン）を +50px 一律でずらし、`ClientSize.Height` を 340 → 390 に拡張。横方向はもともと 620px 確保され `AutoEllipsis=true` で長いパスは末尾省略されるため変更不要。

#### Added (復元イベントの監査ログ)

- **`RestoreService.Restore` と `BackupSectionPanel.btnRestore_Click` に Logger.Info / Error を追加**: 旧実装は復元処理が `Logger` を一切呼んでおらず（`ApplySafetyRetention` 内の retention ログのみ）、`logs/manager/*.log` を grep しても「復元実行」「復元成功」「復元失敗」の痕跡が一切残らない状態だった。失敗時 MessageBox 文言が「**詳細はログを確認**」と促すのに該当ログが空、という不整合があり、今回の本番運用直前の安全窓のうちに塞ぐ。
  - `RestoreService.Restore`: メソッド全体を `try/catch` で包み、開始 / 現DB 退避完了 / DB ファイル置換完了 / 復元完了 を `Logger.Info`、`OperationCanceledException` を Info、その他例外を `Logger.Error(..., ex)`（例外オブジェクトを渡してスタックも残す）で記録してから throw する。caller の `ProcessingDialog` catch では例外型が `Abort` に潰されてしまうため、詳細はここで残すのが唯一の audit point。
  - `BackupSectionPanel.btnRestore_Click`: 確認ダイアログでのキャンセル / 復元意思確定 (確認コード通過) / session conflict キャンセル / ProcessingDialog キャンセル / Abort / 復元成功 + 整合性チェック結果要約 (`broken=N missing_versions=M orphans=K`) をそれぞれ `Logger.Info` / `Logger.Error` で記録。これにより、ログ 1 本を時系列に見るだけで「誰がいつ何を復元してどんなドリフトが残ったか」が追跡できるようになる。
  - 復元の対称機能であるバックアップ作成側 (`BackupService.RunManualBackup` / `RunAutoBackupIfDue`) は既に `backup_log` テーブルに DB レベルで全件記録される設計のため、本変更の対象外。

#### Fixed (`StoreSectionPanel.ConfigureDataGridView` で WinForms 内部 NRE)

- **復元後の `DatabaseChanged` 再読み込み経路でストアセクション panel が WinForms 内部 `NullReferenceException` を起こしていたのを防御化**: `dgvSections.DataSource = null; = _sections; ConfigureDataGridView();` の直後タイミングで auto-generated column の internal state が transient な間に、列の `Visible` / `HeaderText` / `Width` setter が WinForms 内部で null 参照に達する経路が観測された (本リリースで追加した復元後の全 panel reload で表面化、System.Windows.Forms.dll 内で throw)。本 NRE は元々 `LoadSections` 内の `catch (Exception ex)` で握れているため Manager は復元成功後も継続動作するが、ストアセクション一覧が一瞬空になる UX 退行 + デバッグ実行時の例外 break の元になっていた。
  - 対策: (1) `dgvSections.SuspendLayout()` / `ResumeLayout(true)` で内部レイアウト更新を一括化、(2) 全列を一旦非表示にする foreach を `Cast<DataGridViewColumn>().ToList()` でスナップショット経由に変えて enumerator + 列参照の二重防御、(3) 名前指定 column アクセスを `ConfigureColumn(name, header, width)` helper に集約し `Contains` + 二重 null チェックを追加。`GameSectionPanel.ConfigureDataGridView` の defensive pattern と趣旨を揃える。
  - 範囲確認: `BackupSectionPanel` / `LogSectionPanel` は `AutoGenerateColumns=false` + 明示 column 定義で同種 race の影響を受けない。`GameSectionPanel` は既に文字列配列ベースの定義 + 明示 null チェックで対策済。本修正対象は `StoreSectionPanel` のみ。

#### Bump 根拠 (v0.16.6 → v0.17.0)

復元後の整合性チェックという新機能の追加のため minor bump。DB スキーマ変更なし、既存の復元処理（`RestoreService`）の挙動も不変で、成功後に読み取り専用の突き合わせと案内ダイアログを足すのみ。

<!-- 統合元(旧): Manager v0.16.6 - 2026-05-28 -->

#### Added (#234 ② フォローアップ — `game_versions` への UNIQUE 制約)

- **`game_versions(game_id, version)` に UNIQUE INDEX を追加（DB v15）**: v0.16.5 では「本番 live data に既存 dup 行があると migration が失敗しうる」ため app-level guard のみで対応し、DB 制約は意図的に見送っていた（当時の記述は下記 v0.16.5 末尾参照）。本番が本格運用に入る前の安全な窓のうちに、同一ゲームに同一バージョン番号が 2 行入る silent corruption を防ぐ**最後の砦**を DB レベルで追加する。アプリ層 dup-check（`VersionUpForm` / `EditGameForm` / `GameSectionPanel`）は「check → write」が 2 ステップに分かれるため、複数 PC が同一ゲームを同時にバージョンアップする race ではすり抜けうるが、UNIQUE INDEX があれば 2 件目の INSERT を DB が確実に弾く。
  - 実装: `SchemaManager` の `CurrentDbVersion` を 14 → 15 に上げ、新規 DB は `CreateTables`、既存 DB は `MigrateV14ToV15` で同一の `EnsureGameVersionsVersionUniqueIndex` ヘルパーを呼ぶ。
  - **重複残存時の安全装置**: 既存 DB に重複 `(game_id, version)` が残っている場合、index 作成は制約違反で失敗する。これを事前検出し、**throw せず警告ログ + skip** して `user_version` を 14 のまま据え置き、次回起動時に再試行する（`MigrateV10ToV11` の "data residual → skip + warn + retry" パターン踏襲＝起動を壊さない）。`CreateTables` 側は戻り値を無視し警告のみで起動継続。
  - version は raw 文字列比較（BINARY collation）。意味的正規化（`v1.0.0`/`1.0.0` の同一視）は引き続きアプリ層の責務。
  - 検証: live DB（user_version=14・24 版）/ 2026-05-27 本番バックアップ ともに重複なしを確認済みのため、次回起動時にクリーンに index が作成される。

#### Fixed (追加精査 5th pass — 3 フォーム整合の残存ギャップ)

- **①【低】`VersionUpForm.ValidateInput` だけ実行ファイルの「コピー元フォルダ内」チェックが欠落**: サムネ/背景には `IsPathInside` チェックがあるのに exe だけ無い非対称（`AddGameForm` / `EditGameForm` には exe の inside チェックあり）。textbox は ReadOnly でフォルダ外には現状成り得ないため実害は無いが、多層防御として 3 フォームを揃える。
- **③【低】`EditGameForm` の `arguments` が `selectedVersion==null` 防御経路で null 正規化されない**: 通常経路では選択版の正規化値で上書きされるが、防御経路で `games.arguments` に空文字 `""` を残しうる非対称。Add/VersionUp と同じ null 正規化に揃える。
- **④【低】バージョンフォルダ leaf 名の正規化を `PathManager.GetVersionFolderLeaf` に集約**: `PathManager.GetVersionFolder`（disk のコピー先）と `GameSectionPanel`（DB 保存パスの prefix）が共に case-sensitive な `StartsWith("v")` で leaf 名を独立計算しており、生値が `"V1.0.0"`（大文字 V）の場合に前者は `"vV1.0.0"`・後者は別結果となって**実フォルダ名と DB 保存パスが食い違う**死角があった。`v`/`V` を剥がして小文字 `v` を被せ直す helper（`EditGameForm.ToVersionLeaf` と同規則）に両者を集約し、必ず一致させる。新規版は `VersionString` が常に小文字 `v` のため通常フローの挙動は不変。
- **⑤【低】`PathConversionHelper.ToRelativePathAfterCopy` の境界判定が区切り文字非安全**: 生 `StartsWith` のため `dest="games\game1"` が `"games\game10\..."` のような兄弟フォルダにも前方一致しうる死角。現 caller では `destinationFolder` から構築したパスしか渡らず実害は無いが、`IsPathInside` / `ToRelativePath` と同じ「等値 OR 区切り付き StartsWith」に揃えて多層防御を統一。

#### Fixed (② UNIQUE 制約追加による回帰 — バージョン番号の入れ替え保存が失敗)

- **【中】`EditGameForm` でバージョン番号を「入れ替え／玉突き／循環」させて保存すると UNIQUE 制約違反で失敗する回帰**: 上記 ② の `game_versions(game_id, version)` UNIQUE INDEX は immediate 制約のため、編集画面で例えば 2 版の番号を交換（`v1.0.0`↔`v2.0.0`）してから保存すると、保存処理が版を 1 行ずつ確定する途中で「一瞬だけ同じ番号が 2 行」存在する中間状態が生じ、**最終状態は一意なのに制約違反で throw** していた。編集画面はドロップダウンで各版の番号を画面上で自由に書き換えてから OK でまとめて保存する作りのため、アプリ層 dup-check（最終状態を正規化比較）は素通りし、保存時のみ失敗する分かりにくい挙動になっていた。玉突き（A→B→C）や循環（A↔B）でも同様。
  - 修正: `VersionRepository.UpdateMany`（`DatabaseManager.UpdateGameVersions` 経由）を新設し、**単一トランザクション内で「対象全行の `version` を一意な一時値（`__tmp_<id>_<GUID>`、SemVer と絶対に被らない）へ退避 → 本番の全列を確定」する 2 フェーズ方式**に変更。最終状態が一意である限り各 UPDATE 実行時点で衝突相手が存在しないため、途中の UNIQUE 一時衝突を構造的に回避する。
  - 副次的改善: 旧実装は `VersionRepository.Update` を 1 行ずつ呼ぶ per-call commit ループだったため、N 件目で失敗すると 0..N-1 件目が commit 済の**部分コミット drift**（DB と disk フォルダ名の不整合 → 要手動修復）が残りえた。一括化により「全成功 or 全 rollback」の原子性になり、失敗時は DB 無変更で返るため完了済 disk rename を常に安全に rollback できる。`EditGameForm` 側の `dbSucceededCount` 分岐（部分コミット通知）は不要になり削除。

#### Bump 根拠 (v0.16.5 → v0.16.6)

DB スキーマ変更（v15、`game_versions` への UNIQUE INDEX 追加）+ データ整合性 hardening。Bundle 版数の Major 判定（AGENTS.md「DB schema 変更含む」）はリリース時に行う。

<!-- 統合元(旧): Manager v0.16.5 - 2026-05-27 -->

#### Fixed (#234 — バージョンアップ/追加のデータ整合性 8 件 + 周辺修正 + 製作者バリデーション緩和)

ゲーム追加・編集・バージョンアップ処理の精査で、編集パス（`EditGameForm`、#158/#224 で堅牢化済）と同等の防御が version-up / add パスに展開されておらず発生していた整合性欠陥を修正。

- **①【高】バージョンアップに「最新版以外との重複」防止がない**: `VersionUpForm.ValidateInput` は新バージョンを `currentVersion`（=最新版）としか比較しておらず、数値欄を直接編集して非最新版（例: 過去の 1.5.0）と同じ番号を入力すると validation を通過していた。その後 `GameSectionPanel.btnVersionUp_Click` が `Directory.CreateDirectory`（既存フォルダで no-op）→ 既存 version folder へ `File.Copy(..., overwrite:true)` で上書きマージ + `game_versions` へ重複行 INSERT（`UNIQUE(game_id, version)` 制約なし）し、Launcher 側で「どちらの版か」決定不能になる silent corruption が起きた。**対策**: `VersionUpForm` に既存全版リストを渡し、`EditGameForm` の #158 Q2 dup-check と同じく SemVer 正規化後（`SemverInputControl.TryNormalize`、v 大小・leading v 有無を同一視）で全版と重複比較。さらに `btnVersionUp_Click` で `Directory.Exists(versionDir)` を二重防御（`AddGameForm.CopyGameFolder` と同方針）。
- **②【中】新規追加で `AddGameVersion` 失敗時に `games` 行が孤児化**: `AddGame` と `AddGameVersion` は別トランザクションのため、後者失敗時に commit 済 `games` 行だけが残り、版なし・フォルダなしの孤児ゲームが Launcher に出て起動不能になっていた（catch はフォルダのみ削除）。**対策**: `AddGameForm` の catch で `RollbackGameRow` を呼び、commit 済なら `DeleteGame`（FK CASCADE で developers 等も巻き取り）で `games` 行も rollback。
- **③【低〜中】version-up の誤解を招くエラー + 孤児フォルダ**: `AddGameVersion` 成功後に activation（`UpdateGame`）が失敗すると「データベースへの保存に失敗しました」と出るが版は保存済で、同番号で再実行すると①へ突入していた。また `AddGameVersion` 自体の失敗時にコピー済 `versionDir` がディスクに残っていた。**対策**: version 行 INSERT と activation を別 try に分離。INSERT 失敗時は `versionDir` を rollback 削除し「保存に失敗・ファイルは削除」と通知、activation 失敗時は「版は作成済・アクティブ化のみ失敗」と正確に通知。ProcessingDialog cancel 時も `versionDir` を掃除。
- **④【高】保存パスに `v{version}/` プレフィックスが付かず Launcher で実体に届かない**: Launcher は `games` のパス（`executable_path` / `thumbnail_path` / `background_path`）を**ゲームルート `games/{id}/` 基準**でしか解決しない（`GamePathResolver` が `get_game_folder()` に保存文字列を `path_join` するだけで version フォルダを補完しない）。一方ファイル実体は `games/{id}/v{version}/` 配下にあるため、保存値は `v{version}/` を含む必要がある。ところが (a) `AddGameForm` は相対化の基準を version フォルダにしていたため `executable_path` 等が `main.exe`（プレフィックス無し）になり、**新規追加ゲームが起動不能 + サムネ/背景が非表示**（既存 20 本は旧スキームのルート直下重複ファイルで偶然解決できていたが、新規インストールでは実体がルートに無いため救済されない）。(b) version-up は①③と同じ #234 で exe は `v{version}/` 付きに修正済だったが、**サムネ/背景は付け忘れ**ており、バージョンアップしてアクティブ化すると画像だけ消える状態だった。**対策**: `AddGameForm` の相対化基準を version フォルダ → ゲームルート（`PathManager.GetGameFolder`）に変更し exe/サムネ/背景すべてに `v{version}/` を載せる。`GameSectionPanel.btnVersionUp_Click` で exe と同様にサムネ/背景にも version フォルダ名を前置（`games`=`UpdatedGameInfo` / `game_versions`=`NewVersion` 両テーブルに反映）。`game_versions` 側もプレフィックス付きに揃えたことで、version-up 済み既存データ（例: Toney_Fox）と一貫し、`EditGameForm` のバージョン名リネーム（`ReplaceVersionPrefix`）も正しく連動する。

- **⑤【高】追加直後のゲームを編集すると Title/ジャンル/サムネ/背景/難易度/プレイ時間/コントローラ/通信/製作者 が消える**: `AddGameForm` が作る初期バージョン行は `ExecutablePath` / `Description` / `Arguments`（#224 で追加）しか持たず、それ以外のメタデータが未設定のまま `game_versions` に INSERT されていた。`EditGameForm.LoadGameDataForVersion` はアクティブ版（=初期版）の値で UI を上書きするため、追加直後のゲームを編集で開くと上記項目が空 / 既定値（難易度・プレイ時間は「ふつう」、通信は「なし」、コントローラは off）にリセットされ、OK 保存で `games` 行ごと巻き添えに破損していた（#224 が Description/Arguments で直したのと**同じデータ損失が残り項目に残存**していた）。**対策**: (a) `AddGameForm` の初期版を `games` の全フィールドのミラーにする（製作者はディープコピー）。(b) `EditGameForm.LoadGameDataForVersion` の「アクティブ版フォールバック」（#224 で Description/Arguments のみ実装）を Title / Genre / 難易度 / プレイ時間 / 最小最大人数 / サムネ / 背景 / 製作者 / コントローラ / 通信 に拡張し、既存のスカスカ初期版行を編集→保存で自己修復させる。コントローラ/通信は非 nullable で未設定 sentinel が無いため、アクティブ版に限り `games` 値（定義上の真値）を採用する。
- **周辺修正 3 件**: (i) サムネ/背景の**自動検出時にプレビューが更新されない**（`AddGameForm` / `VersionUpForm` の `AutoDetectFiles` が手動選択と違い `UpdateThumbnailPreview` / `UpdateBackgroundPreview` を呼んでいなかった）のを修正。(ii) `VersionUpForm` のサムネ/背景選択に**コピー元フォルダ内チェック**を追加（`AddGameForm`・exe 選択と同挙動。フォルダ外選択で絶対パスがそのまま保存され、コピーされないファイルを指す穴を塞ぐ）。(iii) 最新版判定を `VersionRepository.GetByGameId` の `ORDER BY registered_at DESC` → `id DESC` に統一（秒精度タイで「最新版」が非決定的になる問題を解消し、`GameRepository.GetAll` の `display_version`（`id DESC LIMIT 1`）と整合）。(iv) `VersionUpForm` の `Description` / `UpdateNote` を空白 → null 正規化（#224 で「3 フォームで DB 表現を統一」と決めたが VersionUpForm だけ素の `Trim()` で取り残され、空欄入力時に他フォームの null と異なる `""` が `games` / `game_versions` に保存されていた）。

**追加精査で見つかった残存欠陥（2nd pass）**:

- **⑥【中〜高 UX】編集画面でバージョンを選び直して OK するとアクティブ版が無言で切り替わる**: `EditGameForm.btnOK_Click` は `cmbVersionList.SelectedItem`（ドロップダウンの現在選択版）を `games` 行へミラーし `games.version` まで上書きする設計のため、古い版を眺めようとドロップダウンを切り替えてから他項目を直して OK すると、**Launcher で起動する版が無言でその版に切り替わって**いた（version-up は明示確認するのに編集画面は無確認という非対称）。**対策**: `LoadVersions` 時の初期選択版（=ランチャー表示版）の DB id を記録し、OK 時に別 row が選択されていれば「現在表示しているバージョンをランチャーで表示・起動するバージョンにしますか?」と確認、「いいえ」で編集画面に戻す。row（DB id）比較なので表示版を rename しただけでは発火しない。製作者フォーム（`DeveloperForm`）の「名」ラベルに付いていた必須マーク `*` も上記緩和に合わせて除去。
- **⑦【中】アクティブ版から製作者を全削除しても Launcher に反映されない**: `EditGameForm` は製作者を版（`version_id` 付き）に保存するが `games` 行（`version_id IS NULL`）は `originalGame.Developers` のまま温存していた。Launcher は「版に紐づく製作者が空なら `version_id IS NULL` にフォールバック」（`game_repository.gd`）するため、アクティブ版の製作者を全削除しても `games` 行の旧製作者が残り表示され続けた。**対策**: `games` 行の製作者も編集中リスト（=選択版=OK 後のアクティブ版）でミラーし、全削除が両レイヤーに反映されるようにする。
- **⑧【低〜中】`VersionUpForm` がサムネ/背景の存在・フォルダ内検証を最終段で行っていない**: `AddGameForm` は OK 時に存在＋フォルダ内を検証するが `VersionUpForm.ValidateInput` は exe しか検証せず、OK 時に絶対パスのままだと `GameSectionPanel` の `Path.Combine(versionFolderName, 絶対パス)` が絶対パスを素通しして「コピーされない元フォルダを指す壊れた画像パス」を保存しうる穴（④ と同種）が残っていた。**対策**: `VersionUpForm.ValidateInput` にサムネ/背景の `File.Exists` ＋コピー元フォルダ内チェックを追加し `AddGameForm` と揃える。
- **製作者バリデーション緩和**: `DeveloperForm` は「名」必須だったが、姓のみ判明しているケース等に対応するため「姓・名のどちらか一方でも入っていれば可」に緩和。

**追加精査で見つかった残存欠陥（3rd pass）**:

- **⑨【低】最小プレイ人数 &gt; 最大プレイ人数 を保存できる**: 3 フォーム（`AddGameForm` / `EditGameForm` / `VersionUpForm`）とも `ValidateInput` に min/max の大小チェックが無く、最小 4・最大 1 のようなナンセンスな値をそのまま `games` / `game_versions` に保存できていた（起動は壊れないがランチャー表示が破綻するデータ品質欠陥）。**対策**: `GameFormHelper.ValidatePlayerCount` を新設し 3 フォームで共通呼び出し（drift 防止）。最小 &gt; 最大なら入力エラーで弾く。
- **⑩【低】`VersionUpForm` の重複チェックが malformed な既存版を素通りさせる**: `VersionUpForm.ValidateInput` の dup-check は `SemverInputControl.TryNormalize` 成功版としか比較しておらず、DB に残った正規化不能な版文字列（例: `"1.0"` / `"alpha"`）と raw 一致する新版を作れる穴が残っていた（`EditGameForm` は GroupBy キーを raw fallback して同型を既に捕捉済）。**対策**: 正規化不能な既存版に対しては生値（前後空白・大小無視）で最終比較し、完全同名だけは弾く分岐を追加。
- **⑪【低】新規追加失敗の rollback で空の親フォルダ `games/{id}/` が残る**（②の対称化）: `AddGameForm` の rollback はバージョンフォルダ `games/{id}/v{version}/` しか削除せず、`CopyGameFolder` が新規作成した親 `games/{id}/` が空のまま残り、次回同 gameId 追加時に #120「古いゲームデータが残っています」警告が誤 trigger していた（SPEC §3.8.5 が「将来 `parentCreatedThisCall` flag 等で対称化可能だが別 issue 候補」としていた受容仕様）。**対策**: `baseGameFolderCreated` flag で「この追加操作が親を新規作成したか」を記録し、rollback helper `CleanupCopiedFoldersOnRollback` が **「今回新規作成」かつ「親が空」** の両条件成立時だけ親も削除。追加前から存在した親（#120「既存フォルダで続行」経路）や他 version 共存ケース（親が非空）には一切触らない二重防御で誤削除を排除。SPEC §3.8.5 を対称化済みに更新（SPEC v1.10.43）。
- **⑫【中】#120「既存フォルダあり」警告の文言と実装が矛盾（バージョン衝突時にデータ消失）**: 旧 #120 は「OK で続行＝親フォルダを retain」方針で、警告文に **「※ 古いフォルダの中身は自動削除されません」** と明記していた。ところが既存フォルダに**追加バージョンと同名の版フォルダ**（例: 残骸の `games/{id}/v1.0.0/`）があると、`CopyGameFolder` が `destinationGameFolder` に既存パスをセット→「既に存在します」で throw→rollback の `CleanupCopiedFoldersOnRollback` が**その既存版フォルダを中身ごと削除**しており、「同じバージョン→エラーになるだけ」「自動削除されません」という文言に反する silent data loss だった。**対策（設計変更）**: #120 を **「OK＝フォルダを中身ごと削除して新しく作り直す」** 方針に一本化し、文言も実装に合わせて書き換え（バージョン衝突 footgun を構造的に排除＝ゲーム削除と同じ「警告時点で退避」思想）。`wipeExistingOnCopy` gate（警告を出して OK したときのみ true）を立て、`CopyGameFolder` が worker thread 内で親 `games/{id}/` を丸ごと削除→再作成（UI freeze なし、削除失敗時は「Launcher 等が使用中の可能性」と明示して中断＝半削除フォルダにコピーを重ねない）。⑪ で追加失敗時の空フォルダ残りを潰してあるため、本警告自体めったに発生しない。SPEC §3.8.5 を新方針に更新（SPEC v1.10.43）。

**追加精査で見つかった残存欠陥（4th pass）**:

- **⑬【低〜中】バージョンアップのフォルダコピーが `v`+数字名のフォルダを無言で除外**: `GameSectionPanel.btnVersionUp_Click` のコピーは `excludeFolderPredicate: FileOperationService.IsVersionFolder`（先頭が `v`+数字）を**全階層**に適用していた。本来の狙いは「コピー元に `games/{id}/` 自体を選んだ際に既存版フォルダ `v1.0.0/` 等を巻き込まない」ことだが、(a) そのルート選択誤操作は `CopyDirectoryRecursive` 冒頭の再帰ガード（コピー先がソース内側なら即 return）が既に**空コピー**で防ぐため除外は無力、(b) 一方で新ビルド内の正当な `v2` / `v3_assets` 等のフォルダ（ゲーム本体データ・素材を含みうる、サムネ/exe に限らない）を**無言で取りこぼす**下しか無い保険だった（エラーも出ない silent な欠落）。`AddGameForm` 経路は除外しておらず挙動も非対称。**対策**: `IsVersionFolder` 除外を撤去（唯一の参照だったためメソッドも削除）。ルート選択誤操作は ⑭ で明示的に弾く。
- **⑭ コピー元に `games/` 配下を選ぶ誤操作を境界で拒否**: ⑬のルート選択は従来「空コピー → 壊れた版」になるだけで明示エラーが無かった。新ビルドは必ず `games/`（Manager 管理下のゲーム本体置き場）の外から取り込む規約のため、`GameFormHelper.ValidateSourceNotInGamesFolder` を新設し、`AddGameForm` / `VersionUpForm` の `ValidateInput` でコピー元が `games/` 自身・配下（他ゲーム・版フォルダ含む）なら入力エラーで弾く（区切り文字安全な正規化比較）。
- **⑮【低】`VersionUpForm` のサムネ/背景が空欄時に `""` で保存（null 正規化漏れ）**: #224 review #2 で「3 フォームで空欄は null 統一」と決めたが、`VersionUpForm.btnOK_Click` は Description/UpdateNote/Arguments のみ正規化し ThumbnailPath/BackgroundPath は素の textbox 値（空なら `""`）を代入していた。空のまま進むと `game_versions.thumbnail_path` 等が他フォーム/`games` 行の null と異なる `""` で保存される。**対策**: 空欄を null 正規化（非空時は従来どおり下のブロックで相対パス化）。
- **⑯【低】フォルダ内判定の `StartsWith` が区切り文字非考慮**: 3 フォームの「実行/サムネ/背景はフォルダ内か」チェックと `PathConversionHelper.ConvertSourceToDestination` の分類が区切り文字なしの生 `StartsWith` で、`C:\games\foo` が `C:\games\foobar\...` のような兄弟フォルダに前方一致しうる（実害は下流の区切り安全な `ToRelativePath` がフォルダ外扱いに落として吸収するため軽微だが、UX ゲートとして不正確）。**対策**: `PathConversionHelper.IsPathInside`（正規化＋区切り境界比較）を新設し全箇所を置換。`VersionUpForm` の exe 選択時の相対化も脆い `Substring(folder.Length)` から `ToRelativePath` に統一。`EditGameForm.UpdatePathTextBox`（gameId rename 時の prefix 置換、substring 演算依存・対象は構造上必ず `games/{oldid}/` 配下）は意図的に据え置き。

`game_versions` への `UNIQUE(game_id, version)` 制約追加は、本番 live data に既存 dup 行があると migration が失敗しうるため見送り、app-level guard で対応（編集パスと同方針）。

なお既存 DB の「プレフィックス無し行」（`2D_adventure` / `Only_Up` 等、旧スキームのルート直下重複ファイルで動作中）は本コード修正の対象外。実体がルートにある限り現状でも解決できるため、データ補正は別途必要になったら対応。

#### Bump 根拠 (v0.16.4 → v0.16.5)

SemVer pre-1.0 patch bump: データ整合性 bugfix のみ。スキーマ変更なし。

### [Manager v0.16.4] - 2026-05-27

#### Fixed (#224 — ゲーム編集のデータ損失 2 件)

実機で「Only_Up の説明文が消失」「起動オプションが保存されない」として発覚したデータ損失バグを修正。バージョン制（version ごとに説明/引数を持てる）は維持したまま、実装ミスを正す方針。

- **バグ①: 起動オプション(arguments)が保存されない** — `EditGameForm.SaveGameDataToVersion` が `txtArguments` を version に書いておらず（他フィールドは全て書くのに arguments だけ漏れ）、OK 保存時の mirror `game.Arguments = selectedVersion.Arguments`（null）で `games.arguments` が消えていた。`SaveGameDataToVersion` に arguments の保存を追加。`LoadGameDataForVersion` でも arguments を版から読むようにし per-version で round-trip させる（form ロード時の games 由来ロードは削除して一本化）。
- **バグ②: ゲーム説明文が空で上書き消去** — `AddGameForm` が初期 version の `description` に本物でなく `"初期バージョン"` を入れていたため、編集で開くと version 由来の説明欄に `"初期バージョン"` が出て、保存で `games.description`（本物）が上書きされていた。初期 version は `games` と同じ本物の description / arguments を持たせ、`"初期バージョン"` は更新内容(`update_note`)へ移動。
- **アクティブ版限定の desync フォールバック**: `LoadGameDataForVersion` は version の description/arguments をそのまま読むが、**アクティブ版（`games.version` に一致する版＝games が mirror する版）に限り**、版の値が空で `games` 側に値がある場合のみ `games` にフォールバックする。実 DB には「`games.description` が本物・対応版が null」の旧データ（旧 AddGameForm 由来、実機 15/20 ゲーム）が存在し、これを編集→保存で空消去しないための保護。アクティブ版は定義上 games の mirror なので「空なのに games が非空＝desync と証明できる」行のみが対象。**非アクティブ版の意図的な空は対象外**で per-version 独立性を壊さない（Codex P2 / review #1 の「desync と証明できる行に限定」指針に沿う）。フォールバック値は OK 保存でアクティブ版に書き戻され自己修復する。
- **VersionUpForm**: バージョンUp 時に `games.arguments` が新版の値に更新されていなかった（version 側には入るが games 側に漏れ、Launcher は games を読むため旧引数のまま起動）。`UpdatedGameInfo.Arguments` を設定して整合。

- **arguments の空正規化を 3 フォームで統一** (review #2): 空入力時の `arguments` を `AddGameForm` / `EditGameForm` / `VersionUpForm` すべて「空白なら `null`」に揃えた（旧: 生文字列 / null / 空文字が混在）。`games` / `game_versions` の空表現が安定。Launcher 側は元々 `is_empty()` ガードがあり実行時影響なし。

Launcher は実行時に `games` テーブルのみ読むため、上記で games 側が正しくなれば表示・起動とも正しくなる。本番はまっさら新規インストールのため既存 desync データは無く、DB マイグレーション/backfill は不要。

#### Bump 根拠 (v0.16.3 → v0.16.4)

SemVer pre-1.0 patch bump: データ損失 bugfix のみ。スキーマ変更なし。

### [Manager v0.16.3] - 2026-05-27

#### Fixed (累積コードレビュー指摘の対応)

- **`GameRepository.ReadGameInfo` の `arguments` 読み取りで silent な握り潰しを解消**: `try { … } catch { }` で例外を完全に飲み込んでおり、コメント「GetAll uses display_version alias which doesn't include arguments」も誤り (GetAll / GetById 双方の SELECT に `arguments` を含む)。catch を削除して直接読み取りに変更。将来 SELECT から `arguments` が誤って外れても例外が表面化するようになり、`Arguments` の隠れた null 化経路を排除。
- **`DatabaseConnection.ExecuteWithRetry<T>` の到達不能 `return default(T)` を例外に変更**: ループは「成功で return」「最終 retry で throw」のいずれかで必ず抜けるため到達しないが、万一 `maxRetries<=0` 等で到達した場合に `null` / `0` を silent に返さず `InvalidOperationException` を投げるよう変更 (将来の制御フロー変更時の silent failure 予防)。

#### Changed (スキーマ drift 解消: games.arguments を正規 migration 化、DB v13 → v14)

- **`games.arguments` の追加を `CreateTables()` 内アドホック ALTER から `MigrateV13ToV14` に移設** (`CurrentDbVersion` 13 → 14)。旧実装は (a) `user_version` に連動せず毎起動 `PRAGMA table_info` で存在チェックして足す野良 migration で、(b) 失敗を `catch` で握り潰していた (AGENTS.md「`CreateTables()` を編集したら必ず `MigrateVxToVy`、スキーマ drift の温床」に違反)。version chain に正規化し、失敗時は例外を伝播させて transaction を rollback するよう変更。
- **最終スキーマは不変**: 新規 DB は `CREATE TABLE games` で従来どおり `arguments` を持ち、`MigrateV13ToV14` は `TableHasColumn` で idempotent (= 列がある DB では no-op)。`ExpectedSchema` / SPEC §7.3 とも差分なし。retrofit が必要なのは arguments 列を持たない旧 DB のみ。
- **v0 (versioning 導入前) DB の retrofit を維持** (Codex P1): `user_version=0` の旧 DB は `CheckAndMigrateDatabase` の早期 stamp path で chain を skip するため、`MigrateV13ToV14` をその path 内でも明示実行。これで旧実装 (`CreateTables` 内 retrofit) と同じ v0 カバレッジを保ち、列欠落のまま `no such column: arguments` で落ちる回帰を防ぐ。
- `MigrateGamesTable` (games の `supported_connection` / `version` 追加) は `games.arguments` を参照しないことを確認済みで、retrofit を chain (= `MigrateGamesTable` の後) に移しても初期化中の依存は発生しない。

#### Bump 根拠 (v0.16.2 → v0.16.3)

SemVer pre-1.0 patch bump: bugfix + 内部マイグレーション hygiene のみ。`games.arguments` 移設は最終スキーマ不変 (= ユーザー影響なし) で、隠れた失敗経路の顕在化に限定。DB v13 → v14 bump は migration を版数管理下に置くためで、新規 install / 既存 DB ともに挙動互換。

### [Manager v0.16.2] - 2026-05-21

#### Fixed (#221 — ゲーム編集でバージョン未変更でも self-rename 例外)

バージョン番号を変えずに（例: 起動オプションだけ編集して）OK を押すと、`game_versions.version` が `v` prefix 無し（例 `"1.0.0"`）で保存されているゲームで「フォルダリネーム失敗（ソース パスとターゲット パスを同じにすることはできません）」が出て保存できない不具合を修正。

- 原因: rename skip guard（renamePlan 構築ループの `originalVer` vs `v.Version` の raw 文字列比較）は生比較だが、フォルダ leaf は `ToVersionLeaf` で正規化 (`"1.0.0"` も `"v1.0.0"` も leaf `"v1.0.0"`)。raw 比較は不一致で skip されず、`oldDir == newDir` の self-rename plan が作られ Phase 2 の `Directory.Move(同, 同)` が IOException → 失敗ダイアログ。
- 修正: (1) `oldDir`/`newDir` 算出直後に leaf 正規化後が同一 (`string.Equals(oldDir, newDir, OrdinalIgnoreCase)`) なら rename plan から除外 (`continue`)。(2) 同じ非対称が `reservedOldDirs` 構築ループにもあり（raw guard のままだと「rename されず空かない leaf」を予約済みとして登録し、別 version が同一 leaf を target にした衝突を Phase 1 衝突 check で見逃す）、こちらも leaf 比較に統一。DB は後続の `UpdateGameVersion` ループが全 version を normalized 値で書き戻すため、disk を触らず DB だけ正規化される正しい挙動になる。
- 影響: `v` prefix 無しで DB 保存された既存ゲーム全般（バージョン未変更の編集が全て詰んでいた）。

#### Bump 根拠 (v0.16.1 → v0.16.2)

SemVer pre-1.0 patch bump: bugfix のみ。

### [Manager v0.16.1] - 2026-05-20

#### Changed (#200 — バックアップ履歴の「状態」列削除)

バックアップ履歴 grid (`BackupSectionPanel`) から「状態」列を削除。`failed` は起動時 `AutoCleanupFailedEntries` で DB + 物理ファイル両方が自動掃除され、`in_progress` は backup 実行中の数秒〜数十秒のみのため、grid を開いた時点で実質ほぼ全行「成功」になり情報量ゼロ (= 部員視点で「全部成功と書いてある列」のノイズ) だった。

- `ConfigureGrid` から `status` 列定義を削除、列構成は 開始日時 / 完了日時 / 実行PC / トリガ / サイズ / ファイルパス に
- `RefreshDisplay` から status 文字列 / tooltip / 背景色の cell 設定を撤去 + 未使用になった `nowUnix` 局所変数を削除
- 未使用化した 4 helper (`GetStatusDisplay` / `GetStatusTooltip` / `GetStatusBackColor` / `GetStatusSelectionBackColor`) を削除
- **不変**: `status` の DB 3 値 (success / failed / in_progress) + `RefreshDisplay` 冒頭の reconcile logic (= in_progress → success/failed 確定 / 実在チェック / failed auto-cleanup)。失敗通知は status bar (PR #196 G 系) で覆える
- issue #200 の (a) 列ごと削除案を採用 ((c) color chip 案より素直、「全件 OK」の緑 cue は失うが実運用ほぼ全行成功で情報損失なし)

#### Bump 根拠 (v0.16.0 → v0.16.1)

SemVer pre-1.0 patch bump: 機能追加でなく UI 冗長列の削除 (UX refinement)。SPEC §3.x 列定義更新で SPEC 側も v1.10.34 → v1.10.35。

### [Manager v0.16.0] - 2026-05-20

#### Added (#201 — 設定タブ editing model を「適用 / 元に戻す」式に改修)

設定タブのログ / バックアップ section を **immediate save (= control 変更ごとに即 DB 保存 + LAN 重複起動確認 dialog)** から **per-section「適用 / 元に戻す」式 (commit-on-Apply)** に改修。

**UI** (`SettingsSectionPanel.Designer.cs`):
- grpLog / grpBackup 各々の末尾に「適用」「元に戻す」ボタン + 「● 未保存の変更があります」マーカー (DarkOrange) を追加。初期状態はマーカー hidden + ボタン disabled。

**editing model** (`SettingsSectionPanel.cs`):
- **「dirty flag + UI-is-buffer」モデル**: 別 buffer dict を持たず、UI control 自身が pending 値を保持。control 変更は即 DB 保存せず `SetXxxSectionDirty(true)` で dirty flag + マーカー + ボタン enable。
- TextBox.Leave は直前 save 値と異なる時のみ dirty mark (= no-op Leave で未保存マーカーが誤点灯しない)。
- UI-internal interaction は即時維持 (DB write しない): 自動バックアップ checkbox の interval section enable/disable、間隔単位の hours↔display 換算 + Max 切替。
- **「適用」** (`ApplyLogSection` / `ApplyBackupSection`): validate (ログは絶対 path check) → `CheckBeforeWrite` **1 回** → DB flush → 副作用 (ログは `launcher_logs_root.json` 伝搬) → dirty clear。
- **「元に戻す」** (`RevertLogSection` / `RevertBackupSection`): 既存 `LoadLogSettings` / `LoadBackupSettings` を再利用して DB 値を再読込 (= DB write しないため CheckBeforeWrite 不要)。
- **未保存ガード** (`HasUnsavedChanges` / `PromptAndResolveUnsavedChanges` public API): tab 切替 / フォーム終了時に未保存があれば 3-button 確認 dialog (保存 / 破棄 / キャンセル)。「保存」は Apply を呼ぶ (= そこで CheckBeforeWrite)、「破棄」は Revert、「キャンセル」は留まる。

**MainForm hook** (`MainForm.cs`):
- `tabControl1.Deselecting` を新規 subscribe、`e.TabPage`(= 離脱するタブ)が設定タブの時のみ未保存判定 → user「キャンセル」で `e.Cancel=true` で切替中断 (= `Selecting` だと発火時点で SelectedTab が新タブに変わっており判定 timing が不安定なため `Deselecting` を採用、後述 Round 3 fix 参照)。
- `MainForm_FormClosing` 冒頭に未保存判定 → user「キャンセル」で `e.Cancel=true` で終了中断 (= 既存コメントが予期していた設計)。

#### Changed

- **CheckBeforeWrite (LAN 重複起動確認) の発火を「変更ごと (最大 7 回)」→「section 適用ごと 1 回」に集約**。検出範囲 (同 PC Launcher / 他 PC Manager・Launcher) は不変、発火タイミングのみ変更。同 PC の Manager 2 個目は従来通り起動時 Named Mutex で物理 block。
- 旧即時保存 method (`SaveLogsRootIfChanged` / `SaveBackupDestIfChanged` / `SaveBackupIntervalWithGuard` / `SaveBackupIntervalDirect`) を撤廃、Apply / Revert / dirty-mark handler に再構成。

#### Round 4 review fix (Medium-1 + Low-1 + Low-2)

- **Medium-1**: `MainForm_FormClosing` にも `ActiveControl = null` の focus 強制 commit を tab 切替経路 (`TabControl1_Deselecting`) と**対称**に配置。× ボタン close 時に active control の `Leave` が `FormClosing` より先に発火する保証は WinForms version / focus 状態依存のため、「設定 textbox / numeric を編集途中で × クリック」で dirty 未確定のまま未保存 warning が skip される脆い前提を消去 (= tab 経路で実機検証済の focus-未確定問題と同型を FormClosing でも事前に潰す)。
- **Low-1**: CHANGELOG / SPEC「Added」本文の tab 切替 event 名を shipped code に合わせ `tabControl1.Selecting` → `tabControl1.Deselecting` に訂正 (= Round 3 fix で切替えた最終 code と整合、Added 本文が drift していた catalog ↔ implementation 不一致を解消)。
- **Low-2**: `lblLogUnsaved` / `lblBackupUnsaved` に `Name` プロパティ設定を追加 (= 同時追加した btnApply / btnRevert 群と Designer 一貫性、VS Designer 再生成時の差分ノイズ予防)。

#### Round 3 review fix (実機 smoke test 指摘: tab 切替で警告出ない bug + dialog 文言冗長)

- **タブ切替で未保存警告が出ない bug 修正** (`MainForm` tab 切替 hook): 2 つの原因が重なっていた。(1) **`Selecting` event 発火時点で `SelectedTab` が既に新タブに変わっており**、`if (tabControl1.SelectedTab == tabSettings ...)` 判定が false になってガードブロック全体が skip されていた → `Selecting` から **`Deselecting`** に切替え、`e.TabPage`(= 離脱するタブ)が `tabSettings` か判定する timing 非依存の形に修正。(2) TextBox.Leave / NumericUpDown 入力確定は focus-leave 時発火だが tab 切替 event はそれより先に走るため dirty 未確定 → `this.ActiveControl = null` で focus を強制 commit してから `HasUnsavedChanges()` 判定。FormClosing はフォーム非アクティブ化で focus が先に抜けるため警告が出ていた非対称も併せて解消。
- **未保存確認 dialog を custom 3-button (保存 / 破棄 / キャンセル) 化** (`UnsavedSettingsDialog.cs` 新規): 標準 `MessageBox` は button label を「はい / いいえ / キャンセル」固定でしか出せず、本文で「はい=保存 / いいえ=破棄 / ...」と注記する冗長な文言になっていた。button に直接「保存」「破棄」「キャンセル」を表示する custom Form に置換 (= 既存 `ResetDatabaseConfirmForm` 等の custom dialog pattern と同様)。

#### Round 2 review fix (Medium-1 + Low-1 + Low-2 + Low-3)

- **Medium-1**: `MainForm_FormClosing` の未保存ガード新規コメント「subscription 順序に依存せず確実に最初に走る」が、ガード本体が `if (e.Cancel) return;` の **後**にある実態と矛盾していた drift を解消。コメントを「他 handler が既に e.Cancel=true なら skip、現状 FormClosing hook は本 handler のみなので最初に走るが、将来 cancel 判定 handler を先に subscribe したら skip される (= round 4 review L-3 の順序前提と同じ制約)」に訂正。
- **Low-1** (受容 + 明示): `PromptAndResolveUnsavedChanges` の「保存」分岐は両 section dirty 時に `ApplyLogSection` → `ApplyBackupSection` を順に呼ぶため CheckBeforeWrite が最大 2 連続 + 片側 Cancel で部分適用 (= ログ保存済 / バックアップ dirty 維持で留まる) になりうる。per-section 集約の一貫粒度として受容、本 CHANGELOG + SPEC §3.8.2 に期待値を明記。
- **Low-2**: `btnResetDatabase_Click` 冒頭に未保存ガード (`HasUnsavedChanges() && !PromptAndResolveUnsavedChanges()` で中止) を追加。DB リセットは completion 後に LoadLogSettings / LoadBackupSettings で設定 section を再ロードするため、未保存編集が無確認破棄される穴があった (= tab 切替 / フォーム終了にはガードがあるのにより破壊的なリセットだけ対象外だった整合性穴)。
- **Low-3**: `lblLogUnsaved` / `lblBackupUnsaved` の `AutoSize=true` + 明示 `Size` 併記を解消、明示 Size 行を削除 (= AutoSize 時は無視される + round 3 review L-1 で chkBackupAutoEnabled に適用した規約と一貫)。

#### Round 1 review fix (Medium-1 + Low-2 + Low-3)

- **Medium-1**: `Launcher/scripts/logger.gd:152` のコメントに旧 method 名 `SaveLogsRootIfChanged` が残置していた sweep 漏れ (= C# のみ Grep して `.gd` を漏らした) を `ApplyLogSection` に修正。`SPECIFICATION.md` v1.10.33 履歴 entry + 本 CHANGELOG v0.15.0 entry の同名参照は当時 (= PR #202 時点) の名前を記録した履歴のため残置。
- **Low-2**: `_logSectionDirty` / `_backupSectionDirty` の意味を「DB と差分あり」ではなく「user が control を touch 済」と field docstring で明示。numeric / checkbox / combo は値を DB 値に戻しても dirty 維持 (= TextBox 系のみ `_lastSaved*` 比較で no-op 除外、非対称) が commit-on-Apply の一般的許容挙動である旨を明文化、「元に戻す」で確実に脱出可能。
- **Low-3**: DB リセット完了直後に `LoadLogSettings` / `LoadBackupSettings` を呼んでログ / バックアップ section を新 DB (= default) 値に再ロード + dirty clear。commit-on-Apply モデルでは UI が pending buffer のため、再ロードしないとリセット後も UI が stale 値表示 + (dirty 状態だった場合) 次回「適用」で新規 DB に stale pending を書込む path があった。

#### Bump 根拠 (v0.15.0 → v0.16.0)

SemVer pre-1.0 minor bump: editing model の新機能追加 (= 適用 / 元に戻す + 未保存ガード)。SPEC §3.8.2 に commit-on-Apply 追記で SPEC 側も v1.10.33 → v1.10.34 を同 PR で bump。

### [Manager v0.15.0] - 2026-05-20

#### Added (#201 — Unified logs root path 設定)

設定タブ「ログ保存先」の semantic を **Manager-only** から **全 component (Manager / Launcher / Updater / 将来 Monitor) の unified parent root** に変更。設定 1 つで全 component のログを 1 つのフォルダにまとめて保存できるようになる。

**新 setting `logs_root_path`** (`Manager/Services/SettingsKeys.cs`):
- 空欄なら default `<install>/logs/`、絶対 path で指定すれば custom root
- 指定先には `manager/` `launcher/` `updater/` (将来 `monitor/`) の subdir が**各 component の Logger によって自動作成**される
- 旧 v0.14.0 の `log_destination_path` (Manager-only 直配置 semantic) は **auto-migrate で値を copy + DELETE**、旧 key は code から削除済 (= 1 semantic 維持)

**Manager → Launcher path 伝搬** (`Manager/Services/LauncherLogsRootBridge.cs` 新規):
- Manager は SQLite から読んだ `logs_root_path` 値を `<install>/responses/launcher_logs_root.json` に **atomic write** (= `<file>.tmp` → rename pattern、SessionHeartbeat と同 pattern)
- 書出 timing: (1) Program.Main の Logger.Initialize 直後 (= 毎起動時 sync)、(2) SettingsSectionPanel.SaveLogsRootIfChanged 内 (= UI 変更時即時 sync)
- Launcher Logger はこの JSON を autoload 最先頭 init 時 (= DB 接続前) に read して log dir を決定、SPEC §6.5「Launcher は SQLite write しない」原則を維持しつつ Manager 設定を反映 (= Launcher は file read のみで完結)

**Auto-migrate + 一回限り MessageBox** (`Manager/Program.cs:ReadInitialLogSettingsWithMigration` + `Manager/Program.cs:WriteLogsRootMigrationSentinel` + `Manager/MainForm.cs:TryShowLogsRootMigratedDialog`):
- v0.15.0 初回起動時に SQLite から旧 `log_destination_path` を読み、非空 + 新 `logs_root_path` 空なら value copy + 旧 key DELETE (= 1 transaction)
- 完了時に `<install>/.logs_root_migrated` sentinel file を atomic write、内容に migration 前の旧値を embed
- MainForm が sentinel 経由で部員向け subdir 構造説明 MessageBox を表示 + sentinel を削除 (= 次回起動以降は発火しない)
- 文言は「これまでの設定値はそのまま引き継がれましたが、フォルダ構造が `<old_path>\manager\` `<old_path>\launcher\` `<old_path>\updater\` に変わります」のように subdir 構造を絵で示す

**反映タイミング**:
| 対象 | 動作 |
|---|---|
| Manager | 次回 Manager 起動時 (= Logger.Initialize / PathManager.LogsRootDirectory / LogSectionPanel.Initialize が起動時 1 回 set のため) |
| Updater | 次回 Updater spawn 時 (= Manager が `--log-dir <PathManager.UpdaterLogDir>` を渡す、新 root 経由で computed) |
| Launcher | 次回 Launcher 起動時 (= Manager save 時に `launcher_logs_root.json` 即時 sync、Manager 再起動不要) |

**LAN 重複起動 check**: 既存 `SettingsSectionPanel` の immediate save + `CheckBeforeWrite` + rollback pattern を完全踏襲。本 PR では editing model (= immediate save vs commit-on-OK) 自体は変更しない、設定タブ editing model 全面書換えは別 issue (#201 内 note) で後続 PR にて着手予定。

#### Changed

- `Manager/Services/Logger.cs`: `Initialize(customLogDir)` の semantic 変更 (= 引数を「Manager log file 直配置 dir」から「親 logs root」に変更、内部で `manager/` subdir を append)。旧 v0.14.0 直配置 semantic は廃止。
- `Manager/PathManager.cs`: `LogsRootDirectory` getter + `SetLogsRootDirectory(customRoot)` setter (= 起動時 1 回 set) 追加。`UpdaterLogDir` を hardcode (`<install>/logs/updater/`) から `<LogsRootDirectory>/updater/` 派生に変更。`LauncherLogDir` / `ManagerLogDir` / `MonitorLogDir` 派生 getter も新規追加。
- `Manager/Controls/LogSectionPanel.cs`: `Initialize(projectRoot)` → `Initialize(logsRoot)` signature 変更 (= `Path.Combine(projectRoot, "logs")` の内部 append を削除、親 root 直接受取)。
- `Manager/Controls/SettingsSectionPanel.{cs,Designer.cs}`: UI label を unified semantic 用に書換え (note 文に「Manager / Launcher / Updater 全ての保存先」「反映: Manager は次回起動時 / Launcher は次回起動時」を明示)、`_settingsRepo` の get/set key を `LogDestinationPath` → `LogsRootPath` に変更、save 成功時に `LauncherLogsRootBridge.WriteCurrentLogsRoot` 呼出。
- `Manager/MainForm.cs`: `_logSectionPanel.Initialize(PathManager.BaseDirectory)` を `_logSectionPanel.Initialize(PathManager.LogsRootDirectory)` に変更。`TryShowUpdateCompletedDialog` の隣に `TryShowLogsRootMigratedDialog` 追加。
- `Manager/Program.cs`: `Logger.Initialize` 前に `ReadInitialLogSettingsWithMigration` (= migration check + read + sentinel 書出を 1 SQLite 接続で統合した関数、R2 review Medium #4) 呼出 + `PathManager.SetLogsRootDirectory` + `LauncherLogsRootBridge.WriteCurrentLogsRoot` 呼出を追加。SELECT key は `log_destination_path` (legacy) / `logs_root_path` (current) / `log_retention_days` を 1 query で取得。

#### Removed

- 旧 setting key `log_destination_path` は SettingsRepository の get/set callsite から削除 (= 1 semantic 維持)。`SettingsKeys.LogDestinationPath` const は migration code 内 reference のみで残置 (= deprecated marker、docstring で migration 完了後の参照禁止を明示)。

#### Round 6 review fix (Medium-1 + Low-1 + Low-2)

- **Medium-1**: R4 M-2 で `SaveLogDestIfChanged` → `SaveLogsRootIfChanged` に rename した際の sweep 漏れを解消。現在状態を説明する docstring / SPEC / CHANGELOG 本文に旧名 `SaveLogDestIfChanged` が残置 (`LauncherLogsRootBridge.cs` 3 箇所 + SPEC v1.10.33 entry + CHANGELOG bridge timing 行) し、特に `LauncherLogsRootBridge.cs:32` の「呼出箇所」が読者を実在しないメソッド名へ誘導する forward pointer だった。`SaveLogsRootIfChanged` に統一。CHANGELOG の Round 2 Low #8 履歴記述のみ「R2 当時の名前、R4 M-2 で rename」と注記して残置 (= 現在状態 vs 履歴の区別明示で過剰 sweep 回避)。
- **Low-1**: 絶対 path invariant の defense-in-depth を migration 経路に追加。旧 v0.14.0 UI の save 経路には IsPathRooted ガードが無かった (= 本 PR で新規追加) ため相対 path を持つ v0.14.0 install が存在しうる。migration で相対値をそのまま `logs_root_path` に copy すると「常に絶対 path」invariant が migration 経路だけ破れ Launcher が CWD 依存に倒れるため、`ReadInitialLogSettingsWithMigration` で legacyValue を `Path.IsPathRooted` 判定、相対なら value copy を skip + 旧 key DELETE のみ (= default 化、sentinel なし silent)。
- **Low-2**: Launcher reader (`_read_logs_root_from_responses`) に `is_absolute_path()` 検証を defense-in-depth で追加。Manager 側 enforce (SaveLogsRootIfChanged + migration) を抜けた相対値 (= 手動 file 編集 / 旧 install 残置) が bridge file に載る path に備え、絶対 path でなければ warn + default fallback (= 既存 `["", msg]` 経路に乗せ session log にも転送)。

#### Round 5 review fix (Medium-1 + Low-1 〜 Low-5)

- **Medium-1**: `PathManager.SetLogsRootDirectory` の早期 throw による silent crash regression を解消。customRoot 空時に `Path.Combine(BaseDirectory, "logs")` を eager 評価していたため、broken install (= Manager.exe を `<install>/Manager/` 外起動 → BaseDirectory lazy 解決が `DirectoryNotFoundException`) で本 setter が mutex try-catch 外で uncaught throw → friendly MessageBox なしの silent crash になっていた。customRoot 空時は field を set せず getter の lazy default に委ねる形に変更、後続 `VerifyPaths` (= mutex try-catch 内) が DirectoryNotFoundException を friendly「起動エラー」MessageBox で拾う pre-PR 経路を維持。
- **Low-1**: Launcher `_read_logs_root_from_responses` の bridge file 読込 warn が `push_warning` のみで Launcher session log に転送されない silent diagnostics loss を解消。warn は `_init_godot_log_tail` の baseline 記録前に発火するため godot.log baseline に飲まれて session log に来なかった。戻り値を `[path, warn_msg]` Array 化し、`_open_session_file` 完了後に `_initialize_logger` が `_write_safely("WARN", ...)` で session log に直書き (push_warning も保持で godot.log 冗長性も担保)。
- **Low-2**: `LogSectionPanel.btnOpenLogFolder_Click` docstring の stale な `<install>/logs/` 表現を unified semantic (`_logsRoot` = 現在の logs root、default または custom) に sync (R4 M-2 rename の sweep 漏れ)。
- **Low-3**: `btnLogBrowse_Click` / `btnBackupBrowse_Click` の `FolderBrowserDialog.SelectedPath` set を try-catch で囲み、textbox にゴミ値 (= 無効 path / 構文不正) が残る state で「参照...」押下時の `ArgumentException` crash path を予防 (= 失敗時は dialog を default location で開く)。
- **Low-4**: `SaveLogsRootIfChanged` に `Path.IsPathRooted` validation を追加。相対 path (`logs\custom`) / traverse (`..\elsewhere`) を textbox 直接入力された場合、Manager Logger は CWD 相対で `Directory.CreateDirectory`、Launcher は `path_join` で CWD 依存の予測不能 path に倒れるため、MessageBox + rollback で reject (= docstring「絶対 path」制約を code enforce)。
- **Low-5**: `LauncherLogsRootBridge` docstring に `schema_version` field の forward-compat 意図 (= 将来 v2 format break 時の Launcher 側 gating 用予約 field、現状 v1 固定で reader 未参照、gating guard は別 issue) を明文化。

#### Round 4 review fix (H-1 + H-2 + M-1 + M-2 + M-3 + M-4 + L-1 + L-2 + L-3 + L-4)

- **H-1**: SPEC §3.6「既知制約」fence を 3 経路 (Logger fallback + Manager 側 bridge file 書出 + Launcher 側 bridge file 読込) に拡張。dev 環境 (`.git` 直下起動) で bridge IPC が silent に Launcher に届かない path も明文化。
- **H-2**: `WriteCurrentLogsRoot` docstring に「multi-Manager race による transient mismatch」path を追記。LAN で複数 Manager が CheckBeforeWrite 通過後の interleave で bridge file 内容と SQLite 最新値が transient に食い違う、次回 Manager 起動の Program.Main で self-heal、Bridge を SQLite re-read 化は別 PR で検討。
- **M-1**: `EscapeJsonString` 2 callsite (`Program.cs` + `LauncherLogsRootBridge.cs`) の重複を `Services/JsonEscape.cs` (新 helper) に集約。将来 schema 拡張 (Unicode escape 等) で片方だけ更新する silent drift を予防。
- **M-2**: `SettingsSectionPanel` 内 control / field / method 名を `LogDest*` → `LogsRoot*` に rename (`txtLogsRoot` / `lblLogsRootHint` / `_lastSavedLogsRoot` / `SaveLogsRootIfChanged` / `TxtLogsRoot_Leave`)。UI hint / `SettingsKeys.LogsRootPath` / CHANGELOG が新 semantic に揃った状態で内部 control 名のみ旧 semantic 残置だった drift を解消、後続 #201 PR の editing model 全面書換え時の戻り作業を予防。
- **M-3**: csproj `<Compile>` 順序 alphabetical 違反訂正 (`Services\LauncherLogsRootBridge.cs` を `Services\ImagePreviewHelper.cs` と `Services\LauncherSessionService.cs` の間に移動 + `Services\JsonEscape.cs` も alphabetical 位置に追加)。
- **M-4**: `WriteLogsRootMigrationSentinel` docstring に「tx commit 成功 + sentinel 書出前 crash で dialog 永久不発火」path を fence。発生確率は μs オーダーだが silent failure path として明示、recovery 経路 (= sentinel pre-write pattern) は別 PR で検討。
- **L-1**: Program.Main コメント「SetLogsRootDirectory は immutable 保証 (= 2 回目以降 no-op)」を「2 回目以降は `InvalidOperationException` で fail-fast」に R2 M-5 throw 化と sync 訂正。
- **L-2**: `SettingsKeys.cs` 冒頭 docstring に「SQL literal 埋込制約: const 値は alphanumeric + underscore のみ許容」規約を明文化、`'` 含めると SQL 構文 break + injection hazard を予防。
- **L-3**: `WriteCurrentLogsRoot` docstring に「UI 経路の silent swallow」path を追記。`SaveLogsRootIfChanged` 経路で bridge write 失敗時、user は「保存成功」UI feedback 受けるが Launcher は次回 Manager 再起動まで新値を見ない self-heal 遅延、本 PR では受容 + UI dialog 通知強化は別 PR で検討。
- **L-4**: `TryShowLogsRootMigratedDialog` 内で `migratedFrom = migratedFrom.TrimEnd('\\', '/')` 正規化を追加。FolderBrowserDialog の `SelectedPath` 末尾 `\` 込み値で dialog 本文に `D:\logs\\` の `\\` 混在表示が出る cosmetic 問題を予防。

#### Round 3 review fix (Critical-1 + High-1 + High-2 + Medium-1 + Medium-2 + Medium-3 + Low-1 + Low-2) — 整合性 sweep

R2 round で fix した内容と矛盾する docstring / CHANGELOG / SPEC が他箇所に残っていた整合性問題を一括 sweep:

- **Critical-1**: MainForm.cs:953-954 の `TryShowLogsRootMigratedDialog` docstring が「sentinel JSON schema: `{"migrated_from", "migrated_at"}`」と snake_case で書かれていた R2 fix 漏れを camelCase (`migratedFrom` / `migratedAt`) に書換え。R2 review Critical #1 と完全に同 pattern の silent failure 再発 risk を予防。
- **High-1**: 廃止関数名 `TryAutoMigrateLegacyLogPath` (= R2 で `ReadInitialLogSettingsWithMigration` に統合済) が docstring / CHANGELOG / SPEC §10.x に 9 箇所残置していたのを sweep。sentinel writer は `WriteLogsRootMigrationSentinel` (= 統合 helper) として別関数名で参照。`Manager/MainForm.cs:217, 954, 1017` + `Manager/PathManager.cs:85` + `Manager/Services/Logger.cs:59` + `Manager/Services/SettingsKeys.cs:88` + `CHANGELOG.md:1694, 1716` + `SPECIFICATION.md:3309`。R2 Medium #4 fix の catalog ↔ call-site drift 解消。
- **High-2**: Logger.cs:212-227 (`FindProjectRootForLogs`) と PathManager.cs:248-353 (`FindBaseDirectory`) の project root resolution が `toneprism.db` 不在 case で divergence する pre-existing 問題を SPEC §3.6 「検出方法」記述に「既知制約」fence で明文化。健全 install では発火しない (= `toneprism.db` 存在) ため本 PR では受容、根本解消は別 PR で Logger 側 resolution を PathManager 経由に揃える要。本 PR で `LogSectionPanel.Initialize(PathManager.LogsRootDirectory)` に変更したため hidden divergence が visible 化したことを明示。
- **Medium-1 + Low-2**: migration dialog 本文に「Launcher / Updater の古いログは `<install>/logs/launcher/` / `<install>/logs/updater/` にあります (これまで Manager 設定とは別場所で管理されていたため)」を追記、v0.14.0 で `log_destination_path` を custom 設定していた user が「migratedFrom 配下を全部消せば clean」と誤読 + Launcher / Updater の旧 log を orphan 化させる path を文言レベルで予防。「古いログファイル」の表現も「古い Manager ログ」に specific 化。
- **Medium-2**: `LauncherLogsRootBridge.WriteCurrentLogsRoot` docstring の「実害なし」表現を「Launcher 1 セッション分が user 意図と異なる場所に書かれる、user 通知一切なし」と honest 化。LAN 50 PC 同時起動等の window 衝突 case を明示、`MoveFileEx(MOVEFILE_REPLACE_EXISTING)` P/Invoke 化を別 PR 候補として note。
- **Medium-3**: SettingsKeys.LogDestinationPath docstring の関数名 drift 訂正 (High-1 と一括) + 「廃止条件: 旧 v0.14.0 setting を持つ install が事実上全て v0.15.0+ に migration 済と見なせる段階で本 const + migration code を一括削除可能」を明示。
- **Low-1**: SPEC §3.6 移設例から `monitor/` 列挙を除外、UI hint label「manager/ launcher/ updater/ のフォルダが自動で作られます」と一致させて Manager v0.15.0 時点の user 体験を統一。Monitor component 実装 PR で再追加予定。

#### Round 2 review fix (Critical #1 + High #2 + High #3 + Medium #4 + Medium #5 + Medium #6 + Low #7 + Low #8 + Low #9)

- **Critical #1 + Medium #6**: migration sentinel JSON の wire format が snake_case (`migrated_from`) で書出されていたが、reader 側 DTO は PascalCase property (`MigratedFrom`) で `JavaScriptSerializer.Deserialize<T>` の case-insensitive match に underscore stripping が含まれないため `dto.MigratedFrom == null` → 早期 return で **migration dialog が永久不発火** する Critical bug。wire format を真の camelCase (`migratedFrom` / `migratedAt`) に修正、既存 `UpdateCompletedSentinel` と統一。DTO docstring の「camelCase」誤記も訂正。
- **High #2**: migration dialog 文言「30 日後に自動的に削除されます」が嘘 promise だった。`CleanupOldLogs` は新 subdir (`<root>/manager/`) のみ sweep するため、migration 元 dir 直下の旧 `manager_*.log` は永続残留。dialog 文言を「(不要であれば手動で削除してください)」に書換え。
- **High #3**: `LogSectionPanel` クラス header docstring が旧 hardcode path 表現 (`<project_root>/logs/manager/` と `<project_root>/logs/launcher/`) を残置していた。unified root semantic 反映で「`<PathManager.LogsRootDirectory>/<component>/` を ... scan」表現に書換え。
- **Medium #4**: round 3 review L-3 で確立した「1 起動 1 SQLite 接続」最適化を本 PR で 2 関数分離 (= `TryAutoMigrateLegacyLogPath` + `TryReadInitialLogSettings`) により毎起動 2 接続に退行させていた。両関数を `ReadInitialLogSettingsWithMigration` 1 関数 + 1 接続に統合、migration 完了後の通常 boot も SMB 共有 DB の latency 最適化を継承。
- **Medium #5**: `PathManager.LogsRootDirectory` getter の「set 前 fallback で field に書込む」設計が、setter 後行で呼ばれた case に silent ignore hazard を生んでいた。getter は default を return するだけで field に書込まない設計に変更 + setter は 2 回目以降 `InvalidOperationException` で discipline 厳格化 (= setter→getter 順序逆転 / 重複呼出を dev / test で発覚させる)。
- **Low #7**: `LauncherLogsRootBridge.WriteCurrentLogsRoot` docstring の「atomic write」表現を「near-atomic (Delete + Move pattern、reader 側は不在 / parse 失敗で default fallback の safe path のため許容)」に正確化。真の atomic 化は `MoveFileEx(MOVEFILE_REPLACE_EXISTING)` 要、別 PR で検討。
- **Low #8**: `SettingsSectionPanel.SaveLogDestIfChanged` (= R2 当時の名前、R4 M-2 で `SaveLogsRootIfChanged` に rename) 内の Logger メッセージ「Manager は次回起動時反映、Launcher は次回起動時反映」を「Manager は次回 Manager 起動時、Launcher は次回 Launcher 起動時に反映」に明確化 (= UI hint label の表現と同期、catalog ↔ call-site drift 解消)。
- **Low #9**: `SettingsKeys.LogDestinationPath` const が hardcoded SQL literal 経由で参照されない orphan 状態だった (= docstring「auto-migrate code 内でのみ参照」が嘘) を解消、`ReadInitialLogSettingsWithMigration` の SQL 構築を const concatenation に書換え、4 箇所 (SELECT key list / WHERE clause / DELETE / dual-set cleanup) で const を SoT 参照。

#### Also Changed: `responses/` directory layout 規約 (= β 化)

User レビューで「`responses/` 直下に `launcher_logs_root.json` (本 PR 新規 IPC file) を置くと、将来 SPEC §6.5 のプレイ記録取り込み logic (= 直下 sweep + `imported/` / `failed/` move) と誤認衝突する」hazard を発見、本 PR scope 内で SPEC §6.5 directory layout 規約を **β 化** (= 直下 vs subfolder の責務分離):

- **直下** = Manager ↔ Launcher の **system / IPC 用 file** 専用 (= `launcher_logs_root.json` 等の single-file write、取り込み logic の sweep 対象外)
- **subfolder (category 別)** = **data drop 用** (= プレイ記録は `responses/play_records/{,imported/,failed/}`、アンケートは `responses/surveys/{,imported/,failed/}`、各 subfolder 内が 3-state folder pattern)
- **SessionHeartbeat** (`responses/launcher_sessions/`) も「IPC 用 subfolder」として旧版の「例外」表現から一般化規約に乗る整理

プレイ記録 / アンケートの実装はまだ未着手 (= Launcher / Manager 両側で SQLite write / 取り込み logic はゼロ、SPEC で設計のみ) のため **code 変更ゼロ、SPEC §6.5 書換えのみで完結**。将来 plays/surveys 取り込み実装時に新 layout で着手される。

#### Bump 根拠 (v0.14.0 → v0.15.0)

SemVer pre-1.0 minor bump: 設定 semantic の breaking 変更 (= 旧 `log_destination_path` の Manager-only 直配置 → unified parent root) + 新機能 (Launcher への path 伝搬 / migration dialog) + SPEC §6.5 directory layout 規約 β 化。SPEC §3.6 + §6.5 書換えで SPEC 側も v1.10.32 → v1.10.33 を同 PR で bump。

### [Manager v0.14.0] - 2026-05-19

#### Added (#199 — Companions ログ管理 + ログビューア タブ式リファクタ)

**1. Updater log の Manager log への post-hoc filtered absorb** (`Manager/Services/UpdaterLogAbsorber.cs` 新規):

Manager 起動直後の `ContinueLoadAfterSessionCheck` (= 起動時 session conflict check の通過後) で 1 回呼出。`<install>/logs/updater/*.log` を scan、未 absorb な file から **`[ERROR]` / `[WARN]` 全件 + 主要 milestone marker 行** のみ抽出して Manager 自身の Logger 経由で Manager log に append。各行は `[Updater <original-ts>] <message>` prefix で由来 + 元 timestamp を明示。verbose な詳細行 (file copy / verify 等) は Updater 自身の file に隔離。

milestone marker pattern: `[Step N/M]` ヘッダ / `Manager spawn` 結果 / `Manager dir 置換完了` / `FATAL` / `Updater 起動` / `Updater 終了` / `Updater 全工程完了` / `Manager 起動完了` / `Manager プロセス終了確認` 等 (= success path INFO のみ、failure event は WARN/ERROR 経路で absorb される規約)。

設計判断 (SPEC §3.6 Companions ログ管理規約と同期):
- **絞り込み level**: Warn/Error は全件 (= 問題追跡の信号)、INFO は milestone marker pattern を含むもののみ (= Phase 境界 + 完了 marker)。普段の Manager log が Updater verbose で埋もれない balance。
- **重複 absorb 防止**: `<install>/logs/updater/.absorbed` text file (= 1 行 1 path) で管理。Manager 再起動で同 Updater log を 2 回 absorb しない。
- **部分 absorb 事故防止**: Updater Logger の Shutdown marker 「Updater 終了」行を含む file のみ absorb 対象、未含有なら次回 Manager 起動で再評価 (= Phase B/C 中の race で終端未達のまま mark 済になる事故を構造的に防止)。
- **dead path prune**: Updater Logger の 30 日 retention で消えた file path の `.absorbed` entry を best-effort 掃除、`.absorbed` の永続 growth を防止。
- **例外は内部で握り潰し**: Manager 起動を阻害しない (= SPEC §3.6「Logger 自身の障害は握り潰す」と同じ defensive 規約)。

**2. LogSectionPanel を tab 式 component selector に変更** (`Manager/Controls/LogSectionPanel.{cs,Designer.cs}`):

旧 `chkManager` / `chkLauncher` checkbox 式 component filter を **`TabControl` (Launcher / Manager の 2 tab)** に置換。tab 切替で grid に表示する component が切り替わる。default tab は Launcher (= 部員が普段 trouble shoot する対象が Launcher 側であろう想定、後で変更余地あり)。Monitor は SPEC では 3 component 収束方針の 1 つだが、Monitor 実装着手前なので tab UI には現段階で含めない (= 動かないボタンを表に出さない方針)、`FileNameRegex` のみ将来 readiness で `monitor` 含む。

設計判断:
- **3 component 収束方針**: Manager GUI で見える log source は Launcher / Manager / Monitor の 3 component に固定、Companion 用 tab は追加しない (= SPEC §3.6 Companions ログ管理規約)。Monitor tab は Monitor component 実装着手と同 PR で UI 追加予定。
- **checkbox 撤廃の妥当性**: 旧 checkbox 「両方 ON」状態は grid 上で Manager session と Launcher session の file 一覧を時刻順に並べていたが、log line レベルでの時系列 cross-correlate 機能は存在しなかった (= `RenderContent` は 1 file の内容のみ表示)。tab 式に切替えても失う UX なし、3 component 収束が UI 上に明示される利得のみ。
- **`HasAnyMatchingLine` / `UpdateRowGreyout` / `UpdateFileCountLabel` から component filter logic を削除** (= tab で既に絞込済)、code path 簡素化。

#### Changed

- `Manager/Controls/LogSectionPanel.Designer.cs`: `chkManager` / `chkLauncher` field 削除、`tabComponent` (TabControl) + `tabLauncher` / `tabManager` (TabPage、Monitor は未追加) field 追加。layout は `tabComponent` を最上端 (Dock=Top) に配置、既存 `toolStrip` + `splitContainer` は下に shift。
- `Manager/Controls/LogSectionPanel.cs`: `FileNameRegex` を `(?<component>manager|launcher|monitor)` に拡張 (= 将来 Monitor file が落ちてきた時に parse 可能、現状 file 不在で実害なし)、`_currentComponent` field + `tabComponent_SelectedIndexChanged` handler 追加、`ScanLogFiles(logsRoot)` を `ScanLogFiles(logsRoot, component)` に signature 変更。
- `Manager/MainForm.cs`: `MainForm_Load` の `TryShowUpdateCompletedDialog()` 直後に `Services.UpdaterLogAbsorber.AbsorbPendingLogs()` 呼出を追加。
- `Manager/TonePrism_Manager.csproj`: `Services\UpdaterLogAbsorber.cs` の `<Compile Include>` 追加。

#### Round 4 review fix (M-1 + M-2 + M-3 + L-1 + L-2)

- **「line-prefix 厳格化」表現 drift 解消** (R4 M-1): R3 で導入した「line-prefix 厳格化」「行頭 prefix 固定」表現が `content.IndexOf` の substring 検索実態と乖離していた drift を解消、「Logger 内部 prefix `[Logger]` 込みの specific phrase substring 一致」に整合化。実装は `content.IndexOf(UpdaterShutdownMarker, ...)` の substring 検索のままで、判定 string を `[Logger]` prefix 込みの unique phrase にすることで brittleness を抑える設計意図を表現修正。
- **`dbReady=false` / session conflict Cancel 両 skip path の明文化** (R4 M-2): MainForm.cs コメントで「dbReady=false (= DB 初期化 user 拒否 / 不存在) と session conflict Cancel の両 path で AbsorbPendingLogs が skip される、両 path とも次回 Manager 起動で `.absorbed` 未含有 entry として idempotent picked up」を明文化。CleanupOldLogs (= Program.Main 移設で全起動 path 必達) の設計とは要件が異なる (= absorb は idempotent + deferred OK の弱い保証で十分) こと、CleanupOldLogs と同型の Program.Main 移設は今回採用しない trade-off (= R3 M-2 の「`.absorbed` 競合 bound」設計を維持するため) を embed。
- **orphan 継続行 skip の trade-off documentation** (R4 M-3): SPEC §3.6「多行 entry 継続行サポート」項に「orphan 継続行 (= ファイル先頭からの異常 path / skip された非 milestone INFO 直後の継続行) は active entry なし state で見つかるため noise skip、健全 file は `[Logger] <Component> 起動` で必ず始まる契約のため通常運用では発火しない」を 1 文追記。実装変更なし、契約 documentation の完全性向上のみ。
- **コメント framing 訂正 (L-1 + L-2)**: `_currentComponent` field comment を「二重管理を避ける」から「Designer SoT 優先 + last resort fallback の二段防御」へ訂正 (= 実装が field default を残している現実と整合)。`LogFileEntry.Component` 値域コメントを「3 値の可能性」から「Monitor tab 追加までは事実上 2 値、Monitor は誤配置 file 対応の forward-compat」へ訂正 (= future reader の誤読 path を予防)。

#### Round 3 review fix (H-1 + M-1 + M-2 + M-3)

- **CHANGELOG catalog ↔ call-site drift 解消** (R3 H-1): 上の「Added」記述の milestone marker pattern 列挙から `rollback` を削除 + INFO success-path 限定規約注記を sync。R2 で MilestoneRegex から `rollback` を removal 済だが「Added」記述には残置していて同一 PR エントリ内で矛盾していた状態を解消。
- **Shutdown marker を Logger 内部 prefix 込み specific phrase 一致に厳格化** (R3 M-1): `UpdaterLogAbsorber` の Shutdown marker 検出を `"Updater 終了"` substring 一致から `"[Logger] Updater 終了"` (= Logger 内部 prefix 込みの specific phrase) **substring 一致**に変更、`UpdaterShutdownMarker` const として SoT 化。実装は `content.IndexOf(...)` の substring 検索のままで、判定 string を `[Logger]` prefix 込みの unique phrase に強化することで application code が偶然 error message 中に「Updater 終了」文字列を含めた時の誤発火 path を構造的閉鎖 (= 行頭 anchor までは要求していない、Logger 内部 prefix の uniqueness で十分という判断)。SPEC §3.6 に「Companion の Logger Shutdown 出力には `[Logger] <Component> 終了` を含めること」+「parent absorber は当該 substring の有無で判定」規約を新規明文化、将来 WindowProbe / PauseOverlay 等の parent absorber コピペ時の brittleness 継承も予防。
- **AbsorbPendingLogs 呼出位置を session conflict check 後に移設** (R3 M-2): `MainForm_Load` 早期 (= TryShowUpdateCompletedDialog 直後) から `ContinueLoadAfterSessionCheck` 内 (= session conflict 通過後) に移設。同一 PC 複数 Manager 同時起動時の `.absorbed` 競合 + Manager log file 間重複 absorb path を構造的 bound。session conflict Cancel path では absorb skip されるが、次回 Manager 起動で idempotent に picked up される設計なので timing 影響なし。
- **多行継続行の改行を `Environment.NewLine` に変更** (R3 M-3): `AbsorbContent` の継続行 accumulate `Append('\n')` を `Append(Environment.NewLine)` に変更。Manager Logger の WriteLine 出力 (= entry 間 CRLF on Windows) との line ending mixed (= entry 内 LF / entry 間 CRLF) 状態を解消、log を外部 tool に渡した時の brittleness を予防。

#### Round 2 review fix (H-1 + M-1 + M-2 + M-3 + L-3)

- **多行 ERROR 継続行 (stack trace) を absorb で保持** (`UpdaterLogAbsorber.AbsorbContent`): `Logger.Error(string, Exception)` が出力する exception stack trace は LineRegex (`[ts] [LEVEL]` ヘッダ) を持たない継続行になるため、旧実装は header 1 行目だけ拾って silent に欠落していた。header 行を検知したら直前の累積 entry を flush + 新 entry を開始、header 不一致行は active entry があれば payload に append する state machine pattern に書換え、改行込みの単一 entry として Manager Logger に書出。SPEC §3.6 に「多行 entry 継続行サポート」規約を追記。
- **crashed Updater の time-based fallback absorb** (`UpdaterLogAbsorber.AbsorbPendingLogs`): 「Updater 終了」marker 不在 file は通常「まだ書込中 race」として skip するが、`LastWriteTime` から 10 分以上経過していれば process 終了確定として absorb 対象に含める + `[CRASHED?]` summary marker + WARN level で notice する fallback path を追加。Updater が segfault / kill / OOM 等で abnormally terminate した case で永久 skip され続ける silent failure path を閉じる。SPEC §3.6 に「部分 absorb 事故防止 + crash fallback」規約を追記。
- **INFO milestone success-path 限定規約** + `rollback` alternation removal: SPEC §3.6 で「INFO レベルの milestone marker は success path のみ、failure は WARN/ERROR で出す」契約を明文化、MilestoneRegex から `rollback` alternation を removal (= 現状 Updater rollback はすべて WARN/ERROR で出ているため coverage 損失なし、anchor なし broad match の forward-compat false positive リスクを予防)。
- **`LineRegex` SoT 化** (`Manager/Services/LogLineFormat.cs` 新規): UpdaterLogAbsorber と LogSectionPanel の 2 callsite で hardcode 重複していた Logger format parse regex を共通 helper に抽出、将来 DEBUG level 追加等の format 拡張時の silent drift を予防。

#### Bump 根拠 (v0.13.1 → v0.14.0)

SemVer pre-1.0 minor bump: 新機能追加 (Companion log absorb + UI tab refactor)。SPEC §3.6 に新 subsection 追加で SPEC 側も v1.10.31 → v1.10.32 を同 PR で bump。

### [Manager v0.13.1] - 2026-05-19

#### Added (#170 followup — アップデート時の再起動予告 dialog)

「今すぐアップデート」flow の ProcessingDialog (= zip DL + staging + Updater spawn) 完了直後、
`Application.Exit` 呼出前に新 `MessageBox` を追加して **Manager 再起動を予告**:

> ダウンロードと展開が完了しました。
> OK を押すと Manager を一旦終了して、新しいバージョンで自動的に再起動します。
> 再起動には数秒〜数十秒かかる場合があります。
>
> 新しい Manager が起動したら、「✓ アップデート完了」のお知らせが表示されます。

旧実装 (= v0.13.0 以前) は ProcessingDialog 閉じた直後に Manager が silent に消える挙動で、
user 視点で「あれ?何が起きた?」になりやすかった。本 dialog で「これから一旦終了 → 自動再起動」を
明示してから user の OK で確定終了する flow に変更、再起動完了後の sentinel 経由
「✓ アップデート完了」 dialog (= Bundle v0.4.0 から存在) と組み合わせて開始 → 終了 → 完了の
**3 段階通知** を user に提供。

#### Changed (#170 followup — Updater spawn 時の空 console window を hidden 化 + wait-timeout 無制限化)

`UpdaterClient.cs` の `CreateNoWindow` を `false` → `true` に変更 + `--wait-timeout 0` (= 無制限待機)
を明示渡しに追加。

旧設計は「Updater console を visible にして user 安心感 + 進捗 visible」だったが、実態は
`RedirectStandardOutput=true` で stdout/stderr が Manager の pipe に吸われて
**visible console が常に empty** (= 黒い空 box が表示されるだけで「ウイルスかな?」「強制終了したい」
UX 悪化の温床) だった。「visible 設定だが output は redirect されて見えない」という矛盾した状態を fix。

Updater output の trace 経路:
- (a) `<install>/logs/updater/updater_<PC>_<datetime>.log` (= Updater 自身の file log、**完全な全行ログ、SoT**)
- (b) Manager log 経由 `[Updater stdout/stderr] ...` (= Manager process が生きている間だけ redirect 取込み、Manager 死亡後の Updater output は届かない)

visible console を消しても trace 情報は (a) で完全に残るため、本変更による情報損失なし。

##### `--wait-timeout 0` の根拠
Updater の Manager 終了待ち timeout を **default 60s → 0 (= 無制限)** に明示拡張。
旧 default だと UpdateSectionPanel の再起動予告 dialog (Application.Exit 前) で user が OK を遅延 click
した場合 + defer 化された CHANGELOG / .bak cleanup の SMB latency で Updater が exit 3
(`TimedOutNoForceKill`) を返して abort → 次回 Manager 起動時に「Manager が時間内に閉じませんでした」
失敗 banner が出る race があった。

無制限を採用した根拠: Manager UI freeze (= WebBrowser / SQLite latency / WindowProc 応答不能 等) で
永久 polling し続ける zombie Updater リスクはあるが、Windows user 常識として「ソフトが固まったら
task manager で kill」が確立しており、自動 abort で謎の失敗 banner を出すより、user 自身が手動 recovery
する path のほうが clean。学校 LAN 運用でも来場スタッフ / 顧問が task manager 操作可能な前提で OK。

bump 判断: UI artefact のみの変更 (= 再起動予告 dialog 1 つ追加 + Updater spawn の `CreateNoWindow`
値変更 + `--wait-timeout 0` 渡し追加)。Updater logic / file ops / restart 流れの core path は無変更、
SemVer 上 patch (v0.13.0 → v0.13.1)。「core path 無変更」の意味は **file 置換 / 再起動 / sentinel 処理
等の不変式に変更なし** であって、UI / process spawn の observable behavior には変化あり (= 旧版から
update した user は「黒い console window がなくなる」「再起動予告 dialog が増える」を体験する)。

### [Manager v0.13.0] - 2026-05-19

#### Changed (#170 followup round 2 — review 指摘対応)

- **アップデートタブのリリースノートを local CHANGELOG.md 優先 fallback に変更**: 旧実装は `cache.Latest.Body` を直接「現在実行中: vX.Y.Z」notes として render していたが、cache stale (= current > cache.Latest) のケースで「user は v0.5.0 を実行中なのに、UI は v0.4.0 の release notes を『現在実行中』として表示」する誤誘導があった。新実装は `ChangelogParser.TryReadLatestFromFile(PathManager.BundleChangelogPath)` で local CHANGELOG.md (= bundle 同梱、Release Tooling v0.1.16 以降の SoT) を先読みし、parse 成功時は **local の `### [Bundle vX.Y.Z]` body** を「現在実行中」notes として表示。fallback chain: 1) local CHANGELOG → 2) cache.Latest.Body → 3) 「リリースノートはありません」。ApplyResult の catch block は維持 (= local read 失敗時は warn log + fallback 続行)。
- **自動バックアップを ON/OFF できる checkbox を新規追加**: `chkBackupAutoEnabled` を grpBackup 内に配置、`SettingsKeys.BackupAutoEnabled = "backup_auto_enabled"` (default "true") で永続化。OFF にすると `BackupService.IsAutoBackupDue` / `RunAutoBackupIfDue` が起動時 trigger を完全 skip (= 手動バックアップは引き続き使える)。checkbox に従って interval section の controls (lblBackupInterval / numBackupInterval / cmbBackupIntervalUnit / lblBackupIntervalUnit) を `Enabled` で連動 enable/disable、OFF 時は灰色化して「無効」状態を視覚化。保存先 / 保持世代数は手動バックアップでも使うため対象外で常時有効。
- **設定タブの grpBackup と grpLog の順序を入替**: 旧 round 1 で「ログ (top) → バックアップ」だったが、user 提案で「バックアップ (top) → ログ」に変更。バックアップが日常運用で頻度高い設定であることを反映。

#### Changed (#170 followup round 1 — review 指摘対応)

PR #196 round 1 review で指摘された UI 改善:
- **バックアップタブの「設定...」ボタン削除**: 旧 modal Form 廃止後の info dialog 案内も完全削除、動線を「設定タブ」一本に絞る。
- **設定タブの section 順を再構成**: ログ (top) → バックアップ → データベース → バージョン情報 (bottom) の **使用頻度 / destructive 度** 順に並べ替え (= 旧 DB リセットがトップに来ていた配置の修正)。
- **データベースリセット button を赤色化** (= IndianRed BG + White FG + Bold)、[btnRestore](Manager/Controls/BackupSectionPanel.Designer.cs) と同 destructive pattern で統一。誤押下リスク低減。
- **ログ保存先 path 設定を新規追加**: `SettingsKeys.LogDestinationPath = "log_destination_path"` 新設、`Logger.Initialize(string customLogDir = null)` に signature 変更、Program.Main が SQLite 直接 read で先取得して渡す。設定 UI は `grpLog` 内に txtLogDest + btnLogBrowse + hint で追加、空欄なら default の `<install>/logs/manager/` を使用。**反映は次回 Manager 起動時** (= UI ラベルで明示)。
- **バックアップ自動間隔の表示単位 ComboBox 追加**: 「時間」/「日」を選択可能、`SettingsKeys.BackupAutoIntervalUnit` 新 key で永続化。DB 側 `backup_auto_interval_hours` は **常に時間単位**で BackupService 既存実装と互換 (= UI 表示時のみ unit 換算)、unit 切替時は表示値を換算して update + clamp。
- **バックアップ設定の保存ボタン廃止 + per-control immediate save**: 旧 btnBackupSave (旧 modal の OK pattern) を廃止、ログ retention と同 pattern (= 1 control 変更 = 即 save) に統一。txtBackupDest は Leave event + btnBackupBrowse 経由で save、各 NumericUpDown / ComboBox は値変更 event で save。CheckBeforeWrite は変更ごとに発火、Cancel 時は前回 save 値に rollback。

#### Added (#170 followup — UI brushup PR)

Bundle v0.5.0 受入テストで見つかった UX / safety 課題 5 件をまとめた brushup。**5 commit 構成** で、各 commit は項目別の独立変更:

- **ログ保存日数を 設定タブから設定可能に**: 旧 `Logger.cs:RetentionDays = 30` hardcode を `settings` table の `log_retention_days` 経由に移行、新 `grpLog` group box (NumericUpDown 1-365 日、default 30) を設定タブに追加。変更は次回 Manager 起動時に反映 (= UI label で明示)。`CleanupOldLogs` は `public static void CleanupOldLogs(int retentionDays)` に signature 変更、**`Program.Main` が `Logger.Initialize` 直後に SQLite 直接 read 経由 (`TryReadLogRetentionDays`) で呼出** (= round 1 で MainForm の `ContinueLoadAfterSessionCheck` 経路にしていたが、dbReady=false / SessionConflictDialog Cancel 等の early-return path で到達不能になる regression を round 3 H-1 fix で再移動)。Logger は依然 SettingsRepository に依存しない invariant 維持。
- **バックアップ設定を設定タブに inline 統合**: 旧 modal Form `BackupSettingsForm` を廃止、新 `grpBackup` group box (チェックボックス + 5 control [path/browse、interval、unit ComboBox、retention] の per-control immediate save) を設定タブに inline 統合。BackupSettingsForm.cs / .Designer.cs / csproj 該当行を削除。バックアップタブ「設定」ボタンは round 1 で完全削除 (= 動線を「設定タブ」一本に絞る)。**Per-control immediate save** = 各 control の `Leave` / `ValueChanged` / `SelectedIndexChanged` / `CheckedChanged` で個別 CheckBeforeWrite → save、Cancel 時 rollback (= round 1 で旧 modal の「保存ボタン経由 3 値一括 commit」設計から方針転換、ログ retention と pattern 統一)。
- **status bar を 2 ラベル分割 + 自動消去 timer**: 旧実装は `lblStatus` 1 ラベルで自動バックアップ message が「ゲーム数: N 件」を上書きして元情報一時消失。新 layout は左 zone (lblStatus = DB + ゲーム数 永続、AutoSize=true) + 右 zone (lblBackupStatus = transient backup 状態、**`Alignment=Right + AutoSize=true`**)。`UpdateBackupStatus(message, color, autoRevert)` 関数新設、autoRevert=true で 7 秒 Timer 自動消去。完了 ✓ 緑 / 失敗 ✗ 赤の color + text prefix (accessibility 補強)。設計経緯は round 2 Changed で詳述: 初版の Spring spacer 方式は WinForms layout の broken path で右端外に hidden する症状あり、round 2 で WinForms 本来の `Alignment=Right` 標準 pattern に切替。

#### Fixed (#170 followup)

- **アップデートタブ cache stale バグの defense-in-depth 修正**: Bundle v0.5.0 受入テストで「GitHub API rate limit hit 時に **既に適用済の v0.4.0 release** を『これから適用される変更』と誤表示する」バグ発見。2 layer で修正:
  1. UpdateChecker 側 (`Services/UpdateChecker.cs`): cache hydrate 3 経路 (`CheckAsync` / `LoadCacheOnly` / `CheckFromApiAsync` failure path) で `FilterStaleFromCumulative(cumulative, current)` 新 helper を呼出、`release.Version > current` の release のみ残す
  2. UpdateSectionPanel 側 (`Controls/UpdateSectionPanel.cs:ApplyResult`): 「これから適用される変更」見出しの表示条件に `Status == UpdateAvailable || Status == Skipped` を追加、UpToDate / 各種 error 時は CumulativeReleases が残っていても UI で表示しない fallback
  - あわせて cache 経由情報の disclaimer 強化: `FromCache && LastError != null` 時に「最新バージョン」欄に `(キャッシュ)` suffix + 灰色化、`UpToDate` status message を「最新版を実行中 (キャッシュ比較、再確認失敗中)」+ DimGray に降格 (緑文字「最新版を実行中です。」断言を回避)
- **Update check 系の DB write race fence を `btnSkip_Click` に追加**: `Controls/UpdateSectionPanel.cs:btnSkip_Click` で `_updateChecker.Skip(...)` 直前に `SessionConflictHelper.CheckBeforeWrite(this, "アップデートスキップ")` 追加 (= BackupSettingsForm.btnOk_Click と同 pattern の 1 段目 fence)。`StartBackgroundUpdateCheckIfDue:checker.MarkNotified(...)` への追加は意図的に skip (= background thread + auto side-effect + 非破壊性 / BackupService `last_backup_at` 自動書込の precedent と整合)、該当箇所に 12 行コメントで理由文書化。

#### Changed (#170 followup)

- `Services/Logger.cs`: `private const int RetentionDays = 30` 削除、`CleanupOldLogs` を public + parametrized 化。`Logger.Initialize` から `CleanupOldLogs` 呼出を削除 (= Logger は SettingsRepository 依存ゼロを維持、DB 初期化前に動く invariant 保持)。
- `Services/SettingsKeys.cs`: 新 const `LogRetentionDays = "log_retention_days"` + `DefaultLogRetentionDays = 30`。
- `Controls/SettingsSectionPanel`: GroupBox 4 件構成 (grpBackup / grpLog / grpDatabase / grpInfo の round 2 reorder 後) に拡張、Panel Size 500 → 830、AutoScroll=true。
- `Controls/BackupSectionPanel.cs:btnSettings_Click`: modal Form 開く処理 → info dialog に置換。
- `MainForm.cs:UpdateStatusBar`: signature を `(string additionalInfo = null)` → 引数なし `()` に簡略化 (= 右 zone 上書き path を排除)。新 `UpdateBackupStatus` で右 zone 専用 API 提供。
- `Manager/TonePrism_Manager.csproj`: `<Compile Include="BackupSettingsForm.*">` 2 行削除。

bump 判断: 新機能追加 (UI / API signature 変更) を含むため SemVer minor (0.12.1 → 0.13.0)。pre-1.0 minor bump 規約 (AGENTS.md) と整合。配布物 layout / DB schema / 既存 user data は無変更、user data migration 不要。

### [Manager v0.12.1] - 2026-05-19

#### Changed (#170 — copyright metadata sync + 設定タブ UI 追加)

- **PE metadata sync**: `Properties/AssemblyInfo.cs:13` の `AssemblyCopyright` を `Copyright ©  2025` (著者名なし、年単独) → `Copyright © 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)` に書換、`LICENSE:3` / `README.md:96` と同期。`TonePrism_Manager.exe` を右クリック → プロパティ → 詳細の Copyright 表示が LICENSE と整合するようになる。
- **設定タブ「バージョン情報」UI に copyright + license 行を追加** (`Controls/SettingsSectionPanel.cs:UpdateVersionInfo`): 既存の「製品名 / バージョン / データベース構造」3 行に加えて、`Assembly.GetCustomAttribute<AssemblyCopyrightAttribute>()` で **AssemblyCopyright を Reflection 取得** (= SoT は `AssemblyInfo.cs:13` 1 か所のみ、UI 側に literal を直書きしないので drift 防止) して「Copyright © ... TonePrism Project — Lead maintainer: ...」+「ライセンス: MIT License」を追加表示。来場スタッフ / 顧問が runtime で copyright を目視確認できる経路を確保 (= LICENSE / README / exe properties に続く 4 経路目の surface)。
- **折返しは WinForms の word-wrap に委任** (round 2 review M-2 対応): 初版 `string.Replace(" (Osaka Prefectural", "\n  (Osaka Prefectural")` で school suffix 直前に手動 soft break を挿入していたが、これは AssemblyInfo の中身に対する第二の coupling (= 将来 AssemblyInfo を改変 [学校名 rename / 学校 attribution 削除 / 日本語表記] したら silent no-op で 1 行表示に戻る、HiDPI / font scaling 環境で grpInfo 幅超過リスク) で「SoT 1 か所主張」と矛盾。round 2 fix で **`lblVersionInfo.MaximumSize = new Size(grpInfo.ClientSize.Width - 40, 0)` + 既存 `AutoSize=true`** に切替、`Replace` 自体を削除。WinForms が word 境界で自動折返し + Label 高さを自動拡張、AssemblyInfo の文字列内容に対する coupling が消滅して真の意味で drift 防止が成立。
- **`Controls/SettingsSectionPanel.Designer.cs`**: 追加行 + word-wrap 行数の余裕を確保するため `grpInfo` Size 高さを `120` → `200` に拡張 (= width 760 維持)。
- **`SettingsSectionPanel.cs:catch` に `Logger.Warn` 追加** (round 2 review L-4 対応): 既存 try/catch が silent fail だったため、AGENTS.md Cross-component Standards「新規実装は `Logger.Warn/Error` 直接使用」規約に従って `catch (Exception ex)` 形に変更 + `Logger.Warn` で version + copyright 取得失敗の例外詳細を出力 (= 将来 Reflection / DB 取得失敗時の debug 容易化)。

書式判断は `## Companions Updater v0.2.1` entry 参照、3 component で同じ表記に統一。

bump 判断: AssemblyInfo metadata 変更 + 設定タブ UI 追加は SemVer 上 patch (0.12.0 → 0.12.1)。表示行 1 セクション追加のみで behavior 影響なし (= DB / API / build 出力 layout 無変更)、build 出力の PE metadata と Settings UI 表示だけが変わる。同様の sync 動機は `## Launcher v0.6.1` / `## Companions Updater v0.2.1` も同時 bump、cross-cutting copyright 統一として 3 component 同期。

### [Manager v0.12.0] - 2026-05-19

#### Changed (#168 — 完全 rename + 配布対象拡張、破壊的変更)

プロジェクト brand を `GCTonePrism` / `ゲームセンターTONE Prism` から **`TonePrism`** に統一、他の学校・団体への配布も視野に入れた汎用化 rename。exe filename / DB filename / repo URL / namespace / UI 文字列 / README まで完全 rename、auto-update 互換性は意図的に放棄してハード切替 transition を採用 (= 既存 install は手動で `TonePrism_v0.5.0.zip` 解凍 + Install.bat 再実行が必要)。

bump 判断: exe filename / DB filename / namespace / repo URL 等の breaking change を含むが、SemVer pre-1.0 (= 0.x.y) 原則「Major version zero (0.y.z) is for initial development. Anything MAY change at any time」に乗って **minor bump (0.11.0 → 0.12.0)** で対応。1.0.0 への bump は「API 安定保証 + 配布実績」の milestone として後の release に温存、本 PR は brand 統一 + 配布可能化への準備として位置付け。AGENTS.md Bundle bump ルール「Major = breaking change」は 1.x+ 想定の規約で、0.x 域では minor bump が SemVer 上 OK (= user への warning 強度は CHANGELOG / release notes の文言で確保)。SPEC §1 / §2.4 / §7.3 等の本文 literal も全件 sweep、過去 history (= CHANGELOG 過去 entry / SPEC §10.x 変更履歴 row) は事実として残置 (= git blame / commit 整合保持)。

- **exe filename rename**: `GCTonePrism_Manager.exe` → `TonePrism_Manager.exe`、csproj `AssemblyName` / `RootNamespace` 同期。`Manager/GCTonePrism_Manager.csproj` → `Manager/TonePrism_Manager.csproj` (= `git mv`)、`Manager/GCTonePrism_Manager.slnx` → `Manager/TonePrism_Manager.slnx` 同様
- **C# namespace 全件 rename**: `namespace GCTonePrism.Manager` / `using GCTonePrism.Manager.*` → `TonePrism.Manager` / `TonePrism.Manager.*` を 98 .cs file で 207 occurrence sweep
- **AssemblyInfo.cs metadata update**: `AssemblyTitle("GCTonePrism_Manager")` / `AssemblyProduct("GCTonePrism_Manager")` → `TonePrism_Manager` (+ `AssemblyVersion` 0.11.0.0 → 0.12.0.0)
- **DB filename rename**: `prism.db` → `toneprism.db` 全件 (= `PathManager.cs` / `SchemaManager.cs` / `DatabaseManager.cs` / `BackupService.cs` / `Logger.cs` 等 17 source file + .gitignore + templates/Install.bat + ERROR_CODES_MANUAL.txt + SPEC body)
- **旧版 install detect guard 追加** (`MainForm.cs` MainForm_Load 冒頭): `prism.db` 残置 + `toneprism.db` 不在 = 旧版 install 痕跡として検出、警告 MessageBox + 即時 `Environment.Exit(1)` で process kill。user が誤って NEW zip を旧 dir に上書き展開した時の fail-safe (= 旧 DB と新 schema の混在で不整合 path を物理閉鎖)。**round 1 review fix (M-2)**: 初版 `Application.Exit()` だと WinForms message loop が queued message 消化してから停止する設計のため Form Show 等の race window 残存、`Environment.Exit(1)` で process 即時 kill に変更。**round 1 review fix (M-3 + L-2)**: 設計意図 (= 一過性、再利用前提なし) と dev 環境 priority-2 経路 false-positive 可能性 (= 開発者が repo root に `prism.db` test artifact 残置時) を guard 上のコメントに明示
- **GitHub repo URL rename**: `GitHubReleaseChecker.cs` `Owner` / `Repo` const + `Release.ps1` `$GitHubRepoSlug` + CHANGELOG 内の URL literal 全件 (= 過去 entry 本文中の inline markdown link + 末尾 reference def block 両方) `ken1208git/GCTonePrism` → `ken1208git/TonePrism`。GitHub 自動 redirect で過去 release tag / issue / PR link も継続動作。**round 1 review fix (H-2 + L-4) + round 2 review fix (M-1)**: 「inline body retain」と「URL literal forward update」の境界を明示する形に policy 整理。round 1 では「link def block (= 末尾 reference def) のみ forward update 許容」と書いたが、過去 entry 本文中の inline URL も実装上は forward update 済 (= sed sweep が footer / inline 区別なく走った) で policy ↔ implementation 矛盾、round 2 で「URL literal は inline / footer / table cell どこに居ても forward update OK、non-URL literal (brand 名 / DB filename / 開発元名等) のみ retain」と policy 緩めて整合。SPEC §10.x v1.10.30 row + 本 entry で 2 dimension (literal の content 軸 + 配置 location 軸) を切り分け明示
- **UI 文字列 rewrite**: `MainForm.Designer.cs` title `ゲームセンターTONE Prism 管理ソフト` → `TonePrism 管理ソフト`
- **`UpdateDownloader.cs` legacy validation list 同期**: `ValidateStagingLegacy` (L369-381) の hardcoded filename list を `GCTonePrism_*.exe` → `TonePrism_*.exe` 全件 update。**round 1 review fix (M-1)**: 初版 entry は「OLD Manager v0.11.0 が NEW zip を auto-apply 時に本 validation 失敗で abort」と誤記述、実態は **2 段構成 block**: (1) NEW Manager 起動直後の `MainForm.MainForm_Load` 旧版 detect guard が主 block、(2) OLD → NEW transition で OLD Manager の hardcoded Updater path mismatch が副次 block、`ValidateStagingViaManifest` (v0.3.1 / Manager v0.9.1 以降) は manifest 経由 forward-compat で吸収するため `ValidateStagingLegacy` は単独 block path ではない。詳細 SPEC §10.x v1.10.30 row 参照
- **round 1 review fix (H-1)**: `templates/Install.bat` の v0.2.0 → v0.3.0+ migration block (= 旧 dir `GCTonePrism_Manager/` → `Manager/` rename 処理) で初版 brand sweep が dir 名 historical reference まで `TonePrism_*` に over-rewrite していた問題を revert、v0.2.0 当時の subdir 名は **史実通り `GCTonePrism_*`** に巻き戻し (`.exe` filename は現行 `TonePrism_*` で維持、tasklist の `TonePrism_Manager.exe` check 等)。SPEC §2.4 旧仕様との差分段落 + §10 milestone 1 達成項目の同種 historical reference も `GCTonePrism_*` で revert
- **round 1 review fix (L-3)**: `Companions/Updater/Properties/AssemblyInfo.cs` の「通常 release 跨ぎで変更しない (SPEC §3.7.4)」コメントに「ただし brand rename / cross-cutting sweep 等で全 component sync update が必要な場合は同期 bump する」を 1 行追記、本 PR の 0.1.0 → 0.2.0 bump の判断 trail を明確化
- **round 3 review fix (M-1)** backup filename prefix sweep: `BackupService.cs` の `prism_{DateTime:yyyyMMdd_HHmmss}.db` 生成 + `prism_*.db` glob 列挙 (= 3 callsite) + `BackupLogRepository.cs` の regex `^prism_(\d{8})_(\d{6})\.db$` + `prism_*.db` glob (= 2 callsite) + SPEC §3 機能 12 ファイル名規則を **全件 `toneprism_` prefix に sweep**。初版 sweep で `prism.db` (DB 本体) だけ移行して backup filename prefix を miss していた silent drift を解消。ハード切替 transition 前提で「旧 backup file は新 install dir に carry-over されない (= fresh install から新 prefix で生成開始)」の方針、既存 `prism_*.db` を carry-over したい user は手動 rename
- **round 3 review fix (M-2)** `ValidateStagingLegacy` docstring 整合化: 関数名「Legacy」は v0.3.0 旧構造 zip 用を意図した命名だったが、本 PR で hardcoded list を `TonePrism_*.exe` に sync 更新したため **純粋な v0.3.0 zip には match しない** state になった。docstring に「manifest 不在時の hardcoded fallback、本 PR 以降の install は manifest 必須なので fallback path は NEW + NEW 経路のみ、純粋 v0.3.0 zip apply は MainForm guard で別途 block」を明記、関数名 rename は別 PR 余地
- **round 3 review fix (M-3)** `Install.bat:448` comment path 例の history 整合: 初版 sweep で `%~dp0TonePrism\GCTonePrism_Launcher\...` という mixed-history path 例が生成されていた (= 親 dir 名側だけ over-rewrite、`_Launcher` 側を round 1 で revert した結果の中途半端な状態)。v0.2.0 当時の純粋 path `%~dp0GCTonePrism\GCTonePrism_Launcher\...` に修正
- **round 3 review fix (L-1)** `.gitignore` の transition note を bump-agnostic 表現に: `(v1.0.0)` → `(Bundle v0.5.0 brand rename)` で commit `f41fb2b` の honest pre-1.0 minor bump 同期漏れ sweep
- **round 3 review fix (L-2)** `PathManager.EnumerateZombieStagings` に旧 prefix glob を追加: `TonePrism_update_*` のみ列挙だった zombie cleanup を `+ GCTonePrism_update_*` に拡張、`%TEMP%` 直下に残った旧版 Manager 由来の zombie staging を回収可能化。`v0.13 以降は GCTonePrism_update_* glob 削除候補` を docstring に注記、transition 専用 defensive cleanup の trail を残す
- **round 3 review fix (L-3)** `Launcher/scripts/path_manager.gd` の `parent_path.ends_with("TonePrism")` を `parent_path.get_file() == "TonePrism"` に exact match 化: 旧 suffix match では `GCTonePrism` (= 旧 brand 期の workspace dir 名) も hit する副次効果があった (= 後方互換的に動作はしたが意図外)、exact match で意図明確化。`project_root.ends_with("Launcher")` 側の substring match collision 修正は issue #151 scope で将来実施

### [Manager v0.11.0] - 2026-05-18

#### Added (#179 PR3b — Launcher LAN-wide session tracking + dialog 統合)

学校 LAN 上で Manager 編集中に Launcher が SQLite read で file lock 競合する path を物理閉鎖。PR #184 (v0.10.0) で **Manager 間** の同時起動検出は完成済だったが、**Manager と Launcher** の競合は依然人間頼りだった drift を、SPEC §6.5 「Launcher は SQLite に直接 write しない」原則を遵守した JSON drop folder 方式で解消。詳細仕様は SPEC §3.8.7 / §6.5 例外注記 / 変更履歴 v1.10.28 参照。

- **`LauncherSessionService` 新規追加** (`Manager/Services/LauncherSessionService.cs`): `<install>/responses/launcher_sessions/<pc_name>.json` を on-demand polling で読込、stale (= 30 秒) を除外した active Launcher session list を返す polling-only service。`ManagerSessionService` (DB-based) と非対称、**SQLite write ゼロ + DB table 化なし + in-memory cache のみ + 周期 polling Timer なし** で完結。directory 不在時の自動作成 + JSON parse 失敗時 individual file skip + SMB 一時不到達時 空 list 返却で fail-soft、`Initialize` / `IsInitialized` / `Shutdown` / `DetectActiveLauncherSessions` の 4 method (= `ManagerSessionService` と対称 API)
- **`LauncherSessionInfo` DTO** (`Manager/Models/LauncherSessionInfo.cs`): `PcName` / `StartedAtUnixMs` / `LastHeartbeatAtUnixMs` / `Pid` / `LauncherVersion` の 5 property + `SecondsSinceLastHeartbeat(nowMs)` helper (= `ManagerSessionInfo` と対称)
- **stale 判定 baseline 2 段 logic**: JSON 内 `last_heartbeat_at_unix_ms` primary + file mtime secondary fallback。SMB directory cache (~10 秒、SPEC §6.5) 由来の mtime drift を JSON content で補正、JSON parse 成功だが field 欠落時は file mtime で stale 判定 + `LauncherVersion = "(version 不明)"` fallback で表示
- **`PathManager.LauncherSessionsFolder` property 追加** (`Manager/PathManager.cs`): `<install>/responses/launcher_sessions/` の path SoT。Launcher 側 `Launcher/scripts/session_heartbeat.gd` の `PathManager.get_base_directory().path_join("responses/launcher_sessions")` と同 relative path を別実装 (C# / GDScript) で resolve、drift は SPEC §3.8.7 / §6.5 の literal 定義で fence。`VerifyPaths` で起動時 trail に `LauncherSessionsFolder` path + 存在 flag を embed して drift 目視可能化
- **`SessionConflictDialog.Show` signature 拡張** (`Manager/Services/SessionConflictDialog.cs`): 第 4 引数 `IReadOnlyList<LauncherSessionInfo> launcherOthers` を追加 (= `operationDescription` は第 5 引数に shift)、Manager + Launcher の検出結果を 1 dialog に **merge 表示** (= 2 連続 dialog の UX 退行回避)。`BuildDetectedList` → `BuildMergedDetectedList` に拡張、行毎に component 種別を区別 (`PC-A (Manager v0.11.0、最終確認: 5 秒前)` / `PC-B (Launcher v0.5.18、最終確認: 12 秒前)`)、最大 5 件 + 残件数要約は merge count、Manager → Launcher の表示順
- **Startup dialog title 汎用化**: `【危険】他 PC で Manager が起動中です` → `【危険】他 PC で Manager / Launcher が稼働中です` (= 旧 Manager 主眼から汎用化、merge 表示の検出 list と文言を一致)。EditOperation title は既存維持 (= 「他 PC で誰かが作業中です」、Launcher 検出時も「作業中」と読める汎用表現)
- **`MainForm.MainForm_Load` chain pattern に統合** (`Manager/MainForm.cs`): `_sessionService.Initialize` 直後に `_launcherSessionService = new(PathManager.LauncherSessionsFolder); _launcherSessionService.Initialize();` を追加、`DetectOtherActiveSessions` 直後に `DetectActiveLauncherSessions` で両 detect を sync 取得、両方の OR で `BeginInvoke` dialog 表示判定。Cancel path で `_launcherSessionService.Shutdown() + null` も追加 (= polling-only なので no-op だが対称化 + FormClosed 経由二重呼出予防)
- **`MainForm.CheckSessionConflictBeforeWrite` も同 pattern で Launcher detect を merge**: 13 callsite (SectionPanel + 5 Form の 2 段目 fence) すべてが automatic に Launcher 検出も使うようになる (= callsite 側 code 変更ゼロ、MainForm 内部 merge で API contract 据置)。`_launcherSessionService == null || !_launcherSessionService.IsInitialized` 時は空 list で fail-soft、Manager 単独検出 path に倒れる
- **`MainForm_FormClosed` で `_launcherSessionService.Shutdown()` 追加**: `_sessionService.Shutdown()` と対称、null 化 + try/catch で Warn trail (= polling-only なので no-op だが API 対称化)
- **assembly version bump**: `0.10.2.0` → `0.11.0.0` (minor bump、新 service + 新 DTO + dialog 拡張 + 13 callsite 自動拡張、v0.10.0 (manager_sessions) と同規模、AGENTS.md「Release and Versioning」minor=「機能追加」)
- **同 PC = Manager 起動 PC 上の Launcher も検出に含める** (= 除外しない、安全側設計、SPEC §3.8.7.6): file lock 競合は同 PC でも発生 (= Manager 編集 × 同 PC Launcher SQLite read)、user は dialog で「自分が起動した Launcher」と分かれば閉じれば済む。除外 option は別 PR 余地
- **`csproj` に `<Compile Include>` 2 件追加** (`Manager/GCTonePrism_Manager.csproj`): `Models\LauncherSessionInfo.cs` (= `Models\ManagerSessionInfo.cs` 直前、alphabetical 配置) + `Services\LauncherSessionService.cs` (= `Services\Logger.cs` 直前、同)
- **scope 外** (= 別 PR 余地): Launcher 側に「他 PC Manager 編集中」検出機構を追加 (= PR3b の対称化) は本 PR scope 外、後追い PR 余地
- **詳細仕様は [SPECIFICATION.md §3.8.7](SPECIFICATION.md) (動作仕様 + JSON schema literal + 検出 trigger + fail-soft 戦略 + 非対称性明示) + [§6.5 例外注記](SPECIFICATION.md) (heartbeat 用専用 sub-folder の明文化) 参照**
- **verify**: Manager Release build clean (= warnings 0)。実機 verify 9 path は SPEC §3.8.7 + 本 PR description 参照、merge 前必須

**Round 2 review fix (H-1 + M-1/2/3/4 + L-1/2/5)** — version bump なし、本 entry に統合:

- **H-1**: 新規 `Launcher/scripts/session_heartbeat.gd.uid` (= Godot 4 で `.gd` と pair で生成される UID file) を commit に同梱 (= 既存 19 file の対と一致、別 PC / CI で project open 時の UID drift を予防)
- **M-1 (Launcher 側 fail-soft 表現 drift)**: 本 CHANGELOG entry / SPEC §3.8.7.5 / `session_heartbeat.gd` docstring 間で「`Logger.warn` trail」と書いた drift があり、実装は Godot 4 built-in `Logger` class との名前衝突を避けるため `push_warning` を使用。三者すべてを「`push_warning` 経由で Launcher autoload `Logger` の Godot log tail で WARN 自動分類」表現に同期、#85 (Launcher 統一ログ基盤 sweep) 完了後の明示 `Logger.warn` 直 call 移行 path も明記
- **M-2 (`*.json` glob quirk)**: `LauncherSessionService.DetectActiveLauncherSessions` の `Directory.EnumerateFiles(*.json)` が Windows 8.3 short-name 有効時に `.json.tmp` (Launcher atomic write の rename 途中 / crash 残骸) を誤 match する drift を defensive filter で物理閉鎖 (= `path.EndsWith(".json")` + `!path.EndsWith(".tmp")` の 2 段 check、Launcher crash で `.tmp` 残置しても dialog list に「pc-a.json」誤表示する path を遮断)
- **M-3 (`long.TryParse` silent 0)**: `TryParseSessionFile` で `last_heartbeat_at_unix_ms` field が存在するが `long.TryParse` 失敗 (= 科学記法 `1.7e+12` / 文字列等の数値 corruption) した case に「field 欠落」と同 path で扱い、silent 0 で stale 判定される drift を解消。新実装は field の **存在** と **parse 成否** を区別し、parse 失敗時のみ Warn log で trail を残してから mtime fallback path に流す (= silent drop 予防 + 「primary path で field あり parse 失敗を silent 0 にしない」claim と実装を整合)
- **M-4 (5 件 cap 配分問題)**: `BuildMergedDetectedList` の 5 件 cap が Manager → Launcher の表示順で共有されるため、Manager が 5 件以上検出された場合 Launcher が 0 件表示になる drift を、残件数要約 line で `Manager X 件 / Launcher Y 件 表示外` のように内訳を明示する形に解消 (= 仕様判断 #1 案、cap 自体は 5 件維持で要約を充実)
- **L-1/L-2 (method 名 / 引数名 の self-PC 非対称)**: `DetectActiveLauncherSessions` (= "Other" なし、self 含む) と `SessionConflictDialog.Show` 第 4 引数 `launcherOthers` (= "Others" だが実態は self 含む) の意図的非対称命名を、両 docstring で「SPEC §3.8.7.6 の自 PC 含む安全側設計、Manager 側 `DetectOtherActiveSessions` (= "Other" 明示) と意図的非対称」と明文化、call-site だけ読んで誤用する path を予防
- **L-5 (pid 型注記)**: SPEC §3.8.7.2 の JSON schema literal だけでは `pid` / `started_at_unix_ms` / `last_heartbeat_at_unix_ms` の int64 範囲 / cross-language 整合が読み取れない drift を、schema 直後に型 / 単位の注記段落を追加して明文化 (= `pc_name` string / `started_at_unix_ms` `last_heartbeat_at_unix_ms` int64 / `pid` int64 / `launcher_version` string)
- **scope 外として残置** (L-3 / L-4): `VerifyPaths` への `_initialized` flag 出力 / `_init_failed` + `_initialized` の state machine 単一化 は内部状態の改善で本 PR scope を超えるため別 PR 余地、現状の挙動に bug は確認できないため retain

**Round 3 review fix (M-1/2/3 + L-1/2/4)** — version bump なし、本 entry に統合:

- **M-1 (PC 名 → filename sanitization 漏れ)**: `session_heartbeat.gd` の `_get_pc_name()` 結果を filename に使う前の sanitization が `logger.gd:213-219 _sanitize_filename` と対称になっておらず、CI / testing で `COMPUTERNAME=test/foo` 等の malformed env var injection / HOSTNAME fallback (Linux/macOS) で `:` 等が許容される path で `FileAccess.open` silent 失敗 → 検出不能になる drift があった (= docstring 「`logger.gd:204-210` と同 logic」claim と一段ずれ)。`session_heartbeat.gd` 末尾に `_sanitize_filename` を追加 (= logger.gd と同 logic で `/ \ : * ? " < > |` を `_` 置換)、`_initialize` 内で filename にする前に必ず通す形に修正。JSON 内 `pc_name` field は **オリジナル** 値、filename のみ **sanitized** 値 (= SPEC §3.8.7.2 に明文化)。Manager 側 primary path は JSON 内 `pc_name` 経由でオリジナル表示、fallback path は `Path.GetFileNameWithoutExtension(path)` で sanitized 値に倒れる non-conflicting 設計。helper 共通化 (= 両者で 1 関数化) は別 PR scope
- **M-2 (5 件 cap 維持の trade-off 受容を SPEC §3.8.7.4 で明文化)**: round 2 で導入した「`Manager X 件 / Launcher Y 件 表示外` 残件数要約」だけでは「なぜ category 別 cap (= 案 a: Manager 3 / Launcher 2) や round-robin interleave (= 案 b) や cap 緩和 (= 案 c: 5 → 8) を採らなかったか」が SPEC に残らず将来 reviewer が drift と誤読する余地。SPEC §3.8.7.4 に「5 件 cap 維持の trade-off 受容」段落を追加、学校 LAN (~10 PC) で Manager 5 件以上が稀 + 最 likely な「Manager 1-2 + Launcher 数台」混在 case では Launcher も primary list 表示される根拠、cap 緩和は user feedback で大規模 LAN 確認後の別 issue 余地 を明示
- **M-3 (同 PC 検出の 13 callsite UX cost SPEC 明文化)**: `CheckSessionConflictBeforeWrite` が 13 callsite で編集操作前に毎回 detect するため、同 PC で Launcher を放置すると操作毎に同 dialog が pop up し続ける UX path が SPEC §3.8.7.6 で明示されていない drift。「user は dialog で同 PC Launcher 検出を確認 → × で閉じる → 編集続行」が想定運用 path、放置 path の操作毎 dialog UX cost は安全側設計の trade-off として受容、体感問題と判断したら除外 option (= `Environment.MachineName` で自 PC filter) を別 PR で追加可能、を SPEC §3.8.7.6 末尾段落で明文化
- **L-1 (TryParseSessionFile fallback path で dict 情報を捨てる drift)**: `last_heartbeat_at_unix_ms` field 欠落 / parse 失敗時の fallback path で `PcName = Path.GetFileNameWithoutExtension(path)` + `LauncherVersion = "(version 不明)"` 固定だったが、dict 自体は parse 成功している (= primary 入口 null check 通過) ので `pc_name` / `launcher_version` / `started_at_unix_ms` / `pid` も best-effort 読込可能。新実装は primary path と同じ defensive 読み (= `dict.ContainsKey(...)` + null fallback) で活用、欠落 / null 時のみ filename / "(unknown)" / 0 に倒れる non-conflicting 設計。display 一貫性向上 (PC 名表記揺れ予防)
- **L-2 (`LauncherSessionInfo.Pid` が dead data on the wire だった drift 解消)**: SPEC §3.8.7.2 schema に `pid` を載せて crossing-language 整合表 (`pid: int64`) まで書いていたが Manager 側 actual 消費経路なしだった drift を、`SessionConflictDialog.Show` の Logger trail に `pc=PC-B pid=12345 ver=0.5.18` 形式で embed することで解消。log 解析時に「自 PC 検出 = 自 `Process.GetCurrentProcess().Id` との一致」判定で同 PC 上 Launcher を識別可能化、dialog body (= user 視点) には pid は出さない (= 部員視点で意味なし、log のみ)。`LauncherSessionInfo.Pid` docstring も「dead data」から「Logger trail で消費」に更新
- **L-4 (MainForm_Load と CheckSessionConflictBeforeWrite で IsInitialized guard 非対称)**: 動作上は両 path とも fail-soft で問題なしだが、code style 非対称で読み手の認知 load 増の drift。`MainForm_Load` 側にも `_launcherSessionService != null && _launcherSessionService.IsInitialized` の明示 guard を追加して `CheckSessionConflictBeforeWrite` と pattern を対称化、defense-in-depth を 2 箇所で揃える
- **scope 外として残置** (L-3 / L-5): L-3 (autoload 名 rename / `class_name LauncherLog` 切出しで Godot 4 built-in `Logger` との衝突を構造的に予防) は #85 (Launcher 統一ログ基盤 sweep) で扱う方が文脈一致、本 PR で docstring 警告 retain のみ。L-5 (SPEC 変更履歴 v1.10.28 row が 2KB 超で renderer 視認性低下) は既存 v1.10.26 / v1.10.27 row も同様の長さで PR3b 由来の drift ではない、規約変更は将来別 PR 余地

### [Manager v0.10.2] - 2026-05-18

#### Fixed (#187 — AddGameForm 2 段目 fence を pre-copy に reorder し parent rollback を構造的に不要化)

- **2 段目 fence を `CopyGameFolder` の前に移動** (`Manager/AddGameForm.cs`): PR #184 round 6 案 B で導入した「**DB write 直前**」の post-copy fence は、Cancel 時に 30 秒〜5 分の file copy が無駄になる + version subfolder / parent gameFolder の rollback complexity を抱え込む構造的 cost を持っていた (= PR #187 round 1 で `parentCreatedThisCall` flag + `TryDeleteEmptyParentGameFolder` helper + 3 rollback path 修正という拡張で対症療法を試みたが、根本的な「**フォルダを作って消す**」設計の歪みは残置)。本 PR で fence 位置自体を `CopyGameFolder` の **前** に移動する reorder approach に転換、parent rollback complexity を構造的に不要化。
- **得るもの**:
  - **Cancel 時の即時 feedback**: ProcessingDialog を見せる前に fence dialog → file copy そのものが走らない → version subfolder / parent gameFolder の rollback 自体が不要
  - **code 大幅 simplify**: round 1 で導入した `parentCreatedThisCall` field (+ docstring) + `TryDeleteEmptyParentGameFolder` helper + 3 rollback path での呼出 (= 計 ~60 行) を全部撤去
  - round 7 M-2 で導入した「rollback delete 失敗時の MessageBox 通知」(= ~20 行) も pre-copy fence では rollback 自体が走らないため不要化、合計 ~80 行の defensive code を構造的に廃止
- **失うもの (= 受容仕様)**:
  - file copy 中 (30 秒〜5 分) に他 PC が起動した case を 2 段目 fence で catch できなくなる
  - **1 段目 fence (= SectionPanel `ShowDialog` 前 check) は維持** されているため、ほとんどの race window (= AddGameForm 開いて入力中の数分) は引き続き catch
  - LAN 運用での「30 秒〜5 分の file copy 中に他 PC 起動」は rare event、user 視点で「5 分 copy 後の Cancel 損失」の体感 cost が大きい trade-off を反転
- **3 rollback path は維持** (= ProcessingDialog 失敗 / catch blocks の SQLite + general Exception): file copy が走った後の例外経路 rollback は引き続き必要 (= 案 B fence Cancel ではなくなる)。旧 #120 retain 設計通り version subfolder のみ削除、parent gameFolder は他 version 共存 safety で retain。
- **設計判断の経緯**: PR #190 round 1 で「`parentCreatedThisCall` flag + helper で 3 rollback path に parent 削除を追加」する Option A approach を実装 + verify PASS したが、reviewer (user) から「**わざわざフォルダ消しに行ってるの? 順番変更じゃなくて?**」の指摘を受けて再検討、reorder approach が universally clean (= 「フォルダ作って消す」より「作る前に check」) と判断、round 2 で書き換え。
- **影響範囲限定**: 本 fix は AddGameForm のみ。EditGameForm / VersionUpForm / StoreSectionForm / BackupSettingsForm の 2 段目 fence 位置は touch なし (= 各々 ShowDialog 内部の DB write 直前 = round 6 案 B 配置のまま、これらは ProcessingDialog なしで file copy 経路を持たないため fence 位置による cost 差が AddGameForm ほど大きくない)。
- **assembly version bump**: `0.10.1.0` → `0.10.2.0` (patch、bugfix のみ、DB schema 変更なし、AGENTS.md「Release and Versioning」ルール準拠)。
- **verify**: 
  - **完了**: Manager Release build clean (warnings 0、net -66 行)。
  - **end state のみ verify 済 (= 不完全)**: PR #190 round 1 (= Option A approach、`parentCreatedThisCall` flag + helper + 3 rollback path) の verify session で「同 form 2 回 Cancel + rollback trail 2 回 log + `games/a/` 不在」を確認済。**ただし round 1 verify は end state (= `games/a/` 不在) のみ cover、本 reorder の主目的である path (= ProcessingDialog 出現前に fence dialog / file copy が走らない) は別 verify 必要** (= round 1 は「作って消す」path、round 2 は「作らない」path、両者は end state 一致だが path は別物)。
  - **round 2 reorder 実機 verify** (Manager v0.10.2 リリース時 / PR merge 前に実施 **必須**): (1) DB に他 PC row 手動 INSERT + keepalive、(2) Manager 起動 → MainForm、(3) AddGameForm を新規 gameId で開く、(4) OK 押下 → **CopyGameFolder 開始前** (= ProcessingDialog 進捗バーが出る前) に fence dialog 表示確認 (= round 1 verify では cover していない path)、(5) Cancel 押下 → `Directory.Exists(games/<gameId>/) == false` を PowerShell で確認 (= 何も作成されていない state)、(6) 同 form で再 OK → 同じ fence dialog (= 「古いゲームデータが残っています」誤 trigger なし)、(7) (regression check) OK 押下 → ProcessingDialog → copy 完了 → DB write → Form close の normal path 確認。verify 未完で merge する場合、リリース当日に「fence 出ない / Cancel しても copy 走る」path の脱落 risk を承知して merge する必要あり (Bundle release の Release.ps1 経路では catch しない silent path)。
- **関連**: PR #184 (v0.10.0、LAN-wide 同時起動検出) verify session で発見した 3 issue (#185 / #186 / [#187](https://github.com/ken1208git/TonePrism/issues/187)) のうち本 PR で #187 を closure。#186 は PR #189 で fix 済、#185 は manifest 単独 path 不可と判明、別 milestone へ移行。

### [Manager v0.10.1] - 2026-05-18

#### Fixed (#186 — Startup SessionConflictDialog がタスクバー不在 / focus 喪失で見失う)

PR #184 (v0.10.0) で実装した起動時 SessionConflictDialog (= 「【危険】他 PC で Manager が起動中です」) は `MainForm_Load` 中 (= MainForm まだ `Show` 未完) で `MessageBox.Show(owner=MainForm, ...)` を呼ぶため、modal child も親も **taskbar entry を持たない silent UI bug** があった (= focus 喪失で dialog が裏に行って見失う、PR #184 verify session で発覚)。本 PR で fix。**3 round の試行錯誤を経て round 3 chain pattern が確定**:

- **`MainForm_Load` を 2 段に分割 + chain pattern で gate 維持** (`Manager/MainForm.cs`):
  - `MainForm_Load` 本体は session init + 他 PC 検出までで止め、検出時は `BeginInvoke` で dialog 表示を defer + `return` で本 method を即抜ける
  - 残り init (= 6 SectionPanel `_gameSectionPanel` / `_storeSectionPanel` / `_settingsSectionPanel` / `_backupSectionPanel` / `_logSectionPanel` / `_updateSectionPanel` の `Initialize` + `MigrateLegacySafetyFilesToSafetyFolder` + `RegisterUnknownSafetyFiles` + `CleanupStaleBackupEntries` + `LoadGames` + `StartAutoBackupIfDue` + `CleanupZombieStagings` + `StartBackgroundUpdateCheckIfDue`) は新規 `ContinueLoadAfterSessionCheck()` private method に切出し
  - dialog で OK 押下時のみ `ContinueLoadAfterSessionCheck` を chain で起動 → 旧実装 (v0.10.0) と同等の gate 意味論を維持 (= Cancel 時は panel init / backup / update check すべて skip)
  - 競合なし path は `ContinueLoadAfterSessionCheck` を直接呼んで code path を 1 本化
- **`BeginInvoke` defer の効果**: MainForm の `Show` 完了 (= taskbar 登録済) 後に dialog が modal child として開く → owner-modal の自然な WinForms 挙動 (= taskbar entry あり / 他 window click で裏に行ける / MainForm click で戻れる) を実現しつつ、見失う path を物理閉鎖
- **`Initialize` / `DetectOtherActiveSessions` は sync 維持**: heartbeat thread 起動は最速で走らせるため `_sessionService.Initialize()` は sync 呼出のまま、`DetectOtherActiveSessions` も sync で他 PC 検出結果を握ってから dialog 表示部分のみ `BeginInvoke` で defer する切り出し
- **race guard**: deferred action 冒頭で `if (IsDisposed || Disposing || _sessionService == null) return;` の早期 guard を追加 (= MainForm_Load 中に user が即 × で閉じた race + FormClosed 経由 `_sessionService.Shutdown()` との二重呼出 race の両方を物理閉鎖、PR #189 reviewer Low で「over-defensive」と評価されたが defense-in-depth で残置)
- **deferred action 全体を try/catch で囲み**: `Logger.Error` で握り潰し (= FormClosed handler の Shutdown catch と同方針、PR #189 reviewer Low 指摘、`Application.ThreadException` 経路で UI thread crash を防ぐ defensive guard)
- **`StartBackgroundUpdateCheckIfDue` との race 解消**: 旧 round 2 では `BeginInvoke` 投函された SessionConflictDialog message と、`async void StartBackgroundUpdateCheckIfDue` の continuation MessageBox (`ShowUpdateAvailableNotification`) の表示順序が non-deterministic race だった (PR #189 reviewer Medium 指摘)。本 round 3 で chain pattern により `StartBackgroundUpdateCheckIfDue` の起動を `ContinueLoadAfterSessionCheck` 内に閉じ込めたため、Startup dialog が必ず先に出てから update check が起動する deterministic 順序に修正
- **assembly version bump**: `0.10.0.0` → `0.10.1.0` (patch、bugfix のみ、DB schema 変更なし、AGENTS.md「Release and Versioning」ルール準拠)
- **verify**: Manager Release build clean。実機 verify は DB に他 PC row 手動 INSERT 状態で Manager 起動 → MainForm が一瞬表示 (= panel 未 init の空 state) されてから Startup dialog が modal child として開く → 他 window click で dialog が裏に行き、タスクバーの Manager entry click で復帰できる挙動 + OK 押下後に panel init / LoadGames 等が走って通常の MainForm 表示 + Cancel 押下時は panel init すべて skip して即 Close を目視確認。EditOperation context は PR #184 verify session で動作確認済 (= MainForm visible 経路、本 PR で挙動変化なし)

##### round 1 → round 2 → round 3 試行履歴

- **round 1** (commit `3c9129e`、撤回): `SessionConflictDialog.Show` 内で Startup context 限定 `MessageBoxOptions.DefaultDesktopOnly` を適用。dialog が default desktop 最前面に固定される効果で「見失う」path は閉鎖されたが、user feedback「他 window をクリックしても dialog が裏に行かず常時最前面でうざい」を受けて trade-off 不適切と判断
- **round 2** (commit `ec4339c`、reviewer High 指摘で再修正): caller (`MainForm_Load`) で `BeginInvoke` で dialog 表示を defer。taskbar 問題は解消したが、`MainForm_Load` 残り init (panel.Initialize / LoadGames / RegisterUnknownSafetyFiles / CleanupStaleBackupEntries / StartAutoBackupIfDue / StartBackgroundUpdateCheckIfDue 等) が dialog 表示前に同期で走り終わる **gate → 事後通知 regression** が PR #189 reviewer High で指摘 → Cancel 押下しても backup_log INSERT / 自動 backup 起動 / アップデート check 等が既に走り終わっている path
- **round 3** (commit `48bc6ed`、code logic 確定): `MainForm_Load` を 2 段に分割し chain pattern で gate を物理的に維持。残り init は `ContinueLoadAfterSessionCheck` に切出し、dialog OK 時のみ chain 起動。`SessionConflictDialog.cs` 側は標準 owner-modal MessageBox に revert
- **round 4** (本 entry、documentation drift fix): PR #189 reviewer Medium 2 件 + Low 2 件すべて修正。code logic 変更なしの documentation / comment 修正のみ。
  - **M-1**: 本 CHANGELOG entry 内「panel.Initialize × 4」が実際 6 件 (= 6 SectionPanel) との数値乖離だったため、抽象数を捨てて 6 panel 名を明示列挙する形式に修正 (= 将来 SectionPanel add/remove で drift する path を物理閉鎖、PR #189 round 2 で踏んだ「認識ズレが gate regression を生む」path と同質の防止策)
  - **M-2**: `SessionConflictDialog.cs:92-104` の docstring が「round 2 確定」止まりで round 3 chain pattern を反映していなかったため、「round 3 確定」に書換え + 「詳細 rationale は `MainForm.MainForm_Load` 起動時 check 部の inline コメント参照」の pointer 形式に集約 (= 2 ファイル間の履歴記述分裂を解消)
  - **L-1**: deferred action 内 race guard コメントの「MainForm_Load 中に user が即 × で閉じた」表現が timing として不正確 (= Load 中は MainForm 未表示で × clickable な window なし) だったため、「`MainForm_Load` 完了 → `MainForm.Show` 完了 → message pump が本 BeginInvoke action を pick up するまでの数 ms に user が × した case」と precise 表現に訂正
  - **L-2**: round 3 で旧 `BeginInvoke(new Action(() => Close()))` 二重 defer を素の `Close()` に短絡化した際に「`Application.Exit` ではなく `Close` で FormClosing/Logger.Shutdown を確実に走らせる」rationale コメントが消えていたため復活 (= 将来「直感的な `Application.Exit` に書換え」regression 予防)

##### PR #185 / #188 (manifest 単独 DPI awareness 試行) との分離

#185 が manifest 単独で Form layout regression を起こして revert された結果、起動時 dialog の見失い問題は引き続き残っていた。本 PR は **manifest 触らない MainForm_Load 構造変更のみ** で #185 / #188 の DPI 問題と完全独立な path で fix、Form layout への影響ゼロ。DPI awareness 解消は #185 が再開された時に別 PR で扱う。

##### 関連

PR #184 (v0.10.0、LAN-wide 同時起動検出) の verify session で発見した 3 つの issue (#185 / [#186](https://github.com/ken1208git/TonePrism/issues/186) / #187) のうち、本 PR で #186 を closure。#187 は別 PR で対応予定、#185 は manifest 単独 path 不可と判明、別 milestone へ移行。

### [Manager v0.10.0] - 2026-05-18

#### Added (#179 + #178 (c) — Manager LAN-wide 同時起動検出 + 競合 risk 操作前 dialog)

- **`manager_sessions` table を新設** (DB schema v12 → v13、`SchemaManager.cs`): 学校 LAN 上で複数 PC が同時運用する `prism.db` (SMB 共有) で、各 PC の Manager process 稼働状況を heartbeat 周期で記録する SoT。schema: `pc_name TEXT PRIMARY KEY` + `started_at_unix_ms` + `last_heartbeat_at_unix_ms` + `pid` + `manager_version`。`MigrateV12ToV13` で `CREATE TABLE IF NOT EXISTS` (idempotent)、`CheckAndMigrateDatabase` chain に追加。
- **`ManagerSessionService` を新規追加** (`Services/ManagerSessionService.cs`): heartbeat thread (10 秒間隔、`Task.Run` + `CancellationTokenSource`)、起動時 stale cleanup (`last_heartbeat_at_unix_ms < now - 30000` ms を DELETE で自動回収)、self row INSERT OR REPLACE、`DetectOtherActiveSessions` で他 PC active session 検出、`Shutdown` で heartbeat 停止 + self row DELETE。DB 操作は `DatabaseConnection.ExecuteWithRetry` で SMB BUSY/LOCKED 競合に対応。DB 不到達等は fail-soft (= heartbeat 不在で Manager 自体は継続、Logger.Error で trail)。
- **`ManagerSessionRepository`** (`Repositories/ManagerSessionRepository.cs`): 上記 service の DB CRUD layer。`DeleteStaleSessions` / `UpsertSelfSession` / `UpsertHeartbeat` / `DeleteSelfSession` / `SelectOtherActiveSessions` の 5 method (heartbeat は INSERT OR REPLACE で row 削除後も自動 reanimate、round 3 H-2 で UPDATE → UPSERT 化済)。
- **`ManagerSessionInfo` DTO** (`Models/ManagerSessionInfo.cs`): 5 property + `SecondsSinceLastHeartbeat(nowMs)` helper (UI 表示用)。
- **`SessionConflictDialog`** (`Services/SessionConflictDialog.cs`): 他 PC 検出時の modal 警告 dialog (MessageBoxIcon.Stop + MessageBoxButtons.OKCancel)。`SessionConflictDialogContext` enum (`Startup` / `EditOperation`) で文言出し分け。「データ破損」「競合」のような技術用語を避け、部員が「何が起きるか」を想像できる具体表現 (= 「お互いに上書きされて消える恐れ」「他 PC の人に確認してから」) に統一。`MessageBoxDefaultButton.Button2 (Cancel)` で反射押下による続行 path を抑制。検出 PC list は最大 5 件 + 残件数の要約で長 PC 列で dialog が膨らまない設計。
- **`Program.cs` に Named Mutex で同 PC 重複起動を物理 block**: `Application.Run` 直前に `new Mutex(initiallyOwned: true, name: "Global\\GCTonePrism_Manager_SingleInstance_" + installPathHash, out createdNew)`、`createdNew=false` で既存 instance 検出 → modal dialog「Manager は 1 つだけ起動できます」→ return (Application.Run 不到達)。Mutex name に install path の MD5 hash (前 16 文字) を含めて dev 環境と本番 install を別 mutex に分離、`Global\` prefix で Windows session 全体に effective。LAN table は他 PC 検出専用、同 PC は別レイヤーで責務分離。
- **`MainForm.MainForm_Load` 改修** + **`MainForm.CheckSessionConflictBeforeWrite` public helper 新規追加**: 既存「同時起動に関する注意」MessageBox を撤廃 (#178 (c) 消化)、代わりに `_sessionService.Initialize` + `DetectOtherActiveSessions` → 検出時 `SessionConflictDialog (Startup context)` を表示。user が Cancel で `_sessionService.Shutdown()` + Manager 終了 (= self row delete で clean exit)。`MainForm.FormClosed` event で Shutdown 自動発火。`CheckSessionConflictBeforeWrite(operationDescription)` helper を各 SectionPanel が DB write 直前に呼び、検出時 `SessionConflictDialog (EditOperation context)` を表示 → Cancel で操作中止。
- **各 SectionPanel に `CheckSessionConflictBeforeWrite` 呼出を追加 (13 箇所)**: `GameSectionPanel` の btnAddGame / btnEditGame / btnVersionUp / btnDeleteGame (4 件)、`StoreSectionPanel` の btnAdd / btnEdit / btnDelete / btnMoveUp / btnMoveDown (5 件)、`SettingsSectionPanel` の btnResetDatabase (1 件)、`BackupSectionPanel` の btnBackupNow / btnRestore / btnDelete (3 件)。各 handler 冒頭で `(this.FindForm() as MainForm)?.CheckSessionConflictBeforeWrite("操作名") == DialogResult.Cancel` で early return。read-only 系 (btnRefresh / btnOpenLogFolder 等) は対象外。
- **SPEC §7.3 (table 12 manager_sessions の column 定義表) + §7.4 ER 図 + 新規 §3.8 (LAN-wide 同時起動検出機構の動作仕様、heartbeat / stale timeout / dialog trigger / button 設計 / context-aware 文言の規約) + 変更履歴 v1.10.26 row 追加**。あわせて `SchemaManager.cs` 内 `ExpectedSchema` 辞書に `manager_sessions` を登録 (= AGENTS.md / SPEC §7.6.3 の SoT 同期義務、`VerifySchema` で drift 検出可能化)。SPEC §7.6 workflow 本文は規約変更なしのため touch 不要 (= migration chain の追加は SPEC §7.6.1 規約遵守の実装側変更のみ)。

**スコープ**: Manager 同時起動の「人間頼り運用」を「DB 経由の自動検出 + 競合 risk 操作前 dialog」に upgrade。学校 LAN の SMB 共有 `prism.db` 運用で複数 PC が並走しても、Manager UI 側でデータ破損 risk を user に明示通知できるようになる。「【危険】... お互いに上書きされて消える恐れ」を Startup / EditOperation の両 trigger で表示、user は OK (続行) / Cancel (中止) を都度判断する設計。

**スコープ外** (= 別 PR):
- **Launcher session tracking** (= #179 の Launcher 側) → PR3b で SPEC §6.5 / §3.x 序論 の Launcher write 禁止原則 (= 「Launcher は SQLite に直接書き込まず、JSON ファイルを `responses/` 等の drop folder に出力 → Manager が取り込む drop-folder 方式」) に沿った代替案を設計議論から (candidates: JSON drop folder + Manager polling / file system flag + enumeration / TCP/UDP 通信)。
- Bundle bump (リリース直前のみ)。
- minor bump (v0.9.3 → v0.10.0) 判断: DB schema migration を伴う新機能追加 (manager_sessions table) + 新 service + 13 箇所の UI 動作変化 (検出時 dialog 表示) を考慮。0.x 系慣習でも DB schema 変更は minor bump が妥当。

**詳細仕様は [SPECIFICATION.md §7.3](SPECIFICATION.md) (table 12 manager_sessions の column 定義) + [§7.6.1](SPECIFICATION.md) (migration 規約、本 PR では実装側のみ touch) + [§3.8](SPECIFICATION.md) (LAN-wide 同時起動検出機構の動作仕様) 参照**。

**Round 1 review fix (Critical-1 (+ Low-3 統合) + High-1/2 + Medium-1/2/3/4/5 + Low-1/2/4/5)** — version bump なし、本 entry に統合 (AGENTS.md「1 PR 内の version bump は原則 1 回のみ」原則)。**Low-3 は Critical-1 fix に統合済** (= session init を dbReady=true 確定後に移動した結果、dbReady=false early-return path で session も起動しない clean path に倒れる、本文の Critical-1 entry 末尾参照):

- **Critical-1 `_sessionService.Initialize()` が schema migration 前に走る起動順序 bug を物理閉鎖**: 旧 `MainForm_Load` は `dbManager.InitializeDatabase()` (= v12 → v13 migration trigger) の **前** に `_sessionService = new ... + Initialize()` を呼んでいて、既存 v12 user の初回 v0.10.0 起動で `no such table: manager_sessions` で throw → catch で silent Logger.Error + `_initialized = false` のまま session 機構が永久 disabled になる path があった (= 「LAN-wide 同時起動検出」の publish 直後に対象 user 全員が片方向 degraded state)。新順序: `dbReady = true` 確定後 (= migration 完了後) に `_sessionService` 初期化 → 起動時 check → SessionConflictDialog 表示 → Cancel で Close。L-3 (dbReady=false early-return での session 中途半端状態) も同時解消 (= dbReady=false path では session 起動しない)。
- **High-1 `ExpectedSchema` 辞書に `manager_sessions` を追加** (`SchemaManager.cs:1570`): AGENTS.md / SPEC §7.6.3 の SoT 同期義務違反。旧実装は table 追加したが `ExpectedSchema` 未登録のため `VerifySchema` が drift 検出不可能、v0.8.1 で起きた「SPEC 更新あり migration 漏れ drift」事故の再発防止 fence 自体が無効化されていた。`{ "manager_sessions", new[] { "pc_name", "started_at_unix_ms", "last_heartbeat_at_unix_ms", "pid", "manager_version" } }` を追加して fence 復活。
- **High-2 SPEC §7.3 column 定義表に table 12 を追加 + CHANGELOG / 変更履歴 row の「§7.3 ER 図」表現訂正**: 旧 PR は §7.4 ER 図 (Mermaid) のみ更新、§7.3 (table 単位の column 定義表) には 12 個目の table 定義が追加されていなかった。`#### テーブル12: manager_sessions` を §7.3 末尾に追加 (PC PK + 4 column 表形式 + 用途 / 設計判断の解説)。CHANGELOG / SPEC 変更履歴の文言を「§7.3 ER 図」(誤) → 「§7.3 column 定義表 + §7.4 ER 図」(正) に訂正。
- **Medium-1 `§3.X` placeholder を全 8 ファイルで §3.8 に解決** (Manager 4 ファイル + Program.cs + SchemaManager.cs + CHANGELOG.md + SPECIFICATION.md): 草稿の placeholder が code comment / CHANGELOG / SPEC の自己参照すべてに残置していた整合性違反を sweep。特に SPEC §3.8.6 の「Launcher write 禁止原則 (§3.X 参照)」は **SPEC に存在しない section を指していた誤参照**、実際の Launcher write 禁止記述は `§6.5 / §3.x 序論 (L191 / L203 / L1988)` にあるため正しい anchor に書換え。
- **Medium-2 SPEC §7.6 workflow 本文は未変更だが CHANGELOG / SPEC 変更履歴が「§7.6 chain 化」と主張していた事実誤認を訂正**: コード (`SchemaManager.cs:820-826`) に migration chain は確かに追加されたが、SPEC §7.6 workflow 本文は touch されていない (= 規約変更なし、実装側のみ規約遵守)。文言を「§7.6.1 規約遵守の実装側変更のみ」に reword、「§7.6 chain 化」記述を撤回。
- **Medium-3 「Launcher write 禁止原則は L1926 付近」記述を `§6.5 / §3.x 序論` に訂正**: 旧 CHANGELOG / SPEC 変更履歴の「L1926 付近」を grep で確認したところ「製作者情報データ: developers テーブル」の説明箇所で無関係。`grep "JSON drop folder|Launcher.*SQLite.*書き込"` で実際の記述位置 (L191 / L203 / §3.x 序論、L1988 = §6.5 周辺) に anchor 修正。Medium-1 と同 PR 内 sweep で 1 度に処理。
- **Medium-4 Cancel-終了 path で `_sessionService = null` 追加 (Shutdown 二重呼出抑制)**: Critical-1 fix と一緒に修正済 (= Cancel 選択時に `_sessionService.Shutdown()` 直後で `_sessionService = null;` を set、FormClosed handler が null チェックで早期 return、`Shutdown` の二重呼出が物理的に発生しない path に変更)。`_initialized` flag による guard は dead code 化するが、defensive で残置。
- **Medium-5 `SessionConflictHelper` 共通 helper 抽出 + silent skip path の Logger.Warn 出力** (新規 `Manager/Services/SessionConflictHelper.cs`): 旧 13 callsite の `(this.FindForm() as MainForm)?.CheckSessionConflictBeforeWrite("op") == DialogResult.Cancel` pattern は `FindForm` が null / 非 MainForm を返した場合 `null == Cancel` で false 倒れ → silent skip path があった (現状 MainForm 直下にしかホストされないため実害ゼロだが、将来 panel をネスト dialog に embed した時に全 13 箇所が無音で check を skip する drift)。新 helper `SessionConflictHelper.CheckBeforeWrite(caller, "op")` で null / 非 MainForm path を `Logger.Warn` で flag (fail-soft の OK 返却は維持、debug 容易化のみ)。13 callsite を全部新 helper 経由に書換え。
- **Low-1 Mutex の `ReleaseMutex()` を `finally` block で明示** (`Program.cs`): 旧 `using` 経由 Dispose 単独だと kernel 上「abandoned mutex」状態を経由する code smell (将来 `WaitOne` 経由 pattern 追加時の `AbandonedMutexException` 伏線)。`Logger.Shutdown` 後の `finally` block で `singleInstanceMutex.ReleaseMutex()` を呼ぶ形に追加。
- **Low-2 `ManagerSessionService.Shutdown` の `AggregateException` catch を InnerExceptions filter 付きに**: 旧 `catch (AggregateException) { /* OperationCanceled は想定済 */ }` は **全 inner type を silent swallow** していた drift path (= heartbeat task の最後 UpdateHeartbeat で SQLite 例外を投げた case も trail なし)。`when (ae.InnerExceptions.All(e => e is OperationCanceledException))` filter で OperationCanceled のみ silent OK、それ以外の inner exception は Logger.Warn で 1 件ずつ trail を残す形に変更。`using System.Linq;` 追加。
- **Low-4 SessionConflictDialog の検出 PC list に `manager_version` を embed**: 旧 `BuildDetectedList` は `pc_name` + 最終確認秒数のみで `manager_version` を dead-write 寄り state にしていた。新 list 形式: `- {pc_name} (Manager v{manager_version}、最終確認: {N} 秒前)`、空 version は「(version 不明)」fallback。「他 PC が古い version の Manager で開いている」case を user に視覚で伝達 (= compatibility 警告の役にも立つ)。
- **Low-5 dialog body の `[OK]` / `[Cancel]` 表記を OS button label 準拠に修正**: 旧 body の `[OK] このまま起動する / [Cancel] Manager を終了する` は MessageBox.Show の OS-localized button label (日本語 Windows なら「OK / キャンセル」) と文字列一致しない UX 不揃いだった。新表記: `**「OK」**を押す: このまま起動する / **「キャンセル」**を押す: Manager を終了する` で OS button 上の表記準拠に統一。**(round 2 High-1 で markdown 強調 `**...**` 削除済、現状は plain 表記に再修正)**。

**Round 2 review fix (High-1/2 + Medium-1/2/3 + Low-1/2/3/4 + Info-1/2)** — version bump なし、本 entry に統合:

- **High-1 MessageBox 本文の markdown literal `**...**` 削除**: round 1 Low-5 fix で OS button label 準拠表記の意図で `**「OK」**` / `**「キャンセル」**` の markdown 強調を入れたが、`System.Windows.Forms.MessageBox` は markdown を解釈しないため実機では `**「OK」**を押す: このまま保存する` のように literal の asterisks がそのまま表示される UI bug があった。`SessionConflictDialog.cs:67-83` の 4 箇所すべての `**...**` を削除して plain text に統一、OS button label (日本語 Windows = 「OK / キャンセル」) と文字列一致する表記に再修正。markdown は CHANGELOG / SPEC / PR description のみで、UI 文字列に紛れ込ませない rule を round 2 で確立。
- **High-2 selection 依存 7 handler で check を validation の後に移動 (UX 退行解消)**: 旧 13 callsite は全部 handler 冒頭で `CheckBeforeWrite` を呼んでいたため、selection 依存 handler (= 「行選択なし」で MessageBox 出して return する path) で「**何も選んでいないのに重大警告 dialog が割り込む UX 退行**」があった。SPEC §3.8.2「DB write 直前」規約と乖離していた path を全 7 callsite で物理閉鎖: GameSectionPanel (btnEditGame / btnVersionUp / btnDeleteGame の 3 件) + StoreSectionPanel (btnEdit / btnDelete + btnMoveUp/Down は MoveSection 内で集約 sweep) + BackupSectionPanel (btnRestore / btnDelete の 2 件)。各 handler で selection / range / 削除確認の各 validation 通過後、DB write 直前 (= confirm dialog の OK 後 / RestoreService.Restore 直前 / DeleteSection / 物理ファイル削除 直前) に check を移動。「無条件 write へ進む」handler (= GameSection btnAddGame / Store btnAdd / Settings btnResetDatabase / Backup btnBackupNow) は冒頭 check のまま (旧位置で正当)。
- **Medium-1 EditOperation dialog template を汎用文に書換え** (`SessionConflictDialog.cs:73-83`): 旧 template「{opLabel} の **内容と** 他 PC の編集内容が...」は `operationDescription` が「ゲーム削除」「データベース初期化」「バックアップ復元」「ストアセクション並び替え」等の名詞句 (= 「削除の内容」「初期化の内容」が存在しない含意) で日本語として grammatical に成立しなかった (13 callsite のうち 7 件で違和感)。新 template: 「このまま **{opLabel} を実行すると、他 PC の編集内容と** お互いに上書きされて消える恐れがあります」+ 「**「OK」**を押す: このまま実行する / **「キャンセル」**を押す: 実行を中止する」(High-1 と整合して plain text)。動詞「実行する」で操作種別に依らない汎用文化、13 callsite の言い回し drift も同時に予防。
- **Medium-2 dead constant 削除** (`SettingsKeys.cs`): `ManagerHeartbeatIntervalSeconds` + `DefaultManagerHeartbeatIntervalSeconds` を削除。docstring 自身が「future tunability の予約 slot、本 PR では実装せず default 固定」と明言、Manager 全 file から参照ゼロ。AGENTS.md「Don't design for hypothetical future requirements」+「Don't add features... beyond what the task requires」原則違反だったため YAGNI で removal。settings 経由 override 実装する PR が立った時点で再追加可能、それまでは hardcoded `ManagerSessionService.HeartbeatIntervalSeconds = 10` のみが SoT。
- **Medium-3 SPEC §3.8.5 に起動時 UI freeze 受容仕様を明示** (round 4 Medium-4 で試算補正): `ManagerSessionService.Initialize` + `DetectOtherActiveSessions` は `MainForm_Load` (= UI thread) から sync 呼出で 3 DB query が走り、`DatabaseConnection.ExecuteWithRetry` の `busy_timeout=10000` ms × `maxRetries=3` = 1 query あたり worst case ~30 秒、3 query 直列で **最大 ~90 秒 UI freeze する** path がある。設計判断として受容 (= scope creep の background 化案は採らず、起動時の最初の 3 query のみ freeze で heartbeat 本体は async 化済、学校 LAN 運用での実発生頻度は極低、能動操作中のため許容範囲)。SPEC §3.8.5 末尾に「起動時 UI freeze 受容仕様」段落を追加して暗黙 spec 化を解消、SMB latency 改善 / retry tuning (= 起動時 retry を 1 に絞る等) は別 issue 候補に retain。
- **Low-1 重複起動 path で `Logger.Shutdown()` 追加** (`Program.cs:66 直前`): Named Mutex 取得失敗 → MessageBox 表示 → `return` で early exit する path で `finally { Logger.Shutdown(); }` block を skip していたため、log に「Manager 終了」trail が残らず log 解析時に「crash したのか正常 exit したのか」区別できなくなる drift があった。`return` 直前に `Logger.Shutdown();` 1 行を追加して trail を確保。
- **Low-2 `ComputeInstallPathHash` に `ToLowerInvariant()` 正規化** (`Program.cs`): 旧実装は `installPath` を UTF-8 bytes でそのまま MD5 化していたが、Windows file system (NTFS / SMB) は case-insensitive で `Application.StartupPath` は呼び方 (cmd 直叩き / Explorer shortcut / Process.Start) で casing が変わる可能性があった (Microsoft docs「the path may not have the exact casing of the original on disk」)。`C:\Foo\Manager\` と `c:\foo\manager\` が別 mutex に化けて重複起動 block が bypass する drift path を `ToLowerInvariant()` 正規化で物理閉鎖。
- **Low-3 `SessionConflictHelper.CheckBeforeWrite` で `FindForm()` を 1 回呼出に整理**: 旧実装は cast 用 + Warn message 内で `FindForm()` を 2 回呼出していた micro inefficiency + 2 回の結果が theoretical race を生む (= UI thread 内なので実害ゼロ)。`var form = caller.FindForm();` で 1 回 capture、cast と Warn message の両方で同 instance を参照する形に整理。
- **Low-4 heartbeat shutdown 時の `_heartbeatCts.Dispose()` race を try/catch で握り潰し**: `Wait(2s)` が timeout で抜けた case (= heartbeat task が SQLite BUSY で最大 10 秒 block で 2 秒 timeout を上回る) で task がまだ生きている状態で `Dispose()` が走り、生きた task 側が `token.WaitHandle.WaitOne` で `ObjectDisposedException` を踏む path があった。loop 内 catch で握り潰されるが shutdown log に noise を残すため、`try { _heartbeatCts.Dispose(); } catch { }` で握り潰して shutdown trail を clean に保つ (CancellationTokenSource は finalizer なしで GC 害なし)。round 1 Low-2 の AggregateException filter で trail を強化した方針と一貫。
- **Info-1 CHANGELOG round 1 review fix header に Low-3 統合を明記**: 旧 header `**Round 1 review fix (Critical-1 + High-1/2 + Medium-1/2/3/4/5 + Low-1/2/4/5)**` は L-3 が抜けていて、本文 / コード comment では「L-3 は C-1 fix に統合済」と書いているが header だけ読んだ reviewer が drift を疑う余地があった。`Critical-1 (+ Low-3 統合)` 表記に修正 + header 直下 1 行で統合の意図を明示。
- **Info-2 `MigrateV12ToV13` log message を「migration 完了 (table 確保)」表現に書換え**: 旧 log「manager_sessions テーブルを作成しました (v12 → v13)」は `CREATE TABLE IF NOT EXISTS` の idempotent 性 (= 既存 table 時は silent skip) と log 表現が不整合 (table が既に存在しても「作成しました」と出る)。「v12 → v13 migration 完了 (manager_sessions table 確保)」状態表現に書換えて、idempotent な「確保 (= ensure)」semantic に整合。

**Round 3 review fix (High-1/2 + Medium-1/2/3 + Low-1/2/3)** — version bump なし、本 entry に統合:

- **High-1 v12→v13 migration が v10→v11 retry path を物理的に壊す regression を物理閉鎖** (`SchemaManager.cs:825-834`): 旧 v12→v13 block は `currentVersion = 13` を **無条件 bump** していたため、currentVersion=10 のまま v12→v13 block に入った場合 (= Codex P1 #127 で意図的に保持された「v10→v11 が未完なら次回起動時に再試行させる」path) でも v13 で上書きされ、user_version=13 が DB に書き込まれて以降は migration block に二度と入らない → **v10→v11 が永久に未実行のまま固定** する silent regression があった。v11→v12 block と同 guard pattern (`if (currentVersion >= 12) currentVersion = 13; else Logger.Warn("据え置き")`) を採用、`MigrateV12ToV13` 自体は CREATE IF NOT EXISTS で idempotent なので物理変更は先行適用で害なし。
- **High-2 `UpdateHeartbeat` が row 削除後 silent no-op で「自 PC 永久不可視化」する silent failure を物理閉鎖**: 旧 `UPDATE manager_sessions SET ... WHERE pc_name = ...` は row 不在時 `ExecuteNonQuery` が 0 を返すだけで silent no-op だった。他 PC が `Initialize` で `DeleteStaleSessions` を走らせた瞬間に自 row を DELETE する path (= 自 PC の heartbeat が SMB BUSY / network blip で 30 秒以上遅延 → 別 PC 新規起動の stale cleanup で削除) で、自 PC の heartbeat thread が復帰しても **以降の UPDATE は全部空振り**、他 PC から永久不可視化される。本 PR の主目的 (LAN-wide 同時起動検出) が最初の network blip 後に sustained に機能不全になる致命的 silent failure。`ManagerSessionRepository.UpdateHeartbeat(pcName, heartbeatUnixMs)` を `UpsertHeartbeat(ManagerSessionInfo info)` に signature 変更、内部で `UpsertSelfSession` の `INSERT OR REPLACE` を再利用、row 不在時も自動 reanimate する設計に。`HeartbeatLoop` も `_repo.UpsertHeartbeat(new ManagerSessionInfo { ... })` 呼出に変更、5 field 全部 (PcName / StartedAtUnixMs / LastHeartbeatAtUnixMs / Pid / ManagerVersion) を毎 heartbeat で set。SPEC §3.8.2 + §3.8.4 にも UPSERT 戦略と自動復帰仕様を明示。
- **Medium-1 SPEC §3.8.2 EditOperation 文言を round 2 Medium-1 実装と同期**: 旧 SPEC 本文「このまま保存すると、{operationDescription} の内容と 他 PC の編集内容が...」は round 2 Medium-1 で「**このまま {opLabel} を実行すると、他 PC の編集内容と** お互いに上書きされて消える恐れ」に変更済だったが、SPEC は古い template のまま残置していた SoT 同期漏れ。AGENTS.md「コメント / docstring の記述が実装と一致しているか」(整合性、最重要) 規約違反を解消。
- **Medium-2 SPEC §3.8.2 から削除済 `SettingsKeys.ManagerHeartbeatIntervalSeconds` 参照を撤回**: round 2 Medium-2 で SettingsKeys 側 constant は YAGNI で removal 済だったが、SPEC §3.8.2 の heartbeat 間隔説明では「`SettingsKeys.ManagerHeartbeatIntervalSeconds` 経由 override は future tunability の予約 slot」と削除済 constant を SoT として記述し続ける dangling reference があった。「`ManagerSessionService.HeartbeatIntervalSeconds` private const で hardcoded、override 経路は実装なし、将来 tunability が確定したら settings key 追加 + service 側で読込み実装する」記述に同期更新。
- **Medium-3 SPEC §3.8.4 の「永久不可視化」既知 risk 記述を H-2 修正で消去 + 自動復帰仕様に書換え**: H-2 で UPSERT 化により永久不可視化 path を物理閉鎖したため、SPEC §3.8.4 の「network 切断時の false positive」段落を「永久不可視化 risk + 別 issue で対応」表現から「UPSERT 戦略で blip 回復後に自動 reanimate する tolerance 設計」表現に書換え。「最大 30 秒間は他 PC から自分が唯一と誤判定」path は残るが、blip 回復で自動復帰する旨を明示。完全 network resilience の物理閉鎖は将来別 issue 余地。
- **Low-1 round 2 Low-4 の Dispose try/catch を撤回** (`ManagerSessionService.cs:Shutdown`): `CancellationTokenSource.Dispose()` 自体は idempotent で例外を投げない (MSDN 仕様)。旧 round 2 L-1 / L-4 で「Dispose の race で ObjectDisposedException」と書いた rationale は誤り (実際の noise source は heartbeat loop 側の `WaitOne` 例外)。`try { _heartbeatCts.Dispose(); } catch { }` wrapper を撤回、shutdown trail clean 化の本物の対応は Low-3 と統合して **`_shuttingDown` volatile flag で heartbeat loop 内の race 例外を silent 化** する形に集約。
- **Low-2 heartbeat lambda の late-capture race を解消**: 旧 `Task.Run(() => HeartbeatLoop(_heartbeatCts.Token), _heartbeatCts.Token);` は lambda 内 `_heartbeatCts.Token` が thread pool スケジュール後の遅延評価で、Initialize 直後に Shutdown が走って `_heartbeatCts = null` に set された場合 NRE で task が落ちる theoretical race があった (= startup Cancel-終了 path で発火しうる)。`var capturedToken = _heartbeatCts.Token;` で local capture、lambda は token のみ参照する形に変更。
- **Low-3 heartbeat catch を 2 段階に分け + `_shuttingDown` flag で shutdown race 例外を silent 化** (`ManagerSessionService.cs:HeartbeatLoop`): 旧実装は `try { Wait + Upsert } catch { Logger.Warn("heartbeat update 失敗") }` で Wait 例外 / UpdateHeartbeat 例外 / shutdown race を同じ文言に丸めていて log での原因区別不能だった。新実装: (a) `volatile bool _shuttingDown` field を追加、`Shutdown()` 冒頭で先に set。(b) HeartbeatLoop の try を 2 段階に分け、Wait 部分 / UpsertHeartbeat 部分でそれぞれ catch + exception type を log message に embed。(c) `_shuttingDown == true` 時は silent break で trail を残さず loop 終了。これで shutdown 中の race 例外が log noise を生まず、network blip / SQLite BUSY は明確な exception type で log に残る。

**Round 4 review fix (Medium-1/2/3/4 + Low-1/2/3)** — version bump なし、本 entry に統合:

- **Medium-1 CHANGELOG `Added` 節 `UpdateHeartbeat` → `UpsertHeartbeat` 同期**: Round 3 H-2 で signature 変更 (`UpdateHeartbeat(pcName, heartbeatUnixMs)` → `UpsertHeartbeat(ManagerSessionInfo info)`) したが、CHANGELOG `Added` 節の `ManagerSessionRepository` 5 method 列挙が旧名のまま残置していた SoT drift。Added 節の最初に読まれる reviewer が「`UpdateHeartbeat` という method が存在する」と誤読する path を closure。
- **Medium-2 CHANGELOG `Added` 節から削除済 `SettingsKeys.ManagerHeartbeatIntervalSeconds` bullet 削除**: Round 2 Medium-2 で YAGNI removal 済の constant への dangling reference を Added 節から撤回。Round 2 Medium-2 fix 本文だけ残せば履歴として十分。SPEC §3.8.2 は Round 3 Medium-2 で同期済、CHANGELOG だけ drift していた drift を解消。
- **Medium-3 `TryShowUpdateCompletedDialog` を `void` 化 + docstring の dead invariant 削除**: 旧 docstring の invariant (2) 「本 dialog 表示 (= true 返却) 時は caller が **「同時起動に関する注意」MessageBox を skip する排他置換**」は本 PR で同 MessageBox を撤廃 (#178 (c) 消化) したため成立せず、`MainForm_Load:104` の呼出 `TryShowUpdateCompletedDialog();` は戻り値捨てで bool 返却が dead read。signature を `bool` → `void` に変更、docstring から invariant (2) を削除、現状の単一機能 (= sentinel 読込 + dialog 表示 + sentinel 削除) のみに絞る。
- **Medium-4 SPEC §3.8.5 + CHANGELOG の UI freeze 試算を `ExecuteWithRetry maxRetries=3` 込みに補正**: 旧記述「最大 ~30 秒 UI freeze (= `busy_timeout=10000` ms × 3 query)」は `DatabaseConnection.ExecuteWithRetry` の `maxRetries=3` を計算に入れない誤試算だった。正確な worst case は 1 query あたり最大 ~30 秒、3 query 直列で **最大 ~90 秒**。さらに `OpenConnectionWithJournalMode` の PRAGMA 4 連発で延びる余地あり。SPEC §3.8.5 + CHANGELOG Round 2 Medium-3 entry を `~30 秒` → `~90 秒` に補正、改善余地として「起動時 session check は `maxRetries` を 1 に絞る」案も別 issue 候補として明示。設計判断 (= 学校 LAN での実発生頻度極低、受容仕様) は維持。
- **Low-1 `Initialize()` 冒頭で `_shuttingDown = false;` reset**: Round 3 L-1/L-3 で導入した `_shuttingDown` volatile flag が `Initialize()` で reset されない latent bug があった。現運用 (= 1 process lifetime で 1 回 init / 1 回 shutdown) では実害ゼロだが、将来 test / restart pattern で `Shutdown → Initialize` 再利用すると heartbeat task が初回 iteration で `_shuttingDown == true` を見て即 silent break → 「初期化したつもりが heartbeat 即死、self row が 30 秒後の stale cleanup で消える」silent failure path 予防。`Initialize()` 冒頭 (多重 call check の直後) で `_shuttingDown = false;` 1 行追加して idempotent semantic を完全保証。
- **Low-2 `while/if` 内 `IsCancellationRequested` access を `IsCancelled` helper で wrap**: 旧 HeartbeatLoop の `while (!token.IsCancellationRequested)` (L190) と `if (token.IsCancellationRequested) break;` (L210) は try/catch 外で、.NET Framework 4.8 では CTS.Dispose 後の `IsCancellationRequested` access が `ObjectDisposedException` を投げうる (MSDN 仕様)。Wait(2s) timeout で task が生きてる state で Dispose が走り、loop の条件参照で unhandled exception → `TaskScheduler.UnobservedTaskException` で silent fault する path があった。新 helper `IsCancelled(token)` で wrap、`_shuttingDown` flag check + `try { ... } catch (ObjectDisposedException) { return true; }` で「shutdown 中 = cancelled 扱い」に倒して loop 確実終了。
- **Low-3 `CheckBeforeWrite` callsite のカンマ後スペース統一**: 3 callsite (`BackupSectionPanel.cs:164` / `SettingsSectionPanel.cs:57` / `StoreSectionPanel.cs:96`) で `(this,"...")` のスペース抜けがあった formatting drift を `(this, "...")` に統一、他 10 callsite と一貫させる。機能影響なし、読みやすさのみ。

**Round 5 review fix (Medium-1/2 + Low-1/2/3/4/5)** — version bump なし、本 entry に統合:

- **Medium-1 `btnResetDatabase` 2 段階 check + SPEC §3.8.2 check 位置 invariant 緩和**: 旧設計は「全 callsite で ShowDialog / save 直前に check」だったが、modal form を user が長時間読んでいる間に他 PC が新規起動する race window が残っていた (= SPEC §3.8.2 「DB write 直前」invariant 違反)。**設計判断**: ShowDialog 前 check の UX 親切性 (= user が編集前に他 PC 警告を見て編集作業を無駄にしない) を維持しつつ、最 destructive な `btnResetDatabase` (DB 全削除 + 再構築) のみ **ConfirmForm OK 後にも 2 段階 check** で race fence を厳密化。SPEC §3.8.2 を「ShowDialog 前 check 統一 + btnResetDatabase のみ 2 段階」「modal 内 race window は受容仕様 (= heartbeat UPSERT で永久不可視化はしないため次の操作で検出されるまで warning しない、round 3 H-2 の reanimate 戦略と整合)」に書換え、暗黙 spec 化を解消。
- **Medium-2 SPEC §3.8.5 log level を実装に合わせて Initialize/Detect で分離**: 旧 SPEC「`Initialize` / `DetectOtherActiveSessions` が **Logger.Error** で trail」と一括記述していたが、実装は **Initialize=Error / Detect=Warn** に分離していて log filter / triage 時に齟齬。意図的設計 (Initialize 失敗=機能停止の致命傷、Detect 単発失敗=次回 retry で回復可) を明文化、SPEC を実装に寄せる方向で「Initialize は `Logger.Error` (機能停止)、`DetectOtherActiveSessions` は `Logger.Warn` (次の check で回復可能)」と分けて記述。
- **Low-1 PR description Files changed から `SettingsKeys.cs` 行を削除**: Round 2 Medium-2 で YAGNI removal 済 (= net 変更 0 行) だが PR description は round 1 時点の snapshot で残置していた SoT drift。reviewer が「どの constant?」を探して空振りする時間を防ぐため `gh pr edit 184 --body-file` で削除。
- **Low-2 SPEC §3.8.6 + 変更履歴 v1.10.26 + CHANGELOG の行番号 `L191 / L203 / L1988` 参照を削除**: 本 PR で SPECIFICATION.md に ~80 行追加した結果、追記より下の `§6.5` 周辺 (L1988 と書かれていた) は確実に行番号ズレ。section 番号のみ (`§6.5 / §3.x 序論`) に統一、AGENTS.md / SPECIFICATION.md の他 §3.x 参照と一貫させる。stale 化リスクの物理閉鎖。
- **Low-3 `Environment.MachineName` の dead null fallback を実際の例外 path catch に書換え**: 旧 `_pcName = Environment.MachineName ?? "(unknown)";` は MSDN 仕様で null を返さず取得不能時は `InvalidOperationException` を throw するため null 分岐は dead code。`try { _pcName = Environment.MachineName; } catch (InvalidOperationException) { _pcName = "(unknown)"; }` に書換え、実際の例外 path を catch する形に。実害ゼロだが意図と実装の整合性向上。
- **Low-4 `SessionConflictDialog.Show` の空 list guard を caller の contract に倒す**: 旧 Show 側 `if (others == null || others.Count == 0) return DialogResult.OK;` defensive と、caller (`MainForm.CheckSessionConflictBeforeWrite` / `MainForm_Load`) 側の `if (others.Count == 0) return ...;` で空 list 二重 guard だった。`SessionConflictDialog` は internal sealed class で caller は同 assembly 内に限定 (grep で全数確認可)、`MainForm` 2 caller どちらも事前に `Count > 0` を保証する contract が確立済。Show 側 guard を撤去して thin に保ち、caller contract に責務集約。
- **Low-5 `ComputeInstallPathHash` に `Path.GetFullPath` 正規化追加**: Round 2 Low-2 で `ToLowerInvariant()` 追加したが、Windows path には他にも (a) 8.3 短縮形式 (`PROGRA~1` vs `Program Files`)、(b) 相対 path 解決、(c) 末尾 `\` 有無 の drift 源があった。`Path.GetFullPath(installPath ?? string.Empty).ToLowerInvariant()` で 8.3 展開 + 相対 path 解決 + 末尾 `\` 正規化 + case 統一を 1 段に集約、同 install dir でも呼び方次第で別 mutex に化ける drift を物理閉鎖。`GetFullPath` 自身が invalid char で throw する path は try/catch で生 path fallback。SMB UNC `\\?\` prefix 等は学校 LAN 稀ケースで本 PR scope 外、別 issue 候補に残置。

**Round 6 review fix (Medium-1 案 B フェンス強化)** — version bump なし、本 entry に統合:

- **Medium-1 modal 内 race window を 4 Form の OK button click にも fence 追加 (案 B + 中止=編集画面に戻る)**: Round 5 Medium-1 で「modal 内 race window は受容仕様」と設計判断したが、AddGameForm の file copy が 30 秒 ~ 5 分かかる reality + EditGameForm の編集セッションが 5-10 分 reality を踏まえ、**全 Form の OK button click で DB write 直前にも再 check** する案 B 強化に転換。Cancel 選択時は **`DialogResult.OK` を設定せず Form を閉じない** ことで「中止=編集画面に戻る」semantics、user の入力作業を破棄せず保持する設計に倒した。これで race window を 30 秒 ~ 5 分 → 数秒に圧縮、案 B の最大欠点 (= 編集破棄) を「中止=戻る」UX で解消。実装場所:
  - **`SessionConflictHelper.CheckBeforeWrite` を Form caller 対応に拡張**: 旧 helper は `caller.FindForm() as MainForm` 単段で、`AddGameForm` / `EditGameForm` / `VersionUpForm` / `StoreSectionForm` の OK handler から呼ぶと `FindForm()` が Form 自身を返すため `as MainForm` cast 失敗 → silent skip path に落ちていた。3 段 fallback (`FindForm` → `modalForm.Owner as MainForm` → `Application.OpenForms` 内 `MainForm` 探索) に拡張、各段失敗時の type 情報を Warn log に embed。SectionPanel callsite は (1) で hit するため挙動不変、Form caller は (2) で MainForm に到達。
  - **`AddGameForm.btnOK_Click`**: ProcessingDialog (= 実 file copy) 完了後、`dbManager.AddGame` 直前で check。Cancel 時はコピー済 `destinationGameFolder` を `Directory.Delete(true)` で rollback (既存 L308-320 / L401-411 と同 pattern、削除失敗時は Warn log) + `destinationGameFolder = null;` reset で次回 OK clicked 時の `Directory.Exists` collision 誤検出を予防。`return;` で Form は閉じず編集画面に戻る。
  - **`EditGameForm.btnOK_Click`**: 全 validation / dup-check / rename plan 構築の通過後、最初の DB write (`dbManager.UpdateGameId` を含む ProcessingDialog ブロック) 直前で check。Cancel 時は disk / DB 未変更で `return;` (= rollback 不要)、編集画面に戻る。
  - **`VersionUpForm.btnOK_Click`**: ValidateInput 通過後、`NewVersion` 構築直前で check。Cancel 時は `return;` で Form は閉じない。Note: VersionUpForm 自体は DB write を持たず close 後 caller (`GameSectionPanel`) が `CopyDirectoryWithProgress` + `AddGameVersion` を実行するため、check は pre-copy timing。copy 中の race は依然残る (= 受容仕様、AddGameForm の post-copy fence と非対称だが構造的に止む無し、SPEC §3.8.5 に追記)。
  - **`StoreSectionForm.btnOK_Click`**: title validation + section property 設定後、`AddSection` / `UpdateSection` 直前で check。Cancel 時は `return;` で Form は閉じない。`opLabel` は `_isNew` で「ストアセクション追加」/「ストアセクション編集」分岐。`using GCTonePrism.Manager.Services;` も追加。
  - **SPEC §3.8.2 + §3.8.5 同期**: §3.8.2 を「ShowDialog 前 check (UX 親切性) + Form OK button 内 DB write 直前 check (race fence、案 B、Cancel=編集画面に戻る) の二段 fence」に更新。§3.8.5 に「VersionUpForm 経由のバージョン追加 path は caller (GameSectionPanel) で copy + DB write するため Form 側 check は pre-copy、copy 中の race は受容仕様」段落を追加。

**Round 7 review fix (High-1 + Medium-1/2/3/4 + Low-2/3)** — version bump なし、本 entry に統合:

- **High-1 `BackupSettingsForm.btnOk_Click` に session conflict check 追加 (14 callsite 目の漏れ閉鎖)**: 旧実装は `btnSettings_Click` → `BackupSettingsForm.ShowDialog` → `btnOk_Click` で `backup_destination_path` / `backup_auto_interval_hours` / `backup_retention_count` の 3 件を settings table に INSERT OR REPLACE していたが、ここに session conflict check が**一切なかった** (= PR description / SPEC §3.8.2 / CHANGELOG が「13 callsite で全 DB write を cover」と enumerate していたが、本 callsite のみ silent skip)。「他 PC で `backup_retention_count` を変更 → 自 PC で同 form 開いて別値で OK」path で settings 値が silent 上書きされる、本 PR の主目的「お互いに上書きされて消える恐れ」がそのまま残存する drift。`btnOk_Click` の DB write 直前で `SessionConflictHelper.CheckBeforeWrite(this, "バックアップ設定変更")` を追加、Cancel 時は Form を閉じず編集画面に戻る semantics (= round 6 案 B 同 pattern)。`using GCTonePrism.Manager.Services;` は既存 import あり追加不要。
- **Medium-1 `_sessionService.IsInitialized` property 追加 + `MainForm.CheckSessionConflictBeforeWrite` guard 強化**: 旧実装は `_sessionService == null` のみ short-circuit していたが、`Initialize` 失敗 path (= `_sessionService` non-null + `_initialized=false`) で全 13 SectionPanel callsite が click ごとに `DetectOtherActiveSessions` → `ExecuteWithRetry` (busy_timeout=10000ms × maxRetries=3 = 最大 ~30 秒 block) を空振り → click 毎 UI freeze + Warn log noise の drift があった。`ManagerSessionService.IsInitialized` を public property で expose、`MainForm.CheckSessionConflictBeforeWrite` の guard を `_sessionService == null || !_sessionService.IsInitialized` に拡張して early OK 返却、SPEC §3.8.5「Initialize 失敗は致命傷、検出機能は以降一切働かない」claim と整合。
- **Medium-2 `AddGameForm` session conflict Cancel rollback の delete 失敗時に user 通知 MessageBox 追加**: 旧 round 6 M-1 案 B fence の Cancel rollback で `Directory.Delete(destinationGameFolder, true)` が失敗 (SMB file lock / Launcher 起動中 / 権限不足 etc.) した場合、Warn ログのみで silent 継続 → `destinationGameFolder = null;` reset で「fold 残存のまま rollback 完了したフリ」状態に。user が同 form で再 OK click すると、`CopyGameFolder` の `if (Directory.Exists(destinationGameFolder)) throw "バージョンフォルダは既に存在します"` で **無関係な collision error** として表示される drift があった (= 「session conflict cancel の rollback failure」と読めず混乱)。delete 失敗時に `MessageBox` で「rollback 失敗、手動で `{destinationGameFolder}` を削除してください、編集内容は保持」と通知、user に明示的に next action を促す UX に。
- **Medium-3 `ManagerSessionService.Initialize()` partial-success rollback 追加 (zombie self row 物理閉鎖)**: 旧実装は step (1) DeleteStaleSessions → step (2) UpsertSelfSession → step (3) heartbeat thread 起動 の 3 step を 1 try block で囲んでいたため、(2) 成功 + (3) で例外 (`Task.Run` 直後の OOM / ThreadPool starvation 等、稀だが理論的に発生) で catch に落ちると **self row は DB 登録済 + heartbeat 不在 + `_initialized=false`** という zombie state になり、他 PC からは「自 PC で起動中」と 30 秒間 false positive 検出される drift があった。`bool selfRegistered` flag で step (2) 完了を track、catch 内で `selfRegistered=true` なら `_repo.DeleteSelfSession(_pcName)` で rollback → docstring claim 「DB 不到達は heartbeat 不在で機能退化、self row も残らない」を物理保証。rollback 自体の失敗は stale cleanup に委ねる (= Warn のみ、30 秒以内に他 PC が cleanup)。
- **Medium-4 SPEC §3.8.2 callsite 総数を 13 → 18 に正確化 (round 6 案 B + round 7 H-1 を accounting)**: 旧 SPEC「対象 button は 13 箇所」は SectionPanel 1 段目 fence のみ counted で、round 6 案 B fence で追加された 4 Form OK click 内 callsite + 本 round で追加された `BackupSettingsForm` callsite を accounting していなかった drift。`grep -c "SessionConflictHelper.CheckBeforeWrite"` の hit 数 (実物 18 callsite) と SPEC 表記の乖離を解消、SPEC §3.8.2 を「1 段目 fence 13 callsite (SectionPanel ShowDialog 前 / save 直前) + 2 段目 fence 5 callsite (5 Form OK click 内 DB write 直前)」内訳付きで明示化。
- **Low-2 `ComputeInstallPathHash` を MD5 → SHA256 に移行 (FIPS 環境対応)**: 旧 `MD5.Create()` は `FIPS=enabled` group policy が適用された Windows 環境で `InvalidOperationException ("not part of the Windows Platform FIPS validated cryptographic algorithms")` を throw する path があった。本関数は mutex 取得 **前** に呼ばれるため `Main` の最外 catch がなく、企業 PC 流用の LAN 環境で FIPS 有効化されると Manager が silent crash する drift だった。SHA256 は FIPS 認証 algorithm で policy 影響なし、先頭 16 文字を使う形は維持 (= 衝突回避用途で 64 bit で十分)。
- **Low-3 `HeartbeatLoop` の Warn message から臆測表現 `?` を撤回**: 旧 message 「heartbeat Wait 失敗 (token race?、継続)」の `?` は事実不明 hint だが、実際の例外 type + message は既に embed 済で triage 側は事実から原因判定可能。「heartbeat Wait 例外 (継続)」「heartbeat UpsertHeartbeat 例外 (継続)」のように事実のみ記述に統一、Wait 部分と UpsertHeartbeat 部分の表記揺れ (旧「失敗」/「失敗」) も「例外」に統一して triage 容易化。

**Round 8 review fix (Medium-1/2 + Low-1/2/3/4)** — version bump なし、本 entry に統合:

- **Medium-1 CHANGELOG Round 6/7 section の chronology drift 解消**: 旧 entry 内で round 7 section が round 6 section の **上** に置かれていた drift (= round 7 commit 時に round 6 の上に挿入した形跡)。Round 1〜5 は昇順で、Round 6/7 だけ逆順で時系列履歴として読まれる UX が退行していた。Round 7 entry block を Round 6 entry block の下に move して全 round が昇順に並ぶ形に正規化。
- **Medium-2 `BackupSettingsForm.cs:61` comment の「他 12 callsite」表現を集合関係で書き直し**: 旧 comment 「SectionPanel の **他 12 callsite** は SessionConflictHelper.CheckBeforeWrite で gate 済だが btnSettings だけ漏れていた」は減算表現で、BackupSettingsForm が SectionPanel ではない構造的事実 (= 自分が 13 番目の SectionPanel callsite であるかのような誤読を誘発) と整合しなかった。新 comment は (a) SectionPanel 配下 1 段目 fence 13 callsite は単に form を開くだけ、(b) round 6 案 B 2 段目 fence (4 Form) も BackupSettingsForm は対象外 — の **両方からも漏れていた** という集合関係を明示、SPEC §3.8.2 の callsite 内訳 (1 段目 13 + 2 段目 5 = 18) と直接対応する構造で記述し直す。
- **Low-1 `_heartbeatTask.Wait(2s)` の timeout 戻り値を bool で受けて Warn 出力**: 旧実装は `_heartbeatTask?.Wait(TimeSpan.FromSeconds(2));` の戻り値 (false=timeout) を捨てていて、heartbeat task が UpsertHeartbeat の `ExecuteWithRetry` (busy_timeout=10000ms × maxRetries=3 = 最悪 ~30 秒 block) 中に shutdown が走ると、Wait は 2 秒 timeout で抜けるが heartbeat task はまだ生きていて、直後の `DeleteSelfSession(_pcName)` 実行 → 遅れて UpsertHeartbeat 完了で zombie self row が再登録される silent race があった。30 秒以内に stale cleanup で回収されるため致命的ではないが、log trail を残さないと triage 不能。timeout 経由を bool で受けて `Logger.Warn("...stale cleanup に委ねる (zombie self row が最大 30 秒残存する可能性)")` で trail を残す形に。
- **Low-2 `SessionConflictHelper.CheckBeforeWrite` 3 段目 fallback の `Application.OpenForms` 列挙 race を try/catch で握り潰し**: 旧実装は `foreach (Form f in Application.OpenForms)` を裸で実行していて、enumeration 中に別 thread / 別 event handler で form が `Close` / `Show` されると `InvalidOperationException ("Collection was modified")` を投げて button click handler 自体が unhandled exception で落ちる drift があった。本 helper の主旨「null 経路の silent skip を物理閉鎖」と一貫させるため、3 段目 fallback 自身も例外で落ちないよう `try { foreach } catch (InvalidOperationException) { Logger.Warn(...) }` で握り潰し、catch 後は通常の「mainForm == null → fail-soft OK 返却」path に倒す。1 段目 / 2 段目で 99% は hit するため 3 段目 race は稀 path、Warn trail で triage 可能化のみで足りる。
- **Low-3 `SessionConflictDialog` body の文言を上書き依存から「競合してデータ破損」に書換え (backup 系 callsite との semantic 整合)**: 旧 EditOperation body「他 PC の **編集内容と** お互いに上書きされて消える」は ゲーム / Store / Settings 系には合うが、「バックアップ作成」「バックアップ削除」「バックアップ復元」「バックアップ設定変更」では「他 PC の編集内容を上書きする」関係性が薄く文脈と乖離していた (= 13 callsite のうち 4 件 = BackupSection 3 + BackupSettings 1 が該当)。「他 PC の **作業と競合して**、データが破損したり保存内容が消えたりする恐れ」のように「上書き」「編集内容」依存を撤回した一般語に書換え、全 callsite で semantic 整合。Startup body も同方針で「保存中のデータや バックアップが 競合して、データが破損したり消えたりする恐れ」に書換え。
- **Low-4 `Mutex.ReleaseMutex` 失敗時の Warn message を cause 主題に書換え**: 旧 Warn「Mutex.ReleaseMutex 失敗 (Dispose で abandoned 状態経由): ...」は **失敗 cause** ではなく **その後の Dispose の挙動** を説明していて、triage で読むと cause/effect が逆。実際の典型 cause = mutex を所有していない thread (`ThreadPool` / `Task` 経由等) から release を試みた `ApplicationException` または `AbandonedMutexException` 経由 case。新 Warn は「mutex 非所有 thread からの release 等が typical cause」表現に + 例外 type + message を embed して triage 容易化。docstring の preamble「`using` の Dispose 単独では kernel 上 abandoned mutex 状態を経由する」説明は設計判断の根拠として正しいため retain。

### [Manager v0.9.3] - 2026-05-18

#### Changed (#177 — apply 側 path 解決を manifest 経由化、Phase 4.1+ forward compat 完成)

- **`BundleManifest.Layout` プロパティ + `BundleLayout` POCO クラスを新規追加** (`Services/UpdateDownloader.cs`): manifest の `layout` field を deserialize する optional POCO で、category → zip 内相対 path の mapping を表現する 7 property (`LauncherDir` / `ManagerDir` / `CompanionsDir` / `UpdaterDir` / `LauncherBat` / `ManagerBat` / `ChangelogMd`)。`BundleManifest` クラス docstring を「全 field 追加で `schema_version` bump」(Phase 4.1 round 1 Medium-1 で導入された conservative 規約) → 「**additive optional field の追加は schema bump 不要、breaking change (型変更 / 削除 / semantics 変更) のみ bump**」に修正、本 PR の `layout` 追加が初の additive change 事例として明文化。`BundleLayout` クラス docstring に PR #180 Round 2 Low-2 と同 pattern の「Serializer 切替時の注意」(case-insensitive deserialize 依存) を embed。
- **`ReadBundleManifest` で `layout` を null-safe に deserialize** (同ファイル): 既存 `files` field 取得の隣に `layout` を `TryGetValue` で取得 → `IDictionary<string, object>` cast → 各 key を `TryGetLayoutString` helper で抽出する形に拡張。parse 失敗 / `layout` 不在 / 部分 null は **silent fallback** (`manifest.Layout = null`)、apply 側で hardcoded fallback に倒れる設計。Logger.Info の出力 message にも `layout=present/null` を追加して debug 容易化。
- **`ValidateStaging` signature を拡張** (`out BundleManifest manifest` 引数追加): `ValidateStagingViaManifest` 内で parse 済 `BundleManifest` を caller に流す経路を新設、`ValidateStagingLegacy` 経路 (= v0.3.0 旧構造、manifest 自体不在) では `manifest = null` で out。caller (`UpdateSectionPanel.RunUpdateWorker`) が `manifest?.Layout?.<Key>` 経由で apply 側 path を解決可能になる forward compat 機構。caller は 1 箇所 (`UpdateSectionPanel.cs:489`) のみで同期更新影響範囲は限定的、breaking signature 変更だが impl 時 grep verify 済。
- **`UpdateSectionPanel.RunUpdateWorker` の hardcoded path 6 箇所を `manifest?.Layout?.<Key> ?? "<legacy>"` null-coalesce fallback 形式に書換え**:
  - L534: `stagingLauncher = bundleRoot/files/Launcher` → `manifest?.Layout?.LauncherDir ?? "files/Launcher"`
  - L559: `stagingCompanionsRoot = bundleRoot/files/Companions` → `manifest?.Layout?.CompanionsDir ?? "files/Companions"`
  - L600: `Launcher.bat` → `manifest?.Layout?.LauncherBat ?? "Launcher.bat"`
  - L606: `Manager.bat` → `manifest?.Layout?.ManagerBat ?? "Manager.bat"`
  - L635: `stagingUpdater = bundleRoot/files/Companions/Updater` → `manifest?.Layout?.UpdaterDir ?? "files/Companions/Updater"`
  - L687 (defer): `bundleRoot/files/CHANGELOG.md` → `manifest?.Layout?.ChangelogMd ?? "files/CHANGELOG.md"`
  - これにより v0.3.1 manifest (= layout なし) と v0.3.2+ manifest (= layout あり) を同 code path で処理、将来 `bundle/files/Launcher/` → `bundle/Launcher/` のような dir 構造変更を Manager コード変更ゼロで吸収できる完全 forward compat を獲得。

**スコープ**: Phase 4.1 (PR #175/#176) で validate 側だけ獲得した forward compat (= manifest 経由 file 存在 check) を apply 側にも拡張 (= manifest 経由 path 解決) して片肺状態を解消、Phase 4.1+ 設計を完成。`schema_version=1` 維持 + layout を optional additive field として追加することで Bundle v0.3.1 同梱 Manager (v0.9.1) との互換性も維持 (= リリースノートで約束した「次回以降自動アップデート」を守る)。本 PR は user 視点 invisible な内部 refactor で、現状の release では layout 経由でも legacy fallback でも結果は同一、forward compat 投資は将来の dir 構造変更 PR で初めて報われる。patch bump (v0.9.2 → v0.9.3) で「機能追加だが UX 変化ゼロ」を表現。

**詳細仕様は [SPECIFICATION.md §3.7.7](SPECIFICATION.md) (apply 側 forward compat) + [§3.7.8](SPECIFICATION.md) (新規 component 追加チェックリスト) 参照**。

**Round 1 review fix (High-1 + Medium-1/2/3/4 + Low-1/2/3)** — version bump なし、本 entry に統合 (AGENTS.md「1 PR 内の version bump は原則 1 回のみ」原則):

- **High-1 `UpdateDownloader.ValidateBundleVersion` の hardcoded `files/CHANGELOG.md` 残置を解消**: 初版実装は `UpdateSectionPanel.RunUpdateWorker` の 6 箇所だけ manifest 経由化し、同 file 内の `ValidateBundleVersion` (Step 4 で active に走る) は `Path.Combine(bundleRoot, "files", "CHANGELOG.md")` を hardcoded のまま残していた。同 PR が「Manager コード変更ゼロで dir 構造変更を吸収できる完全 forward compat」と主張する一方、active code path の片方だけ migrate されている inconsistency 状態。signature を `ValidateBundleVersion(string stagingDir, Version expectedVersion, BundleManifest manifest, out Version stagingVer)` に拡張、caller (`UpdateSectionPanel.cs:506`) が Step 3 で取得済の manifest を本関数にも渡す形に同期。これにより Step 4 も `manifest?.Layout?.ChangelogMd ?? "files/CHANGELOG.md"` 経由で forward compat が貫徹。SPEC §3.7.7「apply 側 forward compat」に `ValidateBundleVersion` Step 4 を明示追記。
- **Medium-1 `BundleLayout.ManagerDir` の consumer 不在 (scaffolding) 明示 + 「完全」forward compat 主張後退**: 初版は `manager_dir` を 7 layout key の 1 つとして populate するが、Manager 自身の dir 置換は Updater 責務で Updater (`Companions/Updater/`) は本 PR で touch されていないため `ManagerDir` を読む consumer が repo 内に存在しない (= manifest scaffolding のみ)。Updater 対応は別 PR で消化予定。SPEC §3.7.7 の「完全 forward compat を獲得」主張は **Manager UI apply 経路に限定** (= Launcher / Companion / shortcut bat / CHANGELOG)、`manager_dir` は予約 slot として明示。`BundleLayout.ManagerDir` の docstring に「現状 Manager UI 側からは未参照、Updater 対応 PR で consumer 化予定、本 field は forward compat 計画の予約 slot」を追記、scope を後退させずに将来計画を trail に残す。
- **Medium-2 `BundleLayout` クラス docstring の Serializer rationale を実装と整合させる reword**: 初版 docstring は「`JavaScriptSerializer` の case-insensitive deserialize で互換性が成立」「将来 `System.Text.Json` 切替時に `[JsonPropertyName]` 必要」と書いたが、実装は **POCO 自動 deserialize を一切使っておらず** `ReadBundleManifest` 内で `JavaScriptSerializer.DeserializeObject` → `IDictionary<string, object>` → manual `TryGetValue(literal snake_case key)` で値抽出する dict 経由 manual mapping。serializer の POCO 自動 mapping 挙動 (case-sensitivity / member matching) には依存していない。docstring を「実装は dict 経由で wire key を literal 参照、serializer の POCO mapping 挙動には依存しない。将来 POCO 直 deserialize (`JsonSerializer.Deserialize<BundleManifest>(json)`) に切替えた場合のみ `[JsonPropertyName]` 等の attribute 追加が必要」に reword + 「snake_case ↔ PascalCase は case 差ではなく separator 差 (`_`) のため case-insensitive 自動 mapping だけでは解決できず attribute / camelCase policy 明示が必須」注記。future maintainer が refactor 時に「case-sensitivity だけ気をつければ OK」と誤判断する path を closure。
- **Medium-3 + Low-3 layout silent fallback drift masking 解消 + Logger.Info に populated count 反映**: 初版は `TryGetLayoutString` が dict key 不在 / 値 null で silent に null 返却、`Logger.Info` は `layout=present` / `null` の 2 値のみで partial populate (例: 7 key 中 6 key だけ非 null) を区別しなかった。結果として Release.ps1 で key を misspell (例: `launcer_dir`) しても Manager 側で `LauncherDir = null` → hardcoded `"files/Launcher"` fallback → log は `layout=present` のまま、broken release を success と誤判定する silent drift path があった。`ReadBundleManifest` で `layout` populated count を集計 (`layoutMissing` list)、partial populate 時に `Logger.Warn("BundleLayout partial populate: N/7、apply 側は不足分 hardcoded legacy fallback で動作する (missing: ...)。Release.ps1 ↔ Manager POCO の SoT drift 疑い、新規 key 追加時の同期更新漏れを review してください")` を出力、`Logger.Info` も `layout=present (7/7 populated)` / `(6/7 populated, missing: manager_dir)` 形式に拡張。SoT drift を release 後 runtime に検出する fail-loud path を確保。
- **Medium-4 Layout 経由 path で wire format `/` separator の OS-native 変換を追加**: 初版は `Path.Combine(bundleRoot, manifest?.Layout?.LauncherDir ?? "files/Launcher")` のように `/` separator のまま `Path.Combine` に渡していた (.NET on Windows は `/` も `\` も equivalent で実害ゼロ)。一方 `ValidateStagingViaManifest` 側は `files` field を `rel.Replace('/', Path.DirectorySeparatorChar)` で明示的に OS-native 変換していたため、**同 PR 内で同じ wire format を扱う 2 経路の作法が違う**状態だった。UpdateSectionPanel 側 6 箇所 + `ValidateBundleVersion` (round 1 High-1 で signature 拡張済) を `(manifest?.Layout?.<Key> ?? "<legacy>").Replace('/', Path.DirectorySeparatorChar)` 形式に揃え、in-PR の作法統一を確保。
- **Low-1 SPEC §3.7.8 に layout build-time fence 不在を明記**: `$script:BundleManifestFiles` ↔ `Assert-ExpectedFiles` のような release 時 hard fence は layout には無く、Manager POCO 不在 / mismatch は release を止めない。SPEC §3.7.8 の `$script:BundleLayout` checklist 項目に「build-time fence 不在の注意」を追記、partial populate は `ReadBundleManifest` Logger.Warn で runtime flag、PR review + 手動 E2E test が最終 drift 検出 fence、将来別 issue で `Assert-BundleLayoutPocoSync` 等の追加余地、を expectation として明示化。あわせて新規 key 追加時の同期更新項目数を「3 件」→「**4 件**」(Release.ps1 hashtable / Manager POCO / UpdateSectionPanel apply / `changelog_md` のような ValidateBundleVersion 兼用 key なら caller 同期) に拡張。
- **Low-2 `BundleLayout` property docstring の path base 明示化**: 初版 docstring は `Launcher dir の zip 内相対 path (例: "files/Launcher")` 形式で「zip 内」が zip root 起点か `bundle/` 起点か曖昧 (Release.ps1 側 SoT コメントは「bundle/ 起点」と精密)。実装は `Path.Combine(bundleRoot, ...)` で `bundle/` 起点。各 property docstring を `Launcher dir の bundle/ 起点 zip 内相対 path (例: "files/Launcher" = bundle/files/Launcher)` 形式に reword、Release.ps1 側 SoT コメントと同精度に同期。reader が「zip 内」を `bundle/files/Launcher` vs `files/Launcher` で誤読する path を closure。

**Round 2 review fix (Medium-1 + Low-1/2/3/4)** — version bump なし、本 entry に統合:

- **Medium-2 (再) case-insensitive deserialize 記述の 3 箇所 sync** (round 2 では Medium-1 として再 flag): Round 1 Medium-2 で `BundleLayout` クラス docstring を「実装は dict 経由 manual TryGetValue、serializer の POCO 自動 mapping 挙動には依存しない」に正しく訂正したが、**同 PR 内の他 3 箇所 (Release.ps1 `$script:BundleLayout` 直上コメント / CHANGELOG `## Release Tooling v0.1.18` entry / PR description body) は旧記述「`JavaScriptSerializer` case-insensitive deserialize で wire format と互換」のまま残置** していた整合性漏れ。Release.ps1 / CHANGELOG / PR body の 3 箇所を「未知 field 黙殺 (`TryGetValue` で必要 field のみ取り出し)」+ 「`BundleLayout` 自身は dict 経由 manual `TryGetValue` で literal snake_case key 参照、POCO 自動 mapping には依存しない」+ 「snake_case ↔ PascalCase は case 差ではなく separator 差 `_` のため自動 mapping だけでは不可」に sync 訂正。あわせて PR #180 `UpdateCompletedSentinel` (POCO 直 deserialize で case-insensitive 自動 mapping に依存する case) との設計差異も注記、将来 reviewer が「serializer 切替時は case-insensitive 維持で OK」と誤判断する drift path を closure。
- **Low-1 `ReadBundleManifest` の dead `else` branch 削除**: round 1 Medium-3 + Low-3 fix で `layoutLog` の 4 分岐を追加した際の defensive 残り。`manifest.Layout != null` ⇒ `layoutMissing != null` invariant (両者とも `if (layoutDict != null)` block 内で同時 set) のため最終 `else layoutLog = "present"` は到達不能。3 分岐に圧縮 (`null` / `present (7/7 populated)` / `present (N/7 populated, missing: ...)`) + invariant 由来のコメントを add。読者が「`present` 状態 (count 不明) が起こり得る」と誤読する path を closure。
- **Low-2 layout shape 違反の Logger.Warn 追加**: round 1 Medium-3 で partial populate の Warn を追加したが、これは `if (layoutDict != null)` block 内のみ発火。`dict.TryGetValue("layout", out layoutObj)` が成功しつつ `layoutObj` が `IDictionary<string, object>` 以外 (= 例: `string` や `object[]`、Release.ps1 で書出し誤りで shape を壊した場合) は `layoutDict as IDictionary` が null に倒れ、Warn が出ず `manifest.Layout = null` + Info log は `layout=null` (= layout key absent と同じ表示) で silent drift。`layoutObj != null` かつ `layoutDict == null` の場合に `Logger.Warn("BundleLayout shape 違反: layout field present だが IDictionary 以外の型 (Type)、Release.ps1 $script:BundleLayout hashtable 形式破壊疑い。apply 側は全 key hardcoded legacy fallback で動作する")` を出力、shape 違反 drift も runtime fail-loud に。
- **Low-3 PR description body の「6 箇所」を「7 箇所」に更新**: round 1 High-1 で `UpdateDownloader.ValidateBundleVersion` も layout 経由 sweep に含めた結果、現在は 7 箇所 (UpdateSectionPanel × 6 + ValidateBundleVersion × 1)。CHANGELOG `## Manager v0.9.3` entry の High-1 セクション + SPEC §3.7.7 文言は既に「6 箇所 + ValidateBundleVersion (Step 4、round 1 High-1)」と書いていたが、PR description body だけ round 1 前の数字のまま残置 (= merge ボタン押下前の review entry point で初見の reviewer が ValidateBundleVersion の migration を見落とす path)。PR body を「**7 箇所** (UpdateSectionPanel.RunUpdateWorker × 6 + UpdateDownloader.ValidateBundleVersion × 1、後者は round 1 High-1 で追加 sweep)」に更新。
- **Low-4 `_bundleRootCache` retry path stale を別 issue #183 化** (本 PR scope 外、trail 明示): PR #175 round 2 Low-2 で導入された pre-existing 設計。`Directory.Delete(stagingDir, recursive: true)` + 再 `Extract` 後も cache が invalidate されず stale 値を返す path。実用上は同 release tag の再 DL で同 zip 構造になるため挙動は等価、edge case (= 別 zip 手動配置等) で stale risk。本 PR round 1 High-1 で `ValidateBundleVersion` も `ResolveBundleRoot` を呼ぶ追加 call site が増えて cache surface が拡大、これを trigger に [#183](https://github.com/ken1208git/TonePrism/issues/183) を立てて trail。物理閉鎖は別 PR で消化予定。本 PR では `ResolveBundleRoot` の docstring (`_bundleRootCache` 直前) に「Retry path での stale cache trade-off」段落を追記して将来 reader への注記とする。

### [Manager v0.9.2] - 2026-05-18

#### Changed (#178 (a) — `[A]` 事前確認 dialog の警告色 + LAN 共有運用予告強化)

- **`UpdateSectionPanel.btnUpdateNow_Click` の `[A]` 事前確認 MessageBox を警告色強化** (L320-336): `MessageBoxIcon.Question` → `MessageBoxIcon.Warning`、title 「アップデート開始確認」→ 「**アップデート開始 — 起動中アプリの確認をお願いします**」で意図明確化、body の「Launcher / 常駐ツールが動いていれば事前に閉じる必要があります」を **【重要】ブロック** に昇格 + **「閉じないとアップデートに失敗し、installation が破損する可能性があります」** を強調追記。文言は「**Launcher などシステムに関連するソフト**」と曖昧化 (= 部員に PauseOverlay 等の技術用語を意識させない、Launcher を閉じれば連鎖 cleanup される実装事実とも整合)、**「この PC を含む全ての PC で先に閉じてください」+ 「学校 LAN で共有運用している場合、他 PC で起動中の Launcher も対象です」** を明示 (= SPEC §3.7 で `\\学校サーバー\PCクラブ` SMB 配置運用が想定されており、他 PC で Launcher 実行中だと server 上の launcher.exe が file lock で書換え不能になる問題への暫定対応、user に予告)。button は `YesNo` のまま (= 事前確認の「はい / いいえ」が自然、`MessageBoxButtons.YesNo` は label カスタマイズ不可)。
- **`[A.5]` 起動中プロセスあり MessageBox は本 PR では touch しない** (L350-360 付近、`MessageBoxIcon.Warning` + RetryCancel の現状維持): local file lock 物理安全網として独立した責務 (#179 LAN-wide 検出が完成しても local 同 PC 内の file lock 回避は別レイヤー)。`[A]` 強化で `[A.5]` にたどり着く頻度は激減する見込み。

#### Changed (#178 (b) — アップデート完了 sentinel ファイル + 起動時 dialog 置換)

- **`UpdateSectionPanel.RunUpdateWorker` 末尾で sentinel ファイル `<install>/.update_completed` を書出し**: Updater spawn 成功後、`Application.Exit` 直前 (= 既存の `progress.Report(95, "Manager を終了中...")` 直前) に `<install>/.update_completed` を JSON で書き込み (内容: `{ completedAt: ISO8601 UTC, newVersion: targetVersion.ToString(3) }`、serializer は既存 `UpdateChecker.CacheDto` と同じ `System.Web.Script.Serialization.JavaScriptSerializer`)。書込み失敗は `Logger.Warn` で握り潰し、Application.Exit は続行 (= dialog が出ないだけで installation 自体は完成しているため致命的でない)。
- **`MainForm.TryShowUpdateCompletedDialog` helper を新規追加** (`MainForm.cs` 末尾、bool 返却): `MainForm_Load` 冒頭で呼ばれて sentinel ファイル存在チェック、存在すれば `JavaScriptSerializer.Deserialize<UpdateCompletedSentinel>` で parse → `MessageBox.Show("アップデートが完了しました。\n\n  新しいバージョン: v{newVersion}\n\n新しい管理ソフトが起動しています。", "✓ アップデート完了", OK, MessageBoxIcon.Information)` で完了通知を modal 表示。**設計のキモ**: 既存の「同時起動に関する注意」MessageBox を **置換** する形 (caller の `MainForm_Load` で `if (!TryShowUpdateCompletedDialog()) { 同時起動注意.Show() }` で gate)。起動時 dialog 数は常に 1 つに保たれ、sentinel あり時は完了通知、sentinel なし時は同時起動注意、と排他切替。**sentinel は読込直後の `finally` block で必ず削除** (parse 成功 / 失敗を問わず、永続 dialog 再表示バグ path を物理閉鎖)。`UpdateCompletedSentinel` は private nested class、`completedAt` / `newVersion` 2 field のみ。
- **設計変遷ノート**: 当初 plan では Dock=Top の `pnlUpdateCompletedBanner` Panel + Label + × ボタンで永続 banner 表示する案を実装、smoke test で「消えるのが一瞬すぎ」→「× あるし永続でいい」→「アップデート完了表示はダイアログのつもりやった」とユーザーフィードバックを受けて、banner UI を撤廃して `MessageBox` 置換設計に転換。同時起動注意との二重 dialog を避けるため「同時起動注意の替わり (= 置換)」として 1 dialog 体制を採用。banner UI 関連の Designer 宣言 / Controls.Add / field / ハンドラはすべて新設せず、`MainForm.Designer.cs` への変更行数を最小化 (= 既存 form layout を一切変えない)。

#### Changed (#173 — `Initializing` 状態追加で「最新版を実行中」silent 誤表示を解消)

- **`UpdateCheckStatus` enum に `Initializing` 値を最上位に追加** (`Models/UpdateCheckResult.cs`): cache 不在 + API 未確認の遷移状態を表現する新 status。「最新版を実行中」緑文字 default 誤表示の根本解消。`UpdateChecker.LoadCacheOnly` の cache 不在 path のみが直接代入する設計 (= `ComputeStatus` 経由ではない)。
- **`UpdateChecker.LoadCacheOnly` の cache 不在 path を修正**: 旧 `Status = ComputeStatus(current, null)` → 新 `Status = current == null ? UpdateCheckStatus.UnknownBundle : UpdateCheckStatus.Initializing`。`ComputeStatus` は **触らない** (= `CheckAsync` API 成功 path の `latest == null` を `UpToDate` に倒す既存挙動を維持、Initializing は `LoadCacheOnly` cache 不在 path のみが直接代入する設計)。cache hydrate 経路 (= cache に latest あり) は `ComputeStatus` 経由のままで OK (= cache 由来 latest があるため Initializing にならない)。`current == null` (= UnknownBundle 経路) は従来通り UnknownBundle に倒す。
- **`UpdateSectionPanel.ApplyResult` switch case 追加**: `Initializing` case を `UpToDate` の前に挿入、文言「最新版を確認中...」、`ForeColor = Color.Gray`、`btnUpdateNow.Enabled = false` + `btnSkip.Enabled = false`。background check 完了 (`OnCheckCompleted` 経由 `ApplyResult` 再呼出) で `UpToDate` / `UpdateAvailable` / `NetworkError` 等に上書きされる短命状態。`btnCheckNow_Click` の動的文言「確認中...」と意味一致。
- **`UpdateCheckResult.Status` docstring 更新** (`Models/UpdateCheckResult.cs`): 冒頭に `Initializing` の説明 1 段落を追加 (cache 不在 + API 未確認の遷移状態、`LoadCacheOnly` の cache 不在 path のみが返す、`Latest` は null、background check 完了で上書きされる短命状態、設計判断: `ComputeStatus` 経由ではなく `LoadCacheOnly` で直接代入)。

**スコープ**: Bundle v0.3.0 / v0.3.1 で完成した Manager UI アップデートタブの E2E test 中に観察された 3 件の UX 課題を 1 PR で解消。`[A]` 事前確認の警告色強化 + LAN 共有運用予告 (#178 (a))、アップデート完了通知 banner (#178 (b))、初回起動経路の silent 誤表示解消 (#173)。banner UI 機構は将来 #179 (LAN-wide 同時起動検出) で動的状態切替 banner として再利用予定。**スコープ外**: 同時起動注意 MessageBox 改修 (#178 (c)、PR3 で #179 LAN-wide 検出と統合実装)、Launcher session tracking の自動検出 (#179 issue 本文 update + 実装は別 PR、本 PR は文言で「他 PC 含む」を予告する暫定対応)、Bundle bump (リリース直前のみ)、`[A.5]` 起動中プロセスあり MessageBox 改修 (= local file lock 物理安全網として現状維持、#179 LAN 検出と独立した責務)。patch bump 判断: 既存機能の改善 + 新規 UI 要素追加だが user 視点 invisible な拡張 (sentinel ファイルは next update で初めて意味を持つ) → 0.x 系慣習で patch bump。

**詳細仕様は [SPECIFICATION.md §3.7.3](SPECIFICATION.md) (sentinel ファイル仕様) 参照**。

**Round 1 review fix (High-1/2 + Medium-1/2 + Low-1/2/3)** — version bump なし、本 entry に統合 (AGENTS.md「1 PR 内の version bump は原則 1 回のみ」原則):

- **High-1 SPEC §3.7.3 変更履歴 v1.10.24 row の pivot 漏れ修正**: 既存行が `MainForm.TryShowUpdateCompletedBanner` / 「緑 banner 表示 (5 秒自動消滅 + × ボタン)」と pivot 前の banner 案のまま記述されており、SPEC §3.7.3 本文 + CHANGELOG ## Manager の v0.9.2 entry 「設計変遷ノート」と乖離していた。実装は `TryShowUpdateCompletedDialog` + `MessageBox.Show` 置換設計のため、変更履歴行も同設計に書き換え (method 名 / UI 機構 / 「sentinel banner」→「sentinel dialog」表記統一)。SPEC 変更履歴は audit trail として永続するため、後から v0.9.2 で何を入れたか辿る人を混乱させる drift だった。本 entry の Low-3 圧縮判断と独立した修正で、文言量は変動するが意味整合性を優先。
- **High-2 `UpdateSectionPanel.cs` sentinel 書出しコメントの drift 修正**: sentinel 書出し block 直前のコメント「`MainForm_Load` 冒頭で読まれて **緑 banner を表示する**。書込み失敗は **banner が出ないだけ**で...」を、consumer 側の MessageBox 置換設計に合わせて「`TryShowUpdateCompletedDialog` が読み込んで、『同時起動に関する注意』MessageBox の替わりに『✓ アップデート完了』MessageBox を表示する (= 排他置換、起動時 dialog 数は常に 1 つ)。書込み失敗は dialog が出ないだけで...」に修正。`SPECIFICATION.md §3.7.3` 参照リンクも維持。コメント / docstring と実装の不一致は本リポジトリのレビュー観点で「過去の重大バグはここから出ている」と AGENTS.md で警告されているクラスのため、High 級 fence として処理。
- **Medium-1 MainForm.cs 内 Logger 呼出しの修飾形統一**: 本 PR 新規追加の 3 箇所 (`Logger.Warn` × 2 + `Logger.Info` × 1) を、既存ファイル全体の流儀 `Services.Logger.X` に統一。in-file 流儀混在による grep ヒット数の不一致 / 後続実装者への規約読み取り曖昧化を解消。AGENTS.md Cross-component Standards の MUST は「明示 API 使用」までで修飾形は規定外だが、in-file 統一は read-flow 改善として有効。
- **Medium-2 Initializing 状態 stuck path の docstring 明示** (`Models/UpdateCheckResult.cs`): `StartBackgroundUpdateCheckIfDue` が `dbManager == null` early return / 例外 catch 経路に倒れた場合、`OnCheckCompleted` が発火せず UI は `Initializing` のまま固着する path がある旨を `Status` docstring の `Initializing` 説明段落に追記。**Stuck path 受容**: 旧挙動 (緑「最新版を実行中」誤表示) よりは UX 上良化かつ dbManager null は MainForm 初期化失敗の異常 case で実発生頻度ほぼゼロ、escape は user 手動「更新を確認」button で確保。物理閉鎖 (= catch / early-return で NetworkError 相当を発火) は scope creep のため別 issue 検討で受容。
- **Low-1 sentinel ファイル `completedAt` field の forensic 用途明示** (`MainForm.cs`): `UpdateCompletedSentinel.CompletedAt` プロパティに「forensic 用 (sentinel ファイルを File Explorer で直接見た時に時刻が分かる)。consumer は読み取らない (dialog 文言は `NewVersion` のみで構成)」docstring を追加。SPEC §3.7.3 schema は両 field を仕様として固定化済のため、schema 削除ではなく用途明示で意図を将来 reader に伝える設計に。
- **Low-2 `UpdateCompletedSentinel` プロパティを C# 慣例 PascalCase に rename** (`MainForm.cs`): `completedAt` / `newVersion` (camelCase) → `CompletedAt` / `NewVersion` (PascalCase) に変更。`JavaScriptSerializer` の case-insensitive deserialize により JSON wire format (camelCase) との互換性は維持される (PowerShell 実機で `JavaScriptSerializer.Deserialize<PascalCaseClass>(camelCaseJson)` が値正常代入されることを verify 済)。SPEC §3.7.3 schema も JSON wire 上は camelCase 表記のまま、C# 内部のみ PascalCase 化。private nested class のため外部影響ゼロ。
- **Low-3 MainForm.cs L459-471 コメントブロックを 13 行 → 4 行に圧縮**: 「caller の MainForm_Load で呼ばれて...」「sentinel あり時は完了通知、sentinel なし時は同時起動注意」のような method 本体読めば分かる WHAT 記述を削除、「(1) sentinel ファイルは読込直後の finally で必ず削除 (永続再表示バグ防止)」「(2) 起動時 dialog 数は常に 1 つに保つため排他置換」の 2 invariant のみ保持する 4 行に圧縮。詳細仕様は SPECIFICATION.md §3.7.3 参照リンクで外出し済。AGENTS.md「Default to writing no comments. Only add one when the WHY is non-obvious」基準で WHY 非自明な不変条件のみ残す。

**Round 2 review fix (Medium-1/2 + Low-1/2/3/4)** — version bump なし、本 entry に統合:

- **Medium-1 banner→dialog ログ drift sweep の不徹底解消** (`UpdateSectionPanel.cs:724`): Round 1 High-2 fix で「sentinel 書出し block 直前コメント」の `緑 banner` → `MessageBox` 表記統一を sweep したが、**同 try block の catch ハンドラ内 Warn ログ message** に `"(banner 出ないだけで続行)"` の表記が残置していた漏れ。Round 1 H-2 と同一カテゴリの drift (= 同 try block 内 / コメントは sweep 済 / ログメッセージは漏れ) という対称性の崩れを物理閉鎖。今回 `(dialog 出ないだけで続行)` に書換え。次回類似 PR で同型漏れ防止のため「Round N fix の sweep 範囲」を「同 PR 全範囲の用語 sweep + `git grep` 検出」に拡張する process 改善も検討余地あり (現状の自己ルール化は本 PR scope 外、AGENTS.md 規約強化候補)。
- **Medium-2 + Low-1 同時解消 — dialog 文言の Bundle 文脈明示 + `CompletedAt` の embed 化** (`MainForm.cs` `TryShowUpdateCompletedDialog`): 旧文言「`新しいバージョン: v0.3.2` / 新しい管理ソフトが起動しています」は `newVersion` が **Bundle Version** (`targetVersion.ToString(3)` 由来) でありながら **「管理ソフト」 (= Manager) 文脈** にぐっと寄せた表現で、user から「v0.3.2 は Bundle? Manager?」と曖昧性が残っていた (Bundle v0.3.2 が Manager v0.9.2 を含む実 release を引いた case で特に紛らわしい)。文言を 3 行構成に修正: 「Bundle バージョン: v0.3.2」「完了時刻: 2026-05-18 14:30」「新しい管理ソフトが起動しています」。`CompletedAt` を `DateTime.TryParse` (`AssumeUniversal | AdjustToUniversal`) → `ToLocalTime` → `yyyy-MM-dd HH:mm` で local time format に変換して dialog に embed することで、Round 1 Low-1 fix で「forensic 用」として残した dead field を **実 use case 化** + Round 2 Medium-2 の component 曖昧性を同時解消。`CompletedAt` parse 失敗時は **時刻行を省略して fallback** (= 時刻不在で dialog 自体を skip するより UX 良の判断、`newVersion` のみで dialog 出す)。SPEC §3.7.3 sentinel 仕様 + 変更履歴 v1.10.24 row も同期更新。
- **Low-2 serializer 切替脆弱性 — docstring 追記** (`UpdateCompletedSentinel` class docstring): Round 1 Low-2 fix で property を PascalCase 化 + JSON wire format は camelCase 維持 (writer 側 anonymous type)、`JavaScriptSerializer` の case-insensitive deserialize に依存する設計に。将来 `System.Text.Json` 等の case-sensitive default serializer へ切替時に silent break する risk があるため (= sentinel parse 失敗 → return false → 通常 path に倒れる fail-soft で log にしか痕跡が残らない)、`UpdateCompletedSentinel` クラス docstring に「**Serializer 切替時の注意**: 切替時は wire 名 mapping を再検証、`System.Text.Json` 採用なら `JsonPropertyName` attribute 等で wire 名固定」を明示。serializer 移行自体は本 PR scope 外、debt の明示 trail を docstring に残す形で受容。
- **Low-3 Initializing stuck path を別 issue 化 + docstring に issue 番号 embed** (`Models/UpdateCheckResult.cs`): Round 1 Medium-2 docstring の「scope creep のため別 issue 検討」を **#181 として正式 issue 化** + docstring に issue 番号を embed して「忘れる risk」を物理閉鎖。Round 1 docstring の「user 手動 escape」想定が user が Update tab を開かない場合 escape 不能になる脆弱性 (Initializing 灰色「最新版を確認中...」を「裏で確認中だから待とう」と誤読する path) を踏まえ、catch / early-return での `NetworkError` 発火による物理閉鎖を別 PR で消化する trail を確定。
- **Low-4 progress.Report 段階追加** (`UpdateSectionPanel.RunUpdateWorker`): 旧実装は `progress.Report(85, "Updater を起動中...")` と `progress.Report(95, "Manager を終了中...")` の間に CHANGELOG 置換 + CleanupBak + sentinel 書出しの 3 操作が無音で連続実行され、UI 上は「Updater を起動中... 85%」表示で停滞していた。SSD なら ms 単位だが SMB 共有 / AV scan / 古い HDD で seconds 単位かかる case の体感停滞を緩和するため、`progress.Report(88, "後処理中 (CHANGELOG 置換 + 一時ファイル削除)...")` (= defer block 冒頭) + `progress.Report(92, "完了通知ファイルを準備中...")` (= sentinel 書出し直前) の 2 段階を挿入。実害は軽微だが UX 改善として処理。

### [Manager v0.9.1] - 2026-05-18

#### Changed (#175 Phase 4.1 — Bundle manifest 同梱 + zip 構造整理)

- **`UpdateDownloader.ValidateStaging` を manifest 経由検証に変更 (validate fence drift closure)**: 旧設計 (#108 Phase 4) は Manager 側に hardcoded list (`rootExpected` / `filesExpected`) を持ち、SPEC §3.7.8 同期 fence で Release.ps1 `Assert-ExpectedFiles` と drift 防止していたが、新 release で zip 構造が変わると旧 Manager が新 zip を reject する forward compat 問題があった (PR #161 round 1 C1 で実発生、v0.3.0 → v0.3.1 移行時にも再発見)。新設計では `<staging>/bundle/bundle_manifest.json` を読んで「list 通り存在するか」だけ check、**zip ごとに新 manifest が新 file 構造を表現** するので validate 側 fence の drift を物理 closure (= Manager 側 `ValidateStaging` の hardcoded list を同期更新する規約が不要に)。⚠ **限界 (round 1 High-1 で明示化)**: apply 側 (`UpdateSectionPanel.RunUpdateWorker` Step 5-9 + defer block) の path 参照は `Path.Combine(bundleRoot, "files", "Launcher")` 等で **依然 hardcoded**、将来 `bundle/files/Launcher/` を別 dir 名に変えると validate は通るが apply で fail する partial-state が残る。「Manager コード変更ゼロで全 dir 構造変更を吸収」は overstated、apply 側の manifest 経由化 (= category tag 経由の path 解決) は別 issue で対応予定。manifest 不在 (v0.3.0 zip) は `ValidateStagingLegacy` で旧 hardcoded list fallback。schema_version 1 を想定、`BundleManifest` POCO で deserialize (`Services/UpdateDownloader.cs`)。
- **`UpdateDownloader.ResolveBundleRoot` helper を新規追加 (staging path 解決の中央化)**: staging dir 内の bundle root を解決する helper。manifest あれば `<staging>/bundle` (新構造、v0.3.1+)、無ければ `<staging>` (旧構造 v0.3.0 fallback)。caller (`UpdateSectionPanel.RunUpdateWorker` + `UpdateDownloader.ValidateBundleVersion`) は本 helper で得た `bundleRoot` を経由して `Path.Combine(bundleRoot, "files", ...)` 等で path 解決、新旧両構造を同 code path で扱う forward compat 機構。
- **`UpdateSectionPanel.RunUpdateWorker` の Step 5-9 + defer block + Updater spawn を `bundleRoot` 経由に書き換え**: 旧実装は全 staging path を `Path.Combine(stagingDir, "files", ...)` で hardcoded、v0.3.1 zip 構造 (`bundle/files/...`) で永久 fail する path だった。worker 冒頭で `string bundleRoot = UpdateDownloader.ResolveBundleRoot(stagingDir);` を呼び出し、Step 5 (Launcher) / Step 6 (Companions) / Step 7 (shortcut bat) / Step 9 (Updater) / Step 10 (Updater spawn) / Step 8 defer (CHANGELOG) 全 6 箇所の path 参照を `bundleRoot` 経由に統一。
- **`UpdaterClient.Spawn` の引数を `stagingDir` から `bundleRoot` に rename**: caller (`UpdateSectionPanel`) が bundleRoot 解決の責務を持つ設計。Updater 側 (`Companions/Updater/FileReplacer.cs`) は `--staging <X>/files/Manager` を期待する設計のまま (= 引数の意味は維持、Updater 側コード変更不要で forward compat 獲得)。

**スコープ**: Manager UI update flow の forward compat 獲得 (将来の zip 構造変更を manifest 経由で吸収) + zip 構造整理 (新規ユーザー UX 改善、`bundle/` 配下に集約) の 2 件を 1 PR で。詳細は `## Release Tooling v0.1.17` セクション参照。patch bump 判断: 既存機能の互換性改善 + zip 構造変更は Install.bat の overwrite path で吸収するため user 視点で invisible → 0.x 系慣習で patch bump 扱い (v0.8.10 / v0.8.11 の patch bump 判断と同 spirit)。**Phase 4.1 trade-off**: v0.3.0 install からの v0.3.1 update は新 dir 構造 (`bundle/files/`) を旧 Manager の legacy list が認識できず破綻、手動再 install (Install.bat) が必要。ただし v0.3.0 install は user の dev env (中間 Manager) のみで実 install 他人ゼロのため実害なし、v0.3.1 以降は manifest 経由で永久 forward compat。

**詳細仕様は [SPECIFICATION.md §3.7.7 / §3.7.8](SPECIFICATION.md) 参照**。

**Round 1 review fix (senior Critical-1 + High-1/2 + Medium-1/2/3 + Low-1/2/4、Low-3 process 反省)** — version bump なし、本 entry に統合:

- **Senior Critical-1 (Release.ps1 `Get-Date -AsUTC` PS 5.1 hard-fail)**: `New-BundleManifest` 内の `generated_at = (Get-Date -Format "..." -AsUTC -ErrorAction SilentlyContinue)` + fallback block は PS 5.1 で `-AsUTC` 未対応のため `NamedParameterNotFound` terminating error として `$ErrorActionPreference='Stop'` (Release.ps1 冒頭設定) で abort、hashtable construction 自体が停止して fallback block 永久不到達。`-ErrorAction SilentlyContinue` は parameter binding error には効かない (parameter scope に到達する前に発生する error のため)。次の `Release.bat` 実行で確実に踏む blocker bug を、`[DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")` 直接代入 (PS 5.1/7.x 両対応 + fallback 不要) に統一して修正。
- **Senior High-1 (Manager コード変更なし claim overstated)**: manifest 経由検証は validate 側 fence の drift を物理 closure するが、apply 側 (`UpdateSectionPanel.RunUpdateWorker` Step 5-9) は `Path.Combine(bundleRoot, "files", "Launcher")` 等で **依然 path hardcoded**。将来 `bundle/files/Launcher/` を別 dir 名に変えると validate は通るが apply で fail する partial-state を生む。docstring / CHANGELOG / SPEC の文言を「Manager コード変更ゼロで全 dir 構造変更を吸収」から「validate 側 fence の drift closure (apply 側は限界として明示)」に弱化、apply 側の manifest 経由化 (category tag 経由の path 解決) は別 issue (#177、本 round で作成) で対応予定。
- **Senior High-2 + Medium-3 (manifest parse 失敗時の legacy fallback で必ず fail + bundle/ あり manifest なしの broken release を catch しない)**: 旧実装は `ValidateStaging` の catch block で `ValidateStagingLegacy` に降格していたが、legacy list は staging 直下 `Launcher.bat` を期待するため v0.3.1+ 構造 (`bundle/Launcher.bat`) では必ず 3 件 missing で fail する silent な誤判定。新実装は (a) ResolveBundleRoot で manifest 検出 → 新構造分岐 / 未検出 → 旧構造 or broken 分岐に分けて、(b) `bundle/` あり + manifest なしを「broken release 疑い、再 DL 推奨」の明示 missing sentinel で abort、(c) manifest parse 失敗 / 例外も同 sentinel 経路に統一して legacy fallback への silent 降格を物理閉鎖。
- **Senior Medium-1 (schema_version 検査なし、将来 silent 誤動作)**: `ReadBundleManifest` で `schema_version` 値を POCO 格納するだけで検査せず、将来 `schema_version: 2` で field semantics 変更 (例: files が `{name, sha256}` object 配列に拡張) → `as object[]` cast で偶然 null → silent な validate skip → broken release 誤判定の path があった。`SupportedManifestSchemaVersion = 1` 定数 + `if (manifest.SchemaVersion != SupportedManifestSchemaVersion) return null;` を追加、未対応 schema は parse 不可扱いに降格して broken sentinel 経路に流す形に。
- **Senior Medium-2 (manifest 検出 logic 重複)**: `ResolveBundleRoot` と `ValidateStaging` で同じ predicate (`File.Exists("<staging>/bundle/bundle_manifest.json")`) が literal duplication、manifest path 名 / 位置を変えた時に片方だけ更新する drift bug の温床 (= 本 PR が closure しようとしている同期 fence 自体の再発)。ValidateStaging 冒頭で `ResolveBundleRoot` を呼んで `bundleRoot != stagingDir` で経路分岐する形に SoT 1 箇所集約、新規 helper `ValidateStagingViaManifest` を private 抽出。
- **Senior Low-1 (Updater CLI help text の semantic shift 未反映)**: `Companions/Updater/CliArgs.cs` の `--staging` docstring + Usage 文言は「staging dir のルート」のままで、Phase 4.1 で Manager UI が `bundle root` を渡す semantic shift が反映されていなかった。新規開発者が Updater code から逆引きすると 1 段 mismatch する読みづらさ。docstring + Usage 文言の両方に「Phase 4.1 (#175) 以降は Manager UI が bundle root (`<staging>/bundle`) を渡す形に、Updater 内ロジックは互換維持」と semantic shift を明記。
- **Senior Low-2 (旧構造 fallback log level Warn が alarm)**: `ResolveBundleRoot` / `ValidateStaging` の「manifest 不在 (旧構造 v0.3.0 fallback)」path は v0.3.0 install からの self-update では正常 path だが、`Logger.Warn` で出ていて「実 incident の Warn」を埋もれさせる risk があった。Warn → Info に降格、manifest parse 失敗 / broken release detection (= 真の異常) のみ Error / Warn 維持。
- **Senior Low-4 (SPEC §3.7.7 `bundle/ 配下相対 path` 表現曖昧)**: `$script:BundleManifestFiles` の path 記述が「bundle/ 配下相対」とだけ書かれていて、reader が「bundle/ から数えた path」と「bundle/ 含む path」の両方に解釈しうる曖昧表現。例示「`files\CHANGELOG.md` は zip 内 `bundle\files\CHANGELOG.md` に対応」を SPEC 本文に明示。
- **Low-3 (process 反省、本 round の引き金)**: PR description test plan の `[ ] (merge 後) Release.bat 実行で v0.3.1 zip + GitHub Releases publish` が unchecked のまま PR 出した結果、Critical-1 が review 段階で発見された (本来は smoke test で `New-BundleManifest` 段階の abort を catch すべきだった)。本 round commit 直前に `Release.ps1 -DryRun -SkipUpload` smoke test を必須実行する形に process 修正、AGENTS.md / CONTRIBUTING.md への明文化は別 issue で。

**Codex round 1 false positive 想定**: Phase 4 PR #161 と同様、code 変更 file が多いため codex 側で stale snapshot 由来の false positive が出る可能性。本 round 確定時に判定。

**Round 2 review fix (senior Medium-1/2 + Low-1/2/3/4/5)** — version bump なし、本 entry に統合。Critical / High なし、Round 1 で大物が出尽くした感あり:

- **Senior Medium-1 (PR description test plan の entry 数が古い数字)**: 「zip 内 `bundle/bundle_manifest.json` が存在 + 17 entries 列挙」は旧 `Assert-ExpectedFiles $expected` (zip root 5 + files 12 = 17) の数字で、新 manifest は `$script:BundleManifestFiles` ベース = `bundle/` 直下 3 + `bundle/files/` 配下 12 = **15 entries**。PR description を「15 entries (= `$script:BundleManifestFiles` 件数)」に書き換え。`Assert-ExpectedFiles` の `Write-Ok` 表示は `(zip root 3 + bundle 15)` で正しく報告される。
- **Senior Medium-2 (PR description test plan の v0.3.0 → v0.3.1 シナリオが trade-off と矛盾)**: 「v0.3.0 zip clean install → v0.3.1 検出 → manifest 経由検証で全 file OK → 完走」は本 PR の trade-off 宣言 (= 「v0.3.0 install の旧 Manager は新 zip 構造を validate できない」) と直接矛盾。manifest 経由 path は **v0.9.1 (本 PR) 以降の Manager にのみ存在**、v0.3.0 install 同梱の v0.9.0 Manager は旧 hardcoded list で apply するため新 zip 構造を必ず reject。test plan を 3 phase に再構成: (1) v0.3.1 publish 検証 / (2) v0.3.1 install を base にして次 release を mock 配信する正経路 verify / (3) v0.3.0 install からの自動更新が validate 段階で必ず abort することの明示確認 (= trade-off の実機 verify)。
- **Senior Low-1 (Install.bat error message が新 path 未反映)**: `[FAIL] files/ ディレクトリが見つかりません: "%FILES_DIR%"` の文言は `%FILES_DIR%` が `bundle\files` に変更された後も「files/」のままで、user が「`bundle/` がないのか `bundle/files/` だけ無いのか」を判別できない。文言を「bundle/files/ ディレクトリ」に修正 + 「zip 直下に bundle/ フォルダがある状態で実行してください」hint + Phase 4.1 zip 構造の説明を追加。
- **Senior Low-2 (`ResolveBundleRoot` の 3 回呼出による log noise)**: 1 update worker 実行で `ValidateStaging` 冒頭 + `ValidateBundleVersion` 冒頭 + `RunUpdateWorker` Step 5 直前の 3 箇所から呼ばれ、それぞれ `File.Exists` + `Logger.Info` を実行していた構造的副作用 (round 1 Medium-2 で SoT 集約した結果の caller 側再呼出 cost)。`_bundleRootCache` (Dictionary<string, string>、OrdinalIgnoreCase、lock 保護) を private static で追加、stagingDir ごとに 1 度だけ解決して以降は cache 返却。worker 1 回ごとに新規 staging dir のため cache 肥大は最大数 entries に留まる。
- **Senior Low-3 (manifest filename SoT が 2-3 箇所に分散)**: `$ManifestPath` (Release.ps1:278) + `$zipRootExpected` (Release.ps1:1822) + `UpdateDownloader.ResolveBundleRoot` の 3 箇所で `"bundle_manifest.json"` literal hardcoded、filename 変更時に片方だけ更新する drift bug の温床 (= 本 PR が `$script:BundleManifestFiles` で closure した同期 fence と同型の問題が manifest 自身に残っていた)。Release.ps1 側で `$script:ManifestRelativePath = 'bundle\bundle_manifest.json'` 定数化、`$ManifestPath` 計算 + `Assert-ExpectedFiles` の `$zipRootExpected` 両方で参照。Manager 側は `UpdateDownloader.ManifestFileName = "bundle_manifest.json"` const 化、`ResolveBundleRoot` + broken sentinel 4 箇所 全部で参照。layer (Release.ps1 と Manager) は別 SoT 系列で各別管理が筋。
- **Senior Low-4 (`ValidateStagingViaManifest` の `Directory.Exists` dead branch)**: 旧実装 `if (!File.Exists(full) && !Directory.Exists(full))` は schema_version 1 では `$script:BundleManifestFiles` 全 entries が file path のみ (dir entry なし) のため事実上 dead branch。`if (!File.Exists(full))` 1 行に簡素化 + 「将来 dir entry 許容なら本 check + schema_version bump で再導入」design intent をコメント明示。
- **Senior Low-5 (missing-list の path separator 不揃い)**: `ValidateStaging` が exception message に流す missing list の path separator が経路で不揃い: ① broken-release sentinel `"bundle/bundle_manifest.json (...)"` (forward slash hardcoded)、② manifest 経路 missing `Path.Combine("bundle", relWin)` (backslash)、③ legacy 経路 missing `Path.Combine("files", ...)` (backslash)。Windows 上の表示で broken sentinel だけ separator が違うため user 視点の path 表記感が崩れる。broken sentinel の 3 箇所 (`ValidateStaging` の bundle/ あり manifest なし path + `ValidateStagingViaManifest` の parse 失敗 / 例外時) を全部 `Path.Combine("bundle", ManifestFileName)` 経由に統一して backslash 揃え。

**Codex round 2 false positive 想定**: round 1 と同様、過去 round で fix 済の項目を再 flag される pattern が継続する可能性、本 round 確定時に判定。

### [Manager v0.9.0] - 2026-05-14

#### Added (#108 Phase 4)

- **Manager UI に「アップデート」タブを追加**: Bundle / Manager / Launcher / Updater / DB schema の 5 component version を 1 画面で表示、起動時にバックグラウンドで GitHub Releases API を叩いて新版検出 (6 時間 cache、`update_check_*` settings key 経由で永続化)、累積更新ノート (v0.2.0 → v0.5.0 のような飛び越え更新で v0.3.0 / v0.4.0 / v0.5.0 全部の release notes を WebBrowser + Markdig HTML render で表示)、「このバージョンをスキップ」(`update_skipped_version` settings key、次 release が出るまで黙る)、「ブラウザで詳細を見る」(GitHub Releases ページ直リンク) を実装。`MainForm.cs:CleanupZombieStagings` で前回失敗 staging (`%TEMP%/GCTonePrism_update_*`) を起動時に best-effort 削除。
- **Manager メイン画面表示時の新版検出 → MessageBox 通知**: 起動時 background check で `Status == UpdateAvailable` の場合 `MainForm.ShowUpdateAvailableNotification` が「新しいバージョンが利用可能です」+ 「現在 vX.Y.Z / 最新 vA.B.C」+ 「『アップデート』タブを開いてリリースノートを確認しますか？」MessageBox を `MessageBoxButtons.YesNo` で表示、Yes で `tabControl1.SelectedTab = tabUpdate` 自動切替、No で「あとで」(次回起動時 cache TTL 内なら再通知抑止、TTL 超過なら再表示)。「このバージョンをスキップ」(タブ内 button) を押されている場合は上位で `Status = Skipped` に変わるため本通知はそもそも呼ばれない (= 「次 release が出るまでダイアログ出ない」semantic を `UpdateChecker.ShouldNotify` の `latest != skipped` 判定で構造的に保証 — round 3 L-5 で `latest == skipped` のみ Skipped 扱い (`<` も `>` も notify 可)、`<` 経路は ComputeStatus 上位で `latest <= current` なら UpToDate に倒れるため実際に notify されるのは「downgrade 後の latest > current」case のみ、に厳密化済)。MessageBox は `Invoke` で UI thread に同期 marshal (round 5 L-1 で `BeginInvoke` → `Invoke` 変更、fire-and-forget で window 破棄済み時の `InvalidOperationException` が catch されない経路 closure)、form 破棄済み時の `InvalidOperationException` を握り潰す fault tolerance。
- **「今すぐアップデート」フロー完全実装** (SPEC §3.7.3 [4]〜[11]): button click で `ProcessingDialog` 経由 worker (`UpdateSectionPanel.RunUpdateWorker`) が以下を順次実行。(1) 起動中プロセス (Launcher / Companions) 検出 + 手動 close 待機 (自動 kill しない、`MessageBox.RetryCancel`)、(2) ディスク容量 pre-check (zip サイズ × 3)、(3) zip DL with `IProgress<DownloadProgress>` (5-40%、cancellable)、(4) staging 展開 to `%TEMP%/GCTonePrism_update_<ver>/` (40-50%)、(5) ExpectedFiles 検証 (50-55%、`UpdateDownloader.ValidateStaging`)、(6) staging CHANGELOG.md の Bundle ver 一致検証 (55-60%、zip 改竄 / 取り違え検出)、(7) ここから cancel 無効 (half-state 防止): Launcher dir rename-rollback 置換 (60-67%、`DirReplacer.Replace + CleanupBak`)、(8) Companions/<Updater 以外>/ dir 列挙置換 (67-70%、現状対象なし、将来 WindowProbe / PauseOverlay 用)、(9) `<install_parent>/Launcher.bat` / `Manager.bat` shortcut bat 単体 file 置換 (70-72%、`FileReplacer.ReplaceFile`)、(10) Companions/Updater dir 置換 (77-82%、常に staging の新 Updater で置換、SPEC §3.7.3 [10])、(11) Updater spawn with `--caller-pid Process.GetCurrentProcess().Id` (85-95%、`UpdaterClient.Spawn`)。**defer (Updater spawn 成功後、失敗は warn 継続)**: `<install>/CHANGELOG.md` 単体 file 置換 (`FileReplacer.ReplaceFile`) + 各置換 dir の `.bak` 一括 cleanup (`DirReplacer.CleanupBak`)。round 5 M-1 で旧 Step 8 の CHANGELOG.md 置換を Updater spawn 後に移動 (partial-state で `VersionInventory` が NEW を読み「最新版を実行中」誤表示する path を closure)、round 4 codex P1 で CleanupBak も同 defer に集約 (途中 throw 時 .bak は次回起動時 zombie detection で消化)、round 7 M-1 + L-2 で本 block 全体を try/catch wrap (`FileReplacer.ReplaceFile` の rollback-fatal `InvalidOperationException` throw → `Application.Exit()` skip の silent partial-state を closure、CleanupBak loop も 1 件ずつ try/catch)、round 8 M-1 で defer block に `[Step 8/10]` log label を割り当てて worker log の番号欠番 (Step 7 → Step 9 飛び) を closure。**最終**: `Application.Exit()` で Manager 自身終了 → Updater が Manager dir 置換 + 新 Manager.exe 起動を引き継ぐ。
- **開発環境ガード** (`<install>/.git` 検出): repo 内で動いている場合 (= dev 環境) は適用前に MessageBox で stop、ソース dir (Launcher/ / Manager/ / Companions/) の物理上書きによる事故を防ぐ。本番 install (Install.bat 展開後) には `.git` は存在しないので通常運用に影響なし。
- **新規 services**: `Services/GitHubReleaseChecker.cs` (HTTP client、TLS 1.2 明示、UA / Accept / X-GitHub-Api-Version header)、`Services/UpdateChecker.cs` (cache + skip + force refresh のオーケストレーション)、`Services/ChangelogParser.cs` (Release.ps1 `Get-BundleReleaseNotes` の論理同型 C# 移植、`### [Bundle vX.Y.Z]` 抽出 + 累積 entry 抽出 `GetBundleEntriesBetween`)、`Services/VersionInventory.cs` (5 component version 採取 + fail-soft null)、`Services/MarkdownRenderer.cs` (Markdig wrapper、`UseAdvancedExtensions` 無効 + `DisableHtml` でセキュリティ、累積 HTML 結合 `BuildCumulativeHtml`)、`Services/DirReplacer.cs` (Updater `FileReplacer.cs` の round 7-8 改善版を論理同型で写経、Launcher / Companion dir 置換用)、`Services/FileReplacer.cs` (shortcut bat 用単体 file 置換)、`Services/ProcessTerminator.cs` (Launcher / Companion 起動中 process 検出 + 待機 + kill)、`Services/UpdateDownloader.cs` (zip DL with `IProgress<DownloadProgress>` + staging 展開 + ExpectedFiles 検証 + Bundle version 一致検証)、`Services/UpdaterClient.cs` (Updater spawn with `--caller-pid` + `RedirectStandardError=true` + `StandardErrorEncoding=UTF8` + `BeginErrorReadLine` で 4KB deadlock 回避 + exit code 0-8 dispatch)、`Services/SettingsKeys.cs` (settings key 定数集約、typo 防止)。
- **新規 models**: `Models/ReleaseInfo.cs` (GitHub API `tag_name` / `body` / `published_at` / `assets[]` の POCO)、`Models/UpdateCheckResult.cs` (`UpdateCheckStatus` enum + 結果 wrapper)。
- **WebBrowser コントロール IE11 mode 設定**: `Program.cs:TrySetIE11EmulationMode` で HKCU registry `FEATURE_BROWSER_EMULATION` に自 exe を IE11 (11001) で登録、リリースノート HTML が default IE7 quirks mode で render 崩れする問題を回避 (best-effort、失敗してもアプリ起動継続)。
- **PathManager 拡張**: `LauncherDir` / `ManagerDir` / `UpdaterExePath` / `UpdaterDir` / `CompanionsDir` / `UpdaterLogDir` / `InstallParentDir` (`<install_parent>/Launcher.bat` 等の shortcut bat 用) / `BundleChangelogPath` (= `<install>/CHANGELOG.md`、Phase 4 SoT、SPEC §3.7.7) / `StagingRootForUpdate(version)` / `EnumerateZombieStagings` を追加。
- **csproj 変更**: `<Reference Include="System.Web.Extensions" />` (JavaScriptSerializer for GitHub API JSON parse) + `<Reference Include="System.IO.Compression" />` + `<Reference Include="System.IO.Compression.FileSystem" />` (zip 展開) + Markdig 0.37.0 (NuGet)。

**Round 7 review fix (senior H-1 / M-1 / M-2 / M-3 / M-4 + L-1 / L-2 / L-3、codex L-7 false positive)** — version bump なし、本 entry に統合:

- **Senior H-1 (UpdateCheckResult docstring 再訂正)**: round 6 M-1 で「UpToDate も Latest 非 null 保証」と書いた docstring は `UpdateChecker.ComputeStatus` の `if (latest == null || latest.Version == null || latest.Version <= current) return UpToDate;` を見落としており、`latest == null` (= API fetch 失敗 + cache 無 + Current のみ取得成功 cases) でも UpToDate に倒れる経路が抜けていた誤訂正。Latest 非 null 保証は **UpdateAvailable / Skipped のみ** (= ComputeStatus が `latest != null && latest.Version != null && latest.Version > current` 条件でこの 2 status に分岐) に戻し、UpToDate / NetworkError / ParseError / UnknownBundle は Latest null あり得ると明記。
- **Senior M-1 + L-2 (CHANGELOG ReplaceFile throw + CleanupBak 連鎖失敗で Application.Exit skip)**: Updater spawn 成功後の defer block 内 `FileReplacer.ReplaceFile(staging CHANGELOG.md, install CHANGELOG.md)` は round 2 H4 で導入された rollback-fatal 経路で `InvalidOperationException` を throw する可能性があり、旧 `if (!ReplaceFile(...))` 形式では throw を外に逃がして worker catch (`RunUpdateWorker` 末尾) で rethrow → CleanupBak loop + `Application.Exit()` が skip → Updater が timeout (exit 3) で死ぬ silent partial-state があった。docstring「CHANGELOG 置換失敗は致命的ではない」前提と乖離。本 block を try/catch (Exception) で wrap して Warn log のみで継続する形に揃える。あわせて L-2 として `foreach (string repDir in replacedDirs) DirReplacer.CleanupBak(repDir)` ループも 1 件ずつ try/catch wrap、1 dir cleanup 失敗で残り dir の .bak 処理 + `Application.Exit()` が skip するのを防ぐ (.bak 残置は次回起動時の zombie .bak detection 経路 — `DirReplacer.Replace` 冒頭で target + .bak 同時存在 → 前回 partial → .bak 削除 — で消化されるため致命的ではない)。
- **Senior M-2 (CHANGELOG entry step 順序の実装乖離)**: 本 entry の「今すぐアップデート」フロー step 説明が round 4 codex P1 (CleanupBak defer) + round 5 M-1 (CHANGELOG.md 置換 defer) 後の実装と乖離していた (旧 entry: `(10) CHANGELOG → (11) Updater → (12) spawn → (13) Exit`、実装: `(10) Updater → (11) spawn → (12) [CHANGELOG + CleanupBak defer] → (13) Exit`)。AGENTS.md 規約「レビュー対応コミットの最後で必ず CHANGELOG description を現実装に揃える」抵触のため step 番号を 12 番化 + defer 説明 + round 4/5/7 ref を明記。
- **Senior M-3 (CHANGELOG entry `latest > skipped` / `BeginInvoke` 表記の実装乖離)**: 同 entry の `ShouldNotify` 判定説明「`latest > skipped` で構造的に保証」は round 3 L-5 で「`latest == skipped` のみ Skipped (= `!=` で notify)」に厳密化済の文言乖離。`ShowUpdateAvailableNotification` の「`BeginInvoke` で UI thread に marshal」も round 5 L-1 で `Invoke` 同期化済 (fire-and-forget で `InvalidOperationException` を catch できない経路 closure) のため `Invoke` 表記に訂正。round 6 で漏れた sweep を round 7 で消化。
- **Senior M-4 (TrySetIE11EmulationMode の no-op Logger.Warn)**: round 6 M-3 で `TrySetIE11EmulationMode` の catch に `Logger.Warn` を仕込んだが、`Program.Main` の旧順序が `TrySetIE11EmulationMode() → Logger.Initialize()` で `Logger.Warn` 時点で Logger 未初期化 → Logger 内部で no-op、round 6 M-3 fix は「docstring に合わせたフリ」だった (= path 不到達)。`Logger.Initialize()` を `TrySetIE11EmulationMode()` より前に reorder する 1 行 swap で本物の fix に。catch 内コメントの「Logger 初期化前 path も safe」も「Logger 初期化済前提 + Logger 内部例外のみ防御 (AGENTS.md「Logger 自体の障害は握り潰す」原則)」に書き直し。
- **Senior L-1 (Release.ps1 ↔ ChangelogParser regex literal 不整合)**: SPEC §3.7.8 (round 6 L-4 で追記) が「Release.ps1 `Get-BundleReleaseNotes` regex と ChangelogParser `BundleEntryRegex` は literal 一致」と謳ったが、Release.ps1 line 224 / 879 は `^### \[Bundle v` (literal space)、ChangelogParser.cs は `^###\s+\[Bundle\s+v` (`\s+` = tab 受理) で literal mismatch があった。`\s+` 側が tolerant (将来 tab 混入で Release.ps1 silent skip 防止) のため **Release.ps1 を `\s+` に寄せる** 形で同期 (= ChangelogParser 側を狭くせず両者 same behavior)。
- **Senior L-3 (ValidateBundleVersion docstring の false case 区別欠如)**: `UpdateDownloader.ValidateBundleVersion` は (a) staging CHANGELOG 読込/parse 失敗 → `stagingVer == null` + `false` 返却、(b) staging Bundle version != expectedVersion → `stagingVer != null` (mismatch 値) + `false` 返却 の 2 case を持つが、docstring は parse 失敗のみ言及。caller (UpdateSectionPanel) が UI 表示文言を分岐するための contract を明示。
- **Codex round 7 false positive 1 件 (`line 174`)**: round 2 M7 で fix 済の literal sync を re-flag されたもの、コードに変更なし。

**Round 8 review fix (senior M-1 / M-2 / M-3 / M-4 + L-1 / L-2 / L-5 / L-6 / L-7、L-3 / L-4 defer)** — version bump なし、本 entry に統合:

- **Senior M-1 (worker `[Step N/10]` 番号欠番)**: round 5 M-1 で旧 Step 8 の CHANGELOG.md 置換を Updater spawn 後の defer block に移動した際、`Services.Logger.Info("[UpdateSectionPanel] [Step X/10] ...")` の番号 label が `Step 7 → Step 9 → Step 10` の **8 番欠番** + defer block 無番号のまま残置されていた。round 2 M9 で「code 内部 step 番号 = `[N/10]` 表記を SPEC §3.7.3 番号と並列管理」原則を立てた直後の self-violation。defer block 冒頭の `Services.Logger.Info` に `[Step 8/10] CHANGELOG.md 置換 + .bak cleanup (defer: Updater spawn 成功後)` label を割り当てて旧番号回復、log を読むユーザーから「Step 8 で abort してログが切れた?」と誤読される path を closure。
- **Senior M-2 (FileReplacer rollback-fatal docstring の caller 契約乖離)**: round 2 H4 で `FileReplacer.ReplaceFile` に rollback 失敗時の `InvalidOperationException` escalate を導入した際、docstring に「caller (`UpdateSectionPanel.RunUpdateWorker`) 側で IOException と区別して MessageBox で『手動復旧要』を示せるようにする」と書いた contract が **実装と乖離**していた (= Step 7 caller は `if (!ReplaceFile(...)) throw new IOException(...)` で type 区別なし、`InvalidOperationException` は worker 末尾の汎用 `catch (Exception)` 経由 ProcessingDialog の generic error MessageBox に流れる)。実態は **`InvalidOperationException` の Message body に手動復旧手順 (`手動で .bak を target にリネーム...`) を embed して汎用 MessageBox 経由 user に到達させる** 設計のため、docstring を Message embed 形式に表現訂正。専用 catch (`catch (InvalidOperationException)`) + UX 別 dialog 化は round 9+ UX 改善 issue 候補。
- **Senior M-3 (CheckFromApiAsync の API 失敗で `UpdateCheckLastAtUnixMs` stamp 漏れ → 学校 LAN rate limit 集団自殺)**: `UpdateCheckLastAtUnixMs` の stamp が success path (`SaveCache` 直後) のみで実行されていたため、API 失敗 + fallback cache 返却経路で stamp skip → TTL 切れ + 持続失敗で起動毎に `CheckFromApiAsync` → API 再ヒット → 失敗を loop する path があった。`SettingsKeys.UpdateCheckLastAtUnixMs` docstring (round 1 M4 で立てた「学校 LAN 50 PC 同時起動 + 60 req/hour rate limit mitigation」claim) と実装 mitigation の path 不整合。`nowMs` 計算直後 (失敗判定より上位) に stamp を移動、成功/失敗 path 共通で TTL stamp が進む形に。success path 末尾の旧 stamp 呼出は削除 (重複防止)。
- **Senior M-4 (CHANGELOG entry の defer block 説明が step (12) として一覧に混在)**: round 7 M-2 で「step 番号を 12 番化 + Updater spawn 後 defer block の説明追記」と訂正した本 entry の step 説明は、(1)-(11) が「順次実行」粒度の step を列挙する中で (12) だけが「post-spawn 動作」を直書きする粒度ズレを抱えていた。step (1)-(11) で打ち止め、`**defer (Updater spawn 成功後、失敗は warn 継続)**:` を独立サブ見出しに分離、`Application.Exit` も `**最終**:` 独立サブ見出しに分離。半 commit boundary (= Updater spawn 成功 = ここから「致命的にしない」phase 突入) の semantic が読み手に伝わる形に。
- **Senior L-2 (`SaveCache` の silent fail で診断 trail なし)**: `SaveCache` の `catch { /* 致命ではない、無視 */ }` 空 catch は round 5 M-2 で Cumulative を cache に追加して以降、典型 30 release × 30KB ≈ 900KB が `MaxJsonLength = 1024 * 1024 (1MB)` を超え得る silent fail path を持つようになっていた (画像 base64 embed や長文 release notes で実害可能性あり)。round 6 M-2 sweep 規約 (silent path に Logger.Warn 仕込み) と非対称。`catch (Exception ex)` で受けて `Logger.Warn("[UpdateChecker] SaveCache 失敗 (cache 不更新): " + ex.Message)` 1 行追加、MaxJsonLength 超過 / SQLite 書込み失敗等の診断 trail を残す (MaxJsonLength 拡張は warn 流量の観察後に判断)。
- **Senior L-5 (`GetReleasesBetweenAsync` が GitHub API natural order 信頼)**: docstring「新しい順 (= API の natural order、published_at desc) で返す」claim はあるが Manager 側 sort なしで API 応答順に依存していた。API 仕様変更 / pagination cursor 変更で順序が異なった場合、累積表示 (`MarkdownRenderer.BuildCumulativeHtml`) が予期せぬ順序になる risk があった。filter 後に `filtered.Sort((a, b) => b.Version.CompareTo(a.Version))` を追加して Manager 側 SoT 化、API 順序非依存に (`System.Version` の IComparable 経由 SemVer 3-part numeric 比較、in-place `List<T>.Sort` で `LINQ OrderByDescending` より microopt)。
- **Senior L-6 (`webReleaseNotes_Navigating` の `Process.Start` 空 catch)**: release notes 内 URL click の `Process.Start` 失敗が `catch { }` で空握り潰し、「click したのに何も起きない」UX + 診断 trail なし。同 class の `btnOpenBrowser_Click` 等の他 catch は MessageBox + Logger 双方を残しているため非対称。URL click は連続発火し得る (link hover→click の高頻度 path) ため MessageBox 連発を避けて `Logger.Warn("[UpdateSectionPanel] release notes 内 URL の browser launch 失敗: url=... ex=...")` のみ追加。
- **Senior L-7 (`UpdaterClient.TryLoadLastExitCode` の `[FATAL]` regex が dead code)**: regex `^\[\d{4}-\d{2}-\d{2}.*\]\s*\[(ERROR|FATAL)\]` の `|FATAL` 分岐は Updater 側 Logger (`Companions/Updater/Logger.cs`) が `Logger.Fatal(...)` API を持たず INFO/WARN/ERROR の 3 レベルのみで dead code (`Companions/Updater/FileReplacer.cs:260` の `Logger.Error("FATAL rollback: ...")` は **`[ERROR]` レベルで Message body に "FATAL" 文字列を含む** 形のため `[ERROR]` 部分が既にマッチして失敗判定に流れる)。regex を `^\[\d{4}-\d{2}-\d{2}.*\]\s*\[ERROR\]` に縮小、Updater 側に `Logger.Fatal` を追加する場合は本 regex を `(ERROR|FATAL)` に戻す対称同期 fence を comment で明示 (Manager / Updater Logger の規約整合は SPEC §3.6 で管理)。
- **Senior L-1 (MainForm の `Task.Run` 冗長、inline 取り込み)**: `MainForm.StartBackgroundUpdateCheckIfDue` の `Task.Run(() => checker.CheckAsync(...))` は `CheckAsync` が HttpClient.GetAsync 経由の真の async (UI thread をブロックしない) のため `Task.Run` で thread pool 1 つ消費 + 直ちに async state machine に戻る overhead が無駄だった。直接 `await checker.CheckAsync(...)` に置換、`StartAutoBackupIfDue` 側は synchronous な `BackupService.RunAutoBackupIfDue` を呼ぶため `Task.Run` 必要で対比的に本 path は不要、と comment 明示。当初 defer 予定だったが 1 行 fix のため round 8 の最終 sweep で inline 取り込み。
- **L 系 defer 2 件 (merge 後 follow-up issue 候補)**:
  - **L-3**: 初回起動経路で `LoadCacheOnly` の cache 不在 + Current 取得成功 path が `ComputeStatus(current, null)` → `UpToDate` default に倒れて「最新版を実行中」緑文字表示 → API 未叩き状態と区別不能。専用 status enum (`Initializing` 等) 追加要、UX 改善範囲が大きいため別 issue。
  - **L-4**: `ProcessTerminator.EnumerateRunning` が Companion 名を `"GCTonePrism_" + Path.GetFileName(companionDir)` で推定、AGENTS.md「Naming Conventions」で予告された `Companions/Common/` 等の disambiguation (`GCTonePrism_<Parent><Name>` 形式) の Companion が将来追加された時に false negative する path。Updater のみ運用中の現状は dead code 同型、SPEC §2.4 拡張時 (WindowProbe / PauseOverlay / Common 追加) に再点検する別 issue。

**Codex round 8 false positive 想定**: round 7 と同様、過去 round で fix 済の項目を再 flag される pattern が継続する可能性が高い (codex は最新 snapshot のみ見て commit 履歴を辿らない挙動)、本 round 確定時に判定。

**詳細仕様は [SPECIFICATION.md §3.7.3 / §3.7.7 / §7.5.1](SPECIFICATION.md) 参照**。Updater 側は本 PR で改修なし (Phase 3 v0.1.0 をそのまま `--caller-pid` 含む既存規約で呼び出す)。

### [Manager v0.8.11] - 2026-05-14

#### Added (#158)

- **`SemverInputControl` (新規 UserControl)**: SemVer 形式バージョンを `[Major] . [Minor] . [Patch] -[suffix]` の 3 NumericUpDown + 任意 suffix TextBox で入力する共通 control を `Manager/Controls/` に追加。単一 TextBox 自由入力で起こりがちなフォーマットゆれ (`1.0.0` / `v1.0.0` / `1.0` / 全角ピリオド / 空白混入 等) を **数値入力で構造的に排除**。`VersionString` getter は常に `v<X>.<Y>.<Z>[-<suffix>]` 形式を返すので呼出側は trim / 正規化不要。`BumpPatch()` public method を 1 個提供 (VersionUpForm.Form_Load で「currentVersion + Patch+1 default」を実現するのに使う、= 暗黙の「迷ったら Patch」UX)。

#### Changed (#158)

- **`AddGameForm` の version 入力**: `txtVersion` (TextBox 100×19) を `semverInput` (`SemverInputControl` 300×28) に置換。OK 押下時に `SemverInputControl.IsValid` で suffix の文字種を検証 (= 数値部は NumericUpDown で構造的に正しい)。default 値 v1.0.0 は維持。
- **`VersionUpForm` の version 入力**: `txtNextVersion` (TextBox) + `lblVersionHint` (静的文言) を `semverNext` (SemverInputControl) に置換。Form 起動時は `currentVersion + BumpPatch()` で「次は Patch+1 が default」表示 (= 部員はそのまま OK で patch bump 完了、別の bump が要るなら数値を直接編集する flow)。SemVer 概念解説 / Major/Minor/Patch 使い分け / bump button 等の learn-by-UI 機構は **本 PR では実装せず、#133 ゲーム制作ガイドライン (GAME_SUBMISSION_GUIDE.md) で文書として用意する方針** (= 部員は新規ゲーム制作時に同 doc を読む前提、UI を minimal に保つ)。
- **`EditGameForm` の バージョン番号 入力**: `txtVersionName` (TextBox 225×19、ゲーム情報編集タブ右側の `バージョン番号` 入力欄) を `semverVersionName` (SemverInputControl 300×28) に置換。LoadGameDataForVersion で `version.Version` を SemverInputControl に流し込み (`VersionString` setter が `v?(\d+)\.(\d+)\.(\d+)(-...)?` regex で parse)、SaveGameDataToVersion で `semverVersionName.VersionString` を `version.Version` に書き戻す。OK 押下時に `IsValid` check (suffix 文字種、Q2 重複 check の前) を追加して不正 suffix を block。これで AddGameForm / VersionUpForm / EditGameForm 全 3 form の version 入力が同じ NumericUpDown × 3 + suffix UI に統一される。

#### Fixed (#158 Q2 / Q3 — pre-existing UX hazards in EditGameForm)

- **EditGameForm でバージョン重複検出** (Q2): `game_versions` table が `(game_id, version)` UNIQUE 制約を持たないため、ユーザーが EditGameForm の `txtVersionName` で 2 つの version を同名にすると DB に同 (gameId, version) row が並ぶ silent danger があった (= Launcher 側で「どちらの version か」決定不能)。`btnOK_Click` 冒頭に **app-level 重複 check** を追加: `cmbVersionList` 全 item の Version 文字列を GroupBy で重複検出 → 重複あれば MessageBox + return で block。表示中 version が未 commit の場合に備えて `SaveGameDataToVersion(currentSelected)` を check 前に呼んで最新値で判定。schema migration による物理的 UNIQUE 制約追加は別 issue 候補 (= 既存 DB 内に既に重複が眠っている可能性、migration 失敗 path を別途検討要)。
- **EditGameForm でバージョン変更時の per-version folder rename** (Q3): `PathManager.GetVersionFolder(gameId, version)` 規約 (= `<install>/games/<gameId>/v<version>/`) で per-version folder が物理存在するが、EditGameForm でユーザーが `txtVersionName` を v1.0.0 → v1.0.1 に変更しても **DB の version 文字列だけ書き換わって disk 上の folder 名は古いまま** という drift があった (= Launcher が新 version で起動を試みて「ファイルが見つからない」エラー path)。`LoadVersions` 時に `_originalVersionByDbId: Dictionary<int, string>` snapshot を capture、`btnOK_Click` で各 version の Version 文字列が変わっていれば対応する `<gameFolder>/v<old>/` → `<gameFolder>/v<new>/` を `Directory.Move` で rename。同名衝突 (新 dir 既存) は abort、旧 dir 不在は警告ログのみで DB 更新継続 (= AddGameForm 経由しなかった version 等の防御)。あわせて DB の relative path (`executable_path` / `thumbnail_path` / `background_path`) の `v<old>/` prefix を `v<new>/` に新規 helper `ReplaceVersionPrefix` で書き換え (前方一致のみ、conservative)。

**スコープ**: SemVer 入力 UI hardening (= ユーザー視点の新機能なし、入力 UI の安全性 / 学習コスト改善) + EditGameForm の pre-existing silent corruption fix 2 件 (Q2 / Q3、本 PR レビュー中に user 質問で発覚)。並行 PR (#161 #108 Phase 4) も Manager v0.9.0 に bump 中で 衝突回避のため **patch 扱い** (= 配布構造変更込みの過去 v0.8.10 patch bump pattern と同 spirit)。`AddGameForm` / `VersionUpForm` の caller (= MainForm 経由のゲーム追加 / バージョンアップ flow) は変更なし、入力 UI と OK 押下時の挙動のみ拡張。本 PR の **初期設計 phase の 3 巡目** (= senior review 開始より前、commit a46b328) で SemverHelpControl (collapsible 解説 panel) と bump button × 3 を削除して minimal な構成にした (= 解説は #133 ガイドラインに移管する設計判断、本 entry 末尾の "Round N review fix" 段落は senior review N 巡目を指すので別軸)。

**Round 2 review fix (codex P1×1 + senior H/M/L 系)** — version bump なし、本 entry に統合:

- **CX-1 (P1) folder rename を 2-phase 化**: 旧実装は「N 件目で `Directory.Move` 失敗 → return」で disk 上に部分 rename 残存 + DB 未更新の drift で launcher が「rename 後 disk」「rename 前 DB」を見て該当 version 起動失敗の silent corruption が起きていた。Phase 1 で全件衝突 check + `RenamePlan` 計画作成、Phase 2 で順次 rename + 例外時は完了済を逆順 `Directory.Move` で rollback、rollback 失敗は console log のみで継続して MessageBox に集約報告 (DB は touch しないので OK 押下前状態に戻る)。
- **CX-2 (P2) `TryParseAndSet` overflow 検出**: NumericUpDown Min/Max 超 (例: `v120.0.0`) を silent clamp で `v99.0.0` に化けて `ok=true` 返却していた問題。範囲外を parse 失敗扱いに変更し caller (= MessageBox 警告経路) に通知、値自体は依然 UI 整合のため Clamp で v0.0.0 / 上限値強制設定。
- **CX-3 (P2) 大文字 `V` 受理**: `VersionRegex` が `^v?` で小文字限定だったため `V1.2.3` 等が malformed → silent v0.0.0 fallback で別 version 化していた。`RegexOptions.IgnoreCase` 追加で受理、`VersionString` getter は常に小文字 `v` で正規化出力。
- **H-1 行番号 drift 解消**: `EditGameForm.cs` の rename loop コメントに残っていた `(line 559)` 参照 (実際は 583) を `(直前の gameIdChanged block で `gameFolder = newFolder` に上書き済)` のシンボル参照に書き換え。今後の行ずれで rot しないように。
- **H-2 `VersionUpForm` ctor MessageBox を `Form_Load` に移動**: ctor 中に MessageBox を出すと Form 未 Show で owner=null → 別 window の裏に隠れる / DPI 再計算前で表示崩れ / ctor 例外を caller が握り潰すと silent skip、の risk があった。Show 後の Load タイミングに統一し EditGameForm 側の per-version 警告と一貫性確保。
- **M-1 dup check を構造比較に**: `semverNext.VersionString == currentVersion` の生比較は DB の `1.0.0` (v 無し) / `V1.0.0` (大文字) を素通しして同義 version の重複登録を許していた。`SemverInputControl.TryNormalize(string, out string)` static helper を新規追加、両辺を正規化形 (`v<X>.<Y>.<Z>[-suffix]`) に変換してから比較。
- **M-2 `BumpPatch` saturate を doc 明記**: `Patch=999` で呼ぶと値が変わらず VersionUpForm 側の dup check で蹴られる挙動を XML doc に追記 (silent corruption ではないが API 利用者への明示)。
- **M-3 malformed version 警告を `LoadVersions` で 1 回まとめ表示**: 旧実装は `LoadGameDataForVersion` で per-version 表示時に MessageBox 発火、DB に複数 malformed があると dropdown 切替ごと OK 連打させられる UX。`LoadVersions` 段階で全件事前 scan → 1 個の MessageBox に id 一覧で集約、per-version 警告は撤去 (fallback 入力自体は残置)。
- **L-1 `(L3)` review-round 識別子コメント削除**: 外部参照不能な internal review note の漏れ、対象コメントごと削除 (内容は自明な `using` 指摘)。
- **L-2 `SaveGameDataToVersion` 二重呼び出し削除**: dup-check 直前 (line 497) と後段 (line 671) で同 selectedVersion に対して 2 回呼ばれていたが、間の処理 (gameId / folder rename) は selectedVersion フィールドを変えないため後者を削除して 1 回呼び出しに統一。
- **L-3 `AddGameForm.IsValid` を `ValidateInput` に統合**: 旧実装は「古いゲームデータの確認」MessageBox 後に suffix check が来ていたため、不正 suffix 入力時に長文確認を読まされてからエラーに戻される UX だった。`ValidateInput` 末尾に統合して既存 validation と同タイミングで弾く。
- **L-4 (#164 として follow-up issue 化)**: `LoadGameDataForVersion` の pre-existing 二重代入 (`txtDescription.Text` / `txtVersionDescription.Text`) は本 PR で touch しないため別 issue で消化。
- **L-5 (CX-3 で自然解消)**: `ReplaceVersionPrefix` の case 不整合は CX-3 の上流 fix (= IgnoreCase 受理 → 入力時点で大文字 V を吸収) で実用上カバー。
- **#163 dead button cleanup を本 PR に取り込み (Round 1 で別 issue 化からの撤回)**: `btnApplyVersion` / `btnVersionUp` の `Visible=false` + Designer dead declaration + `// Deprecated` event handler stub + 方針不明 leftover コメントを完全削除。当初は scope drift 回避のため #163 で別 PR 化したが、senior reviewer から「PR #162 の review item として上げた以上本 PR で潰すのが筋」の指摘を受けて取り込み・#163 close。本 round 2 fix 群とは独立。

**Round 3 review fix (codex P2 NEW + senior H/M/L 系)** — version bump なし、本 entry に統合:

- **H-1 (silent path) 全 version の suffix を OK 時に事前 scan**: 旧実装の `semverVersionName.IsValid` は **現在 dropdown で表示中の 1 個** しか検証しておらず、ユーザーが version A の txtSuffix に「鈴木」等の不正値入力 → dropdown を version B に切替 (= `cmbVersionList_SelectedIndexChanged` 経由で `SaveGameDataToVersion(A)` により A.Version が in-memory commit) → そのまま OK 押下、で末尾の `dbManager.UpdateGameVersion(v)` で bad value が DB に流れ込む silent path があった。`SemverInputControl.IsSuffixValid(string)` static helper 新規追加、`btnOK_Click` で `cmbVersionList.Items` 全件を suffix scan + 不正があれば id 一覧で 1 つの MessageBox に集約 block (M-3 と同 pattern)。
- **H-2 (CX-3 regression) 大文字 V → 小文字 v rename 衝突 abort 解消**: round 2 CX-3 で `VersionRegex` を IgnoreCase 受理にした副作用で、DB に `V1.2.3` があった version は `SaveGameDataToVersion` で `v.Version = "v1.2.3"` に正規化 → rename loop の `string.Equals(originalVer, v.Version, Ordinal)` が false → `Directory.Move("vV1.2.3" → "v1.2.3")` を試みるが Windows FS は case-insensitive で同フォルダを hit → "移動先フォルダが既に存在します" abort。比較を `OrdinalIgnoreCase` に変更、case-only 差は rename skip + DB は normalized 値で書き戻す形に。
- **M-1 (overflow 文言) 3 軸別々の Min/Max を表示**: `TryParseAndSet` の overflow エラー文言が `numMajor` の Min/Max (= 0-99) を 3 component 全部の範囲として表示していた誤記。Designer は Major=99 / Minor=999 / Patch=999 と異なるため、軸ごとに「Major (= X) は 0-99 の範囲です」のような個別文言に変更。
- **M-2 (docstring dangling) `<summary>` 順序整理**: round 2 で `TryNormalize` を `TryParseAndSet` の上に挿入した際、元 docstring が dangling して `TryNormalize` の hover doc に紛れ込んでいた状態を解消。両 method の上にそれぞれ正しい `<summary>` を配置。
- **M-3 (PR doc 同期)**: PR description の H2 fix 段落を round 2 M-3 の警告位置移動 (per-version → LoadVersions 集約) を反映する形に書き換え (= 別途 PR description 編集で対応、コード変更なし)。
- **M-4 (UpdateGameVersion 失敗で rename rollback)**: CX-1 の rename 2-phase は rename 失敗だけ rollback 対象にしていたため、Phase 2 全件成功 → `UpdateGameVersion` が SQLite 一時的失敗等で例外 → disk は新 version 名 / DB は旧名のまま、の silent drift が再発しうる経路があった。`UpdateGameVersion` ループも try/catch で囲み、DB 例外時は完了済 rename を逆順 `Directory.Move` で rollback + MessageBox + rethrow。
- **CX-4 (P2 NEW) `int.TryParse` 戻り値 check**: regex の `\d+` は Int32 範囲外も match するため、`v999999999999.1.0` 等を流すと `int.TryParse` が false 返却 + major=0 のまま range check `0 in [0,99]` を pass → `ok=true` で「parse 成功 + 値 0」silent corruption。`TryParseAndSet` / `TryNormalize` 両方で `int.TryParse` 戻り値を check、false なら overflow 同様 parse 失敗扱い。
- **L-1 snapshot コメントの `(#158 L4)` ID 撤去**: コメントの "L4" が CHANGELOG 上の L-4 (= #164 follow-up issue) と意味衝突していたため、ID 撤去 + 内容主導 wording に書き換え。
- **L-2 AddGameForm の `version` ローカル使い回し統一**: line 282 で local キャプチャ後、line 364 / 380 で再度 getter 呼び出しになっていた可読性 / 変更ぶれ防止違反を、3 箇所すべて local 経由に統一。
- **L-3 `SuffixRegex` を SemVer 2.0.0 §9 strict 準拠に**: 旧 regex `^[a-zA-Z0-9.\-]*$` は `..` / `.foo` / `foo.` 等の空 identifier を許容して仕様コメント (= 「SemVer 2.0.0 仕様準拠」) と乖離していた。`^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*$` に変更で空 identifier 不可。エラー文言も「空の identifier (`..`, `.foo`, `foo.` 等) は使えません」を追記。

**Codex round 3 false positive 2 件**: CX-2 (overflow clamp) / CX-3 (大文字 V) は round 2 で fix 済の内容を re-flag されたもの。コードに変更なし、無視 (= codex は本 PR の commit 履歴をたどらず最新 snapshot のみ見る挙動のため、CHANGELOG entry 内に CX-2 / CX-3 の記述があると再検出する模様)。

**Round 4 review fix (codex P1 NEW + senior H/M/L 系)** — version bump なし、本 entry に統合:

- **Round 4 codex P1 (in-memory state rollback)**: CX-1 (rename 失敗) / round 3 M-4 (DB 失敗) 両 rollback path は disk Move を逆順実行するが、in-memory state (`_originalVersionByDbId` snapshot 更新 + `GameVersion.{Executable,Thumbnail,Background}Path` の prefix 書き換え) は revert していなかった。同 dialog で再 OK 押下時に diff check が false (snapshot が NEW 化済) で rename skip → DB に NEW 値 + 旧 disk folder 名で書き込む silent drift が再発する経路。`RenamePlan` に `Old{Executable,Thumbnail,Background}Path` 追加で path 書き換え前を capture、新規 helper `RollbackCompletedRenames` で disk Move 戻し + in-memory state restore を共通化、両 catch 経路から呼び出し。
- **H-1 (TryNormalize range check)**: `TryNormalize` は `int.TryParse` 戻り値 check (CX-4) は持つが NumericUpDown Min/Max 照合を意図的に省略していたため、`LoadVersions` の事前 scan が `v120.0.0` (Major > 99) や `v0.1000.0` (Minor > 999) を素通しして malformed 判定されず、user が dropdown 選択 → silent clamp で `v99.0.0` に化けて DB 上書きの corruption 経路があった。`MaxMajor=99 / MaxMinor=999 / MaxPatch=999 / MinComponent=0` const を追加 + ctor で Designer.cs との同期を defensive assert + `TryNormalize` の終端で range check 追加。
- **M-1 (大文字 V leaf 構築の case 不整合)**: CX-3 で大文字 V を regex 受理にした副作用で、`oldLeaf` 構築の `StartsWith("v")` が case-sensitive だと `oldVer="V1.2.3"` で `"vV1.2.3"` の歪な leaf が生成され、`ReplaceVersionPrefix` が DB 上の `v1.2.3/main.exe` を no-op skip → disk は新フォルダ名 / DB は旧 prefix のまま、で起動失敗の corruption。新 helper `ToVersionLeaf` (`TrimStart('v', 'V')` で先頭 v/V を一度剥がして小文字 v 被せ直し) を導入、rename loop と `ReplaceVersionPrefix` 両方で利用。
- **M-2 (CHANGELOG label 衝突)**: 同 entry 内で `M-3` ラベルが round 2 M-3 (warning 集約) と #163 cleanup の 2 箇所で衝突していたため、後者を「#163 dead button cleanup を本 PR に取り込み (Round 1 で別 issue 化からの撤回)」の無番号 wording に変更。
- **M-3 (CHANGELOG "Round 3" timing)**: SemverHelpControl + bump button 削除 (commit a46b328) は senior review 開始より前 (= 本 PR 初期設計 phase の 3 巡目) なので「Round 3 で削除」と書くと "Round N review fix" 表現と紛らわしい。「初期設計 phase の 3 巡目 (senior review 開始より前、commit a46b328)」と書き換え。
- **L-1 (semverParseErr dead receiver)**: `LoadGameDataForVersion` の `string semverParseErr; ... out semverParseErr` を `out _` discard に置換、「意図的に discard」を文法レベルで明示。
- **L-2 (rename ProcessingDialog)**: per-version rename ループに ProcessingDialog なしで多版時の UI フリーズ risk があるが本 PR scope 外、follow-up [#165](https://github.com/ken1208git/TonePrism/issues/165) で別途消化。
- **L-3 (重複 IsValid 意図明示)**: `btnOK_Click` の表示中 1 個 IsValid と全件 scan の 2 段検証は UX 用途が違うので片方削除しないこと、をコメントで明示。
- **L-4 (見送り)**: VersionRegex の leading zero 受理は senior reviewer 自身も「見送り推奨」のため対応なし。
- **L-5 (AddGameForm SoT 明示)**: `semverInput.VersionString = "v1.0.0"` (AddGameForm.Designer.cs) と `numMajor.Value = 1` (SemverInputControl.Designer.cs) の 2 段で偶然 v1.0.0 になることをコメントに明示、SoT 主は前者であり後者依存しないことを書く。

**Codex round 4 false positive 3 件**: CX-2 / CX-3 (round 2 で fix 済) と round 3 M-4 (rollback) を re-flag されたもの、コードに変更なし。

**Round 5 review fix (codex P1 NEW + senior H/M/L 系)** — version bump なし、本 entry に統合:

- **Round 5 codex P1 (partial DB commit drift)**: `VersionRepository.Update` は call ごとに独立 transaction で commit するため、M-4 ループで N 件目失敗時に 0..N-1 件目は既に DB commit 済の状態で `RollbackCompletedRenames` を呼ぶと commit 済 row が指す新 folder 名を消失させて drift 拡大。`dbSucceededCount` を track し、(a) `==0` なら従来通り disk + in-memory rollback、(b) `>0` なら disk rollback skip + 「partial commit 状態」の詳細 MessageBox + Manager 再起動を促す形に分岐。
- **Senior H-1 (MessageBox 文言と clamp 結果の矛盾)**: round 4 H-1 で `TryParseAndSet` が NumericUpDown 範囲外を parse 失敗扱いにした結果、range overflow ケースは UI 値が `v0.0.0` ではなく Clamp で上限値 (例: `v99.0.0`) に張り付くが、VersionUpForm / EditGameForm の警告 MessageBox は「v0.0.0 にフォールバック」固定文言で残っていた。VersionUpForm 側は `BumpPatch` 後の `semverNext.VersionString` を本文に動的挿入「現在の表示値: vX.Y.Z」に変更、EditGameForm 側 (LoadVersions 集約警告) は「v0.0.0 または上限値に clamp」表現で UI 確認を促す形に変更。
- **Senior M-1 (VersionRegex / SuffixRegex の規則乖離)**: round 3 L-3 で `SuffixRegex` を SemVer §9 strict 寄せにしたが `VersionRegex` の suffix capture `[a-zA-Z0-9.\-]+` は緩いまま放置されていたため、`v1.0.0-..foo` が LoadVersions 時の `TryNormalize` 全件 scan は素通し、OK 時の `IsSuffixValid` 全件 scan で初めて reject される 2 段検出のずれがあった。VersionRegex の suffix capture を SuffixRegex の inner pattern (`[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*`) と揃えて Load/OK で同規則に統一。
- **Senior M-2 (docstring 誇大表記)**: SuffixRegex の docstring「SemVer 2.0.0 §9 strict 準拠」は厳密には §2 leading zero check を満たさず誇大。「概ね準拠 (round 4 L-4 で leading zero 見送り判断)」表現に弱める。
- **Senior L-1 (dead using 削除)**: `EditGameForm.cs` の `using System.Text.RegularExpressions;` は本 PR で suffix 検証を `SemverInputControl` に寄せた結果 unused、削除。
- **Senior L-2 (SoT コメント精度向上)**: round 4 L-5 のコメントが Major=1 default のみ言及していて Minor/Patch も `NumericUpDown.Value` class default (=0) に依存している事実を隠していたため、両者を明示する wording に修正。
- **Senior L-3 (dead defensive condition)**: `TryParseAndSet` の `else if (majorOk && (major < ...))` の `majorOk &&` は直前の `if (!majorOk || ...)` で false 確定経路を弾いた後なので到達不能、削除して可読性向上。
- **Senior L-4 (field 宣言位置)**: `currentDisplayingVersion` field がメソッド直後に挿入されてフィールド集約規約を破っていたため、`_originalVersionByDbId` の隣に移動。
- **Senior L-5 (SourceExists=false 経路の rollback 対称性)**: `SourceExists=false` ブランチでも path/snapshot mutation はするが `completedRenames` に追加されず `RollbackCompletedRenames` の対象外だった。`RenamePlan.MoveDone` flag を導入、SourceExists=false でも `MoveDone=false` として `completedRenames.Add(p)` し、`RollbackCompletedRenames` は `MoveDone=true` のみ disk Move を試行 + in-memory revert は全 entry で実行する形に統一。

**Codex round 5 false positive 4 件**: CX-2 / CX-3 / round 3 M-4 / round 4 codex P1 を re-flag されたもの、いずれも fix 済でコードに変更なし。

**Round 6 review fix (codex P2 NEW + senior H/M/L 系)** — version bump なし、本 entry に統合:

- **Senior H-1 (M-4 catch 二重 MessageBox)**: round 5 codex P1 で追加した M-4 catch ブロック末尾の `throw;` が outer `catch (SQLiteException) / catch (Exception)` に再投され、partial-commit / 安全 rollback 両 path で必ず汎用「ゲームの更新に失敗しました」MessageBox が 2 枚目として表示される UX bug があった。`throw;` を `return;` に変更、form は閉じず DialogResult は default (None) のまま、user に修正リトライ / Cancel 選択肢を残す形に。
- **Round 6 codex P2 (dup check 正規化欠如)**: 旧 `GroupBy(v => v.Version)` は raw 文字列 key で過去 DB の `v1.0.0` / `1.0.0` / `V1.0.0` を別 key 扱い → semantic 上は重複なのに通る silent danger (= Q2 fix の裏口再オープン)。`GroupBy` キーを `SemverInputControl.TryNormalize` の正規化結果に変更、parse 失敗 (= malformed) は raw value を fallback key として別扱い (M-1 全件 scan で別途 block されるため重複 collapse は不要)。MessageBox 文言にも「v 大文字/小文字・leading v 有無は同一視」を明記、生値群も併記して原因を見せる。
- **Senior M-1 (LoadVersions 警告 non-blocking で silent v0.0.0 corruption)**: LoadVersions 集約警告 MessageBox は notice であって block ではないため、user dismiss → そのまま OK で raw malformed v.Version が DB に書き戻る silent path があった。`btnOK_Click` に `TryNormalize` 全件 scan + block を追加 (= H-1 全件 suffix scan と同 pattern、最終防衛線)。**既知の残存 path** として「currently-displayed の malformed が dup-check 直前 SaveGameDataToVersion で clamp 値に上書き済 → TryNormalize succeed → 本 scan で catch できない」を comment 明記、LoadVersions 警告での user 認知 + UI clamp 表示 visibility に頼る (= 表示中 version は user の目に入っているはず)。
- **Senior M-2 (Phase 1 衝突 check が chained rename 非対応)**: 旧 `Directory.Exists(newDir)` は disk 現在状態だけ見ていたため、同 OK 内で chained rename (例: A→B / B→C) があると A→B 計画が「B が既存」で abort、user は「B→C で B が空くこと」を発見不能で詰む。renamePlan 全件の oldDir を `reservedOldDirs: HashSet<string>` (OrdinalIgnoreCase) で「予約済み slot」扱いに集約、`Directory.Exists(newDir) && !reservedOldDirs.Contains(newDir)` で真の衝突のみ block。循環 rename (A→B / B→A) は両方の oldDir が両方の newDir でもあるため互いに skip → Phase 2 で先行 Move の newDir 衝突で fail する経路に流れる (rollback 経路は CX-1 で整備済のため許容)。
- **Senior M-3 (コメント line drift)**: `// (#158 L-2) ... (line 497 付近) ...` の hardcoded 行番号が実際の call site (約 80 行ずれ) と乖離していた。round 2 H-1 と同 pattern でシンボル参照「`SaveGameDataToVersion(currentSelected)` 呼び出し (dup-check ブロックの直前)」に書き換え。
- **Senior L-1 (Console.WriteLine vs Logger)**: 本 PR で新規追加した `RollbackCompletedRenames` rollback 失敗 log + rename skip 警告が `Console.WriteLine` 直書き、AGENTS.md「Cross-component Standards」違反。pre-existing の同型 Console.WriteLine も Manager 全体に複数あり sweep 範囲が広いため follow-up [#166](https://github.com/ken1208git/TonePrism/issues/166) で別途消化。
- **Senior L-2 (txtSuffix MaxLength)**: SemverInputControl.Designer の `txtSuffix` に `MaxLength = 32` 追加。SemVer 2.0.0 自体は suffix 長制限なしだが本 project 運用想定 (#133 ガイドラインの「rc1 / beta.2 程度」) に合わせた reasonable 上限、長文 suffix の folder 名肥大化 / UI 視認性低下を構造的排除に揃える。
- **Senior L-3 (Suffix setter validation bypass)**: `Suffix` setter は `txtSuffix.Text` 直代入で `IsSuffixValid` 等の事前 check を持たない (= caller responsibility)。本 PR 内で setter を使う caller は無いが、将来 footgun を防ぐため docstring で「caller は事前に `IsSuffixValid(value)` で書式確認する責務を負う」「防御 setter にしたい場合は `TrySetSuffix` API 追加を検討」を明示。

**Codex round 6 false positive 3 件**: CX-2 / round 3 M-4 / round 4 codex P1 を re-flag されたもの、いずれも fix 済でコードに変更なし。

**Round 7 review fix (codex P2 NEW = senior H-1 同件 + senior H-2/M/L 系 + L-4 inline 取り込み)** — version bump なし、本 entry に統合:

- **Senior H-1 (= codex P2 NEW) Phase 2 topological sort**: round 6 M-2 で `reservedOldDirs` を導入して Phase 1 衝突 check は chained rename (A→B + B→C) を通すようになったが、Phase 2 は UI 順 (= cmbVersionList.Items の DB 由来 row 順) のまま `Directory.Move` 連発で、A→B が先に走ると B disk 残存で fail → 「同じ操作が成功したり rollback になったりする」非決定挙動が残っていた。greedy topological sort (`pendingOldDirs` に含まれない `NewDir` を持つ plan を優先) で並べ替え、cycle (A↔B 等) は UI 順 fall through で CX-1 rollback 経路に流す形に。
- **Senior H-2 (UpdateGame 失敗 drift)**: round 5 codex P1 / round 3 M-4 で `UpdateGameVersion` ループ内の partial commit は塞いだが、その直後の `dbManager.UpdateGame(game)` (games table 更新) が SQLite 一時失敗等で例外を投げると「version 群は新値 commit 済 / games 行は旧値 / disk folder は新名」の drift が外側 generic catch で生 MessageBox に流れていた。`UpdateGame` を try/catch で囲み、round 5 codex P1 と同 wording で「partial commit 通知 + Manager 再起動案内」を出して `return;` (round 6 H-1 と同様 throw せず form 留め)。
- **Senior M-1 (dup-check fallback コメント wording)**: round 6 codex P2 で導入した `TryNormalize` 失敗時の `: v.Version` fallback は、round 7 L-2 で事前 scan を 1 ループ集約 + return 化したため到達不能 dead path になった。「fallback path は事実上 dead だが defensive guard rail として残す (= silent regression 防止)」を comment 訂正。
- **Senior M-2 (LoadVersions selection OrdinalIgnoreCase)**: `v.Version == originalGame.Version` の生 `==` 比較は CX-3 の大文字 V 受理導入後 `games.version="V1.0.0"` / `game_versions.version="v1.0.0"` 共存で false → fallback で先頭選択され「user が active と思っていた version と違うものが表示される」silent UX drift があった。`string.Equals(..., OrdinalIgnoreCase)` に変更、dup-check / rename 比較と同規則に揃える。
- **Senior M-3 (ctor InvalidOperationException 過大)**: const と Designer.cs の同期 drift を ctor で `InvalidOperationException` で fail-fast にしていたが、3 form すべてが本 control を Designer 経由で new するため drift で全部詰む cost 過大だった。const を真の SoT 化: ctor 内で `numMajor.Maximum = MaxMajor` 等を上書き設定 → Designer drift しても無視される → assert 自体不要に。一方向 SoT (本定数を変える → ctor 上書き)、WinForms Designer は static expression 不可のため逆方向 (Designer から const 参照) は構造的に不可能。
- **Senior L-1 (VersionUpForm BumpPatch on parse fail で文言矛盾)**: 旧実装は無条件 `TryParseAndSet → BumpPatch` で、失敗時 clamp 値 (v0.0.0 / v99.0.0) を更に +1 すると warning MessageBox の「v0.0.0 / 上限値に clamp」表記と矛盾する (= `clamp` と書いてるのに `v0.0.1` が表示されて user 混乱)。parse 失敗時は BumpPatch skip + 文言「Patch+1 default は適用なし」追記。
- **Senior L-2 (3 段 MessageBox 統合)**: 旧実装は (a) suffix scan / (b) 空文字 scan / (c) 数値 scan の 3 段 return で、1 つの version が複数違反を持つと user は 2-3 巡 OK 押させられる UX。1 ループで classification → empty / malformed-suffix / malformed-numeric の 3 リストに分けて 1 つの MessageBox で全件まとめて表示する形に集約 (= round 2 M-3 / round 3 H-1 の集約方針と統一)。
- **Senior L-3 (SemverInputControl.TrySplit helper)**: caller (EditGameForm.btnOK_Click の suffix scan) が `IndexOf('-')` 直書きで suffix 切り出していたため `v-1.0.0` 等の malformed (数値 negative 始まり) で suffix を `1.0.0` と誤判定する余地があった。`SemverInputControl.TrySplit(version, out core, out suffix)` static helper を新規追加、VersionRegex の named capture 経由で構造的に分割 → caller 側 IndexOf 排除。
- **Senior L-4 (gameId rename newFolder 単独 check、inline 取り込み)**: 当初 follow-up issue 化を検討したが、本 PR の silent disk/DB drift 系列 fix と同テーマで 1 行 fix のため inline 取り込み。旧 `oldFolder.Exists && newFolder.Exists` 両方存在のみ throw だったのを `newFolder.Exists` 単独で throw に変更、「oldFolder 不在 + newFolder のみ存在」(= 別 user が手動で newGameId 配下を作った等) で DB だけ rename / disk noop の drift 経路を closure。
- **Senior L-5 (AGENTS.md 規約確認)**: Bundle 移行後 (2026-05-11 以降) の個別 component link 定義不要 / dangling reference 許容の規約と本 entry の `### [Manager v0.8.11] - 2026-05-14` 構成は整合、no action。

**Codex round 7 false positive 3 件**: CX-2 / round 3 M-4 / round 4 codex P1 を re-flag されたもの、コードに変更なし。

**Round 8 review fix (codex P1/P2 NEW + senior M/L 系)** — version bump なし、本 entry に統合:

- **Round 8 codex P1 (version rename recovery)**: round 5 codex P1 partial-commit 後の「disk = 新版名 / DB row = 旧版名」状態で user が DB row を新版名に直して OK 押した時、Phase 1 collision check (`Directory.Exists(newDir) && !reservedOldDirs.Contains(newDir)`) が oldDir 不在を考慮せず block して永久詰みになっていた。先頭に `Directory.Exists(oldDir) &&` を追加、両方存在のみ block (= true collision)、oldDir 不在は SourceExists=false 経路で Phase 2 が Move skip + DB only update する recovery 動作に。version folder は gameFolder 配下に閉じるため cross-game silent merge risk なし。
- **Round 8 codex P2 (gameId rename recovery、L-4 tension 解消)**: round 7 L-4 で newFolder 単独存在を一律 throw にしたが、partial-commit 後の「前回 rename interrupted で disk 既に新 ID + DB 旧 ID」recovery 経路を block していた。一方で「別 user が手動作成した unrelated folder」silent merge risk もあり区別不能のため、確認 dialog (OKCancel) を導入: OK で recovery (Move skip + DB only update)、Cancel で `OperationCanceledException` → 新規 catch で静かに return + form 留め。両方存在は引き続き collision throw。
- **Senior Low #1 (UpdateGame MessageBox wording)**: gameIdChanged=true 経路では既に UpdateGameId で games.gameId は新値 / 他フィールドは旧値の混合状態だが、round 7 H-2 の文言「games 行のみ古い値で残っており drift 状態」は全 fields old と誤読される余地があった。gameIdChanged 有無で文言分岐、true 時は「部分更新状態 (gameId は新値で更新済み、title/ジャンル/人数等のフィールドは旧値の可能性あり)」に明示。
- **Senior Med #2 (TryParseAndSet を const 参照に統一)**: `TryNormalize` は const (`MaxMajor` 等) 参照、`TryParseAndSet` は live property (`numMajor.Maximum` 等) 参照で SoT が乖離していた。ctor 上書きで現状は同値だが、将来 form 側で live property を sneak 書き換えると silent inconsistency が出る risk があるため両方 const 直書きに統一。range check 文言からも `(int)numMajor.Maximum` 等を排除、round 7 M-3 の「const = 真の SoT」方針と文法レベルで一貫。
- **Senior Med #3 (TryGetValue silent skip)**: `reservedOldDirs build` + `renamePlan build` の両ループで `_originalVersionByDbId.TryGetValue` 失敗時に silent continue していた。現状 LoadVersions のみが populate するため到達不能だが、将来 form 内に「version 追加」ボタン等が入ると追加直後 item の snapshot 不在で rename 黙って skip → silent drift する死角になるため `Console.WriteLine` で defensive log を残置 (Logger 移行は #166 で sweep)。
- **Senior Low #4 (dup-check Where dead に defensive comment)**: round 7 L-2 の事前 scan で空文字 version を return で弾いた後の `.Where(v => !string.IsNullOrEmpty(v.Version))` filter は dead path。round 7 M-1 の fallback コメントと同方針で「dead だが defensive guard rail として残す」を明記 (片方だけ defensive コメント付いて非対称だったため両方に注記)。
- **Senior Low #5 (Designer.cs 逆参照 cross-ref comment)**: `SemverInputControl.Designer.cs` の `numMajor.Maximum = 99` 等は round 7 M-3 で ctor 上書きされるため実行時 dead だが Designer.cs 単独で読むと「99 を 200 に変えれば Max が上がる」と誤解される。一方向 SoT の逆参照ポインタ (= 「値を変えたい場合は SemverInputControl.cs の const を変えること」) を Designer.cs 先頭 numMajor ブロックに追記。
- **Senior Low #6 (VersionUpForm dup OrdinalIgnoreCase)**: VersionUpForm.ValidateInput の `semverNext.VersionString == currentNormalized` は両辺 TryNormalize 経由で lowercase v 強制済のため機能等価だが、本 PR の他経路 (rename loop / dup-check) は OrdinalIgnoreCase 統一なので規約整合のため `string.Equals(..., OrdinalIgnoreCase)` に揃える。
- **Senior Low #7 (VersionStringChanged 4 連発)**: TryParseAndSet 1 呼び出しで child event を最大 4 連発する API consistency 違反は scope 外、follow-up [#171](https://github.com/ken1208git/TonePrism/issues/171) で別途消化 (現状 caller 不在で無害)。

**Codex round 8 false positive 4 件**: CX-2 / round 3 M-4 / round 4 codex P1 / round 7 H-1 (topo sort) を re-flag されたもの、コードに変更なし。

**Round 8.6: 残存 follow-up issue 3 件 (#164 / #171 / #165) を本 PR に取り込み**:

- **#164 (LoadGameDataForVersion 二重代入削除、close)**: `txtDescription.Text` / `txtVersionDescription.Text` が冒頭 + 末尾で重複代入されていた pre-existing bug を冒頭側に集約。round 2 L-4 で別 issue 化していた cleanup を本 PR scope (= 触ってるファイル + trivial fix) に統合。
- **#171 (`TryParseAndSet` の `VersionStringChanged` 4 連発抑止、close)**: TryParseAndSet 末尾で `numMajor/Minor/Patch.Value` + `txtSuffix.Text` を順次代入する際、各 ValueChanged/TextChanged 経由で `VersionStringChanged` が 1 setter で最大 4 回発火していた API consistency 違反を解消。`_suspendChangeEvents` flag で child event を集約抑止、setter 完了後に 1 回だけ `OnVersionStringChanged()` を直接呼ぶ pattern (try/finally で flag を必ず戻す)。round 8 Low #7 で別 issue 化していた cosmetic 改善を本 PR scope に統合。
- **#165 (per-version rename ループに ProcessingDialog、close)**: Phase 2 の `Directory.Move` ループを `ProcessingDialog` (marquee) で包んで UI 応答性を維持。共有フォルダ越しや cross-volume で `Directory.Move` が内部 copy+delete になる場合、`orderedPlan.Count > 0` の状況で UI が応答停止に見える問題を解消。gameId rename block と同 pattern。worker 内で rollback メッセージを文字列に format して dialog 終了後に `MessageBox` 表示する (= MessageBox を background thread から直接呼ばない、ProcessingDialog の generic error MessageBox との二重表示も回避するため worker 内では throw せず早期 return)。round 4 L-2 で別 issue 化していた UI 対称性改善を本 PR scope に統合。

**Round 8.5: Manager 全 113 件の `Console.WriteLine` を Logger 経由に sweep (#166 取り込み・close)**:

- 当初は #166 を follow-up issue として残す方針だったが、user 指摘「混在気持ち悪い、AGENTS にも書く」を受けて方針転換。Manager 全 13 ファイル (Logger.cs / Program.cs 除く) の `Console.WriteLine` 113 件を `Logger.Info` (59) / `Logger.Warn` (20) / `Logger.Error` (21) に振り分けて全件移行、Logger 初期化済前提で `using GCTonePrism.Manager.Services;` を 2 ファイル (PathManager / BackupLogRepository) に追加。
- **判定基準**: メッセージに「失敗 / エラー / 例外 / Exception / Failed / Error」または `ex.Message` 後置 → `Error`、「警告 / Warn / 異常 / 不正 / skip / drift」→ `Warn`、それ以外 (情報・進捗・debug) → `Info`。`Error(string, Exception)` の 2-arg overload は例外オブジェクトを直接渡せるケースで採用、`ex.Message` を文字列に埋め込む形からスタックトレース完全保持に格上げ。
- **対象ファイル別件数**: SchemaManager 59 (migration ログ中心)、PathManager 15 (検出 log)、MainForm 9、AddGameForm 7、BackupService 6、EditGameForm 5 (本 PR 新規分 4 + pre-existing 1)、BackupSectionPanel 3、FileOperationService 3、RestoreService 3、PathConversionHelper 2、BackupLogRepository 1。`Console.WriteLine` 自動取込 (`Console.SetOut` フック) はすべて INFO 扱いで WARN/ERROR の選別を放棄するため、明示 API に統一することで Manager のログビューア (#129) のレベルフィルタが本来の選別性能を発揮できる状態に。
- **AGENTS.md「Cross-component Standards」更新**: 「新規実装は `Logger.Info / Warn / Error` を直接使うこと。`Console.WriteLine` (.NET) / `print` (Godot) は legacy」規約を追加、Console 自動転送はあくまで pre-existing 救済の役割と明示。
- **SPECIFICATION.md §3.6 強化**: 「明示 API は推奨」→「**MUST**」に格上げ、変更履歴に v1.10.21 (2026-05-17) 追記。
- **Follow-up**: Launcher 側の `print` / `printerr` 同型 sweep は #85 で別途対応予定 (本 PR は Manager 限定 scope)。

### [Manager v0.8.10] - 2026-05-13

PR #150 で dir rename (`GCTonePrism_Manager/` → `Manager/`) に連動して `PathManager.cs` の self-reference リテラル + priority-3 detection ロジック (StartsWith 二段比較 + Manager/Launcher sibling 同時存在検証) + csproj `<RootNamespace>` を修正。配布構造変更を含むため SemVer 厳密だと minor 寄りだが、Install.bat の v0.2.0 → 新構造 migration で自動吸収されエンドユーザー視点では invisible のため patch bump 扱い。

**詳細は [Release Tooling v0.1.10](#release-tooling-v0110---2026-05-13) entry および SPEC §2.4 / §3.7.x 変更履歴 v1.10.9 を参照** (AGENTS.md「重複記述は避ける」規約準拠、round 7 L6)。

### [Manager v0.8.9] - 2026-05-11

#### Added

- **ログビューア UI を追加 (#129)**: 新規「ログ」タブで `<project_root>/logs/manager/` と `<project_root>/logs/launcher/` 両方のログファイルを Manager から閲覧可能に。Manager v0.8.8 で導入したファイルログ基盤の実用化として、エクスプローラから直接ファイルを開かなくても部員が GUI で過去ログを追える
  - 新規 `Controls/LogSectionPanel.cs` + `.Designer.cs`（既存 BackupSectionPanel と同じ UserControl パターン）
  - 上部 2 行ツールバー (76px): 1 行目=更新ボタン + INFO/WARN/ERROR レベルフィルタ + Manager/Launcher コンポーネントフィルタ + (右) ファイル件数表示。2 行目=検索窓（横一杯）
  - 上下分割（横割り SplitContainer）: 上ペイン=ファイル一覧 (DataGridView)、下ペイン=本文 (RichTextBox)
  - ファイル一覧の列: アプリ / PC / 開始日時 / 最終更新 / サイズ / ファイルパス（残り幅 Fill）。新しい順ソート、選択時に下ペインへ内容ロード
  - 本文表示: Consolas 9pt + WordWrap 有効（横スクロール無し、長い行は改行）
  - **ハイライトモード（フィルタしないで強調）**: フィルタや検索で他の行が消えるのではなく、マッチ行は通常表示+レベル別背景色、非マッチ行は薄い灰色文字でディム。検索ヒット substring には黄色ハイライトを追加。文脈ごと見られるので「エラー前後の INFO ログ」も自然に追える
  - レベル分類: INFO=白 / WARN=淡黄 / ERROR=淡赤 背景色。スタックトレース等のフォーマット外行は直前行と同レベルとして扱う
  - コンポーネントフィルタ: Manager / Launcher のチェックを外すとそのファイルが灰色化（一覧から消えるのではなく見えるけど目立たない状態）
  - ファイルは `FileShare.ReadWrite` で開くため、Logger が書き込み中のセッションファイルもロックなしで閲覧可能
  - フィルタ変更時はファイル再読み込みなしで描画のみ更新（パフォーマンス）

### [Manager v0.8.8] - 2026-05-11

#### Added

- **ファイルログ基盤 (#116)**: 新規 `Services/Logger.cs` を追加し、`<project_root>/logs/manager/manager_<PCname>_<YYYY-MM-DD_HHmmss>.log` に **1 起動セッション = 1 ファイル** でログを出力。INFO / WARN / ERROR の 3 段階、`[YYYY-MM-DD HH:mm:ss] [LEVEL] [Module] msg` 形式。これまで Manager はエラーが出ても後追いで原因調査ができなかった (#115 の WAL 起因エラー診断時に判明) 問題を根本解決
  - **既存 `Console.WriteLine` を `Console.SetOut` で自動キャプチャ**: 既存 109 件 / 11 ファイルの `Console.WriteLine($"[Module] msg")` 呼び出しが **コード変更ゼロ** で自動的にログファイルにも書かれるよう、カスタム `TextWriter` (内部 `ConsoleHookWriter`) を `Program.cs` の `Logger.Initialize()` で `Console.SetOut(...)` 経由で差し替え。INFO 扱いで記録
  - **明示 API**: 新規コードからは `Logger.Info / Warn / Error / Error(msg, ex)` でレベル指定可能。`Error(msg, ex)` は `Exception.ToString()` を改行付きで追記
  - **保存先の判断**: 当初 Issue #116 提案の `%APPDATA%\GCTonePrism_Manager\logs\` ではなく **`<project_root>/logs/manager/`**（prism.db と同じ共有先）に変更。理由は (1) Manager の将来的なログビューア UI で複数 PC のログを 1 箇所で閲覧可能、(2) 本番展示 PC のリカバリ・OS 再構築で揮発しない、(3) クラブメンバーがエクスプローラから直感的に発見できる、(4) Launcher と対称な設計（Launcher も同じ `<project_root>/logs/launcher/` に出力）
  - **1 セッション 1 ファイル設計**: PC 名 + 起動時刻でファイル名がユニークになるため、複数 PC が同時に同じ共有先へ書き込んでも書き込み競合・行間 interleaving が一切起きない。同秒衝突は連番サフィックスで回避
  - **30 日 retention**: 起動時に `logs/manager/manager_*.log` をスキャンし、`LastWriteTime` が 30 日より古いものを削除。現セッションのアクティブファイルは `_currentLogPath` 一致チェックで明示的に保護
  - **障害耐性**: `Logger.Initialize()` 失敗時は MessageBox 警告のみで Manager 起動は継続。`Write` の例外は握り潰し、Logger 自身の例外は **絶対にログに書かない**（無限ループ防止）
  - **プロジェクトルート検出は Logger 内部で重複実装**: PathManager の起動 `Console.WriteLine` も Logger でキャプチャしたいため、Logger は PathManager に依存せず自前で exe → 上に prism.db を 10 階層まで探す軽量ロジックを持つ。見つからなければ exe 隣にフォールバック
  - **起動・終了イベント記録**: `Program.cs` を `try-finally` で囲み、`finally` で `Logger.Shutdown()` を呼んで終了ログを必ず出す。事故調査で「いつ落ちたか」を追跡可能に
  - **横断要件として SPEC §3.6 / AGENTS.md "Cross-component Standards" に格上げ**: 同じベースラインを Monitor 等の将来コンポーネントにも適用する仕組みを明文化

### [Manager v0.8.7] - 2026-05-10

#### Added

- **バックアップ履歴の相対パス保存 (#126)**: `backup_log` テーブルに `relative_path` カラムを追加 (DB v11 → v12 マイグレーション)。バックアップ作成時に `prism.db` のあるディレクトリからの相対パスを記録し、表示・復元時に動的にパスを再構築することで **プロジェクト場所の移動に追従** できるように
  - 新規 `Services/BackupPathResolver.cs`: `relative_path` を優先し、無ければ `file_path` にフォールバックする共通ヘルパー
  - 既存レコード (relative_path NULL) はそのまま絶対パスで動作（後方互換性）
  - dbDir 配下にない destinationDir (ユーザーが絶対パスで設定) は relative_path NULL のまま
- **failed 履歴の自動掃除 (#126)**: Manager 起動時 (`RefreshDisplay`) のリコンサイル処理で、`status='failed'` のレコードを **物理ファイル + DB レコード両方** から自動削除。失敗履歴は復元には使えないため、ユーザーに表示する価値が無い + 古いプロジェクトパスのゴミが残り続ける主因にもなっていたため
- **個別削除 UI (#126)**: 「バックアップ」タブの操作セクションに「選択した履歴を削除...」ボタンを追加。確認ダイアログを経て、選択行のバックアップファイル + DB レコード両方を削除
- **不在ファイル非表示 (#126)**: 履歴表示時にパス解決後の `File.Exists` チェックを行い、ファイルが見つからないレコードは履歴一覧に表示しない (DB レコードは保護のため残す)
- **`DatabaseManager.DatabasePath` プロパティ**: `_conn.DbPath` を公開する読み取り専用プロパティ。BackupPathResolver 等から参照

#### Database

- DB バージョン: 11 → 12
- `backup_log` テーブルに `relative_path TEXT NULL` カラムを追加
- `MigrateV11ToV12` を新設（既に列がある場合はスキップ、ALTER TABLE で追加）
- `ExpectedSchema` の `backup_log` 列リストにも `relative_path` を追加

### [Manager v0.8.6] - 2026-05-10

#### Changed

- **`EditGameForm` / `AddGameForm` / `VersionUpForm` を 2 列レイアウトに刷新 (#123)**: 縦長 (480 × 888〜1000px) だった入力フォームを 2 列構成 (950 × 570〜645px) に再設計。ノート PC でも縦スクロールなしで全項目が見渡せるようになった
  - **左列**: 基本情報 (ゲームID/タイトル/説明文/ジャンル/プレイヤー数/難易度/プレイ時間/フラグ/通信プレイ対応 など)
  - **右列**: アセット & 設定 (サムネイル/背景画像 + プレビュー/実行ファイル/テスト起動/起動オプション/製作者情報 + EditGameForm はバージョン管理、VersionUpForm は更新内容)
  - 入力フィールドの幅を広げ、ジャンル選択 (CheckedListBox) や説明文入力欄も従来より広く

#### Fixed

- **ノート PC で `EditGameForm` / `AddGameForm` が縦に見切れる問題を解消 (#123)**: 上記 2 列化で根本解消。念のため Form に `AutoScroll = true` も設定し、それでも入りきらない環境では縦スクロールバーが出るように
- **`DataGridView` の行高をユーザーが変更できる問題を解消 (#123)**: ゲームタブ・ストアタブ等で行と行の境界をドラッグすると行高が変わってレイアウトが崩れる事故を防止。全 `DataGridView` に `AllowUserToResizeRows = false` を設定
  - 対象: `dgvGames` (GameSectionPanel), `dgvSections` (StoreSectionPanel / StoreSectionListForm), `dgvDevelopers` × 3 (Add/Edit/VersionUp)
  - `gridHistory` (BackupSectionPanel) は既に設定済みで対応不要
- **`DataGridView` の行ヘッダーを非表示化 (#123)**: 行ヘッダー自体を消すことで境界ドラッグの誤操作余地を物理的に排除。新規追加対象は `dgvSections` (StoreSectionListForm), `dgvDevelopers` (Add/Edit) の 3 件 (他は既に設定済み)。製作者情報の `dgvDevelopers` も「追加」「編集」「削除」ボタン経由の操作なので新行マーク不要

### [Manager v0.8.5] - 2026-05-10

#### Added

- **フォルダ削除失敗時の再試行 UI を追加 (#122)**: ゲーム削除や DB リセットでフォルダ削除に失敗した場合、従来は「警告 MessageBox 表示 → ユーザーが手動でなんとかする」だったが、専用ダイアログ `FolderDeletionFailureDialog` で「再試行」「諦める」を選べるように改善
  - 主因は **Launcher が起動中ゲームの実行ファイルを掴んでいる** ケース。ユーザーが Launcher を閉じてから「再試行」を押すだけで解消する
  - ダイアログには対象フォルダパス、エラー詳細 (Exception.Message)、対処手順 (Launcher を閉じてから再試行) を表示
  - `AcceptButton = btnRetry` で Enter で再試行 (再試行は何度押しても安全)、`CancelButton = btnGiveUp` で ESC で諦める
- **新規 `Services/FolderDeletionService.cs`**: フォルダ削除のリトライ機構を共通化 (5 回 × 200ms、`RestoreService.DeleteWithRetry` と同じパターン)。`IOException` / `UnauthorizedAccessException` のみリトライ対象、それ以外は throw
- **新規 `FolderDeletionFailureDialog.cs` + `.Designer.cs` + `.resx`**: 上記再試行 UI のカスタム Form

#### Changed

- **`SchemaManager.ResetDatabase()` の戻り値を `string` → `FolderDeletionService.Result` に変更**: 退避フォルダ削除の Path / Exception を呼び出し側に渡せるようにし、再試行時に同じ path を使えるように構造化 (#122)
- **`DatabaseManager.ResetDatabase()` の wrapper signature 更新**: 同様に `Result` を返す形に
- **`SettingsSectionPanel.btnResetDatabase_Click`**: 退避フォルダ削除失敗時に `FolderDeletionFailureDialog` を表示する再試行ループに変更。「諦める」を選んだ場合のみ警告 MessageBox を表示 (#122)
- **`GameSectionPanel.btnDeleteGame_Click`**: フォルダ削除を `ProcessingDialog` の外に出して再試行ループ化。`folderWarning` 文字列方式を廃止し、失敗時は `FolderDeletionFailureDialog` で対応 (#122)
- **ゲーム削除を rename rollback パターンに刷新**: リセットと同じ 3 フェーズ「(1) `games/{gameId}/` を `.pending-delete-{guid}/` に rename で退避 → (2) DB 削除 → (3) 退避フォルダ物理削除」に統一 (Codex P1 #122 への対応)。これにより:
  - フォルダ物理削除前に DB 削除が走るので、DB 削除失敗時 (SQLiteException 等) はフォルダを rename で戻して**何も変わらない状態にロールバック**でき、永続的データロストを排除
  - (1) 失敗時 (Launcher ロック中など) は再試行 UI、諦めたら全体中止で DB 無事
  - (3) 失敗時は DB 削除済みなのでゴミ退避フォルダだけ残るパターン (リセットと同じ)
- 旧実装の「フォルダ物理削除 → DB 削除」順は、DB 失敗時にフォルダだけ消えて戻せない問題があった (PR #117 以来の負債)。本変更で完全解消

#### Scope out (将来 Issue 候補)

- **ロックしてるプロセス特定 UI** (Restart Manager API 利用): 大規模で P/Invoke 必要、別 Issue として検討
- **ファイルログ機構**: Issue [#116](https://github.com/ken1208git/TonePrism/issues/116) に依存
- **「フォルダをエクスプローラで開く」ボタン**: ロック中はエクスプローラから消そうとしても同じく失敗するため、本質的解決にならず削除

### [Manager v0.8.4] - 2026-05-10

#### Fixed

- **データベースリセット時に `games/` フォルダも削除するよう実装を修正 (#119)**: `ResetDatabaseConfirmForm` の確認画面で「・gamesフォルダ内のすべてのファイルとフォルダ」を削除すると告知していたが、実装 (`SchemaManager.ResetDatabase()`) は `prism.db` 1 ファイルしか削除しておらず、確認画面と挙動が一致していなかった
  - `SchemaManager.ResetDatabase()` を **rename rollback 方式** で実装:
    1. `games/` を `games.pending-delete-{guid}/` に rename して退避（同一ボリューム rename は事実上 atomic）
    2. `prism.db` を削除
    3. 退避フォルダを物理削除
    4. `games/` を再作成 + DB 再構築
  - **rename rollback の意図** (Codex P1 指摘 #121 への対応): 物理削除順 (games → DB) でも、DB 削除でロック等で失敗した場合に「games 消えたまま + DB 古いレコード」という broken partial-reset 状態になる。rename ならフォルダ実体は退避先に残るので、DB 削除失敗時は rename を戻して「何も変わってない」状態にロールバックできる
  - `backups/` 等の隣接フォルダは触らない（復元用に残す）
  - 順序は **「(1) games rename → (2) DB 削除 → (3) games/ 再作成 + DB 再初期化 → (4) 退避フォルダ物理削除」** の 4 ステップ
  - `IOException` / `UnauthorizedAccessException` を捕捉してユーザー向けメッセージに変換。**失敗パターン別の状態**:
    - (1) games rename 失敗 → 何も変わらず throw（DB / games 共に無事）
    - (2) DB 削除失敗 → games を rename で復元してから throw（DB / games 共に無事）
    - (3) games/ 再作成 or DB 再初期化失敗 → 部分作成された games/ と prism.db を削除 + 退避を rename で games/ に戻してから throw（DB だけ消えた状態に着地、ユーザーは backup #96 から復元可能）。Codex P1 #121 への 4 度目の対応
    - (4) 退避フォルダの物理削除失敗 → 戻り値で警告メッセージを返す（DB / games 共に再構築済み + ゴミ退避フォルダだけ残る → ユーザーに「手動削除を」と通知）。rename はファイルロックを解除しないため Launcher が起動中ゲームの実行ファイルを掴んでいるとレアケースで起き得る
  - **`ResetDatabase()` の戻り値を `void` → `string` に変更** (Codex P2 #121): 上記 (4) 失敗時の警告を例外で投げると `ProcessingDialog` が `DialogResult.Abort` を返し、`SettingsSectionPanel.btnResetDatabase_Click` が non-OK で early return → `UpdateVersionInfo()` / `DatabaseReset?.Invoke()` がスキップされて UI が古いまま「失敗」と誤報告されていた。完全成功は null、警告ありは文字列を戻り値で返すよう変更し、呼び出し側は warning の有無に関わらず UI リフレッシュを実行 + warning があれば情報 MessageBox を出す形に
- **`ResetDatabaseConfirmForm` に「すべての展示PCの Launcher を終了してから実行」警告を追加**: DB ファイル + games フォルダ全部に対するロック競合を予防
- **`DeleteGameConfirmForm` に「該当ゲームを起動中の Launcher があれば閉じて」ヒントを追加**: フォルダ削除失敗の主原因を予防
- **`ResetDatabaseConfirmForm` の文言を部員向けに刷新 (#119)**: 「データベース内のすべての情報」「gamesフォルダ内のすべてのファイルとフォルダ」という技術用語ベースの表現を、PR #118 の `DeleteGameConfirmForm` と同じトーンで「すべてのゲーム情報・プレイ記録・アンケート回答」「Manager に登録されている全ゲームのファイル（games フォルダ全体）」に書き換え + 「部員の開発フォルダには影響しません。リセット前にバックアップ機能でスナップショット取得を推奨。」の補足を追加。**「games フォルダ全体」の括弧を残しているのは、未登録の手動配置ファイル（部員の実験フォルダ等）も削除対象であることを明示するため (Codex P2 #121)**

#### Added

- **`AddGameForm` に gameId 重複検出警告を追加 (#120)**: 何らかの原因で `games/{gameId}/` フォルダが残っている状態で同 gameId を新規追加しようとすると、最悪 Launcher が古い実行ファイルを起動する silent failure になり得たため、`btnOK_Click` のバリデーション直後に存在チェックを追加
  - 残骸を検出すると確認 MessageBox を表示し、「失いたくないデータがある場合は手動退避してから削除を」とユーザーに案内
  - 「OK」を押せばそのまま続行（古いフォルダはそのまま残る）、「キャンセル」を押すと追加処理自体を中止
  - 自動削除はしない（データ保護優先）

### [Manager v0.8.3] - 2026-05-10

#### Changed

- **ゲーム削除時に DB レコードに加えて `games/{game_id}/` フォルダも常に削除するよう変更 (#111)**: 従来は DB 削除のみだったため `games/{game_id}/` フォルダがディスクに残り続けていた。SPEC §2.2 にあった「DB のみ / DB + フォルダ」のオプション分岐は廃止し、削除実行 = DB + フォルダのセット削除に統一
  - 新規 `DeleteGameConfirmForm` を追加。何が消えるかを明確化するため、フォルダパスをダイアログ内に表示（`Consolas` モノスペース、ReadOnly）し、警告色で「ディスクから物理的に削除されます」と明示
  - フォルダが存在しない場合（手動削除済み等）は表示を「フォルダが見つかりません。DB のみ削除します」に切り替えて DB 削除のみ実行（無害）
  - `Enter` キーで誤って削除が走らないよう `AcceptButton` をキャンセルに割り当て
  - 削除処理は既存の `ProcessingDialog` (Marquee モード) 内で DB 削除に続けて `Directory.Delete(folder, true)` を実行
  - `IOException` (Launcher など他プロセスがロック中)・`UnauthorizedAccessException` を個別捕捉し、DB 削除は成功した上で「フォルダ削除に失敗、手動削除してください」の警告に切り替える非破壊運用
  - 関連実装: `Controls/GameSectionPanel.cs` の `btnDeleteGame_Click`、`PathManager.GetGameFolder(gameId)` を再利用

### [Manager v0.8.2] - 2026-05-10

#### Changed

- **`prism.db` のジャーナルモードを WAL → DELETE へ移行 (#103)**: 学校 SMB ファイルサーバー上で `prism.db` を共有する運用形態において、SQLite 公式が WAL モードの動作を保証外と明言している（`prism.db-shm` のメモリマップトファイルが SMB で整合性を保証されない）リスクを回避するため、`PRAGMA journal_mode=DELETE` に切り替え
  - `DatabaseConnection.OpenConnectionWithWalMode` を `OpenConnectionWithJournalMode` にリネームし、呼び出し側 7 ファイル（`SchemaManager.cs` + 6 リポジトリ）を更新
  - 接続文字列に `Busy Timeout=10000` を追加（System.Data.SQLite ライブラリ側のフォールバック）
  - 接続オープン時に `PRAGMA busy_timeout=10000` を実行し、書き込み競合時は SQLite 内部で最大 10 秒待機する「書き込み待機列」として動作させる

#### Operations

- **既存環境の移行手順（一度きり）**:
  1. 全 PC で Launcher / Manager を停止
  2. CLI で `tools\sqlite3\sqlite3.exe <prism.db のパス> "PRAGMA wal_checkpoint(TRUNCATE); PRAGMA journal_mode=DELETE;"`
  3. `prism.db-wal` / `prism.db-shm` が削除されたことを確認
  4. v0.8.2 の Manager と v0.5.15 以降の Launcher を全 PC に配布

### [Manager v0.8.1] - 2026-05-10

#### Fixed

- **surveys / play_records スキーマ drift を修正 (`MigrateV10ToV11`)**: SPEC v1.5.1 (2026-03-28) で `surveys`（JSON 形式 → ★評価+コメント）、`play_records`（累計方式 → イベントログ方式）に変更されたが、対応するマイグレーションが書かれていなかったため、`CREATE TABLE IF NOT EXISTS` の仕様により旧スキーマのテーブルが温存されていた。本マイグレーションで修正
  - 旧スキーマ判定: `surveys` は `submitted_at` 列、`play_records` は `play_count` 列の存在で検出
  - 行数 0 の場合のみ DROP & CREATE で新スキーマへ置換（データ保護）
  - 行数あり時は警告ログを出して bool false を返し、`MigrateV10ToV11` が呼び出し側に伝播。`CheckAndMigrateDatabase` は成功した migration のみ `currentVersion` を bump し、`SetDbVersion` には実際に達成した `currentVersion` を書き込むため `user_version` は 10 のまま保持される。これにより次回起動でも migration が再試行されつつ、Manager 自体は正常起動する（Codex P1 指摘 "Avoid marking DB v11 when drift migration is skipped" + "Avoid hard-failing startup on non-empty drift tables" の両方に対応）
- **`games.version` 列を `CreateTables()` に追加**: 既存 DB では `MigrateGamesTable` の ALTER TABLE で後付けされていたが、`CreateTables()` 側に定義が無く、新規 DB と既存 DB でスキーマ定義が分散していた。`VerifySchema` 初回起動で検出し、本 PR 内で修正（`MigrateGamesTable` の ALTER は古い DB 向けのフォールバックとして残す）

#### Added

- **`VerifySchema()` 起動時スキーマ整合性検証**: `InitializeDatabase` 末尾に組み込み、全 11 テーブルの列名一覧と `ExpectedSchema` 定義を `PRAGMA table_info` 経由で比較。不一致があれば警告ログを出す（drift があってもアプリ動作はそのまま継続）
- **`MigrateV10ToV11` マイグレーション**: 上記 surveys / play_records drift 修正を担当
- **マイグレーション機構の helper メソッド**: `CreateSurveysTable` / `CreatePlayRecordsTable`（`CreateTables` と migration の両方から呼ぶ）、`TableHasColumn`、`GetTableRowCount` を追加
- **`AGENTS.md` に "Database Schema Management" セクションを追加**: スキーマ変更時に必ず対応するマイグレーションを書くこと、`tools/sqlite3/sqlite3.exe` で前後検証することを明文化

#### Technical

- `CurrentDbVersion`: `10` → `11`
- `CreateTables()` の `surveys` / `play_records` 作成を helper メソッド化（マイグレーションでも再利用するため）
- `ExpectedSchema` 静的辞書で全テーブルの期待列リストを定義（スキーマ変更時はここも同時更新する規約）

### [Manager v0.8.0] - 2026-05-07

#### Added

- **データベースバックアップ機能 (#96)**: `prism.db` のスナップショットを Manager から取得・管理できる機能を新設
  - **新規タブ「バックアップ」**: MainForm に4タブ目を追加し、専用UIを設置
  - **手動バックアップ**: 「今すぐバックアップ」ボタンで即時実行。SQLite Online Backup API (`SQLiteConnection.BackupDatabase`) を使用するため、Launcher が `prism.db` を開いている状態でも整合性を保ったコピーが可能
  - **自動バックアップ**: Manager 起動時に「前回バックアップから設定間隔（デフォルト 24h）以上経過していたら走らせる」方式。バックグラウンドタスクで起動をブロックしない
  - **マルチPC重複防止**: `settings.last_backup_at` を `BEGIN IMMEDIATE` (System.Data.SQLite における `IsolationLevel.Serializable`) で更新する lease 方式。複数のManagerが同時起動した場合でも片方のみが自動バックアップを走らせる
  - **バックアップ履歴一覧**: DataGridView で過去 100 件までを表示（開始日時 / 完了日時 / 実行PC / トリガ / 状態 / サイズ / ファイルパス）
  - **世代管理**: 設定値 `backup_retention_count`（デフォルト 30）を超える古いバックアップは自動削除
  - **保存先設定**: デフォルトは `<DBフォルダ>/backups/`、`BackupSettingsForm` から任意のフォルダに変更可能（FolderBrowserDialog 経由）
  - **リストア機能**: 履歴から選択 → 警告（「全Launcher を停止してください」「現DBは退避されます」）+ 4桁確認コード入力（`ResetDatabaseConfirmForm` の安全パターンを踏襲）→ 現DBを `safety_before_restore_HHmmss.db` として Online Backup API で退避 → SQLite 接続プールクリア → `prism.db` / `prism.db-wal` / `prism.db-shm` 削除 → バックアップを `prism.db` としてコピー → DB再初期化
- **新規ファイル**:
  - `Models/BackupLogEntry.cs` — `backup_log` テーブルのモデル（UNIX秒 → `DateTime` 変換ヘルパー付き）
  - `Repositories/BackupLogRepository.cs` — `backup_log` の CRUD（in_progress → success/failed の状態遷移）
  - `Repositories/SettingsRepository.cs` — `settings` テーブルへの汎用アクセサ + バックアップ lease 取得 (`TryAcquireBackupLease`)
  - `Services/BackupService.cs` — バックアップのドメインロジック、Online Backup API 呼び出し、リテンション処理、`BackupResult` 結果モデル
  - `Services/RestoreService.cs` — 退避 + 接続プールクリア + 上書きの安全な復元手順
  - `Controls/BackupSectionPanel.cs` (.Designer.cs) — バックアップタブのUserControl
  - `BackupSettingsForm.cs` (.Designer.cs) — 設定ダイアログ
  - `RestoreConfirmForm.cs` (.Designer.cs) — 復元確認ダイアログ

#### Changed

- **DBスキーマ v8 → v9**: additive migration（既存テーブル変更なし、Launcher 互換性に影響なし）
  - `backup_log` テーブル新設（id, started_at, completed_at, pc_name, file_path, file_size_bytes, status, error_message, trigger_type）
  - `settings` テーブルに 4 キー追加（`last_backup_at`, `backup_destination_path`, `backup_auto_interval_hours`, `backup_retention_count`）
  - 自動マイグレーション（`SchemaManager.MigrateV8ToV9`）が起動時に実行される
- **`settings` テーブルの KVS スキーマ整合化**: SPECIFICATION 1.3.1 (2026-02-08) で「単一行 → KVS方式」に変更されていたが、既存DB向けマイグレーションが実装されていなかったため、それより前に作られたDBは古いスキーマのままだった。Manager v0.8.0 では起動時に `settings` テーブルの `key` カラム有無を検査し、無ければ古いテーブルを `settings_legacy_v8_or_earlier` にリネームしてから KVS 方式の新テーブルを作成する移行処理を追加（`EnsureSettingsTableIsKvsSchema`）。旧データに実コードからの参照は無かったためデータロスは発生しないが、念のため legacy テーブルとして退避
- **`DatabaseManager` ファサードを拡張**: 新規プロパティ `BackupService`, `RestoreService`, `BackupLogRepository`, `SettingsRepository` を追加
- **`ProcessingDialog` を拡張 (#99 関連)**: `MarqueeMode` プロパティ（進捗が定量化できない処理向けの流れるバー）と `AllowCancel` プロパティ（中断不可な処理向けにキャンセルボタン非表示化）を追加
- **進捗バーが付いていなかった重め操作にプログレス表示を追加 (#99)**:
  - **EditGameForm**: ゲームID変更時の `Directory.Move(oldFolder, newFolder)` + `UpdateGameId` をマーキー進捗で表示。失敗時のロールバック（フォルダを元に戻す）処理にも進捗メッセージ。共有フォルダ越し・クロスボリューム時の体感速度を改善
  - **SettingsSectionPanel**: 「データベースリセット」操作（DBファイル削除 + テーブル再作成 + マイグレーション再実行）をマーキー進捗で表示
  - **GameSectionPanel**: 「ゲーム削除」操作（CASCADE で developers / game_versions / game_genres / play_records / surveys / store_section_games の関連レコード削除）をマーキー進捗で表示

#### Fixed

- **`backup_log` の自己参照スナップショット問題**: 「今すぐバックアップ」中の `backup_log` には `in_progress` 行が既に書き込まれているため、SQLite Online Backup API でコピーした .db ファイルにも自分自身の `in_progress` 行が含まれてしまう。後でその .db から復元すると、履歴一覧に「進行中のままのゴースト行」が現れる挙動だった
  - **`InsertInProgress` 時点で予定ファイルパスを記録するよう変更**: 旧実装ではバックアップ完了後にファイルパスを書き込んでいたため、自己参照スナップショットには空の `file_path` が入っていた。最初から書き込むことで「実ファイルが存在するか」での判別が可能になった
  - **`BackupLogRepository.ReconcileInProgressEntries(reasonIfMissing, thresholdSeconds)` を新設**: 各 `in_progress` 行について実ファイルの有無を確認し、存在すれば `success`（実ファイルサイズで `file_size_bytes` 更新）、存在しなければ `failed` に更新する。閾値秒数を null にすると全件対象、指定すると古い行のみ対象（実行中のバックアップに干渉しない）
  - **`MainForm` 起動時**: 閾値 600 秒で呼ぶ（Manager クラッシュ等で取り残された古い行のみリコンサイル）
  - **`MainForm.OnDatabaseRestored`**: 閾値なしで呼ぶ（復元直後はスナップショットの状態なので、参照されているファイルが実在すれば正しく `success` として復元される）
  - これにより「**バックアップ実体ファイルは存在しているのに失敗扱いになる**」という不自然なUXが解消され、復元に使ったまさにそのファイルが「成功」表示で履歴に残る
- **更新ボタンが新しいエントリを反映しないことがある問題の改善**: System.Data.SQLite の接続プールが古いスナップショットを保持して新しいコミットを見せないケースに対応。`BackupSectionPanel.RefreshDisplay()` 内で `SQLiteConnection.ClearAllPools()` を呼んで強制的にプールを掃除してから読み直すように変更
- **更新ボタンに包括リコンサイル機能を追加**: `BackupSectionPanel.RefreshDisplay()` で表示更新前に以下を実行：
  - `ReconcileInProgressEntries` を `recoverFailedWithExistingFile=true` で実行 — `failed` 行のうち `file_path` が指すファイルが実在するものを `success` に救済
  - `RecoverLegacyFailedEntriesByFolderScan` を実行 — `file_path` が空のまま残っている `failed` 行について、バックアップフォルダ内の `prism_yyyyMMdd_HHmmss.db` 形式のファイル名と `started_at` を ±1 秒範囲で照合し、一致すれば `success` として復元（旧バージョン Manager 由来のゴースト救済）
  - 「ファイルが本当に無い `failed` 行」（実際のディスク満杯エラー等）はそのまま保持されるので、誤って成功扱いに戻すことはない

#### Changed (UI)

- **バックアップ履歴の状態表示を視覚的に改善**: 表示は **成功 / 失敗 / 実行中** の3状態に統一しつつ、状態セルに **背景色**（淡緑 / 淡赤 / 淡青）と **ツールチップ** を追加。技術的な詳細（クラッシュ残骸 vs 実行直後の通常ケースなど）はツールチップに押し込んで本体表示はシンプルに：
  - **成功** → 「バックアップは完了済みです。この行から復元できます。」
  - **失敗** → `error_message` の内容（「中断理由: ◯◯」）。空なら「実ファイルが存在しないため復元には使えません。」
  - **実行中（30秒以内）** → 「現在実行中です（経過: X 秒）」
  - **実行中（30秒以上）** → 「前回 Manager 異常終了の残骸の可能性があります（経過: X 分）。更新ボタンを押すと実ファイルの有無で 成功/失敗 が確定します。」
  - 選択中も色味が保たれるよう `SelectionBackColor` も状態に合わせて設定

#### Changed (Safety Backup の取り扱い改善)

- **DBスキーマ v9 → v10**: `backup_log.trigger_type` の CHECK 制約を `('manual', 'auto')` から `('manual', 'auto', 'safety')` に拡張。SQLite では CHECK 制約を ALTER できないため、`backup_log_new` を作成してデータを移し替える方式で実施
- **退避ファイルの保存先を整理**: 旧 `<DBフォルダ>/safety_before_restore_yyyyMMdd_HHmmss.db`（プロジェクトルート直下）から、`<DBフォルダ>/backups/safety/safety_yyyyMMdd_HHmmss.db` に変更
  - `RestoreService.Restore` 内で退避先を構築・作成
  - Manager 起動時に旧形式のファイルを `backups/safety/` へ自動移動（`BackupService.MigrateLegacySafetyFilesToSafetyFolder`、idempotent）
- **退避ファイルの世代管理**: `backups/safety/` 内のファイルを最新10件まで保持し、超過分は古いものから自動削除（`RestoreService.ApplySafetyRetention`）
- **退避ファイルを履歴UIに統合**: `BackupLogRepository.RegisterUnknownSafetyFiles` で `backups/safety/` をスキャンし、`backup_log` に未登録の退避ファイルを `trigger_type='safety'`, `status='success'` で自動登録。`started_at` はファイル名のタイムスタンプから復元
  - Manager 起動時 / バックアップ復元後 / 更新ボタン押下時の各タイミングで実行
  - 履歴グリッドで「退避」とラベル表示（「手動」「自動」と並ぶ第3のトリガ種別）
  - 退避ファイルから直接「選択したバックアップから復元」も可能（誤った復元のロールバック手段）
- **`.gitignore` 修正**: `backups/`（通常バックアップ＋退避フォルダ）と旧形式の `safety_before_restore_*.db` を git 管理から除外。これまで `git add .` でうっかりコミットされる危険があった

### [Manager v0.7.6] - 2026-03-29

#### Changed

- **EditForm外部パス警告にバージョンアップ案内を追加**: ゲームフォルダ外のファイル選択時にバージョンアップ機能の利用を案内するメッセージを追記

### [Manager v0.7.5] - 2026-03-29

#### Fixed

- **ゲームIDリネーム時のロールバック追加**: DB更新失敗時にフォルダを元に戻すよう修正
- **DB初期化拒否時のパネル読み込みをスキップ**: DB未作成のまま起動した場合にパネル初期化を行わないよう修正

### [Manager v0.7.4] - 2026-03-29

#### Fixed

- **パネル初期化をDB確認後に移動**: DB存在チェック前にSettingsSectionPanelがDB接続するのを防止

### [Manager v0.7.3] - 2026-03-29

#### Fixed

- **バージョン切り替え時の編集内容保持**: currentDisplayingVersionの代入漏れを修正
- **ストアセクション編集画面の最大表示数を表示**: 非表示だったmax_display_count入力欄を常時表示に変更

### [Manager v0.7.2] - 2026-03-29

#### Fixed

- **ゲームIDリネーム時のデータ不整合を修正**: フォルダリネームをDB更新より先に実行し、失敗時のDB/ファイルシステム不整合を防止
- **ゲームIDリネーム後のパス変換を修正**: リネーム後にパステキストボックスを新フォルダベースに更新してから相対パス変換するよう修正

### [Manager v0.7.1] - 2026-03-28

#### Added

- **ゲームID編集機能**: EditGameFormからゲームIDを変更可能に（全関連テーブルの一括更新+フォルダリネーム）

#### Changed

- **タブ+セクションパネル構成に分割**: MainFormをGameSectionPanel / StoreSectionPanel / SettingsSectionPanelに分離
- **プロジェクト名をGCTonePrism_Managerに統一**: slnx / csproj / AssemblyName をリネーム

#### Fixed

- **ゲームID変更時のDB制約エラー**: PRAGMA foreign_keysをトランザクション外で制御するよう修正
- **DataGridViewの初期選択ハイライト解除**: ゲーム・ストア一覧で起動時の意図しない行選択を解消
- **行ヘッダー（三角マーク）非表示**: ゲーム・ストア一覧で左端の行ヘッダーを非表示に
- **列ヘッダーの選択ハイライト無効化**: セル選択時に列ヘッダーが青くならないよう修正

### [Manager v0.7.0] - 2026-03-27

#### Added

- **StoreSection管理機能を追加**
  - `StoreSectionInfo` / `StoreSectionRepository` / `StoreSectionForm` / `StoreSectionListForm` を追加
  - セクションの追加・編集・削除・並び替え、`manual` セクションの `display_text` 管理を実装
- **MainFormにストア管理導線を追加**
  - ツールバーからStoreSection一覧を開けるように変更

#### Changed

- **DBスキーマをv8へ更新**
  - `V6 -> V7`: `store_sections` / `store_section_games` テーブルを追加
  - `V7 -> V8`: `store_sections.display_text` 列を追加
  - `DatabaseManager` にStoreSection操作APIを追加
- **ゲーム管理フォーム差分を反映**
  - `AddGameForm` / `EditGameForm` / `VersionUpForm` のフォーム本体・Designer・resx差分を反映

### [Manager v0.6.2] - 2026-03-21

#### Changed

- **Form群から共通ロジックをさらに抽出（Phase 2）**
  - `Services/GameFormHelper.cs`: ComboBox初期化、ジャンル操作、テスト起動、プレースホルダー設定、ファイル自動検出を共通化
  - `Services/PathConversionHelper.cs`: 相対パス⇔絶対パス変換を一元化（ToRelativePath, ToAbsolutePath, ConvertSourceToDestination, ToRelativePathAfterCopy）
  - AddGameForm/EditGameForm/VersionUpFormから約766行削減

#### Removed

- **未使用コード・ファイルの削除**
  - `FileVersioningHelper.cs`: 呼び出し元ゼロのデッドコードを削除（機能はFileOperationService・PathConversionHelperで代替済み）
  - `scene_manager.gd`（Launcher側）: AutoLoad未登録・参照なしの未使用スクリプトを削除
  - `EditGameForm.cs`内の60行の開発時メモコメントを整理

### [Manager v0.6.1] - 2026-03-21

#### Changed

- **DatabaseManager.cs をRepositoryパターンで分割**
  - 1,763行のファイルを責務ごとに分離
  - `DatabaseConnection.cs`: 接続管理、WALモード、リトライロジック
  - `SchemaManager.cs`: テーブル作成・マイグレーション
  - `Repositories/GameRepository.cs`: ゲームのCRUD操作
  - `Repositories/VersionRepository.cs`: バージョン管理のCRUD
  - `Repositories/DeveloperRepository.cs`: 開発者情報のCRUD
  - `DatabaseManager.cs` は既存コードとの互換性を保つファサードとして残存
- **Formファイル群から共通ロジックを抽出**
  - `Services/DeveloperListManager.cs`: 開発者DataGridView管理（AddGameForm, EditGameForm, VersionUpFormで共通化）
  - `Services/FileOperationService.cs`: ファイルコピー・進捗追跡（AddGameForm, MainFormで共通化）
  - `Services/ImagePreviewHelper.cs`: 画像プレビュー処理（全Formで共通化）
  - AddGameForm: 1,109行 → 814行
  - EditGameForm: 1,130行 → 917行
  - MainForm: 917行 → 777行
  - VersionUpForm: 735行 → 573行

### [Manager v0.6.0] - 2026-02-09

#### Added

- **ゲームバージョン管理機能の完全実装**
  - バージョンごとのゲーム情報（タイトル、実行ファイル、設定など）を個別に保存・管理可能に
  - **バージョン追加**: 現在のバージョンをベースに新規バージョンを作成
  - **バージョン切り替え**: プルダウンメニューで編集対象のバージョンを即座に切り替え
  - **アクティブバージョン設定**: ランチャーで起動するバージョンを選択可能に
- **UI/UXの改善**
  - **画像プレビュー機能**: サムネイルと背景画像のプレビューを追加（アスペクト比ヒント付き）
  - **テスト起動ボタン**: 編集画面から直接ゲームをテスト起動できるボタンを追加
  - **起動オプション（Arguments）設定**: バージョンごとに起動引数を設定可能に
  - **ウィンドウサイズ修正**: フォームの初期サイズが正しく設定されない問題を修正

#### Technical

- **データベーススキーマ更新 (v6)**
  - `game_versions` テーブルの拡充: タイトル、ジャンル、説明など全フィールドをバージョン管理対象に
  - `arguments` カラムの追加: `games` および `game_versions` テーブル
  - `games` テーブルへの同期ロジック: 選択されたバージョンの情報をメインテーブルに自動同期

#### Fixed

- **バージョン入力UIの改善**
  - バージョンアップ画面の初期値を `v` に設定（入力の手間を削減）
  - ゲーム追加画面の初期バージョンを `v1.0.0` に統一
  - 入力欄のレイアウト調整（ラベル被りを修正）
- **フォルダ構造の最適化**
  - バージョンフォルダの `v` プレフィックスを必須化し、統一された命名規則を適用

### [Manager v0.5.3] - 2026-02-08

#### Fixed

- **データベースマイグレーション処理の修正**
  - アプリ起動時に `supported_connection` カラムの存在チェックと自動追加を行うように修正
  - データベースバージョンに関わらず、不足しているカラムがある場合は自動的に修正されるように改善（自己修復機能）
- **UI文言の微調整**
  - アプリ起動時にデータベース競合防止のための警告メッセージ（1台での運用推奨）を追加
  - ゲーム追加・編集画面に「通信プレイ対応」の設定項目を追加（なし / ローカル通信 / オンライン通信）
  - データベースリセット画面の警告メッセージをよりユーモラスに変更（「リセット実行ボタンは押そうとすると逃げますので、頑張って押してください」）

### [Manager v0.5.2] - 2026-02-08

#### Added

- データベースバージョニング機能の実装
  - `DatabaseManager`クラスにスキーマバージョン管理機能を追加
  - アプリ起動時にデータベースバージョンをチェックし、自動的に最新版へマイグレーション
  - バージョン情報ダイアログにデータベース構造バージョン（v1）を表示
- `DatabaseManager` APIの改善
  - `GetMinDisplayOrder`メソッドの追加
  - `AddGame`, `UpdateGame`メソッドのシグネチャを`GameInfo`オブジェクトを受け取る形に統一

#### Fixed

- `DatabaseManager`のビルドエラー修正
  - `PathManager.GetDatabasePath()`メソッド呼び出しを`PathManager.DatabasePath`プロパティ参照に修正
  - `DeveloperInfo`モデルのプロパティ使用方法を修正（`GradeDisplay` -> `Grade`）
  - 開発者情報（`developers`）とジャンル（`genre`）のデータ型変換処理を修正

### [Manager v0.5.1] - 2025-12-27

#### Added

- ゲーム追加時の不要なフォルダスキップ機能
  - Unity、Unreal Engine、Godotなどの開発環境の不要なフォルダを自動スキップ
  - スキップ対象: Library, Temp, Intermediate, Saved, .import, .vs, .git, node_modulesなど
- 長いパス名のサポート
  - Windowsのパス長制限（260文字）を超える場合に`\\?\`プレフィックスを使用して対応
- データベース画面に製作者情報カラムを追加
  - 「姓 名 (期生)」形式で表示
  - 複数の製作者はカンマ区切りで表示

#### Changed

- ウィンドウタイトルを「ゲームセンターTONE Prism 管理ソフト」に変更
- データベース画面のカラム順序を調整
  - ゲームID → タイトル → リリース年 → 製作者 → ランチャー表示
- ランチャー表示カラムの幅を調整

#### Fixed

- ゲーム追加時の長いパス名によるエラーを修正
- 一部のファイルがコピーできない場合でも処理を続行するように改善

### [Manager v0.5.0] - 2025-12-27

#### Added

- ジャンルリストの拡張
  - ジャンル選択肢を16種類から22種類に拡張
  - 新規追加ジャンル: アーケード、RPG、カジュアル、ストラテジー、その他、ドライビング/レース、ホラー、ファミリー、シミュレーター、脳トレ、リズムアクション、クイズ、教育、フィットネス
- 期生入力欄に説明を追加
  - 「期生（0で教員）」と表示し、0を入力すると教員として扱われることを明示

#### Changed

- ジャンル名の変更・統合
  - 「ロールプレイング」→「RPG」
  - 「レース」→「ドライビング/レース」
  - 「音楽ゲーム」→「リズムアクション」
  - 「学習・教育」→「教育」
  - 「トレーニング」→「フィットネス」
- 削除されたジャンル: テーブルゲーム、コミュニケーション、ツール

### [Manager v0.4.1] - 2025-12-27

#### Fixed

- developers.last_nameがNULLの場合の処理を修正
  - `DatabaseManager.GetDevelopersByGameId`でlast_nameがNULLの場合にIsDBNullでチェックするように修正
  - `DeveloperInfo.FullName`でLastNameがNULLの場合はFirstNameのみを返すように修正

### [Manager v0.4.0] - 2025-12-27

#### Added

- SQLite同時アクセス対応機能
  - WAL（Write-Ahead Logging）モードの有効化
    - ランチャー起動中でも管理ソフトでデータベース操作が可能に
    - 既存データベースにも自動適用
  - リトライ機構の実装
    - ネットワークドライブ経由での一時的なロックエラーを自動リトライ
    - 最大3回リトライ、指数バックオフ（50ms, 100ms, 200ms）
    - 学校サーバー経由での使用に最適化

#### Changed

- データベース接続方式を改善
  - 接続文字列に`Journal Mode=WAL`と`Busy Timeout=5000`を追加
  - すべてのデータベース接続でWALモードを自動有効化

#### Fixed

- エラーハンドリングの改善
  - SQLiteExceptionを具体的に処理し、分かりやすいエラーメッセージを表示
  - データベースロック時: 「データベースが使用中です」メッセージ
  - データベース破損時: 「データベースが破損しています」メッセージ
  - その他のエラーも適切なメッセージを表示

#### Technical

- `OpenConnectionWithWalMode()`メソッドを追加（接続時にWALモードを確実に有効化）
- `ExecuteWithRetry<T>()`メソッドを追加（リトライ機構）
- `GetUserFriendlyErrorMessage()`メソッドを追加（エラーメッセージの改善）
- 主要な書き込み操作（AddGame, UpdateGame, DeleteGame）にリトライ機構を適用

### [Manager v0.3.0] - 2025-12-27

#### Added

- バージョン情報表示機能
  - 設定メニューに「バージョン情報」メニュー項目を追加
  - アセンブリ情報から製品名、バージョン、会社名、著作権情報を取得して表示
  - AssemblyInfo.csのAssemblyProductとAssemblyTitleをGCTonePrism_Managerに統一

### [Manager v0.2.0] - 2025-12-27

#### Added

- ジャンル選択機能の改善
  - マイニンテンドーストア準拠の16ジャンルを定義（GenreList.cs）
  - ジャンル入力UIをTextBoxからCheckedListBoxに変更（複数選択可能）
  - 既存のジャンルデータも正しく読み込めるように実装

#### Changed

- 製作者情報の登録ルールを変更
  - 姓（LastName）を空欄でも登録可能に変更
  - データベースのdevelopersテーブルのlast_nameカラムのNOT NULL制約を削除
  - 既存データベースのマイグレーション処理を追加
- ファイルパスの保存方式を変更
  - サムネイル・背景・実行ファイルのパスを相対パスで保存（games/{game_id}/フォルダからの相対パス）
  - サブフォルダ内のファイルも正しく相対パスで保存されるように改善
  - パス入力欄を編集可能に変更（ReadOnlyをfalseに）
- 実行ファイルの自動検出を改善
  - UnityCrashHandlerなどのクラッシュハンドラーを除外
  - 除外パターン: .console.exe, UnityCrashHandler64.exe, UnityCrashHandler32.exe など

#### Fixed

- ジャンルUIの表示崩れを修正（CheckedListBoxの高さと下のコントロールの位置を調整）
- IndexOutOfRangeExceptionを修正（CheckedListBoxの操作を安全に）
- サブフォルダ内の実行ファイルの相対パス保存を修正

#### Technical

- データベース確認ログに相対パス/絶対パスの判定を追加
- デバッグログを追加（開発時の確認用）

### [Manager v0.1.1] - 2025-12-26

#### Changed

- プロジェクトフォルダ名を`Manager`から`GCTonePrism_Manager`に変更

#### Fixed

- PathManagerの検出ロジックを簡素化（Launcherフォルダの検出ロジックを削除）
- GCTonePrism_Managerフォルダ内に実行ファイルがない場合のエラーチェックを追加
- 不正な配置での実行を防止（エラーメッセージを表示して起動を停止）

### [Manager v0.1.0] - 2025-12-26

マイルストーン2: 管理ソフト基本機能完成

#### Added

- 管理ソフトプロジェクトの新規作成（Windows Forms C#アプリケーション）
- PathManager: アプリケーションパス、データベースパス、ゲームフォルダパスの管理機能
- DatabaseManager: SQLiteデータベースの作成、初期化、操作機能
- データモデルの実装（GameInfo, DeveloperInfo, PlayRecord, Survey, Settings）
- Microsoft.Data.Sqliteパッケージの導入
- ゲーム追加機能（AddGameForm）
  - ゲームフォルダの選択とコピー
  - 実行ファイルの選択
  - サムネイル画像・背景画像の選択
  - ゲーム情報の入力（タイトル、説明、ジャンル、制作年など）
  - 製作者情報の追加・編集（DataGridViewを使用）
- ゲーム編集機能（EditGameForm）
  - 既存ゲーム情報の編集
  - 製作者情報の編集
- ゲーム削除機能
- ゲーム表示順序の変更機能（表示順序の並び替え）
- データベースリセット機能（確認ダイアログ付き）
- メイン画面（MainForm）の実装
  - ゲーム一覧の表示
  - ゲーム追加・編集・削除ボタン
  - データベースリセットボタン
- 製作者管理画面（DeveloperForm）の実装

#### Changed

- プロジェクトフォルダ名を`GCTonePrism.Manager`から`Manager`に変更
- プロジェクト名を`Manager`に変更（RootNamespaceとAssemblyNameを更新）

#### Fixed

- ゲーム追加時の画像ファイルのバリデーションを追加
- 期生入力フィールドを数値形式に変更

### Manager 将来のリリース予定

#### Manager 開発版（v0.x.x）

- **v0.1.0** (マイルストーン2): 管理ソフト基本機能完成
- **v0.2.0** (マイルストーン8): MVP対応版（ランチャーv1.0.0と連携）

#### Manager 正式リリース版（v1.0.0以降）

- **v1.0.0** (マイルストーン11): 管理ソフト完全版完成
- **v1.1.0** (マイルストーン12): 完全版リリース対応

---

## プロジェクトマイルストーン

開発の進捗管理用のマイルストーン一覧です。詳細は [SPECIFICATION.md](SPECIFICATION.md) を参照してください。

- **マイルストーン1**: Godotプロジェクトセットアップ完了
- **マイルストーン2**: 管理ソフト基本機能完成
- **マイルストーン3**: 基本画面・画面遷移
- **マイルストーン4**: データベース連携
- **マイルストーン5**: ゲーム表示・選択機能
- **マイルストーン6**: ゲーム起動機能
- **マイルストーン7**: UI完成・ゲーム情報詳細表示
- **マイルストーン8**: MVP完成
- **マイルストーン9**: 監視ソフト基本機能完成
- **マイルストーン10**: 基本機能完成
- **マイルストーン11**: データ管理機能完成
- **マイルストーン12**: 管理ソフト完全版完成
- **マイルストーン13**: 完全版リリース

---

<!--
参照リンク定義 (Markdown reference-style links resolve target)

Bundle 移行後 (2026-05-11 以降): GitHub Releases tag は Bundle 単位 (`v<X.Y.Z>` 形式) のみ。
個別 component (Launcher / Manager / Updater / Release Tooling) は Bundle release に同梱され
独立 tag を持たないため、本ファイル本文中の `### [Launcher v0.5.17]` 等の角括弧見出しは
Markdown 上 dangling reference (text として表示、リンクとして機能しない) になる。これは
SPEC §3.7.7「Bundle release が SoT」規約準拠の意図的な状態で、本文情報は `## Bundle`
entry 経由か commit 履歴で追跡可能。

Bundle 移行前 (2026-03 まで): Launcher / Manager の個別 GitHub Releases tag (`Launcher_v0.5.7`
/ `Manager_v0.7.6` 等) は実在するため、過去履歴として参照リンク定義を残置。

新規 Bundle release 時は本ブロックに `[Bundle vX.Y.Z]: <URL>` を追加すること。**追加位置は
既存 `[Bundle vX.Y.Z]:` 行群の先頭 (降順を維持、本コメント直下)** とする (= 新しいほど上)。
AGENTS.md "Release and Versioning" 規約、Release.ps1 の `Assert-ChangelogLinkDefs` が検証
して未追加なら Fail で停止する。

footer marker sentinel (Release.ps1 Assert-ChangelogLinkDefs が `LastIndexOf` で探して、
以降を footer block として match 対象にする)。本 sentinel 文字列を変更する場合は
Release.ps1 の $FooterSentinel 定数も同期更新すること。

  round 5 で `LastIndexOf('-->')` から明示 sentinel ベースに切替、round 6 で sentinel 文字列を
  body text に literal 出現しない ALL CAPS unique 形式に変更 + `LastIndexOf` 採用で二重防御。
  body 内で sentinel を引用する場合があっても末尾の本物の sentinel が選ばれる構造。
-->

<!-- GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1 -->

[Bundle v0.11.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.11.0
[Bundle v0.10.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.10.0
[Bundle v0.9.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.9.0
[Bundle v0.8.3]: https://github.com/ken1208git/TonePrism/releases/tag/v0.8.3
[Bundle v0.8.2]: https://github.com/ken1208git/TonePrism/releases/tag/v0.8.2
[Bundle v0.8.1]: https://github.com/ken1208git/TonePrism/releases/tag/v0.8.1
[Bundle v0.8.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.8.0
[Bundle v0.7.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.7.0
[Bundle v0.6.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.6.0
[Bundle v0.5.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.5.0
[Bundle v0.4.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.4.0
[Bundle v0.3.1]: https://github.com/ken1208git/TonePrism/releases/tag/v0.3.1
[Bundle v0.3.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.3.0
[Bundle v0.2.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.2.0
[Bundle v0.1.0]: https://github.com/ken1208git/TonePrism/releases/tag/v0.1.0
[Launcher Unreleased]: https://github.com/ken1208git/TonePrism/compare/launcher-v0.1.0...HEAD
[Launcher v0.5.7]: https://github.com/ken1208git/TonePrism/releases/tag/Launcher_v0.5.7
[Launcher v0.4.5]: https://github.com/ken1208git/TonePrism/releases/tag/Launcher_v0.4.5
[Launcher v0.4.3]: https://github.com/ken1208git/TonePrism/releases/tag/Launcher_v0.4.3
[Manager v0.7.6]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.7.6
[Manager v0.6.0]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.6.0
[Manager v0.5.1]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.5.1
[Manager v0.5.0]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.5.0
[Manager v0.4.1]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.4.1
[Manager v0.4.0]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.4.0
[Manager v0.3.0]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.3.0
[Manager v0.1.1]: https://github.com/ken1208git/TonePrism/releases/tag/Manager_v0.1.1
[Manager v0.1.0]: https://github.com/ken1208git/TonePrism/releases/tag/manager-v0.1.0
