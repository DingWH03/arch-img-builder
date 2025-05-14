#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

WORK_DIR=$(pwd)

# 默认路径参数
IMGS_DIR="output"
DEVICE_DIR="board/k1"
PARTITIONS_FILE="$DEVICE_DIR/partition_universal.json"
FASTBOOT_YAML="$DEVICE_DIR/fastboot.yaml"
GENIMAGE_SCRIPT="script/genimage.sh"
GENIMGCFG_SCRIPT="script/gen_imgcfg.py"
SDCARD_IMAGE="sdcard.img"
TARGET_IMAGE_ZIP="images-pack.zip"

print_header() {
    echo "====== 镜像打包工具 ======"
    echo "运行目录           : $WORK_DIR"
    echo "输出目录           : $IMGS_DIR"
    echo "分区文件           : $PARTITIONS_FILE"
    echo "genimage 脚本      : $GENIMAGE_SCRIPT"
    echo "输出 SD 镜像       : $SDCARD_IMAGE"
    echo "输出 ZIP 包        : $TARGET_IMAGE_ZIP"
    echo "========================"
}

update_genimage_cfg() {
    echo "→ 生成 genimage 配置文件"
    "$WORK_DIR/$GENIMGCFG_SCRIPT" -i "$PARTITIONS_FILE" -n "$SDCARD_IMAGE" -o "$IMGS_DIR/genimage.cfg"
    echo "已生成: $IMGS_DIR/genimage.cfg"
}

gen_sdcard_img() {
    echo "→ 开始生成 SDCARD 镜像..."
    "$WORK_DIR/$GENIMAGE_SCRIPT" -c "$IMGS_DIR/genimage.cfg"
    if [[ $? -ne 0 ]]; then
        echo "✗ 生成 SD 卡镜像失败，请检查错误"
        exit 1
    fi
    echo "成功生成 SD 卡镜像: $IMGS_DIR/$SDCARD_IMAGE"

    echo "→ 开始压缩 SD卡 镜像（xz）..."
    rm -f "$IMGS_DIR/$SDCARD_IMAGE.xz"
    xz -k -T0 -9 "$IMGS_DIR/$SDCARD_IMAGE"
    echo "已生成压缩文件: $IMGS_DIR/$SDCARD_IMAGE.xz"
}

pack_image_zip() {
    echo "→ 开始打包为 ZIP 镜像..."
    rm -f "$IMGS_DIR/$TARGET_IMAGE_ZIP"
    rm -rf "$IMGS_DIR/factory"
    mkdir -p "$IMGS_DIR/factory"

    # 拷贝必要文件
    cp -f "$IMGS_DIR/uboot/FSBL.bin" "$IMGS_DIR/factory/"
    cp -f "$IMGS_DIR/uboot/"bootinfo-*.bin "$IMGS_DIR/factory/"
    cp -f "$FASTBOOT_YAML" "$IMGS_DIR/"
    cp -f "$DEVICE_DIR"/partition_*.json "$IMGS_DIR/"
    cp -f "$IMGS_DIR/uboot/u-boot.itb" "$IMGS_DIR"
    cp -f "$IMGS_DIR/opensbi/fw_dynamic.itb" "$IMGS_DIR"
    cp -f "$IMGS_DIR"/uboot/u-boot-env-default.bin "$IMGS_DIR/env.bin"

    # 进入目录打包
    (
        cd "$IMGS_DIR"
        zip "$TARGET_IMAGE_ZIP" \
            fw_dynamic.itb \
            u-boot.itb \
            env.bin \
            bootfs.img \
            rootfs.img \
            partition_sd.json \
            fastboot.yaml \
            genimage.cfg \
            -r factory
    )

    # CI 兼容软链接
    if [[ -n "${BIANBU_LINUX_ARCHIVE_LATEST:-}" ]]; then
        ln -sf "$TARGET_IMAGE_ZIP" "$BIANBU_LINUX_ARCHIVE_LATEST"
    fi

    echo "镜像已成功打包为: $IMGS_DIR/$TARGET_IMAGE_ZIP"
}

main() {
    print_header
    update_genimage_cfg
    pack_image_zip
    gen_sdcard_img
    echo "全部完成"
}


main "$@"
