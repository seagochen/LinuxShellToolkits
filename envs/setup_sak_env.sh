#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then 
  echo "このスクリプトを実行するには root 権限が必要です。"
  exit 1
fi

# Create a folder in /opt
sudo mkdir -p /opt/sak

# Copy the contents in this project into /opt/sak
sudo cp -r . /opt/sak

# Append SAK environment variables to the .bashrc file
SAK_PATH=/opt/sak
echo ".bashrcにSAKのことを書き込み中..."
echo "# SAK Environment" >> ~/.bashrc
echo "export PATH=\$PATH:$SAK_PATH/bin" >> ~/.bashrc
echo "完了しました。"

# Source the .bashrc file
source ~/.bashrc