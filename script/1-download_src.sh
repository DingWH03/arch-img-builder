#!/bin/bash
set -euo pipefail

# 下载目录
SRC_DIR="${1:-src}"
mkdir -p "$SRC_DIR"

# 每个仓库的 Git 地址和分支名（如有需要可修改）
KERNEL_REPO="https://gitee.com/bianbu-linux/linux-6.6.git"
KERNEL_BRANCH="k1-bl-v2.1.y"

UBOOT_REPO="https://gitee.com/bianbu-linux/uboot-2022.10.git"
UBOOT_BRANCH="k1-bl-v2.1.y"

OPENSBI_REPO="https://gitee.com/bianbu-linux/opensbi.git"
OPENSBI_BRANCH="k1-bl-v2.1.y"

# 克隆函数
clone_repo() {
    local name="$1"
    local url="$2"
    local branch="$3"
    local dest="$SRC_DIR/$name"
    if [[ -d "$dest" ]]; then
        echo "✓ $name 已存在，跳过克隆"
    else
        echo "→ 正在克隆 $name (branch: $branch) ..."
        git clone --depth=1 --branch "$branch" "$url" "$dest"
    fi
}

# 克隆每个仓库（按分支）
clone_repo "linux"   "$KERNEL_REPO"   "$KERNEL_BRANCH"
clone_repo "uboot"   "$UBOOT_REPO"    "$UBOOT_BRANCH"
clone_repo "opensbi" "$OPENSBI_REPO"  "$OPENSBI_BRANCH"

echo "所有源码仓库已成功克隆到 $SRC_DIR/"
