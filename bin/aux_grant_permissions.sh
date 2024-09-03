#!/bin/bash

# 引数の数を確認
if [ $# -ne 1 ]; then
  echo "使い方: $0 [grant|revoke]"
  echo "  grant  - .sh ファイルに可执行権限を付与します"
  echo "  revoke - .sh ファイルの可执行権限を取り消します"
  exit 1
fi

# 操作の選択
if [ "$1" == "grant" ]; then
  # 現在のディレクトリ内のすべての .sh ファイルに可执行権限を付与
  echo "現在のディレクトリ内のすべての .sh ファイルに可执行権限を付与しています..."
  find . -name "*.sh" -type f -print -exec chmod +x {} \;
  echo "可执行権限を正常に付与しました。"

elif [ "$1" == "revoke" ]; then
  # 現在のディレクトリ内のすべての .sh ファイルの可执行権限を取り消し
  echo "現在のディレクトリ内のすべての .sh ファイルの可执行権限を取り消しています..."
  find . -name "*.sh" -type f -print -exec chmod -x {} \;
  echo "可执行権限を正常に取り消しました。"

else
  # 不正な引数が渡された場合
  echo "エラー: 無効な引数です。"
  echo "使い方: $0 [grant|revoke]"
  echo "  grant  - .sh ファイルに可执行権限を付与します"
  echo "  revoke - .sh ファイルの可执行権限を取り消します"
  exit 1
fi

