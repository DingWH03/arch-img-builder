#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# 当前 shell 的工作目录（脚本被调用时所在目录）
WORK_DIR=$(pwd)

# 默认值（相对或绝对路径皆可）
SRC="src/linux"
ARCH="riscv"
OUT="output/kernel"
CONFIG="board/k1/config/kernel.config"
CROSS_COMPILE="riscv64-unknown-linux-gnu-"

print_header() {
    echo "====== 编译 kernel ======"
    echo "运行目录     : $WORK_DIR"
    echo "源码路径     : $SRC"
    echo "架构         : $ARCH"
    echo "输出目录     : $OUT"
    echo "配置         : $CONFIG"
    echo "交叉编译前缀 : $CROSS_COMPILE"
    echo "并发线程数   : $JOBS"
    echo "========================"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --src)           SRC="$2"; shift 2;;
            --arch)          ARCH="$2"; shift 2;;
            --out)           OUT="$2"; shift 2;;
            --config)        CONFIG="$2"; shift 2;;
            --cross-compile) CROSS_COMPILE="$2"; shift 2;;
            *) echo "未知参数: $1"; exit 1;;
        esac
    done

    # 如果是相对路径，就补全为基于 WORK_DIR 的绝对路径
    [[ "${SRC:0:1}" != "/" ]] && SRC="$WORK_DIR/$SRC"
    [[ "${OUT:0:1}" != "/" ]] && OUT="$WORK_DIR/$OUT"
    [[ "${CONFIG:0:1}" != "/" ]] && CONFIG="$WORK_DIR/$CONFIG"

    # 参数检查
    if [[ -z "$SRC" || -z "$ARCH" || -z "$OUT" ]]; then
        echo "用法: $0 --src <源码路径> --arch <架构> --out <输出路径> [--config defconfig]"
        exit 1
    fi
}

clean() {
    echo "→ 清理残留：mrproper"

    make ARCH="$ARCH" mrproper
}

config() {
    echo "→ 生成 .config ($CONFIG)"
    # make ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" "$CONFIG"
    # make ARCH="$ARCH" olddefconfig
    cp $CONFIG "$SRC/.config"
    make ARCH="$ARCH" olddefconfig
}

build() {
    echo "→ 开始编译"
    make -j"$JOBS" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" V=1
}

make_output() {
    echo "→ 复制编译产物"
    mkdir -p "$OUT"
    # 核心镜像
    cp -v "$SRC/arch/$ARCH/boot/Image"      "$OUT/"
    cp -v "$SRC/arch/$ARCH/boot/Image.gz"   "$OUT/" 2>/dev/null || true
    cp -v "$SRC/arch/$ARCH/boot/Image.itb"  "$OUT/" 2>/dev/null || true
    cp -v "$SRC/arch/$ARCH/boot/zImage"     "$OUT/" 2>/dev/null || true
    cp -v "$SRC/arch/$ARCH/boot/uImage"     "$OUT/" 2>/dev/null || true

    # 设备树（二进制）
    mkdir -p "$OUT/dtb"
    cp -v "$SRC/arch/$ARCH/boot/dts"/*/*.dtb "$OUT/dtb/"

}

clean_src() {
    echo "→ 清理源码"
    rm -rf "$SRC"
}

main() {
    parse_args "$@"
    JOBS=$(nproc)
    print_header

    # 进入源码目录
    cd "$SRC"

    # 导出环境
    export ARCH CROSS_COMPILE O="$OUT"

    clean       # 失败自动退出
    config      # 失败自动退出
    build       # 失败自动退出
    make_output

    echo "编译完成"
    clean_src
}

main "$@"
