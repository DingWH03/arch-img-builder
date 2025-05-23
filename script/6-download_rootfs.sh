#!/bin/bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi


# 镜像及挂载目录
IMG="output/rootfs.img"
IMG_SIZE="2G"
ROOTFS_DIR="rootfs"
OVERLAY="board/k1/rootfs_overlay"

# 根文件系统下载地址
# ROOTFS_URL="https://archriscv.felixc.at/images/archriscv-latest.tar.zst"
ROOTFS_URL="https://github.com/DingWH03/arch-img-builder/releases/download/arch-v1-k1-bl-v2.2.y/archrootfs.tar.gz"
ARCHIVE="archriscv-latest.tar.zst"

# 1. 创建一个 2G 的空镜像文件
echo "→ 创建 ${IMG} (${IMG_SIZE})"
fallocate -l "${IMG_SIZE}" "${IMG}"
# 或者用 dd：
# dd if=/dev/zero of="${IMG}" bs=1M count=3072

# 2. 格式化为 ext4 文件系统
echo "→ 格式化 ${IMG} 为 ext4"
mkfs.ext4 -F "${IMG}"

# 3. 准备挂载点并挂载
mkdir -p "${ROOTFS_DIR}"
echo "→ 挂载 ${IMG} 到 ${ROOTFS_DIR}"
$SUDO mount -o loop "${IMG}" "${ROOTFS_DIR}"

# 4. 下载并解压根文件系统
echo "→ 下载 ROOTFS"
wget -q "${ROOTFS_URL}" -O "${ARCHIVE}"
echo "→ 解压到 ${ROOTFS_DIR}"
# --strip-components=1 去掉最外层目录
$SUDO tar --numeric-owner -xvf "${ARCHIVE}" -C "${ROOTFS_DIR}"

if [[ -d "$OVERLAY" ]]; then
        $SUDO cp -a "$OVERLAY"/* "${ROOTFS_DIR}"
    else
        echo "警告：overlay 目录不存在，跳过合并" >&2
    fi

# 5. 清理
if [ -z "${NO_CLEAN:-}" ]; then
  rm "${ARCHIVE}"
fi

echo "→ 同步并卸载"
sync
$SUDO umount "${ROOTFS_DIR}"

echo "→ 完成：镜像文件 ${IMG} 已包含根文件系统"
