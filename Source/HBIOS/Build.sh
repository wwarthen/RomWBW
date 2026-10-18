#!/bin/sh

# fail on any error
set -e

export ROM_PLATFORM
export ROM_CONFIG
export ROMSIZE
export RAMSIZE
export CPUFAM

if [ "${ROM_PLATFORM}" = "dist" ] ; then
	echo "!!!DISTRIBUTION BUILD!!!"
	ROM_PLATFORM="SBC"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="SBC"; ROM_CONFIG="simh_std"; (. ./Build.sh)
	ROM_PLATFORM="MBC"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="ZETA"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="ZETA2"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="N8"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="N8PC"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="MK4"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="RC2014"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="RCEZ80"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="kio_std"; (. ./Build.sh)
	ROM_PLATFORM="EZZ80"; ROM_CONFIG="easy_std"; (. ./Build.sh)
	ROM_PLATFORM="EZZ80"; ROM_CONFIG="tiny_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="skz_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="zrc_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="zrc512_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="ez512_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ80"; ROM_CONFIG="k80w_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="ext_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="nat_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ180"; ROM_CONFIG="z1rcc_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="ext_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="nat_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="zz80mb_std"; (. ./Build.sh)
	ROM_PLATFORM="RCZ280"; ROM_CONFIG="zzrcc_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc126_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc130_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc131_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc140_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc503_std"; (. ./Build.sh)
	ROM_PLATFORM="SCZ180"; ROM_CONFIG="sc700_std"; (. ./Build.sh)
	ROM_PLATFORM="GMZ180"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="DYNO"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="RPH"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="Z80RETRO"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="SZ180"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="DUO"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="HEATH"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="EPITX"; ROM_CONFIG="std"; (. ./Build.sh)
#	ROM_PLATFORM="MON"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="NABU"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="SZ80"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="SZ80"; ROM_CONFIG="t35_std"; (. ./Build.sh)
	ROM_PLATFORM="MSX"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="MECB"; ROM_CONFIG="std"; (. ./Build.sh)
	ROM_PLATFORM="UNA"; ROM_CONFIG="std"; (. ./Build.sh)
	exit
fi

# prompt if no match

platforms=$(find Config -name \*.asm -print | \
	sed -e 's,Config/,,' -e 's/_.*$//' | sort -u | tr '\n' ' ')

while ! echo ${platforms} | grep -q -w -s "${ROM_PLATFORM}" ; do
	printf "Enter platform [%s]: " "$platforms"
	read -r ROM_PLATFORM
	ROM_PLATFORM=$(echo "${ROM_PLATFORM}" | tr '[:lower:]' '[:upper:]')
done

configs=$(find Config -name ${ROM_PLATFORM}_\*.asm -print | \
	sed -e 's,Config/,,' -e "s/${ROM_PLATFORM}_//" -e 's/.asm$//' | sort | tr '\n' ' ')

while ! echo ${configs} | grep -q -w -s "${ROM_CONFIG}" ; do
	printf "Enter config for $ROM_PLATFORM [%s]: " "$configs"
	read -r ROM_CONFIG
done

CONFIGFILE="Config/${ROM_PLATFORM}_${ROM_CONFIG}.asm"

if [ -z "${ROMNAME}" ] ; then
	ROMNAME="${ROM_PLATFORM}_${ROM_CONFIG}"
fi

# Work around for poor file timestamp granularity issues
# in some build environments

rm -f build.inc
sleep 1

printf "\n\nBuilding $ROM_PLATFORM $ROM_CONFIG\n\n"

TIMESTAMP="$(date +%Y-%m-%d)"

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


$MAKE hbios_env.sh

. ./hbios_env.sh

printf "Creating ${ROMSIZE}K ROM named ${ROMNAME}.rom\n"

export OBJECTS
OBJECTS="${ROMNAME}.rom"

if [ "${ROM_PLATFORM}" != "UNA" ] ; then
	OBJECTS="${OBJECTS} ${ROMNAME}.com ${ROMNAME}.upd"
fi

#echo OBJECTS=${OBJECTS}

$MAKE ROM_PLATFORM=${ROM_PLATFORM} ROM_CONFIG=${ROM_CONFIG} ROMSIZE=${ROMSIZE} RAMSIZE=${RAMSIZE} ROMDISKSIZE=${ROMDISKSIZE} RAMDISKSIZE=${RAMDISKSIZE}
