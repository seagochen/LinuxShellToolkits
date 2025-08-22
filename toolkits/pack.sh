#!/bin/bash
# 打包脚本：生成 shells.tar.gz，自动排除不需要的目录

# 输出文件名（可修改）
OUTPUT="shells.tar.gz"

# 可编辑的排除目录列表
EXCLUDE_DIRS=(
  ".git"
)

# 构造 tar 的排除参数
EXCLUDE_ARGS=()
for d in "${EXCLUDE_DIRS[@]}"; do
  EXCLUDE_ARGS+=( "--exclude=./$d" )
done

# 执行打包
echo "📦 正在打包工程，排除目录: ${EXCLUDE_DIRS[*]}"
tar -czvf "$OUTPUT" "${EXCLUDE_ARGS[@]}" .

echo "✅ 打包完成: $OUTPUT"

