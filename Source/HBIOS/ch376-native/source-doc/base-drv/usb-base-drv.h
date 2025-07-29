#ifndef __USB_BASE_DRV
#define __USB_BASE_DRV

#include "dev_transfers.h"
#include "usb_state.h"
#include <stdint.h>

extern uint16_t usb_init(uint8_t state) __z88dk_fastcall;

// ufi_seek is an alias for scsi_seek
extern usb_error usb_scsi_seek(const uint16_t dev_index, const uint32_t lba);
extern usb_error ufi_seek(const uint16_t dev_index, const uint32_t lba);

#endif
