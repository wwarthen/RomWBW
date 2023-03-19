#include "zxcc.h"

#define BDOS_DEF
#include "zxbdos.h"
#include "zxcbdos.h"
#include "zxdbdos.h"

#ifdef __MSDOS__
#include <conio.h>
#endif

#define BCD(x) (((x % 10)+16*(x/10)) & 0xFF)

/* Convert time_t to CP/M day count/hours/minutes */
/* there is a duplicate of this code in util.c.
* same modification applied here
*/
dword cpmtime(time_t t)
{
	dword d = (dword)((t / 86400) - 2921);  /* CP/M day 0 is unix day 2921 */
	dword h = (t % 86400) / 3600;  /* Hour, 0-23 */
	dword m = (t % 3600) / 60;    /* Minute, 0-59 */

	return (d | (BCD(h) << 16) | (BCD(m) << 24));
}


byte get_time(cpm_word b)
{
	time_t t;

	time(&t);
	wr32(b, cpmtime(t));

	return (BCD(t % 60));
}


/* Functions to access 24-bit & 32-bit words in memory. These are always
  little-endian. */

void wr24(word addr, dword v)
{
	RAM[addr] = v & 0xFF;
	RAM[addr + 1] = (v >> 8) & 0xFF;
	RAM[addr + 2] = (v >> 16) & 0xFF;
}

void wr32(word addr, dword v)
{
	RAM[addr] = v & 0xFF;
	RAM[addr + 1] = (v >> 8) & 0xFF;
	RAM[addr + 2] = (v >> 16) & 0xFF;
	RAM[addr + 3] = (v >> 24) & 0xFF;
}

dword rd24(word addr)
{
	register dword rv = RAM[addr + 2];

	rv = (rv << 8) | RAM[addr + 1];
	rv = (rv << 8) | RAM[addr];
	return rv;
}


dword rd32(word addr)
{
	register dword rv = RAM[addr + 3];

	rv = (rv << 8) | RAM[addr + 2];
	rv = (rv << 8) | RAM[addr + 1];
	rv = (rv << 8) | RAM[addr];
	return rv;
}

#define peekw(addr) ( (((word)(RAM[addr + 1])) << 8) | RAM[addr])


/* Get / set the program return code. We store this in 'C' form: 0 for
   success, 1-255 for failure. Translate to/from the CP/M form of:

   0x0000-0xFEFF for success
   0xFF00-0xFFFE for failure

   We also store the actual value so it can be returned

  */

word cpm_errcde(word DE)
{
	static word real_err = 0;

	if (DE == 0xFFFF) return real_err;
	real_err = DE;

	if (DE == 0xFF00) cpm_error = 1;
	else if (DE > 0xFF00) cpm_error = (DE & 0xFF);
	else cpm_error = 0;
	return 0;
}


#ifdef USE_CPMGSX
gsx_byte gsxrd(gsx_word addr)
{
	return RdZ80(addr);
}

void gsxwr(gsx_word addr, gsx_byte value)
{
	WrZ80(addr, value);
}

#endif

#undef bc
#undef de
#undef hl

void setw(byte* l, byte* h, word w)
{
	*l = (w & 0xFF);
	*h = (w >> 8) & 0xFF;
}

void cpmbdos(byte* a, byte* b, byte* c, byte* d, byte* e, byte* f,
			 byte* h, byte* l, word* pc, word* ix, word* iy)
{
	word de = ((*d) << 8) | *e;
	word hl = ((*h) << 8) | *l;
	byte* pde = &RAM[de];
	byte* pdma = &RAM[cpm_dma];
	word temp;
	int retv;

	DBGMSGV("BDOS service invoked: C=0x%02X DE=0x%04X\n", *c, de);

	switch (*c)
	{
	case 0:
		*pc = 0;
		break;

	case 1:		/* Get a character */
#ifdef USE_CPMIO
		retv = cpm_bdos_1();
#else
		retv = cin();
#endif
		if (retv < 0) *pc = 0;
		setw(l, h, retv);
		break;

	case 2:		/* Print a character */
#ifdef USE_CPMIO
		if (cpm_bdos_2(*e)) *pc = 0;
#else
		cout(*e);
#endif
		break;

	case 3:		/* No auxin */
		setw(l, h, 0x1A);
		break;

	case 4:		/* No auxout */
		break;

	case 5:		/* No printer */
		break;

	case 6:		/* Direct console I/O */
		retv = cpm_bdos_6(*e);
		if (retv < 0) *pc = 0;
		setw(l, h, retv);
		break;

	case 7:		/* No auxist */
	case 8:		/* No auxost */
		break;

	case 9:		/* Print a $-terminated string */
#ifdef USE_CPMIO
		if (cpm_bdos_9((char*)pde)) *pc = 0;
# else
		for (temp = 0; RAM[de + temp] != '$'; ++temp)
		{
			cout(RAM[de + temp]);
		}
#endif
		break;

	case 0x0A:
		bdos_rdline(de, &(*pc));
		break;

	case 0x0B:	/* Console status */
		// *l = *h = 0;	/* No keys pressed */
		*l = cstat();
		*h = 0;
		break;

	case 0x0C:	/* Get CP/M version */

		/* For GENCOM's benefit, claim to be v3.1 */

		*l = 0x31;	/* v3.1 */
		/*	*l = 0x22;	 * v2.2 */
		*h = 0;		/* CP/M, no network */
		break;

	case 0x0D:	/* Re-log discs */
		fcb_reset();
		break;

	case 0x0E:	/* Set default drive */
		setw(l, h, fcb_drive(*e));
		break;

	case 0x0F:	/* Open using FCB */
		setw(l, h, x_fcb_open(pde, pdma));
		break;

	case 0x10:	/* Close using FCB */
		setw(l, h, fcb_close(pde));
		break;

	case 0x11:	/* Find first */
		setw(l, h, fcb_find1(pde, pdma));
		break;

	case 0x12:
		setw(l, h, fcb_find2(pde, pdma));
		break;

	case 0x13:	/* Delete using FCB */
		setw(l, h, fcb_unlink(pde, pdma));
		break;

	case 0x14:	/* Sequential read using FCB */
		setw(l, h, fcb_read(pde, pdma));
		break;

	case 0x15:	/* Sequential write using FCB */
		setw(l, h, fcb_write(pde, pdma));
		break;

	case 0x16:	/* Create using FCB */
		setw(l, h, fcb_creat(pde, pdma));
		break;

	case 0x17:	/* Rename using FCB */
		setw(l, h, fcb_rename(pde, pdma));
		break;

	case 0x18:	/* Get login vector */
		setw(l, h, fcb_logvec());
		break;

	case 0x19:	/* Get default drive */
		setw(l, h, cpm_drive);
		break;

	case 0x1A:	/* Set DMA */
		DBGMSGV("Set DMA to 0x%04X\n", de);
		cpm_dma = de;
		break;

	case 0x1B:	/* Get alloc vector */
		fcb_getalv(RAM + 0xFF80, 0x40);
		setw(l, h, 0xFF80);
		break;

	case 0x1C:	/* Make disc R/O */
		setw(l, h, fcb_rodisk());
		break;

	case 0x1D:	/* Get R/O vector */
		setw(l, h, fcb_rovec());
		break;

	case 0x1E:	/* Set attributes */
		setw(l, h, fcb_chmod(pde, pdma));
		break;

	case 0x1F:	/* Get DPB */
		fcb_getdpb(RAM + 0xFFC0);
		setw(l, h, 0xFFC0);
		break;

	case 0x20:	/* Get/set uid */
		setw(l, h, fcb_user(*e));
		break;

	case 0x21:	/* Read a record */
		setw(l, h, fcb_randrd(pde, pdma));
		break;

	case 0x22:	/* Write a record */
		setw(l, h, fcb_randwr(pde, pdma));
		break;

	case 0x23:	/* Get file size */
		setw(l, h, x_fcb_stat(pde));
		break;

	case 0x24:	/* Get file pointer */
		setw(l, h, fcb_tell(pde));
		break;

	case 0x25:
		setw(l, h, fcb_resro(de));
		break;

		/* MP/M drive access functions, not implemented */

	case 0x28:	/* Write with 0 fill */
		setw(l, h, fcb_randwz(pde, pdma));
		break;

		/* MP/M record locking functions, not implemented */

	case 0x2C:	/* Set no. of records to read/write */
		setw(l, h, fcb_multirec(*e));
		break;

	case 0x2D:	/* Set error mode */
		err_mode = *e;
		break;

	case 0x2E:
		setw(l, h, fcb_dfree(*e, pdma));
		break;

		/* 0x2F: Chain */

	case 0x30:
		setw(l, h, fcb_sync(*e));
		break;

	case 0x31:
		if (pde[1] == 0xFE)
		{
			RAM[0xFE9C + *pde] = pde[2];
			RAM[0xFE9D + *pde] = pde[3];
		}
		else if (RAM[hl + 1] == 0xFF)
		{
			RAM[0xFE9C + *pde] = pde[2];
		}
		else
		{
			*l = RAM[0xFE9C + *pde];
			*h = RAM[0xFE9D + *pde];
		}
		break;

	case 0x32:
		temp = *ix;
		*ix = 3 * (pde[0] + 1);
		*a = pde[1];
		*c = pde[2];
		*b = pde[3];
		*e = pde[4];
		*d = pde[5];
		*l = pde[6];
		*h = pde[7];
		cpmbios(a, b, c, d, e, f, h, l, pc, ix, iy);
		*ix = temp;
		break;

	case 0x3C:	/* Communicate with RSX */
		*h = 0; *l = 0xFF; /* return error */
		break;

	case 0x62:	/* Purge */
		setw(l, h, fcb_purge());
		break;

	case 0x63:	/* Truncate file */
		setw(l, h, fcb_trunc(pde, pdma));
		break;

	case 0x64:	/* Set label */
		setw(l, h, fcb_setlbl(pde, pdma));
		break;

	case 0x65:	/* Get label byte */
		setw(l, h, fcb_getlbl(*e));
		break;

	case 0x66:      /* Get file date */
		setw(l, h, fcb_date(pde));
		break;

	case 0x67:	/* Set password */
		setw(l, h, fcb_setpwd(pde, pdma));
		break;

	case 0x68:	/* Set time of day */
		/* Not advisable to let an emulator play with the clock */
		break;

	case 0x69:	/* Get time of day */
		setw(l, h, get_time(de));
		break;

	case 0x6A:	/* Set default password */
		setw(l, h, fcb_defpwd(pde));
		break;

	case 0x6B:	/* Get serial number */
		memcpy(pde, SERIAL, 6);
		break;

	case 0x6C:	/* 0.03 set error code */
		setw(l, h, cpm_errcde(de));
		break;

#ifdef USE_CPMIO
	case 0x6D:	/* Set/get console mode */
		setw(l, h, cpm_bdos_109(de));
		break;

	case 0x6E:	/* Set/get string delimiter */
		setw(l, h, cpm_bdos_110(*e));
		break;

	case 0x6F:	/* Send fixed length string to screen */
		if (cpm_bdos_111((char*)RAM + peekw(de),
			peekw(de + 2)))
			*pc = 0;
		break;

	case 0x70:	/* Send fixed length string to printer */
		break;

	/* 0x71: Strange PCP/M function */
#else
	case 0x6D:	/* Set/get console mode */
		setw(l, h, 0);
		break;

#endif

#ifdef USE_CPMGSX
	case 0x73:	/* GSX */
		setw(l, h, gsx80(gsxrd, gsxwr, de));
		break;
#endif

	case 0x74:	/* Set date stamp */
		setw(l, h, fcb_sdate(pde, pdma));
		break;

	case 0x98:	/* Parse filename */
		setw(l, h, fcb_parse((char*)RAM + peekw(de),
			 (byte*)RAM + peekw(de + 2)));
		break;

	default:
#ifdef USE_CPMIO
		cpm_scr_unit();
#endif
#ifdef USE_CPMGSX
		gsx_deinit();
#endif

		fprintf(stderr, "%s: Unsupported BDOS call %d\n", progname,
			(int)(*c));
		dump_regs(stderr, *a, *b, *c, *d, *e, *f, *h, *l, *pc, *ix, *iy);
		zxcc_exit(1);
		break;
	}

	*a = *l;
	*b = *h;
}

void cpmbios(byte* a, byte* b, byte* c, byte* d, byte* e, byte* f,
	byte* h, byte* l, word* pc, word* ix, word* iy)
{
	int func = (((*ix) & 0xFF) / 3) - 1;

	DBGMSGV("BIOS service invoked: func=0x%02X\n", func);

	switch (func)	/* BIOS function */
	{
	case 1:
		zxcc_exit(zxcc_term());	/* Program termination */
		break;

	case 2:		/* CONST */
#ifdef USE_CPMIO
		* a = cpm_const();
#else 
		* a = cpm_bdos_6(0xFE);
#endif
		break;

	case 3: 	/* CONIN */
#ifdef USE_CPMIO
		* a = cpm_conin();
#else 
		* a = cpm_bdos_6(0xFD);
#endif
		break;

	case 4:		/* CONOUT */
#ifdef USE_CPMIO
		cpm_conout(*c);
#else 
		cpm_bdos_6(*c);
#endif
		break;

	case 20:	/* DEVTBL */
		setw(l, h, 0xFFFF);
		break;

	case 22:	/* DRVTBL */
		setw(l, h, 0xFFFF);
		break;

	case 26:	/* TIME */
		RAM[0xFEF8] = get_time(0xFEF4);
		break;

	case 30:	/* USERF!!! */
#ifdef USE_CPMIO
		cpm_bdos_110('$');
		cpm_bdos_9("This program has attempted to call USERF, "
				   "which is not implemented\n$");
#else
		printf("This program has attempted to call USERF, which "
			   "is not implemented.\n");
#endif
		zxcc_term();
		zxcc_exit(1);
		break;

	default:
#ifdef USE_CPMIO
		cpm_scr_unit();
#endif
#ifdef USE_CPMGSX
		gsx_deinit();
#endif

		fprintf(stderr, "%s: Unsupported BIOS call %d\n", progname, func);
		dump_regs(stderr, *a, *b, *c, *d, *e, *f, *h, *l, *pc, *ix, *iy);
		zxcc_exit(1);
	}
}
