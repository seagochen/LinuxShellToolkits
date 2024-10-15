#!/bin/bash

# Append CUDA environment variables to the .bashrc file
CUDA_PATH=/usr/local/cuda
echo "export PATH=\$PATH:$CUDA_PATH/bin" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$CUDA_PATH/lib64" >> ~/.bashrc

# Source the .bashrc file
source ~/.bashrc