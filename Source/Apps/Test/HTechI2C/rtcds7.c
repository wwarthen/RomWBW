/* RTCDS7.C, DS1307 RTC date/time display, via BF_I2C. */

#include <stdio.h>
#include "bfi2c.h"
#include "buildid.h"

#define DS1307_ADDR	0x68
#define DS1307_W	((DS1307_ADDR << 1) | 0)
#define DS1307_R	((DS1307_ADDR << 1) | 1)

#define REG_SECONDS	0x00
#define REG_MINUTES	0x01
#define REG_HOURS	0x02
#define REG_DATE	0x04
#define REG_MONTH	0x05
#define REG_YEAR	0x06

/* BCD register -> 0-99. mask strips non-BCD control bits (CH,
   12/24 mode) from the tens nibble. */
bcdval(raw, mask)
unsigned char raw, mask;
{
    return (((raw & mask) >> 4) * 10) + (raw & 0x0f);
}

/* read DS1307 registers 0x00-0x07 into buf. returns 0 ok,
   nonzero on the first unacked step. */
readclock(buf)
unsigned char *buf;
{
    unsigned char i, r;

    if (r = bf_i2cstart(DS1307_W)) {
	if (r != 3)
	    bf_i2cstop(0);
	return 1;
    }
    if (bf_i2cwrite(REG_SECONDS)) {
	bf_i2cstop(0);
	return 1;
    }
    if (bf_i2crepstart(DS1307_R)) {
	bf_i2cstop(0);
	return 1;
    }
    for (i = 0; i < 7; i++) {
	if (bf_i2cread(0, &buf[i])) {
	    bf_i2cstop(0);
	    return 1;
	}
    }
    bf_i2cread(1, &buf[7]);	/* last byte, nack expected, not a failure */

    bf_i2cstop(0);
    return 0;
}

main()
{
    unsigned char buf[8];
    unsigned char backend;

    printf("Version: %s\n", BUILDID);

    if (bf_i2cdevice(&backend)) {
	printf("no I2C bus configured\n");
	return;
    }
    printf("I2C backend: %s\n",
	backend == 1 ? "PCF8584" : backend == 2 ? "bitbang" : "unknown");

    if (readclock(buf)) {
	printf("clock read FAILED (no ack)\n");
	return;
    }

    printf("%02u/%02u/%02u %02u:%02u:%02u\n",
	bcdval(buf[REG_DATE], 0x3f),
	bcdval(buf[REG_MONTH], 0x1f),
	bcdval(buf[REG_YEAR], 0xff),
	bcdval(buf[REG_HOURS], 0x3f),		/* 24hr mode assumed */
	bcdval(buf[REG_MINUTES], 0x7f),
	bcdval(buf[REG_SECONDS], 0x7f));	/* CH bit (0x80) masked off */
}
