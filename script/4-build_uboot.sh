#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

WORK_DIR=$(pwd)

# 默认参数
SRC="src/uboot"                          # U-Boot 源码目录
OUT="output/uboot"                   # 输出目录
CONFIG="board/k1/config/uboot.config"     # 外部配置文件路径
CROSS_COMPILE="riscv64-unknown-linux-gnu-"  # 工具链前缀
JOBS=$(nproc)

print_header() {
    echo "====== 编译 U-Boot ======"
    echo "运行目录     : $WORK_DIR"
    echo "源码路径     : $SRC"
    echo "输出目录     : $OUT"
    echo "配置文件     : $CONFIG"
    echo "交叉编译前缀 : $CROSS_COMPILE"
    echo "并发线程数   : $JOBS"
    echo "=========================="
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --src)           SRC="$2"; shift 2;;
            --out)           OUT="$2"; shift 2;;
            --config)        CONFIG="$2"; shift 2;;
            --cross-compile) CROSS_COMPILE="$2"; shift 2;;
            *) echo "未知参数: $1"; exit 1;;
        esac
    done

    [[ "${SRC:0:1}" != "/" ]] && SRC="$WORK_DIR/$SRC"
    [[ "${OUT:0:1}" != "/" ]] && OUT="$WORK_DIR/$OUT"
    [[ "${CONFIG:0:1}" != "/" ]] && CONFIG="$WORK_DIR/$CONFIG"
}

build() {
    cd "$SRC"

    echo "→ 清理旧构建"
    make mrproper

    echo "→ 创建输出目录"
    mkdir -p "$OUT"

    echo "→ 拷贝配置文件"
    cp "$CONFIG" "$SRC/.config"

    echo "→ 执行 olddefconfig 补全配置"
    make CROSS_COMPILE="$CROSS_COMPILE" olddefconfig

    echo "→ 编译 U-Boot（含 SPL）"
    make -j"$JOBS" CROSS_COMPILE="$CROSS_COMPILE" all

    # echo "→ 查找目标产物"
    # for f in u-boot.itb u-boot-env-default.bin FSBL.bin bootinfo_*.bin; do
    #     find "$OUT" -name "$f" -exec ls -lh {} \;
    # done
}

copy_uboot_artifacts() {
    echo "→ 复制 U-Boot 构建产物"
    mkdir -p "$OUT"

    # 1. First-stage loader / FSBL
    cp -v "$SRC/FSBL.bin"                         "$OUT/" 2>/dev/null || true
    cp -v "$SRC/spl/u-boot-spl.bin"               "$OUT/" 2>/dev/null || true
    cp -v "$SRC/spl/u-boot-spl-dtb.bin"           "$OUT/" 2>/dev/null || true
    cp -v "$SRC/spl/u-boot-spl-nodtb.bin"         "$OUT/" 2>/dev/null || true

    # 2. U-Boot 主映像
    cp -v "$SRC/u-boot.bin"                       "$OUT/" 2>/dev/null || true
    cp -v "$SRC/u-boot.img"                       "$OUT/" 2>/dev/null || true
    cp -v "$SRC/u-boot.itb"                       "$OUT/" 2>/dev/null || true
    cp -v "$SRC/u-boot.dtb"                       "$OUT/" 2>/dev/null || true

    # 3. Bootinfo 镜像
    for type in emmc sd card spinor spinand; do
        # 注意目录名：根据你 ls 结果，是 bootinfo_emmc.bin 等
        src_file="$SRC/bootinfo_${type}.bin"
        [ -f "$src_file" ] && cp -v "$src_file" "$OUT/bootinfo-${type}.bin"
    done

    # 4. U-Boot 环境变量
    cp -v "$SRC/u-boot-env-default.bin"                   "$OUT/" 2>/dev/null || true

    # 5. 其它可选二进制
    cp -v "$SRC/fit-dtb.blob"                      "$OUT/" 2>/dev/null || true
    cp -v "$SRC/u-boot-srec"                       "$OUT/" 2>/dev/null || true

    echo "→ 完成：所有可用的 U-Boot 产物都已复制到 $OUT"
}



main() {
    parse_args "$@"
    print_header
    build
    echo "U-Boot 编译完成"
    copy_uboot_artifacts
}

main "$@"
