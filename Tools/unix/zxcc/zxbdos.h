extern char* progname;
extern char** argv;
extern int argc;

extern byte cpm_drive;
extern byte cpm_user;

extern byte RAM[65536]; /* The Z80's address space */

extern void Msg(char* s, ...);

#ifdef BDOS_DEF

word cpm_dma = 0x80;	/* DMA address */
byte err_mode = 0xFF;
byte rec_multi = 1;
word rec_len = 128;
word ffirst_fcb = 0xFFFF;
byte cpm_error = 0;	/* Error code returned by CP/M */

#else /* BDOS_DEF */

extern word cpm_dma, rec_len, ffirst_fcb;
extern byte err_mode, rec_multi, cpm_error;

#endif /* BDOS_DEF */

#ifndef O_BINARY	/* Necessary in DOS, not present in Linux */
  #define O_BINARY 0
#endif

typedef unsigned long dword;

/* Functions in zxbdos.c */

void wr24(word addr, dword v);
void wr32(word addr, dword v);
dword rd24(word addr);
dword rd32(word addr);
dword cpmtime(time_t t);
word cpm_errcde(word DE);

#ifdef USE_CPMGSX
gsx_byte gsxrd(gsx_word addr);
void gsxwr(gsx_word addr, gsx_byte value);
#endif

void cpmbdos();
void cpmbios();
