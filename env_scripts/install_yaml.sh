#!/bin/bash

# Update package list
echo "🟢 Updating package list..."
sudo apt update

# Install YAML C development libraries
echo "🟢 Installing YAML C development libraries..."
sudo apt install -y libyaml-dev
sudo apt-get install libyaml-cpp-dev

# Check if installation was successful
echo "🟢 Checking YAML library installation..."
dpkg -l | grep libyaml-dev

echo "🎉 YAML C development libraries installation completed!"
