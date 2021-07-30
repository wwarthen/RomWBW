#!/bin/bash

# fail on any error
set -e

export ROM_PLATFORM
export ROM_CONFIG
export ROMSIZE

if [ "${ROM_PLATFORM}" == "dist" ] ; then
	echo "!!!DISTRIBUTION BUILD!!!"
	ROM_PLATFORM="DYNO"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="EZZ80"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="EZZ80"; ROM_CONFIG="tz80"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="MK4"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="N8"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="ext"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="nat"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="ext"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="nat"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="nat_zz"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="nat_zzr"; ROMSIZE="256"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="kio"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="mt"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="duart"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="skz"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="zrc"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SBC"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SBC"; ROM_CONFIG="simh"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="MBC"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="126"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="130"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="131"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="140"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="UNA"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="ZETA"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	ROM_PLATFORM="ZETA2"; ROM_CONFIG="std"; ROMSIZE="512"; bash Build.sh
	exit
fi

###if [ $1 == '-d' ] ; then
###	shift
###	diffdir=$1
###	shift
###	if [ -f $diffdir/build.inc ] ; then
###		timestamp=$(grep TIMESTAMP $diffdir/build.inc | awk '{print $3}' | tr -d '\015"')
###		echo diff build using $timestamp
###	fi
###fi

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

while [ ! '(' "${ROMSIZE}" = 1024 -o "${ROMSIZE}" = 512 -o "${ROMSIZE}" = 256 -o "${ROMSIZE}" = 128 ')' ] ; do
	echo -n "Romsize :"
	read ROMSIZE
done

if [ -z "${ROMNAME}" ] ; then
	ROMNAME=${ROM_PLATFORM}_${ROM_CONFIG}
fi

TIMESTAMP=$(date +%Y-%m-%d)

CONFIGFILE=Config/${ROM_PLATFORM}_${ROM_CONFIG}.asm

echo Building $ROMNAME for $ROM_PLATFORM $ROM_CONFIG $ROMSIZE

cat <<- EOF > build.inc
; RomWBW Configured for ${ROM_PLATFORM} ${ROM_CONFIG} ${TIMESTAMP}
;
#DEFINE	TIMESTAMP	"${TIMESTAMP}"
;
ROMSIZE		.EQU	${ROMSIZE}
;
#INCLUDE "${CONFIGFILE}"
;
EOF

export OBJECTS
OBJECTS="${ROMNAME}.rom"
if [ "${ROM_PLATFORM}" != "UNA" ] ; then
	OBJECTS+=" ${ROMNAME}.com ${ROMNAME}.upd"
fi

#echo OBJECTS=${OBJECTS}

make ROM_PLATFORM=${ROM_PLATFORM} ROM_CONFIG=${ROM_CONFIG} ROMSIZE=${ROMSIZE}
