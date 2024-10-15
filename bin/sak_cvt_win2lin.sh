#!/bin/bash

# 引数の数を確認
if [ $# -ne 1 ]; then
  echo "使い方: $0 [ファイルのパス]"
  exit 1
fi

# 引数で渡されたファイルが存在するか確認
TARGET_FILE=$1

if [ ! -f "$TARGET_FILE" ]; then
  echo "エラー: $TARGET_FILE は存在しません。"
  exit 1
fi

# Pythonスクリプト(/opt/sak/pybin/dos2unix.py)を使って、Windowsの CRLF 改行を Linux の LF に変換
if [ ! -f /opt/sak/pybin/dos2unix.py ]; then
  echo "エラー: /opt/sak/pybin/dos2unix.py が見つかりません。"
  exit 1
else
  echo "$TARGET_FILE を Windows 形式 (CRLF) に変換しています..."
  python3 /opt/sak/pybin/dos2unix.py "$TARGET_FILE"
fi
