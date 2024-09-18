#define debugger() __asm__("PUSH AF \n PUSH BC \n  XOR A \n LD B, 7 \n  .DB 	0x49, 0xD7 \n POP BC \n POP AF")
