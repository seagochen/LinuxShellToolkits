#!/bin/bash

# Update package list.
sudo apt-get update && sudo apt-get upgrade -y

# Install basic packages.
sudo apt-get install -y build-essential cmake git pkg-config

# Install bc. It is a command-line calculator that is used in some scripts.
sudo apt-get install bc

# Use Pip to install the Python packages required by the scripts.
# moviepy, PIL, chardet
pip3 install moviepy pillow chardet -i https://mirrors.aliyun.com/pypi/simple/