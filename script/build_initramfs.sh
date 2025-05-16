#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# 工作目录
WORK_DIR=$(pwd)

# 默认配置
BUSYBOX_SRC="https://busybox.net/downloads/busybox-snapshot.tar.bz2"
SRC="${WORK_DIR}/src/busybox"
OUT="${WORK_DIR}/output/busybox"
CONFIG="board/k1/config/busybox.config"
OVERLAY="board/k1/initramfs_overlay"
INITRAMFS_IMG="initramfs-generic.img"
CROSS_COMPILE="riscv64-unknown-linux-gnu-"
JOBS=$(nproc)

print_header() {
    echo "====== 编译 BusyBox 并生成 initramfs ======"
    echo "工作目录       : $WORK_DIR"
    echo "源码路径       : $SRC"
    echo "输出目录       : $OUT"
    echo "配置文件       : $CONFIG"
    echo "Overlay 目录   : $OVERLAY"
    echo "并发线程数     : $JOBS"
    echo "=========================================="
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --src) SRC="$2"; shift 2;;
            --out) OUT="$2"; shift 2;;
            --config) CONFIG="$2"; shift 2;;
            --overlay) OVERLAY="$2"; shift 2;;
            --jobs) JOBS="$2"; shift 2;;
            *) echo "未知参数: $1"; exit 1;;
        esac
    done

    # 绝对路径补全
    [[ "${SRC:0:1}" != "/" ]] && SRC="$WORK_DIR/$SRC"
    [[ "${OUT:0:1}" != "/" ]] && OUT="$WORK_DIR/$OUT"
    [[ "${OVERLAY:0:1}" != "/" ]] && OVERLAY="$WORK_DIR/$OVERLAY"
}

clone_busybox() {
    echo "→ 下载 BusyBox 源码"
    if [[ -d "$SRC" && -n "$(ls -A "$SRC" 2>/dev/null)" ]]; then
        echo "源码目录已存在且不为空，跳过下载"
    else
        echo "开始下载 BusyBox 源码..."
        mkdir -p "$SRC"
        wget -O - "$BUSYBOX_SRC" | tar -xjf - -C "$SRC" --strip-components=
    fi
    rm "$SRC/networking/tc.c"
}

configure_busybox() {
    cp "$CONFIG" "$SRC/.config"
    cd "$SRC"
    make ARCH=riscv oldconfig CROSS_COMPILE="$CROSS_COMPILE" 
}

build_busybox() {
    echo "→ 编译 BusyBox"
    cd "$SRC"
    make ARCH=riscv -j"$JOBS" CROSS_COMPILE="$CROSS_COMPILE"
}

install_busybox() {
    echo "→ 安装 BusyBox 到 initramfs 结构"
    sudo rm -rf "${OUT}/initramfs-generic"
    mkdir -p "${OUT}/initramfs-generic"
    cd "$SRC"
    make ARCH=riscv CONFIG_PREFIX="${OUT}/initramfs-generic" install CROSS_COMPILE="$CROSS_COMPILE"
}

prepare_init_dirs() {
    echo "→ 创建 initramfs 基础目录结构"
    mkdir -p "${OUT}/initramfs-generic"/{bin,sbin,etc,proc,sys,dev,run,tmp,mnt,usr/bin,usr/sbin,root}
}


merge_overlay() {
    echo "→ 合并 overlay 文件"
    prepare_init_dirs
    if [[ -d "$OVERLAY" ]]; then
        cp -a "$OVERLAY"/* "${OUT}/initramfs-generic/"
    else
        echo "警告：overlay 目录不存在，跳过合并" >&2
    fi
}

create_initramfs() {
    echo "→ 生成 initramfs 镜像"
    cd "${OUT}/initramfs-generic"
    sudo chown -R root:root .
    find . | sudo cpio -o --format=newc | gzip > "${OUT}/${INITRAMFS_IMG}"
    echo "initramfs 镜像已生成：${OUT}/${INITRAMFS_IMG}"
}

clean_src() {
    echo "→ 清理源码目录"
    rm -rf "$SRC"
}

main() {
    parse_args "$@"
    print_header

    clone_busybox
    configure_busybox
    build_busybox
    install_busybox
    merge_overlay
    create_initramfs

    echo "全部完成"

    if [ -z "${NO_CLEAN:-}" ]; then
        clean_src
    fi
}

main "$@"
