#!/bin/bash

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