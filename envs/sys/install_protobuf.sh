#!/bin/bash

# 更新软件包列表
echo "Updating package list..."
sudo apt update

# 安装 Protobuf 编译器和开发库
echo "Installing Protobuf compiler and development libraries..."
sudo apt install -y protobuf-compiler libprotobuf-dev libprotoc-dev

# 检查安装的 Protobuf 版本
echo "Checking installed Protobuf version..."
protoc --version

echo "Protobuf installation completed!"
