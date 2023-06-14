croot.c
/*	Copyright (C) 1981, 1982 by Manx Software Systems */
/*	Copyright (C) 1983 by Manx Software Systems */

#define MAXARGS 30
static char *Argv[MAXARGS];
static char Argbuf[128];
static int Argc;

Croot()
{
	register char *cp;

	movmem((char *)0x81, Argbuf, 127);
	Argbuf[*(char *)0x80 & 0x7f] = 0;
	Argv[0] = "";
	cp = Argbuf;
	Argc = 1;
	while (Argc < MAXARGS) {
		while (*cp == ' ' || *cp == '\t')
			++cp;
		if (*cp == 0)
			break;
		Argv[Argc++] = cp;
		while (*++cp)
			if (*cp == ' ' || *cp == '\t') {
				*cp++ = 0;
				break;
			}
	}
	main(Argc,Argv);
	_exit();
}

exit(code)
{
	_exit();
}

getchar()
{
	register int c;

	if ((c = bdos(1)) == '\r') {
		bdos(2,'\n');
		c = '\n';
	} else if (c == 0x1a)
		c = -1;
	return c;
}

putchar(c)
{
	if (c == '\n')
		bdos(2,'\r');
	bdos(2,c);
	return c&255;
}
fprintf.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
/* Copyright (C) 1982  Thomas Fenwick */
#include "stdio.h"

static FILE *Stream;

fprintf(stream,fmt,args)
FILE *stream; char *fmt; unsigned args;
{
	int fpsub();

	Stream = stream;
	return format(fpsub,fmt,&args);
}

static
fpsub(c)
{
	return aputc(c,Stream);
}
printf.c
/*	Copyright (C) 1981, 1982 by Manx Software Systems */
/*	Copyright (C) 1983 by Manx Software Systems */

printf(fmt,args)
char *fmt; unsigned args;
{
	int putchar();

	format(putchar,fmt,&args);
}

format(putsub, fmt, args)
register int (*putsub)(); register char *fmt; unsigned *args;
{
	register int c;
	char *ps;
	char s[8];
	static char *dconv(), *hexconv();

	while ( c = *fmt++ ) {
		if ( c == '%' ) {
			switch ( c = *fmt++ ) {
			case 'x':
				ps = hexconv(*args++, s+7);
				break;
			case 'u':
				ps = dconv(*args++, s+7);
				break;
			case 'd':
				if ( (int)*args < 0 ) {
					ps = dconv(-*args++, s+7);
					*--ps = '-';
				} else
					ps = dconv(*args++, s+7);
				break;
			case 's':
				ps = *args++;
				break;
			case 'c':
				c = *args++;
			default:
				goto deflt;
			}

			while ( *ps )
				(*putsub)(*ps++);
			
		} else
	deflt:
			(*putsub)(c);
	}
}

static char *
dconv(n, s)
register char *s; register unsigned n;
{
	*s = 0;
	do {
		*--s = n%10 + '0';
	} while ( (n /= 10) != 0 );
	return s;
}

static char *
hexconv(n, s)
register char *s; register unsigned n;
{
	*s = 0;
	do {
		*--s = "0123456789abcdef" [n&15];
	} while ( (n >>= 4) != 0 );
	return s;
}
fopen.c
/*	Copyright (C) 1981, 1982 by Manx Software Systems */
/*	Copyright (C) 1983, 1984 by Manx Software Systems */
#include "stdio.h"
#include "errno.h"

#define MAXFILE 4
#define RBUFSIZ 1024
#define WBUFSIZ 1024
#define RDNSCT	(RBUFSIZ/128)
#define WRNSCT	(WBUFSIZ/128)

#define	OPNFIL	15
#define CLSFIL	16
#define DELFIL	19
#define READSQ	20
#define WRITSQ	21
#define MAKFIL	22
#define SETDMA	26
#define READRN	33
#define WRITRN	34
#define FILSIZ	35
#define SETREC	36

static FILE Cbuffs[MAXFILE];
static char writbuf[WBUFSIZ];
static char readbuf[RBUFSIZ];
static char *bufeof;
static FILE *curread;
static FILE *writfp;

FILE *
fopen(name,mode)
char *name,*mode;
{
	register FILE *fp;
	int user;

	fp = Cbuffs;
	while ( fp->_bp ) {
		if ( ++fp >= Cbuffs+MAXFILE ) {
			errno = ENFILE;
			return (NULL);
		}
	}

	if ((user = fcbinit(name,&fp->_fcb)) == -1) {
		errno = EINVAL;
		return NULL;
	}

	if (user == 255)
		user = getusr();
	fp->user = user;
	setusr(user);
	if (*mode == 'r') {
		if (bdos(OPNFIL,&fp->_fcb) == 0xff) {
			errno = ENOENT;
			rstusr();
			return NULL;
		}
		fp->_bp = readbuf;
		curread = 0;
	} else {
		if ( writfp )
			return NULL;
		bdos(DELFIL, &fp->_fcb);
		if (bdos(MAKFIL,&fp->_fcb) == 0xff) {
			errno = ENOENT;
			rstusr();
			return NULL;
		}
		fp->_bp = writbuf;
		writfp = fp;
	}
	rstusr();
	fp->_fcb.f_overfl = fp->_fcb.f_record = 0;
	return fp;
}

fclose(ptr)
register FILE *ptr;
{
	register int err;

	err = 0;
	if (ptr == writfp) {  /* if writing flush buffer */
		err = flush(ptr->_bp - writbuf);
		writfp = 0;
	} else if (ptr == curread)
		curread = 0;
	setusr(ptr->user);
	if (bdos(CLSFIL,&ptr->_fcb) == 0xff)
		err = -1;
	rstusr();
	ptr->_bp = 0;
	return err;
}

agetc(ptr)
register FILE *ptr;
{
	register int c;

top:
	if ((c = getc(ptr)) != EOF) {
		switch (c &= 127) {
		case 0x1a:
			--ptr->_bp;
			return EOF;
		case '\r':
		case 0:
			goto top;
		}
	}
	return c;
}

getc(ptr)
register FILE *ptr;
{
	register int j;

	if (ptr != curread) {
readit:
		curread = 0;		/* mark nobody as current read */
		setusr(ptr->user);
		if ((j = RDNSCT - blkrd(&ptr->_fcb,readbuf,RDNSCT)) == 0)
			return -1;
		rstusr();
		ptr->_fcb.f_record -= j;
		bufeof = readbuf + j*128;
		curread = ptr;
	}
	if (ptr->_bp >= bufeof) {
		ptr->_fcb.f_record += (bufeof-readbuf) >> 7;
		ptr->_bp = readbuf;
		goto readit;
	}
	return *ptr->_bp++ & 255;
}

aputc(c,ptr)
register int c; register FILE *ptr;
{
	c &= 127;
	if (c == '\n')
		if (putc('\r',ptr) == EOF)
			return EOF;
	return putc(c,ptr);
}

putc(c,ptr)
int c; register FILE *ptr;
{
	*ptr->_bp++ = c;
	if (ptr->_bp >= writbuf+WBUFSIZ) {
		if (flush(WBUFSIZ))
			return EOF;
		ptr->_bp = writbuf;
	}
	return (c&255);
}

flush(len)
register int len;
{
	while (len & 127)
		writbuf[len++] = 0x1a;
	setusr(writfp->user);
	if (len != 0 && blkwr(&writfp->_fcb,writbuf,len>>7) != 0) {
		rstusr();
		return EOF;
	}
	rstusr();
	return 0;
}
