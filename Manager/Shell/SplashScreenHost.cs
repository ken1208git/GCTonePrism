using System;
using System.Threading;
using System.Windows.Threading;

namespace TonePrism.Manager.Shell
{
    /// <summary>
    /// (#246) 起動スプラッシュを専用 UI スレッドで表示するホスト。メインスレッドが起動 init
    /// (DB init/migration・パネルロード等) でブロックされている間も、独立した <see cref="Dispatcher"/>
    /// で再描画 (不定プログレスのアニメ) が止まらない。
    ///
    /// 設計: **fail-open**。全メソッドは例外を握り潰し、スプラッシュ障害で起動 (= 心臓部) を絶対に
    /// 止めない。スレッドは IsBackground=true なので、万一閉じ損ねてもプロセス exit で道連れに落ちる。
    /// 非トップモスト (`Topmost="False"`) だが、**フォアグラウンドは握る**。したがって起動中モーダルが前面に出ることは保証されない (更新完了 / DB 作成確認 は現在も owner を渡していない = SPEC §3.8.2.1 の「未解決」に分類。#449 で owner を付け直したのは更新通知と競合ゲート) — 実際 #449 で スプラッシュの背後にダイアログが埋もれて 8 分間固まった。**モーダルの前面性・到達可能性は owner 側で担保する**こと (SPEC §3.8.2.1 / `MainForm.VisibleModalOwnerOrNull`)。
    /// </summary>
    internal static class SplashScreenHost
    {
        private static SplashWindow _window;
        private static Thread _thread;
        private static readonly ManualResetEventSlim _ready = new ManualResetEventSlim(false);

        /// <summary>専用 STA スレッドでスプラッシュを表示する。窓生成まで最大 2 秒待ってから返す。</summary>
        public static void Show()
        {
            try
            {
                if (_thread != null) return;
                _ready.Reset();
                _thread = new Thread(() =>
                {
                    try
                    {
                        _window = new SplashWindow();
                        _window.Show();
                        _ready.Set();
                        Dispatcher.Run(); // このスレッド専用のメッセージループ (InvokeShutdown で終了)
                    }
                    catch
                    {
                        _ready.Set(); // 生成失敗時も Show() の待機を解放する
                    }
                });
                _thread.SetApartmentState(ApartmentState.STA);
                _thread.IsBackground = true;
                _thread.Start();
                _ready.Wait(2000);
            }
            catch { /* fail-open: スプラッシュ障害で起動を止めない */ }
        }

        /// <summary>ステータス文言を更新する (スプラッシュスレッドへマーシャル)。</summary>
        public static void SetStatus(string text)
        {
            try
            {
                SplashWindow w = _window;
                if (w == null) return;
                w.Dispatcher.BeginInvoke(new Action(() => w.SetStatus(text)));
            }
            catch { /* cosmetic */ }
        }

        /// <summary>スプラッシュを閉じて専用スレッドの Dispatcher を終了する。冪等 (二重呼出し可)。</summary>
        public static void Close()
        {
            try
            {
                SplashWindow w = _window;
                _window = null;
                _thread = null;
                if (w == null) return;
                w.Dispatcher.BeginInvoke(new Action(() =>
                {
                    try { w.Close(); } catch { /* 既に閉じている等は無視 */ }
                    try { w.Dispatcher.InvokeShutdown(); } catch { }
                }));
            }
            catch { /* fail-open */ }
        }
    }
}
