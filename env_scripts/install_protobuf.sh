#!/bin/bash

set -e  # Stop script execution on error

echo "🟢 Uninstalling system-installed protobuf..."
sudo apt remove --purge -y protobuf-compiler libprotobuf-dev python3-protobuf
sudo rm -rf /usr/local/bin/protoc
sudo rm -rf /usr/bin/protoc
sudo rm -rf /usr/include/google/protobuf
sudo rm -rf /usr/lib/x86_64-linux-gnu/libprotobuf*
sudo rm -rf /usr/local/lib/libprotobuf*
sudo rm -rf /usr/lib/python3/dist-packages/google/protobuf
sudo rm -rf ~/.local/lib/python3.*/site-packages/google/protobuf

echo "🟢 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🟢 Installing build dependencies..."
sudo apt install -y cmake g++ make git unzip

echo "🟢 Cloning protobuf repository..."
cd ~
rm -rf protobuf
git clone --depth=1 --branch v3.23.4 https://github.com/protocolbuffers/protobuf.git
cd protobuf

echo "🟢 Updating submodules..."
git submodule update --init --recursive

echo "🟢 Building protobuf..."
mkdir -p build
cd build
cmake ..
make -j$(nproc)

echo "🟢 Installing protobuf..."
sudo make install
sudo ldconfig

echo "🟢 Verifying installation..."
protoc --version

echo "🟢 Installing Python protobuf..."
pip3 install --no-cache-dir --upgrade protobuf

echo "🟢 Verifying Python protobuf version..."
python3 -c "import google.protobuf; print(google.protobuf.__version__)"

echo "🎉 Installation complete!"
