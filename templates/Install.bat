@echo off
REM ============================================================================
REM Install.bat - TonePrism initial installer (#108 Phase 2)
REM
REM File format: cp932 (Shift-JIS) + CRLF at *staging time*.
REM   - templates/Install.bat (this source) is UTF-8 (no BOM) + CRLF for repo
REM     readability / cross-platform editing.
REM   - Release.ps1 Copy-Templates re-encodes to cp932 + CRLF for the zip.
REM   - Rationale: cmd.exe parses bat files in the SYSTEM codepage (cp932 on JP
REM     Windows). Bat-internal `chcp 65001` only switches the *console output*
REM     codepage, NOT the file-reading codepage. Long Japanese lines under
REM     UTF-8 source caused cmd parser to mistokenize byte sequences and emit
REM     cascading "is not recognized" errors. Staging as cp932 lets cmd parse
REM     natively. Cost: non-JP Windows (cp437/1252) would mojibake; out of scope
REM     for the school deployment target.
REM
REM Structural rules (still apply since they protect against cmd parser quirks):
REM   (1) Japanese echo MUST live at top-level only (not inside `if ... (...)` blocks).
REM   (2) echo / set /p prompt arguments MUST NOT contain literal `(` or `)`.
REM       Use `[` `]` instead. (set /p prompts go through the same parser as echo;
REM       even top-level placement isn't formally guaranteed by docs against
REM       future cmd version changes — keep the rule uniform for safety.)
REM   (3) PowerShell invocations MUST NOT inline long commands with Japanese in
REM       `set "PS_CMD=...日本語..."` form. Use external .ps1 + `-File`.
REM
REM Usage:
REM   Install.bat   -- double-click to run (target user: 部員 / 来場スタッフ)
REM
REM Flow:
REM   1. FolderBrowserDialog (via show_folder_dialog.ps1) selects parent folder.
REM   2. Nest check: abort if parent path ends in TonePrism.
REM   3. Existing check: <parent>\TonePrism\ exists?
REM        Yes -> Y/N warning. Y = overwrite preserving user data + manager-close wait.
REM        No  -> mkdir + copy files/.
REM   4. Manager-start Y/N prompt.
REM
REM Exit codes (for Phase 3 Updater integration):
REM   0  success or user cancel (dialog cancel / overwrite N / manager-start N).
REM   1  failure (files/ missing / nested path / mkdir fail / robocopy fail / PS launch fail).
REM ============================================================================

REM setlocal disabledelayedexpansion: delayed expansion is intentionally off so
REM FolderBrowserDialog paths containing `!` (e.g. D:\Backup!\) are preserved
REM as-is. No `!VAR!` references exist in this file.
setlocal disabledelayedexpansion

REM Quoted set form (`set "VAR=value"`) is required for *path-derived* values that
REM may contain cmd metachars (`&`, `^` 等) e.g. if zip is extracted under `D:\R&D\`.
REM Unquoted assignment would split the line into multiple commands and abort.
REM Quoted form stores the value literally.
REM
REM Note: numeric sentinels (MANAGER_FOUND / LAUNCHER_FOUND / MANAGER_STARTED /
REM EXIT_CODE 等) are intentionally NOT quoted below — they only hold ERRORLEVEL
REM (0/1) or `1` literals, so quoting adds noise without value. The quote rule
REM applies to path / user-input values, not to numeric flags. (シニアレビュー L1)
REM (#175 Phase 4.1) zip 構造整理: zip 直下 = Install.bat / INSTALL_README.txt のみ、
REM それ以外 (Launcher.bat / Manager.bat / show_folder_dialog.ps1 / bundle_manifest.json /
REM files/) は `bundle/` 配下に集約。本 Install.bat は `<SCRIPT_DIR>\bundle\...` 経由で
REM bundle 内の各 file を参照する。ユーザー視点で zip 展開時に「Install.bat を押すだけ」が
REM 一目瞭然になる UX 改善 + Manager UI Phase 4 update flow の forward compat 機構と一体。
set "SCRIPT_DIR=%~dp0"
set "BUNDLE_DIR=%SCRIPT_DIR%bundle"
set "FILES_DIR=%BUNDLE_DIR%\files"
REM Exit code sentinel: failure paths goto :fail to set 1.
REM (numeric per L1 rule — unquoted, matches :fail's `set EXIT_CODE=1`)
set EXIT_CODE=0

REM ----- robocopy 共通フラグ (round 7 L2): overwrite / new_install 両 path で共通する -----
REM  /E       recursive incl. empty dirs
REM  /NFL /NDL /NJH /NJS /NC /NS /NP  minimal output
REM  /R:1 /W:1                        retry 1 回 / 待機 1 秒
REM `/XF` `/XD` の差は :do_robocopy_overwrite / :do_robocopy で個別管理 (overwrite のみ user data
REM 保護の defense-in-depth として `/XF /XD` を追加)。共通フラグを変数化することで「片方修正時に
REM もう片方が乖離する」事故を防ぐ。
set "ROBOCOPY_COMMON=/E /NFL /NDL /NJH /NJS /NC /NS /NP /R:1 /W:1"

REM ---- bundle/files/ existence check (top-level, no Japanese echo inside block) ----
REM (#175 Phase 4.1 round 2 Low-1) 旧文言「files/ ディレクトリ」は %FILES_DIR% が `bundle\files`
REM に変わった後も取り残されていた表現 (round 1 で path 変更後 sweep 漏れ)。新文言で「zip 直下に
REM bundle/ フォルダがある状態で実行してください」hint を追加、新構造ユーザーが「bundle/ が
REM ないのか bundle/files/ だけ無いのか」を判別しやすくする。
if exist "%FILES_DIR%" goto :files_ok
echo [FAIL] bundle/files/ ディレクトリが見つかりません: "%FILES_DIR%"
echo        zip 直下に bundle/ フォルダがある状態で Install.bat を実行してください。
echo        (Phase 4.1 #175 以降の zip 構造: zip 直下 = Install.bat + INSTALL_README.txt、
echo         それ以外は bundle/ 配下に集約)
goto :fail
:files_ok

echo ============================================================================
echo  TonePrism インストーラ
echo ============================================================================
echo.
echo インストール先の「親フォルダ」を選択してください。
echo  [選んだフォルダの下に TonePrism\ が作成されます]
echo.
echo 例: D:\Games を選ぶ → D:\Games\TonePrism\ にインストール
echo.

REM ---- Launch FolderBrowserDialog via show_folder_dialog.ps1 ----
REM PS exit code dispatch:
REM   0  = OK (selected path written to stdout)
REM   2  = user cancel (explicit [Environment]::Exit(2), distinct from PS error exit 1)
REM   other = PS launch failure (policy block / PS missing / .ps1 missing / etc.)
REM
REM Why a separate .ps1 (vs inline -Command "..."):
REM   cmd's bat parser cannot reliably tokenize a long `set "PS_CMD=...日本語..."`
REM   string. The Japanese byte sequence splits adjacent ASCII tokens like
REM   System.Windows.Forms, and PS receives malformed input.
REM 重要: INSTALL_PARENT は caller env から inherit する可能性があるため、dialog
REM 起動 *前* に明示的にクリア。`set /p` は input が空 (file が空) なら変数を
REM 更新しないため、初期化しないと前回値 / 環境値が leak して別パスへ install
REM するリスクあり (bot review P2 #4)。
set "INSTALL_PARENT="
REM tmp filename uses %RANDOM%%RANDOM% (30 bit, 1/1G collision) instead of bare
REM %RANDOM% (15 bit, 1/32K). Double-clicked installer is not designed for parallel
REM runs, but defends against the "user double-clicked twice, prior instance still
REM waiting on dialog" case where same tmp filename would let set /p pick up stale
REM path (シニアレビュー round 3 L4).
set "TEMP_DIALOG_OUT=%TEMP%\gctone_install_dialog_%RANDOM%%RANDOM%.tmp"
set "TEMP_DIALOG_ERR=%TEMP%\gctone_install_dialog_%RANDOM%%RANDOM%.err.tmp"
REM stdout / stderr を分離キャプチャ (シニアレビュー round 3 M2)。
REM 旧実装は stdout のみリダイレクト、stderr は親 cmd console に直流していた。
REM インタラクティブ実行では人間が画面で見られるが、Phase 3 Updater が
REM `cmd /c install.bat > log.txt 2>&1` で呼ぶ運用に入ったとき、stderr に書かれた
REM 実際の失敗理由 (show_folder_dialog.ps1 catch メッセージ等) は log に残る一方、
REM bat 内の `:dialog_fail` 表示と分離されて読みづらい。本実装では分離キャプチャで
REM `:dialog_fail` の表示に "PS stderr の内容" として明示的に含める。
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%BUNDLE_DIR%\show_folder_dialog.ps1" > "%TEMP_DIALOG_OUT%" 2> "%TEMP_DIALOG_ERR%"
set "DIALOG_EXIT=%ERRORLEVEL%"

if "%DIALOG_EXIT%"=="0" goto :dialog_ok
if "%DIALOG_EXIT%"=="2" goto :dialog_cancel
goto :dialog_fail

:dialog_ok
REM NOTE on trailing whitespace (シニアレビュー round 3 L3):
REM   show_folder_dialog.ps1 の [Console]::Out.Write は trailing newline を付けないが、
REM   FolderBrowserDialog の SelectedPath プロパティ自体が末尾空白を含む path を返す
REM   ケース (theoretical) に対しては防御薄。実害は OS / .NET の SelectedPath
REM   normalize 仕様に依存するが、現状 .NET 4.x の SelectedPath は trailing space を
REM   付けない実装で確認済。問題化したら set /p 後に whitespace trim を入れること。
set /p INSTALL_PARENT=<"%TEMP_DIALOG_OUT%"
del "%TEMP_DIALOG_OUT%" 2>nul
del "%TEMP_DIALOG_ERR%" 2>nul
if defined INSTALL_PARENT goto :dialog_done
echo.
echo [FAIL] PowerShell が exit 0 を返しましたが選択パスが取得できませんでした [想定外]。
echo        本シナリオが再現する場合は GitHub issue で報告してください。
goto :fail

:dialog_cancel
del "%TEMP_DIALOG_OUT%" 2>nul
del "%TEMP_DIALOG_ERR%" 2>nul
echo.
echo [INFO] キャンセルされました。インストールを中止します。
goto :end

:dialog_fail
echo.
echo [FAIL] PowerShell の起動 / 実行に失敗しました [exit %DIALOG_EXIT%]。
echo        PowerShell が利用可能か、Execution Policy を確認してください:
echo          powershell.exe -NoProfile -Command "Get-ExecutionPolicy -List"
if not exist "%TEMP_DIALOG_ERR%" goto :dialog_fail_stdout
REM stderr (catch 経路の [Console]::Error.WriteLine 出力 / PS host 起動エラー等)
echo.
echo PS stderr の内容:
type "%TEMP_DIALOG_ERR%"
:dialog_fail_stdout
if not exist "%TEMP_DIALOG_OUT%" goto :dialog_fail_cleanup
echo.
echo PS stdout の内容:
type "%TEMP_DIALOG_OUT%"
:dialog_fail_cleanup
del "%TEMP_DIALOG_OUT%" 2>nul
del "%TEMP_DIALOG_ERR%" 2>nul
goto :fail

:dialog_done

REM ---- Nest check ----
REM If the selected parent path ends in TonePrism (with or without trailing \),
REM we'd create <parent>\TonePrism\TonePrism\ which is nested. Warn + abort.
REM
REM Edge cases for the leaf extraction:
REM   - Drive root `D:\`        -> strip trailing \ leaves `D:` ->
REM                                `%%~nxF` returns empty string -> leaf = "" ->
REM                                nest check passes (empty != "TonePrism") ->
REM                                INSTALL_TARGET = `D:\TonePrism` -> mkdir
REM                                may fail with permission (drive root often
REM                                requires admin), caught by :new_install
REM                                mkdir-failed branch. Acceptable degradation.
REM   - UNC root `\\server\share`-> leaf = "share" -> nest passes (unless share
REM                                is literally named TonePrism) ->
REM                                INSTALL_TARGET = `\\server\share\TonePrism`.
REM                                Untested in E2E, see PR Known untested list.
set "INSTALL_PARENT_NO_TRAIL=%INSTALL_PARENT%"
if "%INSTALL_PARENT_NO_TRAIL:~-1%"=="\" set "INSTALL_PARENT_NO_TRAIL=%INSTALL_PARENT_NO_TRAIL:~0,-1%"
for %%F in ("%INSTALL_PARENT_NO_TRAIL%") do set "INSTALL_PARENT_LEAF=%%~nxF"

if /i not "%INSTALL_PARENT_LEAF%"=="TonePrism" goto :not_nested
echo.
echo [FAIL] 選択されたフォルダ自体が TonePrism です:
echo        "%INSTALL_PARENT%"
echo.
echo        「親フォルダ」を選んでください [その下に TonePrism\ が作成されます]。
echo        例: D:\Games\TonePrism\ にインストールしたい場合は D:\Games を選択。
goto :fail
:not_nested

set "INSTALL_TARGET=%INSTALL_PARENT_NO_TRAIL%\TonePrism"
echo.
echo インストール先: "%INSTALL_TARGET%"
echo.

REM ---- Existing install check: dispatch to top-level labels ----
if exist "%INSTALL_TARGET%\" goto :existing_install
goto :new_install

:existing_install
echo ============================================================================
echo  [警告] 既存インストールを検出しました
echo ============================================================================
echo.
echo  通常のアップデートは Manager の「アップデート」タブから行うのを推奨します。
echo.
echo  Manager が壊れて起動できない / クリーンインストールしたい場合のみ Y を押してください。
echo  Y を押した場合でも以下のゲームデータは維持されます:
echo    - toneprism.db [ゲーム情報 DB]
echo    - games\        [ゲーム実体]
echo    - backups\      [バックアップ]
echo    - responses\    [アンケート回答]
echo    - logs\         [ログ]
echo.
REM set /p preserves the previous value when user just hits Enter. Initialize to
REM empty so we always evaluate the latest input (defends against future change
REM that might set OVERWRITE_CONFIRM upstream).
set "OVERWRITE_CONFIRM="
set /p OVERWRITE_CONFIRM=上書きしますか？ [Y/N]:
REM Accept y / Y / yes / Yes / YES (Release.ps1 の upload prompt と寛容度を揃える)
if /i "%OVERWRITE_CONFIRM%"=="Y"   goto :checkprocess
if /i "%OVERWRITE_CONFIRM%"=="YES" goto :checkprocess
echo.
echo [INFO] インストールを中止しました。
goto :end

REM ---- Detect running Manager / Launcher; wait for user to close manually ----
REM findstr exit 0 = process found (= running), exit 1 = not found.
REM We do NOT auto-kill: user might have unsaved work. Phase 3 Updater will handle
REM controlled termination if needed.
REM
REM NOTE on wait loop termination (シニアレビュー L4):
REM   :wait_close is an UNBOUNDED loop with no timeout — if the user cannot close
REM   Manager / Launcher (hung process, locked by another session, permission issue),
REM   the only exit path is Ctrl+C. Ctrl+C aborts the bat without running :end, so
REM   %EXIT_CODE% is not set and the cmd exit code is undefined from the caller's
REM   perspective. This is INTENTIONAL for the current Phase 2 scope:
REM     - Phase 2 is "human double-clicks Install.bat", and a stuck process is
REM       almost always operator error that's better surfaced as "the installer
REM       seems stuck, what's going on?" than silently aborted.
REM     - Bounded loop with auto-fail would mask the real cause (e.g. operator
REM       forgot to close a tab) behind a generic "installer failed" message.
REM     - Phase 3 Updater is the proper place for forced termination (it owns the
REM       Manager process lifecycle and can decide to kill safely).
REM   If the loop becomes a problem in practice (e.g. unattended re-install flows
REM   where Ctrl+C isn't available), add a max-iterations counter here and goto :fail.
:checkprocess
tasklist /FI "IMAGENAME eq TonePrism_Manager.exe" 2>nul | findstr /I "TonePrism_Manager.exe" >nul
set MANAGER_FOUND=%ERRORLEVEL%
tasklist /FI "IMAGENAME eq TonePrism_Launcher.exe" 2>nul | findstr /I "TonePrism_Launcher.exe" >nul
set LAUNCHER_FOUND=%ERRORLEVEL%
if "%MANAGER_FOUND%"=="0" goto :wait_close
if "%LAUNCHER_FOUND%"=="0" goto :wait_close
goto :do_overwrite

:wait_close
echo.
if "%MANAGER_FOUND%"=="0" echo [警告] TonePrism_Manager.exe が稼働中です。
if "%LAUNCHER_FOUND%"=="0" echo [警告] TonePrism_Launcher.exe が稼働中です。
echo.
echo  Manager / Launcher を全て閉じてから何かキーを押してください...
pause >nul
goto :checkprocess

:do_overwrite
echo.
echo [INFO] 上書きインストールを開始します...
REM ----- migration 出力を tmp file にキャプチャ (round 7 M1) -----
REM 旧 `move ... >nul` は stdout のみ抑制で、stderr 経由の失敗詳細 (アクセス拒否 / 別プロセス
REM 使用中 等) が握り潰される。show_folder_dialog 呼び出し (line 91-105) と同じ
REM 「stdout/stderr 分離キャプチャ + 失敗時に type 表示」規約に揃える。
REM 2 段階 move (Manager / Launcher) で同 tmp を上書き使用し、失敗時はその時点の内容を表示。
REM
REM 配置 fix (#108 Phase 4 デバッグで発見): 以前は `:migrate_legacy_manager` ラベルより前の
REM ブロック内 (`goto :migrate_legacy_manager` の後ろ) に配置されていた dead code 状態だった。
REM `goto` がこの set 行を飛び越えるため TEMP_MV_OUT が空文字のまま `:migrate_done` の
REM `del "%TEMP_MV_OUT%" 2>nul` (line ~328) に到達 → cmd が `del ""` を current dir wildcard
REM (`del .\*` 相当) と解釈 → 「<SCRIPT_DIR>\*、よろしいですか (Y/N)?」prompt 発生 → Y で
REM zip 展開 dir の top-level files (Install.bat 含む) が削除 → bat 実行が途絶 → cmd window
REM 即閉じ。実害甚大の silent corruption path だった。`:do_overwrite` block 内 (goto より
REM 前) に移動することで goto に関係なく必ず初期化される形に修正。
set "TEMP_MV_OUT=%TEMP%\gctone_install_mv_%RANDOM%%RANDOM%.tmp"
goto :migrate_legacy_manager

REM ---- v0.2.0 → v0.3.0+ 旧構造 migration (シニアレビュー / ディレクトリ rename 整理対応) ----
REM v0.2.0 までは `<install>/GCTonePrism_Manager/` / `<install>/GCTonePrism_Launcher/` 配置。
REM v0.3.0 から `<install>/Manager/` / `<install>/Launcher/` + `<install>/Companions/Updater/` に変更。
REM 旧構造を検出したらリネームしてからロボコピーする (`move` で dir 名のみ変更 = 中身そのまま carry-over)。
REM 一度移行すれば以降はリネーム不要 (旧 dir 不在で skip)。
REM
REM Destination-exists guard:
REM   Windows の `move srcdir dstdir` は dst が既存ディレクトリの場合、エラーで失敗するのではなく
REM   src を dst の中にネスト移動 (`dst\src\` を作る) する挙動を取るバージョン / シェル組合せがある。
REM   errorlevel 0 で済んでしまうと `:migrate_failed` には飛ばず、`<install>/Manager/GCTonePrism_Manager/`
REM   という壊れたネスト構造ができたまま `:do_robocopy` が走り、ユーザーに見えにくいゴミが堆積する
REM   silent failure path だった。事前 `if exist <new>\` チェックで両 dir 並存を検出し、
REM   `:migrate_conflict` で user に手動判断を促す形に変更。並存ケースは theoretical だが、
REM   v0.3.0 install + 過去 zip バックアップ復元 / partial install の再試行で発生し得る。
REM
REM top-level goto pattern: 日本語 echo を if-block 内に置くと cmd parser cascade するため
REM (構造規約 1)、各 step を独立ラベルにしている。

:migrate_legacy_manager
if not exist "%INSTALL_TARGET%\GCTonePrism_Manager\" goto :migrate_legacy_launcher
if exist "%INSTALL_TARGET%\Manager\" goto :migrate_conflict_manager
echo [INFO] 旧構造 (v0.2.0) 検出: GCTonePrism_Manager\ → Manager\ に移行
move "%INSTALL_TARGET%\GCTonePrism_Manager" "%INSTALL_TARGET%\Manager" >"%TEMP_MV_OUT%" 2>&1
if errorlevel 1 goto :migrate_failed_manager
REM Sentinel: Manager 移行成功時にセット。:migrate_failed_launcher が「Manager 移行済」を
REM 案内する条件として使う (Manager 不在で skip された場合は未 set なので誤情報を避ける)。
set MANAGER_MIGRATED=1
:migrate_legacy_launcher
if not exist "%INSTALL_TARGET%\GCTonePrism_Launcher\" goto :migrate_done
if exist "%INSTALL_TARGET%\Launcher\" goto :migrate_conflict_launcher
echo [INFO] 旧構造 (v0.2.0) 検出: GCTonePrism_Launcher\ → Launcher\ に移行
move "%INSTALL_TARGET%\GCTonePrism_Launcher" "%INSTALL_TARGET%\Launcher" >"%TEMP_MV_OUT%" 2>&1
if errorlevel 1 goto :migrate_failed_launcher
REM Sentinel: Launcher 移行成功時にセット。:shortcut_failed が「Launcher 移行済」を
REM 案内する条件として使う (:migrate_failed_launcher / :shortcut_failed 共通の状態案内)。
set LAUNCHER_MIGRATED=1
:migrate_done
REM Migration tmp ファイルは success 時に cleanup (失敗 path 側は失敗ラベルで表示後 cleanup)
del "%TEMP_MV_OUT%" 2>nul
goto :overwrite_set_mode

:migrate_conflict_manager
echo.
echo [FAIL] 旧 dir と新 dir が両方存在しています:
echo          "%INSTALL_TARGET%\GCTonePrism_Manager"  [旧、v0.2.0 配置]
echo          "%INSTALL_TARGET%\Manager"              [新、v0.3.0+ 配置]
echo.
echo        Install.bat は自動でどちらを残すか判断できません。手動でどちらか一方を削除してから再実行:
echo          - 推奨: 新側を残す → 旧 "%INSTALL_TARGET%\GCTonePrism_Manager" を削除
echo            [通常はこちら。Install.bat 再実行で v0.3.0+ binary が上書きインストールされます]
echo          - 旧側を残す → 新 "%INSTALL_TARGET%\Manager" を削除 [v0.2.0 にダウングレードしたい場合のみ]
echo            [Install.bat 再実行で旧 dir が "Manager" にリネーム → 同じ v0.3.0+ binary で robocopy 上書き、
echo             結局 v0.3.0+ binary が入るので、本当に v0.2.0 のまま運用したい場合は zip も v0.2.0 を使うこと]
echo.
echo        どちらを選んでもユーザーデータ [toneprism.db / games / backups / responses / logs] は失われません。
echo        これらは "%INSTALL_TARGET%\" 直下にあり Manager dir の外なので、Manager dir の削除と無関係に維持されます。
goto :fail

:migrate_conflict_launcher
echo.
echo [FAIL] 旧 dir と新 dir が両方存在しています:
echo          "%INSTALL_TARGET%\GCTonePrism_Launcher"  [旧、v0.2.0 配置]
echo          "%INSTALL_TARGET%\Launcher"              [新、v0.3.0+ 配置]
echo.
REM Manager 側が先に移行成功している case を case-aware に明示 (:migrate_failed_launcher / :shortcut_failed
REM と同パターン、round 7 L4)。user が「両方ある = まだ移行されていない、全部一旦戻そう」と
REM 誤判断して "%INSTALL_TARGET%\Manager" を旧 GCTonePrism_Manager に手動 rename し直す path を防ぐ。
if defined MANAGER_MIGRATED echo        [注意] Manager 側はすでに移行済 ["%INSTALL_TARGET%\Manager" が新版]。
if defined MANAGER_MIGRATED echo               Launcher dir の整理に合わせて Manager 側も旧 dir に戻すと整合性が崩れます。
if defined MANAGER_MIGRATED echo.
echo        Install.bat は自動でどちらを残すか判断できません。手動でどちらか一方を削除してから再実行:
echo          - 推奨: 新側を残す → 旧 "%INSTALL_TARGET%\GCTonePrism_Launcher" を削除
echo            [通常はこちら。Install.bat 再実行で v0.3.0+ binary が上書きインストールされます]
echo          - 旧側を残す → 新 "%INSTALL_TARGET%\Launcher" を削除 [v0.2.0 にダウングレードしたい場合のみ]
echo            [Install.bat 再実行で旧 dir が "Launcher" にリネーム → 同じ v0.3.0+ binary で robocopy 上書き、
echo             結局 v0.3.0+ binary が入るので、本当に v0.2.0 のまま運用したい場合は zip も v0.2.0 を使うこと]
echo.
echo        どちらを選んでもユーザーデータ [toneprism.db / games / backups / responses / logs] は失われません。
echo        これらは "%INSTALL_TARGET%\" 直下にあり Launcher dir の外なので、Launcher dir の削除と無関係に維持されます。
goto :fail

REM :migrate_failed_manager と :migrate_failed_launcher は独立ラベル。
REM 旧 `:migrate_failed` 共通ラベルだと、Manager 移行成功 + Launcher 移行失敗のケースで
REM 「Manager の rename が必要」と案内してしまい (実際は完了済)、user が「移動元が無い」と
REM 混乱する path があった。失敗側だけの手動 rename 手順を案内する形に分離。
:migrate_failed_manager
echo.
echo [FAIL] 旧構造 (v0.2.0) → 新構造への Manager フォルダ移行に失敗しました。
echo        フォルダロック / 書き込み権限を確認してください。
echo        手動で以下のリネームを行えば回避可能:
echo          "%INSTALL_TARGET%\GCTonePrism_Manager"  → "%INSTALL_TARGET%\Manager"
echo        Launcher 側は本実行ではまだ移行を試みていないので、現状維持で OK。
echo        Install.bat 再実行で Launcher 側の移行が走ります。
if not exist "%TEMP_MV_OUT%" goto :migrate_failed_manager_cleanup
echo.
echo move コマンド出力:
type "%TEMP_MV_OUT%"
:migrate_failed_manager_cleanup
del "%TEMP_MV_OUT%" 2>nul
goto :fail

:migrate_failed_launcher
echo.
echo [FAIL] 旧構造 (v0.2.0) → 新構造への Launcher フォルダ移行に失敗しました。
REM Manager 移行は skip / 成功 / fail (= 別経路) の 3 通り。fail はここに来る前に止まるので、
REM 残るは skip (Manager 不在) と 成功。sentinel で「成功時のみ案内」する形に絞る。
if defined MANAGER_MIGRATED echo        Manager 側はすでに移行済 ["%INSTALL_TARGET%\Manager" が新版]、Launcher 側のみ rename 失敗。
echo        フォルダロック / 書き込み権限を確認してください。
echo        手動で以下のリネームを行えば回避可能:
echo          "%INSTALL_TARGET%\GCTonePrism_Launcher" → "%INSTALL_TARGET%\Launcher"
if not exist "%TEMP_MV_OUT%" goto :migrate_failed_launcher_cleanup
echo.
echo move コマンド出力:
type "%TEMP_MV_OUT%"
:migrate_failed_launcher_cleanup
del "%TEMP_MV_OUT%" 2>nul
goto :fail

:overwrite_set_mode
REM Overwrite 経路の終端: INSTALL_MODE sentinel を立てて :copy_shortcuts dispatcher に合流。
REM (両 path 共通の flow 順序方針議論は :copy_shortcuts 直下を参照、round 7 L3 で集約)
set "INSTALL_MODE=overwrite"
goto :copy_shortcuts

:new_install
echo [INFO] 新規インストールを開始します...
mkdir "%INSTALL_TARGET%" 2>nul
if exist "%INSTALL_TARGET%\" goto :new_mkdir_ok
echo.
echo [FAIL] インストール先フォルダを作成できませんでした: "%INSTALL_TARGET%"
echo        書き込み権限を確認してください。
goto :fail
:new_mkdir_ok
set "INSTALL_MODE=new"
goto :copy_shortcuts

:copy_shortcuts
REM ============================================================================
REM Dispatch for shortcut copy + robocopy ordering by INSTALL_MODE.
REM
REM Flow 順序方針 (round 3 L3 + Codex P2 で確定):
REM   overwrite path: migration → shortcut → robocopy → install_done
REM     - 理由: robocopy partial failure 時に shortcut bat が旧 path
REM       (`%~dp0GCTonePrism\GCTonePrism_Launcher\...` = v0.2.0 当時の path) のまま実体が新 dir
REM       `<install>/Launcher/` に移動済 → user が Launcher.bat ダブルクリックで
REM       「ファイルが見つかりません」窓を防ぐため、shortcut を先に新 path で書く。
REM       Install.bat 再実行で robocopy リトライ → 復旧可能。
REM   new_install path: mkdir → robocopy → shortcut → install_done
REM     - 理由: 新規 install で旧 shortcut bat が無いため「先に書く必要」がない。
REM       robocopy 失敗時に broken `<install>/TonePrism/` を指す shortcut bat が
REM       `<親>/` に残ると user が混乱する (Codex P2)。完全成功時にのみ shortcut。
REM ============================================================================
if "%INSTALL_MODE%"=="overwrite" goto :overwrite_shortcut_then_robocopy
goto :new_robocopy_then_shortcut

:overwrite_shortcut_then_robocopy
call :do_shortcut_copy
if errorlevel 1 goto :shortcut_failed
goto :do_robocopy_overwrite

:new_robocopy_then_shortcut
call :do_robocopy
if errorlevel 1 goto :copy_failed
call :do_shortcut_copy
if errorlevel 1 goto :shortcut_failed
goto :install_done

REM ----- Subroutine: shortcut bat copy (Launcher.bat / Manager.bat → <parent>/) -----
REM `call :do_shortcut_copy` で呼び出し、ERRORLEVEL で成否伝播。SPEC §3.7.1 のルート
REM ショートカット規約に従って <親>/ 直下に配置。
:do_shortcut_copy
REM (#175 Phase 4.1) shortcut bat は `bundle/` 配下に移動済、source path は %BUNDLE_DIR% 経由。
copy /Y "%BUNDLE_DIR%\Launcher.bat" "%INSTALL_PARENT_NO_TRAIL%\Launcher.bat" >nul
if errorlevel 1 exit /b 1
copy /Y "%BUNDLE_DIR%\Manager.bat" "%INSTALL_PARENT_NO_TRAIL%\Manager.bat" >nul
if errorlevel 1 exit /b 1
exit /b 0

REM ----- Subroutine: robocopy for new_install (no /XF /XD because no user data yet) -----
REM new_install path 用。overwrite 用は :do_robocopy_overwrite で独立 (`/XF /XD` defense-in-depth 必要)。
:do_robocopy
robocopy "%FILES_DIR%" "%INSTALL_TARGET%" %ROBOCOPY_COMMON%
REM robocopy exit code is a bitfield, < 8 = success (0 no change, 1 files copied, etc.).
if errorlevel 8 exit /b 1
exit /b 0

:do_robocopy_overwrite
REM ============================================================================
REM USER DATA PROTECTION — read this carefully before modifying robocopy flags.
REM ============================================================================
REM The PRIMARY protection mechanism is robocopy's DEFAULT non-mirror behavior:
REM   robocopy without /MIR does NOT delete destination files / directories
REM   that are absent from source. So user-generated data in INSTALL_TARGET
REM   (toneprism.db / games/ / backups/ / responses/ / logs/) is left untouched
REM   simply because those names don't exist in the source FILES_DIR.
REM
REM `/XF toneprism.db /XD games backups responses logs` is DEFENSE-IN-DEPTH only:
REM   it guards against a hypothetical future regression where someone
REM   accidentally adds a `toneprism.db` placeholder or a `games/` template into
REM   `files/` (which would then overwrite real user data on upgrade install).
REM   If today's FILES_DIR has no such names, /XF and /XD are effectively no-ops
REM   — verified by Assert-ExpectedFiles in Release.ps1.
REM
REM ⚠ DO NOT add /MIR. /MIR enables "delete dest files not in source" which
REM   would IMMEDIATELY destroy all user data (toneprism.db, games/, etc.). Neither
REM   /XF nor /XD prevents /MIR's purge. If you ever need a mirror-style sync,
REM   the protection list must be reimplemented as `/XO` + manual pre-copy
REM   snapshot of user data, AND /XF /XD must be kept in strict sync with the
REM   SPEC §3.7.3 user-data list. Today: just don't add /MIR.
REM
REM Other flags: /E recursive incl. empty dirs, /NFL /NDL /NJH /NJS /NC /NS /NP
REM minimal output, /R:1 /W:1 retry conservative.
REM
REM Note on /XF /XD name-matching: they match by *name* across the entire tree,
REM so future components containing a `games/` or `backups/` subfolder would be
REM silently excluded. Safe today (no such names in files/) but worth flagging
REM if a future component adds one.
REM ============================================================================
robocopy "%FILES_DIR%" "%INSTALL_TARGET%" %ROBOCOPY_COMMON% /XF toneprism.db /XD games backups responses logs
REM robocopy exit code is a bitfield, < 8 = success (0 no change, 1 files copied, etc.).
if errorlevel 8 goto :copy_failed
goto :install_done

:copy_failed
echo.
echo [FAIL] ファイルコピーに失敗しました [robocopy exit %ERRORLEVEL%]。
REM Install.bat 再実行で復旧可能だが、shortcut bat の状態は INSTALL_MODE で異なる:
REM - overwrite: shortcut copy 先行成功 → robocopy 失敗 (shortcut は新 path、Codex P2 関連)
REM - new:       robocopy 失敗 → shortcut copy 未到達 (shortcut bat 不在、broken shortcut の regression なし)
if "%INSTALL_MODE%"=="overwrite" echo        Install.bat 再実行で復旧可能です [shortcut bat はすでに新版で配置済み]。
if "%INSTALL_MODE%"=="new"       echo        Install.bat 再実行で復旧可能です [shortcut bat はまだ配置されていません]。
goto :fail

:shortcut_failed
echo.
echo [FAIL] ショートカット bat のコピーに失敗しました ["%INSTALL_PARENT_NO_TRAIL%"]。
echo        書き込み権限を確認してください。
REM Migration が走った場合は user に「dir rename は完了済」を案内 (:migrate_failed_launcher と
REM 同パターン、:copy_failed の「shortcut bat はすでに新版」hint との対称性)。user が
REM 「shortcut が壊れたから手動で旧 dir 名に戻そう」と誤対処して migration を巻き戻す path
REM を防ぐ。両 sentinel (Manager/Launcher) が立つのは「両方の rename 成功時」、片方のみは
REM 「片方 skip (= 元から不在) + もう片方 rename 成功」のケース。
if defined MANAGER_MIGRATED goto :shortcut_failed_with_migration_note
if defined LAUNCHER_MIGRATED goto :shortcut_failed_with_migration_note
goto :fail

:shortcut_failed_with_migration_note
echo.
echo  [注意] 旧構造 (v0.2.0) → 新構造への dir rename はすでに完了しています:
REM 空白は echo の前に 1 個固定 (round 6 L5: VAR 名長さに依存した手動 align は将来 sentinel 追加時に崩れる)
if defined MANAGER_MIGRATED echo          "%INSTALL_TARGET%\Manager"   [旧 GCTonePrism_Manager から rename 済]
if defined LAUNCHER_MIGRATED echo          "%INSTALL_TARGET%\Launcher"  [旧 GCTonePrism_Launcher から rename 済]
echo         旧 dir 名 ["%INSTALL_TARGET%\GCTonePrism_*"] に戻さないでください。
echo         書き込み権限を解消してから Install.bat を再実行すれば、shortcut bat だけ
echo         再書き込みされて続行可能です [migration は冪等、再走しても影響なし]。
echo.
echo  [警告] Install.bat 再実行までは、"%INSTALL_PARENT_NO_TRAIL%\Launcher.bat" /
echo         "%INSTALL_PARENT_NO_TRAIL%\Manager.bat" をダブルクリックしないでください。
echo         2 段階 copy で 1 段目成功 + 2 段目失敗の場合、片方が新 path / もう片方が
echo         旧 path (壊れた状態) の不揃いになっている可能性があります。再実行で
echo         両方とも新版に上書きされます。
goto :fail

:install_done

REM ----- (#440) アップデートの受け渡しファイルを掃除する -----
REM 手で入れ直した = それ以前のアップデート試行の結果は無効。放置すると、前回の
REM アプリ内アップデートが失敗したときの記録 (.update_result) が残ったままになり、
REM Manager の「アップデート」タブが解消済みの失敗を言い続ける。
REM
REM .update_completed (Manager -> Manager の申し送り) も同様に無効。Install.bat は
REM これを書かないので、そもそも Manager はこの経路の更新に気づかない (= ダイアログは
REM 出ない)。手で入れた人は自分で分かっているので、それが正しい挙動。
REM
REM 存在しないのが通常なので、失敗しても無視して続行する。
del /q "%INSTALL_TARGET%\.update_result" >nul 2>&1
del /q "%INSTALL_TARGET%\.update_completed" >nul 2>&1

echo.
echo ============================================================================
echo  インストール完了: "%INSTALL_TARGET%"
echo ============================================================================
echo.
echo  日常使い ["%INSTALL_PARENT_NO_TRAIL%"\ 直下のショートカット]:
echo    Launcher.bat   [来場者用 Launcher 起動]
echo    Manager.bat    [運営用 Manager 起動]
echo.

REM ---- Manager start Y/N (top-level, no Japanese echo inside block) ----
REM set /p empty-Enter retains previous value. Initialize to defend.
set "START_MANAGER="
set /p START_MANAGER=Manager を起動しますか？ [Y/N]:
REM Accept y / Y / yes / Yes / YES (Release.ps1 の upload prompt と寛容度を揃える)
if /i "%START_MANAGER%"=="Y"   goto :do_start_manager
if /i "%START_MANAGER%"=="YES" goto :do_start_manager
goto :end
:do_start_manager
echo.
echo [INFO] Manager を起動します...
REM Launch via parent-level Manager.bat (placed by :copy_shortcuts above), to keep
REM the SPEC §3.7.5 "日常起動は Manager.bat 経由" convention consistent across all
REM startup paths (シニアレビュー round 3 M3). Earlier intermediate-cmd residual
REM problem is now handled by Manager.bat's own terminal `exit` (see templates/
REM Manager.bat docstring), so going through the wrapper no longer leaves a stale
REM cmd window. This keeps the future ability to add working-dir setup / env
REM injection / log redirection inside Manager.bat without missing this code path.
start "" "%INSTALL_PARENT_NO_TRAIL%\Manager.bat"
REM Suppress final pause when Manager started (avoid stacking Install.bat 'press
REM any key' prompt on top of Manager UI).
set MANAGER_STARTED=1
goto :end

:fail
set EXIT_CODE=1
goto :end

:end
echo.
REM Final pause (only when Manager not auto-started). cmd default の英語メッセージ
REM "Press any key to continue . . ." を避けて日本語に統一 (シニアレビュー M4)。
if not defined MANAGER_STARTED echo  何かキーを押して終了します...
if not defined MANAGER_STARTED pause >nul
REM `exit` (not `exit /b`) forces cmd process termination so the double-clicked
REM Install.bat window doesn't leave a residual empty prompt. With `exit /b` the
REM bat returns to caller; for `cmd /c install.bat` (the typical Explorer
REM double-click invocation) cmd exits afterwards, but some terminals / cmd-host
REM combinations keep an interactive prompt instead. `exit %CODE%` exits cmd
REM directly with the given code so the window closes uniformly.
REM
REM Trade-off: if a future caller uses `call install.bat` from another bat,
REM `exit` would also terminate the caller. For Phase 3 Updater integration,
REM invoke via `Process.Start("cmd", "/c install.bat ...")` instead of `call`.
endlocal & exit %EXIT_CODE%
