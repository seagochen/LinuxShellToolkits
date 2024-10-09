#!/bin/bash

# Clone the base environment.
conda create --name base --clone base_backup

# Create the base environment for machine learning.
conda create --name base_ml python=3.10

# Activate the base_ml environment.
conda activate base_ml

# Install the required packages.
conda install -y numpy pandas \
                    scikit-learn \
                    matplotlib \
                    seaborn \
                    scipy \
                    pywidgets \
                    tqdm \ 
                    pillow \
                    opencv

# Install JupyterLab.
conda install -y -c conda-forge jupyterlab

# Deactivate the base_ml environment.
conda deactivate

# Create the base environment for deep learning.
conda create --name base_torch --clone base_ml

# Activate the base_torch environment.
conda activate base_torch

# Ask the user which version of PyTorch to install.
echo "Which version of PyTorch would you like to install?"
echo "1. CPU"
echo "2. GPU - CUDA 11.8"
echo "3. GPU - CUDA 12.4"
read -p "Enter the number of your choice: " choice

# Install the selected version of PyTorch.
if [ $choice -eq 1 ]; then
    conda install pytorch torchvision torchaudio cpuonly -c pytorch
elif [ $choice -eq 2 ]; then
    conda install pytorch torchvision torchaudio pytorch-cuda=11.8 -c pytorch -c nvidia
elif [ $choice -eq 3 ]; then
    conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia
else
    echo "Invalid choice. Exiting..."
    exit 1
fi

# Deactivate the base_torch environment.
conda deactivate

# Create the base environment for TensorFlow.
conda create --name base_tf --clone base_ml

# Activate the base_tf environment.
conda activate base_tf

# Install TensorFlow with CPU support only.
conda install tensorflow

# Deactivate the base_tf environment.
conda deactivate

# Create the environment for YOLO 
conda create --name note_yolo --clone base_torch

# Activate the note_yolo environment.
conda activate note_yolo

# Install the required packages.
conda install -y -c conda-forge ultralytics

# Deactivate the base_yolo environment.
conda deactivate

# Create the environment for Transformers
conda create --name note_transformers --clone base_torch

# Activate the note_transformers environment.
conda activate note_transformers

# Install the required packages.
conda install -y -c huggingface -c conda-forge datasets

# Deactivate the base_transformers environment.
conda deactivate