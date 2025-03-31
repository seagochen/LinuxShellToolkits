#!/bin/bash

set -e  # 遇到错误就停止脚本执行

echo "� 卸载系统已安装的 protobuf..."
sudo apt remove --purge -y protobuf-compiler libprotobuf-dev python3-protobuf
sudo rm -rf /usr/local/bin/protoc
sudo rm -rf /usr/bin/protoc
sudo rm -rf /usr/include/google/protobuf
sudo rm -rf /usr/lib/x86_64-linux-gnu/libprotobuf*
sudo rm -rf /usr/local/lib/libprotobuf*
sudo rm -rf /usr/lib/python3/dist-packages/google/protobuf
sudo rm -rf ~/.local/lib/python3.*/site-packages/google/protobuf

echo "� 更新系统..."
sudo apt update && sudo apt upgrade -y

echo "� 安装编译依赖..."
sudo apt install -y cmake g++ make git unzip

echo "� 克隆 protobuf 仓库..."
cd ~
rm -rf protobuf
git clone --depth=1 --branch v3.23.4 https://github.com/protocolbuffers/protobuf.git
cd protobuf

echo "� 更新 submodules..."
git submodule update --init --recursive

echo "�️ 开始编译 protobuf..."
mkdir -p build
cd build
cmake ..
make -j$(nproc)

echo "� 安装 protobuf..."
sudo make install
sudo ldconfig

echo "✅ 验证安装..."
protoc --version

echo "� 安装 Python protobuf..."
pip3 install --no-cache-dir --upgrade protobuf

echo "✅ 验证 Python protobuf 版本..."
python3 -c "import google.protobuf; print(google.protobuf.__version__)"

echo "� 安装完成！"

