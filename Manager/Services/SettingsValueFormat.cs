using System;

namespace TonePrism.Manager.Services
{
    /// <summary>
    /// (#35 / #297 PR3) `settings` テーブルに入る**値**の表現と解釈。
    ///
    /// key 定数の SoT である <see cref="SettingsKeys"/> とは責務が違うので別ファイルに置く
    /// (AGENTS.md「File Structure」: 既存ファイルへの関数追加時、ファイルの責務と合わなければ別ファイルにする)。
    /// </summary>
    public static class SettingsValueFormat
    {
        /// <summary>
        /// bool 設定を解釈する。**正本は "true" / "false"**（大文字小文字は無視、前後の空白は許容）。
        /// "1" / "0" も真偽として受けるのは手編集や外部ツールへの保険で、Manager からはこの形でしか書かない。
        ///
        /// **Launcher 側 (`settings_repository.gd` の `get_bool`) と同じ規則にすること。** 揃っていないと
        /// 「Manager の画面では ON なのに Launcher はアンケートを出さない」という、現場で切り分け不能な
        /// 食い違いになる（実際にレビューで、"0" を Manager が ON・Launcher が OFF と読む非対称が見つかった）。
        /// 両側の表が一致することは `SettingsBoolFormatTests` で固定している。
        /// </summary>
        /// <param name="raw">保存されている生の値（null / 空も可）。</param>
        /// <param name="defaultValue">未設定・解釈不能なときに採る値。</param>
        public static bool ParseBool(string raw, bool defaultValue)
        {
            if (string.IsNullOrWhiteSpace(raw)) return defaultValue;
            string v = raw.Trim();
            if (string.Equals(v, "true", StringComparison.OrdinalIgnoreCase) || v == "1") return true;
            if (string.Equals(v, "false", StringComparison.OrdinalIgnoreCase) || v == "0") return false;
            // 解釈できない値で機能を黙って消さない（既定を ON 側に倒す設定があるため）。
            return defaultValue;
        }

        /// <summary>bool 設定を書くときの表現（<see cref="ParseBool"/> と対）。</summary>
        public static string FormatBool(bool value) => value ? "true" : "false";
    }
}
