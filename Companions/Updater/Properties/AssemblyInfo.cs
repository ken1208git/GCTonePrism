using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("TonePrism_Updater")]
[assembly: AssemblyDescription("Updates TonePrism Manager (Phase 3, minimal CLI). See SPECIFICATION.md §3.7.4.")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("TonePrism_Updater")]
[assembly: AssemblyCopyright("Copyright © 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

[assembly: ComVisible(false)]
[assembly: Guid("b5d71e9c-0f2e-4f4a-9e5a-1a2c3d4e5f6a")]

// 本コンポーネントは通常 release 跨ぎで変更しない (SPEC §3.7.4)。
// ただし brand rename / cross-cutting sweep 等で全 component sync update が必要な場合は同期 bump する
// (例: #168 brand rename で 0.1.0 → 0.2.0、Updater logic 自体は無変更だが exe filename + namespace rename
// で OS layer の breaking change が発生したため)。
// 変更時はここを bump + CHANGELOG `## Companions` セクション (旧 `## Updater`、#160 で rename) に entry 追加。
[assembly: AssemblyVersion("0.2.2.0")]
[assembly: AssemblyFileVersion("0.2.2.0")]
