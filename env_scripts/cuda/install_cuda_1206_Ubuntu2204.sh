#!/bin/bash
set -euo pipefail
trap 'echo -e "\033[0;31m[ERR] 出错于行 $LINENO\033[0m"' ERR

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

# ===== 可调参数 =====
INSTALL_CUDNN="${INSTALL_CUDNN:-yes}"  # yes/no 是否安装 cuDNN
CUDA_BASE="/usr/local/cuda-12.6"       # 目标 CUDA 路径（与上面安装的版本一致）
CUDNN_URL="${CUDNN_URL:-https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/cudnn-linux-x86_64-9.6.0.74_cuda12-archive.tar.xz}"
# ====================

# 定义文件URL和名称（CUDA 12.6.3）
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

# 函数：下载文件（按需装 wget）
download_file() {
    local url=$1
    local filename=$2

    if ! command -v wget >/dev/null 2>&1; then
        print_message "$YELLOW" "未找到 wget，正在安装..."
        apt-get update
        apt-get install -y wget
    fi
    
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

# 函数：清理NVIDIA和CUDA相关文件（保留你的逻辑，改为“失败不致命”）
clean_nvidia_cuda() {
    print_message "$GREEN" "正在清理旧的NVIDIA和CUDA文件..."
    systemctl stop nvidia-* 2>/dev/null || true
    apt-get --purge remove -y "*cuda*" "*cudnn*" || true
    apt-get --purge remove -y "*nvidia*" || true
    apt-get autoremove -y || true
    apt-get autoclean || true
    rm -rf /usr/local/cuda* \
           /usr/lib/x86_64-linux-gnu/nvidia/ \
           /usr/lib/x86_64-linux-gnu/vdpau/ \
           /etc/OpenCL/ \
           /usr/share/nvidia/ || true
    rm -f /usr/lib/x86_64-linux-gnu/libnvidia-*.so.* || true
    rm -rf /var/lib/dkms/nvidia* || true
    ldconfig || true
    print_message "$GREEN" "清理完成"
}

# 开始安装过程
print_message "$GREEN" "开始安装 CUDA 12.6.3 ..."

# 0. 清理旧的安装
print_message "$GREEN" "Step 0: 清理旧的NVIDIA和CUDA安装..."
clean_nvidia_cuda

# 1. 下载并移动 cuda pin 文件
print_message "$GREEN" "Step 1: 配置 CUDA 仓库优先级..."
download_file "$CUDA_PIN_URL" "$CUDA_PIN_FILE"
mv -f "$CUDA_PIN_FILE" /etc/apt/preferences.d/cuda-repository-pin-600
check_status "移动 pin 文件失败"

# 2. 下载并安装 CUDA 仓库包
print_message "$GREEN" "Step 2: 下载并安装 CUDA 仓库包..."
download_file "$CUDA_DEB_URL" "$CUDA_DEB_FILE"
dpkg -i "$CUDA_DEB_FILE" || true
apt-get -y -f install
check_status "安装 CUDA 仓库包失败"

# 3. 拷贝 keyring
print_message "$GREEN" "Step 3: 配置 CUDA 仓库密钥..."
cp -f /var/cuda-repo-ubuntu2204-12-6-local/cuda-*-keyring.gpg /usr/share/keyrings/
check_status "复制 keyring 失败"

# 4. 更新包列表
print_message "$GREEN" "Step 4: 更新包列表..."
apt-get update
check_status "更新包列表失败"

# 5. 安装 CUDA（仅 Toolkit，不动驱动）
print_message "$GREEN" "Step 5: 安装 CUDA Toolkit 12.6..."
apt-get -y install cuda-toolkit-12-6
check_status "安装 CUDA Toolkit 失败"

# 6. 设置环境变量
print_message "$GREEN" "Step 6: 配置环境变量..."
BASHRC="$HOME/.bashrc"
touch "$BASHRC"
grep -qxF 'export PATH=/usr/local/cuda-12.6/bin:$PATH' "$BASHRC" || echo 'export PATH=/usr/local/cuda-12.6/bin:$PATH' >> "$BASHRC"
grep -qxF 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' "$BASHRC" || echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' >> "$BASHRC"

# 7. 清理下载的文件
print_message "$GREEN" "Step 7: 清理安装文件..."
rm -f "$CUDA_DEB_FILE"

# 8. 验证安装
print_message "$GREEN" "Step 8: 验证安装..."
if [ -x "$CUDA_BASE/bin/nvcc" ]; then
    print_message "$GREEN" "CUDA 12.6 安装成功！"
else
    print_message "$RED" "警告：CUDA 安装可能不完整，请检查安装日志"
fi

# ---------- 这里开始集成 cuDNN 安装（默认开启，可用 INSTALL_CUDNN=no 跳过） ----------
if [ "$INSTALL_CUDNN" = "yes" ]; then
    print_message "$GREEN" "Step C1: 下载 cuDNN 包..."
    CUDNN_TARBALL="$(basename "$CUDNN_URL")"
    download_file "$CUDNN_URL" "$CUDNN_TARBALL"

    print_message "$GREEN" "Step C2: 解压 cuDNN 包..."
    CUDNN_DIR="${CUDNN_TARBALL%.tar.xz}"   # e.g. cudnn-linux-x86_64-9.6.0.74_cuda12-archive
    rm -rf "$CUDNN_DIR"
    tar -xf "$CUDNN_TARBALL"
    [ -d "$CUDNN_DIR" ] || { print_message "$RED" "解压目录 $CUDNN_DIR 不存在"; exit 1; }

    print_message "$GREEN" "Step C3: 复制头文件与库到 $CUDA_BASE ..."
    if [ -d "$CUDA_BASE/include" ] && [ -d "$CUDA_BASE/lib64" ]; then
        cp -P "$CUDNN_DIR"/include/cudnn*.h "$CUDA_BASE/include/" || { print_message "$RED" "复制头文件失败"; exit 1; }
        cp -P "$CUDNN_DIR"/lib/libcudnn*   "$CUDA_BASE/lib64/"   || { print_message "$RED" "复制库文件失败"; exit 1; }
        chmod a+r "$CUDA_BASE/include"/cudnn*.h "$CUDA_BASE/lib64"/libcudnn* || true
    else
        print_message "$RED" "CUDA 路径 $CUDA_BASE 不完整（缺 include/lib64），请检查安装"
        exit 1
    fi

    print_message "$GREEN" "Step C4: 刷新动态链接器缓存..."
    ldconfig

    print_message "$GREEN" "Step C5: 验证 cuDNN 安装..."
    if [ -f "$CUDA_BASE/include/cudnn.h" ] && ls "$CUDA_BASE/lib64"/libcudnn.so* >/dev/null 2>&1; then
        print_message "$GREEN" "cuDNN 安装成功！"
    else
        print_message "$RED" "cuDNN 安装校验失败，请检查日志"
        exit 1
    fi

    print_message "$GREEN" "Step C6: 清理 cuDNN 安装介质..."
    rm -rf "$CUDNN_DIR" "$CUDNN_TARBALL"
else
    print_message "$YELLOW" "已跳过 cuDNN 安装（INSTALL_CUDNN=no）"
fi
# ---------- cuDNN 结束 ----------

print_message "$YELLOW" "请运行 'source ~/.bashrc' 或重新登录以使环境变量生效"
print_message "$YELLOW" "可以运行 'nvcc --version' 与 'ldconfig -p | grep cudnn' 来验证"

# 提示重启（Toolkit/库本身不需要；若你后续更换内核驱动再重启）
print_message "$YELLOW" "是否现在重启? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    shutdown -r now
fi
