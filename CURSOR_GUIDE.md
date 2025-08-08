# Cursor 開発ガイド（最小版）

## 1. 読む順番（重要度順）
- Primary: `README.md`
- Secondary: `cursor_log.md`
- 必読リファレンス: `project.godot`, `Global.gd`

## 2. 起動シーケンス（毎セッション）
1) 上のファイルを読む → 2) リポジトリ構造を把握 → 3) 必要なら `gh issue list` で未解決Issue確認

## 3. 運用原則（絶対）
- コミット前に必ず `cursor_log.md` に「目的・変更・影響・次アクション」を1ブロック追記
- 文字化け禁止（UTF-8）。不要な広範囲リライト禁止。

## 4. 回答スタイル（AIへの期待値）
- 日本語、Godot 4.2前提。`ファイル/関数/クラス名`はバッククォートで明示。
- コードはタブインデント（GDScript）。説明は短く、必要十分に。

## 5. よく使うコマンド
- エディタ起動: `godot -e --path .`
- 実行: `godot --path .`
- Issue確認: `gh issue list`
