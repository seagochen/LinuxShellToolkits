#!/bin/bash

# 更新软件包列表
echo "Updating package list..."
sudo apt update

# 安装 YAML C 开发库
echo "Installing YAML C development libraries..."
sudo apt install -y libyaml-dev

# 检查安装是否成功
echo "Checking YAML library installation..."
dpkg -l | grep libyaml-dev

echo "YAML C development libraries installation completed!"
