#!/bin/bash

echo "🟢 Updating package lists..."
sudo apt update

echo "🟢 Installing OpenCV dependencies..."
# 尝试安装通用版本的 libdc1394-dev
# 其他依赖项基本通用
sudo apt install -y build-essential cmake git pkg-config libgtk-3-dev \
                    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
                    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev \
                    libtiff-dev gfortran openexr libatlas-base-dev \
                    libtbb2 libtbb-dev libdc1394-dev # 改用 libdc1394-dev

# 捕获安装 libdc1394-dev 的退出码
if [ $? -ne 0 ]; then
    echo "🚨 Warning: Failed to install libdc1394-dev. This is for FireWire camera support."
    echo "If you don't use FireWire cameras, this might be skippable."
    echo "On older systems, libdc1394-22-dev might be the name, but it was not found."
fi

# 检测架构
ARCH=$(uname -m)
# 使用 ANSI 转义序列显示黄色字体
echo -e "\033[1;33m Detected architecture: $ARCH\033[0m"

if [ "$ARCH" = "aarch64" ]; then
    echo "Platform: ARM64 (likely Jetson or similar ARM device)."
    echo "For Jetson, it's often recommended to use OpenCV installed via NVIDIA JetPack/SDK Manager,"
    echo "or build from source using NVIDIA's scripts for optimal hardware acceleration."
    echo "Attempting to install system OpenCV packages for ARM64..."
    # 在 Jetson 上，这些包通常由 NVIDIA 的 L4T 源提供
    sudo apt install -y libopencv-dev python3-opencv
else # x86_64 等
    echo "Platform: x86_64 (or other non-ARM64)."
    echo "Attempting to install system OpenCV packages..."
    sudo apt install -y libopencv-dev python3-opencv
fi

echo "🎉 Installation attempt complete."
echo ""
echo "------------------------------------------"
echo "Checking installed OpenCV versions:"
echo "------------------------------------------"
echo ""

# 检查 C++ 绑定的 OpenCV 版本 (pkg-config)
echo "🟢 Checking C++ OpenCV version (via pkg-config)..."
if command -v pkg-config &> /dev/null; then
    if pkg-config --modversion opencv4 2>/dev/null; then
        OPENCV_CPP_VERSION=$(pkg-config --modversion opencv4)
        echo "OpenCV 4 (C++) version: $OPENCV_CPP_VERSION"
    elif pkg-config --modversion opencv 2>/dev/null; then
        OPENCV_CPP_VERSION=$(pkg-config --modversion opencv)
        echo "OpenCV (C++) version (likely 2.x or 3.x): $OPENCV_CPP_VERSION"
    else
        echo "Could not determine OpenCV C++ version using pkg-config for 'opencv4' or 'opencv'."
        echo "It might be installed, but pkg-config files are not set up correctly, or it's an older/different setup."
    fi
else
    echo "pkg-config command not found. Cannot check C++ OpenCV version this way."
fi
echo ""

# 检查 Python 绑定的 OpenCV 版本
echo "🟢 Checking Python OpenCV version..."
if python3 -c "import cv2; print(cv2.__version__)" &> /dev/null; then
    PY_OPENCV_VERSION=$(python3 -c "import cv2; print(cv2.__version__)")
    echo "OpenCV (Python) version: $PY_OPENCV_VERSION"

    # 尝试获取构建信息，可能包含 CUDA 等信息
    echo "OpenCV (Python) build information (first few lines):"
    python3 -c "import cv2; print(cv2.getBuildInformation()[:1000])" # Print first 1000 chars
else
    echo "OpenCV Python bindings (cv2) not found or could not be imported in Python 3."
    echo "If you intended to use OpenCV with Python, ensure 'python3-opencv' was installed correctly,"
    # 使用绿色字体高亮 pip install
    echo -e "or consider '\033[1;32mpip install opencv-python\033[0m'."
fi

echo "------------------------------------------"
echo ""
echo "🎉 Script finished."
if [ "$ARCH" = "aarch64" ]; then
    echo "Reminder for Jetson users: For best performance, ensure you are using an OpenCV build optimized for Tegra, often provided by NVIDIA or built from source with CUDA support."
fi