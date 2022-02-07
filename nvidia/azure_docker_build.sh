#!/bin/bash -ex
sudo apt-get update
sudo apt-get install --reinstall kmod

#git config --global user.name lisztkao
#git config --global user.email lisztru@gmail.com
#git clone https://github.com/lisztkao/build_scripts.git

export MACHINE_LIST="$MACHINE_LIST"
export BUILD_NUMBER="$BUILD_NUMBER"
export DATE=`date +%F`
export STORED="./stored"
mkdir $STORED

export FTP_SITE="172.22.15.143"
export FTP_DIR="RISC-Nvidia-Ubuntu18"

#--- [platform specific] ---

# export BSP_URL="https://gitlab.wise-paas.com/air-020/manifests.git"
export BSP_URL="https://AIM-Linux@dev.azure.com/AIM-Linux/AIR-020/_git/manifests"
export BSP_BRANCH="master"
export BSP_XML="default.xml"
export RELEASE_VERSION="V0001"
export BUILDALL_DIR="build_all"

export PATH="/home/adv/bin:${PATH}"
TOPDIR=`pwd`

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
export TOPDIR
export VERSION
set +e
./all_nv_ubuntu_dailybuild.sh
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



	
