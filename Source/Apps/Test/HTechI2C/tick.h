/* TICK.H -- HBIOS tick-counter timing: gettick()/gettickfreq(),
   probetimer() (empirically detects whether the periodic timer is
   actually advancing), tickinit(verbose) (call once at startup, pass
   nonzero to also print which pacing path was found), and
   waitticks() (waits for real ticks when active, an uncalibrated
   busy-wait fallback when not, both abortable by a keypress). */

extern unsigned int gettick();
extern gettickfreq();
extern probetimer();
extern tickinit();
extern waitticks();

extern unsigned char tickfreq;
extern unsigned char timeractive;
