#ifndef _HTC_SETJMP_H
#define _HTC_SETJMP_H

#if	z80
typedef	int	jmp_buf[4];
#endif

#if	i8086
typedef	int	jmp_buf[8];
#endif

#if	i8096
typedef	int	jmp_buf[10];
#endif

#if	m68k
typedef	int	jmp_buf[10];
#endif

extern	int	setjmp(jmp_buf);
extern void	longjmp(jmp_buf, int);

#endif
