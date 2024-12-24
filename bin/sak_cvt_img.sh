#!/bin/bash

# 检查参数数量是否足够
if [ $# -lt 5 ]; then
  echo "Usage: $0 <filepath> -src <source_format> -dst <destination_format>"
  exit 1
fi

# 初始化变量
filepath=""
src=""
dst=""

# 解析输入参数
while [[ $# -gt 0 ]]; do
  case $1 in
    -src)
      src="$2"
      shift 2
      ;;
    -dst)
      dst="$2"
      shift 2
      ;;
    *)
      filepath="$1"
      shift
      ;;
  esac
done

# 检查文件路径、源格式和目标格式是否都已提供
if [ -z "$filepath" ] || [ -z "$src" ] || [ -z "$dst" ]; then
  echo "Error: Missing parameters. Please provide filepath, source format, and destination format."
  exit 1
fi

# 设置 Python 脚本路径
script_dir="/opt/sak/pytools"

# 根据源格式和目标格式选择对应的 Python 脚本
case "$src-$dst" in
  jpg-png)
    python3 "$script_dir/cvt_jpg2png.py" "$filepath"
    ;;
  png-jpg)
    python3 "$script_dir/cvt_png2jpg.py" "$filepath"
    ;;
  webp-png)
    python3 "$script_dir/cvt_webp2png.py" "$filepath"
    ;;
  *)
    echo "Error: Unsupported conversion from $src to $dst"
    exit 1
    ;;
esac

echo "Conversion from $src to $dst completed successfully."
