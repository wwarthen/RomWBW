/* tms9918.h 9/11/2012 dwg - information from TI Docs       */
/* http://www1.cs.columbia.edu/~sedwards/papers/TMS9918.pdf */

extern void vdp_read();
extern void vdp_display();
extern void vdp_pad();
extern void vdp_hz_join();
extern void vdp_main_frame();
extern void vdp_clr16k();
extern void vdp_setregs();
extern void vdp_modes();
extern void vdp_pnt();
extern void vdp_pgt();
extern void vdp_colors();
extern void vdp_load_set();
extern void vdp_fill();
extern void vdp_sync_vdp_regen();
extern void func700();
extern void vdp_clr_vdp_regen();
extern void vdp_set_vdp_regen();
extern void vdp_num_vdp_regen();
extern vdp_wrvram();

/*
#define DEBUG 
*/

#define WIDTH 37
#define HEIGHT 24
#define GUTTER 3

#define BASE 128
#define DATAP (BASE+24)
#define CMDP (BASE+25)

#define WO_R0
#define WOR0B6

#define VDP_TRANSPARENT  0
#define VDP_BLACK        1
#define VDP_MED_GREEN    2
#define VDP_LGREEN  3
#define VDP_DBLUE    4
#define VDP_LBLUE   5
#define VDP_DRED     6
#define VDP_CYAN         7
#define VDP_MRED      8
#define VDP_LRED    9
#define VDP_DYELLOW  10
#define VDP_LYELLOW 11
#define VDP_DGREEN   12
#define VDP_MAGENTA      13
#define VDP_GRAY         14
#define VDP_WHITE        15

#define SINGLE 11
#define TRIPLE 0
char style;			/* can be SINGLE or TRIPPLE */

unsigned char vdp_regen[24*40];


/* eof - tms9918.h */
