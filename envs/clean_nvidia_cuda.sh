#!/bin/bash

# 1. 首先完全卸载 nvidia-dkms-520
apt-get --purge remove -y nvidia-dkms-520
apt-get --purge remove -y cuda-drivers-520

# 2. 清理 DKMS
dkms remove -m nvidia -v 520.61.05 --all
dkms status | grep nvidia | while read line; do
    module=$(echo $line | cut -d',' -f1)
    version=$(echo $line | cut -d',' -f2 | tr -d ' ')
    dkms remove -m $module -v $version --all
done

# 3. 移除所有 NVIDIA 相关的内核模块
lsmod | grep nvidia | awk '{print $1}' | while read module; do
    rmmod $module 2>/dev/null
done

# 4. 清理 CUDA 相关目录
rm -rf /usr/local/cuda*
rm -rf /usr/local/lib/cuda*

# 5. 清理包管理器缓存
apt-get clean
apt-get autoclean
apt-get autoremove -y

# 6. 更新 initramfs
update-initramfs -u

# 7. 确保删除所有相关配置文件
rm -rf /etc/modprobe.d/nvidia*
rm -rf /etc/X11/xorg.conf.d/*nvidia*