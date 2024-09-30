#!/bin/bash

# 显示帮助信息
usage() {
    echo "Usage: $0 [-h]"
    echo "  -h  Show this help message"
}

# 计算文件大小
format_size() {
    local size=$1
    if [ "$size" -ge 1073741824 ]; then
        echo "$(printf "%.2f" $(echo "$size/1073741824" | bc)) GB"
    elif [ "$size" -ge 1048576 ]; then
        echo "$(printf "%.2f" $(echo "$size/1048576" | bc)) MB"
    elif [ "$size" -ge 1024 ]; then
        echo "$(printf "%.2f" $(echo "$size/1024" | bc)) KB"
    else
        echo "$size B"
    fi
}

# 获取文件权限
format_permissions() {
    local perms=$(stat -c "%A" "$1")
    echo "$perms"
}

# 获取文件所有者
format_owner() {
    local owner=$(stat -c "%U" "$1")
    echo "$owner"
}

# 获取文件组
format_group() {
    local group=$(stat -c "%G" "$1")
    echo "$group"
}

# 获取文件大小
format_size_detailed() {
    local size=$(stat -c "%s" "$1")
    echo "$(format_size "$size")"
}

# 计算目录总大小
calculate_directory_size() {
    local dir=$1
    local size=$(du -sb "$dir" | cut -f1)
    echo "$(format_size "$size")"
}

# 主功能实现
list_files() {
    local path=$1

    # 打印表头
    printf "%-6s %-15s %-6s %-6s %-6s %-10s %s\n" "Type" "Permissions" "Links" "Owner" "Group" "Size" "Name"
    echo "---------------------------------------------------------------------------"

    # 遍历目录中的文件和目录，包括隐藏的文件和目录
    for item in "$path"/.* "$path"/*; do

        if [ "$item" = "$path"/. ] || [ "$item" = "$path"/.. ]; then
            continue
        fi

        if [ -d "$item" ]; then
            # 计算文件夹的总大小
            local folder_size=$(calculate_directory_size "$item")
            local perm=$(format_permissions "$item")
            local owner=$(format_owner "$item")
            local group=$(format_group "$item")
            local name=$(basename "$item")
            printf "%-6s %-15s %-6d %-6s %-6s %-10s %s\n" "d" "$perm" "$(stat -c "%h" "$item")" "$owner" "$group" "$folder_size" "$name/"
        elif [ -f "$item" ]; then
            # 计算文件的大小
            local file_size=$(stat -c%s "$item")
            local perm=$(format_permissions "$item")
            local owner=$(format_owner "$item")
            local group=$(format_group "$item")
            local size=$(format_size_detailed "$item")
            local name=$(basename "$item")
            printf "%-6s %-15s %-6d %-6s %-6s %-10s %s\n" "-" "$perm" "1" "$owner" "$group" "$size" "$name"
        fi
    done | sort -k7,7
}

# 解析选项
while getopts "h" opt; do
    case ${opt} in
        h )
            usage
            exit 0
            ;;
        \? )
            usage
            exit 1
            ;;
    esac
done

shift $((OPTIND -1))

# 获取工作目录
working_dir=${1:-$(pwd)}

# 执行文件列出函数
list_files "$working_dir"

