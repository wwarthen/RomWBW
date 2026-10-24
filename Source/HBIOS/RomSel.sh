#!/bin/sh

# fail on any error
set -e

echo "=== Interactive ROM Identifier Selection ==="

printf "ROMFILE: %s\n" ${ROMFILE}
printf "ROM_PLATFORM: %s\n" ${ROM_PLATFORM}
printf "ROM_CONFIG: %s\n" ${ROM_CONFIG}

if ! { [ -t 0 ] || [ -c /dev/tty ]; }; then
	echo "ERROR: Not running in an interactive terminal context."
	exit 1
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

echo "ROM := ${ROM_PLATFORM}_${ROM_CONFIG}" >${ROMFILE}
exit 0



# printf "Enter ROM identifier (<plt>_<cfg>): "
# read CHOICE
# if [ -z "$CHOICE" ]; then
# 	echo "ERROR: No selection made. Aborting."
# 	exit 1
# fi
# echo "ROM := $CHOICE" >$ROMFILE
