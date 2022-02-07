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
docker run -dit --name $CONTAINER_NAME -v $TOPDIR:/home/adv/BSP:rw --privileged $DOCKER_IMAGE /bin/bash
container=`docker ps -a | grep $CONTAINER_NAME`
if [ -z "$container" ]; then
	echo "Failed to create docker container!!!"
	exit 1
fi
docker start $CONTAINER_NAME
docker exec -it $CONTAINER_NAME /bin/sh
docker exec $CONTAINER_NAME /bin/bash -c "./azure_docker_build.sh"
echo "sudo docker exec $CONTAINER_NAME /bin/bash -c ./azure_docker_build.sh"
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID


	
