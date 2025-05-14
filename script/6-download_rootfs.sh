#!/bin/bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="$SUDO"
fi


# 镜像及挂载目录
IMG="output/rootfs.img"
IMG_SIZE="2G"
ROOTFS_DIR="rootfs"

# 根文件系统下载地址
ROOTFS_URL="https://archriscv.felixc.at/images/archriscv-latest.tar.zst"
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

# 5. 清理
rm "${ARCHIVE}"
echo "→ 同步并卸载"
sync
$SUDO umount "${ROOTFS_DIR}"

echo "→ 完成：镜像文件 ${IMG} 已包含根文件系统"
