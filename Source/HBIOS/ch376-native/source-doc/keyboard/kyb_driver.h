#ifndef __KYB_DRIVER__
#define __KYB_DRIVER__

#include <ch376.h>
#include <stdint.h>

extern usb_error usb_kyb_init(const uint8_t dev_index);
extern uint8_t   usb_kyb_flush() __sdcccall(1);
extern uint32_t  usb_kyb_buf_get_next();
// extern <registers> usb_kyb_report();

#endif
