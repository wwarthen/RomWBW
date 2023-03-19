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

	This file parses filenames to FCBs.
*/

#include "cpmint.h"

#define is_num(c)  ((c >= '0') && (c <= '9'))

static int parse_drive_user(char* txt, cpm_byte* fcb)
{
	char uid[4], drvid[4];
	int up, dp;

	for (up = dp = 0; *txt != ':'; ++txt)
	{
		if (is_num(*txt)) uid[up++] = *txt;
		if (isalpha(*txt)) drvid[dp++] = *txt;
		if (!is_num(*txt) && !isalpha(*txt)) return -1;
	}
	uid[up] = 0; drvid[dp] = 0;

	if (dp > 1) return -1;	/* Invalid driveletter */
	if (up > 2) return -1;  /* Invalid uid */

	fcb[0x0d] = atoi(uid) + 1; if (fcb[0x0d] > 16) return -1;

	if (islower(drvid[0])) drvid[0] = toupper(drvid[0]);

	if (drvid[0] < 'A' || drvid[0] > 'P') return -1;

	fcb[0] = drvid[0] - '@';
	return 0;
}

cpm_word fcb_parse(char* txt, cpm_byte* fcb)
{
	int nl = 0, tl = 0, pl = 0, phase = 0;
	char* ntxt, ch;

	memset(fcb, 0, 0x24);

	if (txt[1] == ':' || txt[2] == ':' || txt[3] == ':')
	{
		if (parse_drive_user(txt, fcb)) return 0xFFFF;
		/* Move past the colon */
		ntxt = strchr(txt, ':') + 1;
	}
	else ntxt = txt;
	while (phase < 3)
	{
		ch = *ntxt;
		if (islower(ch)) ch = toupper(ch);

		switch (ch)
		{
		case 0:
		case '\r':	/* EOL */
			phase = 4;
			break;

		case '.':	/* file.typ */
			if (!phase) ++phase;
			else phase = 3;
			break;

		case ';':	/* Password */
			if (phase < 2) phase = 2;
			else phase = 3;
			break;

		case '[': case ']': case '=': case 9:   case ' ':
		case '>': case '<': case ':': case ',': case '/':
		case '|':	/* Terminator */
			phase = 3;

		default:
			switch (phase)
			{
			case 0:
				if (nl >= 8) return 0xFFFF;
				fcb[++nl] = ch;
				break;

			case 1:
				if (tl >= 3) return 0xFFFF;
				fcb[tl + 9] = ch;
				++tl;
				break;

			case 2:
				if (pl >= 8) return 0xFFFF;
				fcb[pl + 0x10] = ch;
				++pl;
				break;
			}
			break;
		}
	}
	if (!nl) return 0xFFFF;

	fcb[0x1A] = pl;

	if (phase == 4) return 0;

	return (cpm_word)(ntxt - txt);
}
