#ifndef __UFI_DRIVER__
#define __UFI_DRIVER__

#include <ch376.h>
#include <stdint.h>

extern uint32_t  usb_ufi_get_cap(const uint16_t dev_index);
extern usb_error usb_ufi_read(const uint16_t dev_index, uint8_t *const buffer);
extern usb_error usb_ufi_write(const uint16_t dev_index, uint8_t *const buffer);

#endif
