/* I2CSCAN.C, universal I2C bus scanner via BF_I2C. Backend-agnostic
   (PCF8584 or bitbang, whichever HBIOS is built with) -- unlike the
   per-board scanners in Test/I2C/ (i2csc126.asm, i2csc137.asm, etc),
   one binary works on any BF_I2C-capable build. */

#include <stdio.h>
#include "bfi2c.h"
#include "buildid.h"

main()
{
    unsigned char backend, addr, row, col, r;

    printf("I2CSCAN, universal I2C bus scanner\n");
    printf("Version: %s\n", BUILDID);

    if (bf_i2cdevice(&backend)) {
	printf("no I2C bus configured\n");
	return;
    }
    printf("I2C backend: %s\n",
	backend == 1 ? "PCF8584" : backend == 2 ? "bitbang" : "unknown");

    printf("     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f\n");

    for (row = 0; row < 0x80; row += 0x10) {
	printf("%02x: ", row);
	for (col = 0; col < 0x10; col++) {
	    addr = row + col;

	    r = bf_i2cstart(addr << 1);
	    bf_i2cstop(0);

	    if (r == 3) {
		/* bus never went idle -- something is holding SCL/SDA
		   low permanently, no further probe can do anything
		   useful until it releases on its own. */
		printf("\nbus error: never went idle at address 0x%02x, "
		    "aborting scan\n", addr);
		return;
	    }

	    if (r == 0)
		printf("%02x ", addr);
	    else
		printf("-- ");
	}
	printf("\n");
    }
}
