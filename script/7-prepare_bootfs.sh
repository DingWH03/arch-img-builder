#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

WORK_DIR=$(pwd)

# 默认参数
IMGS_DIR="output"                                  # Build 输出目录
KERNEL_DIR="$IMGS_DIR/kernel"                      # 内核输出目录
DTB_DIR="$KERNEL_DIR/dtb"                          # 设备树输出目录
PARTITIONS_FILE="board/k1/partition_universal.json"  # 分区描述文件
UENV_TXT="board/k1/env_k1-x.txt"                   # U-Boot 环境脚本
UBOOT_LOGO="board/k1/archlinux.bmp"                # U-Boot 引导 Logo
KERNEL_IMAGE="Image"                           # 内核 FIT 镜像
DTB_PATTERN="*.dtb"                                # 设备树匹配模式
INITRAMFS_IMAGE=""                                 # 可选 initramfs (.cpio.gz)
JQ=$(command -v jq)                                # jq 工具路径
BOOTFS_IMG="bootfs.img"                            # 生成的 FAT 分区镜像
BOOTFS_MOUNT="./.bootfs_mount"                     # 挂载点

print_header() {
    echo "====== 生成 BOOTFS ======"
    echo "运行目录           : $WORK_DIR"
    echo "输出目录           : $IMGS_DIR"
    echo "内核目录           : $KERNEL_DIR"
    echo "设备树目录         : $DTB_DIR"
    echo "分区描述文件       : $PARTITIONS_FILE"
    echo "U-Boot env 文件    : $UENV_TXT"
    echo "U-Boot Logo        : $UBOOT_LOGO"
    echo "内核镜像           : $KERNEL_IMAGE"
    echo "DTB 匹配模式       : $DTB_PATTERN"
    echo "Initramfs（可选）  : $INITRAMFS_IMAGE"
    echo "输出 BOOTFS 镜像   : $IMGS_DIR/$BOOTFS_IMG"
    echo "挂载点             : $BOOTFS_MOUNT"
    echo "========================"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --imgs-dir)           IMGS_DIR="$2"; shift 2;;
            --partitions-file)    PARTITIONS_FILE="$2"; shift 2;;
            --uenv)               UENV_TXT="$2"; shift 2;;
            --logo)               UBOOT_LOGO="$2"; shift 2;;
            --kernel-image)       KERNEL_IMAGE="$2"; shift 2;;
            --dtb-pattern)        DTB_PATTERN="$2"; shift 2;;
            --initramfs-image)    INITRAMFS_IMAGE="$2"; shift 2;;
            *) echo "未知参数: $1"; exit 1;;
        esac
    done

    # 绝对路径化
    [[ "${IMGS_DIR:0:1}" != "/" ]]       && IMGS_DIR="$WORK_DIR/$IMGS_DIR"
    [[ "${KERNEL_DIR:0:1}" != "/" ]]     && KERNEL_DIR="$WORK_DIR/$KERNEL_DIR"
    [[ "${DTB_DIR:0:1}" != "/" ]]        && DTB_DIR="$WORK_DIR/$DTB_DIR"
    [[ "${PARTITIONS_FILE:0:1}" != "/" ]]&& PARTITIONS_FILE="$WORK_DIR/$PARTITIONS_FILE"
    [[ "${UENV_TXT:0:1}" != "/" ]]       && UENV_TXT="$WORK_DIR/$UENV_TXT"
    [[ "${UBOOT_LOGO:0:1}" != "/" ]]     && UBOOT_LOGO="$WORK_DIR/$UBOOT_LOGO"
}

gen_bootfs() {
    echo "→ 解析 BOOTFS 大小（bytes）"
    BOOTFS_SIZE=$($JQ -r '.partitions[] | select(.name=="bootfs") | .size' "$PARTITIONS_FILE")
    echo "   bootfs size: $BOOTFS_SIZE bytes"

    echo "→ 删除旧镜像并创建空镜像"
    rm -f "$BOOTFS_IMG"
    fallocate -l "${BOOTFS_SIZE}" "$BOOTFS_IMG"

    echo "→ 格式化为 FAT"
    mkfs.vfat -n BOOTFS "$BOOTFS_IMG"

    echo "→ 挂载镜像到 $BOOTFS_MOUNT"
    mkdir -p "$BOOTFS_MOUNT"
    sudo mount -o loop "$BOOTFS_IMG" "$BOOTFS_MOUNT"

    echo "→ 拷贝启动文件到 bootfs"
    sudo cp -f "$UENV_TXT"                              "$BOOTFS_MOUNT/"
    sudo cp -f "$UBOOT_LOGO"                            "$BOOTFS_MOUNT/"
    sudo cp -f "$KERNEL_DIR/$KERNEL_IMAGE"              "$BOOTFS_MOUNT/"
    sudo cp -f $DTB_DIR/$DTB_PATTERN                    "$BOOTFS_MOUNT/"
    if [[ -n "$INITRAMFS_IMAGE" ]]; then
        sudo cp -f "$IMGS_DIR/$INITRAMFS_IMAGE"         "$BOOTFS_MOUNT/initramfs-generic.img"
    fi

    echo "→ 同步并卸载"
    sync
    sudo umount "$BOOTFS_MOUNT"
    rmdir "$BOOTFS_MOUNT"

    echo "→ 成功：BOOTFS 镜像生成在 $BOOTFS_IMG"
}

main() {
    parse_args "$@"
    print_header
    gen_bootfs
    echo "build_bootfs 完成"
}

main "$@"
