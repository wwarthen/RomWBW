/* TICK.C -- see tick.h. */

#include <stdio.h>
#include <conio.h>

#define BF_SYSGET	0F8H
#define BF_SYSGET_TIMER	0D0H

/* probetimer()'s empirical CTC/IM2 detection budget: PROBE_UNIT
   iterations per burst, up to PROBE_MAXUNITS bursts, sized to cover a
   couple of real tick periods. */
#define PROBE_UNIT	100
#define PROBE_MAXUNITS	50

/* fallback pacing when no periodic timer is available. */
#define PLAIN_UNIT	227

unsigned char tickfreq;
unsigned char timeractive;

/* low 16 bits of the HBIOS tick counter. */
gettick()
{
#asm
    PUSH	IX
    LD	B,BF_SYSGET
    LD	C,BF_SYSGET_TIMER
    RST	8
    POP	IX
#endasm
}

/* the ROM's configured TICKFREQ, into *freq. */
gettickfreq(freq)
unsigned char *freq;
{
#asm
    PUSH	IX
    LD	B,BF_SYSGET
    LD	C,BF_SYSGET_TIMER
    RST	8
    LD	A,C			; TICKFREQ RETURNED IN C
    LD	L,(IX+6)		; FREQ POINTER
    LD	H,(IX+7)
    LD	(HL),A
    POP	IX
#endasm
}

/* nonzero if HB_TICKS is actually advancing, zero otherwise. */
probetimer()
{
    unsigned int t0;
    unsigned int burst, i;

    t0 = gettick();
    for (burst = 0; burst < PROBE_MAXUNITS; burst++) {
	for (i = 0; i < PROBE_UNIT; i++)
	    ;
	if (gettick() != t0)
	    return 1;
    }
    return 0;
}

/* call once at startup, before waitticks(): sets tickfreq/timeractive. */
tickinit(verbose)
unsigned char verbose;
{
    gettickfreq(&tickfreq);
    if (tickfreq == 0)
	tickfreq = 50;		/* shouldn't happen, defensive only */
    timeractive = probetimer();
    if (!verbose)
	return;
    if (timeractive)
	printf("periodic timer active (TICKFREQ=%u), pacing off HB_TICKS\n",
	       tickfreq);
    else
	printf("periodic timer NOT active, pacing off a plain delay loop\n");
}

/* wait approximately n HBIOS ticks, aborting early on a keypress.
   returns 1 if aborted, 0 if the wait completed. */
waitticks(n)
unsigned int n;
{
    unsigned int start, now;
    unsigned int u, i;

    if (timeractive) {
	start = gettick();
	for (;;) {
	    if (kbhit())
		return 1;
	    now = gettick();
	    if ((unsigned int) (now - start) >= n)
		return 0;
	}
    }
    for (u = 0; u < n; u++) {
	if (kbhit())
	    return 1;
	for (i = 0; i < PLAIN_UNIT; i++)
	    if ((i & 0xFF) == 0 && kbhit())
		return 1;
    }
    return 0;
}
