#ifndef __USB_BASE_DRV
#define __USB_BASE_DRV

#include "usb_state.h"
#include <dev_transfers.h>
#include <stdint.h>

// ufi_seek is an alias for scsi_seek
extern usb_error scsi_seek(const uint16_t dev_index, const uint32_t lba);
extern usb_error ufi_seek(const uint16_t dev_index, const uint32_t lba);

#endif
