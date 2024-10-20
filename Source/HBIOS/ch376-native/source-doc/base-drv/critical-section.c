#include "critical-section.h"
#include <stdint.h>

uint8_t in_critical_usb_section = 0;

void critical_begin() { in_critical_usb_section++; }

void critical_end() { in_critical_usb_section--; }
