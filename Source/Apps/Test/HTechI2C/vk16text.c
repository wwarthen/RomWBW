/* VK16TEXT.C, VK16K33 scrolling text display, via BF_I2C. Two boards,
   8 digits total: 0x71 = digits 0-3 (left), 0x70 = digits 4-7 (right).
   Text comes from the CP/M command line, scrolled right to left; no
   command-line text defaults to "HELLO WORLD!". */

#include <stdio.h>
#include <conio.h>
#include "bfi2c.h"
#include "buildid.h"
#include "tick.h"

#define VK_ADDR0	0x71		/* digits 0-3 (left) */
#define VK_ADDR1	0x70		/* digits 4-7 (right) */
#define VK_W0		((VK_ADDR0 << 1) | 0)
#define VK_W1		((VK_ADDR1 << 1) | 0)

#define MAXTEXT		60		/* max command-tail chars accepted */
#define SCROLL_DELAY_MS	300	/* ms per scroll step */

/* 14-segment bit assignments, standard alphanumeric backpack layout */
#define SEGA	0x0001
#define SEGB	0x0002
#define SEGC	0x0004
#define SEGD	0x0008
#define SEGE	0x0010
#define SEGF	0x0020
#define SEGG1	0x0040
#define SEGG2	0x0080
#define SEGH	0x0100
#define SEGI	0x0200
#define SEGJ	0x0400
#define SEGK	0x0800
#define SEGL	0x1000
#define SEGM	0x2000
#define SEGDP	0x4000		/* bit15 (0x8000) is unwired on this board */

/* indexed by (ch - ' '), covers ' '..'Z' (0x20-0x5A) */
unsigned int font[] = {
    0,					/* SPACE */
    SEGB|SEGC|SEGDP,			/* ! */
    SEGB|SEGF,				/* " */
    0, 0, 0, 0,				/* # $ % & */
    SEGB,				/* ' */
    0, 0, 0,				/* ( ) * */
    0,					/* + */
    SEGM,				/* , */
    SEGG1|SEGG2,			/* - */
    SEGDP,				/* . */
    SEGJ|SEGK,				/* / */
    SEGA|SEGB|SEGC|SEGD|SEGE|SEGF|SEGJ,		/* 0 */
    SEGB|SEGC,						/* 1 */
    SEGA|SEGB|SEGG1|SEGG2|SEGE|SEGD,			/* 2 */
    SEGA|SEGB|SEGG2|SEGC|SEGD,				/* 3 */
    SEGF|SEGG1|SEGG2|SEGB|SEGC,			/* 4 */
    SEGA|SEGF|SEGG1|SEGG2|SEGC|SEGD,			/* 5 */
    SEGA|SEGF|SEGG1|SEGG2|SEGE|SEGC|SEGD,		/* 6 */
    SEGA|SEGB|SEGC,					/* 7 */
    SEGA|SEGB|SEGC|SEGD|SEGE|SEGF|SEGG1|SEGG2,		/* 8 */
    SEGA|SEGB|SEGC|SEGD|SEGF|SEGG1|SEGG2,		/* 9 */
    0, 0, 0,				/* : ; < */
    SEGA|SEGD,				/* = */
    0,					/* > */
    SEGA|SEGB|SEGG2|SEGI,		/* ? */
    0,					/* @ */
    SEGA|SEGB|SEGC|SEGE|SEGF|SEGG1|SEGG2,		/* A */
    SEGA|SEGB|SEGC|SEGD|SEGG2|SEGI|SEGL,		/* B */
    SEGA|SEGD|SEGE|SEGF,				/* C */
    SEGA|SEGB|SEGC|SEGD|SEGI|SEGL,			/* D */
    SEGA|SEGD|SEGE|SEGF|SEGG1,				/* E */
    SEGA|SEGE|SEGF|SEGG1,				/* F */
    SEGA|SEGC|SEGD|SEGE|SEGF|SEGG2,			/* G */
    SEGB|SEGC|SEGE|SEGF|SEGG1|SEGG2,			/* H */
    SEGA|SEGD|SEGI|SEGL,				/* I */
    SEGB|SEGC|SEGD|SEGE,				/* J */
    SEGE|SEGF|SEGG1|SEGJ|SEGM,				/* K */
    SEGD|SEGE|SEGF,					/* L */
    SEGB|SEGC|SEGE|SEGF|SEGH|SEGJ,			/* M */
    SEGB|SEGC|SEGE|SEGF|SEGH|SEGM,			/* N */
    SEGA|SEGB|SEGC|SEGD|SEGE|SEGF,			/* O */
    SEGA|SEGB|SEGE|SEGF|SEGG1|SEGG2,			/* P */
    SEGA|SEGB|SEGC|SEGD|SEGE|SEGF|SEGM,		/* Q */
    SEGA|SEGB|SEGE|SEGF|SEGG1|SEGG2|SEGM,		/* R */
    SEGA|SEGF|SEGG1|SEGG2|SEGC|SEGD,			/* S */
    SEGA|SEGI|SEGL,					/* T */
    SEGB|SEGC|SEGD|SEGE|SEGF,				/* U */
    SEGB|SEGF|SEGK|SEGM,				/* V */
    SEGB|SEGC|SEGE|SEGF|SEGK|SEGL|SEGM,		/* W */
    SEGH|SEGJ|SEGK|SEGM,				/* X */
    SEGH|SEGJ|SEGL,					/* Y */
    SEGA|SEGD|SEGJ|SEGK,				/* Z */
};

#define FONT_LO	' '
#define FONT_HI	'Z'

vk_delay_ms(ms)
unsigned int ms;
{
    return waitticks(((unsigned int) tickfreq * ms) / 1000 + 1);
}

/* A = ASCII char in, returns segment mask (0 if unsupported) */
charseg(ch)
unsigned char ch;
{
    if (ch >= 'a' && ch <= 'z')
	ch &= 0xDF;		/* fold lowercase to uppercase */
    if (ch < FONT_LO || ch > FONT_HI)
	return 0;
    return font[ch - FONT_LO];
}

/* send the 3-byte HT16K33 init sequence to addr, one byte per
   transaction. returns 0 ok, nonzero on the first unacked step */
unsigned char initcmd[3] = { 0x21, 0x81, 0xEF };

initdev(addr)
unsigned char addr;
{
    unsigned char i, r;

    for (i = 0; i < 3; i++) {
	if (r = bf_i2cstart(addr)) {
	    if (r != 3)
		bf_i2cstop(0);
	    return 1;
	}
	if (bf_i2cwrite(initcmd[i])) {
	    bf_i2cstop(0);
	    return 1;
	}
	bf_i2cstop(0);
    }
    return 0;
}

/* build a 9-byte HT16K33 write (register 0x00 + 4 digits x 2 bytes) for
   a 4-char window starting at s, sent as one bf_i2cxfer(). returns 0
   ok, nonzero on failure */
unsigned char vk_buf[9];
unsigned char vk_bank;

showdigits(addr, s)
unsigned char addr;
unsigned char *s;
{
    unsigned int mask;
    unsigned char i, r;

    vk_buf[0] = 0x00;
    for (i = 0; i < 4; i++) {
	mask = charseg(s[i]);
	vk_buf[1 + i * 2] = mask & 0xFF;
	vk_buf[2 + i * 2] = (mask >> 8) & 0xFF;
    }
    if (r = bf_i2cstart(addr)) {
	if (r != 3)
	    bf_i2cstop(0);
	return 1;
    }
    if (bf_i2cxfer(vk_buf, 9, vk_bank, 0)) {
	bf_i2cstop(0);
	return 1;
    }
    bf_i2cstop(0);
    return 0;
}

/* show one 8-char window, left 4 chars to VK_ADDR0, right 4 to
   VK_ADDR1. returns nonzero if either device errors */
showwin(s)
unsigned char *s;
{
    if (showdigits(VK_W0, s))
	return 1;
    return showdigits(VK_W1, s + 4);
}

/* clear both displays, all-zero 9-byte write, same buffer shape as
   showdigits() above */
clearall()
{
    unsigned char i;

    for (i = 1; i < 9; i++)
	vk_buf[i] = 0;
    vk_buf[0] = 0x00;
    bf_i2cstart(VK_W0);
    bf_i2cxfer(vk_buf, 9, vk_bank, 0);
    bf_i2cstop(0);
    bf_i2cstart(VK_W1);
    bf_i2cxfer(vk_buf, 9, vk_bank, 0);
    bf_i2cstop(0);
}

/* command-tail parsing */
unsigned char *tail = (unsigned char *) 0x80;
char defmsg[] = "HELLO WORLD!";
unsigned char msgbuf[MAXTEXT + 16];	/* 8 lead + text + 8 trail */
unsigned char padlen;

/* read command tail (or default message) into msgbuf, padded with 8
   blanks front and back (one full window width). sets padlen to the
   total padded length. */
buildmsg()
{
    unsigned char taillen, i;
    unsigned char *src;

    taillen = tail[0];
    if (taillen == 0) {
	src = (unsigned char *) defmsg;
	taillen = sizeof(defmsg) - 1;
    } else {
	if (taillen > MAXTEXT)
	    taillen = MAXTEXT;
	src = tail + 1;
    }

    for (i = 0; i < 8; i++)
	msgbuf[i] = ' ';
    for (i = 0; i < taillen; i++)
	msgbuf[8 + i] = src[i];
    for (i = 0; i < 8; i++)
	msgbuf[8 + taillen + i] = ' ';

    padlen = taillen + 16;
}

main()
{
    unsigned char backend, pos;

    printf("BF_I2C VK16TEXT test\n");
    printf("Version: %s\n", BUILDID);

    if (bf_i2cdevice(&backend)) {
	printf("no I2C bus configured\n");
	return;
    }
    printf("I2C backend: %s\n",
	backend == 1 ? "PCF8584" : backend == 2 ? "bitbang" : "unknown");
    tickinit(1);

    if (initdev(VK_W0)) {
	printf("VK16K33 NOT RESPONDING (0x%02x)\n", VK_ADDR0);
	return;
    }
    if (initdev(VK_W1)) {
	printf("VK16K33 NOT RESPONDING (0x%02x)\n", VK_ADDR1);
	return;
    }

    vk_bank = getbank();
    buildmsg();

    for (pos = 0; pos + 8 <= padlen; pos++) {
	if (kbhit())
	    break;
	if (showwin(&msgbuf[pos])) {
	    printf("\rdisplay write FAILED\n");
	    break;
	}
	if (vk_delay_ms(SCROLL_DELAY_MS))
	    break;
    }

    clearall();
    printf("done\n");
}
