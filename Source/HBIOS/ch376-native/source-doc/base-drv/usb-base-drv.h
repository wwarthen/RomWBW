#ifndef __USB_BASE_DRV
#define __USB_BASE_DRV

#include <dev_transfers.h>
#include <stdint.h>

extern uint8_t storage_count;

extern uint8_t chnative_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1);

#endif
