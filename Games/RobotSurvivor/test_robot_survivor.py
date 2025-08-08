#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RobotSurvivor 無敵バグ調査用テストプログラム
ワーキングディレクトリの違いによるバグを検証
"""

import os
import sys
import time
import json
from datetime import datetime

def log_startup_info():
    """起動時の環境情報をログに出力"""
    log_data = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "working_directory": os.getcwd(),
        "executable_path": sys.argv[0],
        "command_line_args": sys.argv,
        "python_executable": sys.executable,
        "script_directory": os.path.dirname(os.path.abspath(__file__)),
        "relative_path_test": {
            "current_dir_files": os.listdir(".") if os.path.exists(".") else "ERROR",
            "parent_dir_files": os.listdir("..") if os.path.exists("..") else "ERROR"
        }
    }
    
    # ログファイルに書き出し
    log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "game_log.json")
    
    try:
        with open(log_file, "w", encoding="utf-8") as f:
            json.dump(log_data, f, ensure_ascii=False, indent=2)
        print(f"ログファイル作成: {log_file}")
    except Exception as e:
        print(f"ログファイル作成エラー: {e}")
    
    return log_data

def simulate_game():
    """ゲームの動作をシミュレート"""
    print("=== Robot Survivor テスト版 ===")
    print("無敵バグ調査用プログラム")
    print()
    
    # 起動情報をログ出力
    startup_info = log_startup_info()
    print(f"作業ディレクトリ: {startup_info['working_directory']}")
    print(f"実行ファイルパス: {startup_info['executable_path']}")
    print()
    
    # ゲームシミュレーション
    print("ゲーム開始...")
    hp = 100
    
    for i in range(10):
        hp -= 10
        print(f"タイマー: {i+1}秒 | HP: {hp}")
        time.sleep(1)
        
        # HP0になった時の動作
        if hp <= 0:
            print("\n!!! HP 0 に到達 !!!")
            
            # 設定ファイルやリソースファイルの読み込みテスト
            test_relative_paths(startup_info['working_directory'])
            
            print("ゲームオーバー画面を表示すべき...")
            print("タイマー停止")
            
            # 無敵バグの検証
            if check_invincibility_bug(startup_info['working_directory']):
                print("⚠️ 無敵バグが発生しています！")
            else:
                print("✅ 正常にゲームオーバー処理が実行されました")
            
            break
    
    print("\nテスト完了 - 5秒後に終了します")
    time.sleep(5)

def test_relative_paths(working_dir):
    """相対パスでのファイルアクセステスト"""
    print("\n--- 相対パス確認テスト ---")
    
    # よくあるゲーム設定ファイル
    test_files = [
        "config.ini",
        "settings.json", 
        "data/gamedata.dat",
        "../common/config.txt",
        "saves/savefile.dat"
    ]
    
    for file_path in test_files:
        if os.path.exists(file_path):
            print(f"✅ 見つかった: {file_path}")
        else:
            print(f"❌ 見つからない: {file_path}")

def check_invincibility_bug(working_dir):
    """無敵バグの判定ロジック（簡易版）"""
    
    # 作業ディレクトリによる判定
    if "RobotSurvivor" in working_dir:
        # ゲームディレクトリが作業ディレクトリの場合（ランチャー経由）
        print("検出: ランチャー経由の起動パターン")
        return True
    else:
        # 他のディレクトリが作業ディレクトリの場合（直接起動）
        print("検出: 直接起動パターン")
        return False

if __name__ == "__main__":
    simulate_game()