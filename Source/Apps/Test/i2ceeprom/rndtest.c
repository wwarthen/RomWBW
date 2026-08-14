/* RNDTEST.C -- minimal random-data write/read-back test for a single
   I2CEEPROM DIO unit, via the real HBIOS DIO dispatch (BF_DIOSEEK/
   READ/WRITE). Scoped strictly to DIODEV_I2CEEPROM ($12).
   Finds the I2CEEPROM unit automatically (DIO unit numbers are
   assigned globally across every enabled driver in init order, not
   per-driver, so it is not reliably unit 0), then tests block 0.
   No arguments needed.
 */

#include <stdio.h>
#include "hbio.h"

#define DIODEV_I2CEEPROM 0x12
#define MAXBLKSIZ	256	/* largest possible I2CEEPROMBLKSIZ */

unsigned char wbuf[MAXBLKSIZ], rbuf[MAXBLKSIZ];

dumpbuf(label, buf, len)
char *label;
unsigned char *buf;
unsigned int len;
{
    unsigned char i;

    printf("%s:", label);
    for (i = 0; i < len; i++) {
	if ((i & 0x0F) == 0)
	    printf("\n%5u: ", i);
	printf("%02x", buf[i]);
	putchar(' ');
    }
    putchar('\n');
}

/* Z80 R register into rseed -- free-running refresh counter, a cheap
   seed source with no dedicated hardware RNG available */
unsigned char rseed;

getrseed()
{
#asm
    LD	A,R
    LD	(_rseed),A
#endasm
}

/* find the one I2CEEPROM unit among all registered DIO units. returns
   the unit number, or -1 if none found */
findunit()
{
    unsigned char u, dtype;
    unsigned int addr;

    for (u = 0; u <= 15; u++) {
	if (devinfo(u, &dtype, &addr) == 0 && dtype == DIODEV_I2CEEPROM)
	    return u;
    }
    return -1;
}

main()
{
    unsigned char i, x, mismatch, bank;
    char unit;
    unsigned int blksz, blkcnt;

    bank = getbank();
    getrseed();

    unit = findunit();
    if (unit == -1) {
	printf("No I2CEEPROM unit found.\n");
	return;
    }

    blksz = blksize(unit, &blkcnt);
    if (blksz == 0 || blksz > MAXBLKSIZ) {
	printf("Unit %u reports an unusable block size (%u).\n", unit, blksz);
	return;
    }
    printf("Unit %u: BLKSIZ=%u BLKCNT=%u\n", unit, blksz, blkcnt);

    /* fill wbuf with pseudo-random bytes, an 8-bit LCG (x = x*141+1),
       seeded off rseed | 1 so a zero seed can't produce a degenerate
       all-zero run */
    x = rseed | 1;
    for (i = 0; i < blksz; i++) {
	x = (x * 141 + 1) & 0xFF;
	wbuf[i] = x;
    }

    if (seekblock(unit, 0) != 0 || writeblock(unit, wbuf, bank) != 0) {
	printf("Write error on unit %u\n", unit);
	return;
    }
    if (seekblock(unit, 0) != 0 || readblock(unit, rbuf, bank) != 0) {
	printf("Read error on unit %u\n", unit);
	return;
    }

    mismatch = 0;
    for (i = 0; i < blksz; i++) {
	if (wbuf[i] != rbuf[i]) {
	    if (mismatch == 0) {
		printf("FAIL: first mismatch at offset %u (wrote 0x", i);
		printf("%02x", wbuf[i]);
		printf(", read 0x");
		printf("%02x", rbuf[i]);
		printf(")\n");
	    }
	    mismatch++;
	}
    }
    if (mismatch == 0)
	printf("PASS: unit %u block 0, %u bytes verified\n", unit, blksz);
    else
	printf("FAIL: unit %u, %u byte(s) mismatched\n", unit, mismatch);

    dumpbuf("Wrote", wbuf, blksz);
    dumpbuf("Read ", rbuf, blksz);
}
