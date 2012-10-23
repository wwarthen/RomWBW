/* regs.h for aztec.c (C) Copyright Bill Buckels 2008. All rights reserved. */

#ifndef REGS_DEFINED

/* word registers */
/* different than M$oft so don't mix the two */
struct WORDREGS {
    unsigned int ax;
    unsigned int bx;
    unsigned int cx;
    unsigned int dx;
    unsigned int si;
    unsigned int di;
    unsigned int ds;
    unsigned int es;
    };

/* byte registers */
/* I made these the same as M$oft since
   the first 6 word regs are the same between the two */
struct BYTEREGS {
    unsigned char al, ah;
    unsigned char bl, bh;
    unsigned char cl, ch;
    unsigned char dl, dh;
    };

/* general purpose registers union -
 *  overlays the corresponding word and byte registers.
 */

union REGS {
    struct WORDREGS x;
    struct BYTEREGS h;
    };


/* segment registers */
/* different than M$oft so don't mix the two */
struct SREGS {
    unsigned int cs;
    unsigned int ss;
    unsigned int ds;
    unsigned int es;
    };


/* the following makes it a little easier
   to port code from M$soft and Turbo C
   over to Aztec C unless you want to be
   an Aztec C purist */
#define int86(x,y,z) sysint(x,y,z)

#define REGS_DEFINED 1
#endif