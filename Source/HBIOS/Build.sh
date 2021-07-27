#!/bin/bash

# fail on any error
set -e

# overcome clock resolution issues
sleep 2

timestamp=$(date +%Y-%m-%d)
#timestamp="2020-02-24"

if [ $1 == '-d' ] ; then
	shift
	diffdir=$1
	shift
	if [ -f $diffdir/build.inc ] ; then
		timestamp=$(grep TIMESTAMP $diffdir/build.inc | awk '{print $3}' | tr -d '\015"')
		echo diff build using $timestamp
	fi
fi

# positional arguments
platform=$1
config=$2
romsize=$3
romname=$4

export platform

# prompt if no match
platforms=($(find Config -name \*.asm -print | \
	sed -e 's,Config/,,' -e 's/_.*$//' | sort -u))

while ! echo ${platforms[@]} | grep -q -w -s "$platform" ; do
	echo -n "Enter platform [" ${platforms[@]} "] :"
	read platform
done

configs=$(find Config -name ${platform}_\* -print | \
	sed -e 's,Config/,,' -e "s/${platform}_//" -e "s/.asm//")
while ! echo ${configs[@]} | grep -s -w -q "$config" ; do
	echo -n "Enter config for $platform [" ${configs[@]} "] :"
	read config
done
configfile=Config/${platform}_${config}.asm

while [ ! '(' "$romsize" = 1024 -o "$romsize" = 512 -o "$romsize" = 256 -o "$romsize" = 128 ')' ] ; do
	echo -n "Romsize :"
	read romsize
done

if [ -z "$romname" ] ; then
	romname=${platform}_${config}
fi
echo Building for $romname for $platform $config $romsize

if [ $platform == UNA ] ; then
	BIOS=una
else
	BIOS=wbw
fi

outdir=../../Binary

cat <<- EOF > build.inc
; RomWBW Configured for $platform $config $timestamp
;
#DEFINE	TIMESTAMP	"$timestamp"
;
ROMSIZE		.EQU	$romsize
;
#INCLUDE "$configfile"
;
EOF

make prereq

make dbgmon.bin romldr.bin

if [ $platform != UNA ] ; then
	make nascom.bin tastybasic.bin game.bin eastaegg.bin updater.bin usrrom.bin imgpad2.bin
	make hbios_rom.bin hbios_app.bin hbios_img.bin
fi

echo "Building $romname output files..."

cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$BIOS.bin ../CPM22/cpm_$BIOS.bin >osimg.bin
cat romldr.bin dbgmon.bin ../ZSDOS/zsys_$BIOS.bin >osimg_small.bin

if [ $platform != UNA ] ; then
	cat camel80.bin nascom.bin tastybasic.bin game.bin eastaegg.bin netboot.mod updater.bin usrrom.bin >osimg1.bin
	cat imgpad2.bin >osimg2.bin
fi

if [ $platform = UNA ] ; then
	cp osimg.bin $outdir/UNA_WBW_SYS.bin
	cp ../RomDsk/rom${romsize}_una.dat $outdir/UNA_WBW_ROM$romsize.bin
	cat ../UBIOS/UNA-BIOS.BIN osimg.bin ../UBIOS/FSFAT.BIN ../RomDsk/rom${romsize}_una.dat >$romname.rom
else
	cat hbios_rom.bin osimg.bin osimg1.bin osimg2.bin ../RomDsk/rom${romsize}_wbw.dat >$romname.rom
	cat hbios_rom.bin osimg.bin osimg1.bin osimg2.bin >$romname.upd
	cat hbios_app.bin osimg_small.bin > $romname.com
fi
