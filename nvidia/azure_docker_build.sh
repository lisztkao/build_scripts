#!/bin/bash -ex
sudo apt-get update
sudo apt-get install --reinstall kmod

BSP_URL_EPCR7200="https://AIM-Linux@dev.azure.com/AIM-Linux/EPC-R7200/_git/manifests"
BSP_URL_AIR020="https://AIM-Linux@dev.azure.com/AIM-Linux/AIR-020/_git/manifests"

export MACHINE_LIST="$MACHINE_LIST"
export BUILD_NUMBER="$BUILD_NUMBER"
export DATE=`date +%F`
export STORED="./stored"
export FTP_SITE="172.22.15.143"
export FTP_DIR="RISC-Nvidia-Ubuntu18"
export BSP_URL
export BSP_BRANCH="master"
export BSP_XML="default.xml"
export RELEASE_VERSION="V0001"
export BUILDALL_DIR="build_all"
export PATH="/home/adv/bin:${PATH}"

mkdir $STORED
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
		*)
			echo "Error: Invalid option ${1}"
			exit 1
			;;
		esac
done

if [[ "$PRODUCT" == *"7200"* ]]; then
	BSP_URL=$BSP_URL_EPCR7200
else
	BSP_URL=$BSP_URL_AIR020
fi

set +e
if [ "$DEVICEON" == "1" ]; then	
	./nv_ubuntu_dailybuild_deviceon.sh $PRODUCT ${VERSION}
else
	./nv_ubuntu_dailybuild.sh $PRODUCT ${VERSION}
fi
echo "[ADV] All done!"
rc="$?"
set -e
#---------------------------
cd $STORED/$DATE
pftp -v -n ${FTP_SITE} <<-EOF
  user "essci\\user" "P@ssw0rdQA"
  cd "Product\\${FTP_DIR}\\Daily Build"
  mkdir $DATE
  cd $DATE
  prompt
  binary
  mput *
  close
  quit
EOF

sudo rm * -rf
#---[return code]------------
if [ "$rc" == "0" ]; then
  exit 0;
else
  exit 1;
fi



	
