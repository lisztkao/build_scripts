#!/bin/bash
MACHINE_LIST=""
#AIR-020_projects
if [ "$air020" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST air020"
	export MACHINE_LIST
	./nv_ubuntu_officialbuild.sh air020 "${VERSION}" "${SOC}" "${VER_PREFIX}"
fi

#EPC-R7200_projects
if [ "$epcr7200" == "true" ]; then
	MACHINE_LIST="$MACHINE_LIST epcr7200"
	export MACHINE_LIST
	./nv_ubuntu_officialbuild.sh epcr7200 "${VERSION}" "${SOC}" "${VER_PREFIX}"
fi
echo "[ADV] All done!"


