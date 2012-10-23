/* Copyright (C) 1983 by Manx Software Systems */

#define TIOCGETP	0		/* read contents of tty control structure */
#define TIOCSETP	1		/* set contents of tty control structure */
#define TIOCSETN	1		/* ditto only don't wait for output to flush */

/* special codes for MSDOS 2.x only */
#define TIOCREAD	2		/* read control info from device */
#define TIOCWRITE	3		/* write control info to device */
#define TIOCDREAD	4		/* same as 2 but for drives */
#define TIOCDWRITE	5		/* same as 3 but for drives */
#define GETISTATUS	6		/* get input status */
#define GETOSTATUS	7		/* get output status */

struct sgttyb {
	short sg_flags;		/* control flags */
	char sg_erase;		/* ignored */
	char sg_kill;		/* ignored */
};

/* settings for flags */
#define RAW		0x20	/* no echo or mapping of input/output BDOS(6) */

/* Refer to the MSDOS technical reference for detailed information on
 * the remaining flags.
 */
