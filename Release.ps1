<#
.SYNOPSIS
    TonePrism のリリース zip を生成し、GitHub Releases にアップロードする。

.DESCRIPTION
    Phase 1 (#108): Launcher + Manager のビルドと zip 化のみ。
        - CHANGELOG.md の最新 `### [Bundle v<X.Y.Z>]` エントリが Bundle version + release_notes 両方の SoT
        - project.godot config/version = Launcher version の SoT (#281)、AssemblyInfo.cs = Manager version の SoT
        - Bundle version は zip タグに使う（例: v0.1.0）
        - GitHub Releases の本文は CHANGELOG.md の該当 Bundle セクションから自動抽出
        - Godot エディタとエクスポートテンプレートは tools/godot/ + %APPDATA%/Godot/export_templates/ に自動ダウンロード（バージョンピン留め + SHA256 検証 + キャッシュ + 3 回 retry）
        - Manager のビルドは dotnet publish (net10 SDK、self-contained single-file) を使用 (#258 PR4)
          - LauncherAgent は dotnet publish で net10 build (#258 PR4.x、配布形態を Manager と揃える)、Updater は VS 同梱 MSBuild で net48 build (番人・不変)
        - release/v<version>/files/ に staging
        - Compress-Archive で release/TonePrism_v<version>.zip 生成
        - zip 完成後、Y/N 確認プロンプト → Y なら gh release create でアップロード、N なら zip だけ残して終了
          (`-SkipUpload` で confirm prompt 自体を skip。CI 等の non-interactive 運用向け)

    Phase 2 (#108) 完成: templates/Install.bat / INSTALL_README.txt / Launcher.bat / Manager.bat 同梱
    Phase 3 (#108) 完成: Companions/Updater/ の build + staging を `Build-Updater` で実装済
    #101/#216/#30 完成:  Companions/LauncherAgent/ の build + staging を `Build-LauncherAgent` で実装済
                         (旧 WindowProbe を統合・置換。Companion が増えたら Build-* を配列化して回す余地あり)
    TODO Monitor:        Monitor/ 追加時にビルドステップ追加

    依存ツールのバージョン管理方針:
        - Godot: project.godot の config/features から major.minor を読み取り、$GodotPatchTable で patch をピン留め
        - .NET: Manager / LauncherAgent = net10 SDK (dotnet publish)、Updater = net48 (MSBuild、番人)
        - MSBuild: Visual Studio 2019+ または VS Build Tools を要求（net48 Companions ビルドのため）
        - 各ツールのバージョン上げは Release.ps1 冒頭定数を手動で書き換え + PR

    必要な環境:
        - Windows 10/11
        - Visual Studio 2019+ または Visual Studio Build Tools (https://aka.ms/vs/17/release/vs_BuildTools.exe、~1-2GB)
          - 「.NET デスクトップビルドツール」ワークロードを選択
        - gh CLI (アップロード時、`gh auth login` 済み)
        - .NET 10 SDK (dotnet、Manager の publish 用) + インターネット接続 (初回 Godot + .NET ランタイムパック DL のため)
        - 開発者は別途 Godot 4.6 をインストールして開発（Release.ps1 は CLI export のみ自動化）

.PARAMETER Version
    リリースバージョン (Bundle version)。省略時は CHANGELOG.md の最新 Bundle エントリから自動取得。
    指定する場合は CHANGELOG.md の最新 Bundle エントリと一致する必要がある。
    SemVer 形式（M.m.p または M.m.p-suffix）。

.PARAMETER GodotExe
    Godot 実行ファイルのパス。指定された場合は自動ダウンロードを skip。

.PARAMETER MsBuildExe
    MSBuild 実行ファイルのパス。空なら自動検出 (vswhere → PATH の順、VS or Build Tools が必要)。

.PARAMETER GodotPatch
    Godot patch version を強制指定 (例: "4.6.2")。
    $GodotPatchTable の自動解決を上書きする。SHA256 検証は skip される。

.PARAMETER SkipUpload
    gh release create を実行しない。zip 生成までで停止。

.PARAMETER DryRun
    ビルドのみ実施。zip 化と upload を skip。Godot/Manager 出力の確認用。
    -SkipUpload を自動で ON にする (upload しないため gh preflight も不要)。

.PARAMETER Force
    既存タグ衝突時に gh release delete してから作り直す。
    uncommitted change があっても続行する。

.PARAMETER Offline
    外部ネットワーク呼び出しを skip。キャッシュにある version で実行。
    Godot DL / nuget DL / GitHub API 呼び出しを行わない。
    -SkipUpload を自動で ON にする (upload は network 必須のため)。

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File .\Release.ps1 -Version 0.1.0 -SkipUpload

.EXAMPLE
    pwsh -ExecutionPolicy Bypass -File .\Release.ps1 -Version 0.1.0 -DryRun -SkipUpload
#>

[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$GodotExe = "",
    [string]$MsBuildExe = "",
    [string]$GodotPatch = "",
    [switch]$SkipUpload,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Offline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# Console output encoding を UTF-8 (no BOM) にピン留め
# ============================================================================
# PS 5.1 + chcp 65001 環境では、子プロセス (Invoke-ExternalProcess 経由の
# Godot CLI / msbuild / nuget 等、RedirectStandardOutput=$false でコンソール
# ハンドルを継承するもの) が走った後、後続の Write-Host で日本語が doubled
# rendering される既知バグがある (症状例: `完了` → `完完了了`、ASCII は影響なし)。
# 観察例として本番 v0.1.0 release では msbuild 後に発火を確認、ただし原因として
# Godot / nuget も同じ条件を満たすので等価候補。
# `[Console]::OutputEncoding` を UTF-8 (no BOM) で明示ピン留めしておく + 各
# Invoke-ExternalProcess 呼び出し後に再ピン留めすることで発火を防ぐ。
# `$OutputEncoding` は PS pipeline → native command への送信時の encoding。
#
# 非 console host ガード: CI / headless / redirected 実行コンテキストでは
# `[Console]::OutputEncoding` setter が IOException を投げ、$ErrorActionPreference='Stop'
# 環境では release 開始前に script が hard abort する。try/catch で吸収。
# (script-level の $script:Utf8NoBomEncoding を一意ソースとして共有、
#  Invoke-ExternalProcess の finally でも同じインスタンスを再代入)
$script:Utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::OutputEncoding = $script:Utf8NoBomEncoding
} catch {
    # non-console host では console API は使えないが、$OutputEncoding (PS 変数) は
    # 引き続き設定可能、native command pipeline 送信側は UTF-8 のまま維持される
}
$OutputEncoding = $script:Utf8NoBomEncoding

# ============================================================================
# Native command 呼び出しの方針 (v0.1.8 で再整理)
# ============================================================================
# 経緯: PS 5.1 + $ErrorActionPreference='Stop' 下では、`&` 演算子 + native
# command の組み合わせで「exit 非ゼロ + stderr 出力」を返すコマンドが
# NativeCommandError の terminating error を発生させる。
# v0.1.6 までは `2>$null` / `2>&1 | Out-String` 系で回避できると考えていたが、
# v0.1.7 で実証された通り PS の error stream への ErrorRecord 化が redirect
# よりも先に発火するため redirect は防御にならない。v0.1.8 で
# `Invoke-NativeWithCapture` ヘルパー (System.Diagnostics.Process 直叩き) に
# 一本化、`&` 系の patterns は「success exit が確証できる場合のみ」に格下げ。
#
# 採用ガイドライン (call site では `# pattern: <NAME>` 1 行で catalog 参照、catalog 既述の
# 一般則は per-site から削除して固有理由のみ残す形式):
#
#   1. Invoke-NativeWithCapture (RECOMMENDED for any failable command)
#      $result = Invoke-NativeWithCapture -FilePath 'gh' -Arguments @('release','view','v1.0','--json','id')
#      # → $result.StdOut / $result.StdErr / $result.ExitCode / $result.Combined
#      # System.Diagnostics.Process で PS error stream を経由しないため罠なし。
#      # 失敗 path で stderr を出すコマンドは必ずこれ (gh release view / gh auth status 等)。
#
#   2. pattern: CAPTURE_STDOUT_PASS_STDERR
#      $output = & native-cmd        # stdout は変数 capture、stderr は console 直書き
#      # exit code チェック必須 ($output が空でも非ゼロ exit を見落とさないため)
#      # 例: git status --porcelain (Assert-WorkingTreeClean)
#
#   3. pattern: PASS_THROUGH — 2 実装あり、機能は同等だが内部メカニズムが違う
#
#      (a) 直 & 演算子版 (現状本 script 内で使用なし):
#          & native-cmd               # stdout/stderr 両方 console 直書き、変数 capture なし
#          # exit code チェック必須 (成否を判定する唯一の信号が exit code のみ)
#          # 注: PS 5.1 + chcp 65001 で子プロセスが OutputEncoding を OEM に戻す
#          #     既知バグの再ピン留め保護がない。短時間の単発呼び出し向け
#
#      (b) Invoke-ExternalProcess helper 経由 (推奨、現状の全 PASS_THROUGH 系):
#          $exitCode = Invoke-ExternalProcess -FilePath $cmd -Arguments @(...)
#          # 内部は [System.Diagnostics.Process]::Start + WaitForExit + Dispose
#          # 引数 quoting + finally で [Console]::OutputEncoding を UTF-8 に再ピン留め
#          # 大量 verbose 出力 + 長時間処理向け (Godot CLI export / msbuild / nuget restore)
#
#      注: gh release create/delete は v0.1.7 まで (a) PASS_THROUGH だったが、TTY 検出
#          で進捗 OFF + 完了まで無音になる UX 問題のため v0.1.8 で
#          Invoke-NativeWithCapture -ShowProgress に移行
#
# ANTI-PATTERNS (使用禁止) — いずれも踏み抜き履歴と deprecation 時点を 2 値で記録:
#
#   X. STOP_TRAP — & cmd 2>&1 / $var = & cmd 2>&1
#      stderr が ErrorRecord として success stream に流れ Stop trap 発火。
#      初回 deprecate from v0.1.0 (script 新設時点)。
#      回避: Invoke-NativeWithCapture へ移行。
#
#   X. SUPPRESS_BOTH — & cmd 2>$null | Out-Null
#      踏み抜き: v0.1.6 (本番 release で gh release view が trap 発火)
#      deprecation: v0.1.8 (anti-pattern として正式格下げ)
#      「2>$null で stderr を捨てれば trap 防げる」前提が誤りだった
#
#   X. CAPTURE_DIAGNOSTIC — $out = & cmd 2>&1 | Out-String
#      踏み抜き: v0.1.7 (gh release view の "release not found" stderr で trap)
#      deprecation: v0.1.8 (anti-pattern として正式格下げ)
#      「Out-String を経由すれば Stop の判定対象外」前提が誤りだった
#
#   X. CAPTURE_STDOUT — $out = & cmd 2>$null
#      踏み抜き履歴なし、deprecation: v0.1.8
#      SUPPRESS_BOTH と同じ構造 (2>$null) を持つため同じ trap 形状。
#      本 script では vswhere で使用していたが v0.1.8 で helper に移行、
#      残存 call site ゼロのため anti-pattern 化
#
#   X. TRY_CATCH_NATIVE — try { & cmd 2>&1 | Out-String } catch { ... }
#      導入: v0.1.7 (CAPTURE_DIAGNOSTIC の trap 回避策として)
#      deprecation: v0.1.8 (Invoke-NativeWithCapture が同目的を関数化したため不要)
#
# PS 7.3+ 移行時の注意 (現状未対応):
#   PS 7.3 以降は $PSNativeCommandUseErrorActionPreference (default $true) が
#   追加され、`& native-cmd` の非ゼロ exit code 自体が ErrorActionPreference に
#   従って terminating error 化する。本スクリプトで残る `&` イディオムは
#   Assert-WorkingTreeClean の `git status --porcelain` のみ。これは PS 7.3+ で
#   `if ($LASTEXITCODE -ne 0)` に到達せず abort する。
#   (Invoke-NativeWithCapture / Invoke-ExternalProcess は Process 直叩きのため
#    $PSNativeCommandUseErrorActionPreference の影響を受けず、移行後も安全)
#   PS 7 移行時には以下のいずれかが必須:
#     (a) script 冒頭で $PSNativeCommandUseErrorActionPreference = $false に固定
#     (b) 残った `&` 系 (git status) も Invoke-NativeWithCapture に移行
#   現状は PS 5.1 を前提とした実装。
# ============================================================================

# -Offline / -DryRun は upload を行わないので preflight の gh 関連チェックも
# skip するため -SkipUpload を auto-promote する (Codex P2 #137 ×2)
if (($Offline -or $DryRun) -and -not $SkipUpload) {
    $SkipUpload = $true
}

# ----------------------------------------------------------------------------
# CHANGELOG.md から最新 Bundle エントリの version を取得して $Version に反映
# (RELEASE_VERSION ファイルは持たない、CHANGELOG が SoT)
# ----------------------------------------------------------------------------
$_changelogPathEarly = Join-Path $PSScriptRoot 'CHANGELOG.md'
if (-not (Test-Path $_changelogPathEarly)) {
    Write-Host "[FAIL] CHANGELOG.md が見つかりません: $_changelogPathEarly" -ForegroundColor Red
    exit 1
}
$_changelogContent = [System.IO.File]::ReadAllText($_changelogPathEarly, [System.Text.Encoding]::UTF8)
# (#108 Phase 4 round 7 L-1) `\s+` 採用 = Manager の ChangelogParser.cs BundleEntryRegex と literal 一致
# (SPEC §3.7.8 sync fence)。旧 literal space (` `) 表現は ChangelogParser 側 (`\s+`) より strict で、
# `### [Bundle v0.3.0]` に tab が混入した瞬間 Release.ps1 だけが silent skip → version bump 検出不能
# になる path があった。`\s+` で揃えて両 path 同 behavior に。
$_latestBundleMatch = [regex]::Match($_changelogContent, '(?m)^###\s+\[Bundle\s+v(\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?)\]')
if (-not $_latestBundleMatch.Success) {
    Write-Host "[FAIL] CHANGELOG.md に '### [Bundle vX.Y.Z]' エントリが見つかりません" -ForegroundColor Red
    exit 1
}
$_latestBundleVersion = $_latestBundleMatch.Groups[1].Value
if ($Version -eq "") {
    $Version = $_latestBundleVersion
} elseif ($Version -ne $_latestBundleVersion) {
    Write-Host "[FAIL] -Version 引数 ($Version) と CHANGELOG.md の最新 Bundle ($_latestBundleVersion) が一致しません" -ForegroundColor Red
    Write-Host "       CHANGELOG.md の最新 Bundle エントリを先頭に追加するか、-Version を省略してください" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 定数: ツールチェイン pin（バージョン上げる時はこのセクションを書き換える）
# ============================================================================

# Godot patch table: major.minor → 採用する patch + SHA256
# 新しい patch を採用したい時は新しい行を追加 + SPEC §3.7.7 のルールに従って PR
$GodotPatchTable = @{
    '4.6' = @{
        Patch  = '4.6.2'
        # SHA256SUMS.txt は GitHub Releases に同梱されている。初回 DL 時に取得して比較する。
        # 値が空文字なら検証 skip + warn（初回 setup 用）。値を確定したら埋める運用。
        Sha256Editor    = ''
        Sha256Templates = ''
    }
}

# ============================================================================
# パス定義
# ============================================================================

$RepoRoot     = $PSScriptRoot
$LauncherDir  = Join-Path $RepoRoot 'Launcher'
$ManagerDir   = Join-Path $RepoRoot 'Manager'
$ToolsDir     = Join-Path $RepoRoot 'tools'
$ToolsGodot   = Join-Path $ToolsDir 'godot'
$StagingRoot  = Join-Path $RepoRoot 'release'
$StagingDir   = Join-Path $StagingRoot "v$Version"
# (#175 Phase 4.1) zip 構造整理: zip 直下 = Install.bat / INSTALL_README.txt のみ、
# それ以外 (Launcher.bat / Manager.bat / show_folder_dialog.ps1 / bundle_manifest.json /
# files/) は `bundle/` 配下に集約。ユーザーが zip 展開した時に「Install.bat を押すだけ」を
# 一目瞭然にする UX 改善 + 将来の dir 構造変更を manifest 経由で forward compat に。
# (#175 Phase 4.1 round 2 Low-3) manifest filename を `$script:ManifestRelativePath` 1 箇所に SoT 集約
# (`$ManifestPath` 計算 + `Assert-ExpectedFiles` の `$zipRootExpected` 両方で参照)。Manager 側
# (`UpdateDownloader.ManifestFileName` const) との 2-layer 同期 fence は別 layer なので各別に管理。
$script:ManifestRelativePath = 'bundle\bundle_manifest.json'
$BundleDir    = Join-Path $StagingDir 'bundle'
$FilesDir     = Join-Path $BundleDir 'files'
$ManifestPath = Join-Path $StagingDir $script:ManifestRelativePath
$ZipPath      = Join-Path $StagingRoot "TonePrism_v$Version.zip"
$ChangelogPath = Join-Path $RepoRoot 'CHANGELOG.md'

# round 3 Low-3: GitHub repo slug を SoT 化。本 script は ken1208git/TonePrism 専用前提
# (Assert-ChangelogLinkDefs で release tag URL を組み立てる用途)。fork / repo rename / org
# transfer 時は本定数 1 箇所の修正で全箇所追随する形に集約。他の gh CLI 呼び出しは `gh` の
# repo 自動検出に依拠していて hardcode していないので、本定数は本 script 内で 1 箇所のみで
# 参照される (将来別箇所で必要になれば本定数を使う規約)。
$GitHubRepoSlug = 'ken1208git/TonePrism'

$script:ResolvedGodot       = $null
$script:ResolvedMsBuild     = $null
$script:ResolvedDotnet      = $null
$script:GodotPatchUsed      = $null  # 解決された Godot patch (例: "4.6.2")
$script:LauncherVersion     = $null
$script:ManagerVersion      = $null
$script:LauncherAgentVersion = $null
$script:DeleteExistingRelease = $false

# ============================================================================
# 出力ユーティリティ
# ============================================================================

function Write-Step { param([string]$Message)
    Write-Host ""; Write-Host "==> $Message" -ForegroundColor Cyan
}
function Write-Info { param([string]$Message) Write-Host "    $Message" -ForegroundColor Gray }
function Write-Ok   { param([string]$Message) Write-Host "    [OK] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "    [WARN] $Message" -ForegroundColor Yellow }
function Fail       { param([string]$Message)
    Write-Host ""; Write-Host "[FAIL] $Message" -ForegroundColor Red; exit 1
}

function Get-ToolPath { param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source } else { return $null }
}

# ============================================================================
# Native command の罠なし呼び出し (冒頭の「Native command 呼び出しの方針」セクション参照)
# ============================================================================

function Invoke-NativeWithCapture {
    <#
    .SYNOPSIS
        Native command を実行し、stdout / stderr / exit code を罠なく取得する。
    .DESCRIPTION
        PowerShell の call operator `&` は「exit 非ゼロ + stderr 出力」の native
        command で NativeCommandError を生成し、$ErrorActionPreference='Stop' 下で
        terminating error として throw する。`2>&1 | Out-String` も同じ罠を踏む
        (Out-String が処理する前に PS の error stream で trap が発火)。本関数は
        System.Diagnostics.Process で stdout/stderr を直接捕捉し、PS の error
        pipeline を経由しないため罠を完全に回避できる。

        失敗 path で stderr を出すコマンド (例: gh release view 不在時 exit 1 +
        "release not found"、gh auth status 未認証時 exit 1) の preflight 系
        チェックは本関数を使うこと。
    .OUTPUTS
        PSCustomObject:
          StdOut   - 標準出力 (string、UTF-8 として decode)
          StdErr   - 標準エラー (string、UTF-8 として decode)
          ExitCode - プロセスの終了コード (int)
          Combined - StdOut + "`n" + StdErr 連結 (検索用、stdout 末尾の改行有無で
                     joining 境界がぶれないよう明示 separator)
        注 1: 子プロセス側が UTF-8 で書く前提。`gh` はデフォルトで UTF-8。
        `vswhere` はデフォルト system codepage 出力なので、本 helper 経由の
        call site では `-utf8` フラグを必ず付与して UTF-8 出力を強制する
        (Resolve-MsBuild 内、日本語 VS install path 等の非 ASCII path も正しく
        decode)。msbuild / nuget は OEM 系 codepage を出す可能性があるため
        本 helper は使わず、Invoke-ExternalProcess (直 console 出力 + encoding
        再ピン留め) 経由で扱う。
        注 2: 本関数は System.Diagnostics.Process 直叩きのため、PS 自動変数の
        `$LASTEXITCODE` は **更新されない**。caller は必ず返り値の `.ExitCode` を
        参照すること。helper 呼び出し直後に `if ($LASTEXITCODE -ne 0)` と書くと、
        その前の `&` 呼び出しの古い値を読む silent failure path になるため厳禁。
    #>
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$Arguments = @(),
        # gh release create のように TTY 検出で進捗描画を OFF にするコマンド向け。
        # ハングしてないことを示す経過秒数を `\r` 上書きで表示。
        [switch]$ShowProgress,
        [string]$ProgressMessage = "実行中..."
    )
    # 引数 quoting は Invoke-ExternalProcess と同じ規則
    # 既知制約: trailing backslash を持つパス引数 (例: "C:\path\") は壊れる。
    #   `"C:\path\"` に変換すると CommandLineToArgvW の規則上 `\"` が閉じ引用符と
    #   して機能せず、引数のパースが破損する (\ × N + " → \ × (N/2) + " デコード)。
    #   現 call site (zip / 一時 notes / vswhere) はいずれも trailing backslash を
    #   持たないため安全。新規 call site でディレクトリパスを渡す場合は要注意。
    # TODO (post v0.1.8): 共通化候補。MSVC argv 規則の特殊ケース (\ を引用直前) で
    #                     Invoke-ExternalProcess との 2 箇所が silent に divergence
    #                     する危険、共通 helper 切り出し時に CommandLineToArgvW 規則
    #                     準拠 (\ × N + " → \\ × N + \") に置換
    $quoted = $Arguments | ForEach-Object {
        if ($_ -match '\s|"') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $FilePath
    $psi.Arguments              = $quoted -join ' '
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8

    $proc = $null
    try {
        # Process.Start 自体が Win32Exception を出す path (file not found / 権限不足)。
        # caller は Get-ToolPath で事前 check しているが、helper 単体としても
        # 例外メッセージに何を実行しようとしたか含める
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
        } catch {
            throw "Invoke-NativeWithCapture: '$FilePath' の起動に失敗しました: $($_.Exception.Message)"
        }

        # 両 stream を async で読みデッドロック回避 (片方のバッファが満杯になると
        # child が block する)。WaitForExit() は timeout なし → network hang する
        # コマンド (gh API 呼び出し) では preflight が無限待機する path が残る
        # → TODO (post v0.1.8): -TimeoutSeconds 引数 + WaitForExit($ms) への移行
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()

        # 非 TTY (CI / log file redirect 等) では `\r` が行リセットとして機能せず、
        # progress 更新ごとに改行付きで log に展開されてノイズになる。
        # IsOutputRedirected で検出して live progress を抑止 (取得自体が例外を投げる
        # 非 console host も同様に redirected 扱いで skip = 安全側)
        $isRedirected = try { [Console]::IsOutputRedirected } catch { $true }
        if ($ShowProgress -and -not $isRedirected) {
            # 進捗描画なしコマンド (gh release create 等) のための擬似 progress。
            # 500ms 間隔で経過秒数を `\r` 上書き表示 (CR で行頭戻り、新しい数字で上書き)
            # clear 幅は console window 幅から動的算出。現在の ProgressMessage 長
            # (~20 chars + zip サイズ + elapsed) では全角文字含めても WindowWidth-1
            # 幅の空白で覆える前提に依存している (全角文字の 2 cell 幅を構造的に
            # 補正してはいない、長文 ProgressMessage を追加する場合は実 cell 幅
            # 計算 = ASCII 1 + 全角 2 への切替を検討する)。
            # Fallback 条件 (どちらも 120 cells に置換):
            #   - WindowWidth 取得が例外を投げる (ISE 等の非 console host)
            #   - WindowWidth - 1 が 30 未満 (例: WindowWidth=0 を返す non-console host /
            #     極端に狭い実コンソール)。30 は ProgressMessage 等が最低限収まる threshold
            $clearWidth = try { [Console]::WindowWidth - 1 } catch { 120 }
            if ($clearWidth -lt 30) { $clearWidth = 120 }
            $clearLine = ' ' * $clearWidth
            $start = Get-Date
            while (-not $proc.HasExited) {
                $elapsed = [int]((Get-Date) - $start).TotalSeconds
                Write-Host -NoNewline "`r    $ProgressMessage ${elapsed}s 経過"
                Start-Sleep -Milliseconds 500
            }
            # progress 行を完全に消して cursor を行頭へ (後続の出力が綺麗に流れる)
            Write-Host -NoNewline "`r$clearLine`r"
        }
        # 両 path 合流点の WaitForExit() の役割は path 毎に異なる:
        #   ShowProgress 経路: HasExited ループ後の no-op、表面的対称性のみ
        #   非 ShowProgress 経路: プロセス完了を明示待機する唯一のポイント
        # どちらも削除不可。前者は対称性 / 保険、後者は機能上の必須。
        #
        # 注: WaitForExit() (no-arg) のパイプバッファフラッシュ保証は
        # BeginOutputReadLine / BeginErrorReadLine (event-based 非同期) に対する
        # ものであり、本実装が使う ReadToEndAsync (Task-based) には適用されない。
        # 実際のフラッシュ保証は直後の $outTask.Result / $errTask.Result が EOF まで
        # ブロックすることで提供される。`.Result` を削除すると出力切り捨てバグが
        # 発生するため touch しないこと
        $proc.WaitForExit()

        # AggregateException (faulted task) は明示メッセージで rethrow し、何が
        # 失敗したか caller に伝える
        try {
            $stdout = $outTask.Result
            $stderr = $errTask.Result
        } catch {
            throw "Invoke-NativeWithCapture: '$FilePath' の出力読み取りに失敗しました: $($_.Exception.Message)"
        }

        # Combined の separator 判定 (stdout の末尾改行を軸に 2 分岐):
        #   stdout 空 or 末尾 \n あり  → 単純連結 ($stdout + $stderr)
        #     - stdout 空 + stderr 有  → $stderr そのまま (Combined 先頭 = stderr、^regex effective)
        #     - 末尾 \n あり + stderr 有 → 改行はすでに含まれる
        #     - stderr 空              → $stdout だけ (trailing \n 有無は stdout 次第)
        #   stdout 末尾 \n なし        → `\n` を明示挟む ($stdout + "`n" + $stderr)
        #     - stderr 有              → ^pattern 取りこぼし防止
        #     - stderr 空              → Combined 末尾に trailing \n が付く (caller が
        #                                TrimEnd() で吸収する想定、現 call site は全て適用済み)
        if ($stdout -and -not $stdout.EndsWith("`n")) {
            $combined = $stdout + "`n" + $stderr
        } else {
            $combined = $stdout + $stderr
        }

        return [PSCustomObject]@{
            StdOut   = $stdout
            StdErr   = $stderr
            ExitCode = $proc.ExitCode
            Combined = $combined
        }
    } finally {
        # Process オブジェクトは Dispose 必須 (handle leak 防止)
        if ($null -ne $proc) {
            $proc.Dispose()
        }
    }
}

# ============================================================================
# Download with retry + SHA256 verification
# ============================================================================

function Invoke-DownloadWithRetry {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$ExpectedSha256 = '',
        [int]$MaxRetries = 3
    )
    if ($Offline) {
        Fail "Offline モード時はダウンロードできません: $Url"
    }

    # HttpClient によるチャンク読み出し + 50MB / 5 秒ごとの進捗表示
    # PS 5.1 標準の Invoke-WebRequest はプログレスバー描画バグで DL が極端に遅くなるため不採用
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

    $tempFile = "$OutFile.partial"
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Info "DL [$attempt/$MaxRetries]: $Url"
            $startTime = Get-Date

            $client = New-Object System.Net.Http.HttpClient
            $client.Timeout = [System.TimeSpan]::FromMinutes(15)
            try {
                $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
                if (-not $response.IsSuccessStatusCode) {
                    throw "HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)"
                }

                $total = $response.Content.Headers.ContentLength
                $totalMb = if ($total) { [math]::Round($total / 1MB, 0) } else { 0 }
                Write-Info "サイズ: $totalMb MB"

                $netStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
                $fileStream = [System.IO.File]::Create($tempFile)
                try {
                    $buffer = New-Object byte[] 81920  # 80KB chunks
                    $received = 0
                    $lastReportBytes = 0
                    $lastReportTime = $startTime
                    while (($read = $netStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $fileStream.Write($buffer, 0, $read)
                        $received += $read

                        # 50MB or 5 秒経過で進捗表示
                        $elapsed = (Get-Date) - $lastReportTime
                        if (($received - $lastReportBytes) -ge 50MB -or $elapsed.TotalSeconds -ge 5) {
                            $totalElapsed = (Get-Date) - $startTime
                            $mb = [math]::Round($received / 1MB, 0)
                            $speedMbs = if ($totalElapsed.TotalSeconds -gt 0) { [math]::Round(($received / 1MB) / $totalElapsed.TotalSeconds, 1) } else { 0 }
                            if ($total) {
                                $pct = [math]::Round(($received / $total) * 100, 0)
                                Write-Host "        $pct% ($mb / $totalMb MB, $speedMbs MB/s)" -ForegroundColor DarkGray
                            } else {
                                Write-Host "        $mb MB ($speedMbs MB/s)" -ForegroundColor DarkGray
                            }
                            $lastReportBytes = $received
                            $lastReportTime = Get-Date
                        }
                    }
                } finally {
                    $fileStream.Close()
                    $netStream.Close()
                }
            } finally {
                $client.Dispose()
            }

            if (-not (Test-Path $tempFile)) {
                throw "ダウンロード後にファイルが存在しません"
            }
            $finalElapsed = (Get-Date) - $startTime
            $finalMb = [math]::Round((Get-Item $tempFile).Length / 1MB, 1)
            $avgSpeed = if ($finalElapsed.TotalSeconds -gt 0) { [math]::Round($finalMb / $finalElapsed.TotalSeconds, 1) } else { 0 }
            Write-Info "DL 完了: $finalMb MB / $($finalElapsed.TotalSeconds.ToString('F1'))s (avg $avgSpeed MB/s)"

            if ($ExpectedSha256) {
                $actual = (Get-FileHash $tempFile -Algorithm SHA256).Hash.ToLowerInvariant()
                $expected = $ExpectedSha256.ToLowerInvariant()
                if ($actual -ne $expected) {
                    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                    throw "SHA256 不一致 (expected=$expected, actual=$actual)"
                }
                Write-Info "SHA256 検証 OK"
            } else {
                Write-Warn "SHA256 ハッシュが未設定のため検証 skip"
            }

            Move-Item $tempFile $OutFile -Force
            return
        } catch {
            Write-Warn "DL 失敗 [$attempt/$MaxRetries]: $_"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            if ($attempt -eq $MaxRetries) {
                Fail "ダウンロードに $MaxRetries 回失敗しました: $Url`n        最後のエラー: $_"
            }
            Start-Sleep -Seconds (2 * $attempt)  # 2s, 4s, 6s
        }
    }
}

# ============================================================================
# Godot 解決: project.godot 読み取り → patch lookup → DL + キャッシュ
# ============================================================================

function Assert-GodotMinorFromProject {
    $projectGodot = Join-Path $LauncherDir 'project.godot'
    if (-not (Test-Path $projectGodot)) {
        Fail "project.godot が見つかりません: $projectGodot"
    }
    $content = Get-Content $projectGodot -Raw
    # 例: config/features=PackedStringArray("4.6", "Forward Plus")
    $m = [regex]::Match($content, 'config/features=PackedStringArray\("(\d+\.\d+)"')
    if (-not $m.Success) {
        Fail "project.godot から Godot major.minor を抽出できませんでした"
    }
    return $m.Groups[1].Value
}

function Resolve-Godot {
    Write-Step "Godot 実行ファイルを解決"

    # project.godot から major.minor を取得し、patch を決定（-GodotExe 指定時も templates 確認のため必要）
    $minor = Assert-GodotMinorFromProject
    Write-Info "project.godot 由来の Godot: $minor 系"

    $patch = $null
    $sha256Editor = ''
    $sha256Templates = ''
    if ($GodotPatch -ne "") {
        $patch = $GodotPatch
        Write-Warn "Godot patch を手動上書き: $patch (SHA256 検証 skip)"
    } elseif ($GodotPatchTable.ContainsKey($minor)) {
        $entry = $GodotPatchTable[$minor]
        $patch = $entry.Patch
        $sha256Editor = $entry.Sha256Editor
        $sha256Templates = $entry.Sha256Templates
        Write-Info "patch table から解決: $patch"
    } else {
        Fail "Godot $minor 用の patch が `$GodotPatchTable に未登録です。`n        Release.ps1 冒頭の定数を編集して patch + SHA256 を登録してください。`n        または -GodotPatch <version> で一時的に指定できます。"
    }
    $script:GodotPatchUsed = $patch

    # エディタ解決: -GodotExe 優先、なければキャッシュ確認 → 自動 DL
    if ($GodotExe -ne "") {
        if (-not (Test-Path $GodotExe)) {
            Fail "指定された Godot が見つかりません: $GodotExe"
        }
        $script:ResolvedGodot = $GodotExe
        Write-Ok "Godot エディタ (手動指定): $GodotExe"
    } else {
        $godotVerDir = Join-Path $ToolsGodot $patch
        $godotExePath = Join-Path $godotVerDir "Godot_v$patch-stable_win64.exe"
        if (Test-Path $godotExePath) {
            Write-Ok "Godot エディタ キャッシュ命中: $godotExePath"
            $script:ResolvedGodot = $godotExePath
        } else {
            if ($Offline) {
                Fail "Offline モード時は Godot キャッシュが必要です: $godotVerDir"
            }
            Write-Info "Godot エディタを DL: v$patch"
            if (-not (Test-Path $godotVerDir)) {
                New-Item -ItemType Directory -Path $godotVerDir -Force | Out-Null
            }
            $editorZipUrl = "https://github.com/godotengine/godot/releases/download/$patch-stable/Godot_v$patch-stable_win64.exe.zip"
            $editorZip    = Join-Path $godotVerDir "Godot_v$patch-stable_win64.exe.zip"
            Invoke-DownloadWithRetry -Url $editorZipUrl -OutFile $editorZip -ExpectedSha256 $sha256Editor
            Write-Info "展開中..."
            Expand-Archive -Path $editorZip -DestinationPath $godotVerDir -Force
            Remove-Item $editorZip -Force
            if (-not (Test-Path $godotExePath)) {
                Fail "展開後の Godot exe が見つかりません: $godotExePath"
            }
            Write-Ok "Godot エディタ展開完了: $godotExePath"
            $script:ResolvedGodot = $godotExePath
        }
    }

    # Export templates は %APPDATA%/Godot/export_templates/<patch>.stable/ にあるか必ず確認
    # -GodotExe を指定していてもエディタ単体ではエクスポートできないため
    $godotVerDir = Join-Path $ToolsGodot $patch  # templates DL 用の作業ディレクトリ
    if (-not (Test-Path $godotVerDir)) {
        New-Item -ItemType Directory -Path $godotVerDir -Force | Out-Null
    }
    $templatesDir = Join-Path $env:APPDATA "Godot\export_templates\$patch.stable"
    if (Test-Path (Join-Path $templatesDir 'windows_release_x86_64.exe')) {
        Write-Ok "Templates キャッシュ命中: $templatesDir"
    } else {
        if ($Offline) {
            Fail "Offline モード時は templates キャッシュが必要です: $templatesDir"
        }
        Write-Info "Templates を DL: v$patch"
        if (-not (Test-Path $templatesDir)) {
            New-Item -ItemType Directory -Path $templatesDir -Force | Out-Null
        }
        $tpzUrl = "https://github.com/godotengine/godot/releases/download/$patch-stable/Godot_v$patch-stable_export_templates.tpz"
        $tpzPath = Join-Path $godotVerDir "Godot_v$patch-stable_export_templates.tpz"
        Invoke-DownloadWithRetry -Url $tpzUrl -OutFile $tpzPath -ExpectedSha256 $sha256Templates
        # .tpz は zip 形式。中身は templates/ ディレクトリ配下にファイルが並ぶ
        $extractTemp = Join-Path $godotVerDir 'tpz_extract'
        if (Test-Path $extractTemp) { Remove-Item -Recurse -Force $extractTemp }
        # .tpz を一度 .zip に rename して Expand-Archive で展開
        $tpzAsZip = "$tpzPath.zip"
        Copy-Item $tpzPath $tpzAsZip -Force
        Expand-Archive -Path $tpzAsZip -DestinationPath $extractTemp -Force
        # 展開構造: $extractTemp/templates/*.* を $templatesDir にコピー
        $tpzInner = Join-Path $extractTemp 'templates'
        if (-not (Test-Path $tpzInner)) {
            Fail "templates 展開構造が想定外: $extractTemp 配下に 'templates' ディレクトリがありません"
        }
        Get-ChildItem $tpzInner | ForEach-Object {
            Copy-Item $_.FullName (Join-Path $templatesDir $_.Name) -Force
        }
        Remove-Item -Recurse -Force $extractTemp
        Remove-Item $tpzPath -Force
        Remove-Item $tpzAsZip -Force
        # Release.ps1 管理下を識別するためのマーカーファイル
        # Clear-OldGodot で AppData の古い templates を安全に掃除する根拠
        Set-Content -Path (Join-Path $templatesDir '.gctone_managed') -Value "Release.ps1 v$Version installed at $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))" -NoNewline
        Write-Ok "Templates 展開完了: $templatesDir"
    }
}

# ============================================================================
# dotnet (net10 SDK) 解決: Manager は net10 で dotnet publish するため hard dependency (#258 PR4)
# ============================================================================

function Resolve-Dotnet {
    Write-Step "dotnet (net10 SDK) を解決"

    # (#258 PR4 レビュー Medium) Manager は Build-Manager で dotnet publish するため dotnet (net10 SDK) が必須。
    # Godot / MsBuild と同様に preflight で解決・検証し、未導入なら Build-Launcher (Godot export、数分) より前に fail-fast する。
    $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Fail @"
dotnet が PATH に見つかりません。Manager は net10 で dotnet publish (self-contained single-file) するため
.NET 10 SDK が必要です。https://dotnet.microsoft.com/download から .NET 10 SDK を導入してください。
"@
    }
    $script:ResolvedDotnet = $cmd.Source

    # net10.0-windows を publish できる SDK があるか確認 (SDK が無いと NETSDK エラーで失敗)。
    # SDK major >= 10 を許容: より新しい SDK (11+) でも roll-forward で net10.0 を target/publish 可能なため、
    # 厳密に "10.x" 固定にすると将来 SDK 更新時に preflight が誤 fail する (#258 PR4 レビュー Low)。
    $sdks = & $script:ResolvedDotnet --list-sdks
    $hasNet10 = $false
    foreach ($line in $sdks) {
        if ($line -match '^\s*(\d+)\.\d+\.' -and [int]$Matches[1] -ge 10) { $hasNet10 = $true; break }
    }
    if (-not $hasNet10) {
        Fail @"
net10.0 を publish できる SDK が見つかりません (.NET 10 以上が必要、Manager は net10.0-windows)。
検出された SDK 一覧:
$($sdks -join "`n")
https://dotnet.microsoft.com/download から .NET 10 SDK を導入してください。
"@
    }
    # limitation (#258 PR4 レビュー): 本 preflight は SDK 存在のみ検証。self-contained publish は net10 の
    # ランタイムパック (Microsoft.WindowsDesktop.App.Runtime.win-x64 10.x) を NuGet restore する必要があり、
    # その restore 可否 (SDK 11 のみ + cache cold + offline 等) は Build-Manager の publish で初めて判明する
    # (loud fail なので silent ではないが、Build-Launcher の後になる)。SDK 存在 = publish 成功保証ではない。
    Write-Ok "dotnet 解決: $script:ResolvedDotnet (net10 SDK あり)"
}

# ============================================================================
# MSBuild 解決: Windows 同梱の .NET Framework MSBuild を使う
# ============================================================================

function Resolve-MsBuild {
    Write-Step "MSBuild を解決"

    if ($MsBuildExe -ne "") {
        if (-not (Test-Path $MsBuildExe)) {
            Fail "指定された MSBuild が見つかりません: $MsBuildExe"
        }
        $script:ResolvedMsBuild = $MsBuildExe
        Write-Ok "MSBuild (手動指定): $MsBuildExe"
        return
    }

    # Manager は C# 7+ (ValueTuple / string interpolation / out var 等) を使うため
    # Roslyn 2.x+ → MSBuild 14+ が必須。Windows 同梱 .NET Framework 4.0 MSBuild は
    # csc が古すぎてビルド不可。Visual Studio 2019+ または Build Tools が必要。
    #
    # 優先順位:
    # 1. Visual Studio / Build Tools (vswhere 経由)
    # 2. PATH 上の msbuild

    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { $vswhere = "$env:ProgramFiles\Microsoft Visual Studio\Installer\vswhere.exe" }
    if (Test-Path $vswhere) {
        # vswhere は検索 hit なし時に exit 0 + 空 stdout を返すが、実行環境破損
        # (権限 / インストーラ破損 等) で exit 非ゼロ + stderr 出力する可能性もある。
        # `-utf8` 必須: Invoke-NativeWithCapture は stdout を UTF-8 として decode する
        # ため、vswhere の default (system codepage) 出力だと non-UTF-8 locale で
        # non-ASCII install path (日本語 VS install path 等) が mojibake → 後段の
        # Test-Path が失敗 → MSBuild 検出失敗の path に落ちる
        $vswhereResult = Invoke-NativeWithCapture -FilePath $vswhere `
            -Arguments @('-latest', '-products', '*', '-requires', 'Microsoft.Component.MSBuild', '-property', 'installationPath', '-utf8')
        # vswhere 失敗時は warn して PATH fallback path に落とす (Fail にはしない —
        # PATH に msbuild があれば release は続行できるため)。コメント上で「stderr
        # 出力する可能性」を挙げた以上、その出力をユーザーに届けないと silent pass
        if ($vswhereResult.ExitCode -ne 0) {
            Write-Warn "vswhere が exit $($vswhereResult.ExitCode) で終了 (権限 / VS Installer 破損等の可能性):"
            $vswhereStderr = $vswhereResult.StdErr.TrimEnd()
            if ($vswhereStderr -match '\S') { Write-Warn $vswhereStderr }
            Write-Info "PATH fallback に切替えて MSBuild を探します"
            # 失敗時の StdOut は意図的に破棄: 部分出力 (権限エラーで途中まで吐いた
            # 不完全 path 等) を後段の Test-Path 経路に流すと「PATH fallback に切替」
            # 宣言と矛盾、`if ($vsInstall)` ブロックを silent skip するために明示クリア
            $vsInstall = ''
        } else {
            $vsInstall = $vswhereResult.StdOut.Trim()
        }
        if ($vsInstall) {
            $vsCands = @(
                (Join-Path $vsInstall 'MSBuild\Current\Bin\MSBuild.exe'),
                (Join-Path $vsInstall 'MSBuild\17.0\Bin\MSBuild.exe'),
                (Join-Path $vsInstall 'MSBuild\15.0\Bin\MSBuild.exe')
            )
            foreach ($c in $vsCands) {
                if (Test-Path $c) {
                    $script:ResolvedMsBuild = $c
                    Write-Ok "MSBuild (Visual Studio): $c"
                    return
                }
            }
        }
    }

    # fallback: PATH 上の msbuild
    $cmd = Get-ToolPath 'msbuild'
    if ($cmd) {
        $script:ResolvedMsBuild = $cmd
        Write-Ok "MSBuild (PATH): $cmd"
        return
    }

    # MSBuild なし → 詳細な install ガイドを出して fail
    Fail @"
MSBuild が見つかりません。Manager は C# 7+ を使うため、Visual Studio 2019+ または
Visual Studio Build Tools のインストールが必要です。

【インストール方法】
1. https://visualstudio.microsoft.com/downloads/ にアクセス
2. 「Visual Studio 2022 Build Tools」または「Visual Studio Community」をダウンロード
   - Build Tools のみ (軽量、~1-2GB): https://aka.ms/vs/17/release/vs_BuildTools.exe
3. インストーラ起動後、ワークロード選択画面で「.NET デスクトップビルドツール」にチェック
4. インストール完了後、Release.ps1 を再実行

【インストールしたくない場合】
- -MsBuildExe で MSBuild.exe のフルパスを指定することも可能
- ただし MSBuild 14+ (VS 2015 以降相当) でないと Manager はビルドできない
"@
}

# (#258 PR4) NuGet 解決関数は撤去。Manager が net10 で dotnet publish に移行し nuget.exe を一切使わなくなった
# (Updater は依存ゼロの msbuild 直叩き、Manager / LauncherAgent の publish は dotnet が暗黙 restore)。

# ============================================================================
# git working tree が clean か検証 (Codex P1 #137 への対応)
# Set-ExportPresetVersions が export_presets.cfg を書き換えうるため、
# preflight と sync 後の 2 回呼ぶ
# ============================================================================

function Assert-WorkingTreeClean {
    param(
        [string]$Context,    # phase identifier (Fail / Warn message にも含まれる、user-facing diagnostic)
        [switch]$PostSync    # 特例メッセージ (Set-ExportPresetVersions が書き換えた旨) のトリガ
    )
    # pattern: CAPTURE_STDOUT_PASS_STDERR
    $gitStatus = & git -C $RepoRoot status --porcelain
    if ($LASTEXITCODE -ne 0) {
        Fail "git status の実行に失敗しました (exit code: $LASTEXITCODE, context: $Context)"
    }
    if ($gitStatus) {
        if ($Force) {
            Write-Warn "uncommitted change がありますが -Force のため続行 ($Context)"
            ($gitStatus -split "`n") | ForEach-Object { Write-Info "    $_" }
        } else {
            Write-Host ""
            Write-Host "    uncommitted change が検出されました ($Context):" -ForegroundColor Yellow
            ($gitStatus -split "`n") | ForEach-Object { Write-Host "        $_" -ForegroundColor Yellow }
            if ($PostSync) {
                Fail "Set-ExportPresetVersions が tracked files を書き換えました。差分をコミットしてから再実行してください (一度書き換えれば idempotent なので次回 sync は no-op)。-Force でバイパス可能。"
            } else {
                Fail "コミットしてから再実行するか、-Force で続行してください。"
            }
        }
    } else {
        Write-Ok "git working tree clean ($Context)"
    }
}

# ============================================================================
# CHANGELOG.md から [Bundle v<Version>] セクションを抽出
# ============================================================================

function Get-BundleReleaseNotes {
    param([switch]$AllowMissing)
    if (-not (Test-Path $ChangelogPath)) {
        if ($AllowMissing) { return '' }
        Fail "CHANGELOG.md が見つかりません: $ChangelogPath"
    }
    $content = [System.IO.File]::ReadAllText($ChangelogPath, [System.Text.Encoding]::UTF8)
    # `### [Bundle v0.1.0] - YYYY-MM-DD` から次の `### ` / `^-{3,}\s*$` (= 3 文字以上の `-` 単独行) /
    # `## ` / EOF まで。`\Z`: 後続セクション無しの初回 Bundle release だけが該当する保険。
    # (#108 Phase 4 round 5 M-4) 旧 `^---` だと body 内 horizontal rule で silent truncation する path
    # があったため `^-{3,}\s*$` に厳密化、Manager の ChangelogParser.cs と同型同期。
    # (#108 Phase 4 round 7 L-1) heading の literal space を `\s+` に変更 = ChangelogParser.cs の
    # BundleEntryRegex と literal 一致 (SPEC §3.7.8 sync fence)。tab 混入で Release.ps1 のみ silent
    # skip する path 防止。
    $pattern = '(?ms)^###\s+\[Bundle\s+v' + [regex]::Escape($Version) + '\][^\r\n]*\r?\n(.*?)(?=^### |^-{3,}\s*$|^## |\Z)'
    $m = [regex]::Match($content, $pattern)
    if (-not $m.Success) { return '' }
    return $m.Groups[1].Value.Trim()
}

$script:ReleaseNotesText = ''

# ============================================================================
# Phase 0: Preflight
# ============================================================================

function Assert-Preflight {
    Write-Step "Preflight: 環境とパラメータを検証"

    # Version 形式 (CHANGELOG から取った時点で確定済みだが念のため)
    if ($Version -notmatch '^\d+\.\d+\.\d+(-[a-zA-Z0-9.-]+)?$') {
        Fail "Version 形式が不正です（期待: M.m.p または M.m.p-suffix）: $Version"
    }
    Write-Ok "Bundle version (CHANGELOG 由来): $Version"

    # gh CLI
    if (-not $SkipUpload) {
        $gh = Get-ToolPath 'gh'
        if (-not $gh) {
            Fail "gh (GitHub CLI) が見つかりません。`n        https://cli.github.com/ からインストールするか、-SkipUpload で upload を抑止してください。"
        }
        Write-Ok "gh: $gh"
        # gh auth status は未認証時 exit 1 + stderr 出力 → Invoke-NativeWithCapture で
        # 罠なく捕捉。失敗原因は多様 (未認証 / token expiry / network / proxy /
        # gh install 破損)、Combined を Fail メッセージに含めて切り分け可能にする
        $authResult = Invoke-NativeWithCapture -FilePath 'gh' -Arguments @('auth', 'status')
        if ($authResult.ExitCode -ne 0) {
            Fail "gh 認証に失敗しました (`gh auth login` を実行 / network / proxy / token expiry 等を確認)。`n$($authResult.Combined.TrimEnd())"
        }
        Write-Ok "gh 認証 OK"
        # gh は exit 0 でも stderr に early warning を出すことがある (token scope 不足の
        # 予兆 / token expiry 近接通知 等)。Fail はしないが、リリース担当に気付かせる。
        # 検出は `^warning:` (gh 公式の warning prefix) のみに絞る (token expiry 特殊形式
        # まで網羅する regex は false positive 多 + gh 出力フォーマット変更に脆弱)。
        # warning は実態として stderr 出力なので StdErr を直接見る (Combined だと
        # stdout 末尾改行有無で行境界がブレうる)
        if ($authResult.StdErr -match '(?im)^warning:') {
            Write-Warn "gh auth status からの警告 (release 実行自体は継続):`n$($authResult.StdErr.TrimEnd())"
        }
    }

    # CHANGELOG から Bundle セクションを抽出できるか確認
    # (release_notes は CHANGELOG が SoT、Release.ps1 が抜き出して --notes に渡す)
    if (-not $SkipUpload) {
        $notes = Get-BundleReleaseNotes
        if (-not $notes) {
            Fail "CHANGELOG.md に [Bundle v$Version] セクションが見つかりません。`n        CHANGELOG.md の `## Bundle` 配下に該当 entry を追加してから再実行してください。"
        }
        $script:ReleaseNotesText = $notes
        Write-Ok "CHANGELOG から Bundle v$Version セクションを抽出 ($($notes.Length) 文字)"
    } else {
        $notes = Get-BundleReleaseNotes -AllowMissing
        if ($notes) {
            $script:ReleaseNotesText = $notes
            Write-Info "CHANGELOG Bundle セクション検出: $($notes.Length) 文字 (-SkipUpload のため未使用)"
        } else {
            Write-Warn "CHANGELOG に [Bundle v$Version] セクション未追加（-SkipUpload のためスキップ）"
            $script:ReleaseNotesText = ''
        }
    }

    # uncommitted change
    Assert-WorkingTreeClean -Context "preflight"

    # 注: 既存リリースとのタグ衝突チェックは Resolve-TagConflict() で別フェーズ。
    # zip 完成後 / Y/N upload prompt の前に呼ぶ設計 (zip 生成までは既存タグでも通す
    # ことで、Install.bat 検証等の運用を救う; "publish 不可なのに Y を聞く" 順序を避ける)
}

# ============================================================================
# Phase 9.5: 既存リリースとのタグ衝突チェック (zip 完成後、Y/N prompt の前に呼ぶ)
# ============================================================================
# Y/N prompt の前にチェックする理由:
#   旧設計 (Y/N の後にチェック) では「publish 不可なのに Y を聞いて、Y 押させた後に
#   Fail」というミスリードな順序になる。先にチェックすれば、conflict 検出時に
#   「publish できません、zip は残します」と graceful exit でき、ユーザーが
#   Y/N の判断をする前に状態を把握できる。

function Resolve-TagConflict {
    Write-Step "GitHub Releases タグ衝突チェック"

    # gh release view は release 不在時に exit 1 + stderr "release not found" を出す。
    # Invoke-NativeWithCapture で stdout/stderr/exit を罠なく分離捕捉。
    # `--json id`: 存在時の stdout を最小化 (capture 文字列が小さくなる、parse はしない)。
    # 存在判定は exit code を一次軸、stderr 文字列マッチは「不在 vs 別種失敗」の識別のみ。
    $releaseResult = Invoke-NativeWithCapture -FilePath 'gh' `
        -Arguments @('release', 'view', "v$Version", '--json', 'id')

    if ($releaseResult.ExitCode -eq 0) {
        # 既存 release あり
        if ($Force) {
            Write-Warn "タグ v$Version は既存だが -Force のため後で削除して作り直す"
            $script:DeleteExistingRelease = $true
        } else {
            # 既存 + -Force なし: publish 不可、Y/N に進ませず情報提示で graceful exit。
            # exit code: 2 = tag conflict による publish skip (シニアレビュー round 3 M4)。
            # 旧設計は exit 0 で「成功 + 公開なし」を表現していたが、CI が
            # `Release.bat` を回した結果「publish できなかった」のか「publish した」のかを
            # exit code 単独で区別できない silent path だった。新設計の exit code 体系:
            #   0  = publish 成功 / -SkipUpload / -DryRun
            #   1  = script の本来失敗 (build error / publish error / 環境破損等)
            #   2  = tag conflict による publish skip (env state、CI から見ると "未発火")
            #   3  = Y/N の N 回答による intentional skip
            # Fail (exit 1 + 赤字 FAIL) ではなく warn + exit 2 にしている理由:
            #   - zip 生成自体は成功している (Install.bat 検証等に流用可)
            #   - publish 不可は「環境状態」であって「script の失敗」ではない
            #   - 2 で区別すれば CI が "未発火" を検出して別途リトライ判断できる
            Write-Host ""
            Write-Warn "GitHub Releases に v$Version が既存です。本セッションでは publish できません。"
            Write-Host ""
            Write-Info "zip は以下に残っています (Install.bat 検証等に流用可):"
            Write-Info "  $ZipPath"
            Write-Host ""
            Write-Info "publish するには以下のいずれか:"
            Write-Info "  (a) .\Release.bat -Force"
            Write-Info "     既存 v$Version を削除して同 version で publish 再実行"
            Write-Info "     (再 build は走るが Godot / nuget の DL キャッシュは温存されるため初回より速い)"
            Write-Info "  (b) CHANGELOG.md の ## Bundle に v$Version 以外の新 entry 追加 → .\Release.bat"
            Write-Info "     version を bump して新規 publish"
            Write-Host ""
            exit 2
        }
    } else {
        # exit 非ゼロ → 不在 or 別種失敗。stderr の英文字列で識別
        # (注: gh の i18n / 文言変更で取りこぼし可能性あり、その時は再 trapping。
        #  本格的な structured 検出は --json + ConvertFrom-Json + HTTP 404 判定 etc.)
        if ($releaseResult.StdErr -match 'release not found') {
            Write-Ok "タグ衝突なし: v$Version"
            $script:DeleteExistingRelease = $false
        } else {
            # 別種の失敗 (auth / network / API rate limit / gh install 破損 等)
            # この時点で zip は既に作成済み (New-Zip 完了後にこの関数が呼ばれる)。
            # publish できなくとも zip 自体は流用可能なので、Fail 直前にパスを案内する。
            # シニアレビュー M3: 既存タグの graceful exit path と同じ "zip は残っている"
            # メッセージを network 失敗 path にも適用、ユーザーが zip を破棄されたと
            # 誤解する path を防ぐ。
            Write-Host ""
            Write-Info "zip は以下に残っています (publish 失敗とは独立、Install.bat 検証等に流用可):"
            Write-Info "  $ZipPath"
            Write-Host ""
            Fail "gh release view が予期せず失敗しました (exit $($releaseResult.ExitCode)):`n$($releaseResult.Combined.TrimEnd())"
        }
    }
}

# ============================================================================
# Phase 0.5: CHANGELOG 末尾 Bundle 参照リンク定義の検証
# ============================================================================
# Markdown reference-style link を resolve するためには CHANGELOG 末尾に
# `[Bundle vX.Y.Z]: https://github.com/.../releases/tag/vX.Y.Z` の定義が要る。
# Bundle entry 追加時に手で同時追加するのが AGENTS.md "Release and Versioning" 規約だが、
# 人間 / Claude いずれもミスする可能性があるため、Release.ps1 release 実行前にこの定義の
# 存在を verify して未追加なら Fail で停止する fence を設ける。
#
# 配置: Phase 0.5 (= Assert-Preflight の直後、Build 群より前)
#   round 1 Medium-1: 初版は Assert-ExpectedFiles の **後** (build 完了後) に置いていたが、
#   link def 忘れを「数分のフル build を捨ててから検出」する fail-fast 違反だった。本 Assert
#   は $Version + CHANGELOG.md のみに依存し build 結果を見ない → Preflight 直後に配置する
#   ことで「実行直後 (build 前) に物理的に検知」を実現。AGENTS.md 「実行直後の Assert」
#   記述とも整合化。
#
# 自動 mutation (Release.ps1 が末尾を書き換える) は採らない:
#   - commit/staging のタイミングと干渉する
#   - dry-run と本番で挙動分岐が複雑化する
#   - SoT (CHANGELOG) を script が書き換える形は git 履歴の追跡性を悪くする
# 「検証だけ」で止めれば、リリース直前に手追加忘れに気づいて修正 → 再 Release.bat で済む。

function Assert-ChangelogLinkDefs {
    # round 2 L2: Write-Step convention に揃え (position メタは header コメント側で伝達)。
    Write-Step "CHANGELOG 末尾 Bundle 参照リンク定義の検証"

    # round 2 M2: -SkipUpload 時は publish しない → 参照リンク URL (releases/tag/vX.Y.Z) の
    # resolution 自体が無意味、CHANGELOG 完備の強制契約も緩める。既存 Preflight が CHANGELOG
    # `### [Bundle v$Version]` セクション検証で同じ pattern を採っている (Release.ps1:919
    # `if (-not $SkipUpload) {...Fail} else {Write-Warn}`)、AGENTS.md「release 実行時に verify」
    # 文言とも整合。
    #
    # 注: `-DryRun` / `-Offline` は Release.ps1:208-210 で `$SkipUpload = $true` に
    # **auto-promote** される (Codex P2 #137 経緯)。本 gate は DryRun/Offline 経由でも skip path
    # に流れる = 既存 Preflight と完全同期。実 fence の動作確認は本番 publish 経路 (= flag
    # なしで `.\Release.bat -NoPause -Force`) で初発火を verify する流れ。
    if ($SkipUpload) {
        Write-Warn "Bundle 参照リンク定義の検証を skip (-SkipUpload or -DryRun/-Offline 経由 auto-promote、publish しないので URL resolution 不要)"
        # round 4 Low: 本番 publish 時には Fail で停止することを明示、開発者が DryRun 中に link def
        # 追加を忘れ続けて初回 publish 時に「DryRun では通ってたのに publish で Fail」と混乱する
        # path を防ぐ。
        Write-Warn "  → 本番 publish (flag なし Release.bat -NoPause -Force) では本検証が enforce されます。Bundle entry 追加と同時に link def も追加してください"
        return
    }

    # round 6 Low-2: 既存 module-level $ChangelogPath (script 冒頭 paths section、SoT) を参照、
    # local 変数の shadow 排除。
    # round 1 Low-3: Get-Content -Raw は PS 5.1 で BOM 無し UTF-8 を CP932 として読む既知挙動
    # あり。script 冒頭 ($_changelogContent) と同じ ReadAllText で統一して UTF-8 明示 read。
    $changelogContent = [System.IO.File]::ReadAllText($ChangelogPath, [System.Text.Encoding]::UTF8)

    # footer block を切り出してその範囲内のみ match。
    #   line anchor `(?m)^...\s*$` だけでファイル全体に対して match した場合、release notes 内の
    #   fenced code block で `[Bundle v0.5.0]: ...` を例示行として **独立行** で書いた case で
    #   false-positive で素通りする path があった (footer 不在でも check 緑 → dangling Bundle
    #   heading link で release)。
    #
    #   修正履歴:
    #     (1) round 3 Codex P2: `LastIndexOf('-->')` で「ファイル中で最後の HTML comment 閉じ」
    #         を footer block の先頭とみなしていたが、将来 link def の **下** に別の HTML comment
    #         (例: markdownlint directive) が追加された瞬間に footer block が link def 群を含ま
    #         ない範囲に切り出されて normal publish で false "同期忘れ" Fail が起きる脆弱性。
    #     (2) round 5 Codex P2: 明示 sentinel `footer-link-defs-begin` を埋め込み `IndexOf` で
    #         位置取得 → 即 round 5 commit で本文中に sentinel literal を書いてしまい、
    #         `IndexOf` が body 内の最初の出現を拾って footer block が CHANGELOG 99% に再拡大
    #         する **自爆** が発生 (= round 6 Codex P2 + シニア Critical-1 で発覚)。
    #     (3) round 6 で二重防御に再設計 (現在):
    #         - **sentinel を unique 文字列** `GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1` に変更
    #           (ALL CAPS + hyphen + V1 suffix、human writing で偶発出現しない pattern)
    #         - **`LastIndexOf` を採用**: 万一 body 中で sentinel が引用された場合でも末尾の
    #           本物の sentinel を選ぶ。CHANGELOG 構造上「上 = 新エントリ、末尾 = HTML comment
    #           + link def」で本物 sentinel は常にファイル中最後の出現になる前提。
    $FooterSentinel = 'GCTONEPRISM-CHANGELOG-FOOTER-BEGIN-V1'
    $sentinelIdx = $changelogContent.LastIndexOf($FooterSentinel)
    if ($sentinelIdx -lt 0) {
        Fail "CHANGELOG.md に footer marker sentinel '$FooterSentinel' が見つかりません。CHANGELOG 末尾 HTML comment 内に sentinel を追加してください。"
    }
    $footerBlock = $changelogContent.Substring($sentinelIdx + $FooterSentinel.Length)

    # round 3 Low-3: GitHub repo URL は $GitHubRepoSlug 定数 (script 冒頭 SoT) を参照。
    $expectedUrl = "https://github.com/$GitHubRepoSlug/releases/tag/v$Version"
    # 正規表現: `(?m)` (multiline) + `^` (行頭) + `[Bundle v<Version>]: <URL>` + `\s*$` (行末)
    $linePattern = '(?m)^' + [regex]::Escape("[Bundle v$Version]: $expectedUrl") + '\s*$'
    $expectedDefDisplay = "[Bundle v$Version]: $expectedUrl"

    if (-not [regex]::IsMatch($footerBlock, $linePattern)) {
        # round 3 Low-2: backtick escape を削除、PS double-quoted string で意図しない文字消費を排除。
        Write-Host ""
        Write-Host "    CHANGELOG.md 末尾 footer block に Bundle v$Version の参照リンク定義が見つかりません" -ForegroundColor Red
        Write-Host "    (CHANGELOG 末尾 sentinel '$FooterSentinel' 以降の独立行のみ認識、本文中の例示は false-positive 排除)" -ForegroundColor DarkGray
        Write-Host "    以下を CHANGELOG.md 末尾の参照リンク定義ブロックに追加してから再実行してください:" -ForegroundColor Yellow
        Write-Host "      $expectedDefDisplay" -ForegroundColor Cyan
        Write-Host "    追加位置: 既存 [Bundle vX.Y.Z]: 行群の先頭 (降順を維持、CHANGELOG 末尾 HTML comment ブロック直下)" -ForegroundColor Yellow
        Write-Host "    (AGENTS.md 'Release and Versioning' 規約参照)" -ForegroundColor Yellow
        Fail "CHANGELOG 末尾参照リンク定義の同期忘れ"
    }
    Write-Ok "Bundle v$Version の参照リンク定義 OK (presence)"

    # #154 — Bundle 行群の降順整列 enforce
    #   現状の fence は presence のみ check で、AGENTS.md 規約「既存 [Bundle vX.Y.Z]: 行群の先頭
    #   (降順を維持、新しいほど上)」を強制していなかった。例えば `[Bundle v0.1.0]` の下に
    #   `[Bundle v0.3.0]` を書いても通過する状態で、human reader が「最新リリースがどれか」を
    #   直感的に判断できなくなる運用劣化リスクと、規約と fence の non-symmetric (doc-vs-impl
    #   mismatch) があった。
    #
    #   実装方針:
    #     - footer block 内の `^[Bundle vX.Y.Z]: ...` 独立行を順序通りに抽出
    #     - 隣接ペアで **`[version]` (= .NET System.Version、numeric major.minor.build.revision)
    #       cast 比較** → 降順 (上 > 下) でなければ Fail
    #         * 注: 「SemVer 比較」と表現されることがあるが、厳密には `[version]` は SemVer
    #           pre-release semantics (`1.0.0-rc1 < 1.0.0`) をサポートしない numeric ordering。
    #           Bundle が 3-part numeric の限り SemVer 順序と一致するので運用上問題なし。
    #     - pre-release suffix (例: `0.3.0-rc1`) を含む version は `[version]` cast 不可なので
    #       本 fence 範囲外として warning + 該当ペアの順序 check のみ skip (presence check は維持、
    #       現状 Bundle で pre-release 運用なし、将来運用拡張時は SemanticVersion 比較ロジック等で
    #       対応)
    #     - **round 1 Medium-1**: 全ペアが pre-release skip された場合に「OK」を誤って出さない
    #       よう、実比較ペア数と skip ペア数をカウントしてループ後の Write-Ok 文言を 3 分岐
    #     - Bundle 行が 0 件 (presence check で既に Fail) / 1 件 (順序自明) の case は順序
    #       check 自体不要 → return
    $bundleLinePattern = '(?m)^\[Bundle v(\d+\.\d+\.\d+(?:-[a-zA-Z0-9.-]+)?)\]:'
    $bundleMatches = [regex]::Matches($footerBlock, $bundleLinePattern)
    if ($bundleMatches.Count -le 1) {
        # 1 件以下は順序自明 (presence check は通過済)、ordering check は不要
        return
    }

    $bundleVersions = @($bundleMatches | ForEach-Object { $_.Groups[1].Value })
    $comparedCount = 0
    $skippedCount = 0
    for ($i = 0; $i -lt $bundleVersions.Count - 1; $i++) {
        $upper = $bundleVersions[$i]
        $lower = $bundleVersions[$i + 1]
        # pre-release suffix を含むペアは [version] 比較ロジック範囲外、warning で skip
        if ($upper -match '-' -or $lower -match '-') {
            Write-Warn "Bundle version に pre-release suffix を含むペアの順序 check は本 fence 範囲外: '$upper' / '$lower' (該当ペアの ordering のみ skip、presence は PASS 済)"
            $skippedCount++
            continue
        }
        $upperVer = [version]$upper
        $lowerVer = [version]$lower
        $comparedCount++

        # round 1 Low-2: 等値 (重複 link def) と「下が大きい」(ordering 違反) を分岐表示。
        # round 1 Low-4: 違反位置表示を 1-indexed (human 視点) に統一。
        if ($upperVer -eq $lowerVer) {
            Write-Host ""
            Write-Host "    CHANGELOG.md 末尾 footer block に同じ version の Bundle 行が重複しています" -ForegroundColor Red
            Write-Host "    位置 $($i + 1) と位置 $($i + 2): 両方とも [Bundle v$upper]:" -ForegroundColor Red
            Write-Host "    修正: どちらか片方の link def を削除してください" -ForegroundColor Yellow
            Write-Host "    全 Bundle 行 (現状の並び順):" -ForegroundColor Yellow
            for ($j = 0; $j -lt $bundleVersions.Count; $j++) {
                $marker = if ($j -eq $i -or $j -eq $i + 1) { ' ← 重複箇所' } else { '' }
                Write-Host "      [$($j + 1)] [Bundle v$($bundleVersions[$j])]:$marker" -ForegroundColor DarkGray
            }
            Fail "CHANGELOG 末尾 Bundle 行群の重複 link def"
        }
        elseif ($upperVer -lt $lowerVer) {
            Write-Host ""
            Write-Host "    CHANGELOG.md 末尾 footer block の Bundle 行群が降順に並んでいません" -ForegroundColor Red
            Write-Host "    位置 $($i + 1) (上): [Bundle v$upper]:" -ForegroundColor Red
            Write-Host "    位置 $($i + 2) (下): [Bundle v$lower]: ← 下にあるが version が大きい (ordering 違反)" -ForegroundColor Red
            Write-Host "    修正: 上下を入れ替え (新しい version が上、AGENTS.md 規約: 既存 [Bundle vX.Y.Z]: 行群の先頭に追加、降順を維持)" -ForegroundColor Yellow
            Write-Host "    全 Bundle 行 (現状の並び順):" -ForegroundColor Yellow
            for ($j = 0; $j -lt $bundleVersions.Count; $j++) {
                $marker = if ($j -eq $i -or $j -eq $i + 1) { ' ← 違反箇所' } else { '' }
                Write-Host "      [$($j + 1)] [Bundle v$($bundleVersions[$j])]:$marker" -ForegroundColor DarkGray
            }
            Fail "CHANGELOG 末尾 Bundle 行群の降順違反"
        }
    }

    # round 1 Medium-1: 実比較ペア数と skip ペア数で Write-Ok 文言を 3 分岐
    if ($comparedCount -eq 0 -and $skippedCount -gt 0) {
        # 全ペアが pre-release skip = 実比較ゼロ、「OK」と倒さず warning に明示
        Write-Warn "Bundle 行群の順序 check: 全 $skippedCount ペアが pre-release suffix のため skip (実比較なし、presence のみ PASS)"
    } elseif ($skippedCount -gt 0) {
        Write-Ok "Bundle 行群の降順整列 OK ($($bundleVersions.Count) 件中 $comparedCount ペア比較、$skippedCount ペア pre-release skip)"
    } else {
        Write-Ok "Bundle 行群の降順整列 OK ($($bundleVersions.Count) 件)"
    }
}

# ============================================================================
# Phase 1: Component versions 読み取り
# ============================================================================

function Assert-LauncherVersion {
    # (#281) Launcher 版数の SoT は project.godot の [application] config/version="X.Y.Z"。
    # `config/version`(スラッシュ) を読む (line 9 の `config_version`(アンダースコア、Godot ファイル形式版) と別物)。
    # ※同一パターンを Manager/Services/VersionInventory.cs `ConfigVersionRegex` も持つ。format 変更時は両方同期 (SPEC §3.7.8)。
    $projectGodot = Join-Path $LauncherDir 'project.godot'
    if (-not (Test-Path $projectGodot)) {
        Fail "project.godot が見つかりません: $projectGodot"
    }
    $content = Get-Content $projectGodot -Raw
    $m = [regex]::Match($content, '(?m)^\s*config/version\s*=\s*"(\d+\.\d+\.\d+)"\s*$')
    if (-not $m.Success) {
        Fail "project.godot から config/version (X.Y.Z) を読み取れませんでした"
    }
    return $m.Groups[1].Value
}

function Assert-ManagerVersion {
    $assemblyInfo = Join-Path $ManagerDir 'Properties\AssemblyInfo.cs'
    if (-not (Test-Path $assemblyInfo)) {
        Fail "AssemblyInfo.cs が見つかりません: $assemblyInfo"
    }
    $content = Get-Content $assemblyInfo -Raw
    $m = [regex]::Match($content, 'AssemblyVersion\("(\d+\.\d+\.\d+)\.\d+"\)')
    if (-not $m.Success) {
        Fail "AssemblyInfo.cs から AssemblyVersion を読み取れませんでした"
    }
    return $m.Groups[1].Value
}

function Assert-LauncherAgentVersion {
    $assemblyInfo = Join-Path $RepoRoot 'Companions\LauncherAgent\Properties\AssemblyInfo.cs'
    if (-not (Test-Path $assemblyInfo)) {
        Fail "LauncherAgent AssemblyInfo.cs が見つかりません: $assemblyInfo"
    }
    $content = Get-Content $assemblyInfo -Raw
    $m = [regex]::Match($content, 'AssemblyVersion\("(\d+\.\d+\.\d+)\.\d+"\)')
    if (-not $m.Success) {
        Fail "LauncherAgent AssemblyInfo.cs から AssemblyVersion を読み取れませんでした"
    }
    return $m.Groups[1].Value
}

function Assert-ComponentVersions {
    Write-Step "コンポーネント version を読み取り"
    $script:LauncherVersion = Assert-LauncherVersion
    $script:ManagerVersion = Assert-ManagerVersion
    $script:LauncherAgentVersion = Assert-LauncherAgentVersion
    Write-Ok "Launcher:      v$script:LauncherVersion"
    Write-Ok "Manager:       v$script:ManagerVersion"
    Write-Ok "LauncherAgent: v$script:LauncherAgentVersion"
}

# ============================================================================
# Phase 2: export_presets.cfg を Launcher version で同期
# (#281) project.godot config/version は SoT 自身なので同期対象から外す。
#         派生先である export_presets.cfg の file_version / product_version のみ stamp する。
# ============================================================================

function Write-FileUtf8NoBom {
    param([string]$Path, [string]$Content)
    # Godot ConfigFile / project.godot は BOM を識別子として解釈してパースエラーを起こすため
    # UTF-8 BOM なしで書き出す
    [System.IO.File]::WriteAllText($Path, $Content, $script:Utf8NoBomEncoding)
}

function Set-ExportPresetVersions {
    Write-Step "派生バージョン情報を同期 (Launcher v$script:LauncherVersion 基準)"

    $launcherVer = $script:LauncherVersion
    $fourPart = "$launcherVer.0"

    # (#281) project.godot config/version は Launcher 版数の SoT 自身なので、ここでは同期しない
    # (Assert-LauncherVersion がそこから $script:LauncherVersion を読んでいる)。派生先である
    # export_presets.cfg の file_version / product_version のみ SoT 基準で stamp する。

    # export_presets.cfg: application/file_version & product_version
    $exportPresets = Join-Path $LauncherDir 'export_presets.cfg'
    $content = [System.IO.File]::ReadAllText($exportPresets, [System.Text.Encoding]::UTF8)
    $new = [regex]::Replace($content, '(application/file_version=")[^"]*(")', "`${1}$fourPart`${2}")
    $new = [regex]::Replace($new,     '(application/product_version=")[^"]*(")', "`${1}$fourPart`${2}")
    if ($new -ne $content) {
        Write-FileUtf8NoBom -Path $exportPresets -Content $new
        Write-Ok "export_presets.cfg file_version/product_version → $fourPart"
    } else {
        Write-Info "export_presets.cfg は既に $fourPart"
    }
}

# ============================================================================
# Phase 3: Staging
# ============================================================================

function Clear-Staging {
    Write-Step "Staging エリアを初期化: $StagingDir"
    if (Test-Path $StagingDir) {
        Remove-Item -Recurse -Force $StagingDir
        Write-Info "既存 staging を削除"
    }
    New-Item -ItemType Directory -Path $StagingDir | Out-Null
    New-Item -ItemType Directory -Path $FilesDir | Out-Null
    Write-Ok "Staging 準備完了"
}

# ============================================================================
# Phase 4: Build Launcher
# ============================================================================

function Invoke-ExternalProcess {
    # Process.Start + WaitForExit で明示的に完了を待つ。
    # `&` (call operator) は大量の stdout/stderr で非同期 return することがあり、
    # Start-Process -ArgumentList は配列要素にスペースを含むと argument 分割する問題があるため、
    # ProcessStartInfo.Arguments を自前で quoting する形を採用。
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )
    # スペース・特殊文字を含む引数はダブルクォートで囲む
    $quoted = $Arguments | ForEach-Object {
        if ($_ -match '\s|"') {
            '"' + ($_ -replace '"', '\"') + '"'
        } else {
            $_
        }
    }
    $cmdLine = $quoted -join ' '

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = $cmdLine
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $false  # コンソールに直接出力
    $psi.RedirectStandardError = $false

    $proc = $null
    try {
        # Process.Start 失敗 (file not found / 権限不足) を Invoke-NativeWithCapture
        # と同じ pattern で何を起動しようとしたかを含むメッセージで rethrow、
        # 両 helper の例外メッセージ粒度を対称化
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
        } catch {
            throw "Invoke-ExternalProcess: '$FilePath' の起動に失敗しました: $($_.Exception.Message)"
        }
        $proc.WaitForExit()
        $exitCode = $proc.ExitCode
    } finally {
        if ($null -ne $proc) { $proc.Dispose() }
        # Invoke-ExternalProcess 経由の子プロセス (Godot CLI / msbuild / nuget) が
        # コンソール encoding を OEM 系に戻して去ると、後続 Write-Host で日本語が
        # doubled rendering される PS 5.1 バグの予防的再ピン留め (script 冒頭の
        # pin と二重防御)。
        # 非 console host (CI / headless 等) で console API が IOException を投げる
        # ケースを try/catch で吸収 — finally は外部ツール呼び出しの度に走るため
        # ガードなしだと release flow が abort する。
        # 注: $OutputEncoding (PS variable、pipeline → native command 送信側) は
        # 子プロセスから変更不可なので再ピン留め不要、script 冒頭の代入が継続有効
        try {
            [Console]::OutputEncoding = $script:Utf8NoBomEncoding
        } catch {
            # non-console host では再ピン留め不要 (そもそも doubled rendering は
            # 対話端末でしか起きないため、CI 等では skip OK)
        }
    }
    return $exitCode
}

function Build-Launcher {
    Write-Step "Launcher を Godot CLI でエクスポート"

    $outDir = Join-Path $FilesDir 'Launcher'
    New-Item -ItemType Directory -Path $outDir | Out-Null
    $outExe = Join-Path $outDir 'TonePrism_Launcher.exe'

    Write-Info "出力先: $outExe"
    Write-Info "Godot: $script:ResolvedGodot"

    $exitCode = Invoke-ExternalProcess -FilePath $script:ResolvedGodot -Arguments @(
        '--headless',
        '--path', $LauncherDir,
        '--export-release', 'Windows Desktop',
        $outExe
    )
    if ($exitCode -ne 0) {
        Fail "Godot エクスポートに失敗しました (exit code: $exitCode)"
    }
    if (-not (Test-Path $outExe)) {
        Fail "Godot エクスポート完了したが exe が見つかりません: $outExe"
    }
    Write-Ok "Launcher exe 生成完了"

    Write-Info "出力ファイル一覧:"
    Get-ChildItem $outDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($outDir.Length + 1)
        Write-Host "        $rel ($($_.Length) bytes)" -ForegroundColor DarkGray
    }
}

function Assert-ExportedLauncherVersion {
    # (#283) エクスポート済み Launcher exe の FileVersion が SoT (project.godot config/version) と一致するか検証。
    # Manager UI は prod でこの FileVersion から Launcher 版数を読む (VersionInventory.ReadLauncherVersion)。
    # 版数 stamp は config/version → Set-ExportPresetVersions → export_presets.cfg → Godot/rcedit → exe の
    # 多段パイプライン経由のため、どこか一手が抜けると exe が古い/欠落版数を焼き、Manager が silent に
    # 嘘版数を表示する (#283 で受容した trade-off の安全網)。zip/upload より前にここで hard fail させ、
    # 誤版数の publish を防ぐ。Build-Launcher の後に呼ぶこと。
    Write-Step "エクスポート exe の版数を検証 (SoT 一致)"
    $exe = Join-Path (Join-Path $FilesDir 'Launcher') 'TonePrism_Launcher.exe'
    if (-not (Test-Path $exe)) {
        Fail "検証対象の exe が見つかりません: $exe (Build-Launcher の後に呼ぶこと)"
    }
    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe).FileVersion
    $parsed = $null
    if (-not [version]::TryParse($fileVersion, [ref]$parsed)) {
        Fail "exe の FileVersion を parse できません ('$fileVersion'、path=$exe)。export_presets.cfg の application/file_version / modify_resources (rcedit stamp) を確認。"
    }
    # exe は 4 part (X.Y.Z.0)、SoT は 3 part (X.Y.Z)。Major.Minor.Build で比較。
    $exe3 = "$($parsed.Major).$($parsed.Minor).$($parsed.Build)"
    if ($exe3 -ne $script:LauncherVersion) {
        Fail ("エクスポート exe の FileVersion ($fileVersion → $exe3) が SoT ($script:LauncherVersion) と不一致。" +
            "Set-ExportPresetVersions の stamp が未反映の疑い (export_presets.cfg / rcedit)。" +
            "Manager は prod でこの exe から版数を読むため、誤版数の publish を防ぐべく中止。")
    }
    Write-Ok "exe FileVersion = $fileVersion (SoT $script:LauncherVersion と一致)"
}

function Assert-PublishedManagerVersion {
    # (#258 PR4) net10 single-file 化で Manager exe の Win32 FileVersion は dotnet publish
    # (apphost / singlefilehost の version リソース stamp) 由来になった。net48 時代は exe = コンパイル済
    # アセンブリで FileVersion = AssemblyFileVersion が常に一致したため検証不要だったが、net10 では SDK の
    # stamp が csproj 設定 (GenerateAssemblyInfo=false / Version プロパティ有無) や将来の SDK 挙動変化で
    # SoT から drift しうる。Manager UI は reflection で版数を読むため UI 表示自体は無事だが、Explorer
    # プロパティ / リリース時版数ゲートが嘘版数になる #283 級リスク。Launcher の Assert-ExportedLauncherVersion
    # と対称に、staged exe の FileVersion を SoT と突き合わせ、zip/publish より前に hard fail する。
    # Build-Manager の後に呼ぶこと。
    # 注 (レビュー B-1): 比較は厳密には「exe の Win32 FileVersion (apphost が managed DLL からコピー＝**AssemblyFileVersion**
    # 由来)」↔「$script:ManagerVersion (Assert-ManagerVersion が **AssemblyVersion** 属性を読んだ値＝SoT)」。AssemblyInfo.cs が
    # 両属性を同値に保つ前提で一致し、両者が drift した場合も検出できる有用な不変条件になる。AssemblyFileVersion ≠
    # AssemblyVersion を意図的に運用するなら本 gate は誤 fail するので、その時は比較対象を AssemblyFileVersion に寄せること。
    # 注: 現状の net10 SDK では stamp は正しく 0.27.9.0 を焼く (PR4 で実測確認済) が、本ゲートは「今正しい」を
    # 「以後も機械強制」に格上げする defense-in-depth (stamp 経路が将来壊れても誤版数 publish を防ぐ)。
    Write-Step "Manager exe の版数を検証 (SoT 一致)"
    $exe = Join-Path (Join-Path $FilesDir 'Manager') 'TonePrism_Manager.exe'
    if (-not (Test-Path $exe)) {
        Fail "検証対象の exe が見つかりません: $exe (Build-Manager の後に呼ぶこと)"
    }
    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe).FileVersion
    $parsed = $null
    if (-not [version]::TryParse($fileVersion, [ref]$parsed)) {
        Fail "Manager exe の FileVersion を parse できません ('$fileVersion'、path=$exe)。AssemblyInfo.cs の AssemblyFileVersion / csproj の版数 stamp を確認。"
    }
    # exe は 4 part (X.Y.Z.0)、SoT は 3 part (X.Y.Z)。Major.Minor.Build で比較。
    $exe3 = "$($parsed.Major).$($parsed.Minor).$($parsed.Build)"
    if ($exe3 -ne $script:ManagerVersion) {
        Fail ("Manager exe の FileVersion ($fileVersion → $exe3) が SoT ($script:ManagerVersion) と不一致。" +
            "dotnet publish の版数 stamp が未反映の疑い (AssemblyInfo.cs AssemblyFileVersion / csproj Version プロパティ)。" +
            "Manager は prod でこの exe (Explorer プロパティ) と reflection 版数の一致を期待するため、誤版数の publish を防ぐべく中止。")
    }
    Write-Ok "Manager exe FileVersion = $fileVersion (SoT $script:ManagerVersion と一致)"
}

function Assert-ManagerSingleFile {
    # (#258 PR4 レビュー D-1) single-file 配布の核心不変条件「Manager = exe 1 個」を機械強制する。
    # Assert-ExpectedFiles は manifest 記載ファイルの **presence のみ** 検証し余剰を見ない (manifest forward-compat の
    # 設計上、他コンポーネントの余剰ファイルは許容せねばならない＝余剰検出を入れると旧 Manager が新 zip を reject する
    # 後方互換問題が再燃する) ため、Manager 固有のこの不変条件は専用にここで守る。将来 SDK / System.Data.SQLite.Core の
    # 挙動変化で sidecar (loose native dll / createdump.exe / *.json 等) が publish 出力に混ざり、manifest 非記載のまま
    # zip 同梱される silent drift を upload 前に fail-fast する。Build-Manager の後に呼ぶこと (staging の Manager dir =
    # 出荷物そのもの。pdb は Build-Manager のコピーで除外済なので exe 1 個が期待値)。
    Write-Step "Manager が single-file (exe 1 個) であることを検証"
    $managerDir = Join-Path $FilesDir 'Manager'
    if (-not (Test-Path $managerDir)) {
        Fail "検証対象の Manager staging dir が見つかりません: $managerDir (Build-Manager の後に呼ぶこと)"
    }
    $files = @(Get-ChildItem $managerDir -Recurse -File)
    $unexpected = @($files | Where-Object { $_.Name -ne 'TonePrism_Manager.exe' })
    if ($unexpected.Count -gt 0) {
        $names = ($unexpected | ForEach-Object { $_.FullName.Substring($managerDir.Length + 1) }) -join ', '
        Fail @"
Manager staging に想定外のファイルがあります (single-file = TonePrism_Manager.exe 1 個のはず): $names
single-file 不変条件が崩れています。csproj の PublishSingleFile / IncludeNativeLibrariesForSelfExtract、
または System.Data.SQLite.Core / SDK の挙動変化で sidecar が吐かれていないか確認してください。
expected-files (manifest) は presence のみ検証で余剰を検出しないため、ここで fail-fast します。
"@
    }
    Write-Ok "Manager staging = TonePrism_Manager.exe 1 個 (single-file 不変条件 OK)"
}

# ============================================================================
# Phase 5: Build Manager
# ============================================================================

function Build-Manager {
    Write-Step "Manager を dotnet publish で Release ビルド (net10 self-contained single-file)"

    $csproj = Join-Path $ManagerDir 'TonePrism_Manager.csproj'
    $binRelease = Join-Path $ManagerDir 'bin\Release'
    $publishDir = Join-Path $binRelease 'publish'

    # (#258 PR4) net10 化に伴い msbuild /restore (framework-dependent build) → dotnet publish (self-contained
    # single-file) へ。net10 は OS 同梱でないため、ランタイムを exe に同梱して「解凍 → すぐ動く・オフライン安全・
    # ランタイム導入不要」の現行配布モデルを維持する。
    #   - -r win-x64 --self-contained true : net10 ランタイム同梱 (各 PC に .NET 導入不要)
    #   - PublishSingleFile=true            : 単一 exe (TonePrism_Manager.exe 1 個)。.exe.config / System.Data.SQLite.dll /
    #                                        x64,x86 の SQLite.Interop.dll は全て exe に内包 (bundle の Manager 構成が exe 1 個に簡素化)
    #   - IncludeNativeLibrariesForSelfExtract=true : native (SQLite.Interop.dll) も同梱、初回起動で %TEMP%/.net へ
    #                                        self-extract して load (PR4 で実機 smoke 確認済: DB round-trip 成立)
    # ※ dev build (dotnet build / test) は single-file にしない (csproj に PublishSingleFile を入れず publish 引数で渡す)。
    # ※ Manager / LauncherAgent は dotnet (net10)、Updater は msbuild (net48) のまま (番人)。前提: dotnet (net10 SDK) が PATH。

    # bin/Release/ を事前に削除 (前回ビルドの runtime ゴミ = 開発者が Manager を直接起動した時に発生する
    # db / logs / backups 等を release zip に紛れ込ませないため)
    if (Test-Path $binRelease) {
        Write-Info "bin/Release/ を削除して clean build"
        Remove-Item -Recurse -Force $binRelease
    }

    Write-Info "dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true"
    $exitCode = Invoke-ExternalProcess -FilePath $script:ResolvedDotnet -Arguments @(
        'publish', $csproj,
        '-c', 'Release',
        '-r', 'win-x64',
        '--self-contained', 'true',
        '-p:PublishSingleFile=true',
        '-p:IncludeNativeLibrariesForSelfExtract=true',
        '-o', $publishDir,
        '--nologo',
        '-v', 'minimal'
    )
    if ($exitCode -ne 0) {
        Fail "dotnet publish に失敗しました (exit code: $exitCode)"
    }
    Write-Ok "dotnet publish 完了"

    # publish 出力 (exe 1 個 + .pdb) から staging へコピー (*.pdb 除外)
    $outDir = Join-Path $FilesDir 'Manager'
    New-Item -ItemType Directory -Path $outDir | Out-Null
    if (-not (Test-Path $publishDir)) {
        Fail "Manager publish 出力が見つかりません: $publishDir"
    }

    Get-ChildItem $publishDir -Recurse | Where-Object {
        -not $_.PSIsContainer -and $_.Extension -ne '.pdb'
    } | ForEach-Object {
        $rel = $_.FullName.Substring($publishDir.Length + 1)
        $dest = Join-Path $outDir $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $_.FullName $dest
    }
    Write-Ok "Manager 成果物コピー完了"

    Write-Info "出力ファイル一覧:"
    Get-ChildItem $outDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($outDir.Length + 1)
        Write-Host "        $rel ($($_.Length) bytes)" -ForegroundColor DarkGray
    }
}

# ============================================================================
# Phase 5.5: Companions/Updater を msbuild で Release ビルド (#108 Phase 3)
# ============================================================================
# SPEC §3.7.4: Manager 置換 + 再起動の最小 CLI。.NET Framework 4.8 で SQLite / WindowsAPICodePack
# 等の外部依存を持たない単純な Console app なので、Build-Manager の dotnet publish (net10
# self-contained single-file) のような重い publish 不要。net48 を msbuild 直叩きでよい。
function Assert-UpdaterBitness {
    param([string]$ExePath)

    # (#440) Updater が 32bit で焼かれていないことを機械強制する。
    #
    # `PlatformTarget=AnyCPU` の .NET Framework exe は `Prefer32Bit` の既定が **true** で 32bit として
    # 起動する。Manager は Bundle v0.9.0 (#258) 以降 .NET 10 の 64bit 単一ファイルなので、32bit の
    # Updater からは Manager プロセスの MainModule を読めず、ProcessWaiter が「既に終了済み」と誤判定
    # して待機を skip → 起動中のまま Manager dir を rename → 失敗 → ロールバック、となる。
    # **これでアプリ内アップデートが 2 リリース分ずっと壊れていた (#440)。**
    #
    # csproj には `<Prefer32Bit>false</Prefer32Bit>` があるが、Visual Studio が per-configuration の
    # PropertyGroup に `true` を書き戻すと**後勝ちで無言に revert する**。SPEC §3.7.6.1 が「必須」と
    # 書いているだけでは守られないので、他の版数 stamp 系 (Assert-PublishedManagerVersion /
    # Assert-ExportedLauncherVersion) と同じく公開前に hard fail させる。
    #
    # 判定に PE ヘッダの machine は使えない (AnyCPU は常に I386/PE32)。COR フラグを見る必要があるので
    # `Assembly.GetPEKind` を使う。ReflectionOnlyLoadFrom はコードを実行しない。
    #
    # **前提が 2 つある (レビュー Low-3)**:
    #  (1) `ReflectionOnlyLoadFrom` は **Windows PowerShell 5.1 (.NET Framework) 専用**。PowerShell 7+
    #      (.NET Core) では PlatformNotSupportedException になる。Release.bat が 5.1 (`powershell.exe`) で
    #      起動する前提に依存しているので、7+ へ移す場合はここを `System.Reflection.Metadata` の
    #      PEReader (CorFlags を直接読む) に書き換えること。catch は Fail に落ちるので**黙って通ることは無い**。
    #  (2) 読み込んだ assembly は**プロセスが終わるまでファイルを掴む**。以降この exe を
    #      削除・上書きする step があると失敗する。現状 Build-Updater は先頭で bin/Release を消してから
    #      build するので、1 プロセス 1 回の実行では衝突しない (staging へのコピーは読み取りのみ)。
    if (-not (Test-Path $ExePath)) {
        Fail "Updater の bitness を検証できません (exe が見つかりません): $ExePath"
    }
    try {
        $asm = [System.Reflection.Assembly]::ReflectionOnlyLoadFrom($ExePath)
        $pek = [System.Reflection.PortableExecutableKinds]::ILOnly
        $mach = [System.Reflection.ImageFileMachine]::I386
        $asm.ManifestModule.GetPEKind([ref]$pek, [ref]$mach)
    } catch {
        Fail "Updater の PEKind を読めませんでした: $ExePath`n        $($_.Exception.Message)"
    }
    $kindText = $pek.ToString()
    if ($kindText -match 'Preferred32Bit' -or $kindText -match 'Required32Bit') {
        Fail @"
Updater が 32bit として焼かれています (PEKind: $kindText)。
        32bit の Updater は 64bit の Manager プロセスを識別できず、アプリ内アップデートが
        「Manager だけ更新されない」形で静かに失敗します (#440)。
        Companions/Updater/TonePrism_Updater.csproj に <Prefer32Bit>false</Prefer32Bit> があるか、
        per-configuration の PropertyGroup で true に上書きされていないかを確認してください。
"@
    }
    Write-Ok "Updater bitness OK (PEKind: $kindText = 32bit 指定なし)"
}

function Build-Updater {
    Write-Step "Updater を msbuild で Release ビルド"

    $updaterDir = Join-Path $RepoRoot 'Companions\Updater'
    $csproj = Join-Path $updaterDir 'TonePrism_Updater.csproj'
    $binRelease = Join-Path $updaterDir 'bin\Release'

    if (-not (Test-Path $csproj)) {
        Fail "TonePrism_Updater.csproj が見つかりません: $csproj"
    }

    # 既存 bin/Release/ を消して clean build (Build-Manager と同じ思想)
    if (Test-Path $binRelease) {
        Write-Info "bin/Release/ を削除して clean build"
        Remove-Item -Recurse -Force $binRelease
    }

    Write-Info "msbuild /p:Configuration=Release"
    $exitCode = Invoke-ExternalProcess -FilePath $script:ResolvedMsBuild -Arguments @(
        $csproj,
        '/p:Configuration=Release',
        '/verbosity:minimal',
        '/nologo'
    )
    if ($exitCode -ne 0) {
        Fail "Updater の msbuild に失敗しました (exit code: $exitCode)"
    }
    Write-Ok "msbuild 完了"

    # bin/Release/ から staging へコピー (*.pdb 除外)
    # 配布構造は SPEC §3.7.1 / §2.4 に従い `<staging>/files/Companions/Updater/` 配下に配置
    #
    # シニアレビュー round 2 L5: build 成果物 dir の存在 check を先に行ってから staging dir を
    # 作る順序に。msbuild が exit 0 で抜けたが成果物 dir 生成失敗の pathological case で
    # 空 staging dir 残骸を作らない (最終的に Clear-Staging で消えるが、check 順としては
    # 「check first, mutate second」が clean)。
    if (-not (Test-Path $binRelease)) {
        Fail "Updater ビルド出力が見つかりません: $binRelease"
    }
    # シニアレビュー round 4 L-3: dir 存在 check に加え、`.exe` 1 件以上の存在も check。
    # msbuild が exit 0 で抜けたが成果物 dir が空 (pathological case、msbuild target が空 sln を
    # 受け取った等) の場合、`Get-ChildItem` 0 件で copy ループが silent に 0 回回り、
    # `Write-Ok "Updater 成果物コピー完了"` を空コピーで通過する path があった。最終的に
    # Assert-ExpectedFiles で fail するが、Build-Updater レベルで早期 fail させた方が原因切り分け
    # しやすい (msbuild step が悪いのか staging copy step が悪いのかを切り分け)。
    $exeCount = (Get-ChildItem $binRelease -Recurse -File -Filter '*.exe' -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($exeCount -lt 1) {
        Fail "Updater ビルド出力に .exe が見つかりません ($binRelease 内): msbuild は exit 0 だが成果物が生成されていない可能性"
    }
    # シニアレビュー round 5 L-2: 任意の .exe 1 件ではなく、**特定の exe 名**
    # (`TonePrism_Updater.exe`) の存在も check。csproj の AssemblyName を将来誰かが変更して
    # 別名の .exe を生成しても round 4 L-3 だけだと build step green (任意の .exe で pass)、後段
    # Assert-ExpectedFiles で初めて検出。特定名 check で「msbuild 成功 + 期待 exe 名生成」まで
    # Build-Updater レベルで担保する。csproj 仕様変更時の早期検出。
    $expectedExe = Join-Path $binRelease 'TonePrism_Updater.exe'
    if (-not (Test-Path $expectedExe)) {
        Fail "Updater ビルド出力に TonePrism_Updater.exe が見つかりません: csproj の AssemblyName が変更された可能性 (期待 path: $expectedExe)"
    }

    # (#440) 32bit で焼かれていないことを公開前に hard fail で確認する。
    # **上の存在 check より後に置く**: Assert-UpdaterBitness 自身も Test-Path で落ちるが、その文言は
    # 「exe が見つかりません」止まりで、dir 不在 / AssemblyName 変更といった原因を言い当てられない
    # (レビュー Low-2)。診断の細かい方を先に通してから bitness を見る。
    Assert-UpdaterBitness -ExePath $expectedExe
    $outDir = Join-Path $FilesDir 'Companions\Updater'
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    Get-ChildItem $binRelease -Recurse | Where-Object {
        -not $_.PSIsContainer -and $_.Extension -ne '.pdb'
    } | ForEach-Object {
        $rel = $_.FullName.Substring($binRelease.Length + 1)
        $dest = Join-Path $outDir $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $_.FullName $dest
    }
    Write-Ok "Updater 成果物コピー完了"

    Write-Info "出力ファイル一覧:"
    Get-ChildItem $outDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($outDir.Length + 1)
        Write-Host "        $rel ($($_.Length) bytes)" -ForegroundColor DarkGray
    }
}

function Build-LauncherAgent {
    Write-Step "LauncherAgent を dotnet publish で Release ビルド (net10 self-contained single-file)"

    # (#258 PR4.x) net48 msbuild → net10 dotnet publish (self-contained single-file)。配布形態を Manager と
    # 揃える (net10 ランタイム同梱・解凍即起動・ランタイム導入不要)。LauncherAgent は Launcher 補助の常駐
    # エージェント (probe/sensor/focus 統合、旧 WindowProbe、SPEC §2.4 / #101 / #216 / #30)。依存ゼロ・app native
    # lib 無し (純 Win32 P/Invoke = OS DLL) のため Manager の SQLite native 同梱は無いが、PublishSingleFile +
    # IncludeNativeLibrariesForSelfExtract で net10 ランタイム native も含め exe 1 個に集約する。
    # ※ Updater は net48 msbuild のまま (番人・自己更新の最後の砦)。前提: dotnet (net10 SDK) が PATH (Resolve-Dotnet 済)。
    $companionDir = Join-Path $RepoRoot 'Companions\LauncherAgent'
    $csproj = Join-Path $companionDir 'TonePrism_LauncherAgent.csproj'
    $binRelease = Join-Path $companionDir 'bin\Release'
    $publishDir = Join-Path $binRelease 'publish'

    if (-not (Test-Path $csproj)) {
        Fail "TonePrism_LauncherAgent.csproj が見つかりません: $csproj"
    }

    if (Test-Path $binRelease) {
        Write-Info "bin/Release/ を削除して clean build"
        Remove-Item -Recurse -Force $binRelease
    }

    Write-Info "dotnet publish -r win-x64 --self-contained -p:PublishSingleFile=true"
    $exitCode = Invoke-ExternalProcess -FilePath $script:ResolvedDotnet -Arguments @(
        'publish', $csproj,
        '-c', 'Release',
        '-r', 'win-x64',
        '--self-contained', 'true',
        '-p:PublishSingleFile=true',
        '-p:IncludeNativeLibrariesForSelfExtract=true',
        '-o', $publishDir,
        '--nologo',
        '-v', 'minimal'
    )
    if ($exitCode -ne 0) {
        Fail "LauncherAgent の dotnet publish に失敗しました (exit code: $exitCode)"
    }
    Write-Ok "dotnet publish 完了"

    if (-not (Test-Path $publishDir)) {
        Fail "LauncherAgent publish 出力が見つかりません: $publishDir"
    }
    $expectedExe = Join-Path $publishDir 'TonePrism_LauncherAgent.exe'
    if (-not (Test-Path $expectedExe)) {
        Fail "LauncherAgent publish 出力に TonePrism_LauncherAgent.exe が見つかりません: csproj の AssemblyName が変更された可能性 (期待 path: $expectedExe)"
    }
    $outDir = Join-Path $FilesDir 'Companions\LauncherAgent'
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    # publish 出力 (exe 1 個 + .pdb) から staging へコピー (*.pdb 除外)
    Get-ChildItem $publishDir -Recurse | Where-Object {
        -not $_.PSIsContainer -and $_.Extension -ne '.pdb'
    } | ForEach-Object {
        $rel = $_.FullName.Substring($publishDir.Length + 1)
        $dest = Join-Path $outDir $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item $_.FullName $dest
    }
    Write-Ok "LauncherAgent 成果物コピー完了"

    Write-Info "出力ファイル一覧:"
    Get-ChildItem $outDir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($outDir.Length + 1)
        Write-Host "        $rel ($($_.Length) bytes)" -ForegroundColor DarkGray
    }
}

function Assert-PublishedLauncherAgentVersion {
    # (#258 PR4.x レビュー) net10 single-file 化で LauncherAgent exe の Win32 FileVersion も Manager と同様
    # dotnet publish の apphost stamp (AssemblyFileVersion 由来) になった。net48 時代はコンパイル済アセンブリで
    # 自明に SoT 一致だったため検証不要だったが、net10 では stamp 経路が将来の SDK 挙動変化で drift しうる
    # (#283 と同根)。LauncherAgent は現状 Manager 版数タブ未掲載 (#310) だが、stale stamp の実害 =「誤版数を
    # 焼いた exe を zip 同梱」は表示の有無と無関係に起きるため、Assert-PublishedManagerVersion と対称に
    # defense-in-depth で exe FileVersion ↔ SoT を upload 前に hard fail させる (SPEC §3.7.8: 判定軸は stamp
    # パイプラインの有無で、表示有無ではない)。Build-LauncherAgent の後に呼ぶこと。
    # 注 (Assert-PublishedManagerVersion と対称): 比較は exe の FileVersion (=AssemblyFileVersion 由来) ↔
    # $script:LauncherAgentVersion (=Assert-LauncherAgentVersion が AssemblyVersion 属性を読んだ値=SoT)。
    # AssemblyInfo.cs が両属性を同値に保つ前提で一致し、両者 drift も検出できる。意図的に AssemblyFileVersion ≠
    # AssemblyVersion にする運用なら本 gate は誤 fail するので、その時は比較対象を AssemblyFileVersion に寄せること。
    Write-Step "LauncherAgent exe の版数を検証 (SoT 一致)"
    $exe = Join-Path (Join-Path $FilesDir 'Companions\LauncherAgent') 'TonePrism_LauncherAgent.exe'
    if (-not (Test-Path $exe)) {
        Fail "検証対象の exe が見つかりません: $exe (Build-LauncherAgent の後に呼ぶこと)"
    }
    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe).FileVersion
    $parsed = $null
    if (-not [version]::TryParse($fileVersion, [ref]$parsed)) {
        Fail "LauncherAgent exe の FileVersion を parse できません ('$fileVersion'、path=$exe)。AssemblyInfo.cs の AssemblyFileVersion を確認。"
    }
    # exe は 4 part (X.Y.Z.0)、SoT は 3 part (X.Y.Z)。Major.Minor.Build で比較。
    $exe3 = "$($parsed.Major).$($parsed.Minor).$($parsed.Build)"
    if ($exe3 -ne $script:LauncherAgentVersion) {
        Fail ("LauncherAgent exe の FileVersion ($fileVersion → $exe3) が SoT ($script:LauncherAgentVersion) と不一致。" +
            "dotnet publish の版数 stamp が未反映の疑い (AssemblyInfo.cs AssemblyFileVersion)。誤版数の publish を防ぐべく中止。")
    }
    Write-Ok "LauncherAgent exe FileVersion = $fileVersion (SoT $script:LauncherAgentVersion と一致)"
}

function Assert-LauncherAgentSingleFile {
    # (#258 PR4.x レビュー) LauncherAgent も Manager と同一の self-contained single-file publish
    # (PublishSingleFile + IncludeNativeLibrariesForSelfExtract) を使うため、Assert-ManagerSingleFile と
    # 対称に「LauncherAgent = exe 1 個」を機械強制する。Assert-ExpectedFiles は manifest 記載ファイルの
    # presence のみ検証で余剰を見ない (manifest forward-compat の設計上そうなっている) ため、SDK の挙動変化で
    # sidecar (createdump.exe / loose native dll / *.json 等) が publish 出力に混ざり manifest 非記載のまま
    # zip 同梱される silent drift を upload 前に fail-fast する。Build-LauncherAgent の後に呼ぶこと (staging の
    # Companions\LauncherAgent dir = 出荷物そのもの。pdb は Build-LauncherAgent のコピーで除外済)。
    Write-Step "LauncherAgent が single-file (exe 1 個) であることを検証"
    $laDir = Join-Path $FilesDir 'Companions\LauncherAgent'
    if (-not (Test-Path $laDir)) {
        Fail "検証対象の LauncherAgent staging dir が見つかりません: $laDir (Build-LauncherAgent の後に呼ぶこと)"
    }
    $files = @(Get-ChildItem $laDir -Recurse -File)
    $unexpected = @($files | Where-Object { $_.Name -ne 'TonePrism_LauncherAgent.exe' })
    if ($unexpected.Count -gt 0) {
        $names = ($unexpected | ForEach-Object { $_.FullName.Substring($laDir.Length + 1) }) -join ', '
        Fail @"
LauncherAgent staging に想定外のファイルがあります (single-file = TonePrism_LauncherAgent.exe 1 個のはず): $names
single-file 不変条件が崩れています。csproj の PublishSingleFile / IncludeNativeLibrariesForSelfExtract、
または SDK の挙動変化で sidecar が吐かれていないか確認してください。
expected-files (manifest) は presence のみ検証で余剰を検出しないため、ここで fail-fast します。
"@
    }
    Write-Ok "LauncherAgent staging = TonePrism_LauncherAgent.exe 1 個 (single-file 不変条件 OK)"
}

# ============================================================================
# Phase 6: Install.bat / INSTALL_README.txt + Launcher.bat / Manager.bat 同梱
# ============================================================================
# zip 配布物の構造 (SPEC §3.7.1 正規 zip 構造):
#   zip ルート:    Install.bat / INSTALL_README.txt
#   zip files/:    Launcher.bat / Manager.bat (Install.bat が <インストール先>\TonePrism\
#                  にコピーする payload、ユーザーは TonePrism\Launcher.bat 等で日常起動)

function Copy-Templates {
    Write-Step "テンプレートを staging に同梱"

    # (#175 Phase 4.1) zip 構造整理: zip 直下 = Install.bat / INSTALL_README.txt のみ。
    # Launcher.bat / Manager.bat / show_folder_dialog.ps1 / bundle_manifest.json / files/ は
    # `bundle/` 配下に集約 (新規ユーザーが zip 展開した時の「面食らい」を解消、Install.bat
    # を押すだけが一目瞭然になる)。Install.bat 自身は `<SCRIPT_DIR>\bundle\...` 経由で
    # bundle 内の各 file を参照する形に同期更新 (templates/Install.bat 参照)。

    # zip ルート配置 (ユーザーがダブルクリック / 説明 read する 2 file のみ)
    $rootTemplates = @(
        @{ Src = 'templates\Install.bat';            Dest = 'Install.bat';            Label = 'Install.bat' },
        @{ Src = 'templates\INSTALL_README.txt';     Dest = 'INSTALL_README.txt';     Label = 'INSTALL_README.txt' }
    )

    # bundle/ 直下配置 (Install.bat が `<SCRIPT_DIR>\bundle\...` 経由で参照):
    #   - show_folder_dialog.ps1: Install.bat の FolderBrowserDialog 起動 helper
    #   - Launcher.bat / Manager.bat: Install.bat が <install_parent>/ (= 選んだ親フォルダ直下)
    #     にコピーする shortcut bat、ダブルクリック起動規約 (SPEC §3.7.1)
    $bundleTemplates = @(
        @{ Src = 'templates\show_folder_dialog.ps1'; Dest = 'bundle\show_folder_dialog.ps1'; Label = 'show_folder_dialog.ps1 (Install.bat dialog helper)' },
        @{ Src = 'templates\Launcher.bat';           Dest = 'bundle\Launcher.bat';           Label = 'Launcher.bat (shortcut, parent-level)' },
        @{ Src = 'templates\Manager.bat';            Dest = 'bundle\Manager.bat';            Label = 'Manager.bat (shortcut, parent-level)' }
    )

    # bundle/files/ 配下配置:
    #   - CHANGELOG.md: Phase 4 (#108) で Manager UI が「現在の Bundle version」を抽出するために
    #     `<install>/CHANGELOG.md` から parse する。SPEC §3.7.7「CHANGELOG.md は zip 同梱規約」に
    #     従い、repo root の CHANGELOG.md を `bundle/files/CHANGELOG.md` として同梱する (= zip 展開後
    #     Install.bat の `robocopy bundle\files\* <install>\` で `<install>/CHANGELOG.md` 直下に展開、
    #     `Launcher/` `Manager/` 等と同階層)。Project 全体の SoT という semantic に整合。
    #     Manager UI Phase 4 のアップデートフロー [7]〜[10] では `FileReplacer.ReplaceFile` の単体
    #     file copy で更新 (Launcher.bat / Manager.bat の shortcut bat 置換と同 pattern)。
    #   (#283) Launcher 版数の同梱ファイル (version.gd → #281 で project.godot) は**廃止**。Manager UI の
    #   VersionInventory は `<install>/Launcher/TonePrism_Launcher.exe` の FileVersionInfo (= export_presets.cfg
    #   `application/file_version` を Set-ExportPresetVersions が SoT から stamp → Godot/rcedit が exe に焼く) を
    #   読むようになったため、版数読み取り用の loose ファイルを別途同梱する必要がなくなった (exe は元々同梱)。
    $filesTemplates = @(
        @{ Src = 'CHANGELOG.md'; Dest = 'bundle\files\CHANGELOG.md'; Label = 'CHANGELOG.md (Bundle SoT for Manager UI, Phase 4 #108)' }
    )

    foreach ($tpl in ($rootTemplates + $bundleTemplates + $filesTemplates)) {
        $src = Join-Path $RepoRoot $tpl.Src
        $dst = Join-Path $StagingDir $tpl.Dest
        if (-not (Test-Path $src)) {
            Fail "テンプレートが見つかりません: $src"
        }
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }

        if ($src -match '\.bat$') {
            # cmd.exe は LF-only bat を parse できず double-click で即 close する
            # (PR #140 で Release.bat、Phase 2 で Install.bat が踏んだ事故)。
            # `.gitattributes` の `*.bat eol=crlf` は git checkout 時のみ強制する
            # ため、Write tool 編集後の working tree LF が staging に流れ込む。
            # ここで強制 CRLF normalize。
            #
            # **エンコーディング: cp932 (Shift-JIS) に変換して書き出す**:
            #   cmd.exe の bat parser は **システム codepage** (JP Windows = cp932)
            #   でファイルを読み、`chcp 65001` を bat 内で呼んでも切り替わるのは
            #   console output codepage のみ、ファイル解析側は cp932 のまま。
            #   UTF-8 で書かれた長文 Japanese echo は parser が byte 境界で
            #   mis-tokenize して "is not recognized" 連鎖エラーになる
            #   (Phase 2 で複数 round 試行錯誤の末判明)。
            #   cp932 でファイルを置けば parser が natively 読めて Japanese 行も
            #   安全。デメリット: 非 JP Windows (cp437/1252 等) では mojibake する
            #   が、本配布は JP 校内向けなので OK。
            $content = [System.IO.File]::ReadAllText($src, $script:Utf8NoBomEncoding)
            $content = ($content -replace "`r`n", "`n") -replace "`n", "`r`n"
            $cp932 = [System.Text.Encoding]::GetEncoding(932)
            [System.IO.File]::WriteAllText($dst, $content, $cp932)
        } elseif ($src -match '\.ps1$') {
            # PS 5.1 は .ps1 ファイルを default で ASCII (Windows-1252) として読み込む
            # ため、Japanese 等の non-ASCII char が含まれると mojibake になる。BOM が
            # あれば UTF-8 として正しく読まれるため **UTF-8 with BOM** で staging。
            # working tree の BOM 有無に依存しないよう ReadAllText で auto-detect
            # して読み、Write 時に強制 BOM 付与。CRLF も bat と同じ理由で normalize
            $content = [System.IO.File]::ReadAllText($src)  # auto-detect encoding via BOM/heuristics
            $content = ($content -replace "`r`n", "`n") -replace "`n", "`r`n"
            $utf8WithBom = [System.Text.UTF8Encoding]::new($true)
            [System.IO.File]::WriteAllText($dst, $content, $utf8WithBom)
        } else {
            Copy-Item $src $dst -Force
        }
        Write-Ok "$($tpl.Label) 同梱"
    }
}

# ============================================================================
# Phase 7: ExpectedFiles 検証
# ============================================================================

# (#175 Phase 4.1) Bundle manifest 同梱 + forward compatibility 機構の SoT list。
# `Assert-ExpectedFiles` が staging 検証で参照し、`New-BundleManifest` が `bundle/bundle_manifest.json`
# 生成時にも同 list を流用する (= drift fence の SoT 1 箇所維持、Phase 4 PR #161 で頻発した
# expectedFiles 同期 drift を物理的に closure)。`$script:` scope で関数間共有。
#
# 新 zip 構造 (Phase 4.1):
#   zip 直下 = Install.bat / INSTALL_README.txt のみ (ユーザー視点で「ダブルクリックする 2 file」)
#   bundle/  = それ以外全部 (Launcher.bat / Manager.bat / show_folder_dialog.ps1 / bundle_manifest.json + files/)
#
# manifest files list は **`bundle/` prefix を含まない** = bundle 内の相対 path で表現する自己完結性
# (= 将来 bundle/ → 他名に変えた時に manifest 中身を触らず済む)。`Assert-ExpectedFiles` 側は
# zip root の Install.bat / INSTALL_README.txt + bundle_manifest.json + manifest 内 files
# (それぞれ bundle/ prefix 付与) で staging 全体を検証する。
$script:BundleManifestFiles = @(
    # bundle/ 直下 (Install.bat が `<SCRIPT_DIR>\bundle\...` 経由で参照)
    'show_folder_dialog.ps1',
    'Launcher.bat',
    'Manager.bat',
    # bundle/files/ 配下 = インストール後の <親>\TonePrism\ に展開される payload
    'files\Launcher\TonePrism_Launcher.exe',    # #283: Manager UI VersionInventory が FileVersionInfo で版数を読む対象 (project.godot 同梱は廃止)
    # (#258 PR4) net10 self-contained single-file 化で Manager は exe 1 個に集約。
    # 旧 net48 構成の TonePrism_Manager.exe.config / System.Data.SQLite.dll / x64,x86\SQLite.Interop.dll は
    # 全て single-file exe に内包される (.exe.config 非生成・native は self-extract) ため expected-files から撤去。
    'files\Manager\TonePrism_Manager.exe',
    # Updater (Phase 3、SPEC §3.7.4): Manager 置換 + 再起動の最小 CLI、Companions/ 配下に配置
    'files\Companions\Updater\TonePrism_Updater.exe',
    'files\Companions\Updater\TonePrism_Updater.exe.config',
    # LauncherAgent (#101 / #216 / #30、SPEC §2.4): Launcher 補助の常駐エージェント (probe/sensor/focus 統合、旧 WindowProbe)
    # (#258 PR4.x) net10 self-contained single-file 化で exe 1 個に集約 (旧 .exe.config は net10 で非生成のため撤去)。
    'files\Companions\LauncherAgent\TonePrism_LauncherAgent.exe',
    # CHANGELOG.md (Phase 4 #108、SPEC §3.7.7): Manager UI が installed Bundle version 抽出に使う SoT、
    # `<install>/CHANGELOG.md` 直下配置で `Launcher/` `Manager/` 等と同階層 (project-wide な SoT semantic)
    'files\CHANGELOG.md'
)

# (#177 Phase 4.1+) `bundle/bundle_manifest.json` の `layout` field SoT。Manager 側 apply フロー
# (`UpdateSectionPanel.RunUpdateWorker` Step 5-9 + defer block) が hardcoded path を捨てて本 layout
# 経由で path 解決するための forward compat 機構。`$script:BundleManifestFiles` (= 個別 file list)
# と独立した SoT で、**category → dir / file mapping** を表現する。
#
# 設計判断 (#177): `schema_version=1` 維持、layout は **optional additive field**。Bundle v0.3.1
# リリースノートで「次回以降自動アップデート」と user に約束済のため、schema bump で v0.3.1 ユーザーが
# 1 回手動 install 必須になる事態を避ける必要。**未知 field 黙殺** (= 旧 reader は `TryGetValue` で
# 必要 field のみ取り出し、新 optional field `layout` は dict 内に残るが POCO 側で参照しなければ
# 無視される標準 JSON forward compat pattern) により、v0.3.1 Manager (v0.9.1) も新 manifest を silent
# に parse success できる (PR #180 round 1 Low-2 で PowerShell 実機 verify 済 pattern。**注**: PR #180
# の `UpdateCompletedSentinel` は POCO 直 deserialize で case-insensitive 自動 mapping に依存していたが、
# 本 PR `BundleLayout` は dict 経由 manual `TryGetValue` 参照のため case-sensitivity には依存しない)。
#
# key 命名は **snake_case** (JSON 慣例)、value は zip 内 `bundle/` 起点の `/` separator 相対 path。
# Manager 側 `BundleLayout` POCO は PascalCase property (C# 慣例)、wire format との対応は
# `ReadBundleManifest` 内の `TryGetLayoutString(dict, "launcher_dir")` 等の **literal snake_case key
# 参照** で manual 解決 (= `Dictionary<string, object>` default comparer は case-sensitive、snake_case ↔
# PascalCase は case 差ではなく separator 差 `_` のため自動 mapping だけでは不可)。新規 component 追加
# 時は本 hashtable に新 key を追加 + SPEC §3.7.8 チェックリスト同期更新 (= `$script:BundleManifestFiles`
# と並列の SoT)。
$script:BundleLayout = [ordered]@{
    launcher_dir   = 'files/Launcher'
    manager_dir    = 'files/Manager'
    companions_dir = 'files/Companions'
    updater_dir    = 'files/Companions/Updater'
    launcher_bat   = 'Launcher.bat'
    manager_bat    = 'Manager.bat'
    changelog_md   = 'files/CHANGELOG.md'
}

# ============================================================================
# Phase 6.5: Bundle manifest 生成 (#175 Phase 4.1)
# ============================================================================
# `bundle/bundle_manifest.json` を生成して zip 同梱する。Manager UI 側 (UpdateDownloader.ValidateStaging)
# が apply 時に読み込んで「list 通り存在するか」だけ check することで、Manager 側の hardcoded
# expectedFiles list を持たずに **zip 構造変更を自動追従** できる forward compat 機構を獲得する。
#
# 旧設計 (Phase 4 PR #161) は Manager に hardcoded list を持ち、Release.ps1 の `Assert-ExpectedFiles`
# と SPEC §3.7.8 で同期 fence していたが、新 release で zip 構造が変わると旧 Manager が新 zip を
# reject する (= 「v0.3.0 → v0.3.1 で `files/Manager/CHANGELOG.md` → `files/CHANGELOG.md` に path
# 変更したら旧 Manager が新 zip を validate できず手動 install 必要」path)。manifest 同梱で本
# silent failure を物理的に closure。
function New-BundleManifest {
    Write-Step "Bundle manifest を生成: $ManifestPath"

    # manifest schema (schema_version 1):
    #   {
    #     "bundle_version": "0.3.1",
    #     "generated_at": "2026-05-18T...Z" (ISO 8601),
    #     "schema_version": 1,
    #     "files": ["show_folder_dialog.ps1", "files/CHANGELOG.md", ...]  # bundle/ からの相対 path
    #     "layout": { "launcher_dir": "files/Launcher", ... }              # (#177) apply 側 path 解決用
    #   }
    # Schema 進化方針: **既存 field の semantics 変更** (例: files の型を [string] → [{name, sha256}] に
    # 拡張) は schema_version bump 必須。**新 optional field の追加** (本 PR の `layout` 等) は旧 reader
    # が TryGetValue で無視できる additive change のため schema_version=1 維持で forward compat。詳細
    # SPEC §3.7.7 / Manager `BundleManifest` docstring 参照。
    # (#175 Phase 4.1 round 1 Critical-1) `generated_at` は `[DateTime]::UtcNow.ToString(...)` 直接代入。
    # 旧実装の `Get-Date -Format "..." -AsUTC -ErrorAction SilentlyContinue` + fallback block は PS 5.1
    # では `-AsUTC` が **NamedParameterNotFound** terminating error として `$ErrorActionPreference='Stop'`
    # (Release.ps1 冒頭設定) で abort、hashtable construction 自体が止まって fallback block 永久不到達。
    # `-ErrorAction SilentlyContinue` は parameter binding error には効かない (parameter scope に到達する
    # 前に発生する error のため)。`[DateTime]::UtcNow.ToString(...)` は PS 5.1 / 7.x 両対応 + fallback
    # 不要 + 同等の ISO 8601 UTC 出力 (例: `2026-05-18T16:30:00Z`) で代替。
    $manifest = [ordered]@{
        bundle_version = $Version
        generated_at   = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        schema_version = 1
        # files list: bundle/ からの相対 path (= bundle dir 名変更時に manifest 触らず済む自己完結性)
        # JSON で `/` separator に統一 (Windows path separator `\` は JSON 中 escape 必須 + non-Windows
        # 環境からの読みやすさ低下のため避ける)。staging に書き出すときも `/` で記録し、Manager 側で
        # `Path.Combine` 渡す前に platform-specific separator に変換する想定 (.NET の Path.Combine は
        # `/` separator も受理するので実用上は変換不要、defensive 同期のため明示)。
        files          = @($script:BundleManifestFiles | ForEach-Object { $_ -replace '\\', '/' })
        # (#177) layout (apply 側 path 解決用): Manager `UpdateSectionPanel.RunUpdateWorker` が本 layout
        # 経由で path を取得して hardcoded path を捨てる、forward compat 機構の Phase 4.1+ 完成。layout
        # 不在 (= v0.3.0 legacy) は Manager 側 null-coalesce で hardcoded legacy path に fallback。
        layout         = $script:BundleLayout
    }

    # bundle dir 存在 check (Copy-Templates が既に作成済の想定、defensive で再作成)
    if (-not (Test-Path $BundleDir)) {
        New-Item -ItemType Directory -Path $BundleDir -Force | Out-Null
    }
    $json = $manifest | ConvertTo-Json -Depth 5
    # UTF-8 (no BOM) で書き出し (Manager 側 JavaScriptSerializer が BOM を含む / 含まない両対応の
    # ため strict 制約ではないが、project 全体の JSON 出力規約と一貫させる)
    [System.IO.File]::WriteAllText($ManifestPath, $json, $script:Utf8NoBomEncoding)

    Write-Ok "Bundle manifest 生成完了 ($($script:BundleManifestFiles.Count) files entries + $($script:BundleLayout.Count) layout keys)"
}

function Assert-ExpectedFiles {
    Write-Step "ExpectedFiles 検証"

    # (#175 Phase 4.1) 検証対象 = zip 直下 (Install.bat / INSTALL_README.txt) + bundle/bundle_manifest.json
    # (New-BundleManifest が直前で生成) + bundle/<manifest files> (= staging 内に bundle/ prefix で揃ってる)。
    # SoT は `$script:BundleManifestFiles` (= manifest と共通)、本関数では bundle/ prefix を付与して staging
    # 全 path を検証。
    $zipRootExpected = @(
        'Install.bat',
        'INSTALL_README.txt',
        $script:ManifestRelativePath  # (#175 round 2 Low-3) SoT 集約、line 280 周辺の定数参照
    )
    $bundleExpected = $script:BundleManifestFiles | ForEach-Object { Join-Path 'bundle' $_ }
    $expected = $zipRootExpected + $bundleExpected

    $missing = @()
    foreach ($rel in $expected) {
        $abs = Join-Path $StagingDir $rel
        if (-not (Test-Path $abs)) { $missing += $rel }
    }

    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "    以下のファイルが staging に存在しません:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "        $_" -ForegroundColor Red }
        Fail "ExpectedFiles 検証で漏れを検出しました ($($missing.Count) 件)"
    }
    Write-Ok "ExpectedFiles 全 $($expected.Count) 件 OK (zip root $($zipRootExpected.Count) + bundle $($bundleExpected.Count))"
}

# ============================================================================
# Phase 8: New-Zip
# ============================================================================

function New-Zip {
    Write-Step "zip 化: $ZipPath"
    if (Test-Path $ZipPath) {
        Remove-Item -Force $ZipPath
        Write-Info "既存 zip を削除"
    }
    $items = Get-ChildItem $StagingDir
    Compress-Archive -Path ($items.FullName) -DestinationPath $ZipPath -CompressionLevel Optimal
    if (-not (Test-Path $ZipPath)) {
        Fail "zip 生成に失敗しました"
    }
    $sizeMb = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-Ok "zip 生成完了: $sizeMb MB"
}

# ============================================================================
# Phase 10: gh release create
# ============================================================================

function Invoke-GhRelease {
    Write-Step "GitHub Releases にアップロード"

    if ($script:DeleteExistingRelease) {
        Write-Info "既存タグ v$Version を削除"
        $delResult = Invoke-NativeWithCapture -FilePath 'gh' `
            -Arguments @('release', 'delete', "v$Version", '--yes', '--cleanup-tag') `
            -ShowProgress -ProgressMessage "既存 release を削除中..."
        if ($delResult.ExitCode -ne 0) {
            Fail "既存 release の削除に失敗しました:`n$($delResult.Combined.TrimEnd())"
        }
        # gh release delete は成功時 stdout/stderr ともに無音なので、
        # ShowProgress 行が消えた後の「無の状態」を避けるため明示的な完了表示
        Write-Ok "既存タグ v$Version を削除完了"
        # 下記は future-proofing (現行 gh では成功時 stdout 空のため発火しない、
        # 将来 version が完了メッセージ等を出力するようになった場合に表示)
        $delOut = $delResult.StdOut.TrimEnd()
        if ($delOut -match '\S') { Write-Info $delOut }
    }

    # CHANGELOG から抽出した Bundle セクション本文を --notes に渡す
    # 一時ファイル経由にする (CLI 引数の改行 / 引用符 escape を避けるため)
    $tmpNotes = New-TemporaryFile
    try {
        [System.IO.File]::WriteAllText($tmpNotes.FullName, $script:ReleaseNotesText, $script:Utf8NoBomEncoding)
        # zip サイズは MB / KB を自動切替で表示 (小さいファイル時に `0 MB` 表示で
        # 破損誤解を避ける、Phase 2 以降の Updater 単体 zip 等で発火する想定)
        $zipBytes = (Get-Item $ZipPath).Length
        $zipSize  = if ($zipBytes -ge 1MB) {
            "$([math]::Round($zipBytes / 1MB, 1)) MB"
        } elseif ($zipBytes -ge 1KB) {
            "$([math]::Round($zipBytes / 1KB, 1)) KB"
        } else {
            "$zipBytes B"
        }
        $uploadResult = Invoke-NativeWithCapture -FilePath 'gh' `
            -Arguments @('release', 'create', "v$Version", $ZipPath, '--notes-file', $tmpNotes.FullName, '--title', "v$Version") `
            -ShowProgress -ProgressMessage "アップロード中 (zip $zipSize)..."
        if ($uploadResult.ExitCode -ne 0) {
            Fail "gh release create に失敗しました:`n$($uploadResult.Combined.TrimEnd())"
        }
        # 成功時、gh は release URL を stdout に dump するのでユーザーに表示。
        # 注: gh の将来 version で stdout フォーマットが変わると URL が表示されない
        # silent path になるが、成功は exit code で確実に取れているため fatal で
        # はない (`Write-Ok "公開完了"` は出る、URL は手動で confirm 可能)。
        # 同型の脆弱性は gh release view の "release not found" stderr マッチ側でも
        # 抱えており、本格的な structured 検出は別 issue 系で対処予定。
        $uploadOut = $uploadResult.StdOut.TrimEnd()
        if ($uploadOut -match '\S') { Write-Info $uploadOut }
    } finally {
        Remove-Item $tmpNotes.FullName -Force -ErrorAction SilentlyContinue
    }
    Write-Ok "GitHub Releases v$Version 公開完了"
}

# ============================================================================
# Phase 11: 古い tools/godot/<patch>/ の自動削除（最大 2 version 残す）
# ============================================================================

function Clear-OldGodot {
    Write-Step "古い Godot キャッシュをクリーンアップ"

    # サーバー側 tools/godot/<version>/ は最新 2 version まで残す
    if (Test-Path $ToolsGodot) {
        # version 番号は文字列辞書順だと 4.10 < 4.9 と誤判定するため [version] cast で数値比較する。
        # `-as [version]` が $null になる非 version dir は削除対象から除外 (cast 例外で cleanup が落ちるのも防ぐ)。
        $allGodotDirs = @(Get-ChildItem $ToolsGodot -Directory)
        # 非 version 名 dir (例: pre-release suffix 付き) は cleanup 対象外。無言で蓄積しないよう warn を出す。
        foreach ($nv in @($allGodotDirs | Where-Object { -not ($_.Name -as [version]) })) {
            Write-Warn "tools/godot/$($nv.Name) は version 形式でないため cleanup 対象外 (蓄積に注意)"
        }
        $dirs = @($allGodotDirs |
            Where-Object { $_.Name -as [version] } |
            Sort-Object { [version]$_.Name } -Descending)
        if ($dirs.Count -gt 2) {
            $toDelete = @($dirs | Select-Object -Skip 2)
            foreach ($d in $toDelete) {
                Write-Info "tools/ 削除: $($d.Name)"
                Remove-Item -Recurse -Force $d.FullName
            }
            Write-Ok "サーバー tools/ クリーンアップ: $($toDelete.Count) 件削除"
        } else {
            Write-Info "サーバー tools/: $($dirs.Count) version 保持中 (上限 2 以下なので削除なし)"
        }
    }

    # AppData 側 (%APPDATA%/Godot/export_templates/<version>.stable/) は
    # `.gctone_managed` マーカーがあり、かつ $GodotPatchTable に登録されていない version を削除
    # マーカー無し (Godot エディタ UI で部員が手動 DL した等) は触らない
    $appdataTemplatesRoot = Join-Path $env:APPDATA 'Godot\export_templates'
    if (Test-Path $appdataTemplatesRoot) {
        $managedPatches = @($GodotPatchTable.Values | ForEach-Object { $_.Patch })
        $stableDirs = @(Get-ChildItem $appdataTemplatesRoot -Directory | Where-Object { $_.Name -like '*.stable' })
        $removed = 0
        foreach ($d in $stableDirs) {
            $marker = Join-Path $d.FullName '.gctone_managed'
            if (-not (Test-Path $marker)) {
                # 外部管理 (Godot エディタ UI 等) なので触らない
                continue
            }
            $verName = $d.Name -replace '\.stable$', ''  # "4.6.2.stable" → "4.6.2"
            if ($managedPatches -notcontains $verName) {
                Write-Info "AppData 削除: $($d.Name)"
                Remove-Item -Recurse -Force $d.FullName
                $removed++
            }
        }
        if ($removed -gt 0) {
            Write-Ok "AppData クリーンアップ: $removed 件削除"
        } else {
            Write-Info "AppData: 削除対象なし (現行 patch table 内 + 外部管理は保護)"
        }
    }
}

# ============================================================================
# Main
# ============================================================================

Write-Host ""
Write-Host "TonePrism Release Script" -ForegroundColor White
Write-Host "Bundle Version: $Version" -ForegroundColor White
Write-Host "RepoRoot:       $RepoRoot" -ForegroundColor White
if ($DryRun)     { Write-Host "Mode: DRY-RUN (zip と upload を skip)" -ForegroundColor Yellow }
if ($SkipUpload) { Write-Host "Mode: SKIP-UPLOAD" -ForegroundColor Yellow }
if ($Force)      { Write-Host "Mode: FORCE" -ForegroundColor Yellow }
if ($Offline)    { Write-Host "Mode: OFFLINE" -ForegroundColor Yellow }

Assert-Preflight
Assert-ChangelogLinkDefs
Assert-ComponentVersions
Resolve-Godot
Resolve-MsBuild
Resolve-Dotnet
Set-ExportPresetVersions
Assert-WorkingTreeClean -Context "export_presets sync 後" -PostSync
Clear-Staging
Build-Launcher
Assert-ExportedLauncherVersion
Build-Manager
Assert-PublishedManagerVersion
Assert-ManagerSingleFile
Build-Updater
Build-LauncherAgent
Assert-PublishedLauncherAgentVersion
Assert-LauncherAgentSingleFile
Copy-Templates
New-BundleManifest        # (#175 Phase 4.1) bundle/bundle_manifest.json 生成、Assert より前
Assert-ExpectedFiles
Clear-OldGodot

if ($DryRun) {
    Write-Host ""
    Write-Host "DRY-RUN 完了: staging エリアは $StagingDir に残っています。" -ForegroundColor Yellow
    exit 0
}

New-Zip

if ($SkipUpload) {
    Write-Host ""
    Write-Host "SKIP-UPLOAD 完了: $ZipPath を確認してください。" -ForegroundColor Yellow
    exit 0
}

# zip 完成後の upload フロー (v0.1.9 で再設計):
#   旧: preflight でタグ衝突チェック → build 前に即 fail (zip 検証用途も塞いでいた)
#   v0.1.9 中間: build → zip → Y/N → 衝突チェック (Y 押させてから fail でミスリード)
#   v0.1.9 最終: build → zip → 衝突チェック → Y/N (publish 可能な状態だけ Y を聞く)
#
# (1) タグ衝突チェック
#       既存 + Force なし → 「publish できません」案内で graceful exit (zip は preserve)
#       既存 + Force あり → warn + DeleteExistingRelease=true で続行
#       不在            → OK で続行
Resolve-TagConflict

# (2) 公開確認 Y/N (ここまで来た時点で publish 可能 = 衝突なし or -Force)
Write-Step "GitHub Releases 公開確認"
Write-Info "Bundle version: $Version"
Write-Info "zip ファイル:   $ZipPath"
$zipBytes = (Get-Item $ZipPath).Length
$zipSizeHuman = if ($zipBytes -ge 1MB) {
    "$([math]::Round($zipBytes / 1MB, 1)) MB"
} elseif ($zipBytes -ge 1KB) {
    "$([math]::Round($zipBytes / 1KB, 1)) KB"
} else { "$zipBytes B" }
Write-Info "サイズ:        $zipSizeHuman"
if ($script:DeleteExistingRelease) {
    Write-Info "(-Force: 既存 v$Version を削除して再 publish 予定)"
}
Write-Host ""

# Non-interactive 検出 (シニアレビュー round 4 M3 + round 5 M1):
#   Read-Host は stdin が redirect されている / 端末がない環境で空文字列を返す。
#   `'^(y|yes)$'` は空に一致しないので、CI で `-SkipUpload` 付け忘れた場合に
#   何の警告もなく exit 3 (= N 回答 skip) になる silent path があった。
#   これでは「user が意図的に N と答えた」のか「stdin がなくて空が返った」のか
#   exit code で区別できず、exit code 体系 (2 = env state, 3 = user 判断) の
#   区別が崩れる。明示的に「-SkipUpload を付けてください」と Fail (exit 1) する。
#
# 判定: UserInteractive AND -not IsInputRedirected。
#   - UserInteractive: PS host が user 対話可能と判定したか (CI / Service 等で false)
#   - IsInputRedirected: stdin がパイプやファイルから redirect されているか
#
# 重要 (round 5 M1): 各 API は **独立した try** で取得する。旧実装は両 API を
# 1 つの try ブロックでまとめていたが、最初の API で `$isInteractive = $false`
# が確定した後に 2 番目の API が例外を投げると、catch が `$true` に巻き戻して
# silent path を再導入してしまっていた。独立 try で取得して最後に AND 合成
# することで、片側 API 失敗が他方の確定判定を上書きしないようにする。
# 取得失敗時の default は安全側 (interactive 扱い → 従来通り Read-Host に進む)。
$ui = try { [Environment]::UserInteractive } catch { $true }
$inputRedirected = try { [Console]::IsInputRedirected } catch { $false }
$isInteractive = $ui -and -not $inputRedirected
if (-not $isInteractive) {
    Write-Host ""
    Write-Warn "非対話環境 (CI / stdin redirected) を検出しました。"
    Write-Info "Y/N upload prompt は対話前提のため、本セッションでは安全側で abort します。"
    Write-Info "CI / 自動化からは `-SkipUpload` または `-DryRun` を明示指定してください。"
    Write-Info "(zip は $ZipPath に残っています、別環境で publish するか SkipUpload で build-only 実行)"
    Fail "non-interactive environment: -SkipUpload / -DryRun 未指定で Read-Host を呼ぼうとしました"
}

$confirmUpload = Read-Host "    GitHub Releases に v$Version を公開しますか？ (y/yes/n/no で回答)"
# 厳格マッチ: `^y` だけだと `yikes` / `yo` 等の typo / 「YES (確認)」末尾括弧でも
# 公開が走るため、`y` / `yes` 完全一致 (大小文字不問) のみ Y 扱い。
# 誤判定で abort → 再実行する方が誤公開より低コスト (GitHub Releases publish は
# 巻き戻し不可、明示的同意の意図に合わせる)
if ($confirmUpload -inotmatch '^(y|yes)$') {
    Write-Host ""
    Write-Warn "アップロードをスキップしました。zip は $ZipPath に残っています。"
    Write-Info "別環境での Install.bat 検証等に流用可。"
    Write-Info "再度 publish を試みる場合は .\Release.bat を再実行 → y/yes 選択。"
    Write-Info "(再 build (Godot export / msbuild) は走るが、Godot / nuget の DL キャッシュは"
    Write-Info " 温存されるため初回より速い。`tag conflict` graceful exit と同じキャッシュ挙動)"
    # exit code 3 = Y/N の N 回答による intentional skip (シニアレビュー round 3 M4)。
    # tag conflict skip (exit 2) と区別する: 前者は env 起因の "publish 不可"、
    # こちらは user の判断による "publish しない"。CI から見ると両方 "未発火" だが、
    # リトライ可否 / オペレーター介入の必要性が違う。code 体系は Resolve-TagConflict
    # コメント参照。
    exit 3
}

Invoke-GhRelease

Write-Host ""
Write-Host "全工程完了: GitHub Releases v$Version 公開済み" -ForegroundColor Green
