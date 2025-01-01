#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 定义文件URL和名称
CUDA_PIN_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin"
CUDA_DEB_URL="https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb"
CUDA_PIN_FILE="cuda-ubuntu2204.pin"
CUDA_DEB_FILE="cuda-repo-ubuntu2204-12-6-local_12.6.3-560.35.05-1_amd64.deb"

# 函数：打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 函数：下载文件
download_file() {
    local url=$1
    local filename=$2
    
    if [ -f "$filename" ]; then
        print_message "$YELLOW" "文件 $filename 已存在，跳过下载..."
    else
        print_message "$GREEN" "正在下载 $filename ..."
        wget "$url" -O "$filename"
        if [ $? -ne 0 ]; then
            print_message "$RED" "下载 $filename 失败!"
            exit 1
        fi
    fi
}

# 函数：检查命令是否执行成功
check_status() {
    if [ $? -ne 0 ]; then
        print_message "$RED" "错误: $1"
        exit 1
    fi
}

# 函数：清理NVIDIA和CUDA相关文件
clean_nvidia_cuda() {
    print_message "$GREEN" "正在清理旧的NVIDIA和CUDA文件..."
    
    # 停止可能在运行的NVIDIA服务
    systemctl stop nvidia-*
    
    # 卸载NVIDIA和CUDA包
    apt-get --purge remove -y "*nvidia*" "*cuda*" "*cudnn*"
    apt-get autoremove -y
    apt-get autoclean
    
    # 删除NVIDIA和CUDA相关目录
    rm -rf /usr/local/cuda*
    rm -rf /usr/lib/x86_64-linux-gnu/nvidia/
    rm -rf /usr/lib/x86_64-linux-gnu/vdpau/
    rm -rf /etc/OpenCL/
    rm -rf /usr/share/nvidia/
    
    # 删除可能存在的DKMS模块
    rm -rf /var/lib/dkms/nvidia*
    
    # 更新动态链接器缓存
    ldconfig
    
    print_message "$GREEN" "清理完成"
}

# 开始安装过程
print_message "$GREEN" "开始安装 CUDA 12.6 ..."

# 0. 清理旧的安装
print_message "$GREEN" "Step 0: 清理旧的NVIDIA和CUDA安装..."
clean_nvidia_cuda

# 1. 下载并移动 cuda pin 文件
print_message "$GREEN" "Step 1: 配置 CUDA 仓库优先级..."
download_file "$CUDA_PIN_URL" "$CUDA_PIN_FILE"
mv "$CUDA_PIN_FILE" /etc/apt/preferences.d/cuda-repository-pin-600
check_status "移动 pin 文件失败"

# 2. 下载并安装 CUDA 仓库包
print_message "$GREEN" "Step 2: 下载并安装 CUDA 仓库包..."
download_file "$CUDA_DEB_URL" "$CUDA_DEB_FILE"
dpkg -i "$CUDA_DEB_FILE"
check_status "安装 CUDA 仓库包失败"

# 3. 拷贝 keyring
print_message "$GREEN" "Step 3: 配置 CUDA 仓库密钥..."
cp /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
check_status "复制 keyring 失败"

# 4. 更新包列表
print_message "$GREEN" "Step 4: 更新包列表..."
apt-get update
check_status "更新包列表失败"

# 5. 安装 CUDA
print_message "$GREEN" "Step 5: 安装 CUDA 12.6..."
apt-get -y install cuda-toolkit-12-6
check_status "安装 CUDA 失败"

# 6. 设置环境变量
print_message "$GREEN" "Step 6: 配置环境变量..."
BASHRC="/etc/bash.bashrc"
grep -qxF 'export PATH=/usr/local/cuda-12.6/bin:$PATH' $BASHRC || echo 'export PATH=/usr/local/cuda-12.6/bin:$PATH' >> $BASHRC
grep -qxF 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' $BASHRC || echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' >> $BASHRC

# 7. 清理下载的文件
print_message "$GREEN" "Step 7: 清理安装文件..."
rm -f "$CUDA_DEB_FILE"

# 8. 验证安装
print_message "$GREEN" "Step 8: 验证安装..."
if [ -f "/usr/local/cuda-12.6/bin/nvcc" ]; then
    print_message "$GREEN" "CUDA 12.6 安装成功！"
else
    print_message "$RED" "警告：CUDA 安装可能不完整，请检查安装日志"
fi

print_message "$YELLOW" "请运行 'source /etc/bash.bashrc' 或重新登录以使环境变量生效"
print_message "$YELLOW" "可以运行 'nvcc --version' 来验证安装"

# 提示重启
print_message "$YELLOW" "强烈建议重启系统以确保所有组件正常工作"
print_message "$YELLOW" "是否现在重启? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    shutdown -r now
fi
