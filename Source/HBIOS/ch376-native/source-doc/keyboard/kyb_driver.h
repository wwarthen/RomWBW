#ifndef __KYB_DRIVER__
#define __KYB_DRIVER__

#include <ch376.h>
#include <stdint.h>

extern void     usb_kyb_init(const uint8_t dev_index) __sdcccall(1);
extern uint8_t  usb_kyb_flush() __sdcccall(1);
extern uint8_t  usb_kyb_status() __sdcccall(1);
extern uint16_t usb_kyb_read();

#endif
