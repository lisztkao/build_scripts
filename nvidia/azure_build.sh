#!/bin/bash
TOPDIR=`pwd`
DOCKER_IMAGE="advrisc/u18.04-imx8lbv1:latest"
CONTAINER_NAME="jetson_linux_risc"
while [ $# -gt 0 ]; do
	case ${1} in
		-air020)
			air020="${2}"
			shift 2
			;;
		-VERSION)
			VERSION="${2}"
			shift 2
			;;
		*)
			echo "Error: Invalid option ${1}"
			exit 1
			;;
		esac
done

echo "TOPDIR:$TOPDIR"
echo "VERSION:$VERSION"
echo "air020:$air020"
echo "sudo docker pull $DOCKER_IMAGE"

docker pull $DOCKER_IMAGE
docker run -t -d --name $CONTAINER_NAME -v $TOPDIR:/home/adv/BSP:rw --privileged $DOCKER_IMAGE
echo "docker run -t -d --name $CONTAINER_NAME -v $TOPDIR:/home/adv/BSP:rw --privileged $DOCKER_IMAGE"
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
docker ps -a | grep $CONTAINER_NAME | grep Exited
cd "$TOPDIR/nvidia/"
docker exec $CONTAINER_NAME /bin/bash -c "./azure_docker_build.sh"
echo "docker exec $CONTAINER_NAME /bin/bash -c ./azure_docker_build.sh"
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME


	
