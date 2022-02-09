#!/bin/bash
TOPDIR=`pwd`
DOCKER_IMAGE="advrisc/u18.04-imx8lbv1:latest"
CONTAINER_NAME="jetson_linux_risc"
WORK_DIR="/ext/docker/nvidia/"
GIT_BUILD_FOLDER="build_scripts"
GIT_BUILD_SCRIPT="https://github.com/lisztkao/${GIT_BUILD_FOLDER}.git"
SAS_KEY="?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacupitfx&se=2022-02-09T15:40:31Z&st=2022-02-09T07:40:31Z&spr=https&sig=nxS6KIrgyzsGSKWA6tWUgGI658i18uLWqDBKpTLF4MQ%3D"
STORAGE_ACCOUNT="riscsw"
BLOB_CONTAINER="image"
BLOB_FOLDER="RISC-Nvidia-Ubuntu18"
BUILD_IMAGE_SCRIPT="azure_docker_build.sh"
AZCOPY_URL="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${BLOB_CONTAINER}/${BLOB_FOLDER}/${SAS_KEY}"
DATE=`date +%F`
STORED="stored"
OUTPUT_DIR="$STORED/$DATE"

while [ $# -gt 0 ]; do
	case ${1} in
		-p)
			PRODUCT="${2}"
			shift 2
			;;
		-v)
			VERSION="${2}"
			shift 2
			;;
		-d)
			DEVICEON="${2}"
			shift 2
			;;
		-s)
			SOC="${2}"
			shift 2
			;;
		*)
			echo "Error: Invalid option ${1}"
			exit 1
			;;
		esac
done

mkdir -p $WORK_DIR > /dev/null
docker pull $DOCKER_IMAGE
docker run -t -d --name $CONTAINER_NAME -v $WORK_DIR:/home/adv/BSP:rw --privileged $DOCKER_IMAGE
container=`docker ps -a | grep $CONTAINER_NAME`
if [ -z "$container" ]; then 
	echo "[ERROR] Failed to create docker container!!!"
	exit 1
fi
status=`docker ps -a | grep $CONTAINER_NAME | grep Exited`
if [ ! -z "$status" ]; then
	echo "[ERROR] Docker container is not running!"
	exit 1
fi

sudo git clone $GIT_BUILD_SCRIPT $WORK_DIR/${GIT_BUILD_FOLDER}/
docker exec $CONTAINER_NAME /bin/bash -c "sudo chown adv:adv -R BSP"
docker exec $CONTAINER_NAME /bin/bash -c "cd BSP/;cp ${GIT_BUILD_FOLDER}/nvidia/${BUILD_IMAGE_SCRIPT} .;ls -a"
docker exec $CONTAINER_NAME /bin/bash -c "cd BSP/;source ./${BUILD_IMAGE_SCRIPT} -p $PRODUCT -s $SOC -v $VERSION -d $DEVICEON"
azcopy cp $WORK_DIR/$OUTPUT_DIR $AZCOPY_URL
#docker exec $CONTAINER_NAME /bin/bash -c "cd BSP/;cp nvidia/${BUILD_IMAGE_SCRIPT} .;ls -a;"
#azcopy cp $WORK_DIR/$OUTPUT_DIR $AZCOPY_URL --recursive
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME



	
