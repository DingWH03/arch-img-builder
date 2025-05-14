#!/bin/bash
set -euo pipefail

TOOLCHAIN_URL="http://archive.spacemit.com/toolchain/spacemit-toolchain-linux-glibc-x86_64-v1.0.0.tar.xz"
TOOLCHAIN_DIR="toolchain"

mkdir -p "$TOOLCHAIN_DIR"
cd "$TOOLCHAIN_DIR"

# 判断目录是否为空
if [ -z "$(find . -mindepth 1 -print -quit)" ]; then
    echo "→ 下载交叉工具链..."
    wget "$TOOLCHAIN_URL" -O toolchain.tar.xz
    tar --strip-components=2 -xf toolchain.tar.xz
    rm toolchain.tar.xz
    echo "✓ 工具链安装完成"
else
    echo "✓ $TOOLCHAIN_DIR 已安装，跳过下载"
fi