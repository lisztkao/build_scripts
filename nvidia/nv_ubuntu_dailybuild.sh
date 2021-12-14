#!/bin/bash

PRODUCT=$1
VERSION=$2
VER_PREFIX="nv"
echo "[ADV] DATE = ${DATE}"
echo "[ADV] STORED = ${STORED}"
echo "[ADV] BSP_URL = ${BSP_URL}"
echo "[ADV] BSP_BRANCH = ${BSP_BRANCH}"
echo "[ADV] BSP_XML = ${BSP_XML}"
echo "[ADV] MACHINE_LIST= ${MACHINE_LIST}"
CURR_PATH="$PWD"
VER_TAG="${VER_PREFIX}_${PRODUCT}_${VERSION}"
ROOT_DIR="${VER_TAG}"_"$DATE"
OUTPUT_DIR="$CURR_PATH/$STORED/$DATE"
LINUX_TEGRA="Linux_for_Tegra"

# ===========
#  Functions
# ===========
function get_source_code()
{
    echo "[ADV] get nVidia source code"
	
	mkdir $ROOT_DIR
    pushd $ROOT_DIR 2>&1 > /dev/null
    repo init -u $BSP_URL
    repo sync -j8
	
	KERNELDIR="kernel"
	if [ -f $KERNELDIR ]; then
		pushd $KERNELDIR 2>&1 > /dev/null
		touch version
		echo $VERSION > version
		popd
	fi
	popd
}

function build_image()
{
	pushd $ROOT_DIR 2>&1 > /dev/null
	echo "[ADV] building Xavier-NX / TX2-NX ..."
	source ./scripts/build_release.sh -s 186
	#echo "[ADV] building Nano ..."
	#source ./scripts/build_release.sh -s 210
	popd
}

function generate_md5()
{
    FILENAME=$1

    if [ -e $FILENAME ]; then
        MD5_SUM=`md5sum -b $FILENAME | cut -d ' ' -f 1`
        echo $MD5_SUM > $FILENAME.md5
    fi
}

function prepare_images()
{
    echo "[ADV] creating ${VER_TAG}.tgz ..."
	pushd $ROOT_DIR 2>&1 > /dev/null
    tar czf ${VER_TAG}.tgz $LINUX_TEGRA
    generate_md5 ${VER_TAG}.tgz
	popd
}

function copy_image_to_storage()
{
    echo "[ADV] copy images to $OUTPUT_DIR"
	pushd $ROOT_DIR 2>&1 > /dev/null
    generate_csv ${VER_TAG}.tgz
    mv ${VER_TAG}.tgz.csv $OUTPUT_DIR
    mv -f ${VER_TAG}.tgz $OUTPUT_DIR
    mv -f *.md5 $OUTPUT_DIR
	popd
}

function save_temp_log()
{
	LOG_DIR="log"
	LOG_FILE="${VER_TAG}"_log	
    pushd $ROOT_DIR 2>&1 > /dev/null
    echo "[ADV] creating ${LOG_FILE}.tgz ..."
    tar czf $LOG_FILE.tgz $LOG_DIR
    generate_md5 $LOG_FILE.tgz
    mv -f $LOG_FILE.tgz $OUTPUT_DIR
    mv -f $LOG_FILE.tgz.md5 $OUTPUT_DIR
    rm -rf $LOG_DIR
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
	
	pushd $ROOT_DIR 2>&1 > /dev/null

    #HASH_BSP=$(cd $CURR_PATH/$ROOT_DIR/.repo/manifests && git rev-parse --short HEAD)
    HASH_KERNEL=$(cd kernel && git rev-parse --short HEAD)
    HASH_LINUX_FOR_TEGRA=$(cd Linux_for_Tegra && git rev-parse --short HEAD)

    cat > ${FILENAME}.csv << END_OF_CSV
ESSD Software/OS Update News
OS,Ubuntu 18.04
Part Number,N/A
Author,
Date,${DATE}
Build Number,${VERSION}
TAG,
Tested Platform,${NEW_MACHINE}
MD5 Checksum,TGZ: ${MD5_SUM}
Image Size,${FILE_SIZE}B (${FILE_SIZE_BYTE} bytes)
Issue description, N/A
Function Addition,
Manifest, ${HASH_BSP}

JETSON_KERNEL, ${HASH_KERNEL}
JETSON_L4T, ${HASH_LINUX_FOR_TEGRA}

END_OF_CSV

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

for NEW_MACHINE in $MACHINE_LIST
do
	echo "[ADV] NEW_MACHINE = $NEW_MACHINE"
	get_source_code
	build_image
	prepare_images
	copy_image_to_storage
	save_temp_log
done
cd $CURR_PATH
echo "[ADV] build script done!"

