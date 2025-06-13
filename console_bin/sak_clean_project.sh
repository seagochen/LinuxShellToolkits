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

echo "指定されたディレクトリ内の .o ファイルと macOS のシステムファイル (.DS_Store) を削除しています: $TARGET_DIR"

# .o ファイルを削除
find "$TARGET_DIR" -name "*.o" -print -delete || { echo ".o ファイルの削除に失敗しました"; exit 1; }

# .pycファイルを削除
find "$TARGET_DIR" -name "*.pyc" -print -delete || { echo ".pyc ファイルの削除に失敗しました"; exit 1; }

# .DS_Store ファイルを削除
find "$TARGET_DIR" -name ".DS_Store" -print -delete || { echo ".DS_Store ファイルの削除に失敗しました"; exit 1; }

echo "クリーンアップが完了しました。"

