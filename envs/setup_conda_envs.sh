#!/bin/bash

# 确保 Conda 初始化
if ! command -v conda &> /dev/null; then
    echo "Condaをインストールしない、又はPATHの設置は違いです、確認してください。"
    exit 1
fi

set -e

# 备份 base 环境
echo "base環境をバックアップ中..."
conda create --name base_backup --clone base

# 创建并激活 base_ml 环境
echo "base_ml環境を配置中..."
conda create --name base_ml python=3.10 -y
conda install -n base_ml numpy pandas scikit-learn matplotlib seaborn scipy ipywidgets tqdm pillow opencv -y
conda install -n base_ml -c conda-forge jupyterlab -y

# 创建 base_torch 并安装 PyTorch
echo "base_torch環境を配置中..."
conda create --name base_torch --clone base_ml -y

echo "PyTorchのバージョンを選んでください："
echo "1. CPU"
echo "2. GPU - CUDA 11.8"
echo "3. GPU - CUDA 12.4"
read -p "選択は: " choice

case $choice in
  1)
    conda install -n base_torch pytorch torchvision torchaudio cpuonly -c pytorch -y
    ;;
  2)
    conda install -n base_torch pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia -y
    ;;
  3)
    conda install -n base_torch pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia -y
    ;;
  *)
    echo "無効の選択肢，退出..."
    exit 1
    ;;
esac

# 创建并安装 AI 開発
echo "note_ai環境を作り中..."
conda create --name note_ai --clone base_torch -y
conda install -n note_ai -c conda-forge ultralytics datasets huggingface -y

echo "全ての環境は準備できました。"
