#!/bin/bash

PRODUCT=$1
VERSION=$2
SOC=$3
VER_PREFIX="nv"
echo "[ADV] DATE = ${DATE}"
echo "[ADV] STORED = ${STORED}"
echo "[ADV] BSP_URL = ${BSP_URL}"
echo "[ADV] BSP_BRANCH = ${BSP_BRANCH}"
echo "[ADV] BSP_XML = ${BSP_XML}"
echo "[ADV] MACHINE_LIST= ${MACHINE_LIST}"
echo "[ADV] PRODUCT=$PRODUCT"
echo "[ADV] VERSION=$VERSION"
echo "[ADV] SOC=$SOC"
CURR_PATH="$PWD"
VER_TAG="${VER_PREFIX}_${PRODUCT}_${SOC}_${VERSION}"
ROOT_DIR="${VER_TAG}"_"$DATE"
OUTPUT_DIR="$CURR_PATH/$STORED/$DATE"
LINUX_TEGRA="Linux_for_Tegra"
echo "$Release_Note" > Release_Note
REALEASE_NOTE="Release_Note"

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
	popd
}

function build_image()
{
	cd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	if [ "$PRODUCT" == "air020" ]; then
		echo "[ADV] building Xavier-NX / TX2-NX ..."
		sudo ./scripts/build_release.sh -s 186 -v ${VERSION}
		echo "[ADV] building Nano ..."
		sudo ./scripts/build_release.sh -s 210 -v ${VERSION}
	elif [ "$PRODUCT" == "epcr7200" ]; then
		echo "[ADV] building SOC:${SOC} ..."
		sudo ./scripts/build_release.sh -s ${SOC} -v ${VERSION}
	else
		echo "[ADV] No such projet, exit!"
		return 0
	fi
}

function build_ota_image()
{
	cd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	if [ "$PRODUCT" == "air020" ]; then
		echo "[ADV] building ota image ..."
		sudo ./scripts/build_ota.sh -s 186 -v ${VERSION}
		sudo ./scripts/build_ota.sh -s 194 -v ${VERSION}
		sudo ./scripts/build_ota.sh -s 210 -v ${VERSION}
	elif [ "$PRODUCT" == "epcr7200" ]; then
		echo "[ADV] building ota image SOC:${SOC} ..."
		sudo ./scripts/build_ota.sh -s ${SOC} -v ${VERSION}
	else
		echo "[ADV] No such projet, exit!"
		return 0
	fi
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
	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	sudo tar czf ${VER_TAG}.tgz $LINUX_TEGRA
	generate_md5 ${VER_TAG}.tgz
	sudo tar czf ota_payload_${VER_TAG}.tgz -C ota/output .
	generate_md5 ota_payload_${VER_TAG}.tgz
	popd
}

function copy_image_to_storage()
{
	echo "[ADV] copy images to $OUTPUT_DIR"
	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	generate_csv ${VER_TAG}.tgz
	mv ${VER_TAG}.tgz.csv $OUTPUT_DIR
	mv -f ${VER_TAG}.tgz $OUTPUT_DIR
	mv -f ota_payload_${VER_TAG}.tgz $OUTPUT_DIR
	mv -f *.md5 $OUTPUT_DIR
	popd
}

function save_temp_log()
{
	LOG_DIR="log"
	LOG_FILE="${VER_TAG}"_log
	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null
	echo "[ADV] creating ${LOG_FILE}.tgz ..."
	sudo tar czf $LOG_FILE.tgz $LOG_DIR
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

	pushd $CURR_PATH/$ROOT_DIR 2>&1 > /dev/null

	#HASH_BSP=$(cd $CURR_PATH/$ROOT_DIR/.repo/manifests && git rev-parse --short HEAD)
	HASH_KERNEL=$(cd kernel && git rev-parse --short HEAD)
	HASH_LINUX_FOR_TEGRA=$(cd Linux_for_Tegra && git rev-parse --short HEAD)
	VERSION=`printf "%05d\n" $VERSION`
	cat > ${FILENAME}.csv << END_OF_CSV
ESSD Software/OS Update News
OS,Ubuntu 18.04
Part Number,N/A
Author,
Date,${DATE}
Build Number,"${VERSION}"
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

function check_tag_and_checkout()
{
	FILE_PATH=$1

	if [ -d "$CURR_PATH/$ROOT_DIR/$FILE_PATH" ];then
		cd $CURR_PATH/$ROOT_DIR/$FILE_PATH
		RESPOSITORY_TAG=`git tag | grep $VER_TAG`
		if [ "$RESPOSITORY_TAG" != "" ]; then
			echo "[ADV] [FILE_PATH] repository has been tagged ,and check to this $VER_TAG version"
			REMOTE_SERVER=`git remote -v | grep push | cut -d $'\t' -f 1`
			git checkout $VER_TAG
			#git tag --delete $VER_TAG
			#git push --delete $REMOTE_SERVER refs/tags/$VER_TAG
		else
			echo "[ADV] [FILE_PATH] repository isn't tagged ,nothing to do"
		fi
		cd $CURR_PATH
	else
		echo "[ADV] Directory $ROOT_DIR/$FILE_PATH doesn't exist"
		exit 1
	fi
}

function check_tag_and_replace()
{
	FILE_PATH=$1
	REMOTE_URL=$2
	REMOTE_BRANCH=$3

	HASH_ID=`git ls-remote $REMOTE_URL $VER_TAG | awk '{print $1}'`
	if [ "$HASH_ID" != "" ]; then
		echo "[ADV] $REMOTE_URL has been tagged ,ID is $HASH_ID"
	else
		HASH_ID=`git ls-remote $REMOTE_URL | grep refs/heads/$REMOTE_BRANCH | awk '{print $1}'`
		echo "[ADV] $REMOTE_URL isn't tagged ,get latest HASH_ID is $HASH_ID"
	fi
	sed -i "s/"\$\{AUTOREV\}"/$HASH_ID/g" $ROOT_DIR/$FILE_PATH
}

function auto_add_tag()
{
	FILE_PATH=$1
	echo "[ADV] $FILE_PATH"
	cd $CURR_PATH
	if [ -d "$FILE_PATH" ];then
		cd $FILE_PATH
		echo "[ADV] get HEAD_HASH_ID"
		HEAD_HASH_ID=`git rev-parse HEAD`
		echo "[ADV] TAG_HASH_ID"
		TAG_HASH_ID=`git tag -v $VER_TAG | grep object | cut -d ' ' -f 2`
		if [ "$HEAD_HASH_ID" == "$TAG_HASH_ID" ]; then
				echo "[ADV] tag exists! There is no need to add tag"
		else
				echo "[ADV] Add tag $VER_TAG"
				REMOTE_SERVER=`git remote -v | grep push | cut -d $'\t' -f 1`
				git tag -a $VER_TAG -m "[Official Release] $VER_TAG"
				git push $REMOTE_SERVER $VER_TAG
		fi
		cd $CURR_PATH
	else
		echo "[ADV] Directory $FILE_PATH doesn't exist"
		exit 1
	fi
}

function update_revision_for_xml()
{
	FILE_PATH=$1
	PROJECT_LIST=`grep "path=" $FILE_PATH`
	XML_PATH="$PWD"

	# Delete old revision
	for PROJECT in $PROJECT_LIST
	do
		REV=`expr ${PROJECT} : 'revision="\([a-zA-Z0-9_.-]*\)"'`
		if [ "$REV" != "" ]; then
			echo "[ADV] delete revision : $REV"
			sed -i "s/ revision=\"${REV}\"//g" $FILE_PATH
		fi
	done

	# Add new revision
	for PROJECT in $PROJECT_LIST
	do
		LAYER=`expr ${PROJECT} : 'path="\([a-zA-Z0-9/-]*\)"'`
		if [ "$LAYER" != "" ]; then
			echo "[ADV] add revision for $LAYER"
			cd ../../$LAYER
			HASH_ID=`git rev-parse HEAD`
			cd $XML_PATH
			sed -i "s:path=\"${LAYER}\":path=\"${LAYER}\" revision=\"${HASH_ID}\":g" $FILE_PATH
		fi
	done
}

function create_xml_and_commit()
{
	if [ -d "$ROOT_DIR/.repo/manifests" ];then
		echo "[ADV] Create XML file"
		cd $ROOT_DIR/.repo
		cp manifest.xml manifests/$VER_TAG.xml
		cd manifests
		git checkout $BSP_BRANCH
		# add revision into xml
		update_revision_for_xml $VER_TAG.xml

		# push to github
		REMOTE_SERVER=`git remote -v | grep push | cut -d $'\t' -f 1`
		git add $VER_TAG.xml
		git commit -m "[Official Release] ${VER_TAG}"
		git push
		git tag -a $VER_TAG -F $CURR_PATH/$REALEASE_NOTE
		git push $REMOTE_SERVER $VER_TAG
		cd $CURR_PATH
	else
		echo "[ADV] Directory $ROOT_DIR/.repo/manifests doesn't exist"
		exit 1
	fi
}

function check_tag()
{
	#-- Advantech/rk3399 gitlab android source code repository
	echo "[ADV-ROOT]  $ROOT_DIR"
	echo "[ADV] JETSON_L4T_PATH = $CURR_PATH/$ROOT_DIR/Linux_for_Tegra"
	echo "[ADV] JETSON_KERNEL_PATH = $CURR_PATH/$ROOT_DIR/kernel"
	echo "[ADV] check_tag_and_checkout"
	check_tag_and_checkout $JETSON_L4T_PATH
	check_tag_and_checkout $JETSON_KERNEL_PATH

	# Add git tag
	echo "[ADV] Add tag"
	auto_add_tag $CURR_PATH/$ROOT_DIR/Linux_for_Tegra
	auto_add_tag $CURR_PATH/$ROOT_DIR/kernel

	# Create manifests xml and commit
	echo "[ADV] create_xml_and_commit"
	create_xml_and_commit
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

