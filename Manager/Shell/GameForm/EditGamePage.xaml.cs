using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using TonePrism.Manager.Models;
using TonePrism.Manager.Services;
using WinForms = System.Windows.Forms;

namespace TonePrism.Manager.Shell.GameForm
{
    /// <summary>
    /// (#324 PR1) ゲーム編集の WPF ページ。DataContext = <see cref="EditViewModel"/> (GameListPage が Navigate で注入)。
    /// 葉 UserControl を組み、保存は旧 EditGameForm.btnOK_Click のフローを **抽出済み service** で再現する:
    /// 検証 → GameVersionSetValidator → アクティブ版確認 → SessionConflict → GameIdRenameService →
    /// VersionFolderRenameService → UpdateVersionsAndGame → 失敗時 Rollback → GoBack + 成果通知。
    /// ProcessingDialog / 各 MessageBox は WinForms を <see cref="ShellOwner"/> 渡しで流用 (挙動保存)。
    /// 外部画像は保存時に <see cref="GameImageSaveImporter"/> 経由で <c>.toneprism/</c> へ取り込む (#386)。版即時削除は #393/#387。
    /// 旧との差異 (意図的): 表示中版の version が SemVer 不正な場合、旧 btnOK は clamp 表示値 (v0.0.0) を書き戻して
    /// 保存を「通して」いたが、本実装は VersionName(=生値) を SoT とするため GameVersionSetValidator が不正としてブロックする。
    /// 不正値 (例 "abc") を黙って v0.0.0 に潰す silent データ消失を避け、load 時の警告 + 実行可能なエラー文言で直させる方針。
    /// </summary>
    public partial class EditGamePage : Page, IEditUnsavedGuard
    {
        private EditViewModel Vm => DataContext as EditViewModel;
        private DatabaseManager Db => ShellWindow.SharedDb;
        private WinForms.IWin32Window Owner => ShellOwner.For(this);

        // (レビュー High-1) GameListPage → EditGamePage の DataContext ハンドオフ。WPF-UI NavigationView は遷移済みページを
        // 型単位で cache し、Navigate(type, dataContext) が cache 済みインスタンスへ dataContext を再適用するかは framework
        // 依存で不確実。再適用されないと【2 ゲーム目以降の編集で 1 つ前のゲームを表示・上書きする】致命的取り違えになる。
        // そこで Edit_Click が直前にここへ VM を入れ、OnLoaded (= ページ表示ごとに発火) で確実に DataContext へ適用し、
        // framework 挙動に依らず正しい VM を構造的に保証する。
        public static EditViewModel PendingViewModel;

        public EditGamePage()
        {
            InitializeComponent();
            Loaded += OnLoaded;
            Unloaded += OnUnloaded;
        }

        private void OnLoaded(object sender, RoutedEventArgs e)
        {
            // (High-1) cache 再利用で DataContext が古いままでも、直前に積まれた VM を確実に適用する (誤ったゲームの
            // 表示・上書き防止)。同一参照なら再代入は no-op。
            if (PendingViewModel != null) { DataContext = PendingViewModel; PendingViewModel = null; }

            // (#383) このページを未保存ガードとしてシェルに登録。サイドバー/戻る等あらゆる離脱を Navigating 割り込みが
            // 捕捉し、未保存があれば Fluent 確認ダイアログを出す (サイドバーは押せるまま = グレーアウトしない)。
            if (ShellWindow.Instance != null) ShellWindow.Instance.ActiveEditGuard = this;

            // 不正 version の集約警告 (旧 LoadVersions の MessageBox) を編集 1 回につき一度だけ。フラグは VM 側に
            // 持たせる (ページが type 単位で cache 再利用されても別ゲーム編集で再警告するため)。
            var vm = Vm;
            if (vm == null || vm.MalformedWarningShown || vm.MalformedVersionsOnLoad.Count == 0) return;
            vm.MalformedWarningShown = true;
            WinForms.MessageBox.Show(Owner,
                "DB に保存されている version 文字列のうち " + vm.MalformedVersionsOnLoad.Count + " 件が SemVer 形式では" +
                "ありません。該当バージョンを選択すると v0.0.0 または上限値に clamp されて表示されるので、UI で実表示値を" +
                "確認 → 意図した version 番号に修正してから保存してください。\n\n" + string.Join("\n", vm.MalformedVersionsOnLoad),
                "バージョン読み込み警告 (" + vm.MalformedVersionsOnLoad.Count + " 件)",
                WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
        }

        private void OnUnloaded(object sender, RoutedEventArgs e)
        {
            // (#383) 編集ページを離れたらガード登録を解除。
            if (ShellWindow.Instance != null && ReferenceEquals(ShellWindow.Instance.ActiveEditGuard, this))
                ShellWindow.Instance.ActiveEditGuard = null;
        }

        // (#383) 戻るボタンはナビゲーションするだけ。未保存確認はシェルの Navigating 割り込み (全離脱口共通) が出す。
        private void Back_Click(object sender, RoutedEventArgs e) => GoBack();

        // (#383) IEditUnsavedGuard: シェルの離脱割り込みが参照する。
        public bool HasUnsavedChanges() => Vm?.HasUnsavedChanges() ?? false;
        // (#383 レビュー指摘2) ガードからの保存。成功時の着地はガードが渡す (押した先 / 戻る由来なら pop)。
        public void RequestSaveFromGuard(Action onSavedSuccess) => TrySave(onSavedSuccess);

        private static void GoBack()
        {
            var nav = ShellWindow.Instance?.RootNavigation;
            if (nav == null || !nav.CanGoBack) return;
            ShellWindow.Instance.MarkBackRequested();   // (#383 指摘6) 戻る由来を通知 → ガードは pop で戻す
            nav.GoBack();
        }

        private void BrowseExe_Click(object sender, RoutedEventArgs e)
        {
            if (Vm == null) return;
            var dlg = new Microsoft.Win32.OpenFileDialog
            {
                Title = "実行ファイルを選択",
                Filter = "実行ファイル (*.exe)|*.exe|すべてのファイル (*.*)|*.*",
                CheckFileExists = true
            };
            if (System.IO.Directory.Exists(Vm.GameFolder)) dlg.InitialDirectory = Vm.GameFolder;
            if (dlg.ShowDialog() == true) Vm.ExecutablePath = dlg.FileName;
        }

        // 実行ファイルのテスト起動 (旧 EditGameForm.btnTestRun)。exe 不在/未指定の警告は TestRunGame が内部表示。
        // VM.ExecutablePath は絶対 path だが、相対のときの保険に GameFolder を baseFolder として渡す。
        private void TestRun_Click(object sender, RoutedEventArgs e)
        {
            if (Vm == null) return;
            GameFormHelper.TestRunGame(Vm.ExecutablePath, Vm.Arguments, Vm.GameFolder);
        }

        private void Save_Click(object sender, RoutedEventArgs e) => TrySave(GoBack);   // ボタン保存は成功で一覧へ

        // 保存を try/catch で包んで実行。成功時の着地は onSuccess に委ねる (ボタン=GoBack / ガード=押した先)。
        private void TrySave(Action onSuccess)
        {
            var vm = Vm;
            if (vm == null) return;
            try
            {
                Save(vm, onSuccess);
            }
            catch (System.Data.SQLite.SQLiteException ex)
            {
                WinForms.MessageBox.Show(Owner, "ゲームの更新に失敗しました。\n\n" + DatabaseManager.GetUserFriendlyErrorMessage(ex),
                    "データベースエラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
            }
            catch (OperationCanceledException)
            {
                // gameId rename の recovery 確認で user が Cancel。静かに中断 (ページ留め)。
            }
            catch (Exception ex)
            {
                WinForms.MessageBox.Show(Owner, "ゲームの更新に失敗しました。\n\n" + ex.Message,
                    "エラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Error);
            }
        }

        private void Save(EditViewModel vm, Action onSuccess)
        {
            // 1. 基本検証 (gameId/title)。
            vm.ValidateAll();
            if (vm.HasErrors)
            {
                WinForms.MessageBox.Show(Owner, "入力にエラーがあります。ゲームID・タイトルを確認してください。", "入力エラー",
                    WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }
            // exe/画像の拡張子・存在を検証 (取り込み前。外部 source も存在すれば通る)。実行ファイルは拡張子無制約
            // (.exe 限定にすると非.exe で起動する既存ゲームの編集保存が弾かれる回帰になるため null。画像は従来どおり拡張子チェック)。
            if (!GameFormHelper.ValidateFilePath(vm.ExecutablePath, vm.GameFolder, null, true, "実行ファイル", out string pathErr)
                || !GameFormHelper.ValidateFilePath(vm.ThumbnailPath, vm.GameFolder, GameFormHelper.ImageFileExtensions, false, "サムネイル画像", out pathErr)
                || !GameFormHelper.ValidateFilePath(vm.BackgroundPath, vm.GameFolder, GameFormHelper.ImageFileExtensions, false, "背景画像", out pathErr))
            {
                WinForms.MessageBox.Show(Owner, pathErr, "入力エラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }

            // 2. 実行ファイルは gameFolder 内必須 (exe の外部取り込みは #386 対象外 = 画像のみ取り込む)。これが無いと
            //    CommitToVersion→ToRel が外部 exe を null 化し、保存時に NOT NULL 違反で (しかも rename 実行後に) 落ちる。
            if (!IsInsideGameFolder(vm, vm.ExecutablePath))
            {
                WinForms.MessageBox.Show(Owner,
                    "実行ファイルはゲームフォルダ内のファイルを選択してください:\n  " + vm.GameFolder +
                    "\n\n外部のファイルを使う場合は、いったんゲームフォルダ内にコピーしてから選び直してください。",
                    "入力エラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }

            // 3. 表示中版を in-memory commit。画像の外部パスは ToRelOrKeepExternal で絶対のまま残り (#386 指摘1)、
            //    後段 (手順7) で全版まとめて .toneprism へ取り込む。
            if (vm.SelectedVersion != null) vm.CommitToVersion(vm.SelectedVersion);

            // 4. 版セット検証 (空/不正version/正規化重複/人数)。現版は手順3で commit 済なので scan 対象に含まれる。
            var v = new GameVersionSetValidator().Validate(vm.Versions);
            if (v.VersionStringIssueCount > 0)
            {
                WinForms.MessageBox.Show(Owner, BuildVersionStringError(v), "バージョン入力エラー (" + v.VersionStringIssueCount + " 件)",
                    WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }
            if (v.DuplicateVersions.Count > 0)
            {
                WinForms.MessageBox.Show(Owner,
                    "以下のバージョン名が複数のエントリで重複しています (SemVer 正規化後の比較、v 大文字/小文字・leading v 有無は同一視):\n\n  " +
                    string.Join("\n  ", v.DuplicateVersions) + "\n\nバージョン管理で該当の項目を選び、別の名前に変更してください。",
                    "バージョン重複エラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }
            if (v.PlayerCountViolations.Count > 0)
            {
                WinForms.MessageBox.Show(Owner,
                    "以下のバージョンで「最小プレイ人数 > 最大プレイ人数」になっています。\nバージョン管理で該当版を選び、人数を修正してから再度保存してください:\n\n" +
                    string.Join("\n", v.PlayerCountViolations), "プレイ人数の入力エラー (" + v.PlayerCountViolations.Count + " 件)",
                    WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }

            // 4b. (#386 指摘2) 全版の実行ファイルが内部 (非 null) か検証。非選択版に外部 exe が commit されていると ToRel で
            //     null 化され、選択版のみ見る手順2のガードを通過し、高コストな rename を実行した後に DB で NOT NULL 違反で
            //     落ちる。画像は手順7で全版取り込みするが exe は取り込み非対応なので、rename 前にここで弾く。
            var missingExe = vm.Versions.Where(x => x != null && string.IsNullOrEmpty(x.ExecutablePath)).ToList();
            if (missingExe.Count > 0)
            {
                WinForms.MessageBox.Show(Owner,
                    "以下のバージョンの実行ファイルが未設定、またはゲームフォルダ外を指しています:\n\n  " +
                    string.Join("\n  ", missingExe.Select(x => x.Version ?? "(未設定)")) +
                    "\n\nバージョン管理で該当版を選び、ゲームフォルダ内の実行ファイルを指定してから保存してください。",
                    "実行ファイルの入力エラー (" + missingExe.Count + " 件)", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }

            // 5. アクティブ版 (= ランチャー起動対象) の暗黙切替確認。
            var selected = vm.SelectedVersion;
            if (selected != null && vm.InitialSelectedVersionId.HasValue && selected.Id != vm.InitialSelectedVersionId.Value)
            {
                var dr = WinForms.MessageBox.Show(Owner,
                    "現在表示しているバージョン「" + (selected.Version ?? "(未設定)") + "」を、ランチャーで表示・起動するバージョンにしますか?\n\n" +
                    "  これまで: " + (vm.OriginalGame.Version ?? "(未設定)") + "\n  保存後: " + (selected.Version ?? "(未設定)") + "\n\n" +
                    "「いいえ」で編集に戻ります (元の版を選び直してから保存)。",
                    "ランチャーに表示するバージョンの確認", WinForms.MessageBoxButtons.YesNo, WinForms.MessageBoxIcon.Question);
                if (dr != WinForms.DialogResult.Yes) return;
            }

            // 6. 他 PC session 競合の再 check (DB write 直前)。
            if (SessionConflictHelper.CheckBeforeWrite("ゲーム編集") == WinForms.DialogResult.Cancel) return;

            // 7. (#386) 全版の外部画像を .toneprism/ へ取り込み、版オブジェクトのパスを相対化する。CommitToVersion が
            //    外部画像を絶対のまま残すので、選択版だけでなく全版を走査する (指摘1: 版切替で非選択版の外部画像が
            //    silent loss するのを防ぐ)。取り込み先フォルダは rename 前のディスク leaf (OriginalVersionByDbId)。後段の
            //    gameId/版 rename が .toneprism ごとフォルダ移動 + 相対パス prefix 書換を行うため整合する。
            //    abort 時も取り込みファイルは削除しない: 削除すると非選択版の相対パスが dangling になり retry で silent loss
            //    する (GameImageSaveImporter の doc 参照)。残せば retry でその実体を解決して保存成功・放棄時の orphan は無害。
            //    コピーは同期 (画像は通常小サイズで軽量。多版×大画像で体感が出るなら ProcessingDialog 化を検討)。
            string diskGameId = vm.OriginalGame.GameId;
            bool imagesImported = false;
            try
            {
                foreach (var ver in vm.Versions)
                {
                    if (ver == null) continue;
                    if (!vm.OriginalVersionByDbId.TryGetValue(ver.Id, out var dv) || string.IsNullOrWhiteSpace(dv))
                    {
                        // (#386 指摘5) snapshot 欠落版は取り込み先 leaf が決まらない (新 leaf に作ると後続 rename と衝突)
                        // ため skip + Warn (VersionFolderRenameService の defensive と挙動を揃える。現状 LoadVersions のみが
                        // snapshot を populate するため到達しない。round3 指摘4: 将来 add-version UI を入れると、外部画像を持つ
                        // snapshot 欠落版が skip され絶対パスのまま保存される footgun になるため、その際は exe ガード同様
                        // 「外部画像が残る版はブロック」方向へ揃えること)。
                        Logger.Warn("[EditGamePage] (#386) snapshot 欠落 version id=" + ver.Id + " ('" + (ver.Version ?? "(null)") + "') の画像取り込みを skip");
                        continue;
                    }
                    ver.ThumbnailPath = GameImageSaveImporter.ImportIfExternalToRelative(ver.ThumbnailPath, diskGameId, dv, GameImageAssetHelper.ImageRole.Thumbnail, out bool t);
                    ver.BackgroundPath = GameImageSaveImporter.ImportIfExternalToRelative(ver.BackgroundPath, diskGameId, dv, GameImageAssetHelper.ImageRole.Background, out bool b);
                    imagesImported |= t || b;
                }
            }
            catch (Exception imgEx)
            {
                WinForms.MessageBox.Show(Owner, "画像の取り込みに失敗しました。\n\n" + imgEx.Message,
                    "画像取り込みエラー", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }

            // (#386 round3 指摘1) 画像取り込みは games/ への新バイト書込なので、rename が無くてもアセットバックアップ対象にする。
            // これが無いと「画像だけ差し替えて保存」が DB-only バックアップになり、その世代から復元すると DB が指す画像が欠落する。
            bool assetsChanged = imagesImported;

            // 8. gameId rename (フォルダ Move + DB)。GameIdRenameService に委譲。
            string oldGameId = vm.OriginalGame.GameId;
            string newGameId = (vm.GameId ?? "").Trim();
            if (!string.Equals(newGameId, oldGameId, StringComparison.Ordinal))
            {
                string oldFolder = PathManager.GetGameFolder(oldGameId);
                string newFolder = PathManager.GetGameFolder(newGameId);
                var idSvc = new GameIdRenameService(Db);
                switch (idSvc.DecideCollision(oldFolder, newFolder))
                {
                    case GameIdRenameService.CollisionDecision.Collision:
                        throw new InvalidOperationException("フォルダ「" + newFolder + "」が既に存在します。");
                    case GameIdRenameService.CollisionDecision.NeedsRecoveryConfirm:
                        var rdr = WinForms.MessageBox.Show(Owner,
                            "指定された新しいゲーム ID のフォルダが既に存在しますが、旧 ID のフォルダは見つかりません:\n  " + newFolder + "\n\n" +
                            "前回 rename 中断の残骸か手動作成の可能性があります。\n  ・「OK」= 既存フォルダを引き継いで DB のみ更新\n" +
                            "  ・「キャンセル」= 中身を退避してから再試行\n\n既存フォルダを使って DB を新 gameId に更新しますか?",
                            "フォルダ同期確認", WinForms.MessageBoxButtons.OKCancel, WinForms.MessageBoxIcon.Warning);
                        if (rdr != WinForms.DialogResult.OK) throw new OperationCanceledException("ユーザーがフォルダ同期をキャンセルしました。");
                        break;
                }
                Exception caught = null;
                bool moved = false;
                using (var dialog = new ProcessingDialog((progress, token) =>
                {
                    try { moved = idSvc.Execute(oldGameId, newGameId, oldFolder, newFolder, progress); }
                    catch (Exception ex) { caught = ex; throw; }
                })
                { Text = "ゲームIDを変更中", MarqueeMode = true, AllowCancel = false })
                {
                    if (dialog.ShowDialog(Owner) != WinForms.DialogResult.OK)
                    {
                        if (caught != null) throw caught;
                        return;
                    }
                }
                if (moved) assetsChanged = true;
                vm.ApplyGameIdRename(newGameId, newFolder);   // GameFolder + 全版 GameId を新 ID に追従
            }

            // 9. 版フォルダ rename (VersionFolderRenameService)。完了済は DB 失敗時の rollback に使う。
            var verSvc = new VersionFolderRenameService();
            var plan = verSvc.BuildPlan(vm.GameFolder, vm.Versions, vm.OriginalVersionByDbId);
            if (plan.HasCollision)
            {
                // (#386) 取り込み済画像は削除しない (削除すると非選択版の相対パスが dangling になり retry で silent loss)。
                WinForms.MessageBox.Show(Owner, plan.CollisionMessage, "フォルダ衝突", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Warning);
                return;
            }
            var completed = new List<VersionFolderRenameService.RenamePlan>();
            if (plan.OrderedPlan.Count > 0)
            {
                VersionFolderRenameService.ExecuteResult exec = null;
                using (var dialog = new ProcessingDialog((progress, token) =>
                {
                    exec = verSvc.ExecutePlan(plan.OrderedPlan, vm.OriginalVersionByDbId, progress);
                })
                { Text = "バージョンフォルダをリネーム中", MarqueeMode = true, AllowCancel = false })
                {
                    dialog.ShowDialog(Owner);
                }
                if (exec != null && exec.Failed)
                {
                    // (#386) 取り込み済画像は削除しない (同上: retry での silent loss を避ける)。
                    WinForms.MessageBox.Show(Owner, exec.ErrorMessage, "フォルダリネーム失敗", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Error);
                    return;
                }
                if (exec != null) completed = exec.CompletedRenames;
            }
            // (レビュー #3) 版フォルダ rename も実ファイル移動なので #295 アセットバックアップ対象にする
            // (旧 EditGameForm は版 rename で AssetsChanged を立てない潜在ギャップがあったが、本 PR で是正)。
            if (completed.Count > 0) assetsChanged = true;

            // 10. games 行 = 選択版の mirror + game レベル項目。1 transaction で版群と一緒に保存。
            var game = BuildGameFromSelected(vm, newGameId, selected);
            try
            {
                Db.UpdateVersionsAndGame(vm.Versions, game);
            }
            catch (Exception dbEx)
            {
                int rolledBack, rollbackFailures;
                verSvc.Rollback(completed, vm.OriginalVersionByDbId, out rolledBack, out rollbackFailures);
                // (#386) 取り込み済画像は削除しない (削除すると非選択版の相対パスが dangling になり、ロック解除後の
                // retry で欠落ファイルを指す相対パスが保存成功してしまう = silent loss。残せば retry が実体を解決する)。
                // (#382 (iii)) gameId rename は step6 で独立コミット済のため、ここで巻き戻るのは版フォルダ rename だけ。
                // gameId を変えていた場合に「DB は更新前」と表示すると嘘になるので状態を正確に伝える
                // (完全な rollback / transaction 統合は #382 で継続)。
                bool gameIdChanged = !string.Equals(newGameId, oldGameId, StringComparison.Ordinal);
                string stateNote = gameIdChanged
                    ? "ゲームID の変更 (" + oldGameId + " → " + newGameId + ") は確定済みのまま残ります。版・ゲーム情報の更新のみ失敗しました。"
                    : "DB は更新前の状態です。";
                WinForms.MessageBox.Show(Owner,
                    "バージョン情報 + ゲーム本体情報の DB 更新に失敗しました:\n  " + dbEx.Message + "\n\n  完了済の版フォルダ rename " + rolledBack +
                    " 件を元に戻しました" + (rollbackFailures > 0 ? " (rollback 失敗 " + rollbackFailures + " 件、ログ参照)" : "") +
                    "。\n  " + stateNote, "DB 更新失敗", WinForms.MessageBoxButtons.OK, WinForms.MessageBoxIcon.Error);
                return;
            }

            // 11. #295 アセットバックアップを【この場で確定実行】→ 一覧へ戻り→ 成功トーストを出す (レビュー High)。
            //    旧実装はこれを GoBack 後の GameListPage.Loaded 発火に委ねていたが、(a) cache ページで Loaded が
            //    発火しないと通知もバックアップも silent skip、(b) 後で文脈外に遅延発火、(c) 次の編集が pending を
            //    上書きしてバックアップ消失、という framework 依存リスクがあった。保存成功直後に同期実行すれば、
            //    実ファイル移動 (gameId/版フォルダ rename) のバックアップ保護が確実に走る。バックアップは Owner が要る
            //    ので GoBack 前 (ページ有効中) に。成功通知は WinForms ダイアログをやめ、シェルレベルの非モーダル
            //    トーストにして GoBack 後の一覧の上に出す (#324 Snackbar 化)。
            Db.SessionBackupCoordinator.RunAfterOperation(Owner, assetsChanged, "ゲーム編集");
            vm.MarkSaved();   // (#383) 保存成功 → 未保存なし基準に更新 (再ナビゲーションの割り込みが再確認しないように)
            // (#383 指摘6) 着地先は呼び出し側が決める (ボタン=一覧 / ガード=押した先)。ただし保存は既に成功済なので、
            // 遷移 (onSuccess) の失敗を TrySave の catch に飛ばすと「更新に失敗しました」と嘘表示になる。ここで握って
            // ログのみにし、保存成功トーストは出す (遷移できなくてもデータは保存済 = 利用者に正しく伝える)。
            try { onSuccess?.Invoke(); }
            catch (Exception navEx) { Logger.Error("保存は成功しましたが、画面遷移に失敗しました。", navEx); }
            ShellWindow.Instance?.ShowSuccessToast("ゲーム「" + game.Title + "」を更新しました");
        }

        // 空 (未設定) は OK。非空なら gameFolder 内必須 (ToRel と同じ判定で、保存時の silent null 化を保存前に弾く)。
        private static bool IsInsideGameFolder(EditViewModel vm, string path)
            => string.IsNullOrWhiteSpace(path) || PathConversionHelper.IsPathInside(vm.GameFolder, path.Trim());

        // 選択版 (mirror) + game レベル項目 (ReleaseYear/IsVisible/GameId/DisplayOrder/Controls/KeyMapping) から games 行を組む。
        private static GameInfo BuildGameFromSelected(EditViewModel vm, string newGameId, GameVersion sel)
        {
            return new GameInfo
            {
                GameId = newGameId,
                Version = sel?.Version ?? vm.OriginalGame.Version,
                Title = sel?.Title ?? (vm.Title ?? "").Trim(),
                Description = sel?.Description,
                Genre = sel?.Genre ?? new List<string>(vm.SelectedGenres),
                MinPlayers = sel?.MinPlayers ?? vm.MinPlayers ?? 1,   // プレイ人数は常に数値 (旧 WinForms 同様)
                MaxPlayers = sel?.MaxPlayers ?? vm.MaxPlayers ?? 1,
                Difficulty = sel?.Difficulty ?? vm.Difficulty,
                PlayTime = sel?.PlayTime ?? vm.PlayTime,
                ControllerSupport = sel?.ControllerSupport ?? vm.ControllerSupport,
                SupportedConnection = sel?.SupportedConnection ?? vm.SupportedConnection,
                ExecutablePath = sel?.ExecutablePath,
                ThumbnailPath = sel?.ThumbnailPath,
                BackgroundPath = sel?.BackgroundPath,
                Arguments = sel?.Arguments,
                Developers = sel?.Developers ?? vm.Developers.Where(d => !d.IsBlank).Select(d => d.ToModel()).ToList(),
                ReleaseYear = vm.ReleaseYearUnknown ? (int?)null : vm.ReleaseYear,
                IsVisible = vm.IsVisible,
                DisplayOrder = vm.OriginalGame.DisplayOrder,
                Controls = vm.OriginalGame.Controls,
                KeyMapping = vm.OriginalGame.KeyMapping
            };
        }

        private static string BuildVersionStringError(GameVersionSetValidator.Result r)
        {
            var sb = new StringBuilder();
            sb.AppendLine("以下のバージョンに修正が必要です。バージョン管理で該当版を選び、入力欄を直してから再度保存してください。");
            sb.AppendLine();
            if (r.EmptyIds.Count > 0)
            {
                sb.AppendLine("● バージョン文字列が空 / 未設定 (" + r.EmptyIds.Count + " 件):");
                sb.AppendLine("  " + string.Join("\n  ", r.EmptyIds));
                sb.AppendLine();
            }
            if (r.MalformedSuffixEntries.Count > 0)
            {
                sb.AppendLine("● suffix 部分が SemVer 形式ではない (" + r.MalformedSuffixEntries.Count + " 件):");
                sb.AppendLine(string.Join("\n", r.MalformedSuffixEntries));
                sb.AppendLine();
            }
            if (r.MalformedNumericEntries.Count > 0)
            {
                sb.AppendLine("● 数値部 (Major/Minor/Patch) または書式が parse 不能 (" + r.MalformedNumericEntries.Count + " 件):");
                sb.AppendLine(string.Join("\n", r.MalformedNumericEntries));
            }
            return sb.ToString().TrimEnd();
        }
    }
}
