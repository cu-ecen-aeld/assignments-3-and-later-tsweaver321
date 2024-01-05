#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
CURRENT_DIR=$(dirname "$(realpath "$0")")
NUM_CORES=$(nproc)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

if [ -d "$OUTDIR" ]; then
    echo "$OUTDIR exists, deleting..."
    rm -rf "$OUTDIR"
fi

mkdir -p "$OUTDIR"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Build the kernel
    echo "Building kernel"

    # Deep clean the kernel tree 
    echo "Doing deep clean of kernel tree"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper

    # Config kernel for QEMU (virt arm dev board)
    echo "Configuring kernel for virt arm on QEMU"
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig

    # Build kernel image for booting with QEMU
    echo "Building the kernel using $NUM_CORES cores"
    make -j${NUM_CORES} ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all

    # Build the devicetree
    echo "Building the devicetree using $NUM_CORES cores"
    make -j${NUM_CORES} ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cd "$OUTDIR"
cp linux-stable/arch/arm64/boot/Image .

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf "$OUTDIR"/rootfs
fi

# Create necessary base directories
mkdir -p rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    
    # Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# Make and install busybox
echo "Making busybox"
make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE}
echo "Installing busybox"
make CONFIG_PREFIX="$OUTDIR"/rootfs ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- install

echo "Library dependencies"
cd "$OUTDIR"/rootfs
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
echo "Copying Library dependencies to rootfs"
cd "$OUTDIR"/rootfs

# ld-linux-aarch64.so.1
find /usr/local/bin/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -name "ld-linux-aarch64.so.1" -exec sh -c '
SYMLINK="{}"
TARGET="$(readlink -f $SYMLINK)"

echo "Symlink path: $SYMLINK"
echo "Target path : $TARGET"

cp "$TARGET" lib
ln -sf "$(basename $TARGET)" lib/ld-linux-aarch64.so.1
ls -l lib/ld*
' \;

# libm.so.6
find /usr/local/bin/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -name "libm.so.6" -exec sh -c '
SYMLINK="{}"
TARGET="$(readlink -f $SYMLINK)"

echo "Symlink path: $SYMLINK"
echo "Target path : $TARGET"

cp "$TARGET" lib64
ln -sf "$(basename $TARGET)" lib64/libm.so.6
ls -l lib64/libm*
' \;

# libc.so.6
find /usr/local/bin/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -name "libc.so.6" -exec sh -c '
SYMLINK="{}"
TARGET="$(readlink -f $SYMLINK)"

echo "Symlink path: $SYMLINK"
echo "Target path : $TARGET"

cp "$TARGET" lib64
ln -sf "$(basename $TARGET)" lib64/libc.so.6
ls -l lib64/libc*
' \;

# libresolv.so.2
find /usr/local/bin/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/ -name "libresolv.so.2" -exec sh -c '
SYMLINK="{}"
TARGET="$(readlink -f $SYMLINK)"

echo "Symlink path: $SYMLINK"
echo "Target path : $TARGET"

cp "$TARGET" lib64
ln -sf "$(basename $TARGET)" lib64/libresolv.so.2
ls -l lib64/libresolv*
' \;

# SKIP ** Make device nodes

# Clean and build the writer utility
cd "$CURRENT_DIR"
echo "Building writer app for $ARCH in $CURRENT_DIR"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying Apps to home folder"
if [ -e "writer" ]
then 
    cp writer "$OUTDIR"/rootfs/home
else
    echo "ERROR: Missing writer app"
fi

if [ -e "finder.sh" ]
then 
    cp finder.sh "$OUTDIR"/rootfs/home
else
    echo "ERROR: Missing finder.sh"
fi

if [ -e "finder-test.sh" ]
then 
    cp finder-test.sh "$OUTDIR"/rootfs/home
else
    echo "ERROR: Missing finder-test.sh"
fi

mkdir "$OUTDIR"/rootfs/home/conf

if [ -e "conf/username.txt" ]
then 
    cp conf/username.txt "$OUTDIR"/rootfs/home/conf
else
    echo "ERROR: Missing conf/username.txt"
fi

if [ -e "conf/assignment.txt" ]
then 
    cp conf/assignment.txt "$OUTDIR"/rootfs/home/conf
else
    echo "ERROR: Missing conf/assignment.txt"
fi

if [ -e "autorun-qemu.sh" ]
then 
    cp autorun-qemu.sh "$OUTDIR"/rootfs/home
else
    echo "ERROR: Missing autorun-qemu.sh"
fi

# Chown the root directory
sudo chown -R root:root "$OUTDIR"/rootfs
sudo chmod u+s "$OUTDIR"/rootfs/bin/busybox

# Create initramfs.cpio.gz (RAM disk for file system)
echo "Creating RAM disk for file system"
cd "$OUTDIR"/rootfs
find . | cpio -H newc -ov --owner root:root > "$OUTDIR"/initramfs.cpio
cd "$OUTDIR"
gzip -f initramfs.cpio

cd "$CURRENT_DIR"

echo "All Done!"