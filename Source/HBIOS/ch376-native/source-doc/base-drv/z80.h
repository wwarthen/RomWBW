#ifndef __Z80_HELPERS
#define __Z80_HELPERS

#include <stdint.h>

#define EI   __asm__("EI");
#define DI   __asm__("DI");
#define HALT __asm__("HALT");

typedef void (*jump_fn_t)(void) __z88dk_fastcall;

typedef struct {
  uint8_t   jump_op_code; // JMP or CALL
  jump_fn_t address;
} z80_jump_t;

#endif
