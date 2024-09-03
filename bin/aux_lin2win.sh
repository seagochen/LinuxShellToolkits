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

# ファイルをWindows形式に変換（LF -> CRLF）
echo "$TARGET_FILE を Windows 形式 (CRLF) に変換しています..."

# sed を使って、Linuxの LF 改行を Windows の CRLF に変換
sed -i 's/$/\r/' "$TARGET_FILE"

echo "変換が完了しました。"

