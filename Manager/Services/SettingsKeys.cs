namespace TonePrism.Manager.Services
{
    /// <summary>
    /// `settings` テーブル (汎用 K/V) で使う key 定数を集約する。
    ///
    /// SettingsRepository は ON CONFLICT(key) DO UPDATE で動く汎用 K/V store のため、新規 key の
    /// 追加に schema migration は不要 (CurrentDbVersion bump 不要)。本 class はリポジトリ全体で
    /// 同じ文字列キーを参照するための SoT (typo 防止 + grep 一発で全用例検出)。
    ///
    /// Phase 4 (#108) で導入: アップデート check の cache、skip 機能、background check の頻度
    /// 設定をすべて settings テーブル経由で永続化する (Manager 再起動を跨いでも保持されるよう)。
    ///
    /// **SQL literal 埋込制約 (R4 review L-2)**: 一部 const は `Program.ReadInitialLogSettingsWithMigration`
    /// 等で SQL 文字列に **string concatenation で埋込まれる** (= parameterized query ではない、`AddWithValue`
    /// は value のみ)。そのため **const 値は alphanumeric + underscore のみ** に制限すること。`'` 含めると
    /// SQL 構文 break + 仮に外部流入時は injection hazard。新 key 追加時に literal を遵守。
    /// </summary>
    internal static class SettingsKeys
    {
        // ----- backup 既存 (settings テーブルに既に存在) -----
        // backup 設定系 (`backup_destination_path` / `backup_retention_count` / `last_backup_at`) で使う key。
        // 既存実装に合わせて参照しない (本クラスでラップしない方が既存コードを書き換える scope creep を防げる)。
        // (#295) backup_auto_interval_hours / TryAcquireBackupLease は操作単位トリガ移行で撤去。
        // (#170 followup) 旧 BackupSettingsForm modal は廃止、設定タブ内 grpBackup section に inline 統合
        // (SettingsSectionPanel.LoadBackupSettings + grpBackup の per-control event handler 群:
        //  TxtBackupDest_Leave / NumBackupRetention_ValueChanged / ChkBackupAutoEnabled_CheckedChanged)。
        //  round 1 で「保存ボタン廃止 + per-control immediate save」に方針転換、btnBackupSave は実体なし。
        //  (#295) 時間間隔 UI 撤去で NumBackupInterval_ValueChanged / CmbBackupIntervalUnit_SelectedIndexChanged も撤去。

        // ----- Phase 4 (#108) update flow -----

        /// <summary>
        /// 「このバージョンをスキップ」で記録される Bundle version (例: "0.3.0")。
        /// (#108 Phase 4 round 3 L-5 / round 6 H-1 docstring 反映) UpdateChecker.ShouldNotify は
        /// `latest != skipped` の **厳密一致比較** で再通知判定する (同 tag のみ通知抑止、新 tag が
        /// 出れば通知再開)。`latest < skipped` の downgrade release も「同 tag でなければ新 release
        /// 扱い」で通知する自然な挙動。空文字 / 不在 = skip 履歴なし。
        ///
        /// 旧 docstring は `latest > skipped` の累積 skip semantic を主張していたが round 3 L-5 で実装
        /// 変更済、本 round 6 H-1 で XML doc を実装と同期 (IntelliSense / hover tooltip が authoritative
        /// な契約として読まれるため non-XML コメントだけでは不十分)。
        /// </summary>
        public const string UpdateSkippedVersion = "update_skipped_version";

        /// <summary>
        /// 直近の GitHub Releases API 呼び出し時刻 (Unix epoch milliseconds)。
        /// `UpdateCheckIntervalHours` を超過したら次回 fetch を許可する。
        /// 0 / 不在 = 一度も check していない (起動直後)。
        /// </summary>
        public const string UpdateCheckLastAtUnixMs = "update_check_last_at_unix_ms";

        /// <summary>
        /// 直近の API check 結果を JSON serialize した文字列 (UpdateCheckResult 相当)。
        /// 起動時に hydrate して UI に「最新版あり / なし」を即時表示する用途。
        /// API 失敗時 / cache 有効 case でも前回 cache を表示し続ける fault-tolerance に使う。
        /// 空文字 / 不在 = cache なし。
        /// </summary>
        public const string UpdateCheckCachedJson = "update_check_cached_json";

        /// <summary>
        /// バックグラウンド check の interval (時間単位、default 6)。学校 LAN で複数 PC が
        /// 同時に GitHub API を叩いて 60 req/hour rate limit に当たるのを mitigate。
        /// 設定値の override は Manager UI からは提供しない (運用上 default 固定で十分)。
        /// </summary>
        public const string UpdateCheckIntervalHours = "update_check_interval_hours";

        public const int DefaultUpdateCheckIntervalHours = 6;

        /// <summary>
        /// (#108 Phase 4 round 2 codex P2) 起動時通知 dialog を出した最後の tag 名。`UpdateAvailable`
        /// 検出時にこの値と比較し、同 tag なら通知 skip (= user が「いいえ」で延期した直後の再起動で
        /// 再度同じ dialog が出る UX を抑制)。新 release が出て tag が変われば自動的に notify 再開。
        /// 空文字 / 不在 = 通知履歴なし (= 通知する)。
        /// </summary>
        public const string UpdateNotifiedTag = "update_notified_tag";

        // ----- (#170 followup) Logger retention / destination -----

        /// <summary>
        /// ログファイル保存日数 (default 30)。`Logger.CleanupOldLogs(days)` が起動時 1 回読込み、
        /// 該当日数より古い `manager_*.log` を mtime 基準で削除。設定 UI (SettingsSectionPanel の
        /// grpLog) から変更可、**反映は次回 Manager 起動時** (= 設定 UI 上に明示ラベル)。
        /// 旧実装は `Logger.cs:RetentionDays = 30` の hardcode、本 followup で K/V 化。
        /// </summary>
        public const string LogRetentionDays = "log_retention_days";

        public const int DefaultLogRetentionDays = 30;

        /// <summary>
        /// **DEPRECATED (v0.15.0 で `LogsRootPath` に統合、auto-migrate 対象)**。
        /// 旧 semantic: Manager log だけが直配置される dir (= `<value>/manager_*.log` 直書き、Launcher / Updater
        /// は別管理)。v0.15.0 起動時に `ReadInitialLogSettingsWithMigration` で値を `logs_root_path` に copy + 旧 key DELETE。
        /// 本 const は **`ReadInitialLogSettingsWithMigration` 内の SQL 構築 (= SELECT key list / WHERE / DELETE / dual-set cleanup の 4 箇所) でのみ参照**、UI / runtime path 解決からは削除済。
        /// **廃止条件**: 旧 v0.14.0 setting を持つ install が事実上全て v0.15.0+ に migration 済と見なせる段階で本 const + migration code を一括削除可能。
        /// </summary>
        public const string LogDestinationPath = "log_destination_path";

        /// <summary>
        /// (#201、v0.15.0) ログ全体の親 root directory の絶対 path (空文字 / 不在 = default の
        /// `&lt;project_root&gt;/logs/` を使用)。指定先には `manager/` `launcher/` `updater/` `monitor/` の
        /// subdir が **各 component の Logger により自動作成**される (= subdir append は consumer 側責務)。
        /// 設定 UI から変更可、**反映は次回 Manager 起動時 + 次回 Launcher 起動時の 2 段**。
        /// Manager は Program.Main で Logger.Initialize 前に SQLite 直接 read で取り出して
        /// PathManager.SetLogsRootDirectory に渡す (= Logger は SettingsRepository に依存しない invariant を維持)。
        /// Launcher は同値を `responses/launcher_logs_root.json` 経由で受取 (= SPEC §6.5 Launcher SQLite write 禁止
        /// 原則維持、Logger の autoload 最先頭 init 時に DB 接続前で完結する file read のみ)。
        /// </summary>
        public const string LogsRootPath = "logs_root_path";

        // ----- (#170 followup round 2) 自動バックアップの有効/無効 -----

        /// <summary>
        /// 自動バックアップを実行するかどうか ("true"/"false")。default "true" (= 有効、既存挙動)。
        /// UI 設定タブ「バックアップ」section の checkbox から変更可、UI 上で OFF にすると自動 backup の
        /// 起動時 trigger を完全に skip する (= 手動バックアップは引き続き使える)。
        ///
        /// (#170 followup round 2 review L-2) **比較は `"false"` 厳密一致 (case-insensitive)、それ以外
        /// (空 / "true" / unknown / "1" / "0" 等) はすべて enabled 扱い**。手動 DB 編集で誤った値を入れても
        /// default "true" semantic に safely fall through する設計、UI からは必ず "true"/"false" のみ書込まれる。
        /// </summary>
        public const string BackupAutoEnabled = "backup_auto_enabled";

        // (#295) 旧「バックアップ自動間隔の表示単位」key (backup_auto_interval_unit + "hours"/"days") は、
        // 起動時の時間間隔トリガ廃止 (操作単位トリガ = SessionBackupCoordinator へ移行) に伴い撤去。

        // ----- (#250 PR1) アセット控え (games/ + guide/ の共有プール (CAS / SHA-256) バックアップ) -----

        /// <summary>
        /// (#250) DB バックアップと同時に games/ + guide/ を共有プール (CAS) で控えるか ("true"/"false")。default "true"。
        /// 比較は `BackupAutoEnabled` と同じく **"false" 厳密一致 (case-insensitive) のみ無効、それ以外はすべて有効扱い**
        /// (手動 DB 編集耐性)。値は SQL literal 制約 (alphanumeric + underscore) 準拠。
        /// (round9) UI からは設定不可の隠し既定 true。DB+ゲーム本体は 1 バックアップとしてまとめて取得し、保持世代数も
        /// `backup_retention_count` に統一したため専用 retention key は廃止 (この enable は将来/開発用の escape hatch として残置)。
        /// </summary>
        public const string AssetSnapshotEnabled = "asset_snapshot_enabled";

        // ----- (H5) リストア中の advisory lock -----

        /// <summary>
        /// (H5) リストア進行中の advisory lock。値形式: "<pcName>|<unixMs>"。空文字 / 不在 = lock なし。
        /// RestoreService が Restore() 開始時に書込み、終了 (success/failure/cancel) で削除する。
        /// 他 PC の Manager は SessionConflictHelper.CheckBeforeWrite で本 key を読み、自 PC 以外が保有 +
        /// 5 分以内 (= stale でない) なら書込操作を block する。File.Replace の atomic 性自体は OS 任せだが、
        /// 「他 PC が今まさに復元中」という状態を user/自動 path 双方に伝える coordination layer。
        /// </summary>
        public const string RestoreLockOwner = "restore_lock_owner";

        /// <summary>
        /// (H5) RestoreLockOwner の stale 判定 (= lock 取得 PC が crash した場合の自動失効) 閾値、ミリ秒単位。
        /// 5 分 = 300_000 ms。通常の restore は 1 分以内で完了する想定なので、5 分超過は確実に異常 (crash 等)。
        /// </summary>
        public const long RestoreLockStaleThresholdMs = 5L * 60 * 1000;

        // ----- (ダッシュボード) 要対応チェックリストで × した finding -----

        /// <summary>
        /// (ダッシュボード) チェックリストで「×（非表示）」にした finding の ID を改行区切りで保持する。
        /// 値は SetString の AddWithValue param 経由で書くため任意文字可 (本クラス冒頭の literal 制約は key 名のみ)。
        /// 新規 key = settings への行追加に過ぎず schema migration / CurrentDbVersion bump は不要。
        /// </summary>
        public const string DashboardDismissedFindings = "dashboard_dismissed_findings";

        // ----- (#297 PR2) プレイ記録・アンケート JSON 用の不変キー -----

        /// <summary>
        /// (#297 PR2 / DB v24) `games.game_no` の採番カウンタ (high-water mark = 最後に払い出した番号)。
        /// 単調増加のみで、ゲームを削除しても下がらない。
        ///
        /// **なぜ MAX(game_no)+1 ではなくカウンタなのか**: 最大番号のゲームを削除すると `MAX+1` は
        /// その番号を再利用してしまい、次に追加したゲームが削除済みゲームの過去のプレイ記録・アンケートを
        /// 横取りする (JSON 側は番号しか持たないので気づけない = 静かなデータ破損)。high-water mark なら
        /// 一度使った番号は永久に再利用されない。
        ///
        /// 読み書きは <c>SchemaManager.ReadGameNoHighWaterMark</c> /
        /// <c>SchemaManager.AllocateNextGameNo</c> 経由 (呼び出し側の transaction 内で実行するため
        /// SettingsRepository は使わない。SettingsRepository は自前で connection を開くので、
        /// ゲーム追加の transaction と別 transaction になり atomic 性が崩れる)。
        /// </summary>
        public const string GameNoSeq = "game_no_seq";
    }
}
