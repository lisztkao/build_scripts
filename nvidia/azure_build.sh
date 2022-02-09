#!/bin/bash
TOPDIR=`pwd`
DOCKER_IMAGE="advrisc/u18.04-imx8lbv1:latest"
CONTAINER_NAME="jetson_linux_risc"
WORK_DIR="/ext/docker/nvidia/"
GIT_BUILD_SCRIPT="https://github.com/lisztkao/build_scripts.git"

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

git clone $GIT_BUILD_SCRIPT $WORK_DIR
docker exec $CONTAINER_NAME /bin/bash -c "sudo chown adv:adv -R BSP"
#docker exec $CONTAINER_NAME /bin/bash -c "cd BSP/nvidia/;ls -a;source ./azure_docker_build.sh -p $PRODUCT -s $SOC -v $VERSION -d $DEVICEON"
#docker stop $CONTAINER_NAME
#docker rm $CONTAINER_NAME



	
