#!/bin/bash
PRODUCT=$1

echo "[ADV] DATE = ${DATE}"
echo "[ADV] STORED = ${STORED}"
echo "[ADV] BSP_URL = ${BSP_URL}"
echo "[ADV] BSP_BRANCH = ${BSP_BRANCH}"
echo "[ADV] BSP_XML = ${BSP_XML}"
echo "[ADV] PLATFORM_PREFIX = ${PLATFORM_PREFIX}"
echo "[ADV] VERSION_NUMBER=$VERSION_NUMBER"

CURR_PATH="$PWD"
ROOT_DIR="${PLATFORM_PREFIX}_${RELEASE_VERSION}_${DATE}"
OUTPUT_DIR="${CURR_PATH}/${STORED}/${DATE}"
IMAGE_DIR="out"
DISTRO_IMAGE="debug"
IMAGE_VER="${MODEL_NAME}${BOARD_VER}${AIM_VERSION}UIV${RELEASE_VERSION}_${DATE}"

# ===========
#  Functions
# ===========
function get_source_code()
{
	echo "[ADV] get qcs source code"
	mkdir $ROOT_DIR
	pushd $ROOT_DIR 2>&1 > /dev/null
	repo init -u $BSP_URL -b main -m ${BSP_XML}
	repo sync -c -j8
	popd
}

function get_downloads()
{
	echo "[ADV] get yocto downloads"
	sudo mv $CURR_PATH/downloads $CURR_PATH/$ROOT_DIR/amss/LE.PRODUCT.2.1.r1/apps_proc/downloads
}

function build_image()
{
	cd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	echo "[ADV] building ..."
	script/build_release.sh -all
}

function generate_md5()
{
	FILENAME=$1

	if [ -e $FILENAME ]; then
		MD5_SUM=`md5sum -b $FILENAME | cut -d ' ' -f 1`
		echo $MD5_SUM > $FILENAME.md5
	fi
}

function prepare_and_copy_images()
{
	UFS_IMAGE_VER="${IMAGE_VER}_ufs_${DISTRO_IMAGE}"
	echo "[ADV] creating ${UFS_IMAGE_VER}.tgz ..."
	pushd $CURR_PATH/$ROOT_DIR/ 2>&1 > /dev/null
	mv ${IMAGE_DIR}/ufs ./${UFS_IMAGE_VER}
	sudo tar czf ${UFS_IMAGE_VER}.tgz $UFS_IMAGE_VER
	generate_md5 ${UFS_IMAGE_VER}.tgz
	mv -f ${UFS_IMAGE_VER}.tgz* $OUTPUT_DIR
	popd
}

function generate_csv()
{
	FILENAME=$1
	MD5_SUM=
	FILE_SIZE_BYTE=
	FILE_SIZE=

	if [ -e $FILENAME ]; then
		MD5_SUM=`cat ${FILENAME}.md5`
		set - `ls -l ${FILENAME}`; FILE_SIZE_BYTE=$5
		set - `ls -lh ${FILENAME}`; FILE_SIZE=$5
	fi
	
	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null

	HASH_AMSS=$(cd amss && git rev-parse --short HEAD)
	HASH_BSP=$(cd .repo/manifests && git rev-parse --short HEAD)
	HASH_DOWNLOAD=$(cd download && git rev-parse --short HEAD)
	HASH_KERNEL=$(cd amss/LE.PRODUCT.2.1.r1/apps_proc/src/kernel-5.15/kernel_platform/msm-kernel && git rev-parse --short HEAD)
	HASH_META_ADVANTECH=$(cd amss/LE.PRODUCT.2.1.r1/apps_proc/poky/meta-advantech && git rev-parse --short HEAD)
	HASH_SCRIPTS=$(cd script && git rev-parse --short HEAD)
	HASH_TOOL=$(cd tool && git rev-parse --short HEAD)
	HASH_CDT=$(cd amss/cdt && git rev-parse --short HEAD)

	cat > ${FILENAME}.csv << END_OF_CSV
ESSD Software/OS Update News
OS,Ubuntu 20.04
Part Number,N/A
Author,
Date,${DATE}
Build Number,"${BUILD_NUMBER}"
TAG,
Tested Platform,${PRODUCT}
MD5 Checksum,TGZ: ${MD5_SUM}
Image Size,${FILE_SIZE}B (${FILE_SIZE_BYTE} bytes)
Issue description, N/A
Function Addition,
Manifest, ${HASH_BSP}

QCS_AMSS, ${HASH_AMSS}
QCS_DOWNLOAD, ${HASH_DOWNLOAD}
QCS_KERNEL, ${HASH_KERNEL}
QCS_META_ADVANTECH, ${HASH_META_ADVANTECH}
QCS_SCRIPTS, ${HASH_SCRIPTS}
QCS_TOOLS, ${HASH_TOOL}
QCS_CDT, ${HASH_CDT}

END_OF_CSV

	popd
}

function prepare_and_copy_csv()
{
	echo "[ADV] creating csv files ..."
	pushd $CURR_PATH/$ROOT_DIR/ 2>&1 > /dev/null
	generate_csv ${IMAGE_VER}
	generate_md5 ${IMAGE_VER}.csv
	mv -f ${IMAGE_VER}.csv* $OUTPUT_DIR
	popd
}

function prepare_and_copy_log()
{
	LOG_DIR="log"
	LOG_FILE="${IMAGE_VER}"_log
	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	echo "[ADV] creating ${LOG_FILE}.tgz ..."
	sudo tar czf $LOG_FILE.tgz $LOG_DIR
	generate_md5 $LOG_FILE.tgz
	mv -f $LOG_FILE.tgz* $OUTPUT_DIR
	sudo rm -rf $LOG_DIR
	popd
}

# ================
#  Main procedure
# ================

# Make storage folder
if [ -e $OUTPUT_DIR ] ; then
	echo "[ADV] $OUTPUT_DIR had already been created"
else
	echo "[ADV] mkdir $OUTPUT_DIR"
	mkdir -p $OUTPUT_DIR
fi

#prepare source code and build environment
get_source_code
build_image
prepare_and_copy_images
#other
prepare_and_copy_csv
prepare_and_copy_log

cd $CURR_PATH
echo "[ADV] build script done!"
