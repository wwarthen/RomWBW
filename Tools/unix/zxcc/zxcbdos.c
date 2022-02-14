#include "zxcc.h"
#include "zxbdos.h"
#include "zxcbdos.h"

#ifndef _WIN32
#include <sys/ioctl.h>
#endif

/* Line input */
#ifdef USE_CPMIO

void bdos_rdline(word line, word* PC)
{
	unsigned char* buf;

	if (!line) line = cpm_dma;
	else RAM[line + 1] = 0;

	buf = (unsigned char*)&RAM[line];

	if (cpm_bdos_10(buf)) *PC = 0;
}

#else /* def USE_CPMIO */

void bdos_rdline(word line, word* PC)
{
	unsigned char c;
	unsigned char* p;
	int n;
	int maxlen;

	if (!line) line = cpm_dma;
	maxlen = RAM[line];

	// fgets causes extra linefeeds, so we invent our own
	// fgets((char *)(RAM + line + 2), maxlen, stdin);

	p = (RAM + line + 2);
	n = 0;

	while (1) {
		c = cin();
		if (c == '\r')
			break;
		if (c == '\b') {
			if (n > 0) {
				cout('\b');
				cout(' ');
				cout('\b');
				n--;
				p--;
			}
		}
		else {
			if (n < maxlen) {
				cout(c);
				*p++ = c;
				n++;
			}
		}
	}

	cout('\r');
	*p = '\0';

	//RAM[line + 1] = strlen((char *)(RAM + line + 2)) - 1;	
	RAM[line + 1] = (unsigned char)n;

	DBGMSGV("Input: [%d] %-*.*s\n", RAM[line + 1], RAM[line + 1], RAM[line + 1], (char*)(RAM + line + 2));
}
#endif /* ndef USE_CPMIO */

#ifndef USE_CPMIO

int cpm_bdos_6(byte e)
{
	int c;

	switch (e) {
	case 0xFF:
		if (cstat()) return cin();
		return 0;

	case 0xFE:
		return cstat();

	case 0xFD:
		return cin();

	default:
		cout(e);
		break;
	}
	return 0;
}
#endif

#ifdef _WIN32
byte cin()
{
	if (_isatty(STDIN_FILENO))
		return getch();
	else
		return getchar();
}

void cout(byte c)
{
	if (_isatty(STDOUT_FILENO))
		putch(c);
	else
		putchar(c);
}

int cstat()
{
	if (_isatty(STDIN_FILENO))
		return _kbhit() ? 0xFF : 0;
	else
		return 0xFF;
}

#else /* def _WIN32 */

byte cin()
{
	char c = 0;

	read(STDIN_FILENO, &c, 1);
	return c;
}

void cout(byte c)
{
	write(STDOUT_FILENO, &c, 1);
	return;
}

int cstat()
{
	int i;

	ioctl(STDIN_FILENO, FIONREAD, &i);
	if (i > 0) return 0xFF;
	return 0;
}

#endif
