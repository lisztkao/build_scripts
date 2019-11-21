#!/bin/bash
MACHINE_LIST=""

if [ $RSB4411A1 == true ]; then
	MACHINE_LIST="$MACHINE_LIST rsb_4411_a1"
fi
if  [ $ROM5720A1 == true ]; then
	MACHINE_LIST="$MACHINE_LIST rom5720_a1"
fi
if  [ $ROM7720A1 == true ]; then
	MACHINE_LIST="$MACHINE_LIST rom7720_a1"
fi

export MACHINE_LIST
./imx6_android_P9_dailybuild.sh
