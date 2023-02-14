#!/bin/bash

# fail on any error
set -e

export ROM_PLATFORM
export ROM_CONFIG
export ROMSIZE
export CPUFAM

if [ "${ROM_PLATFORM}" == "dist" ] ; then
	echo "!!!DISTRIBUTION BUILD!!!"
	ROM_PLATFORM="DYNO"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="MK4"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="N8"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="ext"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="nat"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="ext"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="nat"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="zz80mb"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="zzrc"; bash Build.sh
#	ROM_PLATFORM="RCZ80"; ROM_CONFIG="mt"; bash Build.sh
#	ROM_PLATFORM="RCZ80"; ROM_CONFIG="duart"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="kio"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="easy"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="tiny"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="skz"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="zrc"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="zrc_ram"; bash Build.sh
	ROM_PLATFORM="RPH"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="SBC"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="SBC"; ROM_CONFIG="simh"; bash Build.sh
	ROM_PLATFORM="MBC"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="126"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="130"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="131"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="140"; bash Build.sh
	ROM_PLATFORM="UNA"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="ZETA"; ROM_CONFIG="std"; bash Build.sh
	ROM_PLATFORM="ZETA2"; ROM_CONFIG="std"; bash Build.sh
	exit
fi

# prompt if no match
platforms=($(find Config -name \*.asm -print | \
	sed -e 's,Config/,,' -e 's/_.*$//' | sort -u))

while ! echo ${platforms[@]} | grep -q -w -s "${ROM_PLATFORM}" ; do
	echo -n "Enter platform [" ${platforms[@]} "] :"
	read ROM_PLATFORM
done

configs=$(find Config -name ${ROM_PLATFORM}_\* -print | \
	sed -e 's,Config/,,' -e "s/${ROM_PLATFORM}_//" -e "s/.asm//")
while ! echo ${configs[@]} | grep -s -w -q "${ROM_CONFIG}" ; do
	echo -n "Enter config for $platform [" ${configs[@]} "] :"
	read ROM_CONFIG
done

CONFIGFILE=Config/${ROM_PLATFORM}_${ROM_CONFIG}.asm

if [ -z "${ROMNAME}" ] ; then
	ROMNAME=${ROM_PLATFORM}_${ROM_CONFIG}
fi

echo -e "\n\nBuilding $ROM_PLATFORM $ROM_CONFIG\n\n"

TIMESTAMP=$(date +%Y-%m-%d)

if [ "$1" = "-d" ] ; then
	shift
	diffdir=$1
	shift
	if [ -f $diffdir/build.inc ] ; then
		timestamp=$(grep TIMESTAMP $diffdir/build.inc | awk '{print $3}' | tr -d '\015"')
		echo diff build using $timestamp
	fi
fi

CONFIGFILE=Config/${ROM_PLATFORM}_${ROM_CONFIG}.asm

cat <<- EOF > build.inc
; RomWBW Configured for ${ROM_PLATFORM} ${ROM_CONFIG} ${TIMESTAMP}
;
#DEFINE	TIMESTAMP	"${TIMESTAMP}"
#DEFINE CONFIG		"${ROM_PLATFORM}_${ROM_CONFIG}"
;
#INCLUDE "${CONFIGFILE}"
;
EOF

make hbios_env.sh
source hbios_env.sh

echo Creating ${ROMSIZE}K ROM named ${ROMNAME}.rom

export OBJECTS
OBJECTS="${ROMNAME}.rom"
if [ "${ROM_PLATFORM}" != "UNA" ] ; then
	OBJECTS+=" ${ROMNAME}.com ${ROMNAME}.upd"
fi

#echo OBJECTS=${OBJECTS}

make ROM_PLATFORM=${ROM_PLATFORM} ROM_CONFIG=${ROM_CONFIG} ROMSIZE=${ROMSIZE}
