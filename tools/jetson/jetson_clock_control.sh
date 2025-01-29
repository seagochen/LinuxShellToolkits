#!/bin/bash

# スクリプトを root 権限で実行しているか確認
if [ "$EUID" -ne 0 ]; then 
    echo "このスクリプトを実行するには root 権限が必要です。"
    exit 1
fi

CONFIG_FILE="/root/.jetsonclocks_conf.txt"
BACKUP_FILE="/root/jetson_clocks_backup.txt"

# 設定ファイルのセットアップ（作成・バックアップ）
setup_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "クロック設定ファイルが存在しません。新しく作成します..."
        jetson_clocks --store
        if [ $? -ne 0 ]; then
            echo "設定ファイルの作成に失敗しました。"
            exit 1
        fi
        echo "設定ファイルを作成しました: $CONFIG_FILE"
    fi

    if [ ! -f "$BACKUP_FILE" ]; then
        echo "初回バックアップを作成中..."
        cp "$CONFIG_FILE" "$BACKUP_FILE" && chmod 444 "$BACKUP_FILE"
        if [ $? -eq 0 ]; then
            echo "バックアップを作成しました: $BACKUP_FILE"
        else
            echo "バックアップの作成に失敗しました。"
        fi
    fi
}

# クロック設定を変更
set_clocks() {
    case $1 in
        1)  # 自動設定
            MODE=$(nvpmodel -q | grep -oP '(?<=Power Mode: ).*')
            if [[ "$MODE" == "MAXN" ]]; then
                echo "全性能モード: クロック最大化"
                jetson_clocks
            elif [[ "$MODE" == "MODE_10W" ]]; then
                echo "省電力モード: クロックリセット"
                jetson_clocks --restore
            else
                echo "不明なモードです。手動で確認してください。"
                exit 1
            fi
            ;;
        2)  # 省電力モード
            echo "省電力モードに設定します..."
            jetson_clocks --restore
            ;;
        3)  # 全性能モード
            echo "全性能モードに設定します..."
            jetson_clocks
            ;;
        0)  # 現在のクロックを確認
            echo "現在のクロックを確認します..."
            jetson_clocks --show
            ;;
        *)  
            echo "無効な選択です。"
            exit 1
            ;;
    esac
    echo "クロック設定が完了しました。"
}

# メニュー表示
show_menu() {
    echo "Jetson Nano クロック設定:"
    echo "1. 自動設定（MAXN: 最大, MODE_10W: 省電力）"
    echo "2. 省電力モード"
    echo "3. 全性能モード"
    echo "0. 現在のクロックを確認"
}

# メイン処理
main() {
    setup_config
    while true; do
        show_menu
        read -p "選択 (0-3): " choice
        set_clocks "$choice"

        # 再起動確認
        read -p "変更を有効にするために再起動しますか？ (y/n): " reboot_choice
        case "$reboot_choice" in
            y|Y) echo "システムを再起動します..." && reboot ;;
            n|N) echo "再起動をキャンセルしました。" ;;
            *)   echo "無効な入力です。再起動をキャンセルしました。" ;;
        esac
        break
    done
}

# 実行
main
