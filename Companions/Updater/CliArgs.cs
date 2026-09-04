using System;
using System.Collections.Generic;

namespace TonePrism.Updater
{
    /// <summary>
    /// Updater の CLI 引数モデル + parser。
    ///
    /// 想定呼出し (Manager から):
    ///   TonePrism_Updater.exe ^
    ///     --staging "C:\Users\user\AppData\Local\Temp\TonePrism_update_0.2.1\" ^
    ///     --manager-target "D:\Games\TonePrism\Manager\" ^
    ///     --restart-exe "D:\Games\TonePrism\Manager\TonePrism_Manager.exe" ^
    ///     --log-dir "D:\Games\TonePrism\logs\updater\"
    ///
    /// 引数仕様 (SPEC §3.7.4):
    ///   --staging          (必須) source dir のルート。`&lt;source&gt;/files/Manager/` を新 Manager のソースとする。
    ///                      Phase 3 までは Manager UI が `--staging &lt;staging dir&gt;` を渡して Updater は
    ///                      `&lt;staging&gt;/files/Manager` を見ていた。Phase 4.1 (#175) で Manager UI 側 zip
    ///                      構造が `bundle/files/Manager` に変わったため、Manager UI は **bundle root**
    ///                      (`&lt;staging&gt;/bundle`) を `--staging` 値として渡す形に。Updater 側 (本 CLI) は
    ///                      flag 名 + 「`&lt;source&gt;/files/Manager` を見る」semantic を維持 (= caller 互換、
    ///                      v0.3.0 install から spawn される旧 Updater も同 flag で動く)
    ///   --manager-target   (必須) 既存 Manager dir。rename-rollback で置換する dir
    ///   --restart-exe      (必須) 置換後に起動する Manager.exe フルパス
    ///   --log-dir          (任意) ログ出力先。省略時は `<install>/logs/updater/` (manager-target の親から導出、SPEC §3.7.4 準拠)
    ///   --wait-timeout     (任意) Manager プロセス終了待ちの timeout 秒数 (default: 60、0 = 無制限待機)
    ///   --force-kill       (任意) timeout 経過後に Manager を強制 kill するか (default off)
    ///   --caller-pid       (任意) Updater を spawn した Manager の PID。指定時は PID-only で wait/kill (同 PC の他 install Manager を巻き添えにしない)。未指定時は system-wide GetProcessesByName fallback (Codex round 2 P1 #1)
    ///
    /// 引数 parse 失敗時は ArgumentException を投げる (Program.cs 側で catch + Logger.Error + exit 2)。
    /// </summary>
    internal sealed class CliArgs
    {
        public string StagingDir { get; private set; }
        public string ManagerTargetDir { get; private set; }
        public string RestartExe { get; private set; }
        public string LogDir { get; private set; }
        public int WaitTimeoutSeconds { get; private set; } = 60;
        public bool ForceKill { get; private set; }
        // -1 = 未指定 (system-wide GetProcessesByName fallback、Codex round 2 P1 #1 で acknowledged
        // した「同 PC 全 Manager 巻き添えリスク」を回避するため、Manager UI (Phase 4) は自身の
        // PID を `--caller-pid <PID>` で渡すこと推奨。指定時は GetProcessById で PID-only wait/kill)
        public int CallerPid { get; private set; } = -1;

        public static CliArgs Parse(string[] args)
        {
            if (args == null) throw new ArgumentException("引数が null です");

            var result = new CliArgs();
            for (int i = 0; i < args.Length; i++)
            {
                string key = args[i];
                switch (key)
                {
                    case "--staging":
                        result.StagingDir = ReadValue(args, ref i, key);
                        break;
                    case "--manager-target":
                        result.ManagerTargetDir = ReadValue(args, ref i, key);
                        break;
                    case "--restart-exe":
                        result.RestartExe = ReadValue(args, ref i, key);
                        break;
                    case "--log-dir":
                        result.LogDir = ReadValue(args, ref i, key);
                        break;
                    case "--wait-timeout":
                        string ts = ReadValue(args, ref i, key);
                        int t;
                        if (!int.TryParse(ts, out t) || t < 0)
                        {
                            throw new ArgumentException($"--wait-timeout は 0 以上の整数を指定してください: '{ts}'");
                        }
                        result.WaitTimeoutSeconds = t;
                        break;
                    case "--force-kill":
                        result.ForceKill = true;
                        break;
                    case "--caller-pid":
                        string pidStr = ReadValue(args, ref i, key);
                        int pid;
                        if (!int.TryParse(pidStr, out pid) || pid <= 0)
                        {
                            throw new ArgumentException($"--caller-pid は正の整数を指定してください: '{pidStr}'");
                        }
                        result.CallerPid = pid;
                        break;
                    case "--help":
                    case "-h":
                    case "/?":
                        throw new ArgumentException("HELP");
                    default:
                        throw new ArgumentException($"未知の引数: '{key}'");
                }
            }

            ValidateRequired(result);
            // path 引数 4 種を絶対パス化 (シニアレビュー round 1 M3 + L4)。
            //   - Manager UI (Phase 4) が相対 path を渡すケース、または OS テスト等で相対 path を
            //     渡された場合、Updater は spawn 元の CWD に依存して動く silent path があった。
            //   - Path.GetFullPath で正規化することで、後段の Logger / FileReplacer / Process.Start
            //     全箇所で path の絶対性を仮定できる。`"\\"` のような病的入力も `"C:\"` 等の
            //     drive root absolute path に正規化されるので L4 も副次的に解消。
            //
            // catch 範囲 (シニアレビュー round 2 M2): GetFullPath 公式契約のうち「引数自体の不備」
            // 系の例外のみ ArgumentException に変換 (= exit 2 引数エラー、user の入力ミスを明示)。
            //   - ArgumentException: null / 空 / invalid characters
            //   - PathTooLongException: MAX_PATH (260) 超過
            //   - NotSupportedException: ":" 含む (drive letter 以外) など
            // それ以外 (SecurityException / UnauthorizedAccessException 等の権限・環境問題) は
            // throw を抜けて Program.cs Main の `catch (Exception)` で exit 1 (予期しない例外) に倒す
            // (round 6 Codex P2 で追加した、ArgumentException catch の後段にある catch block)。
            // 「引数エラー」表記の正確性を保ち、Manager UI 側の障害解析を misleading にしない。
            // (round 8 Medium-2: 行番号 `Program.cs:77` 参照は round 6 の Main 拡張で rot していたため
            // 削除、関数名引用に置換。round 7 Low-1 の同型 stale 参照削除の漏れ補完。)
            try
            {
                result.StagingDir = System.IO.Path.GetFullPath(result.StagingDir);
                result.ManagerTargetDir = System.IO.Path.GetFullPath(result.ManagerTargetDir);
                result.RestartExe = System.IO.Path.GetFullPath(result.RestartExe);
                if (!string.IsNullOrEmpty(result.LogDir))
                {
                    result.LogDir = System.IO.Path.GetFullPath(result.LogDir);
                }
            }
            catch (ArgumentException ex)
            {
                throw new ArgumentException($"path 引数の絶対パス化に失敗 (引数不備): {ex.Message}", ex);
            }
            catch (System.IO.PathTooLongException ex)
            {
                throw new ArgumentException($"path 引数が長すぎます (MAX_PATH 260 超過): {ex.Message}", ex);
            }
            catch (NotSupportedException ex)
            {
                throw new ArgumentException($"path 引数の形式がサポートされません: {ex.Message}", ex);
            }

            // round 4 M-3: restart-exe は --manager-target 配下の path しか許可しない。
            //   旧実装は `File.Exists(RestartExe)` だけ check していたため、caller (Manager UI Phase 4) の
            //   typo で `--restart-exe C:\Windows\System32\calc.exe` のような誤 path が渡されると、
            //   Updater は新 Manager dir を置き換えた後に calc.exe を起動して exit 0 で抜ける silent
            //   failure path が残っていた。Manager UI 側は「アップデート成功」表示 → 部員 / 顧問は
            //   新 Manager が起動したと信じる mismatch。
            //   round 2 L2 (target 不在 typo を Error + return false) と同じ防御方針で、引数解析時に
            //   引数エラー (exit 2) として早期 fail させる。
            //
            //   比較ロジック: 両 path とも GetFullPath 済の絶対 path。末尾 separator 揺れを TrimEnd で
            //   吸収し、`{ManagerTargetDir}{separator}` で始まることを check (大文字小文字無視、
            //   Windows path 規約)。`--manager-target D:\Manager` + `--restart-exe D:\ManagerExtra\foo.exe`
            //   のような prefix 偶然衝突を separator check で除外。
            string normalizedTarget = result.ManagerTargetDir.TrimEnd('\\', '/');
            string targetWithSep = normalizedTarget + System.IO.Path.DirectorySeparatorChar;
            if (!result.RestartExe.StartsWith(targetWithSep, StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException(
                    $"--restart-exe は --manager-target 配下を指定してください (caller の typo 防止)。\n" +
                    $"  --manager-target: {result.ManagerTargetDir}\n" +
                    $"  --restart-exe:    {result.RestartExe}");
            }
            return result;
        }

        private static string ReadValue(string[] args, ref int i, string key)
        {
            if (i + 1 >= args.Length)
            {
                throw new ArgumentException($"{key} に値が指定されていません");
            }
            // round 5 M-2: 次トークンが `--` で始まる場合は別の引数なので value としては不正。
            //   旧実装は `--staging --manager-target D:\Manager\ ...` のような value 1 つ忘れ
            //   パターンで `--manager-target` を `--staging` の値として吸収 → 次 iter で
            //   `D:\Manager\` が「未知の引数」として throw する misleading な error path に
            //   流れていた。Phase 4 で Manager UI が `--restart-exe "$emptyVar"` のような
            //   引数を組み立てて変数が空展開する case も同じ症状なので、明示 check で
            //   user-facing error をまっとうな「値が指定されていません (次トークンが別の
            //   引数)」に倒す。
            //   なお負数や `--` 単独 token を value として渡すケースは現状なし
            //   (--wait-timeout / --caller-pid は正の整数のみ受理)。将来のためには
            //   `--` (POSIX-style end-of-options) を別途 handling すれば拡張可能。
            string next = args[i + 1];
            if (next.StartsWith("--", StringComparison.Ordinal))
            {
                throw new ArgumentException($"{key} の値が指定されていません (次トークンが別の引数 '{next}'、value 忘れ疑い)");
            }
            i++;
            return next;
        }

        private static void ValidateRequired(CliArgs a)
        {
            var missing = new List<string>();
            if (string.IsNullOrEmpty(a.StagingDir)) missing.Add("--staging");
            if (string.IsNullOrEmpty(a.ManagerTargetDir)) missing.Add("--manager-target");
            if (string.IsNullOrEmpty(a.RestartExe)) missing.Add("--restart-exe");
            if (missing.Count > 0)
            {
                throw new ArgumentException($"必須引数が不足: {string.Join(", ", missing)}");
            }
        }

        public static string UsageText()
        {
            return
                "TonePrism_Updater - Manager 置換 + 再起動の最小 CLI (SPEC §3.7.4)\n" +
                "\n" +
                "Usage:\n" +
                "  TonePrism_Updater.exe --staging <path> --manager-target <path> --restart-exe <path>\n" +
                "                          [--log-dir <path>] [--wait-timeout <seconds>] [--force-kill]\n" +
                "                          [--caller-pid <PID>]\n" +
                "\n" +
                "Required:\n" +
                "  --staging <path>          source dir のルート (中の files/Manager/ をソースに使う)\n" +
                "                            Phase 4.1 (#175): Manager UI は bundle root (<staging>/bundle) を渡す。\n" +
                "  --manager-target <path>   置換先の既存 Manager dir\n" +
                "  --restart-exe <path>      置換後に起動する Manager.exe のフルパス\n" +
                "\n" +
                "Optional:\n" +
                "  --log-dir <path>          ログ出力先 (default: <install>/logs/updater/、manager-target の親から導出、SPEC §3.7.4 準拠)\n" +
                "  --wait-timeout <seconds>  Manager プロセス終了待ちの timeout (default: 60、0 = 無制限待機)\n" +
                "  --force-kill              timeout 経過後に Manager を強制終了する\n" +
                "  --caller-pid <PID>        Updater を spawn した Manager の PID。指定時は PID-only で wait/kill\n" +
                "                            (同 PC の他 install Manager を巻き添えにしない)。未指定時は\n" +
                "                            system-wide GetProcessesByName fallback。\n" +
                "\n" +
                "Exit codes (SPEC §3.7.4 / Program.cs docstring / CHANGELOG ## Companions ### [Updater v0.1.0] (#160 で rename、旧 ## Updater) / PR #152 body と **5 者同期**、round 4 H-1+M-1 で 3 分割 + 1 追記、round 6 で 6 失敗時 rollback 仕様化):\n" +
                "  0  成功\n" +
                "  1  予期しない実行時例外 (Logger に stack trace、bug report 対象。parse 段階の例外は stderr のみ)\n" +
                "  2  引数エラー / 必須引数不足 / --restart-exe が --manager-target 外 等 (parse 段階のため Logger 未初期化、stderr のみ。round 6 Medium-4)\n" +
                "  3  Manager プロセスが timeout 内に終了しなかった (--force-kill 未指定、--force-kill 付与か手動 close で再試行可)\n" +
                "  4  ファイル置換に失敗 (rollback 実施済、旧 Manager 復元。auto-recovery 経路も同 code)\n" +
                "  5  rollback にも失敗した致命的状態 (`.bak` から手動復元要)\n" +
                "  6  新 Manager.exe の起動に失敗、または置換後の版数が持ち込んだものと不一致 (#440) (Process.Start null/throw、spawn 直後 early-crash、restart-exe 不在 等。失敗時は .bak から旧 Manager を自動復元、round 6 Codex P1 + Medium-5)\n" +
                "  7  force-kill 試行が bounded retry (3 回) 上限超過 (permission denied 等、機械的再試行は無意味)\n" +
                "  8  process enumeration 連続失敗 (5 回、IPC/WMI 一時障害、短時間後の再試行で回復見込み)\n" +
                "  9  Manager プロセスの同一性を確認できないまま上限 (60 秒) に達した (#440。手動で Manager を閉じてから再試行。--force-kill は勧めない = 同一性未確認のプロセスは kill しない方針なので、強制終了で再試行しても同じところに戻る行き止まりになる)\n";
        }
    }
}
