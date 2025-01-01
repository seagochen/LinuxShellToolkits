#!/bin/bash


# Append SAK environment variables to the .bashrc file
CUDA_PATH=/usr/local/cuda
echo ".bashrcにCUDAのことを書き込み中..."
echo "# CUDA Environment" >> ~/.bashrc
echo "export PATH=\$PATH:$CUDA_PATH/bin" >> ~/.bashrc
echo "完了しました。"

# Source the .bashrc file
source ~/.bashrc