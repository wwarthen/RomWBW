/* Copyright (C) 1981, 1982 by Manx Software Systems */

extern int errno;
#define FLT_FAULT	0		/* vector for floating-point faults */
extern int (*Sysvec[])();

#define NULL 0
#define EOF -1
#define BUFSIZ 1024

#define _BUSY	0x01
#define _ALLBUF	0x02
#define _DIRTY	0x04
#define _EOF	0x08
#define _IOERR	0x10

typedef struct {
	char *_bp;			/* current position in buffer */
	char *_bend;		/* last character in buffer + 1 */
	char *_buff;		/* address of buffer */
	char _flags;		/* open mode, etc. */
	char _unit;			/* token returned by open */
	char _bytbuf;		/* single byte buffer for unbuffer streams */
	int	_buflen;		/* length of buffer */
} FILE;

extern FILE Cbuffs[];
extern char *Stdbufs;			/* free list of buffers */
long ftell();

#define stdin (&Cbuffs[0])
#define stdout (&Cbuffs[1])
#define stderr (&Cbuffs[2])
#define getchar() agetc(stdin)
#define putchar(c) aputc(c, stdout)
#define feof(fp) (((fp)->_flags&_EOF)!=0)
#define ferror(fp) (((fp)->_flags&_IOERR)!=0)
#define clearerr(fp) ((fp)->_flags &= ~(_IOERR|_EOF))
#define fileno(fp) ((fp)->_unit)
