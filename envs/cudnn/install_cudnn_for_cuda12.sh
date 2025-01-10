#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定义文件 URL 和名称
CUDNN_URL="https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-9.6.0.74_cuda12-archive.tar.xz"
CUDNN_FILE="cudnn-linux-x86_64-9.6.0.74_cuda12-archive.tar.xz"
CUDA_PATH="/usr/local/cuda"

# 函数：打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 函数：检查命令是否执行成功
check_status() {
    if [ $? -ne 0 ]; then
        print_message "$RED" "错误: $1"
        exit 1
    fi
}

# 下载 cuDNN 文件
print_message "$GREEN" "Step 1: 下载 cuDNN 文件..."
if [ -f "$CUDNN_FILE" ]; then
    print_message "$YELLOW" "文件 $CUDNN_FILE 已存在，跳过下载..."
else
    wget "$CUDNN_URL" -O "$CUDNN_FILE"
    check_status "下载 $CUDNN_FILE 失败"
fi

# 解压文件
print_message "$GREEN" "Step 2: 解压 cuDNN 文件..."
tar -xf "$CUDNN_FILE"
check_status "解压 $CUDNN_FILE 失败"

# 确认解压目录是否存在
CUDNN_ARCHIVE_DIR="cudnn-linux-x86_64-9.6.0.74_cuda12-archive"
if [ ! -d "$CUDNN_ARCHIVE_DIR" ]; then
    print_message "$RED" "cuDNN 解压目录 $CUDNN_ARCHIVE_DIR 不存在"
    exit 1
fi

# 安装 cuDNN 文件
print_message "$GREEN" "Step 3: 安装 cuDNN 到 CUDA 目录 ($CUDA_PATH)..."
if [ -d "$CUDA_PATH/include" ] && [ -d "$CUDA_PATH/lib64" ]; then
    cp -P "$CUDNN_ARCHIVE_DIR"/include/cudnn*.h "$CUDA_PATH/include/"
    check_status "复制 cuDNN 头文件失败"

    cp -P "$CUDNN_ARCHIVE_DIR"/lib/libcudnn* "$CUDA_PATH/lib64/"
    check_status "复制 cuDNN 库文件失败"

    chmod a+r "$CUDA_PATH/include/cudnn*.h" "$CUDA_PATH/lib64/libcudnn*"
else
    print_message "$RED" "CUDA 路径 $CUDA_PATH 不存在，请检查您的 CUDA 安装"
    exit 1
fi

# 更新动态链接器缓存
print_message "$GREEN" "Step 4: 更新动态链接器缓存..."
ldconfig
check_status "更新动态链接器缓存失败"

# 验证安装
print_message "$GREEN" "Step 5: 验证 cuDNN 安装..."
if [ -f "$CUDA_PATH/include/cudnn.h" ] && [ -f "$CUDA_PATH/lib64/libcudnn.so" ]; then
    print_message "$GREEN" "cuDNN 安装成功！"
else
    print_message "$RED" "cuDNN 安装失败，请检查日志"
    exit 1
fi

# 清理临时文件
print_message "$GREEN" "Step 6: 清理临时文件..."
rm -rf "$CUDNN_FILE" "$CUDNN_ARCHIVE_DIR"

print_message "$YELLOW" "cuDNN 安装完成，可以开始使用了！"
