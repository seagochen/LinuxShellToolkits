#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Miniconda信息
MINICONDA_VERSION="latest"
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh"
INSTALL_PATH="$HOME/miniconda3"

# 检查是否已安装
if [ -d "$INSTALL_PATH" ]; then
    echo -e "${RED}Miniconda已安装在 $INSTALL_PATH${NC}"
    echo "是否重新安装? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 0
    fi
    rm -rf "$INSTALL_PATH"
fi

# 下载Miniconda
echo -e "${GREEN}下载 Miniconda...${NC}"
wget -O miniconda.sh "$MINICONDA_URL" || {
    echo -e "${RED}下载失败${NC}"
    exit 1
}

# 安装Miniconda
echo -e "${GREEN}安装 Miniconda...${NC}"
bash miniconda.sh -b -p "$INSTALL_PATH" || {
    echo -e "${RED}安装失败${NC}"
    rm miniconda.sh
    exit 1
}

# 清理安装文件
rm miniconda.sh

# 配置环境变量
CONDA_PATH_LINE="export PATH=$INSTALL_PATH/bin:\$PATH"
if ! grep -q "$CONDA_PATH_LINE" ~/.bashrc; then
    echo "$CONDA_PATH_LINE" >> ~/.bashrc
    export PATH="$INSTALL_PATH/bin:$PATH"
fi

# 初始化conda
"$INSTALL_PATH/bin/conda" init bash

# 配置conda镜像
"$INSTALL_PATH/bin/conda" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
"$INSTALL_PATH/bin/conda" config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
"$INSTALL_PATH/bin/conda" config --set show_channel_urls yes

echo -e "${GREEN}Miniconda安装完成！${NC}"
echo "请运行 'source ~/.bashrc' 或重新打开终端以使环境变量生效"
