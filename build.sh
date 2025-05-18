#!/bin/bash
#
# Copyright (C) 2023 ZHANtech™
#

WORK_DIR="${PWD}"
KERNEL_DIR="$(basename $PWD)"
DISTRO=$(source /etc/os-release && echo ${NAME})
KERVER=$(make kernelversion)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
COMMIT_HEAD=$(git log --oneline -1)
ANYKERNEL3_DIR==anykernel
CLANG_VERSION=clang-r547379
TC_DIR=prebuilts/clang/host/linux-x86
OUT_DIR=out/android13-5.15/dist
BOT_MSG_URL="https://api.telegram.org/bot$TOKEN/sendMessage"
BOT_BUILD_URL="https://api.telegram.org/bot$TOKEN/sendDocument"

# Repo URL
ANYKERNEL_REPO="https://github.com/iDeadXD/Ai-AnyKernel3"
ANYKERNEL_BRANCH="gki"

# Costumize
KERNEL="AiKernel"
RELEASE_VERSION=""
DEVICE="Xun"
BENGAL_DEVICE="Bengal"
KERNELNAME="${KERNEL}-${RELEASE_VERSION}-${BRANCH}-${DEVICE}-$(TZ=Asia/Jakarta date +%y%m%d)"
BENGAL_KERNELNAME="${KERNEL}-${RELEASE_VERSION}-${BRANCH}-${BENGAL_DEVICE}-$(TZ=Asia/Jakarta date +%y%m%d)"
FINAL_KERNEL_ZIP="${KERNELNAME}.zip"
FINAL_KERNEL_IMG="${BENGAL_KERNELNAME}.img"

function clean() {
rm -rf "$HOME"/kernel
cd ..
rm -rf out
}

tg_post_msg()
{
	curl -s -H "Content-Type: application/x-www-form-urlencoded" -X POST "$BOT_MSG_URL" -d chat_id="$CHATID" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"

}

##----------------------------------------------------------##

tg_post_build()
{
	# Post MD5Checksum alongwith for easeness
	MD5CHECK=$(md5sum "$1" | cut -d' ' -f1)

	# Show the Checksum alongwith caption
	curl --progress-bar -F document=@"$1" "$BOT_BUILD_URL" \
	-F chat_id="$CHATID"  \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2 | *MD5 Checksum : *\`$MD5CHECK\`"
}

function cloning() {
if ! [ -d "${TC_DIR}"/"${CLANG_VERSION}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
cd "${TC_DIR}"
mkdir ${CLANG_VERSION}
cd ${CLANG_VERSION} || exit
wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/${CLANG_VERSION}.tar.gz
tar -xf ${CLANG_VERSION}.tar.gz
cd "${WORK_DIR}"
cd ..
fi

# Telegram
CHATID="-1002301602471" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="8113908305:AAHwOJTOxaWvcTrdIjS0aIypqCzdyCjRR7M" # Get from botfather
}

function compile_kernel() {

# Starting
tg_post_msg "<b>STARTING KERNEL BUILD</b>" \
    "Docker OS: ${DISTRO}" \
    "Device: ${DEVICE}" \
    "Kernel Version : ${KERVER}" \
    "Kernel Name: <code>${KERNEL}</code>" \
    "Release Version: ${RELEASE_VERSION}" \
    "Toolchain: ${CLANG_VERSION}" \
    "Branch : <code>$BRANCH</code>" \
    "Last Commit : <code>$COMMIT_HEAD</code>"
START=$(TZ=Asia/Jakarta date +"%s")
LTO=thin BUILD_CONFIG=$KERNEL_DIR/build.config.gki.aarch64 build/build.sh

# Check If compilation is success
    if ! [ -f "${OUT_DIR}"/Image ]; then
        END=$(TZ=Asia/Jakarta date +"%s")
        DIFF=$(( END - START ))
        echo -e "Kernel compilation failed, See buildlog to fix errors"
        tg_post_msg "Build for ${DEVICE} <b>failed</b> in $((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)! Check Instance for errors @zh4ntech"
        exit 1
    fi

}

function ziping() {
cd "${WORK_DIR}"

    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "$ANYKERNEL3_DIR"

echo "**** Copying Image ****"
cp ../$OUT_DIR/Image $ANYKERNEL3_DIR/Image
cp ../$OUT_DIR/boot.img "$HOME"/kernel/$FINAL_KERNEL_IMG

echo "**** Time to zip up! ****"
cd $ANYKERNEL3_DIR/
zip -r9 "$HOME"/kernel/"$FINAL_KERNEL_ZIP" * -x README $FINAL_KERNEL_ZIP
echo "**** Done, here is your sha1 ****"
sha1sum "$HOME"/kernel/$FINAL_KERNEL_ZIP
sha1sum "$HOME"/kernel/$FINAL_KERNEL_IMG
}

# eksekusi

    echo ".........................."
    echo ".     Clean Directory    ."
    echo ".........................."
clean
    echo ".........................."
    echo ".     Cloning            ."
    echo ".........................."
cloning
    echo ".........................."
    echo ".     Building Kernel    ."
    echo ".........................."
compile_kernel
    echo ".........................."
    echo ".     Ziping Kernel      ."
    echo ".........................."
ziping

tg_post_build $FINAL_KERNEL_ZIP