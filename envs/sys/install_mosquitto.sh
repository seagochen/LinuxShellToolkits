#!/bin/bash

# 更新软件包列表
echo "Updating package list..."
sudo apt update

# 安装 Mosquitto 和相关开发包
echo "Installing Mosquitto and development packages..."
sudo apt install -y mosquitto mosquitto-clients libmosquitto-dev

# 启动并设置 Mosquitto 服务为开机自启
echo "Starting and enabling Mosquitto service..."
sudo systemctl start mosquitto
sudo systemctl enable mosquitto

# 检查 Mosquitto 服务状态
echo "Checking Mosquitto service status..."
sudo systemctl status mosquitto --no-pager

echo "Mosquitto installation completed!"
