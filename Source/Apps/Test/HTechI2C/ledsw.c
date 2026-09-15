/* LEDSW.C, switch-to-LED mirror on the I2C002/TCA9555 module, via
   BF_I2C. Reads P0 (switches), echoes onto P1 (LEDs). Fixed 0x20
   address (no address pins wired). Runs until any key is pressed. */

#include <stdio.h>
#include <signal.h>
#include <conio.h>
#include "bfi2c.h"
#include "buildid.h"

#define TCA_ADDR	0x20
#define TCA_W		((TCA_ADDR << 1) | 0)
#define TCA_R		((TCA_ADDR << 1) | 1)

/* command bytes, TI tca9555.pdf Table 3 */
#define TCA_IN0		0x00	/* input port 0 */
#define TCA_OUT1	0x03	/* output port 1 */
#define TCA_CFG0	0x06	/* configuration port 0 */
#define TCA_CFG1	0x07	/* configuration port 1 */

#define TCA_CFG0_VAL	0xFF	/* P0 (switches) = all input */
#define TCA_CFG1_VAL	0x00	/* P1 (LEDs) = all output */

/* write data byte val to TCA9555 register reg. returns status (0=ok) */
tca_write_reg(reg, val)
unsigned char reg, val;
{
    unsigned char r;

    if (r = bf_i2cstart(TCA_W)) {
	if (r != 3)	/* 3=bus-busy means nothing was ever written, no
			   START to clean up. else must STOP */
	    bf_i2cstop(0);
	return r;
    }
    if (r = bf_i2cwrite(reg)) {
	bf_i2cstop(0);
	return r;
    }
    if (r = bf_i2cwrite(val)) {
	bf_i2cstop(0);
	return r;
    }
    bf_i2cstop(0);
    return 0;
}

/* read TCA9555 register reg into *out. returns status */
tca_read_reg(reg, out)
unsigned char reg;
unsigned char *out;
{
    unsigned char r;

    if (r = bf_i2cstart(TCA_W)) {
	if (r != 3)
	    bf_i2cstop(0);
	return r;
    }
    if (r = bf_i2cwrite(reg)) {
	bf_i2cstop(0);
	return r;
    }
    if (r = bf_i2crepstart(TCA_R)) {
	bf_i2cstop(0);
	return r;
    }
    bf_i2cread(1, out);	/* real byte, last byte, nack expected */
    bf_i2cstop(0);
    return 0;
}

main()
{
    unsigned char backend, sw, r;

    signal(SIGINT, SIG_IGN);

    printf("LEDSW, switch-to-LED mirror, any key to stop\n");
    printf("Version: %s\n", BUILDID);

    if (bf_i2cdevice(&backend)) {
	printf("no I2C bus configured\n");
	return;
    }
    printf("I2C backend: %s\n",
	backend == 1 ? "PCF8584" : backend == 2 ? "bitbang" : "unknown");

    if (r = tca_write_reg(TCA_CFG0, TCA_CFG0_VAL)) {
	printf("no device found at 0x%02x, code %u\n", TCA_ADDR, r);
	return;
    }
    tca_write_reg(TCA_CFG1, TCA_CFG1_VAL);

    for (;;) {
	if (kbhit())
	    break;

	if (r = tca_read_reg(TCA_IN0, &sw)) {
	    printf("\rswitch read failed, code %u\n", r);
	    break;
	}
	if (r = tca_write_reg(TCA_OUT1, sw)) {
	    printf("\rLED write failed, code %u\n", r);
	    break;
	}
    }

    tca_write_reg(TCA_OUT1, 0);	/* all off before returning to CP/M */
    if (kbhit())
	getch();
    printf("stopped\n");
}
