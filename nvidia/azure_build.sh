#!/bin/bash
TOPDIR=`pwd`
DOCKER_IMAGE="advrisc/u18.04-imx8lbv1:latest"

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

echo "VERSION:$VERSION"
echo "air020:$air020"
echo "sudo docker pull $DOCKER_IMAGE"
sudo docker pull $DOCKER_IMAGE
export DOCK_ID=$(sudo docker run -it --name jetson_linux_risc -v $TOPDIR:/home/adv/BSP:rw --privileged $DOCKER_IMAGE /bin/bash)
echo "sudo docker exec $DOCKER_ID /bin/bash -c ./azure_docker_build.sh"
sudo docker exec $DOCKER_ID /bin/bash -c "./azure_docker_build.sh"
sudo docker stop $DOCK_ID
sudo docker rm $DOCK_ID


	
