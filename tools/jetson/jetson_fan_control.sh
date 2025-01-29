#!/bin/bash

# スクリプトを root 権限で実行しているか確認
if [ "$EUID" -ne 0 ]; then 
    echo "このスクリプトを実行するには root 権限が必要です。"
    exit 1
fi

# ファン制御
control_fan() {
    case $1 in
        on)
            echo "ファンを強制起動します..."
            jetson_clocks --fan && echo "ファンを強制起動しました。" || echo "ファンの起動に失敗しました。"
            ;;
        off)
            echo "ファンを停止します..."
            jetson_clocks --restore && echo "ファンを停止しました。" || echo "ファンの停止に失敗しました。"
            ;;
        *)  
            echo "無効なファン制御オプションです。"
            exit 1
            ;;
    esac
}

# メニュー表示
show_menu() {
    echo "Jetson Nano ファン制御:"
    echo "1. ファンを強制起動"
    echo "2. ファンを停止"
}

# メイン処理
main() {
    while true; do
        show_menu
        read -p "選択 (1-2): " choice

        case $choice in
            1) control_fan "on" ;;
            2) control_fan "off" ;;
            *) echo "無
