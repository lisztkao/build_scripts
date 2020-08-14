#!/bin/bash
MACHINE_LIST=""

#DS100_projects
if [ "$ADS-B3399G" == "true" ]; then
	KERNEL_DTB=rk3399-rsb4710-a2.img
	KERNEL_CONFIG=rk3399_rsb4710a2_2G_defconfig
	MACHINE_LIST="$MACHINE_LIST adsb3399g"
	export KERNEL_DTB
	export KERNEL_CONFIG
	export MACHINE_LIST
	./rk3399_android_N7_adsb3399g_officialbuild.sh $VERSION_NUM
	[ "$?" -ne 0 ] && exit 1
fi
echo "[ADV] All done!"
