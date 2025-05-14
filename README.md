# arch-image-builder

为bit-brick-k1适配archlinux

## 流程

1. Kernel
2. Uboot
3. OpenSBI
4. Rootfs
5. Bootfs

## 编译

默认参数在`script/`文件夹的脚本文件中。为了减少github action编译过程中磁盘空间占用量，默认不设置`NO_CLEAN`变量，会导致源代码等中间产物被删除。
