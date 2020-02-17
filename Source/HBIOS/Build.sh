#!/bin/bash

CPMCP=../../Tools/`uname`/cpmcp

# positional arguments
platform=$1
config=$2
romsize=$3
romname=$4

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

while [ ! '(' "$romsize" = 1024 -o "$romsize" = 512 ')' ] ; do
	echo -n "Romsize :"
	read romsize
done

if [ -z "$romname" ] ; then
	romname=${platform}_${config}
fi
echo Building for $romname for $platform $config $romsize

if [ $platform == UNA ] ; then
	CBIOS=../CBIOS/cbios_una.bin
else
	CBIOS=../CBIOS/cbios_wbw.bin
fi

Apps=(assign fdu format mode osldr rtc survey syscopy sysgen talk timer xm inttest)
timestamp=$(date +%Y-%m-%d)

blankfile=Blank${romsize}.dat
romdiskfile=RomDisk.tmp
romfmt=wbw_rom${romsize}
outdir=../../Binary

echo "creating empty rom disk of size $romsize in $blankfile"
LANG=en_US.US-ASCII tr '\000' '\345' </dev/zero | dd of=$blankfile bs=1024 count=`expr $romsize - 128`

# # Initialize working variables
# $OutDir = "../../Binary"		# Output directory for final image file
# $RomFmt = "wbw_rom${RomSize}"		# Location of files to imbed in ROM disk
# $BlankROM = "Blank${RomSize}KB.dat"	# An initial "empty" image for the ROM disk of propoer size
# $RomDiskFile = "RomDisk.tmp"		# Temporary filename used to create ROM disk image
# $RomFile = "${OutDir}/${RomName}.rom"	# Final name of ROM image
# $ComFile = "${OutDir}/${RomName}.com"	# Final name of COM image (command line loadable HBIOS/CBIOS)
# $ImgFile = "${OutDir}/${RomName}.img"	# Final name of IMG image (memory loadable HBIOS/CBIOS image)

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

cp ../CPM22/OS2CCP.bin ccp.bin
cp ../CPM22/OS3BDOS.bin bdos.bin
cp ../ZCPR-DJ/zcpr.bin zcpr.bin
cp ../ZSDOS/zsdos.bin zsdos.bin
cp ../Forth/camel80.bin camel80.bin

make -f Makefile dbgmon.bin prefix.bin romldr.bin eastaegg.bin nascom.bin \
	tastybasic.bin imgpad.bin imgpad0.bin
if [ $platform != UNA ] ; then
	make -f Makefile hbios_rom.bin hbios_app.bin hbios_img.bin
fi

cat ccp.bin bdos.bin $CBIOS >cpm.bin
cat zcpr.bin zsdos.bin $CBIOS >zsys.bin

cat prefix.bin cpm.bin >cpm.sys
cat prefix.bin zsys.bin >zsys.sys

cat romldr.bin eastaegg.bin dbgmon.bin cpm.bin zsys.bin >osimg.bin
cat camel80.bin nascom.bin tastybasic.bin imgpad0.bin >osimg1.bin

echo "Building ${romsize}KB $romname ROM disk data file..."
cp $blankfile $romdiskfile
$CPMCP -f $romfmt $romdiskfile ../RomDsk/ROM_${romsize}KB/*.* 0:

if [ $(find ../RomDsk/$platform -type f -print 2>/dev/null | wc -l) -gt 0 ] ; then
	$CPMCP -f $romfmt $romdiskfile ../RomDsk/$platform/*.* 0:
fi

for i in ${apps[@]} ; do
	$CPMCP -f $romfmt $romdiskfile ../../Binary/Apps/$i.com 0:
done

for i in *.sys ; do
	$CPMCP -f $romfmt $romdiskfile $i 0:
done

if [ $platform != UNA ] ; then
	cp osimg.bin $outdir/UNA_WBW_SYS.bin
	cp $romdiskfile $outdir/UNA_WBW_ROM$romsize.bin
	cat ../UBIOS/UNA-BIOS.BIN osimg.bin ../UBIOS/FSFAT.BIN $romdiskfile >$romname.rom
else
	cat hbios_rom.bin osimg.bin osimg1.bin osimg.bin $romdiskfile >$romname.rom
	cat hbios_app.bin osimg.bin > $romname.com
	cat hbios_img.bin osimg.bin > $romname.img
fi

#rm $romdiskfile
