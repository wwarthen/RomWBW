/* Copyright (C) 1982, 1984 by Manx Software Systems */
#define fgetc getc
#define fputc putc
#define NULL 0
#define EOF -1

#ifdef TINY
struct fcb {
	char f_driv;
	char f_name[8];
	char f_type[3];
	char f_ext;
	char f_resv[2];
	char f_rc;
	char f_sydx[16];
	char f_cr;
	unsigned f_record; char f_overfl;
};

typedef struct {
	char *_bp;
	struct fcb _fcb;
	char user;
} FILE;

#else

#define BUFSIZ 1024
#define MAXSTREAM	11

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
FILE *fopen();
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
#define fflush(fp) flsh_(fp,-1)
#endif
