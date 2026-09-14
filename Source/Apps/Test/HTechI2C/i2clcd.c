/* I2CLCD.C, HD44780 LCD via PCF8574 I2C backpack, via BF_I2C.
   Write-only, no busy-flag polling, no DDRAM readback. ACK on the
   address byte is the only presence check. Wake-up sequence uses
   individual bf_i2cwrite() calls (real delays needed between steps);
   line text is batched into one bf_i2cxfer() instead. Runs once, no
   arguments. */

#include <stdio.h>
#include <conio.h>
#include "bfi2c.h"
#include "buildid.h"
#include "tick.h"

#define LCD_ADDR	0x27
#define LCD_W		((LCD_ADDR << 1) | 0)

#define LCD_RS		0x01	/* P0: register select (0=cmd, 1=data) */
#define LCD_EN		0x04	/* P2: enable strobe */
#define LCD_BL		0x08	/* P3: backlight (on) */

#define LCD_FUNC_CLEAR	0x01
#define LCD_FUNC_ENTRY	0x04
#define LCD_FUNC_DISP	0x08
#define LCD_FUNC_SET	0x20
#define LCD_FUNC_DDADR	0x80

/* row-start DDRAM addresses for a 20x4 panel, same values and same
   wraparound trick as lcdi2c.asm's LCD_ROWSIDX */
unsigned char lcd_rowsidx[4] = { 0x00, 0x40, 0x14, 0x54 };

/* delay approximately ms milliseconds */
lcd_delay_ms(ms)
unsigned int ms;
{
    waitticks(((unsigned int) tickfreq * ms) / 1000 + 1);
}

/* send one nibble (upper 4 bits of n) with RS bit rs, EN strobed
   high then low. returns 0 if both bytes ACKed. */
lcd_nibble(n, rs)
unsigned char n, rs;
{
    unsigned char b;

    b = (n & 0xF0) | LCD_EN | LCD_BL | rs;
    if (bf_i2cwrite(b))
	return 1;
    b &= ~LCD_EN;
    return bf_i2cwrite(b);
}

/* send a full byte as high nibble then low nibble */
lcd_byte(v, rs)
unsigned char v, rs;
{
    if (lcd_nibble(v, rs))
	return 1;
    return lcd_nibble(v << 4, rs);
}

lcd_cmd(v)
unsigned char v;
{
    return lcd_byte(v, 0);
}

/* encode s into buf as the PCF8574 strobe-byte sequence (4 bytes/char),
   for one bf_i2cxfer() call. returns the byte count written. */
lcd_encode_str(buf, s)
unsigned char *buf;
char *s;
{
    unsigned char n, b, i;

    i = 0;
    while (*s) {
	n = *s;
	b = (n & 0xF0) | LCD_EN | LCD_BL | LCD_RS;
	buf[i++] = b;
	buf[i++] = b & ~LCD_EN;
	n = n << 4;
	b = (n & 0xF0) | LCD_EN | LCD_BL | LCD_RS;
	buf[i++] = b;
	buf[i++] = b & ~LCD_EN;
	s++;
    }
    return i;
}

unsigned char lcd_buf[80];	/* up to 20 chars (one LCD row) * 4 bytes */
unsigned char lcd_bank;

/* set DDRAM address to row (0-3), col (0-19) */
lcd_goto(row, col)
unsigned char row, col;
{
    return lcd_cmd(LCD_FUNC_DDADR | (lcd_rowsidx[row] + col));
}

/* position cursor then send s as one bf_i2cxfer() call */
lcd_line(row, col, s)
unsigned char row, col;
char *s;
{
    unsigned char len;

    if (lcd_goto(row, col))
	return 1;
    len = lcd_encode_str(lcd_buf, s);
    return bf_i2cxfer(lcd_buf, len, lcd_bank, 0);
}

main()
{
    unsigned char backend, status;

    printf("BF_I2C LCD test\n");
    printf("Version: %s\n", BUILDID);

    if (bf_i2cdevice(&backend)) {
	printf("no I2C bus configured\n");
	return;
    }
    printf("I2C backend: %s\n",
	backend == 1 ? "PCF8584" : backend == 2 ? "bitbang" : "unknown");
    tickinit(1);

    status = bf_i2cstart(LCD_W);
    if (status) {
	printf("LCD not present (status %d)\n", status);
	if (status != 3)
	    bf_i2cstop(0);
	return;
    }

    /* HD44780 4-bit wake-up sequence (see datasheet): three 8-bit-mode
       nibbles back to back, a settle delay, then switch to 4-bit */
    lcd_nibble(0x30, 0);
    lcd_nibble(0x30, 0);
    lcd_nibble(0x30, 0);
    lcd_delay_ms(5);
    lcd_nibble(0x20, 0);
    lcd_delay_ms(5);

    lcd_cmd(LCD_FUNC_SET | 0x08);		/* 4-bit, 2 line, 5x8 font */
    lcd_cmd(LCD_FUNC_DISP);			/* display off */
    lcd_cmd(LCD_FUNC_CLEAR);			/* clear, home cursor */
    lcd_delay_ms(50);				/* clear needs real time */
    lcd_cmd(LCD_FUNC_ENTRY | 0x02);		/* increment, no shift */
    lcd_cmd(LCD_FUNC_DISP | 0x04);		/* display on, no cursor/blink */

    /* still the same open transaction from bf_i2cstart() above */
    lcd_bank = getbank();
    status  = lcd_line(0, 0, "Hello from BF_I2C");
    status |= lcd_line(1, 1, "RST8 dispatch test");
    status |= lcd_line(2, 0, "via BF_I2CXFER");
    status |= lcd_line(3, 1, backend == 1 ? "PCF8584 confirmed" : backend == 2 ? "bitbang confirmed" : "backend confirmed");
    printf("lines status=%d\n", status);

    bf_i2cstop(0);

    printf("done\n");
}
