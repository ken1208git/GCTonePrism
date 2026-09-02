using System;
using System.IO;
using System.Text;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// `<install>/responses/launcher_logs_root.json` の atomic write helper。
    ///
    /// Manager 側の SoT (= SQLite `logs_root_path` 設定) を Launcher が autoload 最先頭 init 時に
    /// 読み取れる形で公開する drop file pattern (= SessionHeartbeat の atomic write pattern を踏襲、
    /// SPEC §6.5 「Launcher は SQLite write しない」原則を維持しつつ Manager → Launcher 単方向で
    /// 設定値を伝搬する経路)。
    ///
    /// Schema (JSON):
    /// <code>
    /// {
    ///   "schema_version": 1,
    ///   "logs_root_path": "&lt;absolute path or empty for default&gt;",
    ///   "updated_at_unix_ms": 1234567890000
    /// }
    /// </code>
    ///
    /// **`schema_version` の forward-compat 意図 (R5 review Low-5)**: 現状 Launcher reader は本 field を
    /// 読まず `logs_root_path` を直接参照する (= v1 のみなので gating 不要)。将来 format 互換性 break が
    /// 必要になった時 (= v2 で field 構造変更等)、Launcher 側に「`schema_version > 1` なら warn + default
    /// fallback」guard を追加するための予約 field。本 PR では writer が version を書き、reader 側 gating は
    /// 別 issue で追加検討 (= 当面 v1 固定のため無害)。
    ///
    /// 呼出箇所:
    /// 1. `Program.Main` の Logger.Initialize 直後 (= 毎起動時 sync、user が直接 file を削除した case を回復)
    /// 2. `SettingsSectionPanel.ApplyLogSection` 内 (= UI 変更時即時 sync、Launcher 次回起動で picked up)
    ///
    /// 例外は内部で握り潰し、Manager 起動 / UI 操作を阻害しない (= SPEC §3.6 「Logger 自身の障害は
    /// 握り潰す」と同じ defensive 規約)。
    /// </summary>
    public static class LauncherLogsRootBridge
    {
        private const string FileName = "launcher_logs_root.json";

        /// <summary>
        /// 現在の `logs_root_path` 値 (= 設定が空なら "" を渡す) を JSON file に **near-atomic** write する。
        /// 書出先 dir が存在しなければ作成、既存 file は overwrite。
        /// **near-atomic 制約**: `.tmp` 書出 → Delete + Move pattern で Delete と Move の間に target が一瞬
        /// 不在になる window が残る (= .NET Framework 4.x の `File.Move` が overwrite 対応していないため
        /// 真の atomic 化には Win32 `MoveFileEx(MOVEFILE_REPLACE_EXISTING)` が必要)。
        /// **Launcher 側影響**: reader (Launcher Logger) が **ちょうど window 中に init で読込んだ場合**、
        /// file 不在 → default fallback path に倒れ、**Launcher 1 セッション分の log が user 意図と異なる
        /// 場所に書かれる**。user 通知一切なし、Launcher 起動は阻害されない (= safe path)。LAN 50 PC 同時起動
        /// 等で window 衝突確率が無視できない場合、別 PR で `MoveFileEx` P/Invoke 化を検討すべき。
        ///
        /// **multi-Manager race による transient mismatch (R4 review H-2)**: LAN で複数 PC の Manager が
        /// ほぼ同時に `ApplyLogSection` 通過 (= CheckBeforeWrite 通過後 race) した場合、SQLite write
        /// → bridge write の順で **caller の local 値を書出**ているため、(1) PC-A SetString → (2) PC-B
        /// SetString → (3) PC-A WriteCurrentLogsRoot(自分の値) → (4) PC-B WriteCurrentLogsRoot(自分の値) の
        /// interleave で bridge file 内容と SQLite 最新値が transient に食い違う path がある。**Self-heal**:
        /// 次回 Manager 起動の Program.Main で SQLite SoT から再書出されるため恒久 hazard ではない。
        /// **user 通知なし、Launcher 1 セッション分の log dir が SQLite SoT と食い違う**可能性。本 PR では
        /// 受容、Bridge を SQLite re-read 化は別 PR で検討。
        ///
        /// **UI 経路の silent swallow (R4 review L-3)**: 全例外を catch → `Logger.Warn` 試行のみで return void。
        /// `ApplyLogSection` の UI save 経路で bridge write 失敗時、user は「保存成功」UI feedback を
        /// 受けるが Launcher は次回 Manager 再起動まで新値を見ない (= self-heal するが timing 遅延)。
        /// 本 PR では受容、UI に dialog 通知する強化は別 PR で検討 (= 当面 Logger trail で十分)。
        /// </summary>
        public static void WriteCurrentLogsRoot(string logsRootPath)
        {
            try
            {
                string responsesDir = PathManager.ResponsesFolder;
                Directory.CreateDirectory(responsesDir);
                string targetPath = Path.Combine(responsesDir, FileName);
                string tmpPath = targetPath + ".tmp";

                long unixMs = (long)(DateTime.UtcNow - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalMilliseconds;
                string normalized = logsRootPath ?? string.Empty;
                string json = "{"
                    + "\"schema_version\":1,"
                    + "\"logs_root_path\":\"" + JsonEscape.EscapeString(normalized) + "\","
                    + "\"updated_at_unix_ms\":" + unixMs
                    + "}";

                File.WriteAllText(tmpPath, json, new UTF8Encoding(false));
                if (File.Exists(targetPath)) File.Delete(targetPath);
                File.Move(tmpPath, targetPath);
            }
            catch (Exception ex)
            {
                // Logger 未初期化の case もあるため try-catch で防御 (= Program.Main 初期段階呼出 path 用)
                try { Logger.Warn("[LauncherLogsRootBridge] launcher_logs_root.json 書込失敗: " + ex.Message); }
                catch { /* swallow (= Logger 自体が未初期化 / 失敗中) */ }
            }
        }
    }
}
