#!/bin/bash
set -euo pipefail

TOOLCHAIN_URL="http://archive.spacemit.com/toolchain/spacemit-toolchain-linux-glibc-x86_64-v1.0.0.tar.xz"
TOOLCHAIN_DIR="toolchain"

mkdir -p "$TOOLCHAIN_DIR"
cd "$TOOLCHAIN_DIR"

echo "→ 下载交叉工具链..."
wget "$TOOLCHAIN_URL" -O toolchain.tar.xz
tar --strip-components=1 -xf toolchain.tar.xz
rm toolchain.tar.xz

