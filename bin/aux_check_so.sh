#!/bin/bash

# 检查帮助信息
usage() {
    echo "Usage: $0 <library.so>"
    echo "  <library.so>  The .so file to check"
}

# 检查是否提供了文件名
if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

lib_name=$1
basename_lib=$(basename "$lib_name")

# 检查是否已加载到 ldconfig 缓存中
if ldconfig -p | grep -q "$basename_lib"; then
    echo "$lib_name is loaded in ldconfig cache."
    ldconfig -p | grep "$basename_lib"
else
    echo "Error: $lib_name not found in ldconfig cache!"

    # 使用 locate 命令查找库文件
    echo "Attempting to locate the library file..."
    locate "$basename_lib"

    echo "To add the library to ldconfig, follow these steps:"
    echo "1. Find the directory where the .so file is located."
    echo "2. Add the directory to /etc/ld.so.conf or create a new file in /etc/ld.so.conf.d/."
    echo "3. Run 'sudo ldconfig' to update the ldconfig cache."

    exit 1
fi

