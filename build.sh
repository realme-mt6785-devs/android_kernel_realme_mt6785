#!/bin/bash

function compile() 
{
rm -rf AnyKernel
source ~/.bashrc && source ~/.profile
export LC_ALL=C && export USE_CCACHE=1
ccache -M 100G
export ARCH=arm64
export KBUILD_BUILD_HOST=MARK•DEVS
export KBUILD_BUILD_USER="AbzRaiderXD"
git clone --depth 1  https://github.com/rama982/clang  clang

[ -d "out" ] && rm -rf out || mkdir -p out

make O=out ARCH=arm64 RM6785_defconfig

PATH="${PWD}/clang/bin:${PATH}" \
 make -j "$(nproc --all)" O="out" CC="clang" \
    LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip \
    CROSS_COMPILE=aarch64-linux-gnu-
}

function zupload()
{
git clone --depth=1 https://github.com/sarthakroy2002/AnyKernel3.git -b RMX2001 AnyKernel
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
cd AnyKernel
zip -r9 AbzRaiderXD-OSS-KERNEL-wasabi.zip *
curl -sL https://git.io/file-transfer | sh
./transfer wet AbzRaiderXD-OSS-KERNEL-wasabi.zip
}

compile
zupload
