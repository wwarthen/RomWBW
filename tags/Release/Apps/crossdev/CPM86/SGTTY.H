/* Copyright (C) 1983 by Manx Software Systems */

#define TIOCGETP	0		/* read contents of tty control structure */
#define TIOCSETP	1		/* set contents of tty control structure */
#define TIOCSETN	1		/* ditto only don't wait for output to flush */

struct sgttyb {
	char sg_erase;		/* ignored */
	char sg_kill;		/* ignored */
	short sg_flags;		/* control flags */
};

/* settings for flags */
#define _VALID	0x3a
#define RAW		0x20	/* no echo or mapping of input/output BDOS(6) */
#define CRMOD	0x10	/* map input CR to NL, output NL to CR LF */
#define ECHO	0x08	/* ignored unless CBREAK is set */
#define CBREAK	0x02	/* input using BDOS(1), unless echo off then */
						/* same as RAW */
