#!/usr/bin/env bash
set -euo pipefail

PYTHON_VERSION="${PYTHON_VERSION:-3.10.14}"

log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERROR]\033[0m %s\n" "$*"; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "命令未找到：$1"; exit 1; }; }

install_build_deps_debian() {
  need_cmd sudo; need_cmd apt
  log "安装 Python 构建依赖..."
  sudo apt update
  sudo apt install -y \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm \
    libncurses5-dev libncursesw5-dev xz-utils tk-dev \
    libffi-dev liblzma-dev libgdbm-dev libgdbm-compat-dev \
    uuid-dev
}

build_and_install_python() {
  local ver="$1"
  log "下载并编译 Python $ver..."
  pushd /tmp >/dev/null
  wget -q "https://www.python.org/ftp/python/${ver}/Python-${ver}.tgz"
  tar -xf "Python-${ver}.tgz"
  cd "Python-${ver}"
  ./configure --enable-optimizations
  make -j"$(nproc)"
  sudo make altinstall
  popd >/dev/null
  log "Python $ver 安装完成：$(python3.10 -V 2>/dev/null || echo '未检测到')"
}

ensure_python_310() {
  if command -v python3.10 >/dev/null 2>&1; then
    local v; v="$(python3.10 -V 2>&1 | awk '{print $2}')"
    if [[ "$v" == "$PYTHON_VERSION" ]]; then
      log "已存在 python3.10 ($PYTHON_VERSION)，跳过安装。"
      return
    fi
  fi
  log "安装 python3.10 ($PYTHON_VERSION)..."
  install_build_deps_debian
  build_and_install_python "$PYTHON_VERSION"
}

ensure_python_310
