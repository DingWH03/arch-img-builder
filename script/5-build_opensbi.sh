#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

WORK_DIR=$(pwd)

# 默认参数
SRC="src/opensbi"                         # OpenSBI 源码目录
OUT="output/opensbi"                 # 输出目录
PLATFORM="generic"                   # OpenSBI 支持的平台
PLATFORM_DEFCONFIG="k1_defconfig"    # 自定义 defconfig
CROSS_COMPILE="riscv64-unknown-linux-gnu-"   # 工具链前缀
JOBS=$(nproc)

print_header() {
    echo "====== 编译 OpenSBI ======"
    echo "运行目录           : $WORK_DIR"
    echo "OpenSBI 源码路径   : $SRC"
    echo "平台               : $PLATFORM"
    echo "Defconfig          : $PLATFORM_DEFCONFIG"
    echo "输出目录           : $OUT"
    echo "交叉编译前缀       : $CROSS_COMPILE"
    echo "并发线程数         : $JOBS"
    echo "=========================="
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --src)           SRC="$2"; shift 2;;
            --out)           OUT="$2"; shift 2;;
            --platform)      PLATFORM="$2"; shift 2;;
            --defconfig)     PLATFORM_DEFCONFIG="$2"; shift 2;;
            --cross-compile) CROSS_COMPILE="$2"; shift 2;;
            *) echo "未知参数: $1"; exit 1;;
        esac
    done

    [[ "${SRC:0:1}" != "/" ]] && SRC="$WORK_DIR/$SRC"
    [[ "${OUT:0:1}" != "/" ]] && OUT="$WORK_DIR/$OUT"
}

build() {
    cd "$SRC"
    echo "$SRC"

    echo "→ 清理旧构建"
    make distclean || true

    echo "→ 编译 OpenSBI: $PLATFORM $PLATFORM_DEFCONFIG"
    make PLATFORM="$PLATFORM" PLATFORM_DEFCONFIG="$PLATFORM_DEFCONFIG" CROSS_COMPILE="$CROSS_COMPILE"

    echo "→ 拷贝输出到 $OUT"
    mkdir -p "$OUT"
    cp -v $SRC/build/platform/generic/firmware/fw_dynamic.itb "$OUT/" || echo "未找到 payload 文件"
}

main() {
    parse_args "$@"
    print_header
    build
    echo "OpenSBI 编译完成"
}

main "$@"
