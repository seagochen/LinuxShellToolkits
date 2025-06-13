#!/bin/bash

# 引数の数を確認
if [ $# -ne 1 ]; then
  echo "使い方: $0 [ディレクトリのパス]"
  exit 1
fi

# 引数で渡されたディレクトリが存在するか確認
TARGET_DIR=$1

if [ ! -d "$TARGET_DIR" ]; then
  echo "エラー: $TARGET_DIR は存在しません。"
  exit 1
fi

echo "ディレクトリおよびファイルのパーミッションをリセットしています: $TARGET_DIR"

# ディレクトリのパーミッションを 755 に変更し、変更されたディレクトリを出力
find "$TARGET_DIR" -type d -print -exec chmod 755 {} \; || { echo "ディレクトリのパーミッション変更に失敗しました"; exit 1; }

# ファイルのパーミッションを 644 に変更し、変更されたファイルを出力
find "$TARGET_DIR" -type f -print -exec chmod 644 {} \; || { echo "ファイルのパーミッション変更に失敗しました"; exit 1; }

echo "パーミッションが正常にリセットされました。"

