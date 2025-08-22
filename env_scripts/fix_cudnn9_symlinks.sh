#!/bin/bash

LIB_PATH="/usr/local/cuda/targets/x86_64-linux/lib"

# 备份原始文件
mkdir -p ~/cuda_backup
mv $LIB_PATH/libcudnn*.so.9 ~/cuda_backup/

# 进入 CUDA 目录
cd $LIB_PATH

# 重新创建符号链接
ln -s libcudnn.so.9 libcudnn.so
ln -s libcudnn_adv.so.9 libcudnn_adv.so
ln -s libcudnn_cnn.so.9 libcudnn_cnn.so
ln -s libcudnn_ops.so.9 libcudnn_ops.so
ln -s libcudnn_graph.so.9 libcudnn_graph.so
ln -s libcudnn_engines_runtime_compiled.so.9 libcudnn_engines_runtime_compiled.so
ln -s libcudnn_engines_precompiled.so.9 libcudnn_engines_precompiled.so
ln -s libcudnn_heuristic.so.9 libcudnn_heuristic.so

# 更新库缓存
ldconfig

echo "cuDNN 符号链接修复完成！"
