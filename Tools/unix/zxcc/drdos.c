/*

	CPMREDIR: CP/M filesystem redirector
	Copyright (C) 1998, John Elliott <jce@seasip.demon.co.uk>

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Library General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Library General Public License for more details.

	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free
	Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

	This file holds DRDOS-specific password code.
*/

#include "cpmint.h"

cpm_word redir_drdos_pwmode(cpm_byte b)
{
	cpm_word mode = 0;

	if (b & 0x80) mode |= 0xddd;
	if (b & 0x40) mode |= 0x555;
	if (b & 0x20) mode |= 0x111;

	return mode;
}

cpm_byte redir_cpm_pwmode(cpm_word w)
{
	cpm_byte mode = 0;

	if (w & 0x8) mode |= 0x80;
	if (w & 0x4) mode |= 0x40;
	if (w & 0x1) mode |= 0x20;

	return mode;
}

#ifdef __MSDOS__
#ifdef __GO32__	/* The GO32 extender doesn't understand DRDOS password 
				 * functions, so these are done with __dpmi_int() rather
				 * than intdos() */

cpm_word redir_drdos_get_rights(char* path)
{
	__dpmi_regs r;

	if (!redir_drdos) return 0;

	redir_Msg("Rights for file %s: \n\r", path);

	dosmemput(path, strlen(path) + 1, __tb);
	r.x.ax = 0x4302;
	r.x.dx = __tb & 0x0F;
	r.x.ds = (__tb) >> 4;

	__dpmi_int(0x21, &r);

	redir_Msg("  %04x \n\r", r.x.cx);

	if (r.x.flags & 1) return 0;
	return r.x.cx;
}


cpm_word redir_drdos_put_rights(char* path, cpm_byte* dma, cpm_word rights)
{
	__dpmi_regs r;

	if (!redir_drdos) return 0;

	redir_Msg("Put rights for file %s: %04x %-8.8s %-8.8s\n\r", path, rights, dma, dma + 8);

	dosmemput(dma + 8, 8, __tb);	/* Point DTA at password */
	r.x.ax = 0x1A00;
	r.x.dx = (__tb & 0x0F);
	r.x.ds = (__tb) >> 4;
	__dpmi_int(0x21, &r);

	dosmemput(path, strlen(path) + 1, __tb + 0x10);
	r.x.ax = 0x4303;		/* Set rights */
	r.x.cx = rights;
	r.x.dx = (__tb & 0x0F) + 0x10;
	r.x.ds = (__tb) >> 4;

	__dpmi_int(0x21, &r);

	if (r.x.flags & 1)
	{
		redir_Msg("  Try 1 failed. Error %04x\n\r", r.x.ax);
		if (redir_password_error())
		{
			redir_password_append(path, dma);

			dosmemput(path, strlen(path) + 1, __tb + 0x10);
			r.x.ax = 0x4303;		/* Set rights */
			r.x.cx = rights;
			r.x.dx = (__tb & 0x0F) + 0x10;
			r.x.ds = (__tb) >> 4;

			__dpmi_int(0x21, &r);
			if (!r.x.flags & 1) return 0;
			if (redir_password_error()) return 0x7FF;
		}
		return 0xFF;
	}
	return 0;
}

#else	/* __GO32__ */

cpm_word redir_drdos_get_rights(char* path)
{
	union  REGS r;
	struct SREGS s;

	if (!redir_drdos) return 0;

	redir_Msg("Rights for file %s: \n\r", path);

	dosmemput(path, strlen(path) + 1, __tb);
	r.w.ax = 0x4302;
	r.w.dx = __tb & 0x0F;
	s.ds = (__tb) >> 4;

	intdosx(&r, &r, &s);

	redir_Msg("  %04x \n\r", r.w.cx);

	if (r.w.cflag) return 0;
	return r.w.cx;
}


cpm_word redir_drdos_put_rights(char* path, cpm_byte* dma, cpm_word rights)
{
	union  REGS r;
	struct SREGS s;

	if (!redir_drdos) return 0;

	redir_Msg("Put rights for file %s: %04x\n\r", path, rights);

	dosmemput(dma, 8, __tb);	/* Point DTA at password */
	r.w.ax = 0x1A00;
	r.w.dx = (__tb & 0x0F);
	s.ds = (__tb) >> 4;
	intdosx(&r, &r, &s);

	dosmemput(path, strlen(path) + 1, __tb + 0x10);
	r.w.ax = 0x4303;		/* Set rights */
	r.w.cx = rights;
	r.w.dx = (__tb & 0x0F) + 0x10;
	s.ds = (__tb) >> 4;

	intdosx(&r, &r, &s);

	if (r.w.cflag)
	{
		redir_Msg("  Try 1 failed. Error %04x \n\r", r.w.ax);
		if (redir_password_error())
		{
			redir_password_append(path, dma);

			dosmemput(path, strlen(path) + 1, __tb + 0x10);
			r.w.ax = 0x4303;		/* Set rights */
			r.w.cx = rights;
			r.w.dx = (__tb & 0x0F) + 0x10;
			s.ds = (__tb) >> 4;

			intdosx(&r, &r, &s);
			if (!r.w.cflag) return 0;
		}
		return 0xFF;
	}
	return 0;
}

#endif /* __GO32__ */


cpm_word redir_password_error(void)
{
	union  REGS r;

	if (!redir_drdos) return 0;

	r.w.ax = 0x5900;
	r.w.bx = 0x0000;

	intdos(&r, &r);

	redir_Msg("Last error was: %04x\n", r.w.ax);

	if (r.w.ax == 0x56) return 1;	/* Bad password */
	return 0;
}


void redir_password_append(char* s, cpm_byte* dma)
{
	int n, m;

	if (!redir_drdos) return;

	if (dma[0] == 0 || dma[0] == 0x20) return;

	strcat(s, ";");
	m = strlen(s);

	for (n = 0; n < 8; n++)
	{
		if (dma[n] == ' ') s[m] = 0;
		else               s[m] = dma[n];
		++m;
	}
	s[m] = 0;

}
#else	/* __MSDOS__ */
void redir_password_append(char* s, cpm_byte* dma) {}
cpm_word redir_password_error(void) { return 0; }
cpm_word redir_drdos_put_rights(char* path, cpm_byte* dma, cpm_word rights)
{
	return 0;
}
cpm_word redir_drdos_get_rights(char* path) { return 0; }
#endif	/* __MSDOS__ */
