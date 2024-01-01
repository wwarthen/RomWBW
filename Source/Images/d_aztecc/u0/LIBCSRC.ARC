scanf.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "stdio.h"

static int scnlast;

scanf(fmt, args)
char *fmt; int *args;
{
	int gchar();

	scnlast = 0;
	return scanfmt(gchar, fmt, &args);
}

static gchar(what)
{
	if (what == 0) {
		if (feof(stdin))
			scnlast = EOF;
		else
			scnlast = agetc(stdin);
	} else
		scnlast = ungetc(scnlast, stdin);
	return scnlast;
}

fscanf.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "stdio.h"

static int scnlast;
static FILE *scnfp;

fscanf(fp, fmt, args)
FILE *fp; char *fmt; int *args;
{
	int gchar();

	scnfp = fp;
	scnlast = 0;
	return scanfmt(gchar, fmt, &args);
}

static gchar(what)
{
	if (what == 0) {
		if (feof(scnfp))
			scnlast = EOF;
		else
			scnlast = agetc(scnfp);
	} else
		scnlast = ungetc(scnlast, scnfp);
	return scnlast;
}

sscanf.c
/* Copyright (C) 1983 by Manx Software Systems */
static char *scnstr;
static char quit;

sscanf(string, fmt, arg)
char *string, *fmt; int *arg;
{
	int sgetc();

	scnstr = string;
	quit = 0;
	return scanfmt(sgetc, fmt, &arg);
}

static
sgetc(what)
{
	if (what == 0) {
		if (*scnstr)
			return *scnstr++ & 255;
		quit = 1;
	} else {
		if (!quit)
			return *--scnstr & 255;
	}
	return -1;
}
scan.c
/* Copyright (C) 1982, 1984 by Manx Software Systems */
#include <ctype.h>

#define EOF	-1

static int maxwidth;
static int (*gsub)();
char *index();

scanfmt(getsub, fmt, args)
int (*getsub)(); register char *fmt; register int **args;
{
#ifdef FLOAT
	double atof();
#endif
	long lv;
	register int c, count, base;
	char suppress, lflag, widflg;
	char *cp;
	auto char tlist[130];
	static char list[] = "ABCDEFabcdef9876543210";
	static char vals[] = {
			10,11,12,13,14,15,10,11,12,13,14,15,9,8,7,6,5,4,3,2,1,0
	};

	count = 0;
	gsub = getsub;
	while (c = *fmt++) {
		if (c == '%') {
			widflg = lflag = suppress = 0;
			maxwidth = 127;
			if (*fmt == '*') {
				++fmt;
				suppress = 1;
			}
			if (isdigit(*fmt)) {
				maxwidth = 0;
				do {
					maxwidth = maxwidth*10 + *fmt - '0';
				} while (isdigit(*++fmt));
			}
			if (*fmt == 'l') {
				lflag = 1;
				++fmt;
			}
	
			switch (*fmt++) {
			case '%':
				c = '%';
				goto matchit;
			case 'h':			/* specify short (for compatibility) */
				lflag = 0;
				goto decimal;
			case 'D':
				lflag = 1;
			case 'd':
	decimal:
				c = 12;
				base = 10;
				goto getval;

			case 'X':
				lflag = 1;
			case 'x':
				c = 0;
				base = 16;
				goto getval;

			case 'O':
				lflag = 1;
			case 'o':
				c = 14;
				base = 8;
	getval:
				if (skipblank())
					goto stopscan;
				if (getnum(&list[c], &vals[c], base, &lv) == 0)
					goto stopscan;
				if (!suppress) {
					if (lflag)
						*(long *)(*args++) = lv;
					else
						**args++ = lv;
					++count;
				}
				break;

#ifdef FLOAT
			case 'E':
			case 'F':
				lflag = 1;
			case 'e':
			case 'f':
				if (skipblank())
					goto stopscan;
				if (getflt(tlist))
					goto stopscan;
				if (!suppress) {
					if (lflag)
						*(double *)(*args++) = atof(tlist);
					else
						*(float *)(*args++) = atof(tlist);
					++count;
				}
				break;
#endif
			case '[':
				lflag = 0;
				if (*fmt == '^' || *fmt == '~') {
					++fmt;
					lflag = 1;
				}
				for (cp = tlist ; (c = *fmt++) != ']' ; )
					*cp++ = c;
				*cp = 0;
				goto string;
			case 's':
				lflag = 1;
				tlist[0] = ' ';
				tlist[1] = '\t';
				tlist[2] = '\n';
				tlist[3] = 0;
	string:
				if (skipblank())
					goto stopscan;
	charstring:
				if (!suppress)
					cp = *args++;
				widflg = 0;
				while (maxwidth--) {
					if ((c = (*gsub)(0)) == EOF)
						break;
					if (lflag ? (index(tlist,c)!=0) : (index(tlist,c)==0)) {
						(*gsub)(1);	/* unget last character */
						break;
					}
					if (!suppress)
						*cp++ = c;
					widflg = 1;
				}
				if (!widflg)
					goto stopscan;
				if (!suppress) {
					*cp = 0;
					++count;
				}
				break;

			case 'c':
				if (!widflg)
					maxwidth = 1;
				tlist[0] = 0;
				lflag = 1;
				goto charstring;
			}
		} else if (isspace(c)) {
			if (skipblank())
				goto stopscan;
		} else {
matchit:
			if ((*gsub)(0) != c) {
				(*gsub)(1);
				goto stopscan;
			}
		}
	}

stopscan:
	if (count == 0) {
		if ((*gsub)(0) == EOF)
			return EOF;
		(*gsub)(1);
	}
	return count;
}

skipblank()
{
	while (isspace((*gsub)(0)))
		;
	if ((*gsub)(1) == EOF)
		return EOF;
	return 0;
}

#ifdef FLOAT
getflt(buffer)
char *buffer;
{
	register char *cp;
	register int c;
	char decpt, sign, exp;

	cp = buffer;
	sign = exp = decpt = 0;

	while (maxwidth--) {
		c = (*gsub)(0);
		if (!sign && (c == '-' || c == '+'))
			sign = 1;
		else if (!decpt && c == '.')
			decpt = 1;
		else if (!exp && (c == 'e' || c == 'E')) {
			sign = 0;
			exp = decpt = 1;
		} else if (!isdigit(c)) {
			(*gsub)(1);
			break;
		}
		*cp++ = c;
	}
	*cp = 0;
	return cp==buffer;
}
#endif

getnum(list, values, base, valp)
char *list; char *values; long *valp;
{
	register char *cp;
	register int c, cnt;
	long val;
	int sign;

	if (maxwidth <= 0)
		return 0L;
	val = cnt = sign = 0;
	if ((c = (*gsub)(0)) == '-') {
		sign = 1;
		++cnt;
	} else if (c == '+')
		++cnt;
	else
		(*gsub)(1);

	for ( ; cnt < maxwidth ; ++cnt) {
		if ((cp = index(list, c = (*gsub)(0))) == 0) {
			if (base == 16 && val == 0 && (c=='x' || c=='X'))
				continue;
			(*gsub)(1);
			break;
		}
		val *= base;
		val += values[cp-list];
	}
	if (sign)
		*valp = -val;
	else
		*valp = val;
	return cnt;
}

printf.c
/* Copyright (C) 1981,1982 by Manx Software Systems */

printf(fmt,args)
char *fmt; unsigned args;
{
	extern int putchar();

	format(putchar,fmt,&args);
}
fprintf.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
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
sprintf.c
/* Copyright (C) 1982 by Manx Software Systems */
static char *buff;

sprintf(str,fmt,args)
char *str, *fmt; unsigned args;
{
	int spsub();
	register int i;

	buff = str;
	i = format(spsub,fmt,&args);
	*buff = 0;
	return i;
}

static
spsub(c)
{
	return (*buff++ = c)&0xff;
}

format.c
/* Copyright (C) 1981,1982,1983 by Manx Software Systems */
#include <ctype.h>

char *fmtcvt();

format(putsub, fmt, argp)
register int (*putsub)(); register char *fmt; char *argp;
{
	register int c;
	union {
		int *ip;
		char *cp;
		char **cpp;
#ifdef FLOAT
		double *dp;
#endif
	} args; 
	int charcount;
	int rj, fillc;
	int maxwidth, width;
	int i, k;
	char *cp;
	auto char s[200];

	charcount = 0;
	args.cp = argp;
	while ( c = *fmt++ ) {
		if ( c == '%' ) {
			s[14] = 0;
			rj = 1;
			fillc = ' ';
			maxwidth = 10000;
			if ((c = *fmt++) == '-') {
				rj = 0;
				c = *fmt++;
			}
			if (c == '0') {
				fillc = '0';
				c = *fmt++;
			}
			if (c == '*') {
				width = *args.ip++;
				c = *fmt++;
			} else {
				for (width = 0 ; isdigit(c) ; c = *fmt++)
					width = width*10 + c - '0';
			}
			if ( c == '.' ) {
				if ((c = *fmt++) == '*') {
					maxwidth = *args.ip++;
					c = *fmt++;
				} else {
					for (maxwidth = 0 ; isdigit(c) ; c = *fmt++)
						maxwidth = maxwidth*10 + c - '0';
				}
			}
			i = sizeof(int);
			if (c == 'l') {
				c = *fmt++;
				i = sizeof(long);
			} else if (c == 'h')
				c = *fmt++;

			switch ( c ) {
			case 'o':
				k = 8;
				goto do_conversion;
			case 'u':
				k = 10;
				goto do_conversion;
			case 'x':
				k = 16;
				goto do_conversion;

			case 'd':
				k = -10;
	do_conversion:
				cp = fmtcvt(args.cp, k, s+14, i);
				args.cp += i;
				break;

			case 's':
				i = strlen(cp = *args.cpp++);
				goto havelen;
#ifdef FLOAT
			case 'e':
			case 'f':
			case 'g':
				ftoa(*args.dp++, s, maxwidth==10000?6:maxwidth, c-'e');
				i = strlen(cp = s);
				maxwidth = 200;
				goto havelen;
#endif

			case 'c':
				c = *args.ip++;
			default:
				*(cp = s+13) = c;
				break;
			}

			i = (s+14) - cp;
		havelen:
			if ( i > maxwidth )
				i = maxwidth;
			
			if ( rj ) {
				for (; width-- > i ; ++charcount)
					if ((*putsub)(fillc) == -1)
						return -1;
			}
			for ( k = 0 ; *cp && k < maxwidth ; ++k )
				if ((*putsub)(*cp++) == -1)
					return -1;
			charcount += k;
			
			if ( !rj ) {
				for (; width-- > i ; ++charcount)
					if ((*putsub)(' ') == -1)
						return -1;
			}
		} else {
			if ((*putsub)(c) == -1)
				return -1;
			++charcount;
		}
	}
	return charcount;
}

fopen.c
/* Copyright (C) 1981,1982,1983,1984 by Manx Software Systems */
#include "stdio.h"
#include "fcntl.h"
#include "errno.h"

extern int errno;

static struct modes {
	char fmode[3];
	int omode;
} modes[] = {
	"r",	O_RDONLY,
	"r+",	O_RDWR,
	"w",	(O_WRONLY|O_CREAT|O_TRUNC),
	"w+",	(O_RDWR|O_CREAT|O_TRUNC),
	"a",	(O_WRONLY|O_CREAT|O_APPEND),
	"a+",	(O_RDWR|O_CREAT|O_APPEND),
	"x",	(O_WRONLY|O_CREAT|O_EXCL),
	"x+",	(O_RDWR|O_CREAT|O_EXCL),
	"",		0,
};

FILE *
fopen(name,mode)
char *name,*mode;
{
	register FILE *fp;
	FILE *newstream(), *freopen();

	if ((fp = newstream()) == NULL)
		return NULL;
	return freopen(name, mode, fp);
}

FILE *
freopen(name, mode, fp)
char *name,*mode; FILE *fp;
{
	register struct modes *mp;
	register int fd;

	fclose(fp);

	for (mp = modes ; ; ++mp) {
		if (mp->fmode == 0) {
			errno = EINVAL;
			return NULL;
		}
		if (strcmp(mp->fmode, mode) == 0)
			break;
	}

/*
	Don't try to optimize the next 3 lines.  Since _unit is a char,
	assigning to it in the if statement will cause the -1 test to fail
	on unsigned char machines.
*/
	if ((fd = open(name, mp->omode)) == -1)
		return (NULL);
	fp->_unit = fd;
	fp->_flags = _BUSY;
	return fp;
}
 
fdopen.c
/* Copyright (C) 1984 by Manx Software Systems */
#include "stdio.h"

FILE *
fdopen(fd,mode)
char *mode;
{
	register FILE *fp;
	FILE *newstream();

	if ((fp = newstream()) == NULL)
		return NULL;
	fp->_unit = fd;
	fp->_flags = _BUSY;
	return fp;
}
 
fread.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

fread(buffer,size,number,stream)
register char *buffer; unsigned size; int number;
FILE *stream;
{
	int total;
	register int c,i;

	for ( total = 0 ; total < number ; ++total ) {
		for ( i = size ; i ; --i ) {
			if ( (c = getc(stream)) == EOF )
				return total;
			*buffer++ = c;
		}
	}
	return total;
}
fwrite.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

fwrite(buffer,size,number,stream)
register char *buffer; unsigned size,number;
FILE *stream;
{
	register unsigned i,max;

	max = size * number;
	for ( i = 0 ; i < max ; ++i ) {
		if ( putc(*buffer++,stream) == EOF )
			return 0;
	}
	return number;
}

fseek.c
/* Copyright (c) 1981, 1982 by Manx Software Systems */
#include "stdio.h"

fseek(fp,pos,mode)
register FILE *fp;
long pos;
{
	register int i;
	long curpos, lseek();

	fp->_flags &= ~_EOF;
	if (fp->_flags & _DIRTY) {
		if (flsh_(fp,-1))
			return EOF;
	} else if (mode == 1 && fp->_bp)
		pos -= fp->_bend - fp->_bp;
	fp->_bp = fp->_bend = NULL;
	if (lseek(fp->_unit, pos, mode) < 0)
		return EOF;
	return 0;
}

long ftell(fp)
register FILE *fp;
{
	long pos, lseek();

	pos = lseek(fp->_unit, 0L, 1);	/* find out where we are */
	if (fp->_flags & _DIRTY)
		pos += fp->_bp - fp->_buff;
	else if (fp->_bp)
		pos -= fp->_bend - fp->_bp;
	return pos;
}
gets.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

#undef getchar

char *gets(line)
char *line;
{
	register char *cp;
	register int i;

	cp = line;
	while ((i = getchar()) != EOF && i != '\n')
		*cp++ = i;
	*cp = 0;
	if (i == EOF && cp == line)
		return NULL;
	return line;
}
fgets.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

char *fgets(s, n, fp)
char *s; FILE *fp;
{
	register c;
	register char *cp;

	cp = s;
	while (--n > 0 && (c = agetc(fp)) != EOF) {
		*cp++ = c;
		if (c == '\n')
			break;
	}
	*cp = 0;
	if (c == EOF && cp == s)
		return NULL;
	return(s);
}
getchar.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

#undef getchar

getchar()
{
	return agetc(stdin);
}
agetc.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

agetc(ptr)
register FILE *ptr;
{
	register int c;

top:
	if ((c = getc(ptr)) != EOF) {
		switch (c &= 127) {
		case 0x1a:
			ptr->_flags |= _EOF;
			return EOF;
		case '\r':
		case 0:
			goto top;
		}
	}
	return c;
}

getw.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "stdio.h"

getw(stream)
FILE *stream;
{
	register int x1,x2;

	if ((x1 = getc(stream)) == EOF || (x2 = getc(stream)) == EOF)
		return EOF;
	return (x2<<8) | x1;
}
getc.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "stdio.h"

getc(ptr)
register FILE *ptr;
{
	register int len;

	if (ptr->_bp >= ptr->_bend) {
		if (ptr->_flags&(_EOF|_IOERR))
			return EOF;
		ptr->_flags &= ~_DIRTY;
		if (ptr->_buff == NULL)
			getbuff(ptr);
		if ((len = read(ptr->_unit,ptr->_buff,ptr->_buflen)) <= 0) {
			ptr->_flags |= len==0 ? _EOF : _IOERR;
			return EOF;
		}
		ptr->_bend = (ptr->_bp = ptr->_buff) + len;
	}
	return *ptr->_bp++ & 255;
}
puts.c
/* Copyright (C) 1981,1982 by Manx Software Systems */

puts(str)
register char *str;
{
	while (*str)
		if (putchar(*str++) == -1)
			return -1;
	return putchar('\n');
}
fputs.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

fputs(s,fp)
register char *s;
FILE *fp;
{
	while ( *s )
		if (aputc(*s++,fp) == EOF)
			return(EOF);
	return 0;
}
putchar.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

#undef putchar

putchar(c)
{
	return aputc(c,stdout);
}
puterr.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

puterr(c)
{
	return aputc(c, stderr);
}
aputc.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

aputc(c,ptr)
register int c; register FILE *ptr;
{
	if (c == '\n')
		if (putc('\r',ptr) == EOF)
			return EOF;
	return putc(c,ptr);
}

putw.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

putw(w,stream)
register unsigned w;
FILE *stream;
{
	if ( putc(w,stream) < 0 ) 
		return EOF;
	else if ( putc((w>>8),stream) < 0 )
		return EOF;
	return w;
}
putc.c
/* Copyright (C) 1981,1982,1983,1984 by Manx Software Systems */
#include "stdio.h"

putc(c,ptr)
int c; register FILE *ptr;
{
	if (ptr->_bp >= ptr->_bend)
		return flsh_(ptr,c&0xff);
	return (*ptr->_bp++ = c) & 0xff;
}

static closall()		/* called by exit to close any open files */
{
	register FILE *fp;

	for ( fp = Cbuffs ; fp < Cbuffs+MAXSTREAM ; )
		fclose(fp++);
}

fclose(ptr)
register FILE *ptr;
{
	register int err;

	err = 0;
	if ( ptr->_flags ) {
		if (ptr->_flags&_DIRTY)	/* if modifed flush buffer */
			err = flsh_(ptr,-1);
		err |= close(ptr->_unit);
		if (ptr->_flags&_ALLBUF)
			free(ptr->_buff);
	}
	ptr->_flags = 0;
	return err;
}

flsh_(ptr,data)
register FILE *ptr;
{
	register int size;
	extern int (*cls_)();

	cls_ = closall;
	if (ptr->_flags & _IOERR)
		return EOF;
	if (ptr->_flags & _DIRTY) {
		size = ptr->_bp - ptr->_buff;
		if (write(ptr->_unit, ptr->_buff, size) != size) {
ioerr:
			ptr->_flags |= _IOERR;
			ptr->_bend = ptr->_bp = NULL;
			return EOF;
		}
	}
	if (data == -1) {
		ptr->_flags &= ~_DIRTY;
		ptr->_bend = ptr->_bp = NULL;
		return 0;
	}
	if (ptr->_buff == NULL)
		getbuff(ptr);
	if (ptr->_buflen == 1) {	/* unbuffered I/O */
		if (write(ptr->_unit, &data, 1) != 1)
			goto ioerr;
		return data;
	}
	ptr->_bp = ptr->_buff;
	ptr->_bend = ptr->_buff + ptr->_buflen;
	ptr->_flags |= _DIRTY;
	return (*ptr->_bp++ = data) & 0xff;
}
ungetc.c
/* Copyright (c) 1981, 1982 by Manx Software Systems */
#include "stdio.h"

ungetc(c,ptr)
int c; register FILE *ptr;
{
	if (c == EOF || ptr->_bp <= ptr->_buff)
		return EOF;
	*--ptr->_bp = c;
	return c;
}

getbuff.c
/* Copyright (C) 1983 by Manx Software Systems */
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

FILE Cbuffs[MAXSTREAM] = {
	{ 0,0,0, _BUSY,0,0,1 },
	{ 0,0,0, _BUSY,1,0,1 },
	{ 0,0,0, _BUSY,2,0,1 },
};

FILE *
newstream()
{
	register FILE *fp;

	fp = Cbuffs;
	while (fp->_flags)
		if (++fp >= &Cbuffs[MAXSTREAM])
			return NULL;

	fp->_buff = 
	fp->_bend =  /* nothing in buffer */
	fp->_bp = 0;
	return fp;
}

getbuff(ptr)
register FILE *ptr;
{
	char *buffer;

	if (isatty(ptr->_unit)) {
smlbuff:
		ptr->_buflen = 1;
		ptr->_buff = &ptr->_bytbuf;
		return;
	}
	if ((buffer = malloc(BUFSIZ)) == NULL)
		goto smlbuff;
	ptr->_buflen = BUFSIZ;
	ptr->_flags |= _ALLBUF;
	ptr->_buff = buffer;
	return;
}

setbuf.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include "stdio.h"

setbuf(stream, buffer)
register FILE *stream; char *buffer;
{
	if (stream->_buff)
		return;
	if (buffer) {
		stream->_buff = buffer;
		stream->_buflen = BUFSIZ;
	} else {
		stream->_buff = &stream->_bytbuf;
		stream->_buflen = 1;
	}
}

croot.c
/* Copyright (C) 1981,1982,1984 by Manx Software Systems */
#include "errno.h"
#include "fcntl.h"
#include "io.h"

int bdf_(), ret_();

/*
 * channel table: relates fd's to devices
 */
struct channel chantab[] = {
	{ 2, 0, 1, 0, ret_, 2 },
	{ 0, 2, 1, 0, ret_, 2 },
	{ 0, 2, 1, 0, ret_, 2 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
	{ 0, 0, 0, 0, bdf_, 0 },
};

#define MAXARGS 30
static char *Argv[MAXARGS];
static char Argbuf[128];
static int Argc;
int (*cls_)() = ret_;

Croot()
{
	register char *cp, *fname;
	register int k;

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
#ifndef NOREDIR
		if (*cp == '>') {		/* redirect output */
			k = 1;
			goto redirect;
		} else if (*cp == '<') {	/* redirect input */
			k = 0;
redirect:
			while (*++cp == ' ' || *cp == '\t')
				;
			fname = cp;
			while (*++cp)
				if (*cp == ' ' || *cp == '\t') {
					*cp++ = 0;
					break;
				}
			close(k);
			if (k)
				k = creat(fname, 0666);
			else
				k = open(fname, O_RDONLY);
			if (k == -1) {
				strcpy(0x80, "Can't open file for redirection: ");
				strcat(0x80, fname);
				strcat(0x80, "$");
				bdos(9,0x80);
				exit(10);
			}
		} else
#endif
		{
			Argv[Argc++] = cp;
			while (*++cp)
				if (*cp == ' ' || *cp == '\t') {
					*cp++ = 0;
					break;
				}
		}
	}
	main(Argc,Argv);
	exit(0);
}

exit(code)
{
	register int fd;

	(*cls_)();
	for (fd = 0 ; fd < MAXCHAN ; )
		close(fd++);
	if (code && (bdos(24)&1) != 0)
		unlink("A:$$$.SUB");
	_exit();
}

bdf_()
{
	errno = EBADF;
	return -1;
}

ret_()
{
	return 0;
}

open.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "errno.h"
#include "fcntl.h"
#include "io.h"

#define MAXFILE	8	/* maximum number of open DISK files */
int bdf_(), ret_(), fileop();
/*
 * note: The ioctl function knows that the condev read/write numbers are
 * 2.  It uses this information to patch the read/write tables.
 */
static struct device condev = { 2, 2, 1, 0, ret_ };
static struct device bdosout= { 0, 3, 0, 0, ret_ };
static struct device bdosin = { 3, 0, 0, 0, ret_ };
static struct device filedev= { 1, 1, 0, 1, fileop };

/*
 * device table, contains names and pointers to device entries
 */
static struct devtabl devtabl[] = {
	{ "con:", &condev, 2 },
	{ "CON:", &condev, 2 },
	{ "lst:", &bdosout, 5 },
	{ "LST:", &bdosout, 5 },
	{ "prn:", &bdosout, 5 },
	{ "PRN:", &bdosout, 5 },
	{ "pun:", &bdosout, 4 },
	{ "PUN:", &bdosout, 4 },
	{ "rdr:", &bdosin, 3 },
	{ "RDR:", &bdosin, 3 },
	{ 0, &filedev, 0 }		/* this must be the last slot in the table! */
};


creat(name, mode)
char *name;
{
	return open(name, O_WRONLY|O_TRUNC|O_CREAT, mode);
}

open(name, flag, mode)
char *name;
{
	register struct devtabl *dp;
	register struct channel *chp;
	register struct device *dev;
	int fd, mdmask;

	for (chp = chantab, fd = 0 ; fd < MAXCHAN ; ++chp, ++fd)
		if (chp->c_close == bdf_)
			goto fndchan;
	errno = EMFILE;
	return -1;

fndchan:
	for (dp = devtabl ; dp->d_name ; ++dp)
		if (strcmp(dp->d_name, name) == 0)
			break;
	dev = dp->d_dev;
	mdmask = (flag&3) + 1;
	if (mdmask&1) {
		if ((chp->c_read = dev->d_read) == 0) {
			errno = EACCES;
			return -1;
		}
	}
	if (mdmask&2) {
		if ((chp->c_write = dev->d_write) == 0) {
			errno = EACCES;
			return -1;
		}
	}
	chp->c_arg = dp->d_arg;
	chp->c_ioctl = dev->d_ioctl;
	chp->c_seek = dev->d_seek;
	chp->c_close = ret_;
	if ((*dev->d_open)(name, flag, mode, chp, dp) < 0) {
		chp->c_close = bdf_;
		return -1;
	}
	return fd;
}

close(fd)
{
	register struct channel *chp;

	if (fd < 0 || fd > MAXCHAN) {
		errno = EBADF;
		return -1;
	}
	chp = &chantab[fd];
	fd = (*chp->c_close)(chp->c_arg);
	chp->c_read = chp->c_write = chp->c_ioctl = chp->c_seek = 0;
	chp->c_close = bdf_;
	return fd;
}

static struct fcbtab fcbtab[MAXFILE];

static
fileop(name,flag,mode,chp,dp)
char *name; struct channel *chp; struct devtabl *dp;
{
	register struct fcbtab *fp;
	int filecl();
	int user;

	for ( fp = fcbtab ; fp < fcbtab+MAXFILE ; ++fp )
		if ( fp->flags == 0 )
			goto havefcb;
	errno = ENFILE;
	return -1;

havefcb:
	if ((user = fcbinit(name,&fp->fcb)) == -1) {
		errno = EINVAL;
		return -1;
	}
	if (user == 255)
		user = getusr();
	setusr(user);
	if (flag & O_TRUNC)
		bdos(DELFIL, &fp->fcb);
	if (bdos(OPNFIL,&fp->fcb) == 0xff) {
		if ((flag&(O_TRUNC|O_CREAT)) == 0 || bdos(MAKFIL,&fp->fcb) == 0xff) {
			errno = ENOENT;
			rstusr();
			return -1;
		}
	} else if ((flag&(O_CREAT|O_EXCL)) == (O_CREAT|O_EXCL)) {
		errno = EEXIST;
		rstusr();
		return -1;
	}
	
	fp->offset = fp->fcb.f_overfl = fp->fcb.f_record = 0;
	fp->user = user;
	chp->c_arg = fp;
	fp->flags = (flag&3)+1;
	chp->c_close = filecl;
	if (flag&O_APPEND)
		_Ceof(fp);
	rstusr();
	return 0;
}

static
filecl(fp)
register struct fcbtab *fp;
{
	_zap();		/* zap work buffer, so data is not reused */
	setusr(fp->user);
	bdos(CLSFIL,&fp->fcb);
	rstusr();
	fp->flags = 0;
	return 0;
}

close.c
/* Copyright (C) 1982 by Manx Software Systems */
#include "errno.h"
#include "io.h"

close(fd)
{
	register struct channel *chp;
	extern int bdf_();

	if (fd < 0 || fd > MAXCHAN) {
		errno = EBADF;
		return -1;
	}
	chp = &chantab[fd];
	fd = (*chp->c_close)(chp->c_arg);
	chp->c_read = chp->c_write = chp->c_ioctl = chp->c_seek = 0;
	chp->c_close = bdf_;
	return fd;
}
ioctl.c
/* Copyright (C) 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"
#include "sgtty.h"

#define TIME	10		/* number of iterations of raw_rd loop */
#define MIN		1		/* minimum number of chars returned from read */

extern int (*Rd_tab[])();
extern int (*Wrt_tab[])();

struct sgttyb Tty_ctl;
extern char _Eol;
extern int tty_rd();
static int raw_rd(), raw_wr();
static int rd_func, wrt_func;

ioctl(fd, cmd, arg)
struct sgttyb *arg;
{
	register struct channel *chp;

	chp = &chantab[fd];
	if (chp->c_ioctl == 0) {
		errno = ENOTTY;
		return -1;
	}
	switch (cmd) {
	case TIOCGETP:
		*arg = Tty_ctl;
		break;
	case TIOCSETP:
		Tty_ctl = *arg;
		Wrt_tab[2] = raw_wr;
		Rd_tab[2] = raw_rd;
		if (Tty_ctl.sg_flags&RAW) {
			rd_func =
			wrt_func = 6;
			_Eol = '\r';
			break;
		} else if (Tty_ctl.sg_flags&CBREAK) {
			rd_func = (Tty_ctl.sg_flags&ECHO) ? 1 : 6;
			wrt_func = 2;
		} else {
			Rd_tab[2] = tty_rd;
			wrt_func = 2;
		}
		if (Tty_ctl.sg_flags&CRMOD)
			_Eol = '\n';
		else
			_Eol = '\r';
	}
	return 0;
}

raw_rd(x, buff, len)
register char *buff;
{
	int c, i;
	register int count;

	for (count = 0 ; count < len ; ) {
		for (i = TIME ; i-- ; )
			if ((c = bdos(rd_func,0xff)) != 0)
				goto have_char;
		if (count < MIN)
			continue;
		break;
have_char:
		if (c == '\r')
			c = _Eol;
		*buff++ = c;
		++count;
	}
	return count;
}

raw_wr(kind, buff, len)
register char *buff;
{
	register int count;

	for (count = len ; count-- ; ) {
		if (*buff == '\n' && (Tty_ctl.sg_flags&CRMOD))
			bdos(wrt_func,'\r');
		bdos(wrt_func,*buff++);
	}
	return len;
}
read.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"
#include "fcntl.h"

int bdf_(), filerd(), tty_rd(), bdosrd();

int (*Rd_tab[])() = {
	bdf_, filerd, tty_rd, bdosrd,
};
extern int errno;

read(fd, buff, len)
char *buff;
{
	register struct channel *chp;

	chp = &chantab[fd];
	return (*Rd_tab[chp->c_read])(chp->c_arg, buff, len);
}

static
filerd(afp,buffer,len)
struct fcbtab *afp;
char *buffer; unsigned len;
{
	register unsigned l = 0;
	register struct fcbtab *fp;
	unsigned k,j;

	fp = afp;
	setusr(fp->user);
	if (fp->offset) {
		if ((l = 128 - fp->offset) > len)
			l = len;
		if (getsect(fp, buffer, l)) {
			rstusr();
			return 0;
		}
	}
	if (k = (len-l)/128)
		if ((j = blkrd(&fp->fcb, buffer+l, k)) != 0) {
			rstusr();
			return (k-j)*128 + l;
		}
	l += k*128;
	if (l < len)
		if (getsect(fp, buffer+l, len-l)) {
			rstusr();
			return l;
		}
	rstusr();
	return len;
}

static
getsect(fp, buf, len)
register struct fcbtab *fp; char *buf; unsigned len;
{
	if (_find(fp))
		return -1;
	movmem(Wrkbuf+fp->offset, buf, len);
	if ((fp->offset = (fp->offset + len) & 127) == 0)
		++fp->fcb.f_record;
	return 0;
}

char _Eol = '\n';

tty_rd(x,buff,len)
char *buff;
{
	static char buffer[258];
	static int used;
	register int l;

	if (buffer[1] == 0) {
		buffer[0] = 255;
		buffer[1] = buffer[2] = 0;
		bdos(10,buffer);
		bdos(2,'\n');
		if (buffer[2] == 0x1a) {
			buffer[1] = 0;
			return 0;
		}
		buffer[++buffer[1] + 1] = _Eol;
		used = 2;
	}
	if ((l = buffer[1]) > len)
		l = len;
	movmem(buffer+used, buff, l);
	used += l;
	buffer[1] -= l;
	return l;
}

static
bdosrd(kind, buff, len)
register char *buff;
{
	register int count;

	for (count = 0 ; count < len ; ++count) {
		if ((*buff++ = bdos(kind)) == 0x1a)
			break;
	}
	return count;
}
write.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"

int tty_wr(), bdoswr(), filewr(), bdf_();

int (*Wrt_tab[])() = {
	bdf_, filewr, bdoswr, bdoswr
};

write(fd, buff, len)
char *buff;
{
	register struct channel *chp;

	chp = &chantab[fd];
	return (*Wrt_tab[chp->c_write])(chp->c_arg, buff, len);
}

static
filewr(afp,buffer,len)
struct fcbtab *afp;
char *buffer; unsigned len;
{
	register unsigned l = 0;
	register struct fcbtab *fp;
	unsigned k,j;

	fp = afp;
	setusr(fp->user);
	if (fp->offset) {
		if ((l = 128 - fp->offset) > len)
			l = len;
		if (putsect(fp, buffer, l)) {
			rstusr();
			return -1;
		}
	}
	if (k = (len-l)/128)
		if ((j = blkwr(&fp->fcb, buffer+l, k)) != 0) {
			rstusr();
			if ((l += (k-j)*128) == 0)
				return -1;
			else
				return l;
		}
	l += k*128;
	if (l < len)
		if (putsect(fp, buffer+l, len-l)) {
			rstusr();
			return l;
		}
	rstusr();
	return len;
}

static
putsect(fp, buf, len)
register struct fcbtab *fp; char *buf; unsigned len;
{
	if (_find(fp) < 0)
		return -1;
	movmem(buf, Wrkbuf+fp->offset, len);
	if ((errno = bdos(WRITRN, &fp->fcb)) != 0)
		return -1;
	if ((fp->offset = (fp->offset + len) & 127) == 0)
		++fp->fcb.f_record;
	return 0;
}

tty_wr(kind, buff, len)
register char *buff;
{
	register int count;

	for (count = len ; count-- ; ) {
		if (*buff == '\n')
			bdos(2,'\r');
		bdos(2,*buff++);
	}
	return len;
}

static
bdoswr(kind, buff, len)
register char *buff;
{
	register int count;

	for (count = len ; count-- ; )
		bdos(kind,*buff++);
	return len;
}

lseek.c
/* Copyright (C) 1982, 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"

long lseek(fd, pos, how)
long pos;
{
	register struct fcbtab *fp;

	if (chantab[fd].c_seek == 0) {
Badf:
		errno = EBADF;
		return -1L;
	}
	fp = chantab[fd].c_arg;

	switch (how) {
	case 2:
		/*
		 * Close the file because CP/M doesn't know how big an open file is.
		 * However, the fcb is still valid.
		 */
		setusr(fp->user);
		fp->fcb.f_name[4] |= 0x80;	/* set parital close flag for MP/M */
		bdos(CLSFIL, &fp->fcb);
		fp->fcb.f_name[4] &= 0x7f;	/* clear parital close flag */
		_Ceof(fp);
		rstusr();
	case 1:
		pos += fp->offset + ((long)fp->fcb.f_record << 7);
	case 0:
		break;

	default:
		errno = EINVAL;
		return -1L;
	}

	fp->fcb.f_overfl = 0;
	if (pos < 0) {
		fp->offset = fp->fcb.f_record = 0;
		errno = EINVAL;
		return -1L;
	}
	fp->offset = (unsigned)pos & 127;
	fp->fcb.f_record = pos >> 7;
	return pos;
}

posit.c
/* Copyright (C) 1982,1983 by Manx Software Systems */
#include "io.h"
#include "errno.h"

posit(fd, pos)
unsigned pos;
{
	register struct fcbtab *fp;

	if (chantab[fd].c_seek == 0) {
		errno = EBADF;
		return -1;
	}
	fp = chantab[fd].c_arg;
	fp->fcb.f_record = pos;
	fp->offset = fp->fcb.f_overfl = 0;
	return 0;
}

ceof.c
/* Copyright (C) 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"

_Ceof(fp)
register struct fcbtab *fp;
{
	register char *cp;

	bdos(FILSIZ, &fp->fcb);
	if (fp->fcb.f_record == 0) {
		fp->offset = 0;
		return 0;
	}
	--fp->fcb.f_record;			/* backup to last record */
	if (_find(fp))
		return -1;

	for (cp = Wrkbuf+128 ; cp > Wrkbuf ; )
		if (*--cp != 0x1a) {
			++cp;
			break;
		}
	if ((fp->offset = cp-Wrkbuf) == 128) {
		++fp->fcb.f_record;
		fp->offset = 0;
	}
	return 0;
}
find.c
/* Copyright (C) 1984 by Manx Software Systems */
#include "io.h"

static struct fcbtab *Wfp;
static unsigned Wsct;

_zap()			/* invalidate work buffer */
{
	Wfp = 0;
}

_find(fp)
register struct fcbtab *fp;
{
	extern int errno;

	bdos(SETDMA, Wrkbuf);
	if (Wfp != fp || fp->fcb.f_record != Wsct) {
		if ((errno = bdos(READRN, &fp->fcb)) == 1 || errno == 4) {
			errno = 0;
			setmem(Wrkbuf, 128, 0x1a);
			Wfp = 0;
			return 1;
		} else if (errno)
			return -1;
		Wfp = fp;
		Wsct = fp->fcb.f_record;
	}
	return 0;
}

isatty.c
/* Copyright (C) 1983 by Manx Software Systems */
#include "io.h"
#include "errno.h"

isatty(fd)
{
	return chantab[fd].c_ioctl;
}

rename.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */
#include "errno.h"

rename(old, new)
char *old, *new;
{
	auto char buff[60];
	register int user;

	user = fcbinit(old,buff);
	fcbinit(new,buff+16);
	setusr(user);
	user = 0;
	if (bdos(15,buff+16) != 0xff) {
		bdos(16,buff+16);
		errno = EEXIST;
		user = -1;
	} else if (bdos(23,buff) == 0xff) {
		errno = ENOENT;
		user = -1;
	}
	rstusr();
	return user;
}
unlink.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */
#include "errno.h"

unlink(name)
char *name;
{
	auto char delfcb[40];
	register int user;

	user = fcbinit(name,delfcb);
	setusr(user);
	user = bdos(19,delfcb);
	rstusr();
	if (user == 0xff) {
		errno = ENOENT;
		return -1;
	}
	return 0;
}

atol.c
/* Copyright (C) 1982 by Manx Software Systems */
#include <ctype.h>

long
atol(cp)
register char *cp;
{
	long n;
	register sign;

	while (*cp == ' ' || *cp == '\t')
		++cp;
	sign = 0;
	if ( *cp == '-' ) {
		sign = 1;
		++cp;
	} else if ( *cp == '+' )
		++cp;

	for ( n = 0 ; isdigit(*cp) ; )
		n = n*10 + *cp++ - '0';
	return sign ? -n : n;
}
atoi.c
/* Copyright (C) 1981,1982 by Manx Software Systems */
#include <ctype.h>

atoi(cp)
register char *cp;
{
	register unsigned i;
	register sign;

	while (*cp == ' ' || *cp == '\t')
		++cp;
	sign = 0;
	if ( *cp == '-' ) {
		sign = 1;
		++cp;
	} else if ( *cp == '+' )
		++cp;

	for ( i = 0 ; isdigit(*cp) ; )
		i = i*10 + *cp++ - '0';
	return sign ? -i : i;
}
calloc.c
/* Copyright (C) 1984 by Manx Software Systems */

char *calloc(nelem, size)
unsigned nelem, size;
{
	register unsigned i = nelem*size;
	register char *cp, *malloc();

	if ((cp = malloc(i)) != (char *)0)
		setmem(cp, i, 0);
	return cp;
}
malloc.c
/* Copyright (C) 1984 by Manx Software Systems */

typedef struct freelist {
	unsigned f_size;
	struct freelist *f_chain;
} FREE;

#define NULL	(FREE *)0
#define GRAIN 1024

static FREE head, *last;

char *
realloc(area, size)
register char *area; unsigned size;
{
	register char *cp;
	unsigned osize;
	char *malloc();

	osize = (((FREE *)area-1)->f_size - 1) * sizeof(FREE);
	free(area);
	if ((cp = malloc(size)) != 0 && cp != area)
		movmem(area, cp, size>osize ? osize : size);
	return cp;
}

char *
malloc(size)
unsigned size;
{
	register FREE *tp, *prev;
	char *sbrk();
	int units;

	units = (size+sizeof(FREE)-1)/sizeof(FREE) + 1;
	if ((prev = last) == NULL)
		last = head.f_chain = prev = &head;

	for (tp = prev->f_chain ; ; prev = tp, tp = tp->f_chain) {
		while (tp != tp->f_chain && tp+tp->f_size == tp->f_chain) {
			if (last == tp->f_chain)
				last = tp->f_chain->f_chain;
			tp->f_size += tp->f_chain->f_size;
			tp->f_chain = tp->f_chain->f_chain;
		}

		if (tp->f_size >= units) {
			if (tp->f_size == units)
				prev->f_chain = tp->f_chain;
			else {
				last = tp + units;
				prev->f_chain = last;
				last->f_chain = tp->f_chain;
				last->f_size = tp->f_size - units;
				tp->f_size = units;
			}
			last = prev;
			tp->f_chain = NULL;
			return (char *)(tp+1);
		}
		if (tp == last) {
			if ((tp = (FREE *)sbrk(GRAIN)) == (FREE *)-1)
				return (char *)NULL;
			tp->f_size = GRAIN/sizeof(FREE);
			tp->f_chain = NULL;
			free(tp+1);
			tp = last;
		}
	}
}

free(area)
char *area;
{
	register FREE *tp, *hole;

	hole = (FREE *)area - 1;
	if (hole->f_chain != NULL)
		return -1;
	for (tp = last ; tp > hole || hole > tp->f_chain ; tp = tp->f_chain)
		if (tp >= tp->f_chain && (hole > tp || hole < tp->f_chain))
			break;

	hole->f_chain = tp->f_chain;
	tp->f_chain = hole;
	last = tp;
	return 0;
}
qsort.c
/* Copyright (C) 1984 by Manx Software Systems */

qsort(base, nel, size, compar)
char *base; unsigned nel, size; int (*compar)();
{
	register char *i,*j,*x,*r;
	auto struct stk {
		char *l, *r;
	} stack[16];
	struct stk *sp;

	sp = stack;
	r = base + (nel-1)*size;
	for (;;) {
		do {
			x = base + (r-base)/size/2 * size;
			i = base;
			j = r;
			do {
				while ((*compar)(i,x) < 0)
					i += size;
				while ((*compar)(x,j) < 0)
					j -= size;
				if (i < j) {
					swapmem(i, j, size);
					if (i == x)
						x = j;
					else if (j == x)
						x = i;
				}
				if (i <= j) {
					i += size;
					j -= size;
				}
			} while (i <= j);
			if (j-base < r-i) {
				if (i < r) {	/* stack request for right partition */
					sp->l = i;
					sp->r = r;
					++sp;
				}
				r = j;			/* continue sorting left partition */
			} else {
				if (base < j) {	/* stack request for left partition */
					sp->l = base;
					sp->r = j;
					++sp;
				}
				base = i;		/* continue sorting right partition */
			}
		} while (base < r);

		if (sp <= stack)
			break;
		--sp;
		base = sp->l;
		r = sp->r;
	}
}
ctype.c
/* Copyright (C) 1984 by Manx Software Systems */

char ctp_[129] = {
	0,								/*	EOF */
	0x20,	0x20,	0x20,	0x20,	/*	nul	soh	stx	etx	*/
	0x20,	0x20,	0x20,	0x20,	/*	eot	enq	ack	bel	*/
	0x20,	0x30,	0x30,	0x30,	/*	bs	ht	nl	vt	*/
	0x30,	0x30,	0x20,	0x20,	/*	ff	cr	so	si	*/
	0x20,	0x20,	0x20,	0x20,	/*	dle	dc1	dc2	dc3	*/
	0x20,	0x20,	0x20,	0x20,	/*	dc4	nak	syn	etb	*/
	0x20,	0x20,	0x20,	0x20,	/*	can	em	sub	esc	*/
	0x20,	0x20,	0x20,	0x20,	/*	fs	gs	rs	us	*/
	0x90,	0x40,	0x40,	0x40,	/*	sp	!	"	#	*/
	0x40,	0x40,	0x40,	0x40,	/*	$	%	&	'	*/
	0x40,	0x40,	0x40,	0x40,	/*	(	)	*	+	*/
	0x40,	0x40,	0x40,	0x40,	/*	,	-	.	/	*/
	0x0C,	0x0C,	0x0C,	0x0C,	/*	0	1	2	3	*/
	0x0C,	0x0C,	0x0C,	0x0C,	/*	4	5	6	7	*/
	0x0C,	0x0C,	0x40,	0x40,	/*	8	9	:	;	*/
	0x40,	0x40,	0x40,	0x40,	/*	<	=	>	?	*/
	0x40,	0x09,	0x09,	0x09,	/*	@	A	B	C	*/
	0x09,	0x09,	0x09,	0x01,	/*	D	E	F	G	*/
	0x01,	0x01,	0x01,	0x01,	/*	H	I	J	K	*/
	0x01,	0x01,	0x01,	0x01,	/*	L	M	N	O	*/
	0x01,	0x01,	0x01,	0x01,	/*	P	Q	R	S	*/
	0x01,	0x01,	0x01,	0x01,	/*	T	U	V	W	*/
	0x01,	0x01,	0x01,	0x40,	/*	X	Y	Z	[	*/
	0x40,	0x40,	0x40,	0x01,	/*	\	]	^	_	*/
	0x40,	0x0A,	0x0A,	0x0A,	/*	`	a	b	c	*/
	0x0A,	0x0A,	0x0A,	0x02,	/*	d	e	f	g	*/
	0x02,	0x02,	0x02,	0x02,	/*	h	i	j	k	*/
	0x02,	0x02,	0x02,	0x02,	/*	l	m	n	o	*/
	0x02,	0x02,	0x02,	0x02,	/*	p	q	r	s	*/
	0x02,	0x02,	0x02,	0x02,	/*	t	u	v	w	*/
	0x02,	0x02,	0x02,	0x40,	/*	x	y	z	{	*/
	0x40,	0x40,	0x40,	0x20,	/*	|	}	~	del	*/
} ;
execl.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */

execl(path, args)
char *path, *args;
{
	return execvp(path, &args);
}

execv(path, argv)
char *path, **argv;
{
	return execvp(path, argv);
}
exec.c
/* Copyright (C) 1983, 1984 by Manx Software Systems */
#include "io.h"
#include "errno.h"

execlp(path, args)
char *path, *args;
{
	return execvp(path, &args);
}

execvp(path, argv)
char *path, **argv;
{
	register char *cp, *xp;
	int user, ouser;
	auto struct fcb fcb;
	auto char loader[70];
	extern char ldr_[];

	if ((user = fcbinit(path, &fcb)) == -1) {
		errno = EINVAL;
		return -1;
	}
	if (fcb.f_type[0] == ' ')
		strcpy(fcb.f_type, "COM");
	ouser = bdos(GETUSR, 255);
	bdos(GETUSR, user);
	if (bdos(OPNFIL, &fcb) == 255) {
		errno = ENOENT;
		return -1;
	}
	fcb.f_cr = 0;

	fcbinit(0, 0x5c);
	fcbinit(0, 0x6c);
	cp = (char *)0x81;
	if (*argv) {
		++argv;			/* skip arg0, used for unix (tm) compatibility */
		for (user = 0 ; (xp = *argv++) != 0 ; ++user) {
			if (user == 0)
				fcbinit(xp, 0x5c);
			else if (user == 1)
				fcbinit(xp, 0x6c);
			*cp++ = ' ';
			while (*xp) {
				if (cp > (char *)0xff)
					goto doload;
				*cp++ = *xp++;
			}
		}
	}

doload:
	*(char *)0x80 = cp - (char *)0x81;
	movmem(ldr_, loader, sizeof loader);
	(*(int (*)())loader)(&fcb, ouser);
}

