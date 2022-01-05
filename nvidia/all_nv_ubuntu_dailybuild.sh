#!/bin/bash
MACHINE_LIST=""
#AIR-020_projects
if [ "$air020" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST air020"
	export MACHINE_LIST
	./nv_ubuntu_dailybuild.sh air020 "${VERSION}"
fi

if [ "$air020_deviceon" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST air020"
	export MACHINE_LIST
	./nv_ubuntu_dailybuild_deviceon.sh air020 "${VERSION}"
fi

#EPC-R7200_projects
if [ "$epcr7200" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST epcr7200"
	export MACHINE_LIST
	./nv_ubuntu_dailybuild.sh epcr7200 "${VERSION}" "${SOC}"
fi

if [ "$epcr7200_deviceon" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST epcr7200"
	export MACHINE_LIST
	./nv_ubuntu_dailybuild_deviceon.sh epcr7200 "${VERSION}" "${SOC}"
fi

echo "[ADV] All done!"




