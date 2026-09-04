using System.Collections.Generic;
using TonePrism.Manager.Services;
using Xunit;

namespace TonePrism.Manager.Tests
{
    /// <summary>
    /// (#258) `JsonCompat` (JavaScriptSerializer → System.Text.Json 移行アダプター) の挙動保存テスト。
    /// 移行前は `JavaScriptSerializer` を使う JSON 経路に test が無く「190 緑」が網にならなかったため、
    /// 旧挙動 (case-insensitive deserialize / 動的ツリー型 / serialize round-trip) を明示的に pin する。
    /// </summary>
    public class JsonCompatTests
    {
        private sealed class CamelWireDto
        {
            public string CompletedAt { get; set; }
            public string NewVersion { get; set; }
            /// <summary>(#440) 置換後に起動しているはずの Manager の FileVersion。旧 sentinel には無い。</summary>
            public string NewManagerVersion { get; set; }
        }

        [Fact]
        public void Deserialize_CamelCaseWire_MapsToPascalCaseDto_CaseInsensitive()
        {
            // 旧 JavaScriptSerializer の case-insensitive deserialize 再現: camelCase wire を PascalCase DTO が受理。
            // (= sentinel ファイル UpdateCompletedSentinel / LogsRootMigratedSentinel が依存する挙動)
            var dto = JsonCompat.Deserialize<CamelWireDto>("{\"completedAt\":\"2026-06-11T00:00:00Z\",\"newVersion\":\"1.2.3\"}");
            Assert.NotNull(dto);
            Assert.Equal("2026-06-11T00:00:00Z", dto.CompletedAt);
            Assert.Equal("1.2.3", dto.NewVersion);
        }

        [Fact]
        public void Serialize_AnonymousCamelCase_PreservesWireNames_AndRoundTrips()
        {
            // writer 側 (UpdateSectionPanel sentinel) の匿名型 camelCase が wire にそのまま出ること + round-trip。
            string json = JsonCompat.Serialize(new { completedAt = "T", newVersion = "9.9.9" });
            Assert.Contains("\"completedAt\":", json);
            Assert.Contains("\"newVersion\":", json);
            var back = JsonCompat.Deserialize<CamelWireDto>(json);
            Assert.Equal("T", back.CompletedAt);
            Assert.Equal("9.9.9", back.NewVersion);
        }

        [Fact]
        public void Sentinel_NewManagerVersion_RoundTrips()
        {
            // (#440) 起動時の完了検証は「NewManagerVersion が非空で読めること」に全面的に乗っている。
            // マッピングが壊れると null になり、検証が黙って skip されて従来どおり「✓ 完了」が出る
            // = この修正が潰そうとしている silent pass の形でそのまま退行する。wire contract を固定する。
            string json = JsonCompat.Serialize(new { completedAt = "T", newVersion = "0.11.1", newManagerVersion = "0.34.1.0" });
            Assert.Contains("newManagerVersion", json);
            var back = JsonCompat.Deserialize<CamelWireDto>(json);
            Assert.Equal("0.34.1.0", back.NewManagerVersion);
            Assert.Equal("0.11.1", back.NewVersion);
            Assert.Equal("T", back.CompletedAt);
        }

        [Fact]
        public void Sentinel_WithoutNewManagerVersion_YieldsNull_ForBackwardCompatibility()
        {
            // 旧 sentinel (2 フィールド) を読んでも throw せず、NewManagerVersion が null になること。
            // 起動側はこれを見て検証を skip する (後方互換)。null にならないと誤検知で
            // 「✗ アップデート未完了」を出しかねない。
            string oldJson = JsonCompat.Serialize(new { completedAt = "2026-09-04T00:00:00Z", newVersion = "0.11.0" });
            var dto = JsonCompat.Deserialize<CamelWireDto>(oldJson);
            Assert.NotNull(dto);
            Assert.Equal("0.11.0", dto.NewVersion);
            Assert.Null(dto.NewManagerVersion);
        }

        [Fact]
        public void Sentinel_ExplicitNullNewManagerVersion_RoundTripsAsNull()
        {
            // writer が実際に取り得る 3 つ目の形: staging exe を読めず expectedManagerVersion が null の
            // まま匿名型に入り、wire に "newManagerVersion": null が出るケース (フィールド欠落とは別)。
            // ここが null で返らないと、起動時の完了検証が誤って走って偽の「✗ 未完了」を出しかねない。
            string json = JsonCompat.Serialize(new { completedAt = "T", newVersion = "0.11.1", newManagerVersion = (string)null });
            var back = JsonCompat.Deserialize<CamelWireDto>(json);
            Assert.NotNull(back);
            Assert.Equal("0.11.1", back.NewVersion);
            Assert.Null(back.NewManagerVersion);
        }

        [Fact]
        public void UpdateRunResult_WireContract_RoundTrips()
        {
            // (#440) Updater が `<install>/.update_result` に残す実行結果。Manager 側の成否判定は
            // 全面的にこの wire contract に乗っているので固定する。
            string json = JsonCompat.Serialize(new { finishedAt = "T", exitCode = 4, targetManagerVersion = "0.34.1.0" });
            var dto = JsonCompat.Deserialize<TonePrism.Manager.Services.UpdaterClient.UpdateRunResult>(json);
            Assert.NotNull(dto);
            Assert.Equal(4, dto.ExitCode);
            Assert.Equal("0.34.1.0", dto.TargetManagerVersion);
            // 成否は exitCode から導出する (ファイルに success は持たせない)。
            Assert.False(dto.Success.Value);
        }

        [Fact]
        public void UpdateRunResult_ExitCodeZero_MeansSuccess()
        {
            string json = JsonCompat.Serialize(new { finishedAt = "T", exitCode = 0, targetManagerVersion = "0.34.1.0" });
            var dto = JsonCompat.Deserialize<TonePrism.Manager.Services.UpdaterClient.UpdateRunResult>(json);
            Assert.True(dto.Success.Value);
        }

        [Fact]
        public void UpdateRunResult_MissingExitCode_IsUnknown_NotFailure()
        {
            // exitCode を持たない (壊れた / 想定外の) ファイルを **失敗と決めつけない**。
            // int で受けると欠落が 0 = 成功に化け、bool の success フィールドを持たせると欠落が
            // false = 失敗に化ける。nullable にして「不明」を表現できるようにしてある。
            string json = JsonCompat.Serialize(new { finishedAt = "T", targetManagerVersion = "0.34.1.0" });
            var dto = JsonCompat.Deserialize<TonePrism.Manager.Services.UpdaterClient.UpdateRunResult>(json);
            Assert.NotNull(dto);
            Assert.False(dto.ExitCode.HasValue);
            Assert.False(dto.Success.HasValue);
        }

        [Fact]
        public void DeserializeToObjectTree_Object_ReturnsStringObjectDict_WithJavaScriptSerializerTypes()
        {
            // 旧 DeserializeObject の型再現: object → Dictionary<string,object>、値は string/bool/long/double/null。
            var obj = JsonCompat.DeserializeToObjectTree("{\"s\":\"v\",\"b\":true,\"i\":42,\"d\":1.5,\"n\":null}");
            var dict = Assert.IsType<Dictionary<string, object>>(obj);
            Assert.Equal("v", dict["s"]);
            Assert.Equal(true, dict["b"]);
            Assert.IsType<long>(dict["i"]);           // 整数は long (AsLong の `is long` path が依存)
            Assert.Equal(42L, dict["i"]);
            Assert.IsType<double>(dict["d"]);          // 非整数は double
            Assert.Equal(1.5, (double)dict["d"]);
            Assert.Null(dict["n"]);
        }

        [Fact]
        public void DeserializeToObjectTree_Array_ReturnsObjectArray()
        {
            // 旧 Deserialize<object[]> / DeserializeObject の array → object[] 再現
            // (GitHubReleaseChecker.ParseReleaseArray / assets 走査が `as object[]` / IEnumerable を前提)。
            var obj = JsonCompat.DeserializeToObjectTree("[1,2,3]");
            var arr = Assert.IsType<object[]>(obj);
            Assert.Equal(3, arr.Length);
            Assert.Equal(1L, arr[0]);
        }

        [Fact]
        public void DeserializeToObjectTree_NestedObjectInArray_MatchesAssetsShape()
        {
            // GitHub release の assets:[{...}] 形を再現: dict["assets"] が object[]、要素が Dictionary<string,object>。
            var obj = JsonCompat.DeserializeToObjectTree("{\"assets\":[{\"name\":\"a.zip\",\"size\":12345678901}]}");
            var dict = Assert.IsType<Dictionary<string, object>>(obj);
            var assets = Assert.IsType<object[]>(dict["assets"]);
            var asset0 = Assert.IsType<Dictionary<string, object>>(assets[0]);
            Assert.Equal("a.zip", asset0["name"]);
            Assert.IsType<long>(asset0["size"]);       // int 範囲を超える size も long で保持 (Int64)
            Assert.Equal(12345678901L, asset0["size"]);
        }
    }
}
