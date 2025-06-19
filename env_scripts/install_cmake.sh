#!/bin/bash

# 设置 -e 选项，表示如果任何命令失败，脚本将立即退出
set -e

# 定义要安装的 CMake 版本和下载链接
CMAKE_VERSION="4.0.3"
CMAKE_TAR_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
INSTALL_PREFIX="/usr/local" # CMake 的安装路径，通常推荐 /usr/local

echo "🟢 卸载系统和旧的 CMake 安装..."
# 尝试通过 apt 卸载 CMake 及其数据
sudo apt remove --purge -y cmake cmake-data || true # 允许此命令失败，如果 CMake 未安装

# 彻底删除可能存在的旧 CMake 文件
# 注意：这些命令需要小心，确保你了解其影响
echo "🟢 移除旧的 CMake 文件 (如果存在)..."
sudo rm -rf /usr/local/bin/cmake
sudo rm -rf /usr/local/share/cmake*
sudo rm -rf /usr/bin/cmake
sudo rm -rf /usr/share/cmake*
# 移除可能存在的缓存（虽然不常见，但可以避免一些路径问题）
sudo rm -rf ~/.cmake

echo "🟢 更新系统软件包..."
sudo apt update && sudo apt upgrade -y

echo "🟢 安装编译依赖..."
# build-essential 包含了 gcc, g++, make 等基本编译工具
# libssl-dev 用于 SSL 支持，CMake 下载依赖时可能需要
# libncurses-dev 用于 ccmake 和 cpack 等工具（可选但推荐）
# wget 用于下载文件
sudo apt install -y build-essential libssl-dev libncurses-dev wget

echo "🟢 创建临时目录并进入..."
# 创建一个临时目录用于下载和编译，保持 ~/ 目录整洁
INSTALL_DIR_BASE=~/cmake_install_temp
mkdir -p "$INSTALL_DIR_BASE"
cd "$INSTALL_DIR_BASE"

echo "🟢 下载 CMake 源代码 (${CMAKE_VERSION})..."
wget "$CMAKE_TAR_URL"

echo "🟢 解压 CMake 源代码..."
tar -zxvf cmake-${CMAKE_VERSION}.tar.gz

echo "🟢 进入 CMake 源代码目录..."
cd cmake-${CMAKE_VERSION}

echo "🟢 配置并构建 CMake..."
# 创建 build 目录并在其中进行构建，以保持源代码目录的清洁
mkdir -p build
cd build

# 运行 bootstrap 脚本进行配置
# --prefix 指定安装路径，推荐 /usr/local
../bootstrap --prefix="${INSTALL_PREFIX}"

# 使用所有 CPU 核心并行编译，加快速度
make -j$(nproc)

echo "🟢 安装 CMake..."
# 将编译好的 CMake 安装到指定路径
sudo make install

# 更新共享库缓存（尽管 CMake 通常不需要 ldconfig，但保持一致性）
sudo ldconfig

echo "🟢 清理临时文件..."
cd "$INSTALL_DIR_BASE" # 返回到临时目录的父目录
rm -rf cmake-${CMAKE_VERSION}.tar.gz # 删除下载的压缩包
rm -rf cmake-${CMAKE_VERSION}        # 删除解压后的源代码目录
cd ~ # 返回到用户主目录

echo "🟢 验证安装..."
# 检查 CMake 版本，确保安装成功且为新版本
cmake --version

echo "🎉 CMake ${CMAKE_VERSION} 安装完成！"

echo "👍 提示：如果命令行仍然显示旧的 CMake 版本，请尝试关闭并重新打开终端，或者运行 'hash -r' 命令来刷新 shell 的命令缓存。"
