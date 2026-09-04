using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// (#281) 単体テスト (Manager.Tests) から internal 型 (VersionInventory.ParseConfigVersion 等) を参照可能にする。
[assembly: InternalsVisibleTo("TonePrism_Manager.Tests")]

// アセンブリに関する一般的な情報は、次の方法で制御されます
// 制御されます。アセンブリに関連付けられている情報を変更するには、
// これらの属性値を変更します。
[assembly: AssemblyTitle("TonePrism_Manager")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("TonePrism_Manager")]
[assembly: AssemblyCopyright("Copyright © 2025-2026 TonePrism Project — Lead maintainer: Kenshiro Kuroga (Osaka Prefectural Toneyama Upper Secondary School PC Club)")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// ComVisible を false に設定すると、このアセンブリ内の型は COM コンポーネントから
// 参照できなくなります。COM からこのアセンブリ内の型にアクセスする必要がある場合は、
// その型の ComVisible 属性を true に設定してください。
[assembly: ComVisible(false)]

// このプロジェクトが COM に公開される場合、次の GUID が typelib の ID になります
[assembly: Guid("ea046367-f4b6-4ee0-80ec-6f87d82fe4ef")]

// アセンブリのバージョン情報は、以下の 4 つの値で構成されています:
//
//      メジャー バージョン
//      マイナー バージョン
//      ビルド番号
//      リビジョン
//
[assembly: AssemblyVersion("0.34.1.0")]
[assembly: AssemblyFileVersion("0.34.1.0")]
