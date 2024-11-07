#!/bin/bash

# Add "# CUDA Environment Variables" to the .bashrc file
echo "# CUDA Environment Variables" >> ~/.bashrc

# Append CUDA environment variables to the .bashrc file
CUDA_PATH=/usr/local/cuda
echo "export PATH=\$PATH:$CUDA_PATH/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$CUDA_PATH/lib64" >> ~/.bashrc

# Source the .bashrc file
source ~/.bashrc