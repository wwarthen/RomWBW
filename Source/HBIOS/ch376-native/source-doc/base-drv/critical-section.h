#ifndef __CRITICAL_BLOCKS_H__
#define __CRITICAL_BLOCKS_H__

#include <stdint.h>

extern uint8_t in_critical_usb_section;

void critical_begin();
void critical_end();

#define is_in_critical_section() (in_critical_usb_section != 0)

#endif
