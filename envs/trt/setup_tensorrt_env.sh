#!/bin/bash

TENSORRT_PATH="/opt/tensorrt"
TENSORRT_DIRS=($(ls -d /opt/TensorRT-* 2>/dev/null))

echo "Checking TensorRT environment..."

# 检查 Jetson 设备
if [ -f "/usr/src/tensorrt/bin/trtexec" ]; then
    echo "Jetson environment detected."

    if [ ! -L "$TENSORRT_PATH" ]; then
        echo "Creating symbolic link: $TENSORRT_PATH -> /usr/src/tensorrt"
        sudo ln -sfn "/usr/src/tensorrt" "$TENSORRT_PATH"
    else
        echo "Symbolic link already exists: $TENSORRT_PATH"
    fi

    echo ".bashrcにJetson向けのTensorRTのPATHを追加中..."
    echo "# TensorRT Environment Variables (Jetson)" >> ~/.bashrc
    echo "export PATH=\$PATH:/usr/src/tensorrt/bin" >> ~/.bashrc
    echo "完了しました。"

else
    echo "x86 environment detected."

    # 检查 /opt 下是否有多个 TensorRT 版本
    if [ ${#TENSORRT_DIRS[@]} -eq 0 ]; then
        echo "Error: No TensorRT versions found in /opt/"
        exit 1
    elif [ ${#TENSORRT_DIRS[@]} -eq 1 ]; then
        SELECTED_TENSORRT=${TENSORRT_DIRS[0]}
        echo "Found single TensorRT version: $SELECTED_TENSORRT"
    else
        echo "Multiple TensorRT versions found in /opt/:"
        for i in "${!TENSORRT_DIRS[@]}"; do
            echo "[$i] ${TENSORRT_DIRS[$i]}"
        done

        while true; do
            read -p "Select a version (enter the number): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -lt "${#TENSORRT_DIRS[@]}" ]; then
                SELECTED_TENSORRT=${TENSORRT_DIRS[$choice]}
                break
            else
                echo "Invalid choice, please enter a valid number."
            fi
        done
    fi

    # 确保 /opt/tensorrt 符号链接正确
    if [ -L "$TENSORRT_PATH" ] || [ -d "$TENSORRT_PATH" ]; then
        read -p "Symbolic link /opt/tensorrt already exists. Replace it? (y/n): " confirm
        if [[ "$confirm" != "y" ]]; then
            echo "Operation cancelled."
            exit 0
        fi
        sudo rm -rf "$TENSORRT_PATH"
    fi

    echo "Creating symbolic link: $TENSORRT_PATH -> $SELECTED_TENSORRT"
    sudo ln -sfn "$SELECTED_TENSORRT" "$TENSORRT_PATH"

    # 追加到 .bashrc
    echo ".bashrcにTensorRTの環境変数を書き込み中..."
    echo "# TensorRT Environment Variables (x86)" >> ~/.bashrc
    echo "export PATH=\$PATH:$TENSORRT_PATH/bin" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$TENSORRT_PATH/lib" >> ~/.bashrc
    echo "完了しました。"

    # 添加 /opt/tensorrt/lib 到 ldconfig 配置
    echo "$TENSORRT_PATH/lib" | sudo tee /etc/ld.so.conf.d/tensorrt.conf > /dev/null

    # 运行 ldconfig
    sudo ldconfig
fi

# 重新加载 .bashrc
source ~/.bashrc
echo "Environment setup completed."
