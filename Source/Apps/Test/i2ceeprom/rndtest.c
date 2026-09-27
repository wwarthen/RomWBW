/* RNDTEST.C -- minimal random-data write/read-back test for an
   I2CEEPROM DIO unit, via the real HBIOS DIO dispatch (BF_DIOSEEK/
   READ/WRITE). Scoped strictly to DIODEV_I2CEEPROM ($12). Always tests
   block 0.

   No argument: auto-selects if exactly one I2CEEPROM unit is active,
   otherwise lists all active units (or says none found) and stops.
   One argument (unit number): tests that specific unit directly.
 */

#include <stdio.h>
#include "hbio.h"

unsigned char wbuf[MAXBLKSIZ], rbuf[MAXBLKSIZ];

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

main()
{
    char unitstr[8];
    unsigned char i, x, mismatch, bank, dtype;
    char unit;
    unsigned char units[MAXUNITS], cnt;
    unsigned int addr, blksz, blkcnt;

    bank = getbank();
    getrseed();

    inittail();

    if (nexttoken(unitstr, sizeof(unitstr)) != 0) {
	/* explicit unit given, use it directly */
	unit = parsenum(unitstr);
	if (devinfo(unit, &dtype, &addr) != 0 || dtype != DIODEV_I2CEEPROM) {
	    printf("Unit %u is not an I2CEEPROM device.\n", unit);
	    return;
	}
    } else {
	cnt = scanunits(units);
	if (cnt == 0) {
	    printf("No I2CEEPROM units found.\n");
	    return;
	}
	if (cnt == 1) {
	    unit = units[0];
	} else {
	    printf("%u I2CEEPROM units found:\n", cnt);
	    listunits(units, cnt);
	    printf("Re-run with a unit number to test one, e.g. RNDTEST %u\n", units[0]);
	    return;
	}
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
