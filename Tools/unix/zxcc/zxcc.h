/*
 *  Change the directories in these #defines if necessary. Note trailing slash.
 */
#ifndef _WIN32
  #include "config.h"
  #define ISDIRSEP(c) ((c) == '/')
  #define DIRSEPCH	'/'
  #define DIRSEP  "/"
#else
  #include "config.h"
  #define ISDIRSEP(c) ((c) == '/' || (c) == '\\')
  #define DIRSEPCH	'\\'
  #define DIRSEP  "/\\:"
#endif

#ifndef CPMDIR80
  #ifdef _WIN32
	#define CPMDIR80    "d:/local/lib/cpm/"
  #else
	#define CPMDIR80    "/usr/local/lib/cpm/"
  #endif
#endif

/* the default sub directories trailing / is required */
#ifdef _WIN32
  #define BIN80   "bin80\\"
  #define LIB80   "lib80\\"
  #define INC80   "include80\\"
#else
  #define BIN80   "bin80/"
  #define LIB80   "lib80/"
  #define INC80   "include80/"
#endif

#ifndef BINDIR80
  #define BINDIR80 CPMDIR80 BIN80
#endif
#ifndef LIBDIR80
  #define LIBDIR80 CPMDIR80 LIB80
#endif
#ifndef INCDIR80
  #define INCDIR80 CPMDIR80 INC80
#endif

extern char bindir80[];
extern char libdir80[];
extern char incdir80[];

#define SERIAL "ZXCC05"

/* System include files */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef HAVE_UNISTD_H
  #include <unistd.h>
#endif
#ifdef _WIN32
  #include <windows.h>
  #include <io.h>
  #include <conio.h>
  #define strcasecmp _stricmp
  #ifndef STDIN_FILENO
	#define STDIN_FILENO _fileno(stdin) 
	#define STDOUT_FILENO _fileno(stdout) 
	#define STDERR_FILENO _fileno(stderr)
  #endif
#else
  #include <termios.h>
  #define	_isatty(a) isatty(a)
  #define	_fileno(a) fileno(a)
#endif
#include <errno.h>
#include <time.h>
#ifdef __MSDOS
  #include <dos.h>
#endif
#ifndef _WIN32
  #include <sys/param.h>
  #include <sys/mount.h>
  #define _S_IFDIR S_IFDIR
#endif

/* Library includes */

#ifdef USE_CPMIO
  #include "cpmio.h"
#endif

#ifdef USE_CPMGSX
  #include "cpmgsx.h"
#endif

typedef unsigned char byte;	/* Must be exactly 8 bits */
typedef unsigned short word;	/* Must be exactly 16 bits */

#include "cpmredir.h"	/* BDOS disc simulation */

/* Prototypes */

void ed_fe  (byte *a, byte *b, byte *c, byte *d, byte *e, byte *f,
			 byte *h, byte *l, word *pc, word *ix, word *iy);
void cpmbdos(byte *a, byte *b, byte *c, byte *d, byte *e, byte *f, 
			 byte *h, byte *l, word *pc, word *ix, word *iy);
void cpmbios(byte *a, byte *b, byte *c, byte *d, byte *e, byte *f, 
			 byte *h, byte *l, word *pc, word *ix, word *iy);
void dump_regs(FILE *fp, byte a, byte b, byte c, byte d, byte e, byte f, 
			   byte h, byte l, word pc, word ix, word iy);
void Msg(char *s, ...);
void DbgMsg(const char *file, int line, const char *func, char *s, ...);
int zxcc_term(void);
void zxcc_exit(int code);

void term_init(void);
void term_reset(void);

#ifdef DEBUG
  #define DBGMSGV(s, ...) DbgMsg(__FILE__, __LINE__, __func__, s, __VA_ARGS__)
  #define DBGMSG(s) DbgMsg(__FILE__, __LINE__, __func__, s)

#else
  #define DBGMSGV(s, ...)
  #define DBGMSG(s)
#endif

/* Global variables */

extern char *progname;
extern char **argv;
extern int argc;
extern byte RAM[65536]; /* The Z80's address space */

/* Z80 CPU emulation */

#include "z80.h"
