using TonePrism.Manager.Services;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#35 / レビュー Medium-3) bool 設定の表現と解釈を固定する。
    ///
    /// **Launcher の `settings_repository.gd` の `get_bool` と同じ規則でなければならない。** 揃っていないと
    /// 「Manager の画面では ON なのに Launcher はアンケートを出さない」という、現場で切り分けようのない
    /// 食い違いになる。実際レビューで、旧実装（"false" 以外はすべて ON）が `"0"` を ON と読み、Launcher が
    /// OFF と読む非対称が見つかった。Launcher 側は GDScript でこのテストから参照できないため、
    /// **ここは「Launcher と同じ表を書き写したもの」**として維持する（片方を変えたら両方直す）。
    /// </summary>
    public class SettingsBoolFormatTests
    {
        [Theory]
        [InlineData("true", true)]
        [InlineData("True", true)]
        [InlineData("TRUE", true)]
        [InlineData("1", true)]
        [InlineData("false", false)]
        [InlineData("False", false)]
        [InlineData("0", false)]
        [InlineData(" true ", true)]   // 手編集で空白が混じっても解釈する
        [InlineData(" 0 ", false)]
        public void ParseBool_FollowsTheSameTableAsLauncher(string raw, bool expected)
        {
            // 既定値は結果に影響しない（どちらを渡しても解釈が変わらないこと自体を確かめる）
            Assert.Equal(expected, SettingsValueFormat.ParseBool(raw, true));
            Assert.Equal(expected, SettingsValueFormat.ParseBool(raw, false));
        }

        [Theory]
        [InlineData(null)]
        [InlineData("")]
        [InlineData("   ")]
        [InlineData("yes")]
        [InlineData("2")]
        public void ParseBool_FallsBackToDefault_WhenUninterpretable(string raw)
        {
            // 「値が壊れている」というだけで機能を黙って消さない（既定 ON の設定があるため）。
            Assert.True(SettingsValueFormat.ParseBool(raw, true));
            Assert.False(SettingsValueFormat.ParseBool(raw, false));
        }

        [Fact]
        public void FormatBool_RoundTripsThroughParseBool()
        {
            Assert.Equal("true", SettingsValueFormat.FormatBool(true));
            Assert.Equal("false", SettingsValueFormat.FormatBool(false));
            Assert.True(SettingsValueFormat.ParseBool(SettingsValueFormat.FormatBool(true), false));
            Assert.False(SettingsValueFormat.ParseBool(SettingsValueFormat.FormatBool(false), true));
        }
    }
}
